#!/usr/bin/env bash
# order.sh [apply]: puts every open blocker of the Cesium Roadmap above what it
# blocks (emanspeaks, 2026-11-27), keeping the present order otherwise: the
# rows are placed in their order, each after its open blockers, depth first.
# Without "apply" it prints the rows that would move up.
#   GH_TOKEN="$(bash /c/scratch/github-apps/app-token.sh cesiumlang)" bash order.sh apply
# Needs only bash, awk and gh (its --jq; no jq binary).
set -uo pipefail
[ -n "${GH_TOKEN:-}" ] || GH_TOKEN="$(bash /c/scratch/github-apps/app-token.sh cesiumlang)"
export GH_TOKEN
P=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/project.sh
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

# the open rows, in their order
bash "$P" list | grep -v ' Done ' | grep -oE '[A-Za-z0-9./-]+#[0-9]+' > "$work/rows"
# each row's open blockers: ROW BLOCKER
: > "$work/edges"
while read -r ref; do
  repo=${ref%#*} n=${ref#*#}
  case $repo in */*) owner=${repo%/*} name=${repo#*/} ;; *) owner=cesiumlang name=$repo ;; esac
  gh api graphql -f query="{repository(owner:\"$owner\",name:\"$name\"){issueOrPullRequest(number:$n){... on Issue{blockedBy(first:20){nodes{number state repository{owner{login} name}}}}}}}" \
    --jq '.data.repository.issueOrPullRequest.blockedBy.nodes[]? | select(.state == "OPEN") | (if .repository.owner.login == "cesiumlang" then .repository.name else .repository.owner.login + "/" + .repository.name end) + "#" + (.number|tostring)' 2> /dev/null \
    | while read -r b; do echo "$ref $b"; done >> "$work/edges"
done < "$work/rows"

awk -v rowsfile="$work/rows" '
  BEGIN { while ((getline r < rowsfile) > 0) { order[++n] = r; onboard[r] = 1 } }
  { if ($2 in onboard) deps[$1] = deps[$1] " " $2 }
  function place(r,   k, parts, i) {
    if (r in done || r in visiting) return
    visiting[r] = 1
    k = split(deps[r], parts, " ")
    for (i = 1; i <= k; i++) if (parts[i] != "") place(parts[i])
    done[r] = 1; out[++m] = r
  }
  END { for (i = 1; i <= n; i++) place(order[i]); for (i = 1; i <= m; i++) print out[i] }
' "$work/edges" > "$work/new"

moved=$(awk 'NR == FNR { old[$0] = FNR; next } old[$0] > FNR { printf "%s %d -> %d\n", $0, old[$0], FNR }' "$work/rows" "$work/new")
echo "${moved:-nothing to move}"
[ "${1:-}" = apply ] && [ -n "$moved" ] || exit 0
prev=""
while read -r r; do
  if [ -z "$prev" ]; then bash "$P" move "$r" --top > /dev/null; else bash "$P" move "$r" --after "$prev" > /dev/null; fi || echo "order.sh: could not place $r" >&2
  prev=$r
done < "$work/new"
echo "placed $(wc -l < "$work/new" | tr -d ' ') rows"
