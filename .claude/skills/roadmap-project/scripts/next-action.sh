#!/usr/bin/env bash
# next-action.sh ORG APP_FOLDER
# Gives the organization's project 1 the field "Next action" (emanspeaks or
# agent), sets it on every item that is not done, and puts the label `agent` on
# the open issues of the organization whose next step is the agent's. An item
# is the owner's when it is assigned to emanspeaks, and the agent's otherwise
# (`web-agent` issues included: there is no separate web agent since
# 2026-11-24). Items from other organizations get the field only; their labels
# are their own project's.
set -euo pipefail
org=$1
# a token given in the environment (as the scheduled workflow gives it) is used as it is
[ -n "${GH_TOKEN:-}" ] || GH_TOKEN="$(bash /c/scratch/github-apps/app-token.sh "$2")"
export GH_TOKEN

project=$(gh project view 1 --owner "$org" --format json --jq .id < /dev/null)
field() { gh project field-list 1 --owner "$org" --format json --jq "$1" < /dev/null; }
if [ -z "$(field '.fields[] | select(.name == "Next action") | .id')" ]; then
  gh project field-create 1 --owner "$org" --name "Next action" --data-type SINGLE_SELECT \
    --single-select-options "emanspeaks,agent" < /dev/null > /dev/null
fi
fid=$(field '.fields[] | select(.name == "Next action") | .id')
owner_opt=$(field '.fields[] | select(.name == "Next action") | .options[] | select(.name == "emanspeaks") | .id')
web_opt=$(field '.fields[] | select(.name == "Next action") | .options[] | select(.name == "web-agent") | .id')
agent_opt=$(field '.fields[] | select(.name == "Next action") | .options[] | select(.name == "agent") | .id')
echo "field $fid: emanspeaks=$owner_opt agent=$agent_opt web-agent=$web_opt"

labeled=""
ensure_label() { # repo
  case " $labeled " in *" $1 "*) return ;; esac
  gh label create agent --repo "$1" --color 5319E7 --description "The next step is the agent's" --force < /dev/null > /dev/null
  labeled="$labeled $1"
}

owners=0 agents=0 webs=0 skipped=0
while IFS=$'\t' read -r item type repo number status who; do
  [ -z "$item" ] && continue
  if [ "$status" = Done ]; then skipped=$((skipped + 1)); continue; fi
  case "$who" in
    emanspeaks) opt=$owner_opt; owners=$((owners + 1)) ;;
    web-agent) opt=$web_opt; webs=$((webs + 1)) ;;
    *) opt=$agent_opt; agents=$((agents + 1)) ;;
  esac
  gh project item-edit --id "$item" --project-id "$project" --field-id "$fid" --single-select-option-id "$opt" < /dev/null > /dev/null
  [ "$type" = Issue ] || continue
  repo=${repo#https://github.com/}
  case $repo in "$org"/*) ;; *) continue ;; esac
  ensure_label "$repo"
  if [ "$who" = emanspeaks ]; then
    gh issue edit "$number" --repo "$repo" --remove-label agent < /dev/null > /dev/null 2>&1 || true
  else
    gh issue edit "$number" --repo "$repo" --add-label agent < /dev/null > /dev/null
  fi
done <<< "$(gh project item-list 1 --owner "$org" --limit 500 --format json --jq '.items[] | [.id, .content.type, .content.repository, (.content.number | tostring), (.status // ""), (if (.assignees // []) | index("emanspeaks") then "emanspeaks" else "agent" end)] | @tsv' < /dev/null)"
echo "$org: next action emanspeaks on $owners, agent on $agents, web-agent on $webs; $skipped done items left alone"
