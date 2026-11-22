---
paths:
  - "cesiumlang.org/**"
---

# The website (cesiumlang.org)

- The pages are Markdown in `content/`: relative links to `.md` files, `> [!warning] Title` callouts, a front matter with `title`, `tags` and `sortorder`. Do not edit `site/content/`, `site/assets/site-index.json` or `site/assets/img/`: `tools/zine` writes them from `content/`.
- Build with the devkit Zig: `zig build` (the site in `zig-out/public`), `zig build serve`, `zig build test`. The first build compiles Zine and takes minutes. Delete `zig-out`, `.zig-cache` and `zig-pkg` when done.
- Every push to `dev` and to `web/` branches is built at https://cesiumlang.dev by cesiumlang/cesiumlang.dev; cesiumlang.org is built from `main`.
- Issues here are for site build problems and pages that are out of date with the language design; design questions go to cesiumlang/cesium.
- Reference pages explain by example; the specification (`content/spec/`) is normative and marks each rule Decided, Provisional or Open with the issue it comes from. Never write an undecided rule as decided.
