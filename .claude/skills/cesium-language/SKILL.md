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

1. **The S0 grammar,** for anything `cesium0` and `cesium1` compile: `cesiumlang.org/content/spec/s0-grammar.md` (EBNF; every production cites its decision). Section 3.10 lists where stage 0 as implemented differs.
2. **The specification draft:** `cesiumlang.org/content/spec/` (`index.md` explains the Decided / Provisional / Open markers; `lexical.md`). Only rules marked Decided are settled.
3. **Decision records** in cesiumlang/cesium (label `decision`): the ownership design (#11), stage 0 and S0 (#9), core MIR (#8). Open questions have the label `design` or `audit`: never treat their suggestions as decided.
4. **The reference pages:** `cesiumlang.org/content/reference/`. They teach by example; their "Open" callouts mark what is undecided.

What stage 0 rejects because the design is open (literals with no typed context, unary minus, hexadecimal and other literal forms, shadowing, `null`, full-Cesium keywords as names, whole-struct assignment) is listed in `cesium-src/bootstrap/README.md`, "Open questions stage 0 refuses to answer".

## Examples that compile

- `cesium-src/bootstrap/tests/s0/*.csm`: S0 programs with their expected output; `tests/s0/errors/` holds programs that must be rejected, with the message.
- `cesium-src/bootstrap/stage1/*.csm`: `cesium1`, about 3,400 lines of S0, the largest Cesium program there is.

## Checking code

- Build the compilers in `cesium-src`: `.devkit/zig/zig build` (`cesium0` in `zig-out/bin`; `cesium1` is built by the tests until cesiumlang/cesium#81).
- `cesium0 --emit-mir -o out.mir a.csm b.csm` checks S0 and reports every error as `file:line:col: error: message` (see the bootstrap README for the exact form).
- `cat a.csm b.csm | cesium1` checks the same unit and stops at the first error; its line numbers count from the start of the joined input.
- In VS Code, `zcsls` (vscode-cesium) shows the same diagnostics in the Problems panel.
- A Cesium change is not done until a compiler accepts it, or rejects it with the expected message for an error test.
