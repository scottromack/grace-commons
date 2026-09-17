#!/usr/bin/env python3
"""
Grace Commons spec-corpus linter — the mechanical cross-reference checker.

The spec layer has no compiler. This is a partial one: a dependency-free static
pass over the atoms/ and compositions/ markdown that catches the classes of drift
the three-pass review otherwise has to catch by eye —

  A. Dangling links        — every relative .md/.tla/.als/.cfg link resolves to
                              a real file (a renamed model leaving a spec→.tla
                              link dangling is the class this caught).
  B. Invariant-count refs   — "all N invariants from <Pattern>" matches the
                              actual count of `**Invariant N —**` headers in
                              <Pattern>. (The nine-vs-ten drift hazard.)
  C. Model-present bar      — a Status line that names a `.tla`/`.als` model has
                              that file present AND a `-buggy` twin beside it.
  D. Stale forthcoming      — a `*(forthcoming)*` marker in a list item that also
                              links to a file which is already `grounded`.
  E. Count honesty          — "NN grounded patterns / NN compositions" claims in
                              roadmap.md and readme.md match the real file counts.
  F. Rests-on refs          — a "<Pattern> Invariant N" cross-reference (as used in
                              invariant *Rests on:* clauses) resolves: N <= the cited
                              pattern's real invariant count. The tractable mechanical
                              slice of the capability-provenance rule (pressure-testing.md
                              §Capability provenance); the broader "is this capability
                              actually declared by that constituent" check stays
                              fresh-reader Pass-2 work (paraphrased names defeat a regex).
                              A range, `Event Log Invariant 1 through 7`, is read to its
                              last number.
  F. Stripped link          — a link written `name(path.md)`, brackets stripped.
                              F-stripped-link.
  F. Composes list          — a composition's Composes section lists its linked
                              constituents. F-composes-list.
  F. Constituents agree     — a composition's Composes list, `Term constituents`
                              and `EXACTLY ONE … MUST serve` rules name the same
                              specifications. F-constituents.
  F. Renumber               — an invariant keeps its number and a tombstoned
                              number stays retired, against HEAD and against the
                              spec before its migration. F-renumber.
  F. Range form             — every run of labels, in every Markdown file, is
                              written `Family N through M`: no dash, no repeated or
                              plural family, no *to*, and the last number follows the
                              first in the first number's shape (GRACE-lang Hard
                              invariant 29 through 31). F-range-form.
  G. Status grammar         — every pattern has a `## Status` section whose first
                              line starts with exactly one backticked status token
                              conforming to the pinned grammar (pressure-testing.md
                              §Status line format, pinned 2026-06-11).
  H. Status mirror          — a roadmap.md list entry that links a pattern and carries
                              a backticked status token mirrors the pattern file's own
                              token exactly (the pattern file is the source of truth).
  I. Duplicate table rows   — no roadmap.md table names the same pattern twice
                              (the duplicated-Login-row class).
  J. Banned working noun    — "concern" (any case, any inflection) is banned
                              corpus-wide as working vocabulary (vocabulary
                              directive 2026-06-11: the unit of separation is the
                              *concept*; pre-triage items in the guided tool are
                              *candidate concepts*). The single permitted form is
                              the title-case proper noun "Separation of Concerns"
                              naming the ancestor principle (inheritance map,
                              glossary tombstone) — mention of the ancestor,
                              never working use. Scans the whole corpus, not just
                              the pattern dirs.
  K. Output-level noun      — "application(s)" is output-level vocabulary (a
                              deployed build output) and is banned in the
                              canonical layer: atoms/, compositions/, the core
                              docs, and tools/guide. The canonical layer has
                              exactly two artifact kinds — atomic concepts and
                              compositions thereof. Not scanned: execution-
                              contract.md (the output level is its domain),
                              roadmap.md (dated history), glossary.md (the
                              definition site). Inline code spans and the API
                              acronym's canonical expansion are scrubbed first
                              (naming an external project's literal
                              `applications/` directory, or glossing API, is
                              mention, not use).
  L. Bare C-number          — no bare composition C-number (C1–C19) survives in an
                              atom/composition live body; the name carries the
                              meaning, the C-number is a registry key (debt #14).
                              Example `credential Cn` IDs are scrubbed; root policy
                              docs that cite `Cn` as an example are out of scope.
  M. Internal sigils        — no coined finding-ID sigil (FCn, FC-Fn, MC-Cn-N,
                              Rn-Fn, Cn-N, OG-n) survives in an atom/composition
                              live body (debt #15, naming.md Rule zero). High
                              precision: these shapes have no legitimate collision.
  P. Atomicity over audit   — an all-or-nothing claim ("together or not at all")
                              whose member set names an audit write, with no
                              acknowledgement in the enclosing block that an
                              appended event cannot be withdrawn. The first
                              mechanical slice that polices a *use* of a
                              constituent capability rather than a claim about
                              one (pressure-testing.md §Capability provenance,
                              widened 2026-08-27). The phrase alone is not the
                              signal — most uses of it are benign, over
                              constituent-store writes only.
  Q. Rebuild totality bound — a `*Rebuild procedure:*` that reads an event
                              payload with no stated bound on its own totality.
                              The substrate's purge cascade destroys Event Log's
                              `data` in its entirety at the retention horizon, so
                              an unbounded rebuild claims something that stops
                              being true on a schedule the composition does not
                              control. Exemplar: Audit Trail's "Bound on the
                              rebuild's totality, stated rather than assumed".
  S. Recording-failure step — in a composition that composes Audit Trail, a bare
                              `recording-failure` on the left of a mapping arrow
                              (→), on a line that also names `record_action`,
                              above the Status section. The substrate's contract
                              carries the step that refused — step-4 means the
                              event is already appended, so a retry that cannot
                              see the step duplicates outcome events. A bare
                              token in that position is a transcription of the
                              substrate arm with its payload dropped
                              (pressure-testing.md §A transcribed rejection arm
                              keeps its payload, frozen 2026-08-29). Signature
                              blocks, examples, prose, and a peer composition's
                              own bare arm mapped on a line with no substrate
                              call are not flagged: compositions re-export
                              `recording-failure` bare at their own boundary.
  T. Seal presentation key  — an `original_event_payloads` map subscripted or
                              described as keyed by an identifier (`[event_id]`,
                              `[entry_id]`, "keyed by `disclosure_id`"). The
                              record set a seal commits to is a sequence range
                              (Audit Trail Invariant 7), so a map keyed by an id
                              can present at most one payload per event and
                              every verification under interval cadence returns
                              a seal-record-set mismatch (pressure-testing.md
                              §A seal presentation is keyed by log position,
                              frozen 2026-08-29). Bare-payload `verify_record`
                              calls are NOT flagged — the substrate's own
                              contract uses the singular parameter name.
  U. Retry bit at boundary   — within one action's numbered step list, in a
                              composition that composes Audit Trail, a bare
                              `rejected(recording-failure)` landed at a step
                              BEFORE the action's first qualified constituent
                              commit call and at a step AFTER it. Read calls
                              (`read`, `read_record`, `check`, `verify_*`,
                              `history_for`, `active_for`, …) and
                              `AuditTrail.record_action` (the intent record) do
                              not count as the commit. One token on both sides
                              of the commit tells the caller nothing about
                              whether a retry is safe (pressure-testing.md
                              §A composition's own rejection arm carries the
                              retry bit, frozen 2026-08-30). Landed advisory
                              2026-08-30 (baseline: 10 actions, 5 patterns) and
                              promoted to gating the same day at zero sites.
  O. Term registry resolver — on any page carrying an annotation.md `## Terms`
                              registry, every `[Term]` shortcut-reference marker
                              resolves to a `[Term]: …` definition (no dangling)
                              and every definition is used (no orphan). OPT-IN:
                              pages with no Terms section are skipped, so the
                              not-yet-converted patterns stay at 0 and recall
                              grows as pages convert. The safety net for the
                              annotation.md bulk rollout. (Whitelist gloss is N.)

Design notes (this tool is meant to be maintained by a small/cheap model):
  - Standard library only. No deps. Runs anywhere `python3` does.
  - High precision over high recall: a false positive costs trust, so each check
    fires only on a tight, well-understood pattern. Recall grows by adding
    checks, not by loosening existing ones.
  - One finding per line, machine-greppable. Exit 1 if any finding, 0 if clean.

Usage:  python3 tools/linter/lint.py [repo_root]
"""

from __future__ import annotations

import os
import re
import subprocess
import sys
from dataclasses import dataclass, field
from pathlib import Path

# --------------------------------------------------------------------------- #
# Corpus model
# --------------------------------------------------------------------------- #

PATTERN_DIRS = ("atoms", "compositions")
INVARIANT_HEADER = re.compile(r"^\s*-?\s*\*\*Invariant\s+(\d+)\s+[—-]", re.M)
# a migrated spec states an invariant as rules labelled `Invariant N.M`, and
# some carry no bold bullet heading above them (council read 93)
INVARIANT_RULE = re.compile(r"^\s*Invariant\s+(\d+)(?:\.\d+)?[a-z]?:", re.M)


def invariant_numbers(text: str) -> set[int]:
    """The invariants a spec declares: bold bullet headings and rule labels."""
    return {int(n) for n in INVARIANT_HEADER.findall(text)} | \
        {int(n) for n in INVARIANT_RULE.findall(text)}
# markdown links to a relative path ending in .md/.tla/.als/.cfg (opt. #anchor).
# Model extensions are included so a renamed .tla/.als leaving a spec→model link
# dangling is caught — the original .md-only form missed it (debt #14 lint gap).
MD_LINK = re.compile(r"\[[^\]]+\]\((\.{1,2}/[^)]+?\.(?:md|tla|als|cfg))(#[^)]*)?\)")
# Status line: the first paragraph starting with `grounded` (back-tick optional)
STATUS_GROUNDED = re.compile(r"^`?grounded", re.M)
# model files named in a Status / Lineage line, e.g. `provenance.als`, `kyc.tla`
MODEL_REF = re.compile(r"`([\w\-/]+\.(?:tla|als))`")
# "all ten invariants from [Name](link)" / "[Name](link)'s ten checks" etc.
NUMBER_WORDS = {
    "zero": 0, "one": 1, "two": 2, "three": 3, "four": 4, "five": 5,
    "six": 6, "seven": 7, "eight": 8, "nine": 9, "ten": 10, "eleven": 11,
    "twelve": 12, "thirteen": 13, "fourteen": 14, "fifteen": 15,
}
# "<count> invariants from [Name](path)"  — count is a word or digit
INV_COUNT_REF = re.compile(
    r"(?:all\s+)?(\b\w+\b)\s+invariants?\s+(?:from|of)\s+"
    r"\[[^\]]+\]\((\.{1,2}/[^)]+?\.md)(?:#[^)]*)?\)",
    re.I,
)
# the pattern's display name, read from its H1 title (trailing " (Cxx)" stripped)
H1_TITLE = re.compile(r"^#\s+(.+?)\s*$", re.M)
TRAILING_PAREN = re.compile(r"\s*\([^)]*\)\s*$")


# Checks that REPORT but do not fail the build. A new check landed against an
# existing corpus starts here: it is worth reading from the day it lands, and
# turning the continuous-integration gate red before the findings it names have
# been worked is how a check gets muted rather than fixed. A code leaves this
# set when its findings reach zero — that is the moment the check starts
# defending the property instead of measuring it.
#
# P-atomic-audit and Q-rebuild-bound landed 2026-08-27 with a recorded baseline
# (roadmap.md methodology debt #19): 3 patterns and 8 patterns respectively.
# Their propagation is debt #19 step (iii); they become gating when it closes.
# EMPTY as of 2026-08-27: both checks are gating. Q-rebuild-bound was promoted
# when the retention-horizon class closed on every known instance — including the
# two its own trigger cannot see (Preference-Aware Notification Fanout and
# Forensic Recovery's AP-F1), which is the distinction the promotion waited on.
# A check going silent measures the check's reach, not the corpus's health, so
# silence alone was never the bar; the bar was the class.
#
# P-atomic-audit was promoted to GATING on 2026-08-27, when the last of its three
# instances closed and it fired zero times corpus-wide. That is the condition
# roadmap.md set for promotion: a check becomes gating at the moment it stops
# measuring a backlog and starts defending a property. From here a firing means a
# NEW instance has been introduced, which is exactly the event that should stop a
# build — the class took three rounds and one protocol repair to clear, and
# re-acquiring it silently is the failure mode worth spending a red build on.
#
# S-recording-step and T-seal-key landed 2026-08-29 ADVISORY with a recorded
# baseline (23 sites across 6 patterns; 1 site) — the same discipline P and Q
# followed: a check measuring a backlog is advisory, and becomes gating at the
# moment the sweep under its rule empties it. The rules they police were frozen
# on the day the checks landed (pressure-testing.md, the six sections stated
# 2026-08-29), so the sweep's findings are attributable to a rule that already
# covered them. Promotion is the removal of the code from this set, in the same
# change as the last site's fix, with test_checks.py's pin set switched to exact.
#
# T-seal-key was promoted to GATING on 2026-08-29, the same day it landed: its
# one site (Immutable Transaction Ledger's [Verify Ledger]) closed under the
# sweep and it fires zero times corpus-wide. S-recording-step followed the same
# day: its baseline of 22 sites across five patterns (23 before the peer-arm
# correction) closed under the sweep — External Onboarding, Propagate Consent
# Revocation Downstream, Immutable Transaction Ledger, Capability-Backed
# Sharing, Actor Suspension — and it fires zero times corpus-wide.
# EMPTY as of 2026-08-29: every check is gating.
#
# U-retry-bit landed 2026-08-30 ADVISORY with a recorded baseline of 10 actions
# across 5 patterns (Capability-Backed Sharing, Chain of Custody, Customer
# Onboarding, Forensic Recovery, Immutable Transaction Ledger) — two of them
# patterns the second gates had already closed. Same promotion discipline: it
# becomes gating in the change that closes the last site.
#
# U-retry-bit was promoted to GATING on 2026-08-30, the same day it landed: the
# three third-gated sites closed under the sweep and the two second-gated ones
# (Capability-Backed Sharing, Customer Onboarding) in the change after, and it
# fires zero times corpus-wide.
# EMPTY as of 2026-08-30: every check is gating.
ADVISORY_CODES: frozenset[str] = frozenset()


@dataclass
class Finding:
    path: Path
    line: int
    code: str
    message: str


@dataclass
class Pattern:
    path: Path
    text: str
    invariant_count: int
    grounded: bool


def load_patterns(root: Path) -> dict[Path, Pattern]:
    out: dict[Path, Pattern] = {}
    for d in PATTERN_DIRS:
        for md in sorted((root / d).rglob("*.md")):
            name = md.name.lower()
            # readme/index are catalogs; TAXONOMY.md is a proposal doc
            # (nav_exclude, "Status: proposal") — none are patterns.
            if name in ("readme.md", "index.md", "taxonomy.md"):
                continue
            text = md.read_text(encoding="utf-8")
            out[md] = Pattern(
                path=md,
                text=text,
                invariant_count=len(invariant_numbers(text)),
                grounded=bool(STATUS_GROUNDED.search(text)),
            )
    return out


def line_of(text: str, idx: int) -> int:
    return text.count("\n", 0, idx) + 1


# --------------------------------------------------------------------------- #
# Checks
# --------------------------------------------------------------------------- #

def check_links(root: Path, md_files: list[Path]) -> list[Finding]:
    """A. Every relative .md link resolves to an existing file."""
    findings: list[Finding] = []
    for md in md_files:
        text = md.read_text(encoding="utf-8")
        for m in MD_LINK.finditer(text):
            target = (md.parent / m.group(1)).resolve()
            if not target.exists():
                findings.append(Finding(
                    md, line_of(text, m.start()), "A-dangling-link",
                    f"link target does not exist: {m.group(1)}",
                ))
    return findings


def check_invariant_counts(patterns: dict[Path, Pattern], md_files: list[Path]) -> list[Finding]:
    """B. 'N invariants from [Pattern](path)' matches Pattern's real count."""
    findings: list[Finding] = []
    by_resolved = {p.path.resolve(): p for p in patterns.values()}
    for md in md_files:
        text = md.read_text(encoding="utf-8")
        for m in INV_COUNT_REF.finditer(text):
            word, rel = m.group(1), m.group(2)
            claimed = NUMBER_WORDS.get(word.lower())
            if claimed is None:
                if word.isdigit():
                    claimed = int(word)
                else:
                    continue  # not a count word ("its invariants from") — skip
            target = (md.parent / rel).resolve()
            tgt = by_resolved.get(target)
            if tgt is None:
                continue  # link resolution handled by check A
            if tgt.invariant_count != claimed:
                findings.append(Finding(
                    md, line_of(text, m.start()), "B-invariant-count",
                    f"claims {claimed} invariants from {Path(rel).name}, "
                    f"but it declares {tgt.invariant_count}",
                ))
    return findings


def check_models_present(patterns: dict[Path, Pattern]) -> list[Finding]:
    """C. A named `.tla`/`.als` model in a grounded pattern exists, with a twin.

    Fires only when the pattern actually CLAIMS a verified model (its Status zone
    mentions the harness or a buggy twin) — so an incidental prose mention of a
    hypothetical `.als` ("don't put Alloy on Personal Todo") is not a finding.
    """
    findings: list[Finding] = []
    for p in patterns.values():
        if not p.grounded:
            continue
        # only inspect the Status section's first ~3000 chars to avoid Lineage
        # back-references to other patterns' models
        status_zone = p.text[:3000]
        claims_model = ("tools/harness" in status_zone) or ("buggy twin" in status_zone)
        if not claims_model:
            continue
        for m in MODEL_REF.finditer(status_zone):
            ref = m.group(1)
            # resolve relative to the pattern file's directory
            model = (p.path.parent / ref).resolve() if "/" in ref else (p.path.parent / ref).resolve()
            if "buggy" in ref:
                continue
            if not model.exists():
                findings.append(Finding(
                    p.path, line_of(p.text, m.start()), "C-model-missing",
                    f"Status names model {ref} but file is absent",
                ))
                continue
            stem = model.stem
            ext = model.suffix
            twins = list(model.parent.glob(f"{stem}-buggy*{ext}"))
            if not twins:
                findings.append(Finding(
                    p.path, line_of(p.text, m.start()), "C-twin-missing",
                    f"model {ref} has no -buggy twin beside it (vacuity guard)",
                ))
    return findings


# a forthcoming marker that DECORATES a link: `](path)` then, within a short
# window, a `(forthcoming...)` marker — meaning the linked pattern itself is
# being called forthcoming. (Not merely the word appearing elsewhere on the line.)
DECORATING_FORTHCOMING = re.compile(
    r"\]\((\.{1,2}/[^)]+?\.md)(?:#[^)]*)?\)[^.\n]{0,40}?\(forthcoming",
    re.I,
)


def check_stale_forthcoming(root: Path, patterns: dict[Path, Pattern], md_files: list[Path]) -> list[Finding]:
    """D. A link whose own '(forthcoming)' marker decorates an already-grounded file.

    High precision: the marker must immediately decorate the link (within ~40
    chars after it), not merely appear somewhere on the line — so prose that
    *retires* forthcoming-links, or lists a grounded pattern beside a different
    forthcoming one, does not false-positive.
    """
    findings: list[Finding] = []
    by_resolved = {p.path.resolve(): p for p in patterns.values()}
    for md in md_files:
        text = md.read_text(encoding="utf-8")
        for m in DECORATING_FORTHCOMING.finditer(text):
            target = (md.parent / m.group(1)).resolve()
            tgt = by_resolved.get(target)
            if tgt and tgt.grounded:
                findings.append(Finding(
                    md, line_of(text, m.start()), "D-stale-forthcoming",
                    f"link marked '(forthcoming)' but {Path(m.group(1)).name} "
                    f"is grounded",
                ))
    return findings


ORPHAN_FORTHCOMING = re.compile(
    r"(?:\[(?P<linked>[^\]\n]{2,60})\]\([^)\n]+\)"
    r"|\*\*(?P<bold>[A-Z][^*\n]{2,60}?)\*\*"
    r"|(?P<plain>[A-Z][A-Za-z\u2019'-]*(?:[ /](?:[a-z]{1,3} )?[A-Z][A-Za-z\u2019'-]*){0,4}))"
    r"(?:\u2019s|'s)?\s*\*\(forthcoming\)\*"
)


def check_orphan_forthcoming(root: Path, patterns: dict[Path, Pattern]) -> list[Finding]:
    """M. A migrated spec names a `*(forthcoming)*` pattern roadmap.md does not carry.

    The sibling of D-stale-forthcoming, which reads *linked* markers that have
    since landed. This one reads the *named* markers — the ones an extraction
    flag, a declined delegation or a Non-goal points at — and asks whether the
    home exists on the planning surface at all. `roadmap.md` is the single
    source of truth for library state (AGENTS.md), so a name it does not carry
    is a pointer into nothing: the spec says *someone else owns this* and no
    one is listed. Linked markers are skipped; they are D's.
    """
    findings: list[Finding] = []
    roadmap = root / "roadmap.md"
    if not roadmap.exists():
        return findings
    # A *row* on the planning surface, not a passing mention: a name that
    # appears only inside a prose paragraph is discussed, not listed, and the
    # roadmap's rows are what a drafter reads. Table rows and list entries
    # count; everything else does not.
    road = "\n".join(
        ln.lower() for ln in roadmap.read_text(encoding="utf-8").splitlines()
        if ln.lstrip().startswith(("|", "- ", "* ", "#"))
    )
    for p in patterns.values():
        if not re.search(r"^Term qualifiers:.*\bmigrated\b", p.text, re.M):
            continue  # the unmigrated corpus is not held to this
        seen: set[str] = set()
        for m in ORPHAN_FORTHCOMING.finditer(p.text):
            if m.group("linked"):
                continue  # a linked forthcoming is check_stale_forthcoming's
            name = (m.group("bold") or m.group("plain") or "").strip()
            name = re.sub(r"[\u2019']s$", "", name).strip()
            if len(name) < 6 or (" " not in name and "-" not in name):
                continue  # a bare single word is a fragment, not a pattern name
            key = name.lower()
            if key in seen:
                continue
            seen.add(key)
            head = key.split(" / ")[0].strip()
            if key in road or head in road:
                continue
            findings.append(Finding(
                p.path, line_of(p.text, m.start()), "M-orphan-forthcoming",
                f"names `{name}` *(forthcoming)* and roadmap.md carries no row "
                f"for it \u2014 a delegation pointing at a home the planning "
                f"surface does not list",
            ))
    return findings


def check_counts(root: Path, patterns: dict[Path, Pattern]) -> list[Finding]:
    """E. 'NN grounded patterns / NN compositions' claims match reality."""
    findings: list[Finding] = []
    atoms = [p for p in patterns.values() if "/atoms/" in p.path.as_posix()]
    comps = [p for p in patterns.values() if "/compositions/" in p.path.as_posix()]
    real_total = len(atoms) + len(comps)
    real_comps = len(comps)

    claim = re.compile(r"\*\*(\d+)\s+grounded\s+patterns\s*\(\s*(\d+)\s+grounded\s+compositions?\)\*\*")
    for fname in ("roadmap.md", "readme.md"):
        f = root / fname
        if not f.exists():
            continue
        text = f.read_text(encoding="utf-8")
        # Only check the most-recent (last) claim in the file — earlier ones are
        # dated history and are allowed to be stale.
        matches = list(claim.finditer(text))
        if not matches:
            continue
        last = matches[-1]
        tot, cmp = int(last.group(1)), int(last.group(2))
        if tot != real_total or cmp != real_comps:
            findings.append(Finding(
                f, line_of(text, last.start()), "E-count-drift",
                f"latest claim says {tot} patterns / {cmp} compositions; "
                f"corpus has {real_total} patterns / {real_comps} compositions",
            ))
    return findings


def check_rests_on_refs(patterns: dict[Path, Pattern], md_files: list[Path]) -> list[Finding]:
    """F. A '<Pattern> Invariant N' reference resolves: N <= that pattern's count.

    The tractable mechanical slice of the capability-provenance rule
    (pressure-testing.md §Capability provenance): it catches a cross-reference to an
    invariant *number* a pattern does not have (the dangling-number class). It
    deliberately does NOT verify that the cited capability is the *right* one —
    paraphrased parenthetical names ("Invariant 4 (cross-store atomicity)" for a
    header named "Cascade-on-purge") are legitimate and would false-positive a name
    match — so the broader "is this capability actually declared by that constituent"
    check stays a Pass-2 fresh-reader concern. High precision: fires only when an
    exact known pattern name is immediately followed by "Invariant(s) <n>".
    """
    # The ceiling is the RESERVED label space, not the count of live families: a
    # tombstoned invariant keeps its number forever (GRACE-lang Hard invariant 25,
    # Hard invariant 27), so a spec that tombstones Invariant 9 and 10 still has a
    # legitimate Invariant 11 and a citation to it is not dangling. Counting live
    # headers alone reported Party Identity's own Decisions entry as a dangling
    # citation the moment two duplicated invariants became tombstones (council
    # read 42).
    TOMBSTONED_INV = re.compile(r"^\s*Deleted:\s*Invariant\s+(\d+)\b", re.M)
    by_name: dict[str, int] = {}
    for p in patterns.values():
        m = H1_TITLE.search(p.text)
        if not m or not p.invariant_count:
            continue
        live = sorted(invariant_numbers(p.text))
        reserved = live + [int(n) for n in TOMBSTONED_INV.findall(p.text)]
        name = TRAILING_PAREN.sub("", m.group(1).strip()).strip()
        if name and reserved:
            by_name[name] = max(reserved)
    findings: list[Finding] = []
    if not by_name:
        return findings
    # One alternation over every pattern name rather than one regex per name.
    # The per-name form scanned each file once per pattern — 54 files by 28
    # names over ~60 KB each — and cost 20 of the linter's 39 seconds, which a
    # profile found and a guess did not (council read 46). Longest name first so
    # the alternation prefers `Party Identity` over any shorter name inside it.
    names = sorted(by_name, key=len, reverse=True)
    rx = re.compile(r"(?<![A-Za-z])(" + "|".join(re.escape(n) for n in names)
                    + r")\s+Invariants?\s+([0-9][0-9,\s]*(?:(?:and|through)\s+[0-9]+)?)")
    for md in md_files:
        text = md.read_text(encoding="utf-8")
        for m in rx.finditer(text):
            nm = m.group(1)
            count = by_name[nm]
            for n in (int(x) for x in re.findall(r"\d+", m.group(2))):
                if n > count:
                    findings.append(Finding(
                        md, line_of(text, m.start()), "F-invariant-ref",
                        f"cites {nm} Invariant {n}, but {nm} declares {count}",
                    ))
    return findings


# --------------------------------------------------------------------------- #
# F-constituent-call — composition call sites vs. constituent contracts
# --------------------------------------------------------------------------- #
# The second mechanical slice of the capability-provenance rule (the first is
# F-invariant-ref above): a composition's qualified constituent call —
# `Constituent.action(args)` — must name an action the constituent actually
# declares, and any keyword argument it passes must appear in that action's
# declared contract. This is the drift class that produced the 2026-08-24
# findings (calls to a removed `Capability.expire`; `allocated_by_ref=` /
# `resource_ref=` against `allocate(allocator_ref, scope, max_redemptions,
# ttl)`; a phantom `retention_policy=` on `record_action`): an atom re-grounds,
# its contract moves, and nothing mechanical re-checked the composers.
#
# Precision over recall, per the linter's division of labor:
#   - action existence is checked against a BROAD set (every backticked
#     `name(` in the constituent, plus declared contracts), so an action
#     declared in an unrecognized format never false-positives;
#   - keyword arguments are checked only where a STRICT contract declaration
#     was parsed ("Projected contract: `f(a, b)`" or a bold-inline signature
#     "**`f(a, b) → ...`**"), with `optional`, `?`-optional and [bracket]-optional
#     markers stripped;
#   - positional-arity drift, renamed rejection reasons, and semantic drift
#     stay fresh-reader concerns.
# Call sites are scanned only ABOVE the "## Status" heading — Lineage notes
# legitimately quote superseded signatures as history.

CONSTITUENT_CALL = re.compile(
    r"\b((?:[A-Z][A-Za-z]+ )?[A-Z][A-Za-z]+)\.([a-z_][a-z0-9_]*)\(")
CONTRACT_PROJECTED = re.compile(
    r"Projected contract:\s*`([a-z_][a-z0-9_]*)\(([^)]*)\)")
CONTRACT_BOLD = re.compile(
    r"^\s*(?:[-*]\s*)?\*\*`([a-z_][a-z0-9_]*)\(([^)]*)\)", re.M)
BACKTICKED_ACTION = re.compile(r"`([a-z_][a-z0-9_]*)\(")
# A GRACE lang signature: `name(param, optional param)` over an answers line
# (GRACE-lang Term signature form, v0.48). An unmigrated spec still writes
# `name(param, param?) -> outcome | rejected(...)`, and both are contracts.
CONTRACT_SIGNATURE = re.compile(
    r"^([a-z_][a-z0-9_]*)\(([^)]*)\)(?:\s*(?:\u2192|->)|\n  answers )", re.M)
KWARG = re.compile(r"^\s*([a-z_][a-z0-9_]*)\s*=[^=]")
HANDLE_ALIASES = {"workflow-state-machine": "state-machine"}


def _handle_to_kebab(handle: str) -> str:
    s = handle.replace(" ", "")
    return re.sub(r"(?<=[a-z0-9])(?=[A-Z])", "-", s).lower()


def _resolve_handle(handle: str, stems: dict[str, Path]) -> Path | None:
    """Map a call-site handle to a pattern file: exact kebab, alias, unique
    prefix (Capacity Constraint -> capacity-constraint-enforcement), then a
    retry on the last word alone (a sentence capital glued to a one-word
    handle: 'The LegalHold' -> 'LegalHold')."""
    for candidate in (handle, handle.split(" ")[-1] if " " in handle else None):
        if not candidate:
            continue
        kebab = _handle_to_kebab(candidate)
        kebab = HANDLE_ALIASES.get(kebab, kebab)
        if kebab in stems:
            return stems[kebab]
        prefixed = [p for s, p in stems.items() if s.startswith(kebab + "-")]
        if len(prefixed) == 1:
            return prefixed[0]
    return None


def _declared_contracts(text: str) -> dict[str, set[str]]:
    out: dict[str, set[str]] = {}
    for rx in (CONTRACT_PROJECTED, CONTRACT_BOLD, CONTRACT_SIGNATURE):
        for name, params in rx.findall(text):
            cleaned = set()
            for piece in params.split(","):
                piece = piece.strip().strip("?").strip("[]").strip("?").strip()
                piece = piece.removeprefix("optional ")
                if re.fullmatch(r"[a-z_][a-z0-9_]*", piece):
                    cleaned.add(piece)
            out.setdefault(name, set()).update(cleaned)
    return out


def _top_level_kwargs(text: str, open_paren: int) -> list[str]:
    """Keyword-argument names at depth 0 of the call, best-effort to end of
    line if the paren never closes there."""
    depth, start, pieces = 0, open_paren + 1, []
    i = open_paren + 1
    while i < len(text) and text[i] != "\n":
        c = text[i]
        if c in "({[":
            depth += 1
        elif c in ")}]":
            if c == ")" and depth == 0:
                break
            depth -= 1
        elif c == "," and depth == 0:
            pieces.append(text[start:i])
            start = i + 1
        i += 1
    pieces.append(text[start:i])
    kwargs = []
    for piece in pieces:
        m = KWARG.match(piece)
        if m:
            kwargs.append(m.group(1))
    return kwargs


def check_constituent_calls(patterns: dict[Path, Pattern]) -> list[Finding]:
    stems = {p.path.stem: p.path for p in patterns.values()}
    # per-constituent caches
    contracts_cache: dict[Path, dict[str, set[str]]] = {}
    broad_cache: dict[Path, set[str]] = {}

    def contracts_of(path: Path) -> dict[str, set[str]]:
        if path not in contracts_cache:
            contracts_cache[path] = _declared_contracts(patterns[path].text)
        return contracts_cache[path]

    def broad_actions_of(path: Path) -> set[str]:
        if path not in broad_cache:
            broad_cache[path] = set(BACKTICKED_ACTION.findall(patterns[path].text)) \
                                | set(contracts_of(path))
        return broad_cache[path]

    findings: list[Finding] = []
    for p in patterns.values():
        if "/compositions/" not in p.path.as_posix():
            continue
        cut = p.text.find("\n## Status")
        body = p.text if cut == -1 else p.text[:cut]
        for m in CONSTITUENT_CALL.finditer(body):
            handle, action = m.group(1), m.group(2)
            target = _resolve_handle(handle, stems)
            if target is None or target == p.path:
                continue
            tname = target.stem
            if action not in broad_actions_of(target):
                findings.append(Finding(
                    p.path, line_of(body, m.start()), "F-constituent-call",
                    f"calls {handle}.{action}(...) but {tname} declares no "
                    f"such action",
                ))
                continue
            declared = contracts_of(target).get(action)
            if not declared:
                continue  # action exists but no strict contract parsed — skip kwargs
            open_paren = m.end() - 1
            for k in _top_level_kwargs(body, open_paren):
                if k not in declared:
                    findings.append(Finding(
                        p.path, line_of(body, m.start()), "F-constituent-call",
                        f"{handle}.{action}(... {k}= ...) — parameter `{k}` is "
                        f"not in {tname}'s contract "
                        f"`{action}({', '.join(sorted(declared))})`",
                    ))
    return findings


# --------------------------------------------------------------------------- #
# P-atomic-audit — all-or-nothing claimed over a write the substrate cannot
#                  withdraw
# --------------------------------------------------------------------------- #
# The third mechanical slice of the capability-provenance rule, and the first
# that polices a *use* rather than a claim (pressure-testing.md §Capability
# provenance, widened 2026-08-27). A composition that says a write set "commits
# together or not at all" is claiming a withdrawal capability over every member
# of that set. Where a member is an Audit Trail write, the substrate declares
# the opposite: an appended event cannot be withdrawn and synchronous rollback
# is unavailable to it. The claim is then an undeclared dependency of exactly
# the kind the rule forbids — invisible because nothing on the page announces it.
#
# Precision over recall, per the linter's division of labor:
#   - the phrase alone is NOT the signal. Nine patterns use "together or not at
#     all" and most do so benignly, over constituent-store writes only. The
#     check fires only where the SAME SENTENCE also names an audit write.
#   - a pattern that has already done the honest restatement is not flagged.
#     Chain of Custody's Invariant 4 states the safety-plus-liveness split
#     outright ("synchronous rollback is unavailable … the orphan state *is*
#     reachable … The honest claim therefore splits"), and Resolve a Person's
#     Data Rights carries a modulo-clause for its irreversible precursor. Any
#     acknowledgement marker in the enclosing block suppresses the finding —
#     the check asks "is the un-withdrawable half acknowledged anywhere near
#     this claim", not "is the wording ideal".
#   - the fix a firing asks for is a restatement, never a rewiring: order the
#     un-withdrawable write last, claim "no sealed event without its record" as
#     safety and "no record without its sealed event, within a declared
#     compensation window" as liveness. The in-corpus exemplar is Chain of
#     Custody Invariant 4.

ALL_OR_NOTHING = re.compile(
    r"together or not at all"
    r"|commits? (?:them |the \w+ )?atomically"
    r"|commit \*?\*?atomically",
    re.I,
)
# an audit write named inside the same sentence
AUDIT_WRITE = re.compile(
    r"record_action|[Aa]udit [Tt]rail event|audit event|sealed event|sealed \w+ event",
)
# the un-withdrawable half acknowledged anywhere in the enclosing block
ATOMICITY_ACKNOWLEDGED = re.compile(
    r"synchronous rollback is (?:not available|unavailable)"
    r"|cannot be (?:rolled back|withdrawn|un-appended|unappended)"
    r"|safety ?\+ ?liveness|safety-plus-liveness"
    r"|compensation window"
    r"|honest claim therefore splits",
    re.I,
)


# A line that starts a new TOP-LEVEL list item, at column 0. Sibling bullets sit
# on adjacent lines with no blank line between them, so a purely blank-line-
# delimited block runs across all of them.
_TOP_ITEM = re.compile(r"^(?:[-*+] |\d+\. )", re.M)


def _enclosing_block(text: str, idx: int) -> str:
    """The block containing idx: blank-line-delimited, plus any immediately
    following indented continuation lines (an invariant's sub-bullets), but
    NEVER crossing into a sibling top-level list item.

    The sibling clamp was added 2026-08-27 after it was caught suppressing a real
    finding: multi-party-approval's `chain_store` went silent not because its own
    entry stated a retention bound but because the NEXT BULLET did, two entries
    down in the same blank-line-delimited run. The corpus count fell and looked
    like progress, which is the failure mode these checks keep producing and the
    reason each one is pinned.

    Tightening a suppressor is safe in a way widening a trigger is not, and the
    asymmetry is worth stating: a narrower suppressor can only REVEAL findings,
    and a false positive is visible and cheap to fix, where a false negative is
    neither. Trigger changes move the set the other way and are held to a higher
    bar (see the REBUILD_CLAUSE comment)."""
    start = text.rfind("\n\n", 0, idx)
    start = 0 if start == -1 else start + 2
    end = idx
    while True:
        nxt = text.find("\n\n", end)
        if nxt == -1:
            nxt = len(text)
            break
        # keep going while the paragraph after the break is an indented
        # continuation of the same item
        after = text[nxt + 2: nxt + 6]
        if after.startswith("  ") or after.startswith("\t"):
            end = nxt + 2
            continue
        break
    block_start, block_end = start, nxt
    # clamp to the sibling list item containing idx, where there is one
    for m in _TOP_ITEM.finditer(text, block_start, block_end):
        if m.start() <= idx:
            block_start = max(block_start, m.start())
        else:
            block_end = min(block_end, m.start())
            break
    return text[block_start:block_end]


def _sentence_at(text: str, idx: int) -> tuple[int, int]:
    """Crude sentence bounds around idx: previous '. ' to next '.'."""
    start = text.rfind(". ", 0, idx)
    start = 0 if start == -1 else start + 2
    end = text.find(".", idx)
    end = len(text) if end == -1 else end + 1
    return start, end


def check_atomicity_over_audit(patterns: dict[Path, Pattern]) -> list[Finding]:
    """P. An all-or-nothing claim whose member set names an audit write, with no
    acknowledgement of the un-withdrawable half in the enclosing block."""
    findings: list[Finding] = []
    for p in patterns.values():
        cut = p.text.find("\n## Status")
        body = p.text if cut == -1 else p.text[:cut]
        seen_blocks: set[int] = set()
        for m in ALL_OR_NOTHING.finditer(body):
            s0, s1 = _sentence_at(body, m.start())
            if not AUDIT_WRITE.search(body[s0:s1]):
                continue
            block = _enclosing_block(body, m.start())
            if ATOMICITY_ACKNOWLEDGED.search(block):
                continue
            # one finding per block, not per phrase
            key = body.rfind("\n\n", 0, m.start())
            if key in seen_blocks:
                continue
            seen_blocks.add(key)
            findings.append(Finding(
                p.path, line_of(body, m.start()), "P-atomic-audit",
                "all-or-nothing claimed over a set naming an audit write, with "
                "no acknowledgement that an appended event cannot be withdrawn "
                "— restate as safety plus liveness (exemplar: Chain of Custody "
                "Invariant 4)",
            ))
    return findings


# --------------------------------------------------------------------------- #
# Q-rebuild-bound — a payload-sourced rebuild claiming totality it cannot have
# --------------------------------------------------------------------------- #
# The fourth mechanical slice, and the second that polices a use. A composition
# whose derived-index rebuild reads fields out of audit event payloads is using
# a capability the substrate lawfully withdraws: the purge cascade destroys
# Event Log's `data` field in its entirety at the retention horizon. A rebuild
# stated without a bound on its own totality therefore claims something that
# stops being true on a schedule the composition does not control — and the
# consequence is not always cosmetic (in one pattern a purged payload lets one
# human approval authorize a second regulated firing).
#
# Precision over recall:
#   - fires only on an explicit `*Rebuild procedure:*` clause that names a
#     payload read. A rebuild described in prose is missed; that is a recall
#     gap, deliberately taken, because a looser trigger would fire on every
#     "for every event" in the corpus.
#   - any bound marker in the enclosing block suppresses it. The in-corpus
#     exemplar is Audit Trail's "Bound on the rebuild's totality, stated rather
#     than assumed" — which then states the bound and why it suffices.
#   - atoms owning their own store are unaffected: they are not reading a
#     substrate payload they do not control.
#
# Known recall gaps, recorded rather than chased. Preference-Aware Notification
# Fanout reads payload fields with the phrasings "every fact in the index is a
# `fanout.created` event's (principal_ref, decided_at, channels) triple" and
# "the `fanout.initiated` event carries the invocation's scope" — both genuine
# instances this check does not see. Widening the trigger to "event carries" /
# "event's (tuple)" catches them AND produces a false positive on Audit Trail's
# own `event_to_sequence`, whose rebuild reads `event_id` and `sequence_number`
# — fields the purge cascade PRESERVES, so no bound is owed. That is the real
# shape of the test: not "does it touch a payload" but "does it read a field
# the cascade destroys", which needs the surviving-field set (action_ref,
# actor_ref, attested_at, attestation_id, recorded_at, sequence_number,
# event_id) subtracted from what the clause names. Until a check can do that
# subtraction, this one stays tight and the gap stays written down — the
# linter's rule is that recall grows by adding checks, not by loosening one
# until it matches the answer you expected.

# LINE-SCOPED, and this is a recorded recall gap rather than an oversight: a spec
# that wraps its rebuild procedure across lines is invisible to this check. Corpus
# state bullets are single long lines, so the gap is latent today.
#
# It is left open on evidence, not on caution. Widening the clause to run to the
# end of its paragraph was tried 2026-08-27 and is wrong: markdown list items sit
# on adjacent lines with no blank line between them, so a paragraph-scoped clause
# swallows the following bullets — and doing so silently DROPPED a real finding
# (multi-party-approval's `chain_to_events`), because an over-captured clause
# picked up a negation from a later bullet and the polarity guard suppressed it.
# A recall fix that costs precision on live findings is not a fix. The correct
# form stops at the next list item; it is not attempted while this class is
# mid-flight, because retuning a trigger over careful prose is what produced both
# of this file's earlier regressions.
REBUILD_CLAUSE = re.compile(r"\*Rebuild procedure:\*[^\n]*")
PAYLOAD_READ = re.compile(
    r"from each payload|from the payload|payload alone|each event's payload"
    r"|take `?\{[^}]*\}`? from|event'?s? `?data`?|`data` field"
    r"|each data's",
    re.I,
)
# A payload read that is being DENIED rather than performed. Privileged Access
# Provisioning's `request_to_capability` says the raw token appears in "**no**
# audit event data" — a clause asserting the ABSENCE of a payload read, inside a
# rebuild that sources from the Capability store's own immutable records and is
# genuinely outside this class. Matching it was a polarity error, not a loose
# trigger: the check read a negation as an assertion. Found by the class's
# 2026-08-27 classification sweep and pinned in test_checks.py, because this is
# the second time a regex over careful prose has gone wrong in a way a corpus
# count would not show (the first was P-atomic-audit's `modulo` suppressor).
PAYLOAD_READ_NEGATED = re.compile(
    r"(?:\bno\b|\bnot\b|never|\bnone\b)[^.]{0,60}"
    r"(?:audit )?event'?s? `?data`?"
    r"|appears? (?:on|in) \*?\*?no\*?\*?",
    re.I,
)

REBUILD_BOUNDED = re.compile(
    r"bound on the rebuild"
    r"|totality[^.]{0,90}(?:horizon|retention|purge)"
    r"|(?:horizon|retention|purge)[^.]{0,90}totality"
    r"|still live in the log|still readable|purged subset"
    r"|past the (?:retention )?horizon"
    r"|until its retention"
    # Added 2026-08-27, as the retention-horizon class landed its treatments and
    # patterns began stating the bound in the treatment's own vocabulary rather
    # than in the phrasing the exemplar happened to use.
    #
    # THE RULE THESE FOLLOW, learned the expensive way from P-atomic-audit's
    # `modulo` regression: a suppressor marker must be a STATEMENT OF THE BOUND,
    # never a signal that the author was being careful. `modulo` was the latter —
    # a hedge word that clusters around a pattern's most careful claims, so
    # suppressing on it silenced exactly the findings that mattered most. These
    # are the former: each asserts the specific fact the check asks for, and a
    # spec cannot contain one while leaving the totality unbounded.
    r"|not rebuildable"                      # the tier-2 statement outright
    r"|bounded by the audit"                 # names the bounding authority
    r"|split[s]? by retention state",        # the Contract-classification split
    re.I,
)


def check_rebuild_bound(patterns: dict[Path, Pattern]) -> list[Finding]:
    """Q. A `*Rebuild procedure:*` that reads an event payload with no stated
    bound on its own totality in the enclosing block."""
    findings: list[Finding] = []
    for p in patterns.values():
        cut = p.text.find("\n## Status")
        body = p.text if cut == -1 else p.text[:cut]
        for m in REBUILD_CLAUSE.finditer(body):
            clause = m.group(0)
            hit = PAYLOAD_READ.search(clause)
            if not hit:
                continue
            # polarity: a clause that DENIES a payload read is not a payload read.
            # Test the sentence the match sits in, not the whole clause, so an
            # unrelated negation elsewhere in a long rebuild does not suppress a
            # real finding — the failure mode the `modulo` regression taught.
            s0 = clause.rfind(". ", 0, hit.start())
            s0 = 0 if s0 == -1 else s0 + 2
            s1 = clause.find(".", hit.end())
            s1 = len(clause) if s1 == -1 else s1
            if PAYLOAD_READ_NEGATED.search(clause[s0:s1]):
                continue
            if REBUILD_BOUNDED.search(_enclosing_block(body, m.start())):
                continue
            findings.append(Finding(
                p.path, line_of(body, m.start()), "Q-rebuild-bound",
                "rebuild reads an event payload with no stated bound on its own "
                "totality — the substrate destroys `data` at the retention "
                "horizon (exemplar: Audit Trail's \"Bound on the rebuild's "
                "totality, stated rather than assumed\")",
            ))
    return findings

# --------------------------------------------------------------------------- #
# S-recording-step — the substrate's arm transcribed without its payload
# --------------------------------------------------------------------------- #
# Only Audit Trail (compositions/audit-trail.md) emits `recording-failure`, and
# its projected contract is `recording-failure(step)`: step-2 committed nothing,
# step-3 left an orphan attestation, step-4 left THE EVENT APPENDED. A composition
# that maps the arm to a bare token cannot tell a caller whether a retry will
# duplicate the record — which is exactly what one second gate found the retry
# doing. Precision: the trigger is a bare backticked token immediately followed
# by a mapping arrow, ON A LINE THAT ALSO NAMES `record_action`, in the body of
# a composition that links audit-trail.md. A bare token anywhere else (a
# signature block declaring the composition's own code, an example, a Ledger
# line quoting the defect) is not flagged — and neither is a bare token mapped
# from a PEER composition's call: Multi-Party Approval, Immutable Transaction
# Ledger and their kin re-export `recording-failure` bare at their own caller
# boundary, so a composer transcribing that arm is transcribing it correctly.
# The first draft assumed only Audit Trail emits the token and fired on
# Privileged Access Provisioning's transcription of Multi-Party Approval's
# arm (2026-08-29); the same-line `record_action` condition is what isolates
# the substrate's arm from its composers' — the step lists put the call and
# its mapping on one line, which is the corpus convention this leans on.
RECORDING_BARE_MAPPED = re.compile(r"(?<![\w-])`?recording-failure`?\s*→")
SUBSTRATE_CALL = re.compile(r"record_action")
AUDIT_TRAIL_LINK = re.compile(r"\(\.{0,2}/?(?:compositions/)?audit-trail\.md")


def check_recording_step(patterns: dict[Path, Pattern]) -> list[Finding]:
    """S. A bare `recording-failure` on the left of a mapping arrow, in a
    composition that composes Audit Trail, above the Status section."""
    findings: list[Finding] = []
    for p in patterns.values():
        if "/compositions/" not in p.path.as_posix() or p.path.stem == "audit-trail":
            continue
        cut = p.text.find("\n## Status")
        body = p.text if cut == -1 else p.text[:cut]
        if not AUDIT_TRAIL_LINK.search(body):
            continue
        for m in RECORDING_BARE_MAPPED.finditer(body):
            ls = body.rfind("\n", 0, m.start()) + 1
            le = body.find("\n", m.start())
            le = len(body) if le == -1 else le
            if not SUBSTRATE_CALL.search(body[ls:le]):
                continue
            findings.append(Finding(
                p.path, line_of(body, m.start()), "S-recording-step",
                "substrate arm transcribed without its payload — the contract "
                "is `recording-failure(step)`, and step-4 means the event is "
                "already appended (retry duplicates it); carry the step and "
                "land each arm",
            ))
    return findings


# --------------------------------------------------------------------------- #
# T-seal-key — a seal presentation keyed by an identifier, not by log position
# --------------------------------------------------------------------------- #
# `verify_record` takes the payloads of every event in the covering seal range,
# in ascending sequence_number order (Audit Trail Invariant 7). A map keyed by
# the composition's own identifier holds at most one payload per event, so under
# interval cadence every verification fails with a seal-record-set mismatch and
# the acceptance check reports tampering on an intact log. Two shapes: a
# subscript `original_event_payloads[<x>_id]`, and the phrase "keyed by
# `<x>_id`" within a short distance after the map's name. Keying by `n`, `lo`,
# `hi`, or `sequence_number` is the exemplar (Chain of Custody, Forensic
# Recovery) and is silent.
SEAL_MAP_ID_SUBSCRIPT = re.compile(r"original_event_payloads\[\s*`?\w*_id`?\s*\]")
SEAL_MAP_KEYED_BY_ID = re.compile(
    r"original_event_payloads`?[^.\n]{0,80}?keyed by (?:the )?`\w*_id`", re.I)


def check_seal_key(patterns: dict[Path, Pattern]) -> list[Finding]:
    """T. An `original_event_payloads` map keyed by an identifier."""
    findings: list[Finding] = []
    for p in patterns.values():
        cut = p.text.find("\n## Status")
        body = p.text if cut == -1 else p.text[:cut]
        seen: set[int] = set()
        for rx in (SEAL_MAP_ID_SUBSCRIPT, SEAL_MAP_KEYED_BY_ID):
            for m in rx.finditer(body):
                ln = line_of(body, m.start())
                if ln in seen:
                    continue
                seen.add(ln)
                findings.append(Finding(
                    p.path, ln, "T-seal-key",
                    "seal presentation keyed by an identifier — a seal commits "
                    "to a sequence range, so the map is keyed by "
                    "`sequence_number` over the covering range `read_record` "
                    "names (exemplar: Chain of Custody [Verify Custody])",
                ))
    return findings


# --------------------------------------------------------------------------- #
# U-retry-bit — one exported token on both sides of the commit
# --------------------------------------------------------------------------- #
# A composition's signature is a transcription of its own steps to a caller who
# cannot see them. Where the same bare `rejected(recording-failure)` lands at a
# step before the act's irreversible constituent commit (nothing on disk; retry
# is safe) and at a step after it (the constituent record exists; a retry
# re-runs the act), the caller who receives the token has been told nothing.
# The check walks each `#### `action`` section's numbered steps above Status:
# the first step carrying a qualified constituent call that is neither a read
# (`read`, `read_record`, `check`, `verify_*`, `history_for`, `active_for`,
# `get`, `query`, `list`, `enumerate`, `lookup`, `is_*`, `has_*`, `status`,
# `current`, `resolve`, `evaluate`, `permitted`, `find`, `peek`) nor `AuditTrail.record_action` (the intent
# record precedes the act by design and its own arm is retry-safe) is the
# commit; a bare landing strictly before it and one strictly after it fire.
# The step-2/step-3 rejection at the commit step itself is on neither side —
# the constituent refused, so nothing landed — and is not counted.
ACTION_HEADING = re.compile(r"(?m)^#### `([a-z_]+)`")
STEP_LINE = re.compile(r"(?m)^(\d+)\.[^\n]*")
QUALIFIED_CALL = re.compile(r"\b([A-Z][A-Za-z]+)\.([a-z_]+)\(")
READ_METHOD = re.compile(
    r"^(read|verify|check|history|active|get|query|list|enumerate|lookup|is_|"
    r"has_|status|current|resolve|evaluate|permitted|find|peek)")
BARE_BOUNDARY_TOKEN = re.compile(r"`rejected\(recording-failure\)`")


def _commit_calls(line: str) -> list[tuple[str, str]]:
    return [c for c in QUALIFIED_CALL.findall(line)
            if c != ("AuditTrail", "record_action") and not READ_METHOD.match(c[1])]


def check_retry_bit(patterns: dict[Path, Pattern]) -> list[Finding]:
    """U. A bare `rejected(recording-failure)` landed on both sides of an
    action's first constituent commit, in a composition that composes Audit
    Trail."""
    findings: list[Finding] = []
    for p in patterns.values():
        if "/compositions/" not in p.path.as_posix() or p.path.stem == "audit-trail":
            continue
        cut = p.text.find("\n## Status")
        body = p.text if cut == -1 else p.text[:cut]
        if not AUDIT_TRAIL_LINK.search(body):
            continue
        heads = list(ACTION_HEADING.finditer(body))
        for i, h in enumerate(heads):
            start = h.end()
            end = heads[i + 1].start() if i + 1 < len(heads) else len(body)
            sec = body[start:end]
            commit: int | None = None
            before: list[tuple[int, int]] = []
            after: list[tuple[int, int]] = []
            for m in STEP_LINE.finditer(sec):
                step = int(m.group(1))
                line = m.group(0)
                if commit is None and _commit_calls(line):
                    commit = step
                if BARE_BOUNDARY_TOKEN.search(line):
                    if commit is None or step < commit:
                        before.append((step, start + m.start()))
                    elif step > commit:
                        after.append((step, start + m.start()))
            if commit is None or not before or not after:
                continue
            findings.append(Finding(
                p.path, line_of(body, after[0][1]), "U-retry-bit",
                f"`{h.group(1)}` lands a bare `rejected(recording-failure)` at "
                f"step {before[0][0]} (before the commit at step {commit}) and "
                f"at step {after[0][0]} (after it) — the caller cannot tell "
                "whether a retry is safe; carry the position "
                "(`recording-failure(intent | outcome)`) in the signature",
            ))
    return findings


# --------------------------------------------------------------------------- #
# Status grammar / mirror (G, H, I)
# --------------------------------------------------------------------------- #

# the pinned status-token grammar (pressure-testing.md §Status line format)
STATUS_TOKEN_FORMS = [
    re.compile(r"^draft$"),
    re.compile(r"^unresolved$"),
    re.compile(r"^partially resolved$"),
    re.compile(r"^grounded on Final Critique \d+ — \d{4}-\d{2}-\d{2}$"),
    re.compile(r"^grounded \(English\) on Final Critique \d+ — \d{4}-\d{2}-\d{2} — formal layer pending$"),
    re.compile(r"^grounded on Final Critique \d+ — \d{4}-\d{2}-\d{2} — .+ pending$"),
]
STATUS_SECTION = re.compile(r"^## Status\s*$", re.M)
LEADING_TOKEN = re.compile(r"^`([^`]+)`")


def status_token_of(text: str) -> tuple[str | None, int]:
    """Return (token, line) of the first non-empty line after `## Status`,
    or (None, line-of-section / 0) when the section or token is absent."""
    m = STATUS_SECTION.search(text)
    if not m:
        return None, 0
    rest = text[m.end():]
    offset = m.end()
    for raw in rest.split("\n"):
        if raw.strip():
            tok = LEADING_TOKEN.match(raw.strip())
            return (tok.group(1) if tok else None), line_of(text, offset)
        offset += len(raw) + 1
    return None, line_of(text, m.start())


# V-signature-alternation landed 2026-08-30 GATING, from gate 8's measurement that
# repair rounds were seeding two thirds of the next gate's findings and that ten
# of twelve such findings were mechanically decidable. It is pure syntax — no
# semantics — which is why it could be promoted the day it landed: the corpus
# swept to zero after one true defect was fixed (`customer-onboarding`'s
# `initiate_onboarding`, where `invalid-request` and `invalid-credential` sat on
# consecutive lines with no separator, so the alternation read as one malformed
# code and a generator would have emitted one arm where two were meant).
def _rejected_regions(sig: str) -> list[str]:
    """Each `rejected( ... )` region of a signature block, parens matched."""
    out: list[str] = []
    i = 0
    while True:
        j = sig.find("rejected(", i)
        if j < 0:
            return out
        depth = 0
        for k in range(j + len("rejected"), len(sig)):
            if sig[k] == "(":
                depth += 1
            elif sig[k] == ")":
                depth -= 1
                if depth == 0:
                    out.append(sig[j:k + 1])
                    i = k + 1
                    break
        else:
            return out


def _unseparated(region: str) -> list[str]:
    """Alternatives on their own line that no `|` separates from the one before.

    Depth is tracked so a nested group spanning lines — `enrollment-failed(a |
    b)` — is never read as a missing separator; a line is a new alternative
    only at depth 1, and only where the previous non-empty line ended in
    neither `(` nor `|`.
    """
    bad: list[str] = []
    lines = region.split("\n")
    if len(lines) < 2:
        return bad
    depth = 0
    prev: str | None = None
    for ln in lines:
        stripped = ln.strip()
        at = depth
        depth += ln.count("(") - ln.count(")")
        if prev is not None and stripped and at == 1:
            token = stripped.lstrip("|").strip()
            if (token and not stripped.startswith("|") and not stripped.startswith(")")
                    and not prev.endswith("(") and not prev.endswith("|")):
                bad.append(token.split()[0].strip("`,"))
        if stripped:
            prev = stripped
    return bad


SIGNATURE_BLOCK = re.compile(r"```\n(.*?)\n```", re.S)


KNOWN_DIRS = {"atoms", "compositions", "demos", "grants", "internal", "tools",
              "working-ideas", "build-terms", "_data", "_includes", "_layouts",
              "_sass", "assets", ".github"}


def check_stray_directory(root: Path) -> list[Finding]:
    """M. A top-level directory outside the closed set. A past session created
    `Claude outputs/` and filed real work in it — formal models, gate records,
    verification scripts — where no instrument read them and the reading order
    did not name them. The set is closed so that adding to it is a decision
    rather than a discovery (AGENTS.md, Session hygiene)."""
    findings: list[Finding] = []
    for d in sorted(p for p in root.iterdir() if p.is_dir()):
        if d.name.startswith(".") or d.name in KNOWN_DIRS:
            continue
        n = sum(1 for _ in d.rglob("*") if _.is_file())
        findings.append(Finding(
            d, 1, "M-stray-directory",
            f"`{d.name}/` is not in the repo's closed top-level set and holds "
            f"{n} file(s) — a file belongs in an existing home or in the chat"))
    return findings


def check_formal_siblings(root: Path, patterns: dict[Path, Pattern]) -> list[Finding]:
    """M. The formal-model family, which no instrument read until now. Two checks:
    a model's declared module name must match its file stem, and a spec's Ledger
    `formal:` line must name models that sit beside the spec. The rename of
    2026-09-13 had to edit two Alloy module declarations by hand precisely because
    nothing checked the first, which is the fix loop's boundary stated as a
    symptom (council read 37)."""
    findings: list[Finding] = []
    ALS = re.compile(r"^module\s+([A-Za-z_0-9]+)", re.M)
    TLA = re.compile(r"^-+\s*MODULE\s+([A-Za-z_0-9-]+)", re.M)
    for d in ("atoms", "compositions"):
        for f in sorted((root / d).glob("*.als")) + sorted((root / d).glob("*.tla")):
            text = f.read_text(encoding="utf-8", errors="replace")
            m = (ALS if f.suffix == ".als" else TLA).search(text)
            if not m:
                findings.append(Finding(f, 1, "M-model-unnamed",
                    "formal model declares no module name"))
                continue
            want = f.stem.replace("-", "_") if f.suffix == ".als" else f.stem
            if m.group(1) != want:
                findings.append(Finding(f, line_of(text, m.start()), "M-model-name",
                    f"module is `{m.group(1)}` and the file is `{f.name}` — a rename "
                    f"that misses the declaration leaves the model orphaned from its spec"))
    for p in patterns.values():
        fm = re.search(r"^formal:\s*(.+)$", p.text, re.M)
        if not fm:
            continue
        for name in dict.fromkeys(re.findall(r"([A-Za-z0-9_-]+\.(?:als|tla))", fm.group(1))):
            if (p.path.parent / name).exists():
                continue
            found = next((q for q in root.rglob(name) if ".git" not in q.parts), None)
            where = f"; it sits at {found.relative_to(root)}" if found else ""
            findings.append(Finding(
                p.path, line_of(p.text, fm.start()), "M-model-misplaced",
                f"the Ledger names `{name}`, which is not beside this spec{where}"))
    return findings


def check_stale_census(root: Path, patterns: dict[Path, Pattern]) -> list[Finding]:
    """W. A label-family count written into the grammar's watch list that no
    longer matches the corpus. Section 18 carried these by hand and they went
    stale on arrival three council reads running; the census is mechanical, so
    disagreeing with it is a finding rather than a discovery (council read 33)."""
    findings: list[Finding] = []
    grammar = root / "GRACE-lang.md"
    try:
        text = grammar.read_text(encoding="utf-8")
    except OSError:
        return findings
    census: dict[str, int] = {}
    for p in patterns.values():
        for m in re.finditer(r"^\s*([A-Z][A-Za-z ]*?) \d+(?:\.\d+)?[a-z]?:", p.text, re.M):
            census.setdefault(m.group(1), set()).add(p.path.name)  # type: ignore[arg-type]
    # the >= term-entry census, stated in section 18 to inform the operator
    # ruling. Counted by hand twice and wrong both times -- once including
    # adversarial-scenario headings as term entries, once miscounting the specs
    # -- which is the same disease as the family counts and takes the same cure
    # (council read 34).
    ge_entries = 0
    ge_specs = set()
    for p in patterns.values():
        for m in re.finditer(r"^#### (.+)$((?:\n(?!####).*)*)", p.text, re.M):
            body = m.group(2)
            if re.search(r"^Kind:", body, re.M) and "\u2265" in body:
                ge_entries += 1
                ge_specs.add(p.path.name)
    gm = re.search(r"(\d+) term entries across (\d+) specs carry `\u2265`", text)
    if gm and (int(gm.group(1)), int(gm.group(2))) != (ge_entries, len(ge_specs)):
        findings.append(Finding(
            grammar, line_of(text, gm.start()), "W-stale-census",
            f"the watch list says {gm.group(1)} term entries across "
            f"{gm.group(2)} specs carry `\u2265`; the corpus has "
            f"{ge_entries} across {len(ge_specs)}"))
    for name, spec in re.findall(r"`([A-Z][A-Za-z ]+)` \((\d+)\)", text):
        actual = len(census.get(name, ()))
        if actual != int(spec):
            findings.append(Finding(
                grammar, line_of(text, text.index(f"`{name}` ({spec})")),
                "W-stale-census",
                f"the watch list says `{name}` is in {spec} specs; the corpus "
                f"has {actual} (tools/grace/cites.py --drift)"))
    # the inverse reading, and the one the loop above cannot give: a family the
    # corpus carries at the promotion threshold that the watch list does not
    # name at all. The comparison above only ever reads counts somebody already
    # wrote down, so a family can cross three in silence -- which is read 58's
    # lesson one layer out, the census *list* being the second hand-census.
    # Standard families are excluded: the grammar owns those and they are not
    # promotion candidates (council read 63).
    listed = {n for n, _ in re.findall(r"`([A-Z][A-Za-z ]+)` \((\d+)\)", text)}
    std: set[str] = set()
    sm = re.search(r"^Term standard label family: (.+)$", text, re.M)
    if sm:
        # the family line's value set, names bare since v0.51: `Name (gloss) | …`
        std = {x.strip().strip("`") for x in re.findall(r"(?:^|\|)\s*([^|(]+?)\s*\(", sm.group(1))}
    clause = re.search(r"a label family recurring across specs outside the standard set", text)
    clause_line = line_of(text, clause.start()) if clause else 1
    for name, specs in sorted(census.items()):
        if name in listed or name in std or len(specs) < 3:
            continue
        findings.append(Finding(
            grammar, clause_line, "W-stale-census",
            f"the watch list names no `{name}`; the corpus carries it in "
            f"{len(specs)} specs, at or past the promotion threshold "
            f"(Standard label 4; tools/grace/cites.py --drift)"))
    return findings


def check_acceptance_surface(patterns: dict[Path, Pattern]) -> list[Finding]:
    """Y. A migrated spec that states no acceptance posture at all. Generation
    acceptance was optional for non-regulated primitives, and three atoms took
    the option by saying nothing -- Duplicate Prevention, Event Log and Personal
    Todo, the three earliest migrations, composed between them by eleven of the
    corpus's compositions. The cost is paid one layer up: Undo History rests
    thirteen Check rules on two constituents that audit none of their own, and
    no instrument said so, because silence and a considered decline read alike.

    Presence is now mandatory and the posture is what has to be discoverable, so
    two shapes satisfy this and a third does not. A spec carries an acceptance
    section with at least one `Check` or `External check` rule, or it declines
    by delegation on its own `Term qualifiers` line -- `audit declined`, with
    the pattern that owns the surface named after the dash. Silence is the only
    thing outlawed, and a decline that names no owner is silence with a label on
    it (council read 65)."""
    findings: list[Finding] = []
    for p in patterns.values():
        if not re.search(r"^Term qualifiers:.*\bmigrated\b", p.text, re.M):
            continue  # the unmigrated corpus is not held to this
        section = re.search(r"^## Generation acceptance\s*$", p.text, re.M)
        if section:
            if re.search(r"^\s*(?:Check|External check) \d", p.text, re.M):
                continue
            findings.append(Finding(
                p.path, line_of(p.text, section.start()), "Y-acceptance-surface",
                "carries a Generation acceptance section with no `Check` and no "
                "`External check` rule — a section nothing audits is the silence "
                "the rule forbids, wearing a heading"))
            continue
        decline = re.search(r"^Term qualifiers:.*`audit declined` — (.*)$", p.text, re.M)
        if decline is None:
            findings.append(Finding(
                p.path, 1, "Y-acceptance-surface",
                "is migrated and states no acceptance posture — carry a "
                "`## Generation acceptance` section, or decline by delegation on "
                "the qualifiers line (`audit declined` — <the pattern that owns "
                "the audit surface>)"))
            continue
        if not re.search(r"[A-Za-z]", decline.group(1).split(";")[0]):
            findings.append(Finding(
                p.path, line_of(p.text, decline.start()), "Y-acceptance-surface",
                "declines the audit surface and names no owner — a decline is by "
                "delegation, never by silence"))
    return findings


def check_migration_seam(patterns: dict[Path, Pattern]) -> list[Finding]:
    """M. A spec carrying the same section heading twice — two owners for one
    section.

    Built at council read 30 for one heading: a migrated atom carried two
    `## Terms` headings, because the extraction began at the old section
    heading rather than at the first term entry. The *shape* is a spec with two
    owners for one section; the check named the one section it was found on,
    and stayed that narrow for fifteen versions.

    Widened at council read 72, which found what the narrow cut could not see:
    Login and Idempotent Reservation each carried `## Generation acceptance`
    twice — the migrated rules in the declared position, and the pre-migration
    prose copy surviving after `## Standards references`, with its own
    `### External checks` beneath it in the second case. Six of Login's open
    Ledger lines cited the stale copy by ordinal, so the doubling was
    load-bearing rather than inert, and both specs had passed every run of both
    tools since they were migrated.

    The narrowing was not a cheaper version of the general check. It is the
    same lesson `M-orphan-forthcoming` learned at council read 68 between
    *mentioned* and *listed*: an instrument cut to its first specimen reports
    that specimen and nothing else. Unmigrated specs are scanned too — a
    doubled section is a defect whatever language the spec is written in
    (Authority 3)."""
    findings: list[Finding] = []
    for p in patterns.values():
        for level in ("## ", "### "):
            seen: dict[str, int] = {}
            for m in re.finditer(rf"^{level}(?!#)(.+?)\s*$", p.text, re.M):
                name = m.group(1).strip()
                if name in seen:
                    findings.append(Finding(
                        p.path, line_of(p.text, m.start()), "M-section-doubled",
                        f"the spec carries `{level.strip()} {name}` twice (first at "
                        f"line {seen[name]}) — two owners for one section, so a "
                        f"citation of it resolves to either (Authority 3)"))
                else:
                    seen[name] = line_of(p.text, m.start())
    return findings

def check_end_marker(patterns: dict[Path, Pattern]) -> list[Finding]:
    """M. A migrated spec whose last line is not `NOTE: End of <Name>.`

    The marker is not decoration. These specs are read by council members
    through a paste, and a paste that silently truncates looks exactly like a
    spec that is short a section — the reader reviews the fragment and reports
    findings against rules the spec does carry. The marker makes truncation
    self-evident at the only place the reader can check it: if the last line
    is not the marker, what arrived is not the spec.

    Instrumented at 27 of 27 rather than after a drift, because the census was
    perfect the day Provisional Commitment shipped without one and a hand check
    caught it (council read 35). A convention with a real function and no
    enforcement is a convention with an expiry date."""
    findings: list[Finding] = []
    for p in patterns.values():
        if not re.search(r"^Term qualifiers:.*\bmigrated\b", p.text, re.M):
            continue  # the marker is a migration convention
        lines = [ln for ln in p.text.rstrip().split("\n") if ln.strip()]
        if not lines:
            continue
        tm = re.search(r"^title:\s*(.+?)\s*$", p.text, re.M)
        if not tm:
            continue  # no front-matter title to name the marker with
        want = f"NOTE: End of {tm.group(1)}."
        if lines[-1].strip() != want:
            findings.append(Finding(
                p.path, len(p.text.rstrip().split("\n")), "M-end-marker",
                f"a migrated spec's last line is `{lines[-1].strip()[:48]}` and not "
                f"`{want}` — the marker is how a reader tells a truncated paste "
                f"from a short spec"))
    return findings


def check_term_coverage(patterns: dict[Path, Pattern]) -> list[Finding]:
    """O. A field the spec rules over with no term entry, or a term entry the
    registry cannot reach.

    The registry is the citation substrate: a `[Marker]` resolves through a link
    line to a term entry, and a reader following a rule's field name lands
    there. Four ways that breaks, and until this check only two were watched.
    `O-term-dangling` catches a marker with no link line; `O-term-orphan`
    catches a link line no marker uses; `O-term-anchor` (council read 44)
    catches a link line whose anchor names no entry. The two this adds are the
    one this adds is the fourth: an entry the link block never names, so no
    marker can reach it however correctly the prose is written — Medication
    Order's `On Hold Rejection`, and Invitation's `Expired Rejection` before it
    (council read 45).

    The fifth way — a field the rules turn on with no entry at all — is real and
    is NOT checked here. Deciding it needs the `Term records` line to
    distinguish a record name from a field name from a derived index, and it
    does not: Provenance declares two records on that line and Audit Trail
    declares named indexes there, so a naive read reports both as missing
    fields. A check that fires on correct specs teaches readers to ignore it,
    which is the failure every census in this window was instrumented against.
    Docketed instead."""
    findings: list[Finding] = []
    LINKNAME = re.compile(r"^\[([^\]]+)\]:\s*#\S+\s*$", re.M)

    # A `####` heading is a term entry only when a `Kind:` line follows it. The
    # corpus also uses `####` for adversarial scenarios, action signatures and
    # subsection titles, and reading those as term entries is the same error
    # that made the `>=` census wrong twice (council read 34).
    def entry_names(text: str) -> list[str]:
        parts = re.split(r"^#### ([^\n]+)$", text, flags=re.M)
        return [n.strip() for n, body in zip(parts[1::2], parts[2::2])
                if re.search(r"^Kind:", body, re.M)]

    for p in patterns.values():
        heads = entry_names(p.text)
        if not heads:
            continue  # no term entries: not a migrated registry
        linked = {m.group(1) for m in LINKNAME.finditer(p.text)}
        for h in heads:
            if h not in linked:
                findings.append(Finding(
                    p.path, line_of(p.text, p.text.find(f"#### {h}")),
                    "O-term-unreachable",
                    f"the term entry `{h}` has no registry link line, so no "
                    f"`[{h}]` marker can resolve to it"))
    return findings


def check_dead_anchors(patterns: dict[Path, Pattern]) -> list[Finding]:
    """O. A term-registry link line pointing at a heading the page does not have.

    The registry's shortcut-reference block maps `[Name]: #anchor` onto a term
    entry's heading. `O-term-dangling` catches a *marker* with no link line and
    `O-term-orphan` catches a *definition* nothing uses; neither looks at a link
    line whose anchor resolves to nothing, because neither starts from the link
    block. Medication Order's migration shipped thirteen of them at once — every
    attribution and instant field of the four terminal transitions had a link
    and no entry — and they are invisible in review, because the prose reads
    correctly and only a rendered click finds the hole (council read 44).

    Anchors are matched the way kramdown generates them from an `####` heading:
    lower-cased, non-alphanumerics collapsed to hyphens, ends trimmed."""
    findings: list[Finding] = []
    HEADING = re.compile(r"^#### (.+)$", re.M)
    LINKLINE = re.compile(r"^\[([^\]]+)\]:\s*#(\S+)\s*$", re.M)

    def slug(s: str) -> str:
        return re.sub(r"[^a-z0-9]+", "-", s.strip().lower()).strip("-")

    for p in patterns.values():
        heads = {slug(h) for h in HEADING.findall(p.text)}
        if not heads:
            continue  # a spec with no term entries has no registry to check
        for m in LINKLINE.finditer(p.text):
            if m.group(2) not in heads:
                findings.append(Finding(
                    p.path, line_of(p.text, m.start()), "O-term-anchor",
                    f"`[{m.group(1)}]` links to `#{m.group(2)}`, which names no "
                    f"term entry on this page — the marker renders as a dead "
                    f"link rather than as a missing one"))
    return findings


def check_provenance_drift(root: Path, patterns: dict[Path, Pattern]) -> list[Finding]:
    """R. A Ledger provenance line that changed without the commit saying so.

    `status:`, `formal:` and `last gate:` record what a gate and a model run
    actually produced. Nothing in a migration should touch them — a migration
    rewrites language, not history — and yet two of four migrations in one day
    invented them: a critique number bumped, a date moved, a twin count raised
    from two to three. One of the fabrications shipped, and a council read
    quoted it back as a receipt, because a reviewer reads what the page says
    (council read 42).

    So the check is a comparison against git rather than a shape rule: if a
    working-tree spec's provenance lines differ from the same lines at HEAD, say
    so. A real re-grounding changes them legitimately — that is why this reports
    the drift rather than forbidding it, and why the message asks for the gate
    rather than asserting a fault. It is clean when nothing moved, which is the
    state a language-only migration must be in."""
    findings: list[Finding] = []
    KEYS = ("status:", "formal:", "last gate:")

    def provenance(text: str) -> dict[str, str]:
        out = {}
        for ln in text.split("\n"):
            for k in KEYS:
                if ln.startswith(k):
                    out[k] = ln.strip()
        return out

    def git(*args, timeout=20):
        try:
            return subprocess.run(["git", "--no-optional-locks", *args], cwd=root,
                                  capture_output=True, text=True, timeout=timeout)
        except (OSError, subprocess.SubprocessError):
            return None

    if (probe := git("rev-parse", "--is-inside-work-tree", timeout=10)) is None:
        return findings
    if probe.returncode != 0:
        return findings

    # Ask git once which files differ from HEAD rather than reading every spec
    # out of HEAD. A provenance line cannot have drifted in a file that has not
    # changed, so the unchanged majority costs nothing. Worth recording that this
    # was NOT the slow check: it was blamed for the linter's 39 seconds on a
    # guess, the batching changed nothing measurable, and a profile then put the
    # cost in `check_rests_on_refs` and `check_council_register` instead. The
    # batching is kept because it is correct, not because it was the cure.
    changed = git("diff", "--name-only", "HEAD")
    if changed is None or changed.returncode != 0:
        return findings
    touched = {ln.strip() for ln in changed.stdout.split("\n") if ln.strip()}
    if not touched:
        return findings

    for p in patterns.values():
        rel = p.path.relative_to(root).as_posix()
        if rel not in touched:
            continue
        show = git("show", f"HEAD:{rel}")
        if show is None or show.returncode != 0:
            continue  # new file; nothing to compare against
        was, now = provenance(show.stdout), provenance(p.text)
        for k in KEYS:
            if k in was and k in now and was[k] != now[k]:
                findings.append(Finding(
                    p.path, line_of(p.text, p.text.find(now[k])),
                    "R-provenance-drift",
                    f"`{k}` changed from `{was[k]}` to `{now[k]}` — provenance "
                    f"records what a gate produced, so name the gate in the "
                    f"commit or restore the line"))
    return findings


def check_seam_injections(patterns: dict[Path, Pattern]) -> list[Finding]:
    """M. A spec obliging the deployment to supply something at the seam, whose
    own `Term seam` declaration does not name it.

    The seam declaration is a spec's list of what crosses its I/O boundary, and
    it is how a reader decides whether a transition is the pure function the
    logic-confinement discipline claims. Two migrations running shipped a seam
    naming two injections while the rules consumed a third — Provisional
    Commitment's registry verdict, then Credential's derivation registry — and
    both were found by a human reading the rules against the declaration
    (council read 38, council read 41). Twice is a habit, so it becomes a
    check: every `MUST supply X at the seam` must find X's significant words in
    the seam declaration. `now` is satisfied by the clock reading, which is
    what every seam declaration in the corpus calls it.

    The reverse direction — a seam naming an injection no rule consumes — is
    deliberately not checked; it has never failed, and a spec may name a seam
    input its rules reach only through a declared term."""
    findings: list[Finding] = []
    SUPPLY = re.compile(r"MUST supply (.+?) at the seam")
    SEAM = re.compile(r"^Term seam:(.+)$", re.M)
    STOP = {"the", "a", "an", "and", "or", "s"}
    for p in patterns.values():
        seam = SEAM.search(p.text)
        if not seam:
            continue  # a spec that declares no seam obliges nothing at one
        haystack = set(re.findall(r"[a-z_]+", seam.group(1).lower()))
        for m in SUPPLY.finditer(p.text):
            phrase = m.group(1).lower()
            if phrase.strip() == "now":
                words = {"clock"}
            else:
                words = {w for w in re.findall(r"[a-z_]+", phrase) if w not in STOP}
            missing = words - haystack
            if missing:
                findings.append(Finding(
                    p.path, line_of(p.text, m.start()), "M-seam-injection",
                    f"the deployment is obliged to supply `{m.group(1)}` at the "
                    f"seam, and the seam declaration does not name it "
                    f"({', '.join(sorted(missing))}) — a transition consuming an "
                    f"undeclared input is not the pure function logic "
                    f"confinement claims"))
    return findings


def check_council_register(root: Path) -> list[Finding]:
    """M. A council-read number the register assigns twice, or a citation to a
    read the register does not carry.

    Council-read numbers are the corpus's only cross-document citation key that
    no instrument reads, and they drifted exactly as an unheld number does: the
    register already carried 35, 36 and 37 when a second 35 was written on top
    of them and then cited eleven times across three documents and a commit
    subject (council read 39). Two checks, both mechanical: the register must
    not assign one number twice, and a `council read N` citation must name a
    read the register carries. Nothing here checks that a citation aims at the
    *right* read — that is the human reading Principle 8 holds."""
    findings: list[Finding] = []
    reg = root / "governance.md"
    try:
        text = reg.read_text(encoding="utf-8")
    except OSError:
        return findings
    entries = list(re.finditer(r"^- \*\*Council read (\d+) — ", text, re.M))
    if not entries:
        return findings
    seen: dict[str, int] = {}
    for m in entries:
        n = m.group(1)
        if n in seen:
            findings.append(Finding(
                reg, line_of(text, m.start()), "M-register-number",
                f"the register assigns council read {n} twice (first at line "
                f"{seen[n]}) — the number is a citation key, so a duplicate "
                f"makes every citation of it ambiguous"))
        else:
            seen[n] = line_of(text, m.start())
    known = set(seen)
    # Prune the walk rather than filter after it: this tree carries 417 markdown
    # files and 208 of them are inside `node_modules`, so `rglob` was descending
    # a vendored dependency tree to throw it away. Second-slowest check in the
    # linter until measured (council read 46).
    def corpus_md(base: Path):
        for dirpath, dirnames, filenames in os.walk(base):
            dirnames[:] = [d for d in dirnames
                           if d != "node_modules" and not d.startswith(".")]
            for fn in sorted(filenames):
                if fn.endswith(".md"):
                    yield Path(dirpath) / fn

    for f in corpus_md(root):
        try:
            body = f.read_text(encoding="utf-8")
        except OSError:
            continue
        for m in re.finditer(r"council read (\d+)", body):
            if m.group(1) not in known:
                findings.append(Finding(
                    f, line_of(body, m.start()), "M-register-citation",
                    f"cites council read {m.group(1)}, which the register does "
                    f"not carry"))
    return findings


def check_signature_alternation(patterns: dict[Path, Pattern]) -> list[Finding]:
    """V. A rejection alternation in a signature block whose items are not
    separated by `|`, so two intended alternatives read as one code."""
    findings: list[Finding] = []
    for p in patterns.values():
        for h in ACTION_HEADING.finditer(p.text):
            tail = p.text[h.end():]
            nxt = ACTION_HEADING.search(tail)
            sec = tail[:nxt.start()] if nxt else tail
            m = SIGNATURE_BLOCK.search(sec)
            if not m:
                continue
            for region in _rejected_regions(m.group(1)):
                for item in _unseparated(region):
                    findings.append(Finding(
                        p.path, line_of(p.text, h.end() + m.start()),
                        "V-signature-alternation",
                        f"`{h.group(1)}`: `{item}` is not separated from the "
                        f"alternative before it — the alternation reads as one code"))
    return findings

# W-step-reference landed 2026-08-30 GATING and is PREVENTIVE: unlike V, it has
# never fired on this corpus, and it did not fix a defect on the way in. It is
# here because it sits on the decidable side of the line the three prototypes of
# that day drew — it asks only what a document CONTAINS (does that action have a
# step 5?), never what a sentence CLAIMS. The two prototypes that asked the
# second question were not promoted. If this stays silent for a long time it can
# be retired; silence is its expected state, not evidence that it works.
STEP_REF_A = re.compile(r"\[([A-Z][A-Za-z ]*)\]\s+step\s+(\d+)")
STEP_REF_B = re.compile(r"step\s+(\d+)\s+of\s+\[([A-Z][A-Za-z ]*)\]")
NUMBERED_STEP = re.compile(r"(?m)^(\d+)\. ")


def _highest_steps(text: str) -> dict[str, int]:
    out: dict[str, int] = {}
    heads = list(ACTION_HEADING.finditer(text))
    for i, h in enumerate(heads):
        end = heads[i + 1].start() if i + 1 < len(heads) else len(text)
        nums = [int(m.group(1)) for m in NUMBERED_STEP.finditer(text[h.end():end])]
        out[h.group(1)] = max(nums) if nums else 0
    return out


def check_step_reference(patterns: dict[Path, Pattern]) -> list[Finding]:
    """W. A cross-reference to `[Action] step N` where that action declares
    fewer than N numbered steps."""
    findings: list[Finding] = []
    for p in patterns.values():
        highest = _highest_steps(p.text)
        seen: list[tuple[str, int, int]] = []
        for m in STEP_REF_A.finditer(p.text):
            seen.append((m.group(1), int(m.group(2)), m.start()))
        for m in STEP_REF_B.finditer(p.text):
            seen.append((m.group(2), int(m.group(1)), m.start()))
        for display, n, at in seen:
            name = display.strip().lower().replace(" ", "_")
            if name in highest and n > highest[name]:
                findings.append(Finding(
                    p.path, line_of(p.text, at), "W-step-reference",
                    f"`[{display}] step {n}` — that action declares "
                    f"{highest[name]} numbered step(s)"))
    return findings

def check_status_grammar(patterns: dict[Path, Pattern]) -> list[Finding]:
    """G. `## Status` present; first line starts with one conformant backticked token."""
    findings: list[Finding] = []
    for p in patterns.values():
        m = STATUS_SECTION.search(p.text)
        if not m:
            findings.append(Finding(
                p.path, 1, "G-status-section-missing",
                "no `## Status` section (required container; a top-of-file "
                "**Status:** line is a shape deviation)",
            ))
            continue
        token, line = status_token_of(p.text)
        if token is None:
            findings.append(Finding(
                p.path, line, "G-status-grammar",
                "Status line does not start with a backticked status token",
            ))
            continue
        if not any(rx.match(token) for rx in STATUS_TOKEN_FORMS):
            findings.append(Finding(
                p.path, line, "G-status-grammar",
                f"token `{token}` matches no form of the pinned grammar "
                f"(pressure-testing.md §Status line format)",
            ))
    return findings


# a roadmap list entry that links a pattern AND carries a token after the em-dash:
#   - **[Name](./compositions/x.md)** — `token` ...
ROADMAP_LIST_ENTRY = re.compile(
    r"^- \*\*\[[^\]]+\]\((\./(?:atoms|compositions)/[^)]+?\.md)\)\*\* — `([^`]+)`",
    re.M,
)


def check_status_mirror(root: Path, patterns: dict[Path, Pattern]) -> list[Finding]:
    """H. roadmap.md linked list entries mirror the pattern file's status token.

    High precision: fires only on list entries that both link a pattern file and
    carry a backticked token immediately after the em-dash. Unlinked table rows
    are not checked (no machine-resolvable file mapping); the table is covered by
    the duplicate-row check (I) and by review.
    """
    findings: list[Finding] = []
    roadmap = root / "roadmap.md"
    if not roadmap.exists():
        return findings
    text = roadmap.read_text(encoding="utf-8")
    by_resolved = {p.path.resolve(): p for p in patterns.values()}
    for m in ROADMAP_LIST_ENTRY.finditer(text):
        rel, cell_token = m.group(1), m.group(2)
        tgt = by_resolved.get((root / rel).resolve())
        if tgt is None:
            continue  # dangling link is check A's finding
        file_token, _ = status_token_of(tgt.text)
        if file_token is None:
            continue  # grammar violation is check G's finding
        if cell_token != file_token:
            findings.append(Finding(
                roadmap, line_of(text, m.start()), "H-status-mirror",
                f"{Path(rel).name}: roadmap says `{cell_token}` but the pattern's "
                f"Status line says `{file_token}` (pattern file is the source of truth)",
            ))
    return findings


def check_duplicate_rows(root: Path) -> list[Finding]:
    """I. No roadmap.md *status* table names the same pattern twice.

    High precision: only tables whose header row contains a 'Status' column are
    inspected (the duplicated-Login-row class lives there); the name column is
    the cell to the left of nothing in particular — column 2 by the status
    table's shape. Inventory tables whose second column legitimately repeats
    (Type, tool names) are not status tables and are skipped.
    """
    findings: list[Finding] = []
    roadmap = root / "roadmap.md"
    if not roadmap.exists():
        return findings
    text = roadmap.read_text(encoding="utf-8")
    seen: dict[str, int] = {}
    in_table = False
    is_status_table = False
    for i, raw in enumerate(text.split("\n"), start=1):
        line = raw.strip()
        if line.startswith("|") and line.endswith("|"):
            cells = [c.strip() for c in line.strip("|").split("|")]
            if not in_table:
                in_table = True
                seen = {}
                is_status_table = any(c.lower() == "status" for c in cells)
                continue  # header row
            if not is_status_table or len(cells) < 3:
                continue
            if set(cells[1]) <= {"-", " ", ":"}:
                continue  # separator row
            name = cells[1]
            if name in seen:
                findings.append(Finding(
                    roadmap, i, "I-duplicate-row",
                    f"status table names '{name}' twice (also at line {seen[name]})",
                ))
            else:
                seen[name] = i
        else:
            in_table = False
            is_status_table = False
    return findings


BANNED_TOKEN = re.compile(r"(?i)\bconcern\w*")
ANCESTOR_PROPER_NOUN = "Separation of Concerns"
# Ordinary-English "concern" — a deployment-level matter/responsibility, not the
# banned unit-of-separation working noun. Permitted; stripped before the scan.
ORDINARY_CONCERN = re.compile(r"(?i)\bdeployment\s+concern\w*")
BANNED_TOKEN_EXCLUDED_DIRS = {".git", ".github", "node_modules", "Alloy.app",
                              "demos", "grants", "internal", "working-ideas"}

# Lineage notes are dated historical narration (like roadmap.md, already exempt);
# the vocabulary rules J/K govern the live spec body, not the record of past rounds.
# A pattern's Lineage is its last section, so scanning stops at its heading —
# whether that heading is markdown (`## Lineage…`) or, when the section is folded
# into a <details> for readability, an HTML `<h2>…Lineage…</h2>`. Both forms are
# anchored to the line start, so an in-body prose mention ("see Lineage notes §…")
# never matches and the live body above Lineage is still fully scanned.
LINEAGE_HEADING = re.compile(r"^(?:##\s+|\s*<h2\b[^>]*>\s*)Lineage\b", re.IGNORECASE)


def check_banned_token(root: Path) -> list[Finding]:
    """J: the working noun "concern" is banned corpus-wide (vocabulary directive
    2026-06-11). The unit of separation is the concept; pre-triage items are
    candidate concepts. Exceptions: the exact title-case proper noun
    "Separation of Concerns" — the ancestor principle's name (mention of the
    ancestor, never working use); and ordinary-English "deployment concern(s)"
    (a deployment-level matter/responsibility, not the unit of separation)."""
    out: list[Finding] = []
    md_files: list[Path] = []
    for dirpath, dirnames, filenames in os.walk(root):
        # prune in place so excluded trees (Alloy.app, node_modules, …) are
        # never descended into — rglob-then-filter walks them and is far too slow
        dirnames[:] = [d for d in dirnames if d not in BANNED_TOKEN_EXCLUDED_DIRS]
        md_files += [Path(dirpath) / f for f in filenames if f.endswith(".md")]
    for md in sorted(md_files):
        try:
            text = md.read_text(encoding="utf-8")
        except OSError:
            continue
        for i, line in enumerate(text.splitlines(), start=1):
            if LINEAGE_HEADING.match(line):
                break  # live body only — Lineage is dated history
            scrubbed = CODE_SPAN.sub("", line).replace(ANCESTOR_PROPER_NOUN, "")
            scrubbed = ORDINARY_CONCERN.sub("", scrubbed)
            for m in BANNED_TOKEN.finditer(scrubbed):
                out.append(Finding(
                    md, i, "J-banned-token",
                    f'banned working noun "{m.group(0)}" — the unit of separation '
                    f"is the concept; pre-triage items are candidate concepts "
                    f"(vocabulary directive 2026-06-11)",
                ))
    return out


BANNED_OUTPUT_NOUN = re.compile(r"(?i)\bapplications?\b")
CODE_SPAN = re.compile(r"`[^`]*`")
# The canonical expansion of the API acronym is a fixed term of art — mention,
# not working use — and is scrubbed before matching, like code spans.
API_GLOSS = "Application Programming Interface"
# Standards proper-nouns / org names containing "application" are fixed terms of
# art — mention, not working use — like the API gloss; scrubbed before matching.
STANDARDS_PROPER_NOUNS = re.compile(
    r"(?i)Open Worldwide Application Security Project"
    r"|Application Security Verification Standard"
    r"|System and Application Access Control"
    r"|software applications?")
OUTPUT_NOUN_CORE_DOCS = ("readme.md", "the-spec-layer.md", "pressure-testing.md",
                         "spec-format.md", "contributing.md")


def check_banned_application(root: Path) -> list[Finding]:
    """K: "application" names only a deployed build output. The canonical layer
    has exactly two artifact kinds — atomic concepts and compositions thereof —
    so the word is banned there (vocabulary direction 2026-06-11). Excluded by
    design: execution-contract.md (output level is its domain), roadmap.md
    (dated history), glossary.md (the definition site). Code spans scrubbed:
    a backticked external path like `applications/` is mention, not use."""
    scoped: list[Path] = []
    for d in PATTERN_DIRS:
        base = root / d
        if base.is_dir():
            scoped += sorted(base.glob("*.md"))
    scoped += [root / n for n in OUTPUT_NOUN_CORE_DOCS if (root / n).exists()]
    guide = root / "tools" / "guide"
    if guide.is_dir():
        scoped += sorted(guide.rglob("*.md"))
    out: list[Finding] = []
    for md in scoped:
        try:
            text = md.read_text(encoding="utf-8")
        except OSError:
            continue
        for i, line in enumerate(text.splitlines(), start=1):
            if LINEAGE_HEADING.match(line):
                break  # live body only — Lineage is dated history
            scrubbed = STANDARDS_PROPER_NOUNS.sub(
                "", CODE_SPAN.sub("", line).replace(API_GLOSS, ""))
            for m in BANNED_OUTPUT_NOUN.finditer(scrubbed):
                out.append(Finding(
                    md, i, "K-output-noun",
                    f'"{m.group(0)}" is output-level vocabulary — the canonical '
                    f"layer has two artifact kinds: atomic concepts and "
                    f"compositions thereof (deployed build outputs belong to "
                    f"execution-contract.md)",
                ))
    return out


# --------------------------------------------------------------------------- #
# Internal-identifier guards (L, M) — lock in the C-number / coinage cleanup
# --------------------------------------------------------------------------- #

# Bare composition C-number, C1–C19 (the registry sigil retired from spec bodies,
# debt #14). The token must stand alone: "C12345" and the "C9" inside "IC9" do not
# match. Example *credential* IDs ("credential C2") are scrubbed before matching.
BARE_CNUMBER = re.compile(r"\bC(?:1[0-9]|[1-9])\b")
CREDENTIAL_ID = re.compile(r"(?i)\bcredential\s+C\d+\b")

# The methodology's own coined finding-ID sigils (debt #15) — no legitimate
# collision in a spec body, so a high-precision regression guard. Bare `S-n` is
# deliberately omitted (collides with the SEC "S-1" form); the others are unique.
INTERNAL_SIGILS = [
    (re.compile(r"\bMC-C\d+-\d+\b"), "MC-Cn-N coverage-finding ID"),
    (re.compile(r"\bFC-F\d+\b"),     "FC-Fn (Final Critique finding) ID"),
    (re.compile(r"\bFC-?\d+\b"),     "FCn (Final Critique n) sigil"),
    (re.compile(r"\bR\d+-F\d+\b"),   "Rn-Fn (round / finding) ID"),
    (re.compile(r"\bC\d+-\d+\b"),    "Cn-N finding ID"),
    (re.compile(r"\bOG-\d+\b"),      "OG-n finding ID"),
]


def check_internal_ids(patterns: dict[Path, Pattern]) -> list[Finding]:
    """L + M. No bare composition C-number and no coined finding-ID sigil survives
    in an atom/composition live body — locking in debts #14 and #15 so the cleared
    cruft cannot quietly regrow during a prose pass. Code spans are scrubbed (a
    backticked token is mention, not use); Lineage is skipped (dated history, same
    convention as checks J/K); example `credential Cn` IDs are scrubbed before the
    bare-C-number match. Scoped to atoms/ + compositions/: root policy docs cite
    `Cn` and acronyms as deliberate teaching examples."""
    findings: list[Finding] = []
    for p in patterns.values():
        for i, raw in enumerate(p.text.splitlines(), start=1):
            if LINEAGE_HEADING.match(raw):
                break  # live body only — Lineage is dated history
            scrubbed = CODE_SPAN.sub("", raw)
            # M — coined sigils
            cn_line = scrubbed
            for rx, label in INTERNAL_SIGILS:
                for m in rx.finditer(scrubbed):
                    findings.append(Finding(
                        p.path, i, "M-internal-sigil",
                        f'coined finding-ID "{m.group(0)}" ({label}) — spell the '
                        f"concept out or describe it (naming.md Rule zero)",
                    ))
                cn_line = rx.sub("", cn_line)  # don't double-report its C-prefix
            # L — bare composition C-number (example credential IDs scrubbed)
            cn_line = CREDENTIAL_ID.sub("", cn_line)
            for m in BARE_CNUMBER.finditer(cn_line):
                findings.append(Finding(
                    p.path, i, "L-bare-cnumber",
                    f'bare composition C-number "{m.group(0)}" — use the '
                    f"composition's name (the C-number is a registry key, not prose)",
                ))
    return findings


# --------------------------------------------------------------------------- #
# Common-acronym whitelist (N) — the redundant-gloss guard
# --------------------------------------------------------------------------- #

# spec-format's acronym rule (§Cross-cutting authoring conventions) exempts a
# short, dictionary-headword whitelist (SMS, GPS, URL, HTML, US/USA, ID, PDF,
# FAQ) from the spell-out requirement. *Glossing* a whitelisted acronym anyway —
# "SMS (Short Message Service …)" — is the redundant noise the whitelist exists
# to remove, so it is a finding. High precision: each pattern is a whitelisted
# acronym immediately followed by a parenthetical carrying its canonical
# expansion, so an ordinary aside ("US (and the EU)") never matches. US/USA and
# ID are whitelisted but deliberately NOT auto-detected — their expansions are
# common-enough words to risk a false positive, and the linter's bar is
# precision over recall. Code spans scrubbed; Lineage skipped (dated history),
# same convention as J/K/L/M.
WHITELIST_GLOSS = [
    (re.compile(r"\bSMS\b\s*\([^)]*Short Message Service", re.I), "SMS"),
    (re.compile(r"\bGPS\b\s*\([^)]*Global Positioning System", re.I), "GPS"),
    (re.compile(r"\bURL\b\s*\([^)]*Uniform Resource Locator", re.I), "URL"),
    (re.compile(r"\bHTML\b\s*\([^)]*HyperText Markup Language", re.I), "HTML"),
    (re.compile(r"\bPDF\b\s*\([^)]*Portable Document Format", re.I), "PDF"),
    (re.compile(r"\bFAQ\b\s*\([^)]*Frequently Asked Questions?", re.I), "FAQ"),
]


def check_whitelist_gloss(patterns: dict[Path, Pattern]) -> list[Finding]:
    """N. A whitelisted common acronym carries a redundant spelled-out gloss.

    spec-format whitelists a few dictionary-headword acronyms from the spell-out
    rule; glossing one anyway is noise the whitelist exists to remove. Scoped to
    atoms/ + compositions/; code spans scrubbed; Lineage skipped (dated history).
    """
    findings: list[Finding] = []
    for p in patterns.values():
        for i, raw in enumerate(p.text.splitlines(), start=1):
            if LINEAGE_HEADING.match(raw):
                break  # live body only — Lineage is dated history
            scrubbed = CODE_SPAN.sub("", raw)
            for rx, acr in WHITELIST_GLOSS:
                if rx.search(scrubbed):
                    findings.append(Finding(
                        p.path, i, "N-whitelist-gloss",
                        f"{acr} is a whitelisted common acronym (spec-format "
                        f"§Cross-cutting authoring conventions) — drop the "
                        f"spelled-out gloss; the acronym stands alone",
                    ))
    return findings


# --------------------------------------------------------------------------- #
# Term registry resolver (O) — the annotation.md [Term] safety net
# --------------------------------------------------------------------------- #
#
# OPT-IN BY DESIGN. The check fires only on a page that carries a `## Terms`
# section (the annotation.md registry). The ~49 not-yet-converted patterns have no
# such section, so they are skipped entirely and stay at 0 findings — recall grows
# as pages convert, never by loosening. For a converted page it resolves every
# `[Term]` shortcut-reference marker in the live body against the page's own
# shortcut-reference definition set, flagging two drift classes:
#   O-term-dangling  — a `[Term]` marker with no matching `[Term]: …` definition
#                      (the reader's click 404s; the adapter can't project it).
#   O-term-orphan    — a `[Term]: …` definition no marker uses (dead registry entry).
#
# A `[Term]` MARKER is a kramdown SHORTCUT reference: `[Text]` NOT immediately
# followed by `(` (inline link) or `[` (full/collapsed reference). Code spans and
# HTML comments are scrubbed first, so the meta-prose `` `[Term]` `` and the
# commented definition block never count as markers. Definitions are the
# `[Text]: target` lines (the registry itself). Comparison is on the bracket text
# verbatim — anchors/casing are the adapter's job, not this check's.
TERMS_SECTION = re.compile(r"^##\s+Terms\b", re.M)
HTML_COMMENT = re.compile(r"<!--.*?-->", re.S)
# a shortcut-reference definition line: `[Text]: destination`
TERM_DEF = re.compile(r"^\[([^\]]+)\]:\s*\S", re.M)
# a shortcut-reference USE: `[Text]` that is NOT
#   - preceded by `]`   (the label half of a full/collapsed reference `[text][label]`)
#   - a footnote        (`[^id]`)
#   - followed by `(`   (inline link `[text](url)`)
#   - followed by `[`   (full/collapsed reference `[text][label]` / `[text][]`)
#   - followed by `:`   (it is itself a `[text]: …` definition line, handled above)
TERM_USE = re.compile(r"(?<!\])\[(?!\^)([^\]\[]+)\](?![\(\[:])")


def check_term_registry(patterns: dict[Path, Pattern]) -> list[Finding]:
    """O. On any page carrying a `## Terms` registry, every `[Term]` marker resolves
    to a registry definition, and every definition is used. Opt-in: pages without a
    Terms section are skipped, so unconverted patterns stay clean."""
    findings: list[Finding] = []
    for p in patterns.values():
        if not TERMS_SECTION.search(p.text):
            continue  # opt-in: only converted pages carry a Terms registry
        # definitions: the registry's `[Term]: …` lines (anywhere on the page)
        defs = {m.group(1) for m in TERM_DEF.finditer(p.text)}
        # markers: scrub HTML comments (possibly multi-line) and code spans, then
        # collect shortcut refs. Comments are blanked line-count-preserving so the
        # registry's own commented "[Term] marker" prose never counts and line
        # numbers stay accurate.
        no_comments = HTML_COMMENT.sub(
            lambda m: "\n" * m.group(0).count("\n"), p.text)
        used: dict[str, int] = {}
        for i, raw in enumerate(no_comments.splitlines(), start=1):
            line = CODE_SPAN.sub("", raw)
            if TERM_DEF.match(line.strip()):
                continue  # the definition line is not itself a marker use
            for m in TERM_USE.finditer(line):
                used.setdefault(m.group(1), i)
        # O-term-dangling — a marker with no definition
        for name, line in sorted(used.items(), key=lambda kv: kv[1]):
            if name not in defs:
                findings.append(Finding(
                    p.path, line, "O-term-dangling",
                    f"[{name}] marker has no registry definition "
                    f"([{name}]: …) in this page's Terms section",
                ))
        # O-term-orphan — a definition no marker uses
        def_lines = {m.group(1): line_of(p.text, m.start()) for m in TERM_DEF.finditer(p.text)}
        for name in sorted(defs):
            if name not in used:
                findings.append(Finding(
                    p.path, def_lines.get(name, 1), "O-term-orphan",
                    f"registry defines [{name}] but no [{name}] marker uses it "
                    f"(orphan definition)",
                ))
    return findings


# --------------------------------------------------------------------------- #
# Ledger grammar and census (R)
# --------------------------------------------------------------------------- #
#
# The Ledger is the countable single source of truth for a pattern's health
# (open-questions.md §Replace the prose Lineage; pressure-testing.md §Where the
# journey gets recorded). Its grammar is fixed so this file can parse it:
#
#   ## Ledger
#
#   ```
#   status: <token — identical to the Status line's token>
#   formal: <verified — model.tla + N twin(s), YYYY-MM-DD | pending — <why> |
#            not applicable — <why>>
#   last gate: <YYYY-MM-DD — <kind> — <result>> | none
#
#   open:
#   - <YYYY-MM-DD-x> · <foundational|refining|rhetorical> · <where> · <defect> → <fix>
#   ```
#
# `open: none` when nothing is open. When a finding closes its line is deleted;
# the fact that it existed is in git. Derived rules the check refuses by
# construction: a grounded token with an open foundational line; a Ledger
# status that disagrees with the Status line; an open line with the wrong
# field count, an unknown class, a malformed or duplicate id.

LEDGER_SECTION = re.compile(r"^## Ledger\s*$", re.M)
DECISIONS_SECTION = re.compile(r"^## Decisions\s*$", re.M)
FENCE = re.compile(r"^```[^\n]*\n(.*?)^```", re.M | re.S)
LEDGER_ID = re.compile(r"^\d{4}-\d{2}-\d{2}-[a-z]+$")
LEDGER_CLASSES = ("foundational", "refining", "rhetorical")
LEDGER_FORMAL = re.compile(
    r"^(?:verified — .+\d{4}-\d{2}-\d{2}"
    r"|pending — .+"
    r"|not applicable — .+)$"
)
LEDGER_GATE = re.compile(r"^(?:none|\d{4}-\d{2}-\d{2} — [^—]+ — .+)$")
DECISION_ENTRY = re.compile(
    r"^- \*\*\d{4}-\d{2}-\d{2} — [^*]+\*\* \*Chose:\* .+ \*Over:\* .+ \*Because:\* .+$"
)


@dataclass
class LedgerLine:
    id: str
    cls: str
    where: str
    defect: str
    fix: str
    line: int


@dataclass
class Ledger:
    status: str | None = None
    formal: str | None = None
    gate: str | None = None
    open: list[LedgerLine] = field(default_factory=list)
    problems: list[tuple[int, str]] = field(default_factory=list)
    line: int = 0

    def count(self, cls: str) -> int:
        return sum(1 for o in self.open if o.cls == cls)


def parse_ledger(text: str) -> Ledger | None:
    """Parse the fenced block under `## Ledger`; None when the section is absent.
    Grammar problems are collected on the Ledger rather than raised, so one pass
    reports all of them."""
    m = LEDGER_SECTION.search(text)
    if not m:
        return None
    led = Ledger(line=line_of(text, m.start()))
    fence = FENCE.search(text, m.end())
    # the fence must be the first non-blank content after the heading
    between = text[m.end():fence.start()] if fence else text[m.end():m.end() + 200]
    if not fence or between.strip():
        led.problems.append((led.line, "no fenced block immediately after `## Ledger`"))
        return led
    base = line_of(text, fence.start()) + 1
    seen_keys: set[str] = set()
    in_open = False
    ids: set[str] = set()
    for i, raw in enumerate(fence.group(1).split("\n")):
        ln = base + i
        line = raw.rstrip()
        if not line.strip():
            continue
        if in_open:
            if not line.startswith("- "):
                led.problems.append((ln, "line inside `open:` does not start with `- `"))
                continue
            parts = [s.strip() for s in line[2:].split(" · ")]
            if len(parts) != 4 or " → " not in parts[3]:
                led.problems.append((
                    ln, "open line needs five fields: `id · class · where · defect → fix`"))
                continue
            defect, fix = (s.strip() for s in parts[3].split(" → ", 1))
            oid, cls, where = parts[0], parts[1], parts[2]
            if not LEDGER_ID.match(oid):
                led.problems.append((ln, f"id `{oid}` is not `YYYY-MM-DD-x`"))
            if oid in ids:
                led.problems.append((ln, f"duplicate id `{oid}`"))
            ids.add(oid)
            if cls not in LEDGER_CLASSES:
                led.problems.append((ln, f"class `{cls}` is not one of {', '.join(LEDGER_CLASSES)}"))
            if not (where and defect and fix):
                led.problems.append((ln, "empty field in open line"))
            led.open.append(LedgerLine(oid, cls, where, defect, fix, ln))
            continue
        if ":" not in line:
            led.problems.append((ln, f"unrecognized line `{line[:40]}`"))
            continue
        key, _, val = line.partition(":")
        key, val = key.strip(), val.strip()
        if key in seen_keys:
            led.problems.append((ln, f"duplicate key `{key}`"))
        seen_keys.add(key)
        if key == "status":
            led.status = val
            if not any(rx.match(val) for rx in STATUS_TOKEN_FORMS):
                led.problems.append((ln, f"status `{val}` matches no form of the pinned grammar"))
        elif key == "formal":
            led.formal = val
            if not LEDGER_FORMAL.match(val):
                led.problems.append((ln, "formal line is not `verified — … YYYY-MM-DD` / "
                                         "`pending — …` / `not applicable — …`"))
        elif key == "last gate":
            led.gate = val
            if not LEDGER_GATE.match(val):
                led.problems.append((ln, "last gate is not `YYYY-MM-DD — kind — result` or `none`"))
        elif key == "open":
            if val == "none":
                in_open = False
                seen_keys.add("open-none")
            elif val == "":
                in_open = True
            else:
                led.problems.append((ln, "`open:` takes nothing (lines follow) or `none`"))
        else:
            led.problems.append((ln, f"unknown key `{key}`"))
    for key in ("status", "formal", "last gate"):
        if key not in seen_keys:
            led.problems.append((led.line, f"missing `{key}:` line"))
    if "open" not in seen_keys:
        led.problems.append((led.line, "missing `open:` line"))
    elif "open-none" in seen_keys and led.open:
        led.problems.append((led.line, "`open: none` but open lines follow"))
    elif "open-none" not in seen_keys and not led.open:
        led.problems.append((led.line, "`open:` with no lines — write `open: none`"))
    return led


def check_ledger(patterns: dict[Path, Pattern]) -> list[Finding]:
    """R. Ledger grammar, and the contradictions it refuses by construction.
    Every pattern carries a Ledger since the 2026-08-27 migration; a missing
    one is a finding."""
    findings: list[Finding] = []
    for p in patterns.values():
        led = parse_ledger(p.text)
        if led is None:
            findings.append(Finding(
                p.path, 1, "R-ledger-missing",
                "no `## Ledger` section (spec-format.md §Status / Ledger / Decisions; "
                "pressure-testing.md §Where the journey gets recorded)",
            ))
            continue
        for ln, msg in led.problems:
            findings.append(Finding(p.path, ln, "R-ledger-grammar", msg))
        token, _ = status_token_of(p.text)
        if led.status and token and led.status != token:
            findings.append(Finding(
                p.path, led.line, "R-ledger-status",
                f"Ledger says `{led.status}` but the Status line says `{token}`",
            ))
        if led.status and led.status.startswith("grounded") and led.count("foundational"):
            findings.append(Finding(
                p.path, led.line, "R-ledger-grounded-open",
                f"status is grounded with {led.count('foundational')} open foundational "
                f"line(s); grounding requires zero (pressure-testing.md §The 92%-good "
                f"grounding threshold)",
            ))
        if led.status == "partially resolved" and not led.open and led.gate == "none":
            findings.append(Finding(
                p.path, led.line, "R-ledger-status",
                "partially resolved with nothing open and no gate on record — "
                "either an open line is missing or the status is `draft`",
            ))
        # Decisions: required alongside a Ledger; entries, if any, in the fixed form
        d = DECISIONS_SECTION.search(p.text)
        if not d:
            findings.append(Finding(
                p.path, led.line, "R-decisions-missing",
                "a pattern with a Ledger carries a `## Decisions` section "
                "(directional changes only; may have no entries)",
            ))
            continue
        nxt = re.compile(r"^(?:## |---\s*$)", re.M).search(p.text, d.end())
        body = p.text[d.end():nxt.start() if nxt else len(p.text)]
        for i, raw in enumerate(body.split("\n")):
            if raw.startswith("- ") and not DECISION_ENTRY.match(raw):
                findings.append(Finding(
                    p.path, line_of(p.text, d.end()) + i, "R-decisions-grammar",
                    "decision entry is not `- **YYYY-MM-DD — title.** *Chose:* … "
                    "*Over:* … *Because:* …`",
                ))
    return findings


def census(root: Path, patterns: dict[Path, Pattern]) -> int:
    """`--census`: the corpus health tally, derived from Ledgers. Patterns
    without a Ledger are listed as unmigrated so the number is honest about
    its own coverage."""
    rows = []
    unmigrated = []
    for p in sorted(patterns.values(), key=lambda q: q.path.as_posix()):
        led = parse_ledger(p.text)
        rel = p.path.relative_to(root).as_posix()
        if led is None:
            unmigrated.append(rel)
            continue
        rows.append((rel, led.status or "?", led.count("foundational"),
                     led.count("refining"), led.count("rhetorical"), led.gate or "?"))
    w = max((len(r[0]) for r in rows), default=20)
    print(f"{'pattern':<{w}}  {'status':<42}  fnd  ref  rhe  last gate")
    for rel, st, f, r, h, g in rows:
        print(f"{rel:<{w}}  {st[:42]:<42}  {f:>3}  {r:>3}  {h:>3}  {g}")
    tf = sum(r[2] for r in rows); tr = sum(r[3] for r in rows); th = sum(r[4] for r in rows)
    by_status: dict[str, int] = {}
    for r in rows:
        key = r[1].split(" on ")[0].split(" (")[0]
        by_status[key] = by_status.get(key, 0) + 1
    print()
    print(f"— {len(rows)} pattern(s) with a Ledger: "
          + ", ".join(f"{n} {k}" for k, n in sorted(by_status.items())))
    print(f"— open: {tf} foundational, {tr} refining, {th} rhetorical "
          f"across {sum(1 for r in rows if r[2] + r[3] + r[4])} pattern(s); "
          f"{sum(1 for r in rows if r[2])} pattern(s) carry open foundational")
    if unmigrated:
        print(f"— {len(unmigrated)} pattern(s) without a Ledger (not counted): "
              + ", ".join(unmigrated))
    return 0


# --------------------------------------------------------------------------- #
# H. The heading standard — spec-format.md §Heading standard
# --------------------------------------------------------------------------- #

_HEADING_TABLES = {"atom": "### Atom headings", "composition": "### Composition headings"}


def heading_standard(spec_format_text: str) -> dict[str, list[dict]]:
    """The two heading tables, read from spec-format.md rather than held here.

    Each row: name, level, inside, required (`yes` | `no` | `when grounded`),
    unplaced (`yes` | `no` | `any order`). The linter holds no copy, so a
    heading renamed in spec-format is renamed for the instrument in the same
    edit (the lesson check.py learned from its category set, council read 29)."""
    out: dict[str, list[dict]] = {}
    for shape, title in _HEADING_TABLES.items():
        start = spec_format_text.find(title + "\n")
        if start < 0:
            raise SystemExit(f"lint.py: spec-format.md carries no `{title}` table; "
                             "the heading standard has no authority to read (H-heading)")
        rows = []
        for line in spec_format_text[start:].split("\n")[1:]:
            if line.startswith("#"):
                break
            cells = [c.strip() for c in line.strip().strip("|").split("|")]
            if len(cells) != 5 or cells[0] in ("Heading", "") or set(cells[0]) <= set("-"):
                continue
            rows.append({"name": cells[0], "level": int(cells[1]), "inside": cells[2],
                         "required": cells[3], "unplaced": cells[4]})
        out[shape] = rows
    return out


def retired_heading_names(spec_format_text: str) -> dict[str, str]:
    """spec-format.md §Retired heading names: retired name -> the row it became."""
    start = spec_format_text.find("### Retired heading names\n")
    if start < 0:
        raise SystemExit("lint.py: spec-format.md carries no `### Retired heading names` "
                         "table (H-heading)")
    out: dict[str, str] = {}
    for line in spec_format_text[start:].split("\n")[1:]:
        if line.startswith("#") or line.strip() == "---":
            break
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        if len(cells) == 2 and cells[0] not in ("Retired name", "") and set(cells[0]) - set("-"):
            out[cells[0]] = cells[1]
    return out


def _singular(name: str) -> str:
    words = name.split()
    if words and len(words[-1]) > 3 and words[-1].endswith("s") and not words[-1].endswith("ss"):
        words[-1] = words[-1][:-1]
    return " ".join(words).casefold()


def _collation_key(name: str) -> str:
    """Case-insensitive, punctuation ignored, a space before any letter."""
    return "".join(ch for ch in name.casefold() if ch.isalnum() or ch == " ")


def _heading_tree(text: str) -> list[tuple[int, str, int]]:
    """(level, name, line) for every `##` and `###` outside a fence."""
    out, fence = [], False
    for i, line in enumerate(text.split("\n"), start=1):
        if line.lstrip().startswith("```"):
            fence = not fence
            continue
        if fence:
            continue
        m = re.match(r"^(#{2,3}) (.+?)\s*$", line)
        if m:
            out.append((len(m.group(1)), m.group(2), i))
    return out


def check_heading_standard(root: Path, patterns: dict[Path, Pattern]) -> list[Finding]:
    """H. A migrated spec's `##` and `###` headings against spec-format.md
    §Heading standard: every heading a known row or an unplaced child where the
    parent admits one, at the row's level and under the row's parent, in table
    order with unplaced children after the placed ones in collation order, and
    every required row present.

    The instrument open-questions.md carried as *a spec's section list is
    declared and unread*: spec-format fixed the order, `Standard label 9` sent
    promoted families to it, and nothing read either — which is how Idempotent
    Reservation's `Housekeeping` sat second for a day and how `Clock semantics`
    came to live at two depths (council read 80)."""
    sf_text = (root / "spec-format.md").read_text(encoding="utf-8")
    tables = heading_standard(sf_text)
    retired = retired_heading_names(sf_text)
    findings: list[Finding] = []
    for p in patterns.values():
        if not re.search(r"^Term qualifiers:.*\bmigrated\b", p.text, re.M):
            continue
        shape = "composition" if "/compositions/" in p.path.as_posix() else "atom"
        rows = tables[shape]
        top = [r for r in rows if r["level"] == 2]
        top_index = {r["name"]: k for k, r in enumerate(top)}
        kids = {r["name"]: [c for c in rows if c["level"] == 3 and c["inside"] == r["name"]] for r in top}
        by_name = {r["name"]: r for r in rows}

        def add(line: int, msg: str) -> None:
            findings.append(Finding(p.path, line, "H-heading", msg))

        parent = None
        last_top = -1
        last_child: tuple[int, str] = (-1, "")
        present: set[tuple[str, str]] = set()
        row_by_singular = {_singular(r["name"]): r["name"] for r in rows}
        for level, name, line in _heading_tree(p.text):
            bare = name.split(" — ")[0].strip()
            synonym = retired.get(bare)
            if synonym is None and bare not in by_name:
                synonym = row_by_singular.get(_singular(bare))
            if synonym is not None:
                add(line, f"`{'#' * level} {name}` is a second name for `{synonym}`; the "
                          f"heading takes the row's name (spec-format.md §Retired heading names)")
            if level == 2:
                row = by_name.get(name)
                if row is None or row["level"] != 2:
                    where = f" (the standard places it at `###` under {row['inside']})" if row else ""
                    add(line, f"`## {name}` is not a section of the {shape} shape{where}")
                    parent = None
                    continue
                k = top_index[name]
                if k < last_top:
                    add(line, f"`## {name}` comes after `## {top[last_top]['name']}`; the "
                              f"{shape} order puts it before (spec-format.md §Heading standard)")
                last_top = max(last_top, k)
                parent = row
                last_child = (-1, "")
                present.add(("", name))
                continue
            # level 3
            if parent is None:
                continue
            placed = kids[parent["name"]]
            names = [c["name"] for c in placed]
            if name in names:
                pos = names.index(name)
                if last_child[0] >= len(names):
                    add(line, f"`### {name}` follows the unplaced `### {last_child[1]}`; "
                              f"placed headings come first under `## {parent['name']}`")
                elif pos < last_child[0]:
                    add(line, f"`### {name}` comes after `### {last_child[1]}`; the order "
                              f"under `## {parent['name']}` puts it before")
                last_child = (max(last_child[0], pos), name) if last_child[0] < len(names) else last_child
                present.add((parent["name"], name))
                continue
            row = by_name.get(name)
            if row is not None:
                add(line, f"`### {name}` belongs "
                          + (f"under `## {row['inside']}`" if row["inside"] else "at `##`")
                          + f", not under `## {parent['name']}`")
                continue
            if parent["unplaced"] == "no":
                add(line, f"`## {parent['name']}` takes no heading the standard does not name, "
                          f"and `### {name}` is not one of its rows")
                continue
            if parent["unplaced"] == "yes":
                if last_child[0] >= len(names) and _collation_key(name) < _collation_key(last_child[1]):
                    add(line, f"`### {name}` comes after `### {last_child[1]}`; unplaced headings "
                              f"under `## {parent['name']}` run in alphabetical order")
                last_child = (len(names), name)
        for r in rows:
            if r["required"] == "no" or (r["required"] == "when grounded" and not p.grounded):
                continue
            if r["level"] == 3 and ("", r["inside"]) not in present:
                continue  # the parent's own absence is the finding
            if (r["inside"], r["name"]) not in present:
                where = f"under `## {r['inside']}`" if r["inside"] else "at `##`"
                add(1, f"carries no `{'#' * r['level']} {r['name']}` {where}, which the {shape} "
                       f"shape requires (spec-format.md §Heading standard)")
    return findings


def check_section_classification(root: Path) -> list[Finding]:
    """H. The section-name check execution-contract.md §Section-name
    classification specified in June and nothing ran: every heading the
    standard names is classified by the Contract, and every name the Contract
    classifies is still a heading spec-format.md names. Both directions read by
    case-insensitive containment, which is what a classification written as
    prose admits."""
    sf_path, ec_path = root / "spec-format.md", root / "execution-contract.md"
    sf, ec = sf_path.read_text(encoding="utf-8"), ec_path.read_text(encoding="utf-8")
    m = re.search(r"\*\*Every section name spec-format requires is classified exactly once\*\*(.*?)"
                  r"\*\*The section-name lint check", ec, re.S)
    if not m:
        return [Finding(ec_path, 1, "H-classification",
                        "no section-name classification block to read")]
    block = m.group(1)
    findings: list[Finding] = []
    names = {r["name"] for rows in heading_standard(sf).values() for r in rows}
    for n in sorted(names):
        if n.lower() not in block.lower():
            findings.append(Finding(ec_path, line_of(ec, m.start()), "H-classification",
                                    f"`{n}` is a heading spec-format.md §Heading standard names "
                                    f"and the Contract does not classify"))
    for bullet in re.findall(r"^- \*\*[^*]+:\*\* (.*)$", block, re.M):
        depth, parts, cur = 0, [], ""
        for ch in bullet:
            depth += (ch == "(") - (ch == ")")
            if ch == ";" and depth == 0:
                parts.append(cur)
                cur = ""
            else:
                cur += ch
        parts.append(cur)
        for part in parts:
            name = re.split(r" \(|\. ", part.strip())[0].strip().rstrip(".")
            if name and name.lower() not in sf.lower():
                findings.append(Finding(ec_path, line_of(ec, m.start()), "H-classification",
                                        f"the Contract classifies `{name}`, which spec-format.md "
                                        f"no longer names"))
    return findings


# --------------------------------------------------------------------------- #
# F-range-form — a run of labels is written `Family N through M`
# --------------------------------------------------------------------------- #
# GRACE-lang Hard invariant 29 through 31 (v0.47). The corpus wrote one range
# four ways — `Operation 3–7`, `Operation 3 through Operation 7`,
# `Operations 3–7`, `Operation 3 to 7` — and no reader resolved any of them
# past the first label. The families are read from the labelled rules of the
# grammar and every spec, inside bare fences, so an external standard's
# `Articles 5–6` is not a label and is not flagged. A repeated family after
# `to` is left alone: *renumbered Operation 3 to Operation 7* is a move, not a
# range. Code spans are scrubbed, so the grammar can quote a retired form.
RANGE_EXCLUDED_DIRS = {".git", ".github", "node_modules", "Alloy.app", "_site",
                       "vendor", "__pycache__"}
_RANGE_FENCE = re.compile(r"^\s*```(\w*)")
_RANGE_LABEL = re.compile(
    r"^\s*(?:Deleted:\s*)?([A-Za-z_][\w'’-]*(?: [A-Za-z_][\w'’-]*){0,4}) "
    r"(?:step )?[\d½]+(?:\.\d+)?[a-z]?:")
_RANGE_NOT_FAMILY = {"NOTE", "WHY", "UX", "PROVISIONAL"}


def label_families(root: Path) -> set[str]:
    fams: set[str] = set()
    sources = [root / "GRACE-lang.md"]
    for d in ("atoms", "compositions"):
        sources += sorted((root / d).glob("*.md"))
    for src in sources:
        if not src.exists():
            continue
        in_text = False
        for line in src.read_text(encoding="utf-8").splitlines():
            fm = _RANGE_FENCE.match(line)
            if fm:
                in_text = not in_text and fm.group(1) == ""
                continue
            m = _RANGE_LABEL.match(line) if in_text else None
            if m and m.group(1) not in _RANGE_NOT_FAMILY:
                fams.add(m.group(1))
    return fams


def _range_key(num: str) -> tuple[int, ...]:
    return tuple(int(x) for x in re.findall(r"\d+", num))


def check_range_form(root: Path) -> list[Finding]:
    """F. Every range of labels, in every Markdown file, in the one form."""
    fams = label_families(root)
    if not fams:
        return []
    alt = "|".join(re.escape(f) for f in sorted(fams, key=len, reverse=True))
    first = r"((?:step )?[\d½]+(?:\.\d+)?[a-z]?)"
    last = r"([\d½]+(?:\.\d+)?[a-z]?)(?![\w.]\d)"
    lead = r"(?<![\w-])(" + alt + r")"
    retired = [
        (re.compile(lead + r"s? " + first + r"\s*[–—]\s*(?:(?:" + alt + r")s? )?(?:step )?" + last),
         "a dash between two numbers"),
        (re.compile(lead + r" " + first + r" through \1 (?:step )?" + last),
         "the family written twice"),
        (re.compile(lead + r"s " + first + r" (?:through|to) " + last),
         "the family written plural"),
        (re.compile(lead + r" " + first + r" to " + last),
         "*to*, which does not say whether the last is in"),
    ]
    # the family written in any case, singular or plural, with the numbers in
    # parentheses: `all Audit Trail invariants (1–8)` (council read 95)
    retired.append((re.compile(r"(?i)(?<![\w-])(" + alt + r")s? \((\d+(?:\.\d+)?)\s*[–—-]\s*(\d+(?:\.\d+)?)\)"),
                    "the numbers in parentheses"))
    written = re.compile(lead + r" " + first + r" through " + last)
    md_files: list[Path] = []
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = [d for d in dirnames if d not in RANGE_EXCLUDED_DIRS]
        md_files += [Path(dirpath) / f for f in filenames if f.endswith(".md")]
    out: list[Finding] = []
    for md in sorted(md_files):
        try:
            text = md.read_text(encoding="utf-8")
        except OSError:
            continue
        for i, raw in enumerate(text.splitlines(), start=1):
            line = CODE_SPAN.sub("", raw)
            for rx, why in retired:
                for m in rx.finditer(line):
                    out.append(Finding(md, i, "F-range-form",
                        f"'{m.group(0)}' — {why}; write `{m.group(1)} "
                        f"{m.group(2)} through {m.groups()[-1]}` (GRACE-lang Hard invariant 31)"))
            for m in written.finditer(line):
                lo, hi = _range_key(m.group(2)), _range_key(m.group(3))
                if len(lo) != len(hi):
                    out.append(Finding(md, i, "F-range-form",
                        f"'{m.group(0)}' — the last number does not carry the first "
                        f"number's shape (GRACE-lang Term range citation)"))
                elif hi <= lo:
                    out.append(Finding(md, i, "F-range-form",
                        f"'{m.group(0)}' — the last number does not follow the first "
                        f"(GRACE-lang Hard invariant 30)"))
    return out


# --------------------------------------------------------------------------- #
# F-stripped-link / F-composes-list — the links the generated views read
# --------------------------------------------------------------------------- #
# A link whose brackets were stripped and whose text was lower-cased —
# `permissions(../atoms/permissions.md)` — renders as its own source. Seven
# migrated compositions carried 144 of them (council read 93), written by the
# migration's casing pass. And a composition's constituents are the linked
# bullets under its `## Composes` heading (spec-format.md §Composes), which is
# what tools/taxonomy reads for the catalogue, the graph and the pattern data:
# seven migrated compositions had dropped the list, and the generated views went
# three commits stale before anyone regenerated them.
STRIPPED_LINK = re.compile(
    r"(?<![\[\]\w`/])[A-Za-z][A-Za-z' -]*\((?:\.\./)*(?:atoms/|compositions/|\./)"
    r"[a-z0-9-]+\.md(?:#[^)]*)?\)")
COMPOSES_BULLET = re.compile(
    r"^\s*-\s+\*{0,2}\[[^\]]+\]\((?:\.\./atoms/(?:[a-z-]+/)?|\./)([a-z0-9-]+)\.md\)", re.M)
CONSTITUENT_LINK = re.compile(r"\[[^\]]+\]\((?:\.\./atoms/(?:[a-z-]+/)?|\./)([a-z0-9-]+)\.md\)")
TERM_CONSTITUENTS = re.compile(r"^Term constituents: (.*)$", re.M)
SERVE_RULE = re.compile(r"^\s*Composes \d+[a-z]?: EXACTLY ONE (.+?) (?:instance|shape) MUST serve", re.M)


def check_stripped_links(root: Path) -> list[Finding]:
    out: list[Finding] = []
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = [d for d in dirnames if d not in RANGE_EXCLUDED_DIRS]
        for fn in filenames:
            if not fn.endswith(".md"):
                continue
            md = Path(dirpath) / fn
            try:
                lines = md.read_text(encoding="utf-8").splitlines()
            except OSError:
                continue
            in_fence = False
            for i, raw in enumerate(lines, start=1):
                if raw.lstrip().startswith("```"):
                    in_fence = not in_fence
                    continue
                if in_fence:
                    continue
                for m in STRIPPED_LINK.finditer(CODE_SPAN.sub("", raw)):
                    out.append(Finding(md, i, "F-stripped-link",
                        f"'{m.group(0)}' is a link with its brackets stripped; write "
                        f"`[Title](path)`"))
    return out


SECTION_CITE = re.compile(r"\b[Tt]he (?:section|row) titled ")
SECTION_FILE = re.compile(r" in \[?`([\w./-]+\.md)`")


def _titles(path: Path) -> set[str]:
    """Every title a citation may name: a heading, a heading's part before its
    subtitle, a bold-bullet heading, a table row's bold first cell, a labelled
    rule of `execution-contract.md`."""
    try:
        text = path.read_text(encoding="utf-8")
    except OSError:
        return set()
    out: set[str] = set()
    for m in re.finditer(r"^#+\s+(.*?)\s*$", text, re.M):
        h = re.sub(r"^\d+(\.\d+)*\.?\s+", "", m.group(1).strip().replace("`", ""))
        h = re.sub(r"\s*\*\(.*\)\*\s*$", "", h)
        out.add(h)
        if " — " in h:
            out.add(h.split(" — ")[0])
    for m in re.finditer(r"^\s*- \*\*`?([^*`]+?)`?\*\*", text, re.M):
        out.add(m.group(1).strip())
    for m in re.finditer(r"^\| \*\*([^*]+?)\*\* \|", text, re.M):
        out.add(m.group(1).strip())
    return {t.lower().replace("*", "").replace("`", "") for t in out if t}


def check_section_titles(root: Path) -> list[Finding]:
    """X-section-title: a citation `the section titled X` names a heading of the
    file it names, or of its own page where it names none (council read 126). A
    section carries no label, so nothing else resolves the citation."""
    cache: dict[Path, set[str]] = {}

    def titles(path: Path) -> set[str]:
        if path not in cache:
            cache[path] = _titles(path)
        return cache[path]

    out: list[Finding] = []
    for sub in ("atoms", "compositions"):
        for md in sorted((root / sub).glob("*.md")):
            for i, raw in enumerate(md.read_text(encoding="utf-8").splitlines(), start=1):
                for m in SECTION_CITE.finditer(raw):
                    seg = raw[m.end():].lower().replace("*", "").replace("`", "")
                    known = set(titles(md))
                    fm = SECTION_FILE.search(raw[m.end():m.end() + 140])
                    if fm:
                        named = md.parent / fm.group(1)
                        if not named.exists():
                            named = root / fm.group(1)
                        known |= titles(named)
                    cited = re.split(r" in \[?[\w./-]+\.md|[.,;:)]", seg)[0].strip()
                    if any(seg.startswith(t) for t in known) or (
                            len(cited) > 8 and any(t.startswith(cited) for t in known)):
                        continue
                    out.append(Finding(md, i, "X-section-title",
                        f"'{raw[m.end():m.end() + 40].strip()}' opens no section title"))
    return out


CONTRACT_CITE = re.compile(r"\bExecution Contract ((?:[A-Z][a-z]+)(?: [a-z]+)*) (\d+)\b")
CONTRACT_LABEL = re.compile(r"\*\*((?:[A-Z][a-z]+)(?: [a-z]+)*) (\d+):")


def check_contract_labels(root: Path) -> list[Finding]:
    """X-contract-label: a citation `Execution Contract <Family> <N>` names a
    label `execution-contract.md` carries (council read 124). The contract's
    rules are labelled prose, so no rule block resolves them."""
    try:
        labels = {f"{m.group(1)} {m.group(2)}" for m in
                  CONTRACT_LABEL.finditer((root / "execution-contract.md").read_text(encoding="utf-8"))}
    except OSError:
        return []
    out: list[Finding] = []
    for sub in ("atoms", "compositions"):
        for md in sorted((root / sub).glob("*.md")):
            for i, raw in enumerate(md.read_text(encoding="utf-8").splitlines(), start=1):
                for m in CONTRACT_CITE.finditer(CODE_SPAN.sub("", raw)):
                    if f"{m.group(1)} {m.group(2)}" not in labels:
                        out.append(Finding(md, i, "X-contract-label",
                            f"'{m.group(0)}' names no label execution-contract.md carries"))
    return out


def check_composes_list(patterns: dict[Path, Pattern]) -> list[Finding]:
    out: list[Finding] = []
    for p in patterns.values():
        if p.path.parent.name != "compositions":
            continue
        m = re.search(r"(?ms)^## Composes\b[^\n]*\n(.*?)(?=^## |\Z)", p.text)
        if not m:
            continue  # H-heading owns a missing section
        if not COMPOSES_BULLET.search(m.group(1)):
            out.append(Finding(p.path, line_of(p.text, m.start()), "F-composes-list",
                "the Composes section lists no linked constituent — "
                "`- **[Name](path)** — role.` (spec-format.md §Composes); the "
                "generated catalogue, graph and pattern data read this list"))
    return out


def check_constituents_agree(patterns: dict[Path, Pattern]) -> list[Finding]:
    """F. A composition names its constituents in up to three places: the
    Composes list (the reader's copy, which the generated views read), a
    `Term constituents` declaration, and the `Composes N: EXACTLY ONE X instance
    MUST serve` rules. Where a second or third is present, it names the same
    specifications as the list. Actor Suspension's list carried a constituent
    its declaration and its rules did not, found by hand (council read 94)."""
    titles: dict[str, str] = {}
    for q in patterns.values():
        m = H1_TITLE.search(q.text)
        if m:
            titles[TRAILING_PAREN.sub("", m.group(1)).strip()] = q.path.stem
    out: list[Finding] = []
    for p in patterns.values():
        if p.path.parent.name != "compositions":
            continue
        sec = re.search(r"(?ms)^## Composes\b[^\n]*\n(.*?)(?=^## |\Z)", p.text)
        if not sec or not COMPOSES_BULLET.search(sec.group(1)):
            continue  # F-composes-list owns a missing list
        listed = set(COMPOSES_BULLET.findall(sec.group(1)))
        homes = []
        tc = TERM_CONSTITUENTS.search(p.text)
        if tc:
            homes.append(("`Term constituents`", tc.start(), set(CONSTITUENT_LINK.findall(tc.group(1)))))
        serve = SERVE_RULE.findall(sec.group(1))
        if serve:
            homes.append(("the `EXACTLY ONE … MUST serve` rules", sec.start(),
                          {titles.get(n, "?" + n) for n in serve}))
        for where, at, named in homes:
            if named != listed:
                extra = sorted(listed - named)
                missing = sorted(named - listed)
                out.append(Finding(p.path, line_of(p.text, at), "F-constituents",
                    f"{where} and the Composes list disagree — list only: "
                    f"{', '.join(extra) or 'none'}; {where} only: {', '.join(missing) or 'none'}"))
    return out


# --------------------------------------------------------------------------- #
# F-renumber — an invariant keeps its number (GRACE-lang Hard invariant 26, 27)
# --------------------------------------------------------------------------- #
# Provenance's migration moved its "No id reuse" invariant into two Identity
# rules and gave the freed number 9 to the durability invariant that had been
# 10. Nothing read a number's meaning across time, so the break surfaced four
# days later, only because a range citation in another spec became readable
# (council read 95). The references are read from git, never from a stored
# copy: the spec at HEAD when the working tree differs from it, and, for a
# migrated spec, the spec as it stood before the commit that migrated it.
# Three things are compared, all by number and one by title:
#   * every number a reference declared is still declared or tombstoned;
#   * a number a reference had wholly tombstoned is not declared again;
#   * an invariant's title does not reappear under another number — a title's
#     content words overlapping the other number's title by half or more, and
#     by more than they overlap the title now at their own number.
INVARIANT_TITLE = re.compile(r"^\s*-?\s*\*\*Invariant\s+(\d+)\s+[—-]\s*(.*?)\.?\*\*", re.M)
INVARIANT_TOMBSTONE = re.compile(r"^\s*Deleted:\s*Invariant\s+(\d+)\b", re.M)
MIGRATED_LINE = re.compile(r"^(?:Terms › `?qualifiers`?|Term qualifiers):[^\n]*\bmigrated\b", re.M)
_TITLE_STOP = frozenset("the a an of to in on at by for and or with is are as it its this that "
                        "no not over own one every any be never".split())


def _title_words(t: str) -> set[str]:
    t = re.sub(r"[`*\[\]().,;:—-]", " ", t.lower())
    return {w.rstrip("s") for w in t.split() if w not in _TITLE_STOP and len(w) > 2}


def _invariant_shape(text: str) -> tuple[set[int], set[int], dict[int, str]]:
    live = invariant_numbers(text)
    tomb = {int(n) for n in INVARIANT_TOMBSTONE.findall(text)} - live
    titles = {int(n): t.strip() for n, t in INVARIANT_TITLE.findall(text)}
    return live, tomb, titles


def check_invariant_numbers(root: Path, patterns: dict[Path, Pattern]) -> list[Finding]:
    def git(*args):
        try:
            r = subprocess.run(["git", "--no-optional-locks", *args], cwd=root,
                               capture_output=True, text=True, timeout=60)
        except (OSError, subprocess.SubprocessError):
            return None
        return r.stdout if r.returncode == 0 else None

    if git("rev-parse", "--is-inside-work-tree") is None:
        return []
    changed = set((git("diff", "--name-only", "HEAD") or "").split())
    # every commit that changed how often "migrated" appears, oldest first, with
    # the files it touched: the migration commit of a spec is among them
    log = git("log", "--reverse", "--format=@%h", "--name-only", "-S", "migrated",
              "--", "atoms", "compositions") or ""
    candidates: dict[str, list[str]] = {}
    commit = None
    for ln in log.splitlines():
        if ln.startswith("@"):
            commit = ln[1:]
        elif ln.strip() and commit:
            candidates.setdefault(ln.strip(), []).append(commit)

    out: list[Finding] = []
    for p in patterns.values():
        rel = p.path.relative_to(root).as_posix()
        refs: list[tuple[str, str]] = []
        if rel in changed and (head := git("show", f"HEAD:{rel}")) is not None:
            refs.append(("at HEAD", head))
        if MIGRATED_LINE.search(p.text):
            def migration(name: str):
                for c in candidates.get(name, []):
                    body = git("show", f"{c}:{name}")
                    if body is not None and MIGRATED_LINE.search(body):
                        prior = git("show", f"{c}^:{name}")
                        if prior is not None and not MIGRATED_LINE.search(prior):
                            return c, prior
                        return None
                return None
            before = migration(rel)
            if before is None:
                # a spec migrated under an earlier name (Observation was Clinical
                # Observation) is read at that name
                follow = git("log", "--follow", "--format=", "--name-status", "--", rel) or ""
                for ln in follow.splitlines():
                    parts = ln.split("\t")
                    if parts[0].startswith("R") and len(parts) == 3:
                        before = migration(parts[1])
                        if before is not None:
                            break
            if before is not None:
                refs.append((f"before its migration ({before[0]})", before[1]))
        if not refs:
            continue
        live, tomb, titles = _invariant_shape(p.text)
        reported: set[tuple[str, int]] = set()

        def add(kind: str, n: int, msg: str, at: int | None = None) -> None:
            if (kind, n) not in reported:
                reported.add((kind, n))
                hm = re.search(r"^\s*-?\s*\*\*Invariant\s+" + str(at or n) + r"\b", p.text, re.M)
                out.append(Finding(p.path, line_of(p.text, hm.start()) if hm else 1, "F-renumber", msg))

        for where, ref in refs:
            r_live, r_tomb, r_titles = _invariant_shape(ref)
            for n in sorted(r_live - live - tomb):
                add("lost", n, f"Invariant {n} was declared {where} and is neither declared nor "
                    f"tombstoned now (Hard invariant 26, Hard invariant 27)")
            for n in sorted(r_tomb & live):
                add("reused", n, f"Invariant {n} was tombstoned {where} and is declared again "
                    f"(Hard invariant 27)")
            for n, old in r_titles.items():
                words = _title_words(old)
                if not words:
                    continue
                own = len(words & _title_words(titles.get(n, ""))) / len(words)
                for m, now in titles.items():
                    if m == n:
                        continue
                    moved = len(words & _title_words(now)) / len(words)
                    if moved >= 0.5 and moved > own:
                        add("moved", n, f"Invariant {n}, *{old}* {where}, now stands at Invariant "
                            f"{m} — an invariant keeps its number (Hard invariant 26)", at=m)
    return out


# --------------------------------------------------------------------------- #
# Driver
# --------------------------------------------------------------------------- #

def main(argv: list[str]) -> int:
    args = [a for a in argv[1:] if not a.startswith("--")]
    flags = {a for a in argv[1:] if a.startswith("--")}
    root = Path(args[0]).resolve() if args else Path(__file__).resolve().parents[2]
    patterns = load_patterns(root)
    if "--census" in flags:
        return census(root, patterns)
    # link / forthcoming / count checks also scan the top-level canonical docs
    extra_docs = [root / n for n in ("roadmap.md", "readme.md", "CLAUDE.md",
                                     "pressure-testing.md", "contributing.md",
                                     "spec-format.md")]
    pattern_files = [p.path for p in patterns.values()]
    readme_files = [root / d / "README.md" for d in PATTERN_DIRS] + [root / "compositions" / "README.md"]
    scan = pattern_files + [f for f in extra_docs if f.exists()] + [f for f in readme_files if f.exists()]
    # de-dup
    scan = sorted(set(scan))

    findings: list[Finding] = []
    findings += check_links(root, scan)
    findings += check_invariant_counts(patterns, scan)
    findings += check_models_present(patterns)
    findings += check_stale_forthcoming(root, patterns, scan)
    findings += check_orphan_forthcoming(root, patterns)
    findings += check_counts(root, patterns)
    findings += check_rests_on_refs(patterns, scan)
    findings += check_constituent_calls(patterns)
    findings += check_atomicity_over_audit(patterns)
    findings += check_rebuild_bound(patterns)
    findings += check_recording_step(patterns)
    findings += check_seal_key(patterns)
    findings += check_retry_bit(patterns)
    findings += check_stray_directory(root)
    findings += check_formal_siblings(root, patterns)
    findings += check_stale_census(root, patterns)
    findings += check_acceptance_surface(patterns)
    findings += check_migration_seam(patterns)
    findings += check_end_marker(patterns)
    findings += check_dead_anchors(patterns)
    findings += check_term_coverage(patterns)
    findings += check_seam_injections(patterns)
    findings += check_provenance_drift(root, patterns)
    findings += check_council_register(root)
    findings += check_signature_alternation(patterns)
    findings += check_step_reference(patterns)
    findings += check_status_grammar(patterns)
    findings += check_status_mirror(root, patterns)
    findings += check_duplicate_rows(root)
    findings += check_banned_token(root)
    findings += check_banned_application(root)
    findings += check_internal_ids(patterns)
    findings += check_whitelist_gloss(patterns)
    findings += check_term_registry(patterns)
    findings += check_ledger(patterns)
    findings += check_heading_standard(root, patterns)
    findings += check_section_classification(root)
    findings += check_range_form(root)
    findings += check_stripped_links(root)
    findings += check_contract_labels(root)
    findings += check_section_titles(root)
    findings += check_composes_list(patterns)
    findings += check_constituents_agree(patterns)
    findings += check_invariant_numbers(root, patterns)

    findings.sort(key=lambda f: (f.code, str(f.path), f.line))
    for f in findings:
        rel = f.path.relative_to(root)
        tag = " (advisory)" if f.code in ADVISORY_CODES else ""
        print(f"{rel}:{f.line}: [{f.code}]{tag} {f.message}")

    gating = [f for f in findings if f.code not in ADVISORY_CODES]
    advisory = [f for f in findings if f.code in ADVISORY_CODES]

    n_atoms = sum(1 for p in patterns.values() if "/atoms/" in p.path.as_posix())
    n_comps = sum(1 for p in patterns.values() if "/compositions/" in p.path.as_posix())
    tail = f"{len(gating)} finding(s)"
    if advisory:
        tail += f" + {len(advisory)} advisory (non-gating)"
    print(f"\n— scanned {len(patterns)} patterns "
          f"({n_atoms} atoms, {n_comps} compositions); "
          f"{tail}.", file=sys.stderr)
    return 1 if gating else 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
