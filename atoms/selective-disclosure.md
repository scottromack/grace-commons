---
title: Selective Disclosure
parent: Atomic Concepts
has_toc: true
toc: true
---

# Selective Disclosure

<details open markdown="block">
<summary>Table of contents</summary>
{: .text-delta }
1. TOC
{:toc}
</details>

## Summary

Selective Disclosure keeps a permanent, add-only record of every time someone's data was shared with anyone other than that person — answering the question regulators and individuals routinely ask: what was shared about this person, with whom, under what authority, and when?

The pattern does not do the sharing — it does not fetch, redact, or transmit data. Instead, right after a disclosure happens, the system calls it to log the subject, the recipient, the scope of what was shared, and the authority for sharing, which must be one of exactly three kinds: consent (the person agreed), legal hold (a legal process compelled it), or regulatory (a regulation required it).

Once written, a record can never be changed, and this pattern never deletes one — which is precisely what guarantees the sharing history is complete and cannot be quietly altered. How long the records are kept, and when one may lawfully be destroyed, is for a separate retention pattern to decide. The records can be queried by subject, recipient, authority type, or date, producing the disclosure accounting that privacy and securities regulations demand.

A few questions need other patterns to answer — whether a referenced consent was actually valid at the time, whether every disclosure was in fact logged, and whether a backdated timestamp is honest — and those boundaries are spelled out in the Generation acceptance section.

*Also known as: a disclosure log, an accounting of disclosures, a data-sharing register.*

---

## Intent

WHY:
Regulated systems handling personal data, financial records or protected health information must keep a complete and durable account of every disclosure made — what was shared, with whom, under what legal authority, and when. A GDPR (EU General Data Protection Regulation) supervisory authority conducting an Article 15 review asks what was disclosed to which recipients. An HHS OCR (Office for Civil Rights) inspector validating HIPAA (US Health Insurance Portability and Accountability Act) compliance asks for the accounting of disclosures section 164.528 requires. An SEC (Securities and Exchange Commission) examiner reviewing broker-dealer records asks for the disclosure trail Rule 17a-4 mandates. The obligation is the same across all three: answer provably, without developer testimony, log reconstruction or institutional memory.

This atom is the accountability layer that makes those answers possible, and the line it holds is between *recording* and *performing*. An atom that also performed disclosures — retrieving subject data, applying redaction, routing to recipients — would absorb concepts from storage layers, redaction engines and notification systems, each with its own state, its own invariants and its own composing pattern. Absorbing them destroys freestanding status and produces a spec that cannot be composed independently of the technologies it would have to name. The atom specifies the accountability obligation; the implementation specifies the mechanics of delivery.

Four adjacent concepts are distinguished, and every distinction is load-bearing. [Audit Trail](../compositions/audit-trail.md) answers *what happened in this system* for any action, any actor, any subject; this atom answers *what was disclosed about this subject, to whom, under what authority* for one class of event. [Consent](./consent.md) governs authorization — *may I?* — and is a precondition check; this atom records *I did*, after the fact, whether the basis was consent, compulsion or regulation. [Legal Hold](./legal-hold.md) governs compelled *preservation*; this atom records compelled *disclosure*, and the two address opposite obligations on the same records. [Actor Identity](./actor-identity.md) answers *who authorized an action*; this atom answers *to whom was subject data disclosed*. Both carry attribution fields and they are different kinds of attribution — a disclosure to a regulator names the regulator here and may name the authorizing compliance officer in a composing attestation.

The authority field is where the atom earns its name. Three types and no others — consent, legal-hold, regulatory — cover the complete space of legitimate disclosure bases: data-subject authorization, legal compulsion, regulatory mandate. Refusing a fourth value is a structural claim, not a validation convenience: a disclosure falling outside those three is not a legitimate disclosure, and the database must not be able to say otherwise. Splitting the field into a machine-queryable type and a human-readable reference is what keeps the accounting both filterable and readable by the regulator who has to act on it.

## Structure

### Identity model

```
Identity 1: The atom MUST identify a disclosure record by the disclosure id.
Identity 2: The host MUST allocate a disclosure id at the seam.
Identity 3: The transition MUST NOT allocate a disclosure id.
Identity 4: The atom MUST NOT change a disclosure id.
Identity 5: Two disclosure records in one database instance MUST NOT share a disclosure id.
Identity 6: The deployment MUST route EVERY call to one database instance.
Identity 7: The atom MUST NOT identify a disclosure record by the subject reference.
Identity 8: The atom MUST admit a second disclosure record carrying a recorded subject reference.
Identity 9: The atom MUST match a subject reference exactly.
Identity 10: The atom MUST match a recipient exactly.
Identity 11: The atom MUST NOT normalize a subject reference.
Identity 12: The atom MUST NOT confirm that a subject reference names a known subject.
Identity 13: The atom MUST NOT interpret a scope.
Identity 14: The atom MUST NOT interpret a recipient.
Deleted: Identity 15. Execution Contract Logic confinement 10 owns it.
```

NOTE: open 2026-10-21-g — Identity 6 reads as each call routed to one instance or as every call routed to the same instance, and under the first a subject reference query answers only its own instance's records.

Term disclosure record: one recorded disclosure of one subject's data to one recipient under one authority — the record this atom holds.

Term disclosure id: the opaque string naming one disclosure record — a [Disclosure Id]; host-allocated at the seam, fresh per call by the seam's construction.

Term subject reference: the opaque reference naming the data subject whose data was disclosed — a [Subject Reference]; a property of the record, never the record's identity.

Term recipient: the opaque string naming the party the data reached — a [Recipient].

Term scope: the opaque string naming what subset of the subject's data was disclosed — a [Scope]; recorded as the caller declares it.

Term database instance: one named database a call is routed to; disclosure id uniqueness ranges over one instance.

Term seam: the atom's I/O boundary as the section titled Logic Confinement Principle in `execution-contract.md` declares it; the host injects the clock reading and the disclosure id here.

Term transition: the atom's evaluation of one call against the disclosure records, as the section titled Logic Confinement Principle in `execution-contract.md` declares it.

NOTE: open 2026-10-27-a — Term seam, Term transition, Term now and Term business caller cite the section titled Logic Confinement Principle in `execution-contract.md`, which declares none of them.

### State

```
State 1: EVERY disclosure record MUST carry disclosure id, subject reference, recipient, scope, authority type, authority reference and disclosure instant.
State 2: The atom MUST NOT offer a state machine over a disclosure record.
State 3: The atom MUST NOT offer an optional field on a disclosure record.
State 4: The atom MUST NOT offer an edit surface.
State 5: The atom MUST NOT offer a removal surface.
State 6: The atom MUST NOT offer a retraction surface.
State 7: The atom MUST NOT offer a batch record surface.
Deleted: State 8. Invariant 6.1 and Execution Contract Database 4 own it.
Deleted: State 9. Operation 27, Execution Contract Query 4, Invariant 6.1 and Execution Contract Database 4 own it.
State 10: The atom MUST NOT record a receipt instant.
```

NOTE: open 2026-10-21-f — State 1 and Invariant 3.1 both require a disclosure instant on every record, and Term disclosure instant's *never later than now* restates Invariant 4.1 beside Term resolved disclosure instant.

### Capability requirement

```
Capability requirement 1: The deployment MUST supply now at the seam.
Capability requirement 5: The deployment MUST supply the disclosure records PER Execution Contract Database 1, Execution Contract Database 3, Execution Contract Database 4, Execution Contract Database 6, Execution Contract Read 1 through 3, Execution Contract Refusal 1 and Execution Contract Query 1 through 4.
Deleted: Capability requirement 2. Execution Contract Logic confinement 7 owns it.
Deleted: Capability requirement 3. Execution Contract Logic confinement 7 owns it.
Deleted: Capability requirement 4. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 1. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 2. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 3. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 4. State 10 owns it.
Deleted: Clock semantics 5. Non-goal 23 owns it.
```

### Operations

```
record(subject_ref, recipient, scope, authority, optional disclosed_at)
  answers recorded(disclosure_id)
  refuses invalid-request | unknown-authority-type | storage-failure

read(filters)
  answers the matching disclosure records
  refuses invalid-query
```

```
Operation 1: IF subject reference EQUALS blank THEN [Record] MUST answer invalid-request.
Operation 2: IF recipient EQUALS blank THEN [Record] MUST answer invalid-request.
Operation 3: IF scope EQUALS blank THEN [Record] MUST answer invalid-request.
Operation 4: IF authority EQUALS blank THEN [Record] MUST answer invalid-request.
Operation 5: IF authority type EQUALS blank THEN [Record] MUST answer invalid-request.
Operation 6: IF authority reference EQUALS blank THEN [Record] MUST answer invalid-request.
Operation 7: IF now PRECEDES the resolved disclosure instant THEN [Record] MUST answer invalid-request.
Deleted: Operation 8. Execution Contract Refusal 1 owns it.
Operation 9: IF authority type IS NOT IN the authority types THEN [Record] MUST answer unknown-authority-type.
Operation 10: An admitted record MUST record EXACTLY ONE disclosure record.
Operation 11: An admitted record MUST take the disclosure record's disclosure id from the injected disclosure id.
Operation 12: An admitted record MUST stamp the disclosure record's disclosure instant from the resolved disclosure instant.
Operation 13: An admitted record MUST answer the disclosure id.
Operation 14: IF the database refuses the write THEN [Record] MUST answer storage-failure.
Deleted: Operation 15. Execution Contract Refusal 1 owns it.
Operation 16: A refused [Record] MUST NOT record a disclosure record.
Operation 17: A refused [Record] MUST leave the database as the call found the database.
Operation 18: An admitted read MUST answer the matching disclosure records in disclosure instant ascending order.
Operation 19: An admitted read MUST order two disclosure records sharing a disclosure instant by disclosure id ascending (Execution Contract Logic confinement 10).
Operation 20: IF no disclosure record matches THEN an admitted read MUST answer an empty record sequence.
Deleted: Operation 21. Execution Contract Query 4 and Operation 27 own it.
Operation 22: IF a filter's axis IS NOT IN the filter axes THEN [Read] MUST answer invalid-query.
Operation 23: IF a disclosure id, subject reference OR recipient filter's value EQUALS blank THEN [Read] MUST answer invalid-query.
Operation 24: IF an authority type filter's value IS NOT IN the authority types THEN [Read] MUST answer invalid-query.
Operation 25: IF a disclosure instant range's before PRECEDES the range's after THEN [Read] MUST answer invalid-query.
Deleted: Operation 26. Execution Contract Query 2 owns it.
Operation 27: An admitted read MUST answer EVERY disclosure record matching the supplied filters.
Operation 28: An admitted read MUST NOT answer a disclosure record failing a supplied filter.
Operation 29: [Read] MUST NOT write.
Operation 30: [Read] MUST NOT answer storage-failure.
Deleted: Operation 31. Capability requirement 1 owns it.
Deleted: Operation 32. Execution Contract Logic confinement 3 owns it.
Deleted: Operation 33. Execution Contract Logic confinement 3 owns it.
Deleted: Operation 34. Execution Contract Logic confinement 3 owns it.
Deleted: Operation 35. Execution Contract Refusal 1 owns it.
Operation 36: IF a filter is malformed THEN [Read] MUST answer invalid-query.
Operation 37: IF the supplied disclosure instant DOES NOT EQUAL blank AND the supplied disclosure instant IS NOT IN the instants THEN [Record] MUST answer invalid-request.
```

NOTE: watch the untyped input (Operation 37).

Term now: the wall-time reading the host takes at the seam and hands to the transition, as the section titled Logic Confinement Principle in `execution-contract.md` declares it; never read inside the transition, never supplied by the business caller.

Term business caller: the party whose action the call carries, as the section titled Logic Confinement Principle in `execution-contract.md` declares it; never the source of an injected value.

Term authority: the structured field naming the basis the disclosure was made under — an [Authority]; carries authority type and authority reference and nothing else; a field a call's authority carries beyond the two is not recorded.

Term authority type: consent | legal-hold | regulatory — an [Authority Type], set at record and never changed.

Term authority types: the three members of authority type, cited here from that declaration (Closed vocabulary 15).

Term authority reference: the opaque string naming the specific authority — an [Authority Reference]; a consent record's id, a legal hold's id, or a regulatory citation.

Term disclosure instant: the instant the disclosure happened — a [Disclosure Instant]; caller-supplied or resolved to now, and never later than now.

Term resolved disclosure instant: the disclosure instant the record carries — the supplied value, and now where the call leaves it blank.

NOTE: watch the instant left blank (Term resolved disclosure instant).

Term filter axes: disclosure id | subject reference | recipient | authority type | disclosure instant — the five axes [Read] accepts, and no others, a filter keyed by the projection of the field its axis names, and a filter on disclosure instant carrying a range whose after is its start and whose before is its end.

NOTE: watch the wire layer (Term filter axes).

Term admitted record: a [Record] call whose fields, resolved disclosure instant and authority type the guards all admit.

Term admitted read: a [Read] call whose every filter axis and filter value the guards admit.

| # | Condition | [Record] answers |
|---|---|---|
| 1 | a field is blank, a supplied disclosure instant is no instant, or the resolved disclosure instant follows now | invalid-request |
| 2 | every field passes, authority type stands outside the authority types | unknown-authority-type |
| 3 | every precondition passes, the database refuses the write | storage-failure |
| 4 | every precondition passes, the database accepts the write | `recorded(disclosure_id)` |

### Invariants

- **Invariant 1 — Record immutability.**
  ```
  Invariant 1.1: A stored disclosure record's field MUST NOT change.
  Invariant 1.2: The atom MUST NOT offer an action that changes a stored disclosure record.
  ```
- **Invariant 2 — Authority completeness.**
  ```
  Invariant 2.1: EVERY disclosure record's authority type MUST stand in the authority types.
  Invariant 2.2: EVERY disclosure record's authority reference MUST stand non-blank.
  ```
- **Invariant 3 — Field completeness.**
  ```
  Invariant 3.1: EVERY disclosure record MUST carry a disclosure instant.
  Invariant 3.2: EVERY disclosure record's subject reference, recipient, scope and authority reference MUST stand non-blank.
  ```
- **Invariant 4 — Temporal soundness.**
  ```
  Invariant 4.1: EVERY disclosure record's disclosure instant MUST NOT follow the now the record's creation read.
  ```
- **Invariant 5 — No disclosure unrecorded.**
  ```
  Invariant 5.1: EVERY transmission of a subject's data to a party beside the subject MUST produce a disclosure record.
  Invariant 5.2: The atom MUST NOT detect a transmission the atom's caller does not record.
  ```
- **Invariant 6 — Record durability and append-only nature.**
  ```
  Invariant 6.1: The atom MUST NOT remove a disclosure record from the database.
  Deleted: Invariant 6.2. Execution Contract Database 1 owns it.
  Deleted: Invariant 6.3. Execution Contract Database 3 owns it.
  ```

NOTE: open 2026-10-21-e — Invariant 5.1's subject is a transmission, and no rule names the party that records each one: Composition note 8 binds only a composing pattern that closes it, and External check 2 reads an egress record no rule requires.

---

## Examples

### Consent-authorized disclosure to a research partner

A hospital shares a de-identified summary with a research institution under a signed consent. Immediately after transmission the calling system records it: `record(subject_ref: "patient-88213", recipient: "Northgate Research Institute", scope: "medical-record:summary", authority: {type: consent, reference: "consent-3301"})` → `recorded("01HQ3M...")`, with the host injecting `now: 2026-03-04T14:02:11Z` and the fresh id at the seam. No disclosure instant was supplied, so the record carries the injected reading (Term resolved disclosure instant).

### Regulatory-mandate disclosure to a public health authority

A communicable-disease report goes to a state health department under a reporting statute: `record("patient-88213", "State Dept of Health — Epidemiology", "medical-record:communicable-disease-report", {type: regulatory, reference: "HIPAA §164.512(b) — public health reporting"}, disclosed_at: "2026-03-04T09:15:00Z")` → `recorded("01HQ3K...")`. The supplied instant precedes now, so it stands (Operation 7). Backdating to the moment of the actual transmission is the point — the record documents when the disclosure happened, not when it was keyed.

### Legal-Hold-compelled disclosure to an investigator

`record("patient-88213", "OIG Investigator R. Alvarez", "medical-record:billing-2025", {type: legal-hold, reference: "hold-2026-0142"})` → `recorded("01HQ4A...")`, with the host injecting `now: 2026-03-04T16:40:00Z`. The hold id is an opaque pointer; whether the hold was active is [Legal Hold](./legal-hold.md)'s record and not this atom's guard (Non-goal 9).

### The Article 15 answer

A data subject exercises their access right. `read({subject_ref: "patient-88213"})` answers three records in disclosure instant ascending order — the regulatory report first at 09:15, then the consent disclosure at 14:02, then the compelled one — each carrying its recipient, scope, authority type and authority reference. `read({subject_ref: "patient-88213", "authority.type": "consent"})` narrows to one. The regulatory question's answer is provable.

### Rejection paths

`record("", "Northgate Research Institute", "medical-record:summary", {type: consent, reference: "consent-3301"})` → invalid-request. An empty subject reference EQUALS blank (Operation 1, String 5).

`record("patient-88213", "Northgate", "summary", {type: "legitimate-interest", reference: "policy-7"})` → unknown-authority-type. The value stands outside the three (Operation 9). The same call with a blank scope answers invalid-request instead — the field-level checks complete first, so the caller learns the blank field before the bad type (Execution Contract Refusal 1).

`record("patient-88213", "Northgate", "summary", {type: consent, reference: "   "})` → invalid-request. A whitespace-only reference is blank, and a reference nobody can follow defeats the record's purpose (Operation 6).

`record(..., disclosed_at: "2027-01-01T00:00:00Z")` against `now: 2026-03-04` → invalid-request. Nothing is written (Operation 7, Operation 16).

`read({subject_ref: "patient-88213", "authority.reference": "consent-3301"})` → invalid-query. Reference-level filtering is not an axis this atom offers, and the key is refused rather than ignored (Operation 22, Non-goal 22).

`read({disclosed_at: {after: "2026-06-01", before: "2026-03-01"}})` → invalid-query (Operation 25).

`read({subject_ref: "patient-99999"})` → an empty record sequence. No disclosure of that subject's data has been recorded, which is itself the compliance answer (Operation 20).

### Regulated adversarial scenarios

- **Regulator audit.** A GDPR supervisory authority reviewing an Article 15 complaint asks which recipients received the complainant's data in 2026. `read({subject_ref: X, disclosed_at: {after: "2026-01-01", before: "2026-12-31"}})` answers the complete set in order, each with its authority. Invariant 3 is what makes the answer usable — every field on every record, so no entry has to be explained (Check 2.1, Check 2.2).
- **Disputed disclosure.** A data subject denies ever consenting to a research disclosure. The database yields the record and its `authority_reference: "consent-3301"`. That is where this atom's answer stops: it proves the calling system *claimed* that consent as the basis, and the [Consent](./consent.md) records are what prove the consent was granted, in scope and unrevoked at disclosure instant. The split is deliberate and it is named rather than hidden (External check 1, Non-goal 7).
- **Breach forensics.** An investigator reconstructing what left the system during an exposure window reads every disclosure record in the window and groups by recipient. The atom never removes a record (Invariant 6.1), and the database removes none except by an action a specification declares (Execution Contract Database 4), so a second read during a long investigation can only add records — nothing an earlier read showed can have quietly left, and a record a composed retention pattern purged in between left by a purge that pattern's own records show (External check 5). What the investigator cannot learn here is whether a transmission happened that nobody recorded; that is Invariant 5's gap, cleared against egress logs rather than against these records (External check 2).

---

## Generation acceptance

This atom's acceptance is provable: an external auditor clears it from the disclosure records.

### Conformance checks

```
Check 2.1: An auditor MUST find disclosure id, subject reference, recipient, scope, authority type, authority reference and disclosure instant on EVERY disclosure record (State 1, Invariant 3.1).
Check 2.2: An auditor MUST find EVERY disclosure record's subject reference, recipient, scope and authority reference non-blank (Invariant 3.2).
Check 2.3: An auditor MUST find EVERY disclosure record whose authority type IS IN the authority types (Invariant 2.1).
Check 3.1: An auditor MUST find a re-read disclosure record's fields unchanged from the prior read (Invariant 1.1).
Deleted: Check 3.2. Execution Contract Database 6 owns it.
Check 4.1: An auditor MUST find [Record] answering unknown-authority-type for an authority type that IS NOT IN the authority types (Operation 9).
Check 4.2: An auditor MUST find no disclosure record recorded by a refused [Record] (Operation 16).
Check 5.1: An auditor MUST find a subject reference query answering EVERY disclosure record carrying the subject reference (Operation 27).
Check 5.2: An auditor MUST find an authority type query answering ONLY the disclosure records carrying the authority type (Operation 28).
Check 5.3: An auditor MUST find an unmatched well-formed query answering an empty record sequence (Operation 20).
Check 6.1: An auditor MUST find [Record] answering invalid-request for a disclosure instant following now (Operation 7).
Deleted: Check 6.2. Check 6.1 owns it.
```

NOTE: EVERY check names the rule the check tests.

NOTE: open 2026-10-21-h — the Generation acceptance bar says an external auditor clears the atom from the disclosure records, and Check 4.1 and Check 6.1 find [Record]'s answers to calls, which no record carries.

### External checks

```
External check 1: A deployment needing a disclosure's authority legitimacy cleared MUST read the composing pattern's authority records (Non-goal 7, Non-goal 8).
External check 2: A deployment needing Invariant 5.1 cleared MUST read the egress record beside the disclosure records.
External check 3: A deployment needing a backdated disclosure instant detected MUST read the composing Event Log's receipt instant (State 10).
Deleted: External check 4. Execution Contract Database 3 owns it.
Deleted: External check 5. Execution Contract Database 6 owns it.
```

## Non-goals

```
Non-goal 1: The atom MUST NOT retrieve a subject's data.
Non-goal 2: The atom MUST NOT redact a subject's data.
Non-goal 3: The atom MUST NOT transmit a subject's data.
Non-goal 4: The atom MUST NOT confirm that a scope names what a transmission carried.
Non-goal 5: The atom MUST NOT bound a scope's vocabulary.
Non-goal 6: The atom MUST NOT bound a recipient's vocabulary.
Non-goal 7: The atom MUST NOT confirm that an authority reference names a live authority.
Non-goal 8: The atom MUST NOT confirm that an authority reference agrees with the authority type.
Non-goal 9: A deployment needing an authority's legitimacy confirmed MUST compose the authority's own pattern.
Non-goal 10: The atom MUST NOT decide who may call an action.
Non-goal 11: A deployment needing an authorization decision MUST compose Permissions.
Non-goal 12: The atom MUST NOT record who called [Record].
Non-goal 13: A deployment needing the recording actor bound MUST compose Actor Identity.
Non-goal 14: The atom MUST NOT read two [Record] calls carrying one field set as one disclosure.
Non-goal 15: A deployment needing at-most-once recording MUST compose Duplicate Prevention.
Non-goal 16: The atom MUST NOT detect a rewrite under the database.
Non-goal 17: A deployment needing a rewrite detected MUST compose Tamper Evidence.
Non-goal 18: The atom MUST NOT bound a disclosure record's retention.
Non-goal 19: A deployment needing a retention bound MUST compose Retention Window.
Non-goal 20: The atom MUST NOT decide whether a disclosure to the subject stands as a disclosure.
Non-goal 21: The atom MUST NOT bound disclosure instant from below.
Non-goal 22: The atom MUST NOT offer a filter axis over an authority reference.
Non-goal 23: A deployment needing a verifiable time anchor MUST compose a trusted timestamping pattern.
```

NOTE: the owners — the calling system (Non-goal 4, Non-goal 5, Non-goal 6); [Consent](./consent.md) and [Legal Hold](./legal-hold.md) (Non-goal 7, Non-goal 8, Non-goal 9); [Permissions](./permissions.md) (Non-goal 10, Non-goal 11); [Actor Identity](./actor-identity.md) (Non-goal 12, Non-goal 13); [Duplicate Prevention](./duplicate-prevention.md) (Non-goal 14, Non-goal 15); [Tamper Evidence](./tamper-evidence.md) (Non-goal 16, Non-goal 17); [Retention Window](./retention-window.md) (Non-goal 18, Non-goal 19); the compliance team, and [Resolve a Person's Data Rights](../compositions/resolve-a-persons-data-rights.md) for an access request (Non-goal 20).

---

## Edge cases

### Concurrency

```
Concurrency 1: The atom MUST NOT serialize two [Record] calls against one subject reference.
Concurrency 2: A [Record] call's answer MUST NOT rest on a concurrent [Record] call's answer.
Concurrency 3: The implementation MUST issue EXACTLY ONE disclosure id per admitted record.
```

### String policy

```
String 1: The atom MUST compare a string input byte-exactly.
String 2: The atom MUST NOT trim a string input.
String 3: The atom MUST NOT normalize a string input.
String 4: The atom MUST NOT case-fold a string input.
String 5: The atom MUST read a whitespace-only string input as blank.
String 6: The atom MUST read an absent string input as blank.
String 7: The deployment MUST canonicalize an opaque reference.
```

Term string input: subject reference, recipient, scope, authority reference OR a filter's value — every caller-supplied string this atom accepts.

NOTE: watch host obligations — this atom sets no maximum length on a string input, where [Duplicate Prevention](./duplicate-prevention.md) declares a cap and [Provenance](./provenance.md) obliges the deployment to set one. Three postures, and the *host obligations* docket row carries the count — a watch flag states the pressure, never a census nothing reads.

NOTE: open 2026-10-21-d — String 7's *an opaque reference* is a phrase no Term declares (Term subject reference alone calls itself one), so which string inputs the deployment canonicalizes is left to the reader.

### Correction by append

```
Correction 1: The atom MUST NOT edit a disclosure record.
Correction 2: The atom MUST NOT remove a disclosure record.
Correction 3: A caller correcting a disclosure record MUST call [Record] again.
Correction 4: A correcting disclosure record's correction narrative MUST name the corrected disclosure record.
```

Term correction narrative: the prose a correcting disclosure record's scope OR authority reference carries beside what the field names — the two fields that hold prose.

---

## Composition notes

```
Composition note 1: A deployment MUST declare which composing patterns the deployment wired in.
Composition note 2: A composing pattern MUST own the authorization of a call.
Composition note 3: A composing pattern MUST own the attestation binding the recording actor.
Composition note 4: A composing pattern MUST own the legitimacy of an authority reference.
Composition note 5: A composing pattern MUST own the tamper seal over the disclosure records.
Composition note 6: A composing pattern MUST own the retention of the disclosure records.
Composition note 7: A composing pattern MUST own at-most-once recording.
Composition note 8: A composing pattern closing Invariant 5.1 MUST own the only disclosure surface.
Composition note 9: A composing pattern reading the disclosure records MUST NOT write to the disclosure records.
```

WHY:
[Resolve a Person's Data Rights](../compositions/resolve-a-persons-data-rights.md) uses this atom in both directions: *read* to answer Article 15(1)(c)'s recipients limb, and *written* to record each fulfillment response as an accountable disclosure to the requester — which settles, for that case, the policy question Non-goal 20 leaves open.

NOTE: open 2026-10-05-a — read to the letter, Composition note 9 forbids a pattern that reads the disclosure records from writing to them at all, where Resolve a Person's Data Rights reads them and records through [Record].

NOTE: composing patterns — [Capability-Backed Sharing](../compositions/capability-backed-sharing.md), [Chain of Custody](../compositions/chain-of-custody.md), [Immutable Transaction Ledger](../compositions/immutable-transaction-ledger.md), [Resolve a Person's Data Rights](../compositions/resolve-a-persons-data-rights.md).

---

## Terms

Each `[Term]` marker above links to its term entry here; a term entry states what the concept *is* and its **Kind**.

### Vocabulary

Term actors: the atom; the host; the transition; the implementation; the deployment; a composing pattern; a business caller; a caller; a guard; an auditor; a regulator; a data subject; the database; a disclosure record; a stored disclosure record; a correcting disclosure record; a refused [Record]; a query; a filter; a transmission; a string input; an opaque reference.

Term records: disclosure record — one recorded disclosure, carrying disclosure id, subject reference, recipient, scope, authority type, authority reference and disclosure instant.

Term record verbs: identify, allocate, change, carry, stand, answer, record, resolve, take, stamp, leave, own, match, normalize, interpret, confirm, admit, offer, detect, route, share, precede, follow, exceed, compare, trim, case-fold, refuse, write, find, read, remove, edit, retract, order, bound, decide, compose, declare, wire, rest, apply, supply, serialize, issue, name, claim, transmit, redact, retrieve, canonicalize, persist, call, produce, evaluate.

Term value sets: authority type = consent | legal-hold | regulatory.

Term bounds: empty.

Term cadences: empty.

Term qualifiers: migrated — rewritten in GRACE lang v0.40 (2026-09-12).

Term terms: disclosure record, disclosure id, subject reference, recipient, scope, database instance, seam, transition, now, business caller, authority, authority type, authority types, authority reference, disclosure instant, resolved disclosure instant, filter axes, admitted record, string input, blank.

#### Record

The behavior that appends one immutable disclosure record: it takes the injected `id_t` as the record's [Disclosure Id], stores [Subject Reference], [Recipient], [Scope], [Authority] (both [Authority Type] and [Authority Reference]), and [Disclosure Instant] (the injected clock now if left blank; rejected [Invalid Request] if no instant or in the future), and returns `recorded(disclosure_id)`. Rejection priority: [Invalid Request] → [Unknown Authority Type] → [Storage Failure].

Kind: Operation

#### Read

The read-only query returning the matching disclosure records in [Disclosure Instant] then [Disclosure Id] ascending order, filtered by any of [Disclosure Id], [Subject Reference], [Recipient], [Authority Type], or a [Disclosure Instant] range. Never writes; an empty result is not a rejection. Rejected [Invalid Query] for a malformed filter.

Kind: Operation

#### Disclosure Id

The opaque, immutable identity of a disclosure record — the injected `id_t`, supplied at the I/O seam, fresh per call and never reused (Invariant 6). It is the record's identity; the other fields are properties.

Kind:       Field
Field of:   the disclosure record
Projection: disclosure_id

#### Subject Reference

The opaque reference to the data subject whose data was disclosed. Set on [Record], immutable, non-blank (Invariant 3); the same subject may appear in many records.

Kind:       Field
Field of:   the disclosure record
Projection: subject_ref

#### Recipient

The non-empty string naming the party the data was disclosed to. Set on [Record], immutable (Invariants 1 and 3); opaque and exact-match on [Read] (subject-recognizable naming is the calling system's obligation).

Kind:       Field
Field of:   the disclosure record
Projection: recipient

#### Scope

The non-empty string naming what subset of the subject's data was disclosed, as declared by the calling system. Set on [Record], immutable; opaque (subject-comprehensible vocabulary is the calling system's obligation).

Kind:       Field
Field of:   the disclosure record
Projection: scope

#### Authority

The structured field naming the legal basis for the disclosure — exactly two sub-fields, [Authority Type] and [Authority Reference]. Always present in structured form (Invariant 2). Set on [Record], immutable.

Kind:       Field
Field of:   the disclosure record
Projection: authority

#### Authority Type

The kind of authority — exactly consent, legal-hold, or regulatory (any other value is [Unknown Authority Type]). The machine-queryable half of [Authority]; the [Read] filter axis of the same name matches on it.

Kind:       Field
Field of:   the authority field
Projection: authority.type

#### Authority Reference

The opaque, non-blank string identifying the specific authority — a Consent id, a Legal Hold id, or a regulatory citation. The human-readable half of [Authority]; the atom validates its presence, not its legitimacy.

Kind:       Field
Field of:   the authority field
Projection: authority.reference

#### Disclosure Instant

The timestamp of the disclosure event. Set on [Record] or defaulted to the injected clock now; immutable. Must not be in the future relative to the injected now (Invariant 4); may be backdated. Best-effort — the wall clock, not this atom, bounds its honesty.

Kind:       Field
Field of:   the disclosure record
Projection: disclosed_at

#### Invalid Request

The rejection [Record] returns when [Subject Reference], [Recipient], [Scope], [Authority], [Authority Type] or [Authority Reference] is missing or whitespace-only, a supplied [Disclosure Instant] is no instant, or the resolved [Disclosure Instant] is in the future.

Kind:       Member
Member of:  the record rejection
Role:       Outcome
Projection: invalid-request

#### Unknown Authority Type

The rejection [Record] returns when [Authority Type] is not one of consent, legal-hold, or regulatory — checked after all field-level validation passes.

Kind:       Member
Member of:  the record rejection
Role:       Outcome
Projection: unknown-authority-type

#### Storage Failure

The rejection [Record] returns when the database write fails after all preconditions pass; guarantees no partial record was persisted (Operation 16).

Kind:       Member
Member of:  the record rejection
Role:       Outcome
Projection: storage-failure

#### Invalid Query

The rejection [Read] returns when a filter value is malformed — a null or whitespace [Disclosure Id], [Subject Reference], or [Recipient]; an [Authority Type] outside the three values; a reversed [Disclosure Instant] range, or one missing its after or its before; or an unrecognized filter key.

Kind:       Member
Member of:  the read rejection
Role:       Outcome
Projection: invalid-query

<!-- Term registry — shortcut-reference definitions. These produce no visible
     output; each resolves a [Term] marker to its term entry heading above (kramdown
     auto-generates the heading anchors on GitHub Pages). Standard CommonMark /
     kramdown; no plugin required. -->

[Record]: #record
[Read]: #read
[Disclosure Id]: #disclosure-id
[Subject Reference]: #subject-reference
[Recipient]: #recipient
[Scope]: #scope
[Authority]: #authority
[Authority Type]: #authority-type
[Authority Reference]: #authority-reference
[Disclosure Instant]: #disclosure-instant
[Invalid Request]: #invalid-request
[Unknown Authority Type]: #unknown-authority-type
[Storage Failure]: #storage-failure
[Invalid Query]: #invalid-query

---

## Standards references

- **GDPR Article 15(1)(c)** — the data subject's right of access includes the right to know the recipients or categories of recipients to whom their personal data has been or will be disclosed. Selective Disclosure is the accountability layer that makes Article 15(1)(c) responses provable. Every disclosure record's [Recipient] field and [Authority] field are the data the Article 15 response draws from.
- **GDPR Article 30 (Records of processing activities)** — controllers must maintain records of processing activities, including categories of recipients to whom personal data has been or will be disclosed, and transfers to third countries or international organizations. Disclosure records under this atom are the processing-activity records Article 30 requires for the disclosure category of processing.
- **HIPAA section 164.528 (Accounting of disclosures of protected health information)** — individuals have the right to receive an accounting of disclosures of their PHI (Protected Health Information — individually identifiable health data covered by HIPAA) made by a covered entity or business associate. The accounting must include the date of each disclosure, the name and address of the recipient, a brief description of the PHI disclosed, and a brief statement of the purpose. Each field maps directly: [Disclosure Instant] (date), [Recipient] (recipient name), [Scope] (description of PHI), [Authority Reference] (purpose statement). The atom is the structural implementation of section 164.528's accounting obligation.
- **SEC Rule 17a-4** — broker-dealers must preserve records in non-rewriteable, non-erasable format, accessible to regulators on demand. Disclosure records for broker-dealer records are themselves required records under 17a-4. Composing with Tamper Evidence satisfies the non-rewriteable, non-erasable standard; this atom provides the disclosure record structure.

---

## Status

`partially resolved` — see the Ledger.

## Ledger

```
status: partially resolved
formal: not applicable — vote no 2026-06-03
last gate: 2026-10-27 — Final Critique 7 — foundational count 2, not clean, no sample

open:
- 2026-10-05-a · refining · Composition note 9 · read to the letter it forbids a pattern that reads the disclosure records from writing to them at all, where the atom's own account of Resolve a Person's Data Rights has that composition read and record through the atom's surfaces → say no write beside [Record]; reported by that composition's gate
- 2026-10-21-d · refining · String 7 · the rule obliges the deployment to canonicalize an opaque reference, a phrase no Term declares (Term subject reference alone calls itself one), so which inputs it covers is left to the reader → name them
- 2026-10-21-e · refining · Invariant 5.1; Composition note 8; External check 2 · the invariant's subject is a transmission, and no rule names the party that records each one: Composition note 8 binds only a composing pattern that closes it, and External check 2 reads an egress record no rule requires → name the owner, as the owners NOTE names the calling system for Non-goal 4 through 6
- 2026-10-21-f · refining · State 1; Invariant 3.1; Term disclosure instant; Term resolved disclosure instant · one proposition stated twice: State 1 and Invariant 3.1 both require a disclosure instant on every record, and Term disclosure instant's never later than now restates Invariant 4.1 beside a second Term for the instant the record carries → one owner each
- 2026-10-21-g · refining · Identity 6; Term database instance · the rule reads as each call routed to one instance or as every call routed to the same instance, and under the first a subject reference query answers only its own instance's records → say which
- 2026-10-21-h · refining · Generation acceptance; Check 4.1; Check 6.1 · the bar says an external auditor clears the atom from the disclosure records, and Check 4.1 and Check 6.1 find [Record]'s answers to calls, which no record carries → say where those checks run
- 2026-10-27-a · refining · Term seam; Term transition; Term now; Term business caller · each says the section titled Logic Confinement Principle in `execution-contract.md` declares it, and that section declares none of them, as Assignment 2026-10-21-a, Permissions 2026-10-21-f and Event Log 2026-10-20-c record of their own → declare each here, or cite where each is declared
```

## Decisions

Directional changes only — the turns a future reader must know the pattern took, and why. Everything smaller lives in the commit that made it: `git log -- atoms/selective-disclosure.md`; the migration and the repairs that got it here are in [its history](./selective-disclosure.hist.md).

- **2026-10-19 — The store's guarantees cited, not restated.** *Chose:* the disclosure store supplied under Execution Contract Store 1, Store 3 and Store 4 (Capability requirement 5), and the three rules that restated them, or stood in for them, tombstoned to their owner — Invariant 6.2, no partial record left by a storage-failure, to Store 1; Invariant 6.3, an answered disclosure id naming a durably persisted record, and External check 4, the recorded answers captured to find an issued disclosure id the store is missing, to Store 3; rules 130 to 128. *Over:* the atom restating, for its own store, what every deployment's store guarantees, and a deployment capturing its record answers against a store that might lose a disclosure. *Because:* the maintainer ruled 2026-10-12 that the corpus takes a store's specification, never the store, and `execution-contract.md` writes it once as the Store contract. The atom's own no-removal rules stay (State 5, State 8, State 9, Invariant 6.1), since Store 4 alone does not keep the atom from removing a record or the count from falling; a refused [Record] still records nothing and leaves the store as the call found the store, guard refusals included (Operation 16, Operation 17). [Record]'s guards read no store state and each record is written once under a fresh host-allocated id, so the atom cites no Store 2; Check 3.1 and Check 3.2 rest on the auditor's own two reads, and [Read] orders by disclosure instant and disclosure id, so the atom cites neither History 1 nor Order 1. What the atom does for its domain is unchanged.

- **2026-10-21 — A composed retention may purge what the atom never removes; [Record]'s refusals answer in one stated order.** *Chose:* State 8 and State 9, which held the record count and every unfiltered read's records for good, tombstoned to the rules that hold what is true — the atom removes no record (Invariant 6.1), the database removes none but by an action a specification declares (Execution Contract Database 4), and an unfiltered read answers what the database holds (Operation 21); Check 3.2 moved to External check 5, which reads the composing pattern's purge records beside two reads; Check 6.2 tombstoned to Check 6.1, which tests the guard that keeps Invariant 4.1; and one record refusal order over [Record]'s guard refusals (Operation 35), with Operation 8 and Operation 15 kept as its pairs. *Over:* a record count that may never fall beside Non-goal 19, which sends a deployment needing a retention bound to Retention Window, whose purge destroys the record, so a conforming deployment broke State 8 and State 9 and failed Check 3.2 at its first purge; a check comparing each record with a creation instant no record carries; and pairwise ONLY IF rules, Operation 8 read alone forbidding what Operation 9 obliges on a call carrying a blank field and an unknown type. *Because:* Final Critique 6 found each two rules no build could both obey, or a check a conforming deployment fails or a violating one passes; Final Critique 5's text already put the purge with Retention Window (*when (if ever) they may be purged — is a composing Retention Window concept*), so the method's entry of 2026-10-08 tombstones the broken rules to the rules that hold the lawful states rather than qualifying them, and Approval Step's sixth round gave the refusal order its form. What the atom does for its domain is unchanged: it records and reads as it did, refuses the same calls with the same codes, and never removes a record.

- **2026-10-21 — Which refusal answers is the Execution Contract's.** *Chose:* [Record]'s refuses line kept as the page wrote it, already in the order the record refusal order gave — invalid-request, unknown-authority-type, then storage-failure, which answers only at the write — and the order cited from the Execution Contract (Capability requirement 5, Execution Contract Refusal 1); the rules that only stated it deleted to Refusal 1: Operation 35, which evaluated the record refusal order, with Term record refusal order, and the pairs Operation 8 (unknown-authority-type only once every field-level precondition passes) and Operation 15 (storage-failure only once they pass and the authority type is known), with Term field-level precondition, which only those pairs read; rules 126 to 123. *Over:* the page stating for itself which of [Record]'s refusals answers when several apply. *Because:* the maintainer ruled on 2026-10-21 that the Execution Contract states once that the refusal listed first on an action's refuses line answers; this page's sixth Final Critique had made the cure one specification at a time. What each action answers on every call is unchanged.

- **2026-10-22 — A composed purge is answered by the purging pattern's records, as the Execution Contract says.** *Chose:* External check 5, a composing pattern's purge records read beside two unfiltered reads of the disclosure records, deleted to Execution Contract Database 6, with Check 3.2's tombstone, which named it, now naming the contract, and the label cited on Capability requirement 5; the atom's own no-removal rules stand as written and bind its own actions; rules 123 to 122. *Over:* the page stating for itself that a purge another specification declares is answered outside the disclosure records. *Because:* the maintainer ruled on 2026-10-22 that five repeated cures are each stated once, the composed erasure among them; this page's sixth Final Critique had made the cure first, one specification at a time. What each action does and answers is unchanged.

NOTE: End of Selective Disclosure.
