# Grace bootstrap — read before you change anything here

This render is built from patterns, never edited by hand (Scott, 2026-11-16: "We don't hack code ever"). An agent working in this folder:

1. Never hand-edits generated code or a `.sdd` file. A wrong behaviour is a pattern to change: change the pattern in Grace Commons, or this app's own page, and rebuild.
2. Reads the intent here, in `.grace/`:
   - `todo.idd` — the app page, a copy of `library/apps/todo/index.md` at the commit `pins.tsv` names for it;
   - `pins.tsv` — the ten atoms the app pulls, each with the Grace Commons commit that last changed it and the file's SHA-256. A pulled atom is used only at its pin; a pin moves only by a rebuild.
3. Reads the target in `../todo.sdd` (the root spec: the platform, the UX and the existing systems) and the render's choices in `../CORNERS.md`.
4. Leaves `.specdd/`, `AGENTS.md` and `CLAUDE.md` as SpecDD's CLI writes them (`specdd init`); SpecDD's own rules there govern the `.sdd` contracts.

No `.sdd` file and no code exists yet: both come with the build (release 0.4), written by the render in the same pass as the code.
