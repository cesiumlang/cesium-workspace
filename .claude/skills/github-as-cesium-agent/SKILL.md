---
name: github-as-cesium-agent
description: How to act on GitHub in the cesiumlang repositories - issues, comments, pull requests, merges, commits and pushes as the Cesium Agent app, the emanspeaks-bot fallback and its limits, pull request conventions. Use before any gh command, commit or push in this workspace.
---

# Acting on GitHub as the Cesium Agent

Claude acts as the GitHub App **Cesium Agent** (`cesium-agent[bot]`, installed on every cesiumlang repository), never as emanspeaks (cesium-workspace#6).

## Commands

- **Issues, comments, pull requests, merges, Projects:** prefix `gh` with the app's token (one hour, cached):
  `GH_TOKEN="$(bash /c/scratch/github-apps/app-token.sh cesiumlang)" gh ...`
- **Commits and pushes:** run every Git command that writes a commit (commit, amend, rebase, cherry-pick, merge) or pushes as
  `bash /c/scratch/github-apps/app-git.sh cesiumlang <git arguments>`
  It commits as the app's bot and pushes with its token.
- **The app's own token** (for `/app` endpoints, such as reading its permissions): `app-token.sh cesiumlang --jwt`, then `GET /app/installations/184089428`.
- Never print, copy or commit anything in `C:\scratch\github-apps\cesiumlang\` (the private key).

The app can write contents, issues, pull requests, workflows, actions, administration (rulesets) and organization Projects. It cannot read or set Actions secrets and variables, or change a Project's visibility; those are emanspeaks's.

## Messages

- **Commits:** one short line (about 50 characters), a blank line, then `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. No other body.
- **Pull request bodies:** what and why, how it was checked, a "Choices made without guidance" section, ending with `🤖 Generated with [Claude Code](https://claude.com/claude-code)`. Write the body to a file and pass `--body-file`: heredocs in the Bash tool mangle backslashes and apostrophes.
- **Issues and comments** end with `_Filed by Claude at the request of emanspeaks._` or `_Posted by Claude at the request of emanspeaks._`.
- **Every issue has a type** (organization issue types, 2026-11-21): Task (work, including docs trackers), Bug, Feature, Design (an open language or toolchain design question), Question (an answer needed from emanspeaks), Decision (a decision record, until rewritten as a proposal). Set it when filing: `gh api -X PATCH repos/cesiumlang/<repo>/issues/<n> -f type=Task` (the app may set types, not create them).
- **The owner is `emanspeaks`** (2026-11-20), never his first name: in issues, pull requests, comments, commit messages and files. Record his directions as "(emanspeaks, 2026-11-20)", without `@`; write `@emanspeaks` only to ask for his input or attention, since every `@` notifies him. `RandyOS`, `randyos-org`, `randyos-agent` and `randyos-bot` are names of other things; leave them.
- `Closes #N` in a pull request into `dev` closes the issue when it merges (the shared workflow in cesiumlang/.github, called from each repository's `close-issues.yml`); inside code spans and code blocks it is ignored. Use `Part of #N` for partial work.
- **Whose action is next is said three ways, kept the same** (emanspeaks, 2026-11-20 and 2026-11-21). emanspeaks is the assignee only where he must answer something or do something Claude cannot (a decision, a web-only step). Everything whose next step is Claude's has no assignee, the label `agent`, and "Next action: agent" in the Roadmap project (GitHub Apps cannot be assignees, and the machine account `emanspeaks-bot`, which was assigned such work before, cannot be assigned since GitHub flagged it on 2026-11-21). When the next step changes hands, change all three; `next-action.sh` in the `roadmap-project` skill sets the field and the label from the assignees for the whole project. A mention or assignment from the app reaches emanspeaks.

## Merging

- The app merges pull requests into `dev`, and `dev` to `main` where the repository has no tagged release.
- A pull request into `dev` is merged at once (emanspeaks, 2026-11-21; as zfls and rstd): no ruleset of a `dev` branch requires a check, and CI does not start for pull requests into `dev` or pushes to it. Run the checks of the repository locally first and say in the pull request which were run.
- CI runs on the standing pull request from `dev` to `main` of each repository that has CI (cesium, devkits, vscode-cesium, grammar): each merge into `dev` restarts its run. Look at it after merging; a red run means `dev` is broken, and is fixed with a new pull request into `dev`. To check one branch before merging, start the workflow by hand: `gh workflow run ci.yml --ref BRANCH`. `main` requires CI.
- The standing pull request is merged by emanspeaks, or on his word; open a new one (`dev` to `main`, titled "dev to main") right after.
- In a repository with a tagged release (check its tags; devkits is the first), all work goes through pull requests, nothing is pushed to `main`, and emanspeaks merges the `dev` to `main` pull request, or it is merged on his word.
- After a merge: delete the local branch (GitHub deletes the remote one), move the submodule pointer in the workspace, and tick or move the item on the Project (`roadmap-project` skill).

## The emanspeaks-bot fallback

The machine user `emanspeaks-bot` (named `cesium-bot` until emanspeaks renamed it on 2026-11-21; its email is `bot@emanspeaks.com`) does only what the app cannot because it needs a user account: being assigned or asked for a review, its own profile, gists, notifications, endpoints that refuse app tokens. It is also the fallback when the app's token cannot be had. Run those `gh` commands with `GH_CONFIG_DIR` set to `../cesium-bot/gh` (next to the workspace checkout; the token is in the system keyring).

`emanspeaks-bot` is emanspeaks's one machine account (GitHub Terms of Service, section B.3; a second one, `randyos-bot`, was suspended on 2026-11-19). Never create another machine account, never use `emanspeaks-bot` outside the cesiumlang repositories, keep its activity to the work at hand (no bulk or repeated posting, no starring, following or watching, nothing in other people's repositories). If its sign-in reports the account suspended or flagged, stop using it, use plain `gh` and tell emanspeaks. If neither the app nor the bot works, say so and use plain `gh`, ending the text with "Posted by Claude at the request of emanspeaks".
