#!/usr/bin/env python3
"""Fixture tests for the linter's capability-provenance *use* checks (P, Q).

Why this file exists. P and Q were built by sweeping the corpus, and a check
built that way has a specific failure mode: it is easy to keep loosening the
trigger until the finding set matches the answer you already had in mind. That
is not verification, it is curve-fitting — and it costs the thing the linter
trades on, which is that a firing is worth reading.

So each check is pinned from both sides:

  * a NEGATIVE — the pattern that already does the right thing. If the check
    fires there, the check is wrong, because that pattern is the exemplar its
    own message points authors at. Chain of Custody Invariant 4 states the
    safety-plus-liveness split for P; Audit Trail states the rebuild's totality
    bound for Q.
  * POSITIVES — the patterns whose findings are routed open in their Lineage
    entries. If the check stops firing there, it has been loosened into
    uselessness or the finding was closed without updating this file. Either
    way someone should look.

This is the same discipline `tools/harness/isolate.mjs` applies to the formal
models: an invariant with no dedicated rejecting twin is not verified, it is
asserted. A check with no known-silent case is not precise, it is untested.

Run:  python3 tools/linter/test_checks.py [repo_root]
Exit: 0 all pinned expectations hold, 1 otherwise.
"""

from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from lint import (  # noqa: E402
    check_migration_seam,
    check_heading_standard,
    Pattern,
    check_atomicity_over_audit,
    check_rebuild_bound,
    check_recording_step,
    check_retry_bit,
    check_signature_alternation,
    check_step_reference,
    check_seal_key,
    check_ledger,
    check_stale_census,
    check_acceptance_surface,
    check_orphan_forthcoming,
    load_patterns,
)

# ── The motivating case, pinned SYNTHETICALLY ─────────────────────────────── #
# This started as a pin on two real corpus blocks and had to stop being one, and
# why is the useful part.
#
# P's first draft treated the word "modulo" as an acknowledgement marker.
# Resolve a Person's Data Rights carried a modulo-clause about a DIFFERENT
# boundary — its irreversible purge precursor — and that clause suppressed the
# finding on its Invariant 1, the claim the corpus survey had routed the day
# before. Capability-Backed Sharing lost a finding the same way. The check went
# silent on the two cases that motivated it, and a file-level pin would not have
# shown it: both patterns still fired at other sites, so the run looked healthy.
# A hedge word like "modulo" clusters around a pattern's most careful claims,
# because those are the ones an author qualifies — so a hedge-word suppressor is
# not randomly lossy, it is biased toward silencing the findings that matter
# most. Both sites it dropped were their pattern's declared formal-model subject.
#
# Both are now FIXED — restated 2026-08-27 — and that is the problem with pinning
# a regression to corpus text: the pin dies the moment the finding is repaired,
# which is the moment you most want the guard still standing. A perishable pin
# also creates a bad incentive, since the cheapest way to make it pass is to
# delete it. So the regression is pinned to a SYNTHETIC block instead, which
# encodes the bug rather than a victim of it and outlives every fix.
FIXTURE_MODULO_DECOY = """
## Composition-level invariants

- **Invariant 1 — Binding.** The record and its sealed Audit Trail event commit
  together or not at all. This holds *modulo* the inherited irreversible-purge
  contract, which governs a different boundary entirely.
"""
# The negative half: a block that does the real acknowledgement must stay silent.
FIXTURE_ACKNOWLEDGED = """
## Composition-level invariants

- **Invariant 1 — Binding.** The record and its sealed Audit Trail event commit
  together or not at all — except that they do not: an appended event cannot be
  withdrawn, so the honest claim therefore splits into safety and liveness.
"""


# Q's synthetic pair, added when its class was half-landed and its corpus floor
# set began emptying — the same perishability that forced P's pins synthetic.
# Written as SINGLE LINES on purpose. The check's trigger is line-scoped (see the
# REBUILD_CLAUSE comment in lint.py), which is a documented recall gap, and these
# fixtures follow the corpus's actual convention rather than papering over it.
# The gap was found BY this fixture — the first draft wrapped across lines and did
# not fire — which is the argument for synthetic fixtures in miniature: a
# corpus-only test cannot show you a shape the corpus does not happen to contain.
FIXTURE_Q_UNBOUNDED = (
    "- **`thing_to_other`** — a map. **Contract classification: derived index.** "
    "*Rebuild procedure:* traverse the Audit Trail for `thing.happened` events "
    "and take `{a, b}` from each payload, so the binding facts are immutable "
    "audit content and the rebuild is total.\n"
)
FIXTURE_Q_BOUNDED = (
    "- **`thing_to_other`** — a map. **Contract classification: derived index.** "
    "*Rebuild procedure:* traverse the Audit Trail for `thing.happened` events "
    "and take `{a, b}` from each payload — bounded by the audit instance's "
    "horizon, past which the payload is destroyed and these entries are not "
    "rebuildable.\n"
)


def check_q_synthetic(problems: list[str]) -> None:
    """Q must fire on an unbounded payload-sourced rebuild and stay silent on one
    that states its bound. Neither case depends on any corpus file, so the guard
    survives the class closing — which is the state a closed class reaches."""
    for name, text, want_fire in (
        ("FIXTURE_Q_UNBOUNDED", FIXTURE_Q_UNBOUNDED, True),
        ("FIXTURE_Q_BOUNDED", FIXTURE_Q_BOUNDED, False),
    ):
        pat = Pattern(path=Path(f"synthetic/{name}.md"), text=text,
                      invariant_count=1, grounded=False)
        fired = bool(check_rebuild_bound({pat.path: pat}))
        if fired != want_fire:
            problems.append(
                f"Q-rebuild-bound: {name} expected "
                f"{'a firing' if want_fire else 'silence'} and got the opposite. "
                + ("The trigger has been narrowed past usefulness."
                   if want_fire else
                   "A bound marker no longer suppresses — or, worse, a marker was "
                   "added that signals care rather than stating the bound, which "
                   "is the P-atomic-audit `modulo` failure in a new place.")
            )


def check_synthetic(problems: list[str]) -> None:
    """The check must fire on a hedge-word decoy and stay silent on a real
    acknowledgement. Neither case depends on any corpus file."""
    for name, text, want_fire in (
        ("FIXTURE_MODULO_DECOY", FIXTURE_MODULO_DECOY, True),
        ("FIXTURE_ACKNOWLEDGED", FIXTURE_ACKNOWLEDGED, False),
    ):
        pat = Pattern(path=Path(f"synthetic/{name}.md"), text=text,
                      invariant_count=1, grounded=False)
        fired = bool(check_atomicity_over_audit({pat.path: pat}))
        if fired != want_fire:
            problems.append(
                f"P-atomic-audit: {name} expected "
                f"{'a firing' if want_fire else 'silence'} and got the opposite. "
                + ("A suppressor has gone generic — check what the block is being "
                   "credited with acknowledging; a hedge word is not an "
                   "acknowledgement." if want_fire else
                   "The check no longer recognizes a genuine safety-plus-liveness "
                   "restatement, so it now fires on patterns that did the right "
                   "thing.")
            )


# ── Corpus pins ───────────────────────────────────────────────────────────── #
# Pinned by SITE, not by file, and this distinction is the whole reason the
# entry exists. P's first draft treated the word "modulo" as an acknowledgement
# marker. Resolve a Person's Data Rights carries a modulo-clause about a
# DIFFERENT boundary — its irreversible purge precursor — and that clause then
# suppressed the finding on Invariant 1, which is the claim the corpus survey
# had routed the day before. The check went silent on the case that motivated
# it, and a file-level pin would not have shown it: the pattern still fired at
# three other sites, so the run looked healthy.
#
# Pinning a substring of the enclosing block survives renumbering, which line
# numbers do not.
# BOTH sites the regression silenced are pinned, and which two they are is the
# point. A hedge word like "modulo" clusters around a pattern's most careful
# claims, because those are the ones an author qualifies — so a hedge-word
# suppressor is not randomly lossy, it is biased toward silencing the findings
# that matter most. The two it dropped here are each their pattern's declared
# formal-model subject.
# Empty by design, and it should stay empty: both motivating sites are repaired.
# The regression they exposed is guarded by check_synthetic() above, which no
# fix can retire.
P_MOTIVATING_SITES: list[tuple[str, str]] = []
# CLOSED 2026-08-27 — Resolve a Person's Data Rights. Its Invariant 1 was the
# other motivating site, and it is now restated in safety-plus-liveness form, so
# the check is correctly silent there and the pin is retired rather than
# weakened. Retiring a pin is the only legitimate reason a positive disappears,
# and it belongs in the same change as the fix: a pin removed without the
# corresponding restatement is how a baseline quietly rots.
P_RETIRED_SITES = [
    ("resolve-a-persons-data-rights", "Invariant 1 — Request", "restated 2026-08-27"),
    ("capability-backed-sharing", "Invariant 2 — Disclosure-accountability",
     "protocol repair 2026-08-27 — the append moved out of the host transaction"),
    ("propagate-consent-revocation-downstream", "Invariant 3 — Revocation propagation",
     "restated 2026-08-27 — class closed; P promoted to gating"),
]

# ── P-atomic-audit ─────────────────────────────────────────────────────────── #
# Silent: the exemplar. Chain of Custody's Invariant 4 splits the claim into
# safety ("no *unsurfaced* orphan") and liveness (detection plus compensation),
# having first said that synchronous rollback is unavailable and the orphan
# state is therefore reachable. Nothing to flag.
P_SILENT = {"chain-of-custody"}
# Firing: the three routed instances (roadmap.md debt #19, pre-campaign survey).
# Resolve a Person's Data Rights was here until 2026-08-27; its four sites closed
# when Invariant 1 was restated (debt #19 step (iii), atomicity class). It must
# now stay OUT of this set — the `exact` comparison below turns that into a real
# assertion rather than a deletion, so a regression that reopened it would be
# reported as an unpinned firing.
# EMPTY, AND THAT IS THE ASSERTION. All three instances of the class closed on
# 2026-08-27 — Resolve a Person's Data Rights and Propagate Consent Revocation
# Downstream by restatement, Capability-Backed Sharing by protocol repair — and P
# now fires zero times corpus-wide, which is why it was promoted from advisory to
# gating in lint.py.
#
# The `exact` comparison below is what makes an empty set do work: ANY firing is
# now reported as an unpinned pattern, so a newly introduced instance fails this
# test rather than quietly joining a backlog. An empty pin set is not an absence
# of coverage here; the coverage moved to check_synthetic(), which does not depend
# on the corpus containing a broken pattern and therefore survives the class being
# clean — which is the state a closed class is supposed to reach.
P_FIRING: set[str] = set()

# ── Q-rebuild-bound ───────────────────────────────────────────────────────── #
# Silent: the exemplar. Audit Trail carries "Bound on the rebuild's totality,
# stated rather than assumed" and then states the bound and why it suffices —
# which is the right thing to do in the pattern that performs the destruction.
Q_SILENT = {"audit-trail"}
# The polarity false positive, pinned by SITE. Privileged Access Provisioning's
# `request_to_capability` rebuild reads the Capability store's own immutable
# records, not an event payload — it is outside this class. Q fired on it because
# the clause contains the phrase "audit event data" inside a sentence saying the
# raw token appears in NO audit event data: the check read a negation as an
# assertion. Fixed 2026-08-27 by the retention-horizon classification sweep.
#
# Pinned at the site rather than the file, and that distinction is the same one
# P-atomic-audit paid for: Privileged Access Provisioning has two OTHER genuine
# firings, so a file-level pin would pass whether or not this one is fixed, and
# the run would look healthy either way.
Q_NEGATED_SITES = [
    ("privileged-access-provisioning", "request_to_capability"),
]
# Firing: at least these. Not an exhaustive census — the check has a recorded
# recall gap (see the docblock in lint.py), so this set is a floor.
# Retired as their instances close (methodology debt #19, the retention-horizon
# class): Defensible Retention and Propagate Consent Revocation Downstream, both
# 2026-08-27. This is a FLOOR rather than an `exact` set, so a retirement is a
# deletion here — which is exactly the perishability that made P-atomic-audit's
# corpus pins untrustworthy, and Q will need the same synthetic treatment when
# its class closes and this set empties. Until then, keep the reason in the
# comment so a retirement cannot pass as a loosened check.
# EMPTY as of 2026-08-27: every site Q can see has been treated.
#
# THIS IS NOT THE CLASS CLOSING, and the distinction is the reason this comment
# exists rather than a promotion. Q's trigger keys on the literal
# `*Rebuild procedure:*` marker and is line-scoped (see lint.py), so it has a
# recorded recall gap — two known instances of this class are invisible to it:
# Preference-Aware Notification Fanout, found by the pre-campaign survey by
# reading, and Forensic Recovery's AP-F1, routed by a gate. **A check going
# silent measures the check's reach, not the corpus's health**, which is the same
# lesson the 2026-06-08 capability-provenance rescan taught when it found zero
# undeclared dependencies by sweeping the one surface the rule then named.
#
# So this set stays a floor rather than becoming `exact`, and Q stays advisory,
# until those two land. Promotion and the switch to `exact` happen together, as
# they did for P — at which point the synthetic fixtures above are what carries
# the regression coverage, since there will be no corpus positive left to pin.
Q_FIRING_AT_LEAST: set[str] = set()


def stems(findings) -> set[str]:
    return {f.path.stem for f in findings}


def _block_at(text: str, line: int) -> str:
    """The blank-line-delimited block containing a 1-indexed line."""
    lines = text.split("\n")
    i = max(0, line - 1)
    start = i
    while start > 0 and lines[start - 1].strip():
        start -= 1
    end = i
    while end + 1 < len(lines) and lines[end + 1].strip():
        end += 1
    return "\n".join(lines[start:end + 1])


def check_not_firing_at(patterns, findings, sites, code) -> list[str]:
    """A check must stay silent at these specific sites. Pinned by site, not by
    file, because a file with other genuine firings hides a site-level regression
    completely."""
    problems: list[str] = []
    for stem, marker in sites:
        pat = next((p for p in patterns.values() if p.path.stem == stem), None)
        if pat is None:
            continue
        for f in findings:
            if f.path.stem != stem:
                continue
            if marker in _block_at(pat.text, f.line):
                problems.append(
                    f"{code}: fires on the {stem} block containing {marker!r}, "
                    f"which is NOT an instance of this class — its rebuild reads a "
                    f"constituent's own records, and the phrase that matched sits "
                    f"inside a clause DENYING a payload read. The polarity guard "
                    f"has regressed; check what the match is being read as."
                )
    return problems


def check_motivating_sites(patterns, findings) -> list[str]:
    """P must fire on the specific blocks that motivated the check, not merely
    somewhere in those files."""
    problems: list[str] = []
    for stem, marker in P_MOTIVATING_SITES:
        pat = next((p for p in patterns.values() if p.path.stem == stem), None)
        hit = pat is not None and any(
            f.path.stem == stem and marker in _block_at(pat.text, f.line)
            for f in findings
        )
        if not hit:
            problems.append(
                f"P-atomic-audit: does not fire on the {stem} block containing "
                f"{marker!r} — one of the two cases the check was built for, and "
                f"that pattern's own formal-model subject. A suppressor has gone "
                f"generic again; check what the block is being credited with "
                f"acknowledging."
            )
    return problems


# --------------------------------------------------------------------------- #
# R-ledger synthetic fixtures — the grammar and the contradictions it refuses.
# One well-formed page must be silent; each malformed page must fire with the
# named code. None depends on any corpus file.
# --------------------------------------------------------------------------- #

def _ledger_page(status: str, ledger_status: str, open_lines: str,
                 decisions: str = "- **2026-08-26 — Title.** *Chose:* a. *Over:* b. *Because:* c.") -> str:
    return f"""# Synthetic

## Status

`{status}` — derived.

## Ledger

```
status: {ledger_status}
formal: verified — synthetic.tla + 1 twin, 2026-06-03
last gate: 2026-08-26 — fresh reader — clean

open:{open_lines}
```

## Decisions

{decisions}
"""


R_FIXTURES = [
    # name, page text, code expected (None = must be silent)
    ("R_CLEAN", _ledger_page(
        "partially resolved", "partially resolved",
        "\n- 2026-08-27-a · foundational · step 4 · x is unset → set it"), None),
    ("R_CLEAN_NONE", _ledger_page(
        "grounded on Final Critique 4 — 2026-06-04",
        "grounded on Final Critique 4 — 2026-06-04", " none"), None),
    ("R_GROUNDED_OPEN", _ledger_page(
        "grounded on Final Critique 4 — 2026-06-04",
        "grounded on Final Critique 4 — 2026-06-04",
        "\n- 2026-08-27-a · foundational · step 4 · x is unset → set it"),
     "R-ledger-grounded-open"),
    ("R_STATUS_MISMATCH", _ledger_page(
        "partially resolved", "grounded on Final Critique 4 — 2026-06-04", " none"),
     "R-ledger-status"),
    ("R_FOUR_FIELDS", _ledger_page(
        "partially resolved", "partially resolved",
        "\n- 2026-08-27-a · foundational · x is unset → set it"), "R-ledger-grammar"),
    ("R_NO_ARROW", _ledger_page(
        "partially resolved", "partially resolved",
        "\n- 2026-08-27-a · foundational · step 4 · x is unset, set it"), "R-ledger-grammar"),
    ("R_BAD_CLASS", _ledger_page(
        "partially resolved", "partially resolved",
        "\n- 2026-08-27-a · blocking · step 4 · x is unset → set it"), "R-ledger-grammar"),
    ("R_DUP_ID", _ledger_page(
        "partially resolved", "partially resolved",
        "\n- 2026-08-27-a · refining · step 4 · x → y\n- 2026-08-27-a · refining · step 5 · x → y"),
     "R-ledger-grammar"),
    ("R_GATE_ID", _ledger_page(
        "partially resolved", "partially resolved",
        "\n- FC7-F2 · foundational · step 4 · x is unset → set it"), "R-ledger-grammar"),
    ("R_EMPTY_OPEN", _ledger_page(
        "partially resolved", "partially resolved", ""), "R-ledger-grammar"),
    ("R_DECISION_FORM", _ledger_page(
        "partially resolved", "partially resolved", " none",
        decisions="- **2026-08-26 — Title.** We chose a because c."), "R-decisions-grammar"),
    ("R_DECISIONS_MISSING", _ledger_page(
        "partially resolved", "partially resolved", " none").split("## Decisions")[0],
     "R-decisions-missing"),
    ("R_LEDGER_MISSING", "# Synthetic\n\n## Status\n\n`partially resolved` — see the Ledger.\n",
     "R-ledger-missing"),
]


# ── S-recording-step / T-seal-key ─────────────────────────────────────────── #
# Landed 2026-08-29 ADVISORY, the day the rules they police were frozen in
# pressure-testing.md, so that every site the sweep closes is attributable to a
# rule that already covered it. Synthetic from the start — the lesson P paid for
# is that a corpus pin dies when the finding is fixed, and both of these are
# expected to be fixed within days. The corpus sets below are FLOORS recorded at
# landing; they shrink as the sweep runs and are switched to `exact` (and the
# codes removed from lint.py's ADVISORY_CODES) in the change that closes the last
# site.

_S_HEAD = "# Synthetic\n\n## Composes\n\n- [Audit Trail](../compositions/audit-trail.md)\n\n"

# fires: the substrate's arm transcribed bare, on the left of the arrow.
FIXTURE_S_BARE = _S_HEAD + (
    "3. `AuditTrail.record_action(...)` → `event_id`. Rejection mapping: "
    "`invalid-credential` → `rejected(invalid-credential)`; "
    "`recording-failure` → `rejected(recording-failure)`, the one retryable arm.\n"
)
# silent: the same mapping carrying the step.
FIXTURE_S_STEPPED = _S_HEAD + (
    "3. `AuditTrail.record_action(...)` → `event_id`. Rejection mapping: "
    "`invalid-credential` → `rejected(invalid-credential)`; "
    "`recording-failure(step)` → `rejected(recording-failure(step))` — on "
    "step-4 the event is appended; read the id back.\n"
)
# silent: a bare token that is NOT a transcription — the composition's own
# signature block naming its own code over a non-substrate write.
FIXTURE_S_SIGNATURE = _S_HEAD + (
    "- **[Confirm]** — (Projected contract: `confirm(token) → ok | "
    "rejected(not-known | recording-failure)`) — the journal refused.\n"
)
# silent: a composition that does not compose Audit Trail at all — nothing
# it maps can be the substrate's arm.
# silent: a bare token that is a PEER composition's own arm — Multi-Party
# Approval declares `recording-failure` bare at its boundary, so a composer
# mapping it is correct. The substrate call is absent from the line; that is
# the discriminator (found 2026-08-29 on Privileged Access Provisioning).
FIXTURE_S_PEER = _S_HEAD + (
    "3. `MultiPartyApproval.approve_step(actor_ref, credential, chain_id, step_id)` "
    "→ propagates `not-pending` unchanged; its `recording-failure` → "
    "`recording-failure` (the substrate's own recovery owns that partial).\n"
)
FIXTURE_S_NO_AUDIT = (
    "# Synthetic\n\n## Composes\n\n- [Journal](../atoms/journal.md)\n\n"
    "3. Map `recording-failure` → `rejected(recording-failure)`.\n"
)


def check_s_synthetic(problems: list[str]) -> None:
    for name, text, want_fire in (
        ("FIXTURE_S_BARE", FIXTURE_S_BARE, True),
        ("FIXTURE_S_STEPPED", FIXTURE_S_STEPPED, False),
        ("FIXTURE_S_SIGNATURE", FIXTURE_S_SIGNATURE, False),
        ("FIXTURE_S_NO_AUDIT", FIXTURE_S_NO_AUDIT, False),
        ("FIXTURE_S_PEER", FIXTURE_S_PEER, False),
    ):
        pat = Pattern(path=Path(f"synthetic/compositions/{name}.md"), text=text,
                      invariant_count=1, grounded=False)
        fired = bool(check_recording_step({pat.path: pat}))
        if fired != want_fire:
            problems.append(
                f"S-recording-step: {name} expected "
                f"{'a firing' if want_fire else 'silence'} and got the opposite."
            )


# fires: the map subscripted by an id; and the phrase form.
FIXTURE_T_SUBSCRIPT = (
    "5. `AuditTrail.verify_record(event_id, original_event_payloads[event_id])` "
    "→ record the outcome.\n"
)
FIXTURE_T_PHRASE = (
    "`original_event_payloads` is a map keyed by `entry_id` to the payload.\n"
)
# silent: the exemplar shape — keyed by sequence number, read over a range.
FIXTURE_T_POSITION = (
    "`original_event_payloads` is a map keyed by the audit log's "
    "**`sequence_number`** to the byte-exact payload; step 3c assembles "
    "`original_event_payloads[lo]` .. `original_event_payloads[hi]` and "
    "compares against `original_event_payloads[n]`.\n"
)


def check_t_synthetic(problems: list[str]) -> None:
    for name, text, want_fire in (
        ("FIXTURE_T_SUBSCRIPT", FIXTURE_T_SUBSCRIPT, True),
        ("FIXTURE_T_PHRASE", FIXTURE_T_PHRASE, True),
        ("FIXTURE_T_POSITION", FIXTURE_T_POSITION, False),
    ):
        pat = Pattern(path=Path(f"synthetic/compositions/{name}.md"), text=text,
                      invariant_count=1, grounded=False)
        fired = bool(check_seal_key({pat.path: pat}))
        if fired != want_fire:
            problems.append(
                f"T-seal-key: {name} expected "
                f"{'a firing' if want_fire else 'silence'} and got the opposite."
            )


# Corpus floors at landing (2026-08-29). Silent: the two exemplars the rules
# point authors at. Firing: the baseline the sweep is expected to empty.
S_SILENT = {"login", "chain-of-custody"}
# Retired as the sweep closes them (one line per retirement, with the date, so
# a retirement cannot pass as a loosened check): external-onboarding 2026-08-29;
# propagate-consent-revocation-downstream 2026-08-29; immutable-transaction-
# ledger 2026-08-29; privileged-access-provisioning 2026-08-29 (a false
# positive — the peer-arm case above — not a fix); capability-backed-sharing
# 2026-08-29; actor-suspension 2026-08-29.
# EMPTY as of 2026-08-29, when the last site closed. S was promoted to GATING
# in the same change and this set switched to `exact`; the regression coverage
# lives in check_s_synthetic(), which needs no corpus positive to exist.
S_FIRING: set[str] = set()
T_SILENT = {"chain-of-custody", "forensic-recovery"}
# EMPTY as of 2026-08-29, when Immutable Transaction Ledger's [Verify Ledger]
# was re-keyed by sequence_number — the one site the check ever saw. T was
# promoted to GATING in the same change and this set switched to `exact`, so
# any firing is reported as an unpinned pattern; the regression coverage lives
# in check_t_synthetic(), which needs no corpus positive to exist.
T_FIRING: set[str] = set()


# U-retry-bit — landed 2026-08-30 ADVISORY (pressure-testing.md §A composition's
# own rejection arm carries the retry bit, frozen the same day). Synthetic from
# the start, like S and T. The corpus set below is a FLOOR at landing and is
# switched to `exact` in the change that closes the last site.
_U_HEAD = ("# Synthetic\n\n## Composes\n\n- [Audit Trail](../compositions/audit-trail.md)"
           "\n\n#### `do_thing`\n\n")
# fires: one bare token before the commit (step 2) and one after it (step 4).
FIXTURE_U_STRADDLE = _U_HEAD + (
    "1. Validate. Failure → `rejected(invalid-request)`. Stop.\n"
    "2. `AuditTrail.record_action(...)` → `event_id`; `recording-failure(step-2 | step-3)` "
    "→ `rejected(recording-failure)`. Stop.\n"
    "3. `Store.commit(record_id, now)` → `committed`.\n"
    "4. `AuditTrail.record_action(...)` → `event_id`; `recording-failure(step-2 | step-3)` "
    "→ `rejected(recording-failure)`; the orphan is the scan's.\n"
)
# silent: the same two landings carrying the position.
FIXTURE_U_POSITIONED = _U_HEAD + (
    "1. Validate. Failure → `rejected(invalid-request)`. Stop.\n"
    "2. `AuditTrail.record_action(...)` → `event_id`; `recording-failure(step-2 | step-3)` "
    "→ `rejected(recording-failure(intent))`. Stop.\n"
    "3. `Store.commit(record_id, now)` → `committed`.\n"
    "4. `AuditTrail.record_action(...)` → `event_id`; `recording-failure(step-2 | step-3)` "
    "→ `rejected(recording-failure(outcome))`; the orphan is the scan's.\n"
)
# silent: two bare landings, both before the commit — one disposition.
FIXTURE_U_BOTH_BEFORE = _U_HEAD + (
    "1. `Store.read(record_id)` → record; absent → `rejected(not-known)`.\n"
    "2. `AuditTrail.record_action(...)` → `event_id`; `recording-failure(step-2 | step-3)` "
    "→ `rejected(recording-failure)`. Stop.\n"
    "3. `AuditTrail.record_action(...)` → `event_id`; `recording-failure(step-2 | step-3)` "
    "→ `rejected(recording-failure)`. Stop.\n"
    "4. `Store.commit(record_id, now)` → `committed`.\n"
)


def check_u_synthetic(problems: list[str]) -> None:
    for name, text, want_fire in (
        ("FIXTURE_U_STRADDLE", FIXTURE_U_STRADDLE, True),
        ("FIXTURE_U_POSITIONED", FIXTURE_U_POSITIONED, False),
        ("FIXTURE_U_BOTH_BEFORE", FIXTURE_U_BOTH_BEFORE, False),
    ):
        pat = Pattern(path=Path(f"synthetic/compositions/{name}.md"), text=text,
                      invariant_count=1, grounded=False)
        fired = bool(check_retry_bit({pat.path: pat}))
        if fired != want_fire:
            problems.append(
                f"U-retry-bit: {name} expected "
                f"{'a firing' if want_fire else 'silence'} and got the opposite."
            )


# --- V-signature-alternation ------------------------------------------------
# Both directions, because a checker that only ever sees its own defect proves
# nothing: the wrapped and nested cases are the ones a naive rule breaks on.
_V_HEAD = "---\ntitle: T\n---\n\n## Composition logic\n\n#### `op`\n\n"

# fires: two alternatives on consecutive lines with no separator.
FIXTURE_V_UNSEPARATED = _V_HEAD + (
    "```\nop(a) →\n  v\n | rejected(\n   invalid-request\n"
    "   invalid-credential\n  | party-not-known\n  )\n```\n"
)
# silent: the same block, separated.
FIXTURE_V_SEPARATED = _V_HEAD + (
    "```\nop(a) →\n  v\n | rejected(\n   invalid-request\n"
    "  | invalid-credential\n  | party-not-known\n  )\n```\n"
)
# silent: one line, several alternatives.
FIXTURE_V_INLINE = _V_HEAD + (
    "```\nop(a) → v | rejected(not-open | recording-failure(outcome))\n```\n"
)
# silent: nested groups spanning lines — the case a depth-blind rule breaks on.
FIXTURE_V_NESTED = _V_HEAD + (
    "```\nop(a) →\n  v\n | rejected(\n      invalid-credential\n"
    "    | enrollment-failed(invalid-request | storage-failure)\n"
    "    | recording-failure(intent | outcome)\n    )\n```\n"
)
# silent, and this is the fixture that pins the depth logic: a nested group
# SPANNING lines, whose continuation does not start with `|`. A depth-blind
# rule flags `invalid-request` here; the earlier nested fixture does not catch
# that, because its groups each sit on one line and are separated anyway.
FIXTURE_V_NESTED_MULTILINE = _V_HEAD + (
    "```\nop(a) \u2192\n  v\n | rejected(\n      invalid-credential\n"
    "    | recording-failure(refusal,\n        constituent_code)\n"
    "    | not-open\n    )\n```\n"
)


# --- W-step-reference -------------------------------------------------------
_W_BODY = (
    "---\ntitle: T\n---\n\n## Composition logic\n\n"
    "#### `reconcile`\n\n1. One.\n2. Two.\n3. Three.\n\n"
    "#### `close`\n\n1. A.\n2. B.\n\n"
)
# silent: every reference resolves.
FIXTURE_W_RESOLVES = _W_BODY + "See [Reconcile] step 3 and step 2 of [Close].\n"
# fires: past the last step the action declares.
FIXTURE_W_DANGLING = _W_BODY + "See [Reconcile] step 5.\n"
# fires: the other reference form.
FIXTURE_W_DANGLING_OF = _W_BODY + "See step 9 of [Close].\n"
# silent: an action this page does not define is another page's business.
FIXTURE_W_FOREIGN = _W_BODY + "See [Some Other Thing] step 7.\n"


def check_w_synthetic(problems: list[str]) -> None:
    for name, text, want_fire in (
        ("FIXTURE_W_RESOLVES", FIXTURE_W_RESOLVES, False),
        ("FIXTURE_W_DANGLING", FIXTURE_W_DANGLING, True),
        ("FIXTURE_W_DANGLING_OF", FIXTURE_W_DANGLING_OF, True),
        ("FIXTURE_W_FOREIGN", FIXTURE_W_FOREIGN, False),
    ):
        pat = Pattern(path=Path(f"synthetic/compositions/{name}.md"), text=text,
                      invariant_count=1, grounded=False)
        fired = bool(check_step_reference({pat.path: pat}))
        if fired != want_fire:
            problems.append(
                f"W-step-reference: {name} expected "
                f"{'a firing' if want_fire else 'silence'} and got the opposite."
            )


def check_v_synthetic(problems: list[str]) -> None:
    for name, text, want_fire in (
        ("FIXTURE_V_UNSEPARATED", FIXTURE_V_UNSEPARATED, True),
        ("FIXTURE_V_SEPARATED", FIXTURE_V_SEPARATED, False),
        ("FIXTURE_V_INLINE", FIXTURE_V_INLINE, False),
        ("FIXTURE_V_NESTED", FIXTURE_V_NESTED, False),
        ("FIXTURE_V_NESTED_MULTILINE", FIXTURE_V_NESTED_MULTILINE, False),
    ):
        pat = Pattern(path=Path(f"synthetic/compositions/{name}.md"), text=text,
                      invariant_count=1, grounded=False)
        fired = bool(check_signature_alternation({pat.path: pat}))
        if fired != want_fire:
            problems.append(
                f"V-signature-alternation: {name} expected "
                f"{'a firing' if want_fire else 'silence'} and got the opposite."
            )


# Corpus floor at landing (2026-08-30): the ten actions across five patterns
# the survey measured. Silent: Login and Defensible Retention, whose actions
# already carry the position at their boundary.
U_SILENT = {"login", "defensible-retention"}
# Retired as the sweep closes them (one line per retirement, with the date):
# chain-of-custody 2026-08-30; forensic-recovery 2026-08-30;
# immutable-transaction-ledger 2026-08-30; capability-backed-sharing
# 2026-08-30; customer-onboarding 2026-08-30.
# EMPTY as of 2026-08-30, when the last site closed. U was promoted to GATING
# in the same change and this set switched to `exact`; the regression coverage
# lives in check_u_synthetic(), which needs no corpus positive to exist.
U_FIRING: set[str] = set()


def check_r_synthetic(problems: list[str]) -> None:
    for name, text, want in R_FIXTURES:
        pat = Pattern(path=Path(f"synthetic/{name}.md"), text=text,
                      invariant_count=1, grounded=False)
        codes = {f.code for f in check_ledger({pat.path: pat})}
        if want is None and codes:
            problems.append(f"R-ledger: {name} should be silent; fired {sorted(codes)}")
        elif want is not None and want not in codes:
            problems.append(f"R-ledger: {name} should fire {want}; got {sorted(codes) or 'nothing'}")


# ── W-stale-census, both readings, pinned synthetically ───────────────────── #
# The count reading was built at council read 33 against hand-written family
# counts and compares only the counts somebody already wrote down. The list
# reading was added at council read 63, when `Reconciliation` crossed Standard
# label 4's threshold of three in silence because §18 named it nowhere — the
# census list being the second hand-census, which is read 58's lesson one layer
# out. Pinned without a victim: a throwaway grammar and two throwaway patterns,
# so the fixtures cannot die when a corpus family's count moves.
CENSUS_GRAMMAR = """### 18. Candidate Forms

NOTE:
Also watched, and counted: a label family recurring across specs outside the standard set: {listing}.

Terms › `standard label family`: `Identity` (what identifies an instance) | `Invariant` (a property of every reachable state).
"""

CENSUS_PATTERN = """Terms › `qualifiers`: `migrated` — rewritten in GRACE lang v0.40 (2026-09-14).

```text
{family} 1: The composition MUST stand.
Invariant 1.1: The composition MUST stand.
```
"""


def check_census_synthetic(problems: list[str]) -> None:
    import tempfile

    def run(listing: str, families: list[tuple[str, str]]) -> set[str]:
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            (root / "GRACE-lang.md").write_text(
                CENSUS_GRAMMAR.format(listing=listing), encoding="utf-8")
            pats = {}
            for stem, fam in families:
                path = root / f"{stem}.md"
                text = CENSUS_PATTERN.format(family=fam)
                pats[path] = Pattern(path=path, text=text,
                                     invariant_count=1, grounded=False)
            return {f.code + "|" + f.message for f in check_stale_census(root, pats)}

    three = [("a", "Ghost"), ("b", "Ghost"), ("c", "Ghost")]
    # (1) a family at three the list does not name must fire
    got = run("", three)
    if not any("names no `Ghost`" in m for m in got):
        problems.append("W-stale-census: a family at three specs the watch list "
                        "does not name did not fire — the list reading is dead")
    # (2) the same family, named with the right count, must stay silent
    got = run("", [("a", "Ghost"), ("b", "Ghost")])
    got_named = {m for m in got if "Ghost" in m}
    if got_named:
        problems.append("W-stale-census: fired on a family at two specs — "
                        "below Standard label 4's threshold, so it is not a candidate")
    # (3) a standard family at three must stay silent: the grammar owns it and
    #     it is not a promotion candidate
    got = run("", [("a", "Identity"), ("b", "Identity"), ("c", "Identity")])
    if any("Identity" in m for m in got):
        problems.append("W-stale-census: fired on a standard label family — "
                        "the grammar owns those and they never stand as candidates")
    # (4) the count reading still works: a listed family whose count is wrong
    got = run("`Wraith` (9)", [("a", "Wraith"), ("b", "Wraith")])
    if not any("`Wraith` is in 9 specs" in m for m in got):
        problems.append("W-stale-census: a listed family with a stale count did "
                        "not fire — the count reading is dead")


# ── M-orphan-forthcoming, pinned synthetically ─────────────────── #
# A migrated spec that delegates to a `*(forthcoming)*` pattern the roadmap does
# not carry is pointing at a home nobody has written down. Council read 68 found
# sixteen such names at once, so the shapes are pinned without a victim -- a
# corpus pin would go stale the moment one of them lands.

ORPHAN_SPEC = """# Ghost Pattern

{body}

## Terms

Terms › `qualifiers`: {qualifier}
"""


def check_orphan_synthetic(problems: list[str]) -> None:
    import tempfile

    def run(body: str, roadmap: str, qualifier: str = "`migrated` — rewritten in GRACE lang v0.41 (2026-09-15).") -> set[str]:
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            (root / "roadmap.md").write_text(roadmap, encoding="utf-8")
            path = root / "ghost.md"
            text = ORPHAN_SPEC.format(body=body, qualifier=qualifier)
            pats = {path: Pattern(path=path, text=text,
                                  invariant_count=1, grounded=False)}
            return {f.message for f in check_orphan_forthcoming(root, pats)}

    # (1) a named forthcoming the roadmap does not carry must fire
    got = run("A **Spectre Ledger** *(forthcoming)* owns the rest.", "# Roadmap\n")
    if not any("Spectre Ledger" in m for m in got):
        problems.append("M-orphan-forthcoming: a named forthcoming with no roadmap "
                        "row did not fire — the roadmap reading is dead")
    # (2) the same name, carried by the roadmap, must stay silent
    got = run("A **Spectre Ledger** *(forthcoming)* owns the rest.",
              "# Roadmap\n\n- **Spectre Ledger** — a row.\n")
    if got:
        problems.append("M-orphan-forthcoming: fired on a name the roadmap carries "
                        "— a listed home is not an orphan")
    # (3) a *linked* forthcoming is D-stale-forthcoming's, never this check's
    got = run("See [Spectre Ledger](./atoms/spectre-ledger.md) *(forthcoming)*.",
              "# Roadmap\n")
    if got:
        problems.append("M-orphan-forthcoming: fired on a linked forthcoming — "
                        "those are check_stale_forthcoming's and would double-report")
    # (4) an unmigrated spec is exempt: the whitelist rule is the corpus's
    got = run("A **Spectre Ledger** *(forthcoming)* owns the rest.", "# Roadmap\n",
              qualifier="none declared.")
    if got:
        problems.append("M-orphan-forthcoming: fired on an unmigrated spec — "
                        "only a migrated spec is held to the language's rules")
    # (5) a bare single word before the marker is a fragment, not a pattern name
    got = run("An audit **Log** *(forthcoming)* owns the rest.", "# Roadmap\n")
    if got:
        problems.append("M-orphan-forthcoming: fired on a single-word fragment — "
                        "a pattern name carries a space or a hyphen")


# ── Y-acceptance-surface, pinned synthetically ────────────────────────────── #
# Presence became mandatory at council read 65, after three atoms took the
# then-optional Generation acceptance section by saying nothing and eleven
# compositions rested checks on them. Two shapes satisfy it and the third is the
# defect, so all three are pinned without a victim -- a corpus pin here would
# die the day the three atoms gained their sections, which is the same
# perishability P-atomic-audit's pins had.
ACCEPT_HEAD = """Terms › `qualifiers`: `migrated` — rewritten in GRACE lang v0.41 (2026-09-14){decline}.

"""
ACCEPT_SECTION = """## Generation acceptance

### Conformance checks

```text
Check 1.1: An auditor MUST find the thing (Operation 1).
```
"""
ACCEPT_EMPTY_SECTION = """## Generation acceptance

An implementation is acceptable when an auditor can read the store.
"""


def check_acceptance_synthetic(problems: list[str]) -> None:
    def run(name: str, text: str) -> set[str]:
        path = Path(f"synthetic/atoms/{name}.md")
        pat = Pattern(path=path, text=text, invariant_count=1, grounded=False)
        return {f.message for f in check_acceptance_surface({path: pat})}

    # (1) a section carrying a Check rule is the ordinary satisfying shape
    if run("has_section", ACCEPT_HEAD.format(decline="") + ACCEPT_SECTION):
        problems.append("Y-acceptance-surface: fired on a spec carrying a section "
                        "with a Check rule — the ordinary satisfying shape")
    # (2) a declared decline naming an owner is the other satisfying shape
    declined = ACCEPT_HEAD.format(
        decline="; `audit declined` — the audit surface is owned by Audit Trail")
    if run("declined", declined):
        problems.append("Y-acceptance-surface: fired on a declared decline that "
                        "names an owner — a decline by delegation is admitted")
    # (3) silence is the defect
    got = run("silent", ACCEPT_HEAD.format(decline=""))
    if not any("states no acceptance posture" in m for m in got):
        problems.append("Y-acceptance-surface: did not fire on a migrated spec "
                        "with no section and no decline — silence is the one "
                        "thing the rule outlaws")
    # (4) a section with no Check rule is silence wearing a heading
    got = run("empty", ACCEPT_HEAD.format(decline="") + ACCEPT_EMPTY_SECTION)
    if not any("no `Check` and no" in m for m in got):
        problems.append("Y-acceptance-surface: did not fire on a section carrying "
                        "no Check and no External check rule")
    # (5) a decline naming no owner is silence with a label on it
    got = run("ownerless", ACCEPT_HEAD.format(decline="; `audit declined` — "))
    if not any("names no owner" in m for m in got):
        problems.append("Y-acceptance-surface: did not fire on a decline naming "
                        "no owner — by delegation, never by silence")
    # (6) an unmigrated spec is not held to the rule at all
    if run("unmigrated", "Terms › `qualifiers`: none.\n"):
        problems.append("Y-acceptance-surface: fired on an unmigrated spec — the "
                        "rule reaches the migrated corpus only")


def check_doubled_section_synthetic(problems: list[str]) -> None:
    """M-section-doubled — widened at council read 72 from the one heading it
    was built on. Five fixtures: the two doubling shapes fire, and the three
    that look like doubling to a careless reader stay silent."""
    def run(name: str, text: str) -> set[str]:
        path = Path(f"synthetic/atoms/{name}.md")
        pat = Pattern(path=path, text=text, invariant_count=1, grounded=False)
        return {f.message for f in check_migration_seam({path: pat})}

    # (1) the specimen the narrow check was built on, still caught
    got = run("terms_twice", "## Terms\n\nx\n\n## Intent\n\ny\n\n## Terms\n\nz\n")
    if not any("## Terms` twice" in m for m in got):
        problems.append("M-section-doubled: did not fire on two `## Terms` "
                        "headings — council read 30's own specimen")
    # (2) the shape the narrow cut could not see
    got = run("accept_twice",
              "## Generation acceptance\n\nx\n\n## Standards references\n\ny\n"
              "\n## Generation acceptance\n\nz\n")
    if not any("## Generation acceptance` twice" in m for m in got):
        problems.append("M-section-doubled: did not fire on a doubled section "
                        "other than Terms — the narrowing this check was widened out of")
    # (3) a doubled subsection is the same defect one level down
    got = run("sub_twice",
              "## A\n\n### External checks\n\nx\n\n## B\n\n### External checks\n\ny\n")
    if not any("### External checks` twice" in m for m in got):
        problems.append("M-section-doubled: did not fire on a doubled `###` heading")
    # (4) distinct headings at one level are the ordinary shape
    if run("distinct", "## Terms\n\nx\n\n## Intent\n\ny\n\n## Status\n\nz\n"):
        problems.append("M-section-doubled: fired on a spec whose headings are "
                        "all distinct — the ordinary shape")
    # (5) one name at two levels is two different sections, not a doubling
    if run("two_levels", "## Examples\n\nx\n\n### Examples\n\ny\n"):
        problems.append("M-section-doubled: fired on one name at `##` and `###` — "
                        "a subsection is not a second copy of its parent")


def check_caps_synthetic(problems: list[str]) -> None:
    """R-caps / W-caps (tools/grace/check.py) — landed at council read 79, when
    WHILE, WHERE and EXIST were found in three normative rules both checkers
    passed. Six fixtures, one per shape the split has to hold."""
    sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "grace"))
    from check import unreserved_capitals  # noqa: E402
    cases = (
        ("a watched form", "A reader MUST NOT read x WHILE y = no.", ["WHILE"], []),
        ("an inflection of a reserved token", "IF the candidates EXIST THEN x MUST drop y.", ["EXIST"], []),
        ("a provisional form", "x DEGRADES TO y.", ["DEGRADES", "TO"], []),
        ("a proper noun in capitals", "A deployment under SOX MUST NOT set advisory.", [], ["SOX"]),
        ("reserved tokens only", "IF x EXISTS AND y EXCEEDS z THEN EVERY w MUST NOT EXCEED v ONLY AFTER u.", [], []),
        ("a code span quoting a form", "A spec MUST mark a `DEGRADES TO` pairing.", [], []),
    )
    for name, text, shaped, other in cases:
        got = unreserved_capitals(text)
        if got != (shaped, other):
            problems.append(f"R-caps/W-caps: {name} read as {got}, expected {(shaped, other)}")


def check_heading_synthetic(problems: list[str]) -> None:
    """H-heading — landed at council read 80. Six fixtures against the real
    standard: a conforming atom stays silent, and each of the five defect
    shapes the sweep cleared fires."""
    root = Path(__file__).resolve().parents[2]
    head = "Terms › `qualifiers`: `migrated` — rewritten in GRACE lang v0.44 (2026-09-15).\n\n"
    good = ["Summary", "Intent", "Structure", "### Identity model", "### State", "### Operations",
            "### Invariants", "### Store instance model", "Examples", "### Walkthrough",
            "Generation acceptance", "### Conformance checks", "Non-goals", "Edge cases",
            "### Clock semantics", "### Concurrency", "### The aggregate question",
            "Composition notes", "Terms", "### Vocabulary", "Standards references",
            "Status", "Ledger", "Decisions"]

    def page(names: list[str]) -> str:
        return head + "".join(("" if n.startswith("#") else "## ") + n + "\n\nx\n\n" for n in names)

    def run(name: str, names: list[str]) -> set[str]:
        path = Path(f"synthetic/atoms/{name}.md")
        pat = Pattern(path=path, text=page(names), invariant_count=1, grounded=False)
        return {f.message for f in check_heading_standard(root, {path: pat})}

    if run("good", good):
        problems.append(f"H-heading: fired on a conforming atom: {run('good', good)}")
    cases = (
        ("loose_family", [n if n != "### Clock semantics" else "## Clock semantics" for n in good], "is not a section"),
        ("wrong_parent", [n for n in good if n != "### Concurrency"][:6] + ["### Concurrency"] + [n for n in good if n != "### Concurrency"][6:], "belongs under"),
        ("out_of_order", ["Intent", "Summary"] + good[2:], "comes after"),
        ("unplaced_first", good[:3] + ["### Store instance model"] + [n for n in good[3:] if n != "### Store instance model"], "placed headings come first"),
        ("missing", [n for n in good if n != "### Vocabulary"], "requires"),
    )
    for name, names, needle in cases:
        if not any(needle in m for m in run(name, names)):
            problems.append(f"H-heading: {name} did not fire ({needle!r})")


def main(argv: list[str]) -> int:
    root = Path(argv[1]).resolve() if len(argv) > 1 else Path(__file__).resolve().parents[2]
    patterns = load_patterns(root)

    failures: list[str] = []
    for code, fn, silent, firing, exact in (
        ("P-atomic-audit", check_atomicity_over_audit, P_SILENT, P_FIRING, True),
        # `exact` since 2026-08-27, when the class closed and Q was promoted to
        # gating: with an empty pin set, exactness is what makes the emptiness an
        # assertion — any firing is reported as an unpinned pattern rather than
        # quietly joining a backlog. The regression coverage lives in
        # check_q_synthetic(), which needs no corpus positive to exist.
        ("Q-rebuild-bound", check_rebuild_bound, Q_SILENT, Q_FIRING_AT_LEAST, True),
        # Both exact since 2026-08-29, when the sweep emptied them (see the S/T block).
        ("S-recording-step", check_recording_step, S_SILENT, S_FIRING, True),
        ("T-seal-key", check_seal_key, T_SILENT, T_FIRING, True),
        # Exact since 2026-08-30, the day it landed, when the sweep emptied it.
        ("U-retry-bit", check_retry_bit, U_SILENT, U_FIRING, True),
    ):
        got = stems(fn(patterns))
        for s in sorted(silent):
            if s in got:
                failures.append(
                    f"{code}: fired on {s}, which is the exemplar this check's own "
                    f"message points authors at — the check has lost precision"
                )
        missing = sorted(firing - got)
        if missing:
            failures.append(
                f"{code}: did not fire on {', '.join(missing)} — either the check "
                f"was loosened past usefulness, or the finding closed and this "
                f"file was not updated"
            )
        if exact:
            extra = sorted(got - firing)
            if extra:
                failures.append(
                    f"{code}: fired on unpinned pattern(s) {', '.join(extra)} — "
                    f"a genuinely new instance (route it, then pin it here) or a "
                    f"false positive (tighten the check)"
                )
        print(f"{code}: {len(got)} pattern(s) firing — {', '.join(sorted(got)) or 'none'}")
        if code == "Q-rebuild-bound":
            problems = check_not_firing_at(patterns, fn(patterns),
                                           Q_NEGATED_SITES, code)
            check_q_synthetic(problems)
            failures.extend(problems)
            if not problems:
                for stem, marker in Q_NEGATED_SITES:
                    print(f"{code}: polarity site silent — {stem} / {marker!r} \u2713")
                print(f"{code}: synthetic fixtures hold "
                      f"(unbounded rebuild fires, bounded one silent) \u2713")
        if code == "P-atomic-audit":
            problems = check_motivating_sites(patterns, fn(patterns))
            check_synthetic(problems)
            failures.extend(problems)
            if not problems:
                print(f"{code}: synthetic regression fixtures hold "
                      f"(hedge-word decoy fires, real acknowledgement silent) ✓")
            if not problems:
                for stem, marker in P_MOTIVATING_SITES:
                    print(f"{code}: motivating site pinned — {stem} / {marker!r} ✓")

    st_problems: list[str] = []
    check_s_synthetic(st_problems)
    check_t_synthetic(st_problems)
    check_u_synthetic(st_problems)
    check_v_synthetic(st_problems)
    check_w_synthetic(st_problems)
    print("V-signature-alternation: 5 synthetic fixtures hold (an unseparated "
          "alternation fires; separated, inline, nested and multi-line-nested "
          "blocks silent) \u2713")
    print("W-step-reference: 4 synthetic fixtures hold (both dangling forms "
          "fire; resolving references and foreign actions silent) \u2713")
    failures.extend(st_problems)
    if not st_problems:
        print("S-recording-step / T-seal-key / U-retry-bit: synthetic fixtures hold "
              "(bare substrate mapping fires; stepped mapping, own-code "
              "signature and peer arm silent; id-keyed map fires, "
              "position-keyed map silent; straddling bare landings fire, "
              "positioned and same-side landings silent) \u2713")

    accept_problems: list[str] = []
    check_acceptance_synthetic(accept_problems)
    failures.extend(accept_problems)
    if not accept_problems:
        print("Y-acceptance-surface: 6 synthetic fixtures hold (a section with a "
              "check and a decline naming an owner silent; silence, an empty "
              "section and an ownerless decline fire; an unmigrated spec exempt) \u2713")

    orphan_problems: list[str] = []
    check_orphan_synthetic(orphan_problems)
    failures.extend(orphan_problems)
    if not orphan_problems:
        print("M-orphan-forthcoming: 5 synthetic fixtures hold (an unlisted "
              "forthcoming fires; a listed one, a linked one, an unmigrated "
              "spec and a single-word fragment stay silent) \u2713")

    doubled_problems: list[str] = []
    check_doubled_section_synthetic(doubled_problems)
    failures.extend(doubled_problems)
    if not doubled_problems:
        print("M-section-doubled: 5 synthetic fixtures hold (a doubled `##` "
              "and a doubled `###` fire; distinct headings and one name at two "
              "levels stay silent) \u2713")

    census_problems: list[str] = []
    check_census_synthetic(census_problems)
    failures.extend(census_problems)
    if not census_problems:
        print("W-stale-census: 4 synthetic fixtures hold (an unlisted family at "
              "three fires; the same family at two, a standard family at three "
              "and a correct listing silent; a stale listed count fires) \u2713")

    heading_problems: list[str] = []
    check_heading_synthetic(heading_problems)
    failures.extend(heading_problems)
    if not heading_problems:
        print("H-heading: 6 synthetic fixtures hold (a conforming atom silent; a loose "
              "family, a wrong parent, a wrong order, an unplaced heading first and a "
              "missing required heading fire) \u2713")

    caps_problems: list[str] = []
    check_caps_synthetic(caps_problems)
    failures.extend(caps_problems)
    if not caps_problems:
        print("R-caps / W-caps: 6 synthetic fixtures hold (a watched form, an "
              "inflection and a provisional form gate; a capitalized proper noun is "
              "advisory; reserved tokens and a quoted form stay silent) \u2713")

    r_problems: list[str] = []
    check_r_synthetic(r_problems)
    failures.extend(r_problems)
    if not r_problems:
        print(f"R-ledger: {len(R_FIXTURES)} synthetic fixtures hold "
              f"(two clean pages silent, eleven malformed pages fire their code) \u2713")

    for f in failures:
        print(f"FAIL  {f}", file=sys.stderr)
    print(
        f"\n— {'all pinned expectations hold' if not failures else str(len(failures)) + ' pinned expectation(s) broken'}",
        file=sys.stderr,
    )
    return 1 if failures else 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
