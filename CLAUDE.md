# Cesium Workspace

This repository is the parent of the Cesium repositories. It has no code of its own. Its submodules, side by side:

- `cesium-src/` is cesiumlang/cesium, the compiler. Its submodules: `buildtools/` (cesium-buildtools), `.cspell/cesium/` (cspell-cesium).
- `cesiumlang.org/` is the website. Its submodules: `quartz_repo/` (Quartz, locked), `grammar/`, `.cspell/cesium/`.
- `devkits/` builds the devkit. Its submodules: `qbe/`, `llvm-project/`.
- `vscode-cesium/` is the VS Code extension (no code yet).
- `dot-github/` is cesiumlang/.github, the organization profile.

## Rules

- Do not modify files in `cesiumlang.org/src/quartz/` or `cesiumlang.org/quartz_repo/`: they are "locked" submodule references. Never move the commit of the `quartz_repo` submodule. Notify Randy if something there absolutely must change and cannot be handled by overriding it from files outside those directories.
- Do not redirect output to NUL (`2>nul`, `> NUL`). It does not work as expected on Windows. Let commands print.
- Indentation is two spaces (Zig files: four, as `zig fmt` writes them).
- Indent preprocessor directives where it helps readability; do not force them to column 0.
- In class definitions, indent the `public` and `private` keywords, and indent the members below them once more.
- Builds use the Zig of the Cesium devkit in `cesium-src/.devkit` (`python tools/fetch-devkit.py`), not the VS Code extension's Zig. CMake and the C++ prototype are gone from the compiler.

## How work is done here

- GitHub issues are the knowledge base. Before deciding anything about the language or the compiler, look for the issue that decides it (label `decision`; `design` and `audit` are open questions) and cite it. List anything decided without such guidance under "Choices made without guidance" in the pull request. Do not close or decide open design questions.
- Randy's uncommitted edits to `CLAUDE.md`, the LTeX dictionary and false-positive files, and readmes, in any repository of this workspace, go into the next commit there; they are usually small fixes. He says so when he is writing something larger that should be left alone until he is done.
- Disk space on Randy's machine is limited. No large downloads in the background (a test VS Code, toolchains, archives): leave those to CI. Git worktrees only when needed, few at a time, inside `C:\cesium`, removed when done. Delete local and GitHub branches once merged or no longer needed; keep only `main` and `dev` otherwise.
- The roadmap, cesium-workspace#12, is the priority order of all work across the repositories. Add every new issue to it when you file it, at its place in that order (not at the end), tick items as they close (with the pull request or the date of the decision), and edit its text when the order changes.
- Every repository has `main` and `dev`. Work goes to `dev`; `dev` goes to `main` through a pull request.
- A repository with a tagged release (check its tags; devkits is the first) takes all work through pull requests, nothing is pushed to its `main` directly, and Randy reviews its `dev` to `main` pull request. Until a repository has a tagged release, its `dev` to `main` pull request needs no review.
- Whatever needs a design decision or Randy's input is not settled here: label the issue `question` (or `design` in cesiumlang/cesium), assign it to Randy and leave it open. Recommend an answer only where there is one unambiguous or obvious one.
- On GitHub, Claude acts as the GitHub App Cesium Agent (`cesium-agent[bot]`, installed on every cesiumlang repository), not as Randy (cesium-workspace#6). Issues, comments, pull requests and merges: prefix the `gh` command with `GH_TOKEN="$(bash /c/scratch/github-apps/app-token.sh cesiumlang)"` (a token for one hour, cached). Commits and pushes: run every Git command that writes a commit (commit, amend, rebase, cherry-pick, merge) or pushes as `bash /c/scratch/github-apps/app-git.sh cesiumlang <git arguments>`, which commits as the app's bot and pushes with its token, never under Randy's identity; commit messages still end with the co-author line. Never print, copy or commit anything in `C:\scratch\github-apps\cesiumlang\` (the app's private key). A mention or assignment from the app reaches Randy, so mention and assign him where his input is needed. The app merges pull requests into `dev`, and `dev` to `main` where the repository has no tagged release; the `dev` to `main` pull request of a repository with a tagged release is merged by Randy, or on his word.
- The machine user `cesium-bot` does only what the app cannot, because it needs a user account: being assigned an issue or asked for a review, its own profile, gists, notifications, endpoints that refuse app tokens. It is also the fallback when the app's token cannot be had. Run those `gh` commands with `GH_CONFIG_DIR` set to `../cesium-bot/gh` (next to this checkout; the token is in the system keyring, not in a file). If neither works, say so and use plain `gh`, ending the text with "Posted by Claude at Randy's request".
- `cesium-bot` is Randy's one machine account: GitHub's terms allow one free machine account per person, used only for automated tasks, with the human owner responsible for it (Terms of Service, section B.3). A second one, `randyos-bot`, was suspended by GitHub on 2026-11-19. So: never create another machine account, and never use `cesium-bot` outside the cesiumlang repositories. Keep its activity to the work at hand: no bulk or repeated posting, no starring, following or watching, no activity in other people's repositories. If its sign-in reports the account suspended or flagged, stop using it, use plain `gh` and tell Randy.
- Each submodule here records the `dev` head of its repository. After a merge to a submodule's `dev`, move the pointer here in the same piece of work.
- A setting or tool requirement added to a submodule's `*.code-workspace` or `.envrc` is repeated in `cesium-workspace.code-workspace` and `.envrc` here, with its path. LTeX reads only the dictionary of the workspace root, so words added to a submodule's `.vscode/ltex.dictionary.en-US.txt` go into the one here too.
- The website does not have the compiler as a submodule. Its `build.js` finds the compiler in `../cesium-src`, which is this layout.
