# cesium-workspace

One place to work on all repositories of the [Cesium programming language](https://cesiumlang.org). This repository has no code of its own: it has the other repositories as submodules, side by side, and a VS Code workspace for all of them.

## The repositories

| Path | Repository | What |
| --- | --- | --- |
| `cesium-src/` | [cesium](https://github.com/cesiumlang/cesium) | The compiler |
| `cesiumlang.org/` | [cesiumlang.org](https://github.com/cesiumlang/cesiumlang.org) | The website: language reference, compiler documentation, draft specification |
| `devkits/` | [devkits](https://github.com/cesiumlang/devkits) | The scripts and pins that build the devkit: Zig, the LLVM and LLD libraries, and QBE per host |
| `vscode-cesium/` | [vscode-cesium](https://github.com/cesiumlang/vscode-cesium) | The VS Code extension |
| `dot-github/` | [.github](https://github.com/cesiumlang/.github) | The organization's profile page |

Some of them have submodules of their own, which are Cesium repositories too:

| Path | Repository | What |
| --- | --- | --- |
| `cesium-src/buildtools/` | [cesium-buildtools](https://github.com/cesiumlang/cesium-buildtools) | Windows scripts for tools the devkit does not contain |
| `cesiumlang.org/grammar/` | [grammar](https://github.com/cesiumlang/grammar) | The TextMate grammar that highlights Cesium code |
| `cesium-src/.cspell/cesium/`, `cesiumlang.org/.cspell/cesium/` | [cspell-cesium](https://github.com/cesiumlang/cspell-cesium) | The spelling dictionary of Cesium terms |

The website is to include documentation generated from the compiler's source. Its build finds the compiler next to it, in `cesium-src/`; see the readme of cesiumlang.org.

## Clone

```bash
git clone --recurse-submodules https://github.com/cesiumlang/cesium-workspace.git
```

This also fetches LLVM, the `llvm-project` submodule of devkits: one commit without history, roughly 2 GB with the files checked out. To leave it out, clone without `--recurse-submodules` and then run:

```bash
git submodule update --init
git -C cesium-src submodule update --init
git -C cesiumlang.org submodule update --init
git -C devkits submodule update --init qbe
```

Each submodule is checked out at the commit this repository records, with no branch. Before working in one, switch to its `dev` branch:

```bash
git submodule foreach 'git checkout dev && git pull --ff-only'
```

## Setup

Open `cesium-workspace.code-workspace` in VS Code. It repeats the settings of the repositories' own workspace files with their paths, so this one workspace is enough.

With [direnv](https://direnv.net) installed, `.envrc` loads the `.envrc` files of the compiler and the website: the Zig and QBE of the Cesium devkit on `PATH`, and the Node.js version of the website through [fnm](https://github.com/Schniz/fnm). Run `direnv allow` once.

What each repository needs beyond that is in its own readme.

## Branches

Like the other repositories: work goes to `dev` through pull requests, and `dev` goes to `main` through a pull request. Each submodule records the `dev` head of its repository. After work is merged there, move the pointer:

```bash
git add cesium-src
git commit -m "Move cesium-src to its dev head"
```

## License

[MIT](LICENSE)
