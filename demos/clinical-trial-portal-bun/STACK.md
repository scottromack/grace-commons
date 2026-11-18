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

More, from rendering the atoms: a query inside a write transaction is refused, so a guard is an `ASSERT` in the write's own transaction; a table and its columns must exist before a guard or read names them (`Store.declare`); and some ordinary words are reserved in XTDB SQL (`session` is one, so the table is `sessions`).

**In a container (Fly), 2026-11-18.** `Dockerfile`, `fly.toml` and `stack/start.sh` run the same pins on linux: XTDB's jar from `ghcr.io/xtdb/xtdb` by the index digest of 2.2.0 (`sha256:a6a42650...`), Temurin 21.0.13 (`eclipse-temurin:21.0.13_9-jre`), Bun 1.3.2 (`oven/bun:1.3.2-debian`), Hono and postgres by the exact versions in `package.json` (`bun install --production`). `start.sh` starts XTDB in memory with a 512 MB heap, waits for its health answer, then runs `src/main.ts`; the machine has 1 GB (the local run held 485 MB resident after signing in and opening five pages). Fly's builder built the image on 2026-11-18 (217 MB); it was not run before the deploy, so the deploy's own health check on `/login` is its first run on linux.
