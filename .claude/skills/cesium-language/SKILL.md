---
name: cesium-language
description: Writing, reading or reviewing Cesium source (.csm, .csi files) - where the decided syntax and rules are, what is not Cesium, examples that compile, and how to check code with the bootstrap compilers. Use before writing or changing any Cesium code, or when a question depends on Cesium syntax or semantics.
paths:
  - "**/*.csm"
  - "**/*.csi"
---

# Cesium source

No model was trained on Cesium. Do not guess its syntax from C, Zig or C++: check every construct against the sources below, and run a compiler on what you write.

## Where the truth is, in this order

1. **The S0 chapter,** for anything `cesium0` and `cesium1` compile: `cesium-src/spec/s0.md` (the grammar as `syntax` rules, with the rules around it). Its last section, "Stage 0 as implemented", lists where `cesium0` differs.
2. **The specification:** `cesium-src/spec/` (`index.md` explains the rules, their statuses and the source each gives: decided, a direction of emanspeaks, by use, provisional; `lexical.md`). Every rule is `draft` until a proposal accepts it (`cesium-src/proposals/`): a decided or direction rule is guidance, a provisional one is a recommendation. `skein trace ID` shows a rule with what refers to it.
3. **Decision records** in cesiumlang/cesium (label `decision`): the ownership design (#11), stage 0 and S0 (#9), core MIR (#8). Open questions have the label `design` or `audit`: never treat their suggestions as decided.
4. **The reference pages:** `cesiumlang.org/content/reference/`. They teach by example; their "Open" callouts mark what is undecided.

What stage 0 rejects because the design is open (literals with no typed context, unary minus, hexadecimal and other literal forms, shadowing, `null`, full-Cesium keywords as names, whole-struct assignment) is listed in `cesium-src/bootstrap/README.md`, "Open questions stage 0 refuses to answer".

## Examples that compile

- `cesium-src/bootstrap/tests/s0/*.csm`: S0 programs with their expected output; `tests/s0/errors/` holds programs that must be rejected, with the message.
- `cesium-src/bootstrap/stage1/*.csm`: `cesium1`, about 3,400 lines of S0, the largest Cesium program there is.

## Checking code

- Build the compilers in `cesium-src`: `.devkit/zig/zig build` installs `cesium0` and `cesium1` to `zig-out/bin` (on the workspace `PATH` through `.envrc`).
- `cesium0 --emit-mir -o out.mir a.csm b.csm` checks S0 and reports every error as `file:line:col: error[E0304]: message` (see the bootstrap README for the exact form); `bootstrap/diagnostics.md` explains each code.
- `cesium1 a.csm b.csm` checks the same unit and stops at the first error, naming its file; given the files joined on standard input instead (`cat a.csm b.csm | cesium1`, as editors do), its line numbers count from the start of the input.
- In VS Code, `zcsls` (vscode-cesium) shows the same diagnostics in the Problems panel.
- A Cesium change is not done until a compiler accepts it, or rejects it with the expected message for an error test.
