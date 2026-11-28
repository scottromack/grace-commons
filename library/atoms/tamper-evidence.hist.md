---
title: Tamper Evidence — history
nav_exclude: true
search_exclude: true
---

# Tamper Evidence — history

The dated record of how [Tamper Evidence](./tamper-evidence.idd) got here, moved out of the spec on 2026-10-19 because a reader does not need it to use the spec today. The spec keeps every section `spec-format.md` requires and its `Deleted:` tombstones; everything smaller is in `git log -- atoms/tamper-evidence.md`.

## Decisions

Entries that record a round or a migration rather than a turn the pattern took.

- **2026-09-12 — Rewritten in GRACE lang v0.35; nothing but language changed.** *Chose:* labelled rules in fenced blocks, the two actions as a signature block, the verify precedence carried by each rule's own condition rather than by the order the rules sit in, the nine invariant numbers frozen exactly as Audit Trail cites them, Generation acceptance moved ahead of Non-goals as `spec-format.md` requires, Non-goals and Edge cases as two sections, the case table kept beside the rules. *Over:* the prose spec. *Because:* the migration plan takes the atoms the migrated compositions already cite first — Audit Trail cites this atom's Invariants 1, 3, 4, 8 and 9 (`tools/grace/cites.py --into tamper-evidence`).

- **2026-09-26 — The read surface restored.** *Chose:* `read()` in the signature block, answering every evidence with its stored fields (Operation 27 through 30). *Over:* an atom with no declared read. *Because:* the prose spec declared its read surface in its Outputs section — "the current set of [Evidence] records", each with its fields — and the migration dropped it with the section. Restored as the prose had it, not widened. Found beside the same loss in Permissions and Actor Identity, which the cold regeneration of the Attributed Permissions Admin demo surfaced (council read 230).

- **2026-10-19 — The store's guarantees cited, not restated.** *Chose:* the seal store supplied under Execution Contract Store 1, Store 3 and Store 4 (Capability requirement 2), and the four rules that restated them tombstoned to their owner — Invariant 9.3, no partial evidence on a storage-failure, and Seal atomicity 1, a seal atomic, to Store 1; Seal atomicity 2, no evidence left by a crash with a proof the mechanism did not produce, to Store 1 and Store 3; Seal atomicity 3, the deployment owning the seal store's durability, to Store 3; rules 106 to 103. *Over:* the atom restating, for its own store, what every deployment's store guarantees. *Because:* the maintainer ruled 2026-10-12 that the corpus takes a store's specification, never the store, and `execution-contract.md` writes it once as the Store contract. Discarding the proof on a storage-failure stays (Operation 11): it binds the proof outside the store as well. What the atom does for its domain is unchanged.

- **2026-10-21 — Record set match decides which record set and the seal check its content; the contract covers mechanisms checkable from the verification set; a failed read answers on every action.** *Chose:* record set match answering yes for the named record set whatever its content, the content left to the seal check (Term record set match), so a change is detected where the right records are presented and the check can run (Invariant 2.1), the proof is bound to the record set presented at [Seal] (Invariant 3.1), two verifications answer alike unless one answers mechanism-verification-unavailable or state-unavailable (Invariant 7.1), and the verification set names the record set match the verdict rules read; verified obliged for the right records under a seal check that holds (Operation 19, Operation 33); the contract held for every sound mechanism whose verification function consults no source outside the verification set, so a chain keyed by a shared secret is outside it and the payments example is a signed hash chain (Invariant 8.1); state-unavailable on all three actions where the read of the seal store fails, the Execution Contract's Step 1 failure (Operation 31, Term store read), with [Seal]'s refusals in one stated order, the store read first (Operation 32, Term seal refusal order); the composing patterns and the mechanism read from the deployment's own declaration (External check 3, External check 4, Capability requirement 3). *Over:* a match a host could decide by content, which reports tampering as a caller error; detectability and binding rules that the page's own wrong-record and altered-record examples break; no answer obliged for a proof that holds; a neutrality claim taking in mechanisms no auditor can check from the records; a read forbidden to refuse a store it cannot read; conformance checks reading what the records do not carry. *Because:* Final Critique 5 found each a divergence between conforming builds or a rule no conforming build could keep, and the page already held the line: its Summary rests the guarantee on what is detectable from the records alone, and its Intent names only mechanisms a verifier checks without a secret; Actor Identity's fifth round cured a failed store read, a one-way verified rule and a declaration-reading check the same way. Compositions affected: Audit Trail, which presents its seals to this atom, routes state-unavailable from [Verify] and [Read] when its round reads them.

- **2026-10-21 — A failed read answers as the Execution Contract says.** *Chose:* the failed read cited from the Execution Contract (Capability requirement 2, Execution Contract Read 1 through 3) and the two rules that restated it deleted to it: the atom-wide state-unavailable (Operation 31) to Read 1, and [Read]'s state-unavailable on a failed read alone (Operation 30) to Read 2 beside Operation 27; the read's condition off the rules it held to an answered read (Operation 14, Operation 15, Operation 27), the failed read off the verifications Invariant 7.1 compares, which Read 2 holds to verifications whose reads answered, the read off the seal refusal order, Term database read deleted, state-unavailable off every signature and off the answers Check 4.1 tells apart; rules 106 to 104. *Over:* the page stating for itself what every action answers when the seal records cannot be read. *Because:* the maintainer ruled on 2026-10-21 that the Execution Contract states the failed read once; this page's fifth Final Critique had made one of the cures the contract's Read family is written from. A mechanism that cannot verify keeps its own answer, mechanism-verification-unavailable: the mechanism is no read of the database. What each action answers on an answered read is unchanged.

- **2026-10-21 — Which refusal answers is the Execution Contract's.** *Chose:* [Seal]'s refuses line kept as the page wrote it, already in the order the seal refusal order gave — invalid-request, mechanism-failure, then storage-failure, which answers only at the write — and the order cited from the Execution Contract (Capability requirement 2, Execution Contract Refusal 1); Operation 32, which evaluated the seal refusal order, deleted to Refusal 1, and Term seal refusal order deleted with it; rules 104 to 103. *Over:* the page stating for itself which of [Seal]'s refusals answers when both apply. *Because:* the maintainer ruled on 2026-10-21 that the Execution Contract states once that the refusal listed first on an action's refuses line answers; this page's fifth Final Critique had made the cure one specification at a time. What each action answers on every call is unchanged.

- **2026-10-22 — The wiring is read outside the records, as the Execution Contract says.** *Chose:* External check 3, the auditor reading which composing patterns a deployment wired in from the deployment's own declaration, deleted to Execution Contract Conformance 9, with Check 6.1's tombstone, which named it, now naming the contract, the wiring off the NOTE listing what the seal records do not carry, and the label cited on Capability requirement 2; rules 103 to 102. *Over:* the page stating for itself that the wiring is an external check. *Because:* the maintainer ruled on 2026-10-22 that five repeated cures are each stated once, the wiring declaration among them; this page's fifth Final Critique had made the cure one specification at a time. What each action does and answers is unchanged.

- **2026-10-22 — The external anchor's answer can change, and the invariants that read the seal check say so.** *Chose:* a change in what the mechanism's own external anchor answers its verification function for an evidence's proof, such as a revocation or a withdrawal of trust the anchoring authority records, named once (Term anchor change); two verifications of one evidence against one record set held to one answer only where no anchor change falls between them (Invariant 7.1), a recorded proof held to verifying against the record set presented at [Seal] only where no anchor change has reached it (Invariant 3.1), and no cached result carried across an anchor change (Verification caching 3). *Over:* a consistency invariant and a binding invariant that a lawful revocation at the anchoring authority breaks on a mechanism the contract covers, with a cache free to answer verified across the change where a fresh verification answers proof-invalid. *Because:* Final Critique 6 found the two answers parting, and the verification set already takes in the mechanism's own external anchor, whose records the atom does not own (External check 2); a mechanism judging expiry against the verify-time clock stays outside the contract, since the verification set does not take in now (Invariant 4.3, Invariant 8.1). Actor Identity's sixth round held its consistency invariant to one registry view and its binding invariants to the material in force at attestation instant, the same shape. The round also moved the cryptographic material and record set match into the Capability requirements the deployment supplies (Capability requirement 4, Capability requirement 5; Operation 22 and Operation 22a tombstoned to them), as the seam normalization moved now. Compositions affected: Audit Trail, which rests on Invariant 3 and Invariant 7, reads them under an unchanged anchor when its round reads them.

- **2026-10-22 — A detected tampering is bounded below by each seal it fails.** *Chose:* the anchored bound an auditor draws for a detected tampering stated as the one the records always give: the anchoring instant of every evidence over the record set whose verification answers proof-invalid bounds the tampering below (Check 5.1, now citing Invariant 2.1 and Operation 4), since such an evidence sealed the records as they stood before the alteration; the Breach forensics scenario closing the window at the next evidence that verifies the altered records, where one exists, and the Rejection paths' journal, which one seal covers, leaving it open. *Over:* a check obliging a bound between two adjacent anchoring instants, which a record set sealed once cannot give and a tampering made after the last seal over a record set never has, and a scenario reading the window from a verifying seal to the failing seal after it, a pair that brackets when the altered records were written rather than when they were altered. *Because:* Final Critique 7 found a conforming deployment failing the page's own check: nothing obliges a second seal over a record set (Term cadences, Non-goal 14), and the Financial and Payments examples seal each day's records once. The round also deleted Invariant 4.2, *[Verify] MUST NOT consult the host's state*, to Invariant 4.3, as Actor Identity's seventh round deleted its twin: on every reading of Term verification set the rule either forbade the host-injected record set match Invariant 4.1 has [Verify] consult or restated Invariant 4.3. Compositions affected: none; Audit Trail rests on Invariant 4 as a family, which keeps Invariant 4.1 and Invariant 4.3.

- **2026-10-23 — A detected tampering is bounded below only by the seals the altered records fail, and a seal over purged records is no proof of their content.** *Chose:* Check 5.1 bounding a detected tampering below by the anchoring instant of every evidence over the record set whose verification over the altered record set answers proof-invalid, where no anchor change exists for the evidence's proof, now citing Invariant 3.1; the Breach forensics scenario running each seal over the suspect records as they now stand, and the [Proof Invalid] entry naming the anchor change; Retention coupling 1, *A purged record set MUST leave [Verify] unable to hold*, deleted to Retention coupling 3; Operation 12, which restated Invariant 1.1 for [Seal] alone, deleted to it; the Generation acceptance introduction naming the deployment's declared mechanism among what the conformance checks read; rules 102 to 100. *Over:* a check that took any verification answering proof-invalid as a seal made before the alteration, so a backup presented to a seal made after the alteration, as the Rejection paths present one, or a seal whose anchor was later revoked, put the bound above the alteration, the previous round's own cure failing two histories the page permits (Identity 8, Non-goal 13, Term anchor change); and a rule no party the page names could keep: [Verify] may not read a purge (Invariant 4.3), and a host answering record set match for a copy of a purged record set as it answers for the Rejection paths' backup answers yes, so the copy verifies. *Because:* Final Critique 8 found both, and Retention coupling 3 already says what stays true after a purge: no seal over destroyed records is proof of their content. The anchor condition is the watched shape *the external answer that moves*, flagged after the checks. Compositions affected: none; Audit Trail cites Invariant 1, 3, 4 and 8, all unchanged.

- **2026-10-23 — The atom answers only whether a record set changed since its seal; when it changed belongs to the composing patterns.** *Chose:* the atom bounding no time of change (Non-goal 15), a deployment needing one composing a forensic-attribution pattern (Non-goal 16); Check 5.1, the anchored lower bound on a detected tampering, deleted to a trusted-timestamping pattern (Non-goal 9), and Check 5.2, the bound between two seals, to a forensic-attribution pattern; Verification caching 3, no cached result across an anchor change, deleted to an external-anchoring pattern (Non-goal 2), whose question is what a seal answers once its anchor changes; Retention coupling 3, no seal over destroyed records read as proof of their content, deleted to the composing pattern that owns the purge (Retention coupling 2), and Retention coupling 1's tombstone re-pointed there; the Breach forensics scenario answering, for each seal, whether the suspect records changed since it, with the window and the attribution left to Forensic Attribution; the Rejection paths, the Regulator integrity audit, the Financial and Healthcare examples, the [Evidence] and [Verified] entries and the eIDAS reference no longer placing a change in time; the Summary and the Intent saying the same; rules 100 to 98. The anchor change stays on Invariant 3.1 and Invariant 7.1 and in the [Proof Invalid] entry: it keeps the binding and consistency claims [Verify] makes against one seal true for a mechanism whose anchor can change, and says nothing of what such a seal then means. The anchoring instant stays a field the evidence carries (State 4, Operation 4); a bound drawn from it is the trusted-timestamping pattern's. *Over:* the atom keeping a forensic bound on when records changed, which three rounds cured and the next found broken on histories the page permits (Final Critique 6 through 8). *Because:* the maintainer ruled on 2026-10-23, direction (b) of the 02:44Z escalation, that the atom answers only *has this record set changed since this seal*, and that when it changed leaves the atom for Trusted Timestamping, External Anchoring and Forensic Attribution, all forthcoming. Compositions affected: none; Audit Trail's own forensic window (its Check 4.1, seal cadence 1 and 2, seal mechanism 2) rests on [Verify]'s answers and the seal stamps, which stand, and on none of the deleted rules.

- **2026-11-02 — The string cap has a default.** *Chose:* the string cap stated as 4,096 Unicode code points where a deployment declares none, Capability requirement 6 added, citing Execution Contract Input 2. *Over:* a bound the deployment must supply, or silence. *Because:* the maintainer ruled on 2026-11-01 that what the host must bound takes one posture, a corpus default a deployment may override; the string inputs are a record set reference and a mechanism credential, which is keying material, and a PEM-encoded 4096-bit RSA private key runs to about 3,200 code points; the credential sets the cap.
- **2026-11-21 — A mechanism's verification fault has its own answer; the host's duties at the seam are capability requirements; the page's edge-case headings and labels take spec-format's spellings.** *Chose:* the seal check gaining the value faulted (Capability requirement 12) and [Verify] answering mechanism-verification-failure on it (Operation 35), the counterpart of [Seal]'s mechanism-failure, with Invariant 2.1 and 3.1 conditioned on neither unavailable nor faulted and Invariant 7.1 excluding a failure as it excludes an outage; Term sealed record set declaring what Invariant 2.1, 3.1 and 3.2 compare with, and Non-goal 12 becoming Capability requirement 10 (the host presents a record set in one form at [Seal] and [Verify]); Capability requirement 11, the deployment supplying an evidence id no evidence has carried, the form Assignment, Approval Step and Notification took, Identity 2 standing; Invariant 4.4, a value the host injects at the seam being taken, not consulted, and Operation 17, 18, 19 and 35 and Invariant 2.1 conditioned on an evidence existing for the id, as Operation 16 is, so a lookup miss answers not-known alone; Check 3.2 checking the sealed record set answers verified, beside Check 3.1's failure direction, which stays at its least difference; the record is *evidence* and the action is [Seal], one name each; the headings *Atomic writes*, *Concurrency* and *Retention asymmetry*, the old labels tombstoned naming the new. *Over:* a seal check of three values that left a faulting mechanism with no arm (Capability requirement 8 barred failed there, Capability requirement 9 barred unavailable), an obligation on the host under a Non-goal heading, a check that proved one direction of Invariant 3.1 and 2.1 alone, and headings that stood beside the table's own rows. *Because:* Scott's directions of 2026-11-19 (rounds/open-line-choices-directions-2.md, items 77 to 80, and group 6 of 2026-11-19T21:32Z); the cost of the check Check 3.1 keeps is that it tries one differing set, the least, where Invariant 2.1 covers any.

- **2026-11-26 — The atom converted to the bond shape, batch 3 of the converter: it offers the evidence id and names no other pattern.** *Chose:* the tree order, every label kept and none renumbered; `Term offer key: key evidence id; carried by evidence; calls Read` (Bonds Key 9, 10, 26), the evidence id declared (Key 18). No need: the record carries no actor (Non-goal 6), so the actor id need the converter drafted from Non-goal 7's name was dropped. Non-goal 7 tombstoned to Non-goal 6; Composition note 2, the Seal entry, two Verify entries, a scenario, the Part 11 source and the composing-patterns NOTE say each job, not a pattern. Retention asymmetry 1 is no skipped rule: the family kept Retention coupling 2's number when the heading was renamed (80f8bac0, 2026-11-21), and Retention coupling 1's tombstone stands under its old family in Deleted rules, so no tombstone is written for a label that never stood. Labelled rules 108 before, 107 after; 707 lines before, 730 after. *Over:* a tombstone for a label that never stood, and a key need on the actor id; splitting by length (Scott, 2026-11-25 11:14 PM Central: "don't arbetrarly split at 800 lines"). *Because:* unit `atom: Tamper Evidence, converted` (batch 3, 4 of 5).

## Migration notes

- **2026-09-15 — Capability requirement 1, moved from Operation.** What the deployment supplies, which is what the family means. The rule stood under `Operation` — one action's rules — while naming no action, because this spec was migrated before the standard family had a home in an atom; the five atoms migrated a day later put the same obligation here. The words are the words the rule carried (council read 76).

## Deleted rules

The spec's tombstones, moved here from the page on 2026-11-13 because the spec is done (GRACE-lang Hard invariant 25 and Hard invariant 27, since v0.71): each `Deleted:` line byte for byte and in the page's order, under the heading it stood under there. A tombstone carries no obligation, and each still reserves its label: no rule of [Tamper Evidence](./tamper-evidence.idd) may carry it again.

### Structure › Identity model

```
Deleted: Identity 3. Execution Contract Logic confinement 3 owns it.
```

### Structure › Operations

```
Deleted: Operation 12. Invariant 1.1 owns it.
Deleted: Operation 21. Capability requirement 1 owns it.
Deleted: Operation 22. Capability requirement 4 owns it.
Deleted: Operation 22a. Capability requirement 5 owns it.
Deleted: Operation 23. Execution Contract Logic confinement 3 owns it.
Deleted: Operation 24. Execution Contract Logic confinement 3 owns it.
Deleted: Operation 30. Operation 27 and Execution Contract Read 2 own it.
Deleted: Operation 31. Execution Contract Read 1 owns it.
Deleted: Operation 32. Execution Contract Refusal 1 owns it.
```

### Structure › Invariants › Invariant 2 — Detectability of tampering

```
  Deleted: Invariant 2.3. Non-goal 17 owns it.
```

### Structure › Invariants › Invariant 4 — Verification self-containment given the originating records

```
  Deleted: Invariant 4.2. Invariant 4.3 owns it.
```

### Structure › Invariants › Invariant 9 — Seal record durability

```
  Deleted: Invariant 9.2. Invariant 9.1 and Execution Contract Database 6 own it.
  Deleted: Invariant 9.3. Execution Contract Database 1 owns it.
```

### Generation acceptance › Conformance checks

```
Deleted: Check 5.1. A trusted-timestamping pattern owns it (Non-goal 9, Non-goal 15): an anchored bound on when a record set changed.
Deleted: Check 5.2. A forensic-attribution pattern owns it (Non-goal 15, Non-goal 16): a bound between two seals on when a record set changed.
Deleted: Check 6.1. Execution Contract Conformance 9 owns it.
Deleted: Check 6.2. External check 4 owns it.
```

### Generation acceptance › External checks

```
Deleted: External check 3. Execution Contract Conformance 9 owns it.
```

### Non-goals

```
Deleted: Non-goal 12. Capability requirement 10 owns it.
```

### Edge cases › Atomic writes

```
Deleted: Seal atomicity 1. Execution Contract Database 1 owns it.
Deleted: Seal atomicity 2. Execution Contract Database 1 and Execution Contract Database 3 own it.
Deleted: Seal atomicity 3. Execution Contract Database 3 owns it.
```

### Edge cases › Concurrency

```
Deleted: Concurrent seal 1. Concurrency 1 owns it.
Deleted: Concurrent seal 2. Concurrency 2 owns it.
```

### Edge cases › Retention asymmetry

```
Deleted: Retention coupling 1. The composing pattern that owns the purge owns it (Retention asymmetry 2): a copy of a purged record set can still verify.
Deleted: Retention coupling 2. Retention asymmetry 2 owns it.
Deleted: Retention coupling 3. The composing pattern that owns the purge owns it (Retention asymmetry 2): what a seal over destroyed records proves.
Deleted: Retention asymmetry 1. Retention coupling 1, above, held it under the family's old name; Retention asymmetry 2 owns it.
```

### Edge cases › Verification caching

```
Deleted: Verification caching 3. An external-anchoring pattern owns it (Non-goal 2): what a seal answers once its anchor changes.
```

### Composition notes

```
Deleted: Composition note 5. GRACE-lang Hard invariant 26 owns it.
```
