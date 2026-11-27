#!/usr/bin/env bash
# ci-sync.sh ORG APP_DIR: fills the Roadmap's "CI" field from the checks of
# each open pull request (emanspeaks, 2026-11-27): the rollup of the checks of
# its latest commit, as GitHub shows it next to the commit. An open issue
# shows the checks of an open pull request that closes it ("Closes #N").
# Closed items keep their last value; an item with no checks has none.
#   ci-sync.sh cesiumlang cesiumlang
# Needs only bash and gh (its --jq; no jq binary).
set -uo pipefail

org=${1:?ci-sync.sh ORG APP_DIR}
app=${2:?ci-sync.sh ORG APP_DIR}
[ -n "${GH_TOKEN:-}" ] || GH_TOKEN="$(bash /c/scratch/github-apps/app-token.sh "$app")"
export GH_TOKEN
number=1
us=$'\x1f'

gql () { gh api graphql "$@"; }

project=$(gql -f query="{organization(login:\"$org\"){projectV2(number:$number){id}}}" --jq .data.organization.projectV2.id)

# the field and its options, created when missing: NAME<US>ID per option
field_rows () {
  gql -f query="{organization(login:\"$org\"){projectV2(number:$number){field(name:\"CI\"){... on ProjectV2SingleSelectField{id options{id name}}}}}}" \
    --jq '.data.organization.projectV2.field | .id as $f | .options[] | $f + "\u001f" + .id + "\u001f" + .name' 2>/dev/null
}
rows=$(field_rows) || rows=""
if [ -z "$rows" ]; then
  gql -f query="mutation{createProjectV2Field(input:{projectId:\"$project\",dataType:SINGLE_SELECT,name:\"CI\",singleSelectOptions:[
    {name:\"✅ Passing\",color:GREEN,description:\"Every check passed\"},
    {name:\"❌ Failing\",color:RED,description:\"A check failed\"},
    {name:\"🟡 Running\",color:YELLOW,description:\"Checks are running or waiting\"}]}){projectV2Field{... on ProjectV2SingleSelectField{id}}}}" > /dev/null
  rows=$(field_rows)
fi
field=$(head -1 <<< "$rows" | cut -d"$us" -f1)
[[ $field == PVTSSF_* ]] || { echo "ci-sync.sh: no field CI" >&2; exit 1; }
option_id () { awk -F"$us" -v n="$1" '$3 == n { print $2 }' <<< "$rows"; }

# a rollup state as the field's option name
label () {
  case $1 in
    SUCCESS) echo "✅ Passing" ;;
    FAILURE | ERROR) echo "❌ Failing" ;;
    PENDING | EXPECTED) echo "🟡 Running" ;;
    *) echo "" ;;
  esac
}

changed=0 cursor="" after=""
rollup='commits(last:1){nodes{commit{statusCheckRollup{state}}}}'
while :; do
  page=$(gql -f query="{organization(login:\"$org\"){projectV2(number:$number){items(first:100$after){pageInfo{hasNextPage endCursor} nodes{id
    ci: fieldValueByName(name:\"CI\"){... on ProjectV2ItemFieldSingleSelectValue{name}}
    content{__typename
      ... on PullRequest{state number repository{nameWithOwner} $rollup}
      ... on Issue{state number repository{nameWithOwner} closedByPullRequestsReferences(first:5,includeClosedPrs:false){nodes{state $rollup}}}}}}}}}" \
    --jq '.data.organization.projectV2.items | (.nodes[] | select(.content.state == "OPEN") | [.id, (.ci.name // ""), .content.repository.nameWithOwner + "#" + (.content.number|tostring),
      (if .content.__typename == "PullRequest" then (.content.commits.nodes[0].commit.statusCheckRollup.state // "")
       else ([.content.closedByPullRequestsReferences.nodes[] | select(.state == "OPEN") | .commits.nodes[0].commit.statusCheckRollup.state // empty] | first // "") end)] | join("\u001f")),
      "CURSOR\u001f" + (if .pageInfo.hasNextPage then .pageInfo.endCursor else "" end)')
  while IFS="$us" read -r item now ref state; do
    [ "$item" = CURSOR ] && { cursor=$now; continue; }
    want=$(label "$state")
    [ "$want" = "$now" ] && continue
    if [ -z "$want" ]; then
      gql -f query="mutation{clearProjectV2ItemFieldValue(input:{projectId:\"$project\",itemId:\"$item\",fieldId:\"$field\"}){projectV2Item{id}}}" > /dev/null
    else
      gql -f query="mutation{updateProjectV2ItemFieldValue(input:{projectId:\"$project\",itemId:\"$item\",fieldId:\"$field\",value:{singleSelectOptionId:\"$(option_id "$want")\"}}){projectV2Item{id}}}" > /dev/null
    fi && { echo "$ref: CI ${now:-none} -> ${want:-none}"; changed=$((changed + 1)); }
  done <<< "$page"
  [ -n "$cursor" ] || break
  after=",after:\"$cursor\"" cursor=""
done
echo "$org: CI updated on $changed items"
