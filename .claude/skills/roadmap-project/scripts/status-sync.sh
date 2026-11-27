#!/usr/bin/env bash
# status-sync.sh ORG APP_DIR: keeps the Roadmap's Status field and each
# issue's own status (GitHub's issue status: Backlog, Todo, In progress, In
# review, Done, Not planned, Duplicate) the same, both ways (emanspeaks,
# 2026-11-27). The hidden text field "Synced status" holds the value last
# synced: a Status that differs from it was changed on the Roadmap and goes
# to the issue; else an issue status that differs from it was changed on the
# issue and goes to the Roadmap. Pull requests and draft items keep the
# Roadmap's Status alone.
#   status-sync.sh cesiumlang cesiumlang
# Needs only bash and gh (its --jq; no jq binary).
set -uo pipefail

org=${1:?status-sync.sh ORG APP_DIR}
app=${2:?status-sync.sh ORG APP_DIR}
[ -n "${GH_TOKEN:-}" ] || GH_TOKEN="$(bash /c/scratch/github-apps/app-token.sh "$app")"
export GH_TOKEN
number=1
statuses=(Backlog Todo "In progress" "In review" Done "Not planned" Duplicate)
# fields are separated by the unit separator: a tab is white space to read,
# which would merge an empty field with the next
us=$'\x1f'

gql () { gh api graphql "$@"; }

project=$(gql -f query="{organization(login:\"$org\"){projectV2(number:$number){id}}}" --jq .data.organization.projectV2.id)

# the Status field, with the issue statuses as its options (kept by ID)
field_status () {
  gql -f query="{organization(login:\"$org\"){projectV2(number:$number){field(name:\"Status\"){... on ProjectV2SingleSelectField{id options{id name}}}}}}" \
    --jq '.data.organization.projectV2.field | .id as $f | .options[] | $f + "\u001f" + .id + "\u001f" + .name'
}
ensure_options () {
  local rows fid list="" name id color
  rows=$(field_status)
  fid=$(head -1 <<< "$rows" | cut -d"$us" -f1)
  for name in "${statuses[@]}"; do
    # the old "In Progress" becomes "In progress", keeping its ID and values
    id=$(awk -F"$us" -v n="$name" 'tolower($3) == tolower(n) { print $2 }' <<< "$rows")
    case $name in
      Backlog) color=GRAY ;; Todo) color=GREEN ;; "In progress") color=YELLOW ;; "In review") color=BLUE ;;
      Done) color=PURPLE ;; *) color=GRAY ;;
    esac
    list+="{${id:+id:\"$id\",}name:\"$name\",color:$color,description:\"\"},"
  done
  gql -f query="mutation{updateProjectV2Field(input:{fieldId:\"$fid\",singleSelectOptions:[${list%,}]}){projectV2Field{... on ProjectV2SingleSelectField{name}}}}" --jq '.data.updateProjectV2Field.projectV2Field.name' > /dev/null
}

# the hidden field that remembers the last synced value
synced_field () {
  local id
  # a field that does not exist is an error of the query, not an empty answer
  id=$(gql -f query="{organization(login:\"$org\"){projectV2(number:$number){field(name:\"Synced status\"){... on ProjectV2Field{id}}}}}" --jq '.data.organization.projectV2.field.id // empty' 2>/dev/null) || id=""
  if [[ $id != PVTF_* ]]; then
    id=$(gql -f query="mutation{createProjectV2Field(input:{projectId:\"$project\",dataType:TEXT,name:\"Synced status\"}){projectV2Field{... on ProjectV2Field{id}}}}" --jq .data.createProjectV2Field.projectV2Field.id)
  fi
  [[ $id == PVTF_* ]] || { echo "status-sync.sh: no field \"Synced status\" ($id)" >&2; exit 1; }
  echo "$id"
}

ensure_options
rows=$(field_status)
status_field=$(head -1 <<< "$rows" | cut -d"$us" -f1)
synced=$(synced_field)
option_id () { awk -F"$us" -v n="$1" '$3 == n { print $2 }' <<< "$rows"; }

# the issue statuses of a repository: NAME<US>ID
declare -A repo_statuses
issue_status_id () {
  local repo=$1 name=$2
  if [ -z "${repo_statuses[$repo]:-}" ]; then
    repo_statuses[$repo]=$(gql -f query="{repository(owner:\"${repo%/*}\",name:\"${repo#*/}\"){planningStatuses(first:20){nodes{id name}}}}" \
      --jq '.data.repository.planningStatuses.nodes[] | .name + "\u001f" + .id')
  fi
  awk -F"$us" -v n="$name" '$1 == n { print $2 }' <<< "${repo_statuses[$repo]}"
}

set_project () { # ITEM FIELD VALUE-JSON
  gql -f query="mutation{updateProjectV2ItemFieldValue(input:{projectId:\"$project\",itemId:\"$1\",fieldId:\"$2\",value:$3}){projectV2Item{id}}}" > /dev/null
}

changed=0 cursor="" after=""
while :; do
  page=$(gql -f query="{organization(login:\"$org\"){projectV2(number:$number){items(first:100$after){pageInfo{hasNextPage endCursor} nodes{id
    status: fieldValueByName(name:\"Status\"){... on ProjectV2ItemFieldSingleSelectValue{name}}
    synced: fieldValueByName(name:\"Synced status\"){... on ProjectV2ItemFieldTextValue{text}}
    content{__typename ... on Issue{id number repository{nameWithOwner} status{name}}}}}}}}" \
    --jq '.data.organization.projectV2.items | (.nodes[] | select(.content.__typename == "Issue") | [.id, (.status.name // ""), (.synced.text // ""), .content.id, .content.repository.nameWithOwner + "#" + (.content.number|tostring), (.content.status.name // "")] | join("\u001f")), "CURSOR\u001f" + (if .pageInfo.hasNextPage then .pageInfo.endCursor else "" end)')
  while IFS="$us" read -r item p s issue ref i; do
    [ "$item" = CURSOR ] && { cursor=$p; continue; }
    # never synced and closed: the issue's own closing status wins
    first_closed=false
    if [ -z "$s" ]; then case $i in Done | "Not planned" | Duplicate) first_closed=true ;; esac; fi
    if [ -n "$p" ] && [ "$p" != "$s" ] && [ $first_closed = false ]; then
      # changed on the Roadmap (or never synced): the issue follows
      if [ "$p" != "$i" ]; then
        sid=$(issue_status_id "${ref%#*}" "$p")
        if [ -n "$sid" ]; then
          gql -f query="mutation{setIssueStatus(input:{issueId:\"$issue\",statusId:\"$sid\"}){issue{number}}}" > /dev/null && echo "$ref: issue ${i:-none} -> $p"
        else
          echo "$ref: no issue status named $p" >&2; continue
        fi
      fi
      set_project "$item" "$synced" "{text:\"$p\"}"; changed=$((changed + 1))
    elif [ -n "$i" ] && [ "$i" != "$s" ]; then
      # changed on the issue: the Roadmap follows
      oid=$(option_id "$i")
      [ -n "$oid" ] || { echo "$ref: no Status option $i" >&2; continue; }
      set_project "$item" "$status_field" "{singleSelectOptionId:\"$oid\"}" && echo "$ref: Roadmap ${p:-none} -> $i"
      set_project "$item" "$synced" "{text:\"$i\"}"; changed=$((changed + 1))
    fi
  done <<< "$page"
  [ -n "$cursor" ] || break
  after=",after:\"$cursor\"" cursor=""
done
echo "$org: status synced on $changed items"
