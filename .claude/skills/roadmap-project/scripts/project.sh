#!/usr/bin/env bash
# Keeps the Cesium Roadmap Project (cesiumlang, project 1) in order.
#
# Run with the Cesium Agent's token in GH_TOKEN:
#   GH_TOKEN="$(bash /c/scratch/github-apps/app-token.sh cesiumlang)" bash project.sh <command> ...
#
# Commands:
#   list [TRACK]                       rows in priority order: position, status, track, item, title
#   add REF TRACK (--after REF | --top) add an issue (or move it) with that Track, placed after REF
#   move REF (--after REF | --top)     place an existing row
#   status STATUS REF...               set Status (Todo, In Progress, Done)
#   track TRACK REF...                 set Track
#   block BLOCKED BLOCKER...           link "BLOCKED is blocked by BLOCKER" between issues
#   draft TITLE BODY TRACK (--after REF | --top)   add a draft item for a plan without an issue
#
# REF is repo#number in cesiumlang, e.g. cesium#57 or vscode-cesium#7 (".github" for the org repo).
# Needs only bash and gh (its --jq; no jq binary).
set -uo pipefail

ORG=cesiumlang
NUMBER=1

die () { printf '%s\n' "$*" >&2; exit 1; }
usage () { sed -n '2,17p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//' >&2; exit 1; }

# a jq string literal
jstr () { local s=${1//\\/\\\\}; printf '"%s"' "${s//\"/\\\"}"; }

# gql QUERY JQ [-f|-F NAME=VALUE]...: the query's data through the jq filter
gql () {
  local query=$1 filter=$2 out
  shift 2
  out=$(gh api graphql -f "query=$query" "$@" --jq "$filter" 2>&1) || die "GraphQL error: $out"
  printf '%s\n' "${out//$'\r'/}"
}

# project: set PID
project () {
  PID=$(gql 'query($o:String!,$n:Int!){organization(login:$o){projectV2(number:$n){id}}}' \
    '.data.organization.projectV2.id' -f o=$ORG -F n=$NUMBER) || exit 1
}

# option FIELD VALUE: print "<field id> <option id>"
option () {
  local name=$1 value=$2 out
  out=$(gql 'query($o:String!,$n:Int!){organization(login:$o){projectV2(number:$n){
      fields(first:30){nodes{... on ProjectV2SingleSelectField{id name options{id name}}}}}}}' \
    ".data.organization.projectV2.fields.nodes[] | select(.name == $(jstr "$name"))
      | ([.options[] | select(.name == $(jstr "$value")) | .id][0]) as \$o
      | if \$o then \"\(.id) \(\$o)\" else \"none \([.options[].name] | join(\", \"))\" end" \
    -f o=$ORG -F n=$NUMBER) || exit 1
  [ -n "$out" ] || die "the Project has no field $name"
  case $out in
    none\ *) die "$name has no option '$value'; options: ${out#none }" ;;
    *) printf '%s\n' "$out" ;;
  esac
}

# split_ref REF: set REPO and NUM
split_ref () {
  REPO=${1%%#*} NUM=${1#*#}
  case $1 in *#*) ;; *) NUM= ;; esac
  [[ -n $REPO && $NUM =~ ^[0-9]+$ ]] || die "not a reference: '$1' (expected repo#number)"
}

# issue_node REF: print "<content id> <item id or nothing>"
issue_node () {
  local out
  split_ref "$1"
  out=$(gql 'query($o:String!,$r:String!,$n:Int!){repository(owner:$o,name:$r){
      issueOrPullRequest(number:$n){... on Issue{id projectItems(first:10){nodes{id project{number}}}}
                                    ... on PullRequest{id projectItems(first:10){nodes{id project{number}}}}}}}' \
    ".data.repository.issueOrPullRequest | if . == null then \"null\"
      else \"\(.id) \([.projectItems.nodes[] | select(.project.number == $NUMBER) | .id][0] // \"\")\" end" \
    -f o=$ORG -f "r=$REPO" -F "n=$NUM") || exit 1
  [ "$out" != null ] || die "$1 does not exist"
  printf '%s\n' "$out"
}

# item_of REF: print the Project item of REF
item_of () {
  local node item
  node=$(issue_node "$1") || exit 1
  item=${node#* }
  [ -n "$item" ] || die "$1 is not on the Project"
  printf '%s\n' "$item"
}

# set_field ITEM FIELD_ID OPTION_ID
set_field () {
  gql 'mutation($p:ID!,$i:ID!,$f:ID!,$o:String!){updateProjectV2ItemFieldValue(
      input:{projectId:$p,itemId:$i,fieldId:$f,value:{singleSelectOptionId:$o}}){projectV2Item{id}}}' \
    '.data.updateProjectV2ItemFieldValue.projectV2Item.id' \
    -f "p=$PID" -f "i=$1" -f "f=$2" -f "o=$3" > /dev/null || exit 1
}

# place ITEM [AFTER_REF]: at the top, or after AFTER_REF
place () {
  if [ -z "${2:-}" ]; then
    gql 'mutation($p:ID!,$i:ID!){updateProjectV2ItemPosition(input:{projectId:$p,itemId:$i}){
        items(first:1){totalCount}}}' '.data' -f "p=$PID" -f "i=$1" > /dev/null || exit 1
  else
    local after
    after=$(item_of "$2") || exit 1
    gql 'mutation($p:ID!,$i:ID!,$a:ID!){updateProjectV2ItemPosition(input:{projectId:$p,itemId:$i,afterId:$a}){
        items(first:1){totalCount}}}' '.data' -f "p=$PID" -f "i=$1" -f "a=$after" > /dev/null || exit 1
  fi
}

# where ARGS...: set AFTER to the REF after --after, or empty for --top
where () {
  local prev=
  AFTER=
  for a in "$@"; do [ "$a" = --top ] && return 0; done
  for a in "$@"; do
    if [ "$prev" = --after ]; then AFTER=$a; return 0; fi
    prev=$a
  done
  die "give --after REF or --top"
}

cmd_list () {
  local track=${1-} filter=${1+x} cursor= page head pos=0 status row_track ref title
  local query='query($o:String!,$n:Int!,$c:String){organization(login:$o){projectV2(number:$n){
      items(first:100,after:$c){pageInfo{hasNextPage endCursor} nodes{
        fieldValues(first:10){nodes{... on ProjectV2ItemFieldSingleSelectValue{name field{... on ProjectV2SingleSelectField{name}}}}}
        content{... on Issue{number title repository{name}} ... on PullRequest{number title repository{name}}
                ... on DraftIssue{title}}}}}}}'
  # the page line, then one line per row: status, track, item, title
  local jq='.data.organization.projectV2.items
    | "\(.pageInfo.hasNextPage) \(.pageInfo.endCursor)",
      (.nodes[] | ([.fieldValues.nodes[] | select(.field) | {(.field.name): .name}] | add // {}) as $v
        | (.content // {}) as $c
        | [$v.Status // "", $v.Track // "",
           (if $c.number then "\($c.repository.name)#\($c.number)" else "draft" end), $c.title // ""]
        | join("\u001f"))'
  while :; do
    if [ -n "$cursor" ]; then
      page=$(gql "$query" "$jq" -f o=$ORG -F n=$NUMBER -f "c=$cursor") || exit 1
    else
      page=$(gql "$query" "$jq" -f o=$ORG -F n=$NUMBER) || exit 1
    fi
    head=${page%%$'\n'*}
    while IFS=$'\x1f' read -r status row_track ref title; do
      pos=$((pos + 1))
      [ -n "$filter" ] && [ "$row_track" != "$track" ] && continue
      printf '%3d %-11s %-26s %-24s %s\n' "$pos" "$status" "$row_track" "$ref" "$title"
    done < <(printf '%s\n' "$page" | tail -n +2)
    [ "${head%% *}" = true ] || break
    cursor=${head#* }
  done
}

cmd_add () {
  [ $# -ge 2 ] || die "add REF TRACK (--after REF | --top)"
  local node content item ids
  project
  node=$(issue_node "$1") || exit 1
  content=${node%% *} item=${node#* }
  if [ -z "$item" ]; then
    item=$(gql 'mutation($p:ID!,$c:ID!){addProjectV2ItemById(input:{projectId:$p,contentId:$c}){item{id}}}' \
      '.data.addProjectV2ItemById.item.id' -f "p=$PID" -f "c=$content") || exit 1
    ids=$(option Status Todo) || exit 1
    # shellcheck disable=SC2086  # two words on purpose
    set_field "$item" $ids
  fi
  ids=$(option Track "$2") || exit 1
  # shellcheck disable=SC2086
  set_field "$item" $ids
  where "$@"
  place "$item" "$AFTER"
  printf '%s: %s, placed\n' "$1" "$2"
}

cmd_move () {
  [ $# -ge 1 ] || die "give --after REF or --top"
  local item
  project
  item=$(item_of "$1") || exit 1
  where "$@"
  place "$item" "$AFTER"
  printf '%s: placed\n' "$1"
}

cmd_field () { # FIELD VALUE REF...
  local name=$1 value=$2 ids ref item
  shift 2
  project
  ids=$(option "$name" "$value") || exit 1
  for ref in "$@"; do
    item=$(item_of "$ref") || exit 1
    # shellcheck disable=SC2086
    set_field "$item" $ids
    printf '%s: %s %s\n' "$ref" "$name" "$value"
  done
}

cmd_block () {
  local blocked=$1 blocker id out
  shift
  for blocker in "$@"; do
    split_ref "$blocker"
    id=$(gh api "repos/$ORG/$REPO/issues/$NUM" -q .id) || exit 1
    split_ref "$blocked"
    if out=$(gh api -X POST "repos/$ORG/$REPO/issues/$NUM/dependencies/blocked_by" -F "issue_id=$id" 2>&1 > /dev/null); then
      printf '%s blocked by %s: ok\n' "$blocked" "$blocker"
    else
      printf '%s blocked by %s: %s\n' "$blocked" "$blocker" "$out"
    fi
  done
}

cmd_draft () {
  [ $# -ge 3 ] || die "draft TITLE BODY TRACK (--after REF | --top)"
  local item ids
  project
  item=$(gql 'mutation($p:ID!,$t:String!,$b:String!){addProjectV2DraftIssue(input:{projectId:$p,title:$t,body:$b}){
      projectItem{id}}}' '.data.addProjectV2DraftIssue.projectItem.id' -f "p=$PID" -f "t=$1" -f "b=$2") || exit 1
  ids=$(option Status Todo) || exit 1
  # shellcheck disable=SC2086
  set_field "$item" $ids
  ids=$(option Track "$3") || exit 1
  # shellcheck disable=SC2086
  set_field "$item" $ids
  where "$@"
  place "$item" "$AFTER"
  printf "draft '%s': %s, placed\n" "$1" "$3"
}

[ $# -ge 1 ] || usage
command=$1
shift
case $command in
  list) cmd_list "$@" ;;
  add) cmd_add "$@" ;;
  move) cmd_move "$@" ;;
  status) [ $# -ge 1 ] || usage; cmd_field Status "$@" ;;
  track) [ $# -ge 1 ] || usage; cmd_field Track "$@" ;;
  block) [ $# -ge 1 ] || usage; cmd_block "$@" ;;
  draft) cmd_draft "$@" ;;
  *) usage ;;
esac
