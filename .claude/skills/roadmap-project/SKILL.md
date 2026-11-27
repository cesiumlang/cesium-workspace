---
name: roadmap-project
description: Keep the Cesium Roadmap GitHub Project in order - add a newly filed issue at its place in the priority order with its Track, set Status and Next action, link blocked-by dependencies, list what comes next. Use after filing an issue, when work on an item starts or ends, or to find the next item to work.
---

# The Cesium Roadmap Project

[Cesium Roadmap](https://github.com/orgs/cesiumlang/projects/1) (cesiumlang, project 1) is the source of truth for the order of all work across the Cesium repositories. Its README says how it is kept; in short:

- **Rows are in priority order.** The next item of a Track is its first row that is not Done.
- **Every new issue goes in when it is filed,** with its Track, at its place in that order, never at the end.
- **Status:** the issue's own status (GitHub's issue status): Backlog, Todo, In progress, In review, Done, Not planned, Duplicate. Set In progress when work starts; In review while a pull request waits for emanspeaks's decision (a proposal's design issue); Backlog for the `backlog` milestone; closing the issue sets Done. The Roadmap's Status field and the issue's status are kept the same both ways (see "Status, both ways").
- **Real dependencies** are GitHub "blocked by" links between issues.
- **Every plan is an issue,** even one far off or not yet scoped; the issue says what it waits on. No draft items (emanspeaks, 2026-11-20): they are invisible in the repositories and cannot be referenced or linked.
- The order changes when emanspeaks says so, or when a decision changes what depends on what.

**Tracks:** Editor infrastructure; Short answers; Design: S0 code; Design: direction and S1; Grammar, spec, stage 1; Real compiler; Docs follow-up; Later.

## Milestones and the order (emanspeaks, 2026-11-27)

- **Every open issue of a versioned repository has a milestone,** set when it is filed: cesium, grammar and cspell-cesium, whose versions are kept in step (grammar and cspell-cesium record the state of Cesium at a version), and vscode-cesium and devkits, which have versions of their own. cesiumlang.org, cesium-workspace and cesium-buildtools follow the latest tips and need none.
- **A milestone holds only what its release needs.** A design or question issue, and a proposal's pull request, goes in the milestone of the first release that depends on its answer. Work with no release planned goes in `backlog`. A repository may plan several releases ahead, so that a feature needed sooner ships before later work that builds on it.
- **cesium's milestones:** v0.1.0, `cesium0` and `cesium1` as they are, signed; v0.2.0, S0 complete; v0.3.0, S1; v0.4.0, the real compiler; `backlog`.
- **The rows are in milestone order,** the earliest release first; within a release, in the order the work and emanspeaks's answers unblock each other. A release is ready when its milestone has no open issue, not when its CI is green.

## Status, both ways (emanspeaks, 2026-11-27)

A change of the status on an issue shows in the Roadmap's Status column, and a change on the Roadmap changes the issue. `scripts/status-sync.sh cesiumlang cesiumlang` does it: the hidden text field "Synced status" holds the value last synced, so the side that differs from it is the side that changed (the Roadmap wins when both did). The workflow `roadmap-sync.yml` of cesium-workspace runs it, and `next-action.sh`, every 10 minutes; run it by hand after changing statuses in bulk. Pull requests on the Roadmap have only the Roadmap's Status.

## Script

`scripts/project.sh` does all of it, with bash and `gh` alone. Run it with the Cesium Agent's token (its `draft` command exists but is not used):

```sh
export GH_TOKEN="$(bash /c/scratch/github-apps/app-token.sh cesiumlang)"
P=/c/cesium/workspace/.claude/skills/roadmap-project/scripts/project.sh
bash $P list "Editor infrastructure"     # rows of one Track, in order
bash $P add cesium#90 "Real compiler" --after cesium#64
bash $P status "In progress" vscode-cesium#7
bash $P block cesiumlang.org#30 cesium#90  # cesiumlang.org#30 is blocked by cesium#90
```

An issue or pull request of another organization that Cesium work waits on (a Skein release or feature) goes on the board too, written `owner/repo#N`: `bash $P add chasingdaylight/skein#72 "Editor infrastructure" --after cesium#98` (emanspeaks, 2026-11-24). It gets the Track and the Next action here; its labels are its own project's.

`list` without a Track prints every row with its position. Decide the place by reading the neighbors in that Track: an item goes after what it depends on and before what depends on it.

## Next action

The field **Next action** of the project says whose step is next on a row: `emanspeaks` or `agent`. It follows the assignee, and the label `agent` follows it (emanspeaks, 2026-11-21): a row assigned to emanspeaks is his; every other row that is not Done is the agent's and its issue carries the label `agent`.

After changing an assignee, or after adding issues, bring the field and the labels in line for the whole project:

```sh
bash /c/cesium/workspace/.claude/skills/roadmap-project/scripts/next-action.sh cesiumlang cesiumlang
```

The script takes the organization and the folder of its app in `C:\scratch\github-apps\`; it does the same for the project skein Roadmap with `chasingdaylight chasingdaylight`. It can be run as often as wanted.
