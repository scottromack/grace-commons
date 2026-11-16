# The stack Beacon is rendered on

Read 2026-11-16 (part 2 of `demo: Beacon's permissions are built from what is written, not patched`). The default render stack of the corpus (Execution Contract, *Database*; Scott 2026-10-12 "XTDB is the default render"; 2026-11-16 "Bun rocks"), pinned:

| Piece | Version | Why this way |
|---|---|---|
| Bun | 1.3.2, from npm's `bun` package | the `bun` on this Mac's PATH is an x86 binary and there is no Rosetta; the npm package installs the arm64 build |
| Hono | 4.13.19 | |
| postgres (npm) | 4.1.1 | XTDB's Postgres wire port is its primary API |
| XTDB | 2.2.0, in memory | published only as a container image; `stack/stack.sh install` takes the one layer that holds `xtdb.jar`, by digest, and checks its sha256, so no container runtime is needed |
| Java | Temurin 21.0.13 | the jar is class file version 65: Java 17 refuses it |

`bash stack/stack.sh install` then `bash stack/stack.sh start`, `bun test`, `bash stack/stack.sh stop`. Install and start took 18 seconds from nothing on 2026-11-16. macOS arm64 only so far.

Two facts the stack taught, for the render: a write over the wire binds every parameter with its type (`sql.typed(value, 25)` for text; an untyped one is refused), and an integer `_id` is read back as text. `tests/stack.test.ts` shows a write, a read and an earlier version of a record kept (Database 5).
