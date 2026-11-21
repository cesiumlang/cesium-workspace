---
name: github-as-cesium-agent
description: How to act on GitHub in the cesiumlang repositories - issues, comments, pull requests, merges, commits and pushes as the Cesium Agent app, the cesium-bot fallback and its limits, pull request conventions. Use before any gh command, commit or push in this workspace.
---

# Acting on GitHub as the Cesium Agent

Claude acts as the GitHub App **Cesium Agent** (`cesium-agent[bot]`, installed on every cesiumlang repository), never as Randy (cesium-workspace#6).

## Commands

- **Issues, comments, pull requests, merges, Projects:** prefix `gh` with the app's token (one hour, cached):
  `GH_TOKEN="$(bash /c/scratch/github-apps/app-token.sh cesiumlang)" gh ...`
- **Commits and pushes:** run every Git command that writes a commit (commit, amend, rebase, cherry-pick, merge) or pushes as
  `bash /c/scratch/github-apps/app-git.sh cesiumlang <git arguments>`
  It commits as the app's bot and pushes with its token.
- **The app's own token** (for `/app` endpoints, such as reading its permissions): `app-token.sh cesiumlang --jwt`, then `GET /app/installations/184089428`.
- Never print, copy or commit anything in `C:\scratch\github-apps\cesiumlang\` (the private key).

The app can write contents, issues, pull requests, workflows, actions, administration (rulesets) and organization Projects. It cannot read or set Actions secrets and variables, or change a Project's visibility; those are Randy's.

## Messages

- **Commits:** one short line (about 50 characters), a blank line, then `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. No other body.
- **Pull request bodies:** what and why, how it was checked, a "Choices made without guidance" section, ending with `🤖 Generated with [Claude Code](https://claude.com/claude-code)`. Write the body to a file and pass `--body-file`: heredocs in the Bash tool mangle backslashes and apostrophes.
- **Issues and comments** end with `_Filed by Claude at Randy's request._` or `_Posted by Claude at Randy's request._`.
- `Closes #N` in a pull request into `dev` closes the issue when it merges (the shared workflow in cesiumlang/.github, called from each repository's `close-issues.yml`); inside code spans and code blocks it is ignored. Use `Part of #N` for partial work.
- A mention or assignment from the app reaches Randy: mention and assign him where his input is needed.

## Merging

- The app merges pull requests into `dev`, and `dev` to `main` where the repository has no tagged release.
- In a repository with a tagged release (check its tags; devkits is the first), all work goes through pull requests, nothing is pushed to `main`, and Randy merges the `dev` to `main` pull request, or it is merged on his word.
- After a merge: delete the local branch (GitHub deletes the remote one), move the submodule pointer in the workspace, and tick or move the item on the Project (`roadmap-project` skill).

## The cesium-bot fallback

The machine user `cesium-bot` does only what the app cannot because it needs a user account: being assigned or asked for a review, its own profile, gists, notifications, endpoints that refuse app tokens. It is also the fallback when the app's token cannot be had. Run those `gh` commands with `GH_CONFIG_DIR` set to `../cesium-bot/gh` (next to the workspace checkout; the token is in the system keyring).

`cesium-bot` is Randy's one machine account (GitHub Terms of Service, section B.3; a second one, `randyos-bot`, was suspended on 2026-11-19). Never create another machine account, never use `cesium-bot` outside the cesiumlang repositories, keep its activity to the work at hand (no bulk or repeated posting, no starring, following or watching, nothing in other people's repositories). If its sign-in reports the account suspended or flagged, stop using it, use plain `gh` and tell Randy. If neither the app nor the bot works, say so and use plain `gh`, ending the text with "Posted by Claude at Randy's request".
