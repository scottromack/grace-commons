# GRACE lang migration — plan

2026-09-10. Replaces the order of work in `roadmap.md` debt #21; deleted once that carries it.

**Rewrite every spec in GRACE lang. Cut everything else hard.**

## Language

`GRACE-lang.md` is v0.27. Land v0.28 first: the review's eight changes, plus one — a declaration MAY cite its owner (§13), so a composition uses a constituent's term without restating it.

## Rewrite

One spec at a time. Obligations in Strict Caveman (§20), each with a label. Rationale in `WHY:`, short. Real examples. Terms one line each, the card's fields kept. Cut to about 30% of today's bytes; a target, not a gate.

Language only. Same obligations, same terms, same invariant numbers, same Ledger. A defect found on the way goes on the Ledger as an open line, fixed after. No inventory, no diff, no gate per spec, no parser yet — the rewrite fixes the shape, the parser reads it afterwards (debt #21, step ii).

Order:

1. Lease, Duplicate Prevention, Event Log — the language on three small atoms.
2. Recoverable Invocation, into `compositions/` under `draft`.
3. The other atoms.
4. Audit Trail.
5. The other compositions, each after the compositions it composes.

The linter runs, cut to the checks that read a controlled form: links, invariant counts, model present, count honesty, rests-on refs, status grammar and mirror, duplicate rows, term registry, Ledger, the banned words. The eight that read prose shape go off now — constituent calls, atomicity over audit, rebuild bound, recording-failure step, seal key, retry bit, signature alternation, step reference. They come back as queries on the parsed corpus, or not at all.

## After

The parser, on the rewritten corpus. Method docs, same treatment. `Claude outputs/` gone: every file to its home or deleted, git keeps the history.
