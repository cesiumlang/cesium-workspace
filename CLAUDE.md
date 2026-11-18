# cesium-workspace

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
- Every repository has `main` and `dev`. Work goes to `dev` through pull requests; `dev` goes to `main` through a pull request that Randy reviews.
- Each submodule here records the `dev` head of its repository. After a merge to a submodule's `dev`, move the pointer here in the same piece of work.
- A setting or tool requirement added to a submodule's `*.code-workspace` or `.envrc` is repeated in `cesium-workspace.code-workspace` and `.envrc` here, with its path. LTeX reads only the dictionary of the workspace root, so words added to a submodule's `.vscode/ltex.dictionary.en-US.txt` go into the one here too.
- The website does not have the compiler as a submodule. Its `build.js` finds the compiler in `../cesium-src`, which is this layout.
