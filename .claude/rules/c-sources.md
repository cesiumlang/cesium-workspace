---
paths:
  - "**/*.{c,h,cpp,hpp}"
---

# C and C++ sources

- Two-space indentation.
- Indent preprocessor directives where it helps readability; do not force them to column 0.
- In class definitions, indent the `public` and `private` keywords, and indent the members below them once more.
- Stage 0 and `libcsmir` (`cesium-src/bootstrap/`) follow the stage 0 C dialect, cesiumlang/cesium#10: valid as both C99 and C11, no compiler extensions, only the ISO C library, none of the banned functions (`include/cs_banned.h`), every `.c` file includes the common header. `tools/check-c-dialect.sh` and `tools/portable-c.sh` check it, as CI does.
