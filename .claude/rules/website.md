---
paths:
  - "cesiumlang.org/**"
---

# The website (cesiumlang.org)

- The pages are Markdown in `content/`: relative links to `.md` files, `> [!warning] Title` callouts, a front matter with `title`, `tags` and `sortorder`. Do not edit `site/content/`, `site/assets/site-index.json` or `site/assets/img/`: `tools/zine` writes them from `content/`.
- Build with the devkit Zig: `zig build` (the site in `zig-out/public`), `zig build serve`, `zig build test`. The first build compiles Zine and takes minutes. Delete `zig-out`, `.zig-cache` and `zig-pkg` when done.
- Every push to `dev` and to `web/` branches is built at https://cesiumlang.dev by cesiumlang/cesiumlang.dev; cesiumlang.org is built from `main`. After each deploy, `deploy.yml` starts the build of the mirror at https://cesium.randyeckman.com (emanspeaks/cesium-site-mirror), whose `pages.yml` repeats its build steps: a build step changed in one is changed in the other.
- Issues here are for site build problems and pages that are out of date with the language design; design questions go to cesiumlang/cesium.
- Reference pages explain by example. The specification and the proposals are kept in cesiumlang/cesium (`spec/`, `proposals/`) and generated into `content/spec/` and `content/proposals/` by `tools/take-spec.sh` (cesiumlang/cesium#106): edit them there, never here. Never write an undecided rule as decided.
