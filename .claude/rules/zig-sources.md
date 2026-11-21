---
paths:
  - "**/*.zig"
  - "**/build.zig.zon"
---

# Zig sources

- Build with the Zig of the Cesium devkit (0.17.1): `cesium-src/.devkit/zig/zig` locally; CI fetches the devkit. Never the VS Code extension's Zig or another download.
- Four-space indentation, as `zig fmt` writes it; run `zig fmt --check` before committing.
- `const sysinfo = @import("builtin");`, never `builtin`; every `@import` is a `const` near the top of the file.
- Exact error sets with plain names; panic only for broken invariants (a doc comment says when a function panics); slices, not pointer plus length; the allocator is the first parameter; `try` allocation errors.
- A `switch` that maps tags to values has one prong per distinct value (`.a, .b => 1,`).
- Delete `.zig-cache` and `zig-out` you create when done: disk space is limited.
