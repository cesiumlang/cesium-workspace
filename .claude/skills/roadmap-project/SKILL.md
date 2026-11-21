---
name: roadmap-project
description: Keep the Cesium Roadmap GitHub Project in order - add a newly filed issue at its place in the priority order with its Track, set Status and Next action, link blocked-by dependencies, list what comes next. Use after filing an issue, when work on an item starts or ends, or to find the next item to work.
---

# The Cesium Roadmap Project

[Cesium Roadmap](https://github.com/orgs/cesiumlang/projects/1) (cesiumlang, project 1) is the source of truth for the order of all work across the Cesium repositories. Its README says how it is kept; in short:

- **Rows are in priority order.** The next item of a Track is its first row that is not Done.
- **Every new issue goes in when it is filed,** with its Track, at its place in that order, never at the end.
- **Status:** Todo, In Progress, Done. Set In Progress when work starts; closing the issue sets Done.
- **Real dependencies** are GitHub "blocked by" links between issues.
- **Every plan is an issue,** even one far off or not yet scoped; the issue says what it waits on. No draft items (emanspeaks, 2026-11-20): they are invisible in the repositories and cannot be referenced or linked.
- The order changes when emanspeaks says so, or when a decision changes what depends on what.

**Tracks:** Editor infrastructure; Short answers; Design: S0 code; Design: direction and S1; Grammar, spec, stage 1; Real compiler; Docs follow-up; Later.

## Script

`scripts/project.sh` does all of it, with bash and `gh` alone. Run it with the Cesium Agent's token (its `draft` command exists but is not used):

```sh
export GH_TOKEN="$(bash /c/scratch/github-apps/app-token.sh cesiumlang)"
P=/c/cesium/workspace/.claude/skills/roadmap-project/scripts/project.sh
bash $P list "Editor infrastructure"     # rows of one Track, in order
bash $P add cesium#90 "Real compiler" --after cesium#64
bash $P status "In Progress" vscode-cesium#7
bash $P block cesiumlang.org#30 cesium#90  # cesiumlang.org#30 is blocked by cesium#90
```

`list` without a Track prints every row with its position. Decide the place by reading the neighbors in that Track: an item goes after what it depends on and before what depends on it.

## Next action

The field **Next action** of the project says whose step is next on a row: `emanspeaks` or `agent`. It follows the assignee, and the label `agent` follows it (emanspeaks, 2026-11-21): a row assigned to emanspeaks is his; every other row that is not Done is the agent's and its issue carries the label `agent`.

After changing an assignee, or after adding issues, bring the field and the labels in line for the whole project:

```sh
bash /c/cesium/workspace/.claude/skills/roadmap-project/scripts/next-action.sh cesiumlang cesiumlang
```

The script takes the organization and the folder of its app in `C:\scratch\github-apps\`; it does the same for the project skein Roadmap with `chasingdaylight chasingdaylight`. It can be run as often as wanted.
