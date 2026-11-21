---
name: roadmap-project
description: Keep the Cesium Roadmap GitHub Project in order - add a newly filed issue at its place in the priority order with its Track, set Status, link blocked-by dependencies, list what comes next. Use after filing an issue, when work on an item starts or ends, or to find the next item to work.
---

# The Cesium Roadmap Project

[Cesium Roadmap](https://github.com/orgs/cesiumlang/projects/1) (cesiumlang, project 1) is the source of truth for the order of all work across the Cesium repositories. Its README says how it is kept; in short:

- **Rows are in priority order.** The next item of a Track is its first row that is not Done.
- **Every new issue goes in when it is filed,** with its Track, at its place in that order, never at the end.
- **Status:** Todo, In Progress, Done. Set In Progress when work starts; closing the issue sets Done.
- **Real dependencies** are GitHub "blocked by" links between issues.
- **Every plan is an issue,** even one far off or not yet scoped; the issue says what it waits on. No draft items (Randy, 2026-11-20): they are invisible in the repositories and cannot be referenced or linked.
- The order changes when Randy says so, or when a decision changes what depends on what.

**Tracks:** Editor infrastructure; Short answers; Design: S0 code; Design: direction and S1; Grammar, spec, stage 1; Real compiler; Docs follow-up; Later.

## Script

`scripts/project.py` does all of it. Run it with the Cesium Agent's token (its `draft` command exists but is not used):

```sh
export GH_TOKEN="$(bash /c/scratch/github-apps/app-token.sh cesiumlang)"
P=/c/cesium/workspace/.claude/skills/roadmap-project/scripts/project.py
python -I $P list "Editor infrastructure"          # rows of one Track, in order
python -I $P add cesium#90 "Real compiler" --after cesium#64
python -I $P status "In Progress" vscode-cesium#7
python -I $P block cesiumlang.org#30 cesium#90     # cesiumlang.org#30 is blocked by cesium#90
```

`list` without a Track prints every row with its position. Decide the place by reading the neighbors in that Track: an item goes after what it depends on and before what depends on it.
