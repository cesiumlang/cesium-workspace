---
name: cesium-spec
description: Writing or changing Cesium's specification, proposals, charter or the tests' citations of rules - rule markers and IDs, categories, statuses and sources, tested examples, open points, proposal files and who sets their status, `// spec:` citations and reviews, and the Skein commands that check them. Use before editing cesium-src/spec, cesium-src/proposals, cesium-src/docs/charter.md or a test's citations.
paths:
  - "cesium-src/spec/**"
  - "cesium-src/proposals/**"
  - "cesium-src/docs/**"
  - "cesium-src/.skein/**"
---

# The specification, the proposals and the tests

The process is Proposal 0000 (`cesium-src/proposals/0000-documentation-system.md`): the charter and the proposals decide, the specification records, the tests cite. Skein (`skein`, from the VS Code extension `chasingdaylight.skein`, or `bash tools/fetch-skein.sh` into `.skein-bin/`) reads all of it; its rules are in `cesium-src/.skein/`.

## Rules (`spec/`)

- A rule is a paragraph or list entry: `%rule[ID category status introduced-by=P-NNNN] Text. Source.` Write the marker in that order.
- **ID:** by topic, `lex.comment.line`, `s0.expr.convert`; never changed by hand (`skein move OLD NEW`); a dropped rule keeps its ID with the status `removed`. Parts are list entries `%rule[.name ...]` under a rule.
- **Category:** `syntax`, `legality` (what is rejected), `static` (meaning at compile time), `dynamic` (behavior at run time).
- **Status:** `draft` until an accepted proposal makes it `final`; agents never write `final`.
- **introduced-by** is required: the proposal that brings the rule. Rules drafted from the old material, or from emanspeaks's directions before a proposal carries them, name `P-0000`; when a proposal is accepted, it is `changed-by=P-NNNN`.
- **Source,** at the end of the text, so a reader knows how firm it is: "Decided in [#11], rule 2." (a decision record or the reference), "Direction in [#15], 2026-11-22." (emanspeaks's answer on a design issue), "By use (...)", or "Provisional (...)" (an editor's recommendation). Issues are reference links `[#15]`, defined at the end of the chapter. The site's AI files fail the build on a rule that names no source (`cesium-site-ai --strict`).
- **Open points** are narrative, "Open: ... ([#39])", with no rule. Never write an undecided point as a rule.
- **Examples:** a fenced block in a rule, with the marker after the language: ```` ```cesium %example[.name accepts] ````, or `rejects`. Each must compile (or be rejected) with `cesium0` as it says: `bash tools/spec-examples.sh` after `zig build` (CI runs it).
- **References:** `%[id]` in text; `\%` to write a percent sign before a bracket literally.

## Proposals (`proposals/NNNN-name.md`, and the charter `docs/charter.md`)

- A file with front matter: `id = "P-NNNN"`, `type = "proposal"`, `status`. Numbers in order of filing.
- Sections: Motivation, Design (numbered points, each acceptable alone), Alternatives, Drawbacks, Open questions; for one carried from an issue, What changed since the record.
- **Status:** `draft` or `proposed` by anyone; `accepted`, `rejected`, `superseded` by emanspeaks only; `withdrawn` by the author or emanspeaks. An agent writes a proposal and recommends; it never sets `accepted`.
- Acceptance is emanspeaks merging the proposal's pull request with `accepted`; the type requires an approval of the accepted text: `skein approve P-NNNN --from-pull-request` after his approving review.

## Tests (`bootstrap/tests/`)

- A test names the rules it checks under its header comment: `// spec: s0.expr.alloc, s0.check.address-context`.
- Citations are reviewed: after adding or changing one, `skein review FILE`, and commit `.skein/reviews/`. When a cited rule changes, `skein check` reports the citation until it is reviewed again.
- A test of what stage 0 rejects because the design is open cites nothing.

## Checking

- `skein check`: every marker, link, reference and citation (CI fails on it). `skein coverage`: the rules no test or example reaches yet (reported, not failed). `skein trace ID`: a rule with what refers to it.
- markdownlint and cspell, as for any Markdown.
- The sites take `spec/` and `proposals/` from cesium when they build (`tools/take-spec.sh` of cesiumlang.org); a push to cesium that changes them starts the rebuild (`site.yml`). Never edit `cesiumlang.org/content/spec/` or `content/proposals/`: they are generated.
