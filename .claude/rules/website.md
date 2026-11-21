---
paths:
  - "cesiumlang.org/**"
---

# The website (cesiumlang.org)

- `quartz_repo/` and `src/quartz/` are locked: never edit them or move the submodule's commit. Customize Quartz from `src/` (the `custom-*` files, `quartz_overrides/`, `quartz.config.ts`, `quartz.layout.ts`).
- Build locally with `npm run build`, which works in a separate `build/` directory. Never run `npm run build:ci` locally: it builds inside `quartz_repo` and leaves files there. If `quartz_repo` shows changes, revert them and delete `public/` and `quartz/.quartz-cache/` there.
- Issues here are for site build problems and pages that are out of date with the language design; design questions go to cesiumlang/cesium.
- Reference pages explain by example; the specification (`content/spec/`) is normative and marks each rule Decided, Provisional or Open with the issue it comes from. Never write an undecided rule as decided.
