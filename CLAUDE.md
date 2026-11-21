# Cesium Workspace

This repository is the parent of the Cesium repositories. It has no code of its own; its `.claude/` holds the agent setup (skills, rules, subagents). Its submodules, side by side:

- `cesium-src/` is cesiumlang/cesium, the compiler. Its submodules: `buildtools/` (cesium-buildtools), `.cspell/cesium/` (cspell-cesium).
- `cesiumlang.org/` is the website. Its submodules: `quartz_repo/` (Quartz, locked), `grammar/`, `.cspell/cesium/`.
- `devkits/` builds the devkit. Its submodules: `qbe/`, `llvm-project/`.
- `vscode-cesium/` is the VS Code extension and the temporary language server `zcsls` (Zig). Its submodule: `grammar/`.
- `dot-github/` is cesiumlang/.github, the organization profile and the shared workflows.

## Rules

- `cesiumlang.org/quartz_repo/` and `cesiumlang.org/src/quartz/` are locked: never modify them or move the `quartz_repo` commit; tell Randy if something there must change.
- Do not redirect output to NUL (`2>nul`, `> NUL`); it does not work as expected on Windows. Let commands print.
- Indentation is two spaces (Zig: four, as `zig fmt` writes). Language-specific rules are in `.claude/rules/` and load with the files they cover.
- Builds use the Zig of the Cesium devkit (`cesium-src/.devkit`, `bash tools/fetch-devkit.sh`), not the VS Code extension's Zig.
- Other external tools come from `cesium-src/buildtools` (`buildtools.bat`), so a developer needs nothing preinstalled: the Vulkan SDK, Node.js, the tree-sitter CLI, direnv, Qt. Code uses those copies (the buildtools Vulkan SDK, never a system-wide one, which is left alone). A new tool is added there as a pinned, checked download.
- The `.envrc` files are the one source of the environment, loaded by direnv (from buildtools) for every consumer: Git Bash (`cesium-src/buildtools/direnv-hook.sh` sourced in `~/.bashrc`), VS Code (the direnv extension), and Claude Code sessions (the `SessionStart` hook `.claude/hooks/direnv-env.sh`). Node.js comes from buildtools, and from fnm only where buildtools has none.
- No Python in any Cesium repository, as it cannot be assumed installed: scripts are bash or batch files; programs that are part of the build or the tests are Zig (cesiumlang/cesium#90).
- Disk space is limited: no large downloads in the background (a test VS Code, toolchains, archives; CI does those); few Git worktrees, inside `C:\cesium`, removed when done; delete branches once merged, keeping only `main` and `dev`.

## How work is done here

- GitHub issues are the knowledge base. Before deciding anything about the language or the compiler, find the issue that decides it (label `decision`; `design` and `audit` are open questions) and cite it. List anything decided without such guidance under "Choices made without guidance" in the pull request. Never close or decide an open design question.
- Writing or reading Cesium code: the `cesium-language` skill says where the decided syntax is and how to check code with the compilers.
- Whatever needs a design decision or Randy's input: label the issue `question` (`design` in cesiumlang/cesium), assign Randy, leave it open. Recommend an answer only where one is unambiguous or obvious.
- Assignees say whose action is next: Randy only where he must answer or do something Claude cannot; Claude's work is assigned to `cesium-bot` (an app cannot be assigned). Change the assignee when the next step changes hands.
- The GitHub Project [Cesium Roadmap](https://github.com/orgs/cesiumlang/projects/1) is the source of truth for the order of all work. Every new issue goes into it at its place in the priority order, and every plan is an issue, however far off (no draft items); the `roadmap-project` skill has the procedure and scripts.
- On GitHub, Claude acts as the GitHub App Cesium Agent, never as Randy, and commits as its bot; the `github-as-cesium-agent` skill has the commands, the `cesium-bot` fallback and its limits. Never print, copy or commit anything in `C:\scratch\github-apps\cesiumlang\`.
- Every repository has `main` and `dev`. Work goes to `dev` through pull requests; `dev` goes to `main` through a pull request. Once a repository has a tagged release (devkits; check its tags), Randy reviews and merges its `dev` to `main` pull request.
- Each submodule here records the `dev` head of its repository: after a merge to a submodule's `dev`, move the pointer here in the same piece of work.
- Randy's uncommitted edits to `CLAUDE.md`, the LTeX dictionary and false-positive files, and readmes, in any repository here, go into the next commit there. He says when he is writing something larger to leave alone.
- A setting or tool requirement added to a submodule's `*.code-workspace` or `.envrc` is repeated in `cesium-workspace.code-workspace` and `.envrc` here. LTeX reads only this root's dictionary, so words added to a submodule's `.vscode/ltex.dictionary.en-US.txt` go into the one here too.
- The website's `build.js` finds the compiler in `../cesium-src`; the website does not have it as a submodule.
