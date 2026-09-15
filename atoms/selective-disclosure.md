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

Once written, a record can never be changed or deleted, and nothing is ever removed from the store — which is precisely what guarantees the sharing history is complete and cannot be quietly altered. The records can be queried by subject, recipient, authority type, or date, producing the disclosure accounting that privacy and securities regulations demand.

A few questions need other patterns to answer — whether a referenced consent was actually valid at the time, whether every disclosure was in fact logged, and whether a backdated timestamp is honest — and those boundaries are spelled out in the Generation acceptance section.

*Also known as: a disclosure log, an accounting of disclosures, a data-sharing register.*

---

## Intent

WHY:
Regulated systems handling personal data, financial records or protected health information must keep a complete and durable account of every disclosure made — what was shared, with whom, under what legal authority, and when. A GDPR (EU General Data Protection Regulation) supervisory authority conducting an Article 15 review asks what was disclosed to which recipients. An HHS OCR (Office for Civil Rights) inspector validating HIPAA (US Health Insurance Portability and Accountability Act) compliance asks for the accounting of disclosures §164.528 requires. An SEC (Securities and Exchange Commission) examiner reviewing broker-dealer records asks for the disclosure trail Rule 17a-4 mandates. The obligation is the same across all three: answer from the records alone, without developer testimony, log reconstruction or institutional memory.

This atom is the accountability layer that makes those answers possible, and the line it holds is between *recording* and *performing*. An atom that also performed disclosures — retrieving subject data, applying redaction, routing to recipients — would absorb concepts from storage layers, redaction engines and notification systems, each with its own state, its own invariants and its own composing pattern. Absorbing them destroys freestanding status and produces a spec that cannot be composed independently of the technologies it would have to name. The atom specifies the accountability obligation; the implementation specifies the mechanics of delivery.

Four adjacent concepts are distinguished, and every distinction is load-bearing. [Audit Trail](../compositions/audit-trail.md) answers *what happened in this system* for any action, any actor, any subject; this atom answers *what was disclosed about this subject, to whom, under what authority* for one class of event. [Consent](./consent.md) governs authorization — *may I?* — and is a precondition check; this atom records *I did*, after the fact, whether the basis was consent, compulsion or regulation. [Legal Hold](./legal-hold.md) governs compelled *preservation*; this atom records compelled *disclosure*, and the two address opposite obligations on the same records. [Actor Identity](./actor-identity.md) answers *who authorized an action*; this atom answers *to whom was subject data disclosed*. Both carry attribution fields and they are different kinds of attribution — a disclosure to a regulator names the regulator here and may name the authorizing compliance officer in a composing attestation.

The authority field is where the atom earns its name. Three types and no others — `consent`, `legal-hold`, `regulatory` — cover the complete space of legitimate disclosure bases: data-subject authorization, legal compulsion, regulatory mandate. Refusing a fourth value is a structural claim, not a validation convenience: a disclosure falling outside those three is not a legitimate disclosure, and the store must not be able to say otherwise. Splitting the field into a machine-queryable type and a human-readable reference is what keeps the accounting both filterable and readable by the regulator who has to act on it.

## Structure

### Identity model

```text
Identity 1: The atom MUST identify a disclosure record by the disclosure_id.
Identity 2: The host MUST allocate a disclosure_id at the seam.
Identity 3: The transition MUST NOT allocate a disclosure_id.
Identity 4: The atom MUST NOT change a disclosure_id.
Identity 5: Two disclosure records in one store instance MUST NOT share a disclosure_id.
Identity 6: The deployment MUST route EVERY call to one store instance.
Identity 7: The atom MUST NOT identify a disclosure record by the subject_ref.
Identity 8: The atom MUST admit a second disclosure record carrying a recorded subject_ref.
Identity 9: The atom MUST match a subject_ref exactly.
Identity 10: The atom MUST match a recipient exactly.
Identity 11: The atom MUST NOT normalize a subject_ref.
Identity 12: The atom MUST NOT confirm that a subject_ref names a known subject.
Identity 13: The atom MUST NOT interpret a scope.
Identity 14: The atom MUST NOT interpret a recipient.
Identity 15: The deployment MUST choose a disclosure_id format that sorts in lexicographic byte order.
```

Terms › `disclosure record`: one recorded disclosure of one subject's data to one recipient under one authority — the record this atom holds.

Terms › `disclosure_id`: the opaque value naming one disclosure record — a [Disclosure Id]; host-allocated at the seam, fresh per call by the seam's construction.

Terms › `subject_ref`: the opaque reference naming the data subject whose data was disclosed — a [Subject Ref]; a property of the record, never the record's identity.

Terms › `recipient`: the opaque string naming the party the data reached — a [Recipient].

Terms › `scope`: the opaque string naming what subset of the subject's data was disclosed — a [Scope]; recorded as the caller declares it.

Terms › `store instance`: one named disclosure store a call is routed to; `disclosure_id` uniqueness ranges over one instance.

Terms › `seam`: the atom's I/O boundary as `execution-contract.md` §Logic confinement declares it; the host injects the clock reading and the disclosure_id here.

Terms › `transition`: the atom's evaluation of one call against the disclosure store, as `execution-contract.md` §Logic confinement declares it.

WHY:
The id is the injected `id_t`, fresh by construction at the seam, which is what makes Identity 5 hold at the action level without the transition owning a generator or a collision path. Lexicographic sortability (Identity 15) is not cosmetic: it is the stable tiebreaker [Read]'s total order rests on, so a deployment choosing an unsortable id format breaks the read contract rather than merely the aesthetics — ULID, UUID v7 and a zero-padded integer string all satisfy it.

`subject_ref` is deliberately not an identity (Identity 7, Identity 8). One subject has many disclosures; each is its own accountability record, and collapsing them under a subject key would make the store answer *what is true of this subject* rather than *what happened to this subject's data*, which is the question the regulation asks.

### Operations

```
record(subject_ref, recipient, scope, authority, disclosed_at?)
  → recorded(disclosure_id)
  | rejected(invalid-request | unknown-authority-type | storage-failure)

read(filters)
  → the matching disclosure records
  | rejected(invalid-query)
```

```text
Operation 1: IF subject_ref NOT EXISTS THEN [Record] MUST answer invalid-request.
Operation 2: IF recipient NOT EXISTS THEN [Record] MUST answer invalid-request.
Operation 3: IF scope NOT EXISTS THEN [Record] MUST answer invalid-request.
Operation 4: IF authority NOT EXISTS THEN [Record] MUST answer invalid-request.
Operation 5: IF authority_type NOT EXISTS THEN [Record] MUST answer invalid-request.
Operation 6: IF authority_reference NOT EXISTS THEN [Record] MUST answer invalid-request.
Operation 7: IF the resolved disclosed_at EXCEEDS now THEN [Record] MUST answer invalid-request.
Operation 8: [Record] MUST answer unknown-authority-type ONLY IF EVERY field-level precondition passes.
Operation 9: IF authority_type NOT EXISTS in the authority types THEN [Record] MUST answer unknown-authority-type.
Operation 10: An admitted record MUST record EXACTLY ONE disclosure record.
Operation 11: An admitted record MUST take the disclosure record's disclosure_id from the injected disclosure_id.
Operation 12: An admitted record MUST stamp the disclosure record's disclosed_at from the resolved disclosed_at.
Operation 13: An admitted record MUST answer the disclosure_id.
Operation 14: IF the store refuses the write THEN [Record] MUST answer storage-failure.
Operation 15: [Record] MUST answer storage-failure ONLY IF EVERY precondition passes.
Operation 16: A refused [Record] MUST NOT record a disclosure record.
Operation 17: A refused [Record] MUST leave the store as the call found the store.
Operation 18: An admitted read MUST answer the matching disclosure records in disclosed_at ascending order.
Operation 19: An admitted read MUST order two disclosure records sharing a disclosed_at by disclosure_id ascending.
Operation 20: IF no disclosure record matches THEN an admitted read MUST answer an empty record sequence.
Operation 21: An admitted read carrying no filter MUST answer EVERY disclosure record in the store instance.
Operation 22: IF a filter's axis NOT EXISTS in the filter axes THEN [Read] MUST answer invalid-query.
Operation 23: IF a disclosure_id, subject_ref OR recipient filter's value NOT EXISTS THEN [Read] MUST answer invalid-query.
Operation 24: IF an authority_type filter's value NOT EXISTS in the authority types THEN [Read] MUST answer invalid-query.
Operation 25: IF a disclosed_at range's before precedes the range's after THEN [Read] MUST answer invalid-query.
Operation 26: An admitted read MUST match a disclosed_at range as a closed interval.
Operation 27: An admitted read MUST answer EVERY disclosure record matching the supplied filters.
Operation 28: An admitted read MUST NOT answer a disclosure record failing a supplied filter.
Operation 29: [Read] MUST NOT write.
Operation 30: [Read] MUST NOT answer storage-failure.
NOTE: Operation 31 deleted — Capability requirement 1 owns it.
Operation 32: The transition MUST NOT read a clock.
Operation 33: The business caller MUST NOT supply now.
Operation 34: A guard MUST NOT read a clock.
```

Terms › `now`: the wall-time reading the host takes at the seam and hands to the transition, as `execution-contract.md` §Logic confinement declares it; never read inside the transition, never supplied by the business caller.

Terms › `business caller`: the party whose action the call carries, as `execution-contract.md` §Logic confinement declares it; never the source of an injected value.

Terms › `authority`: the structured field naming the basis the disclosure was made under — an [Authority]; carries `authority_type` and `authority_reference` and nothing else.

Terms › `authority_type`: `consent` | `legal-hold` | `regulatory` — an [Authority Type], set at record and never changed.

Terms › `authority types`: the three members of `authority_type`, cited here from that declaration (Closed vocabulary 15).

Terms › `authority_reference`: the opaque string naming the specific authority — an [Authority Reference]; a consent record's id, a legal hold's id, or a regulatory citation.

Terms › `disclosed_at`: the instant the disclosure happened — a [Disclosed At]; caller-supplied or resolved to `now`, and never later than `now`.

Terms › `resolved disclosed_at`: the `disclosed_at` the record carries — the supplied value where one exists, and `now` otherwise.

Terms › `field-level precondition`: Operation 1 through Operation 7 — every check [Record] makes before the authority type is read.

Terms › `filter axes`: `disclosure_id` | `subject_ref` | `recipient` | `authority_type` | `disclosed_at` — the five axes [Read] accepts, and no others.

Terms › `admitted record`: a [Record] call whose fields, resolved disclosed_at and authority_type the guards all admit.

Terms › `admitted read`: a [Read] call whose every filter axis and filter value the guards admit.

| # | Condition | [Record] answers |
|---|---|---|
| 1 | a field is blank, or the resolved disclosed_at follows now | `invalid-request` |
| 2 | every field passes, authority_type stands outside the authority types | `unknown-authority-type` |
| 3 | every precondition passes, the store refuses the write | `storage-failure` |
| 4 | every precondition passes, the store accepts the write | `recorded(disclosure_id)` |

WHY:
Operation 8 is the precedence rule, and it is load-bearing rather than tidy. Without it a call carrying both a blank `subject_ref` and a misspelled authority type could answer either way, and a caller repairing the authority type would then discover the blank field on the next attempt — two round trips to learn what one answer already knew. The same shape governs Operation 15: `storage-failure` means *the call was good and the store was not*, so landing it while a precondition is unchecked would tell the caller to retry something that will never succeed.

Operation 7 is the atom's one genuine execution-time validation — the residual the logic-confinement discipline marks rather than derives away. A disclosure cannot be recorded as having happened later than the moment of recording, and that determination can only be made against the injected reading. The guard is a pure function of the resolved `disclosed_at` and `now`, and it writes nothing when it fails.

Operation 22 refuses an unrecognized filter key rather than ignoring it, which is the difference between an answer and a coincidence: a silently ignored key returns a result set that does not match what the caller asked, and a compliance answer no one can trust the shape of is worse than a rejection. Operation 20 draws the opposite line on the same surface — a well-formed query matching nothing is a meaningful answer (*no disclosures of this kind were recorded*), not a failure.

### State

```text
State 1: EVERY disclosure record MUST carry disclosure_id, subject_ref, recipient, scope, authority_type, authority_reference and disclosed_at.
State 2: The atom MUST NOT offer a state machine over a disclosure record.
State 3: The atom MUST NOT offer an optional field on a disclosure record.
State 4: The atom MUST NOT offer an edit surface.
State 5: The atom MUST NOT offer a removal surface.
State 6: The atom MUST NOT offer a retraction surface.
State 7: The atom MUST NOT offer a batch record surface.
State 8: The store instance's record count MUST NOT fall.
State 9: A later unfiltered [Read] MUST answer EVERY disclosure record an earlier unfiltered [Read] answered.
```

WHY:
A disclosure record has no lifecycle (State 2). It is categorically unlike the state-machine atoms — [Legal Hold](./legal-hold.md)'s active and released, [Approval Step](./approval-step.md)'s pending, approved, rejected and withdrawn — because a disclosure simply *is*, from the moment it is recorded. There is no transition to model and therefore no transition to get wrong, and the store's only state is the growing set.

State 3 is what makes the accounting answerable in one pass. Every field is on every record, so an auditor never has to ask whether an absent value means *not applicable* or *not captured* — a distinction no store can make after the fact.

### Invariants

- **Invariant 1 — Record immutability.**
  ```text
  Invariant 1.1: A stored disclosure record's field MUST NOT change.
  Invariant 1.2: The atom MUST NOT offer an action that changes a stored disclosure record.
  ```
- **Invariant 2 — Authority completeness.**
  ```text
  Invariant 2.1: EVERY disclosure record's authority_type MUST stand in the authority types.
  Invariant 2.2: EVERY disclosure record's authority_reference MUST carry a non-whitespace character.
  ```
  WHY: a record failing either arm cannot answer *under what authority was this disclosure made*, which is the one question the atom exists to answer. An unrecognized type or an empty reference is a conformance failure rather than a degraded record, because a disclosure accounting that cannot name its basis is not an accounting.
- **Invariant 3 — Field completeness.**
  ```text
  Invariant 3.1: EVERY disclosure record MUST carry a disclosed_at.
  Invariant 3.2: EVERY disclosure record's subject_ref, recipient, scope and authority_reference MUST carry a non-whitespace character.
  ```
- **Invariant 4 — Temporal soundness.**
  ```text
  Invariant 4.1: EVERY disclosure record's disclosed_at MUST NOT follow the now the record's creation read.
  ```
  WHY: a record whose `disclosed_at` is later than the instant it was written claims the system recorded a disclosure that had not happened yet. The constraint is enforced against the resolved value — caller-supplied or defaulted — by Operation 7's guard, before the write.
- **Invariant 5 — No disclosure unrecorded.**
  ```text
  Invariant 5.1: EVERY transmission of a subject's data to a party beside the subject MUST produce a disclosure record.
  Invariant 5.2: The atom MUST NOT detect a transmission the atom's caller does not record.
  ```
  WHY: the atom's whole accountability purpose rests on this invariant and the atom cannot enforce it, which is why Invariant 5.2 states the limit plainly rather than leaving it to be discovered. The atom records when called and cannot intercept a disclosure that happens without a call. It is a calling-system obligation, cleared by External check 2 and structurally closed only by a composing pattern that makes its own disclosure surface the only one — which [Immutable Transaction Ledger](../compositions/immutable-transaction-ledger.md) does.
- **Invariant 6 — Store durability and append-only nature.**
  ```text
  Invariant 6.1: The atom MUST NOT remove a disclosure record from the store.
  Invariant 6.2: A storage-failure rejection MUST leave no partial record in the store.
  Invariant 6.3: An answered disclosure_id MUST name a durably persisted disclosure record.
  ```
  WHY: append-only is the structural guarantee that a subject's disclosure history is complete from the records alone. A deletion or an edit would break that guarantee in a way no auditor could detect from the store — which is exactly the gap [Tamper Evidence](./tamper-evidence.md) closes cryptographically and this atom closes only by specification.

---
## Examples

### Consent-authorized disclosure to a research partner

A hospital shares a de-identified summary with a research institution under a signed consent. Immediately after transmission the calling system records it: `record(subject_ref: "patient-88213", recipient: "Northgate Research Institute", scope: "medical-record:summary", authority: {type: consent, reference: "consent-3301"})` → `recorded("01HQ3M...")`, with the host injecting `now: 2026-03-04T14:02:11Z` and the fresh id at the seam. No `disclosed_at` was supplied, so the record carries the injected reading (Terms › `resolved disclosed_at`).

### Regulatory-mandate disclosure to a public health authority

A communicable-disease report goes to a state health department under a reporting statute: `record("patient-88213", "State Dept of Health — Epidemiology", "medical-record:communicable-disease-report", {type: regulatory, reference: "HIPAA §164.512(b) — public health reporting"}, disclosed_at: "2026-03-04T09:15:00Z")` → `recorded("01HQ3K...")`. The supplied instant precedes `now`, so it stands (Operation 7). Backdating to the moment of the actual transmission is the point — the record documents when the disclosure happened, not when it was keyed.

### Legal-Hold-compelled disclosure to an investigator

`record("patient-88213", "OIG Investigator R. Alvarez", "medical-record:billing-2025", {type: legal-hold, reference: "hold-2026-0142"})` → `recorded("01HQ4A...")`. The hold id is an opaque pointer; whether the hold was active is [Legal Hold](./legal-hold.md)'s record and not this atom's guard (Non-goal 9).

### The Article 15 answer

A data subject exercises their access right. `read({subject_ref: "patient-88213"})` answers three records in `disclosed_at` ascending order — the regulatory report first at 09:15, then the consent disclosure at 14:02, then the compelled one — each carrying its recipient, scope, authority type and authority reference. `read({subject_ref: "patient-88213", authority_type: "consent"})` narrows to one. The regulatory question is answered from the store alone.

### Rejection paths

`record("", "Northgate Research Institute", "medical-record:summary", {type: consent, reference: "consent-3301"})` → `rejected(invalid-request)`. A blank `subject_ref` NOT EXISTS (Operation 1, String 5).

`record("patient-88213", "Northgate", "summary", {type: "legitimate-interest", reference: "policy-7"})` → `rejected(unknown-authority-type)`. The value stands outside the three (Operation 9). The same call with a blank `scope` answers `invalid-request` instead — the field-level checks complete first, so the caller learns the blank field before the bad type (Operation 8).

`record("patient-88213", "Northgate", "summary", {type: consent, reference: "   "})` → `rejected(invalid-request)`. A whitespace-only reference is blank, and a reference nobody can follow defeats the record's purpose (Operation 6).

`record(..., disclosed_at: "2027-01-01T00:00:00Z")` against `now: 2026-03-04` → `rejected(invalid-request)`. Nothing is written (Operation 7, Operation 16).

`read({subject_ref: "patient-88213", authority_reference: "consent-3301"})` → `rejected(invalid-query)`. Reference-level filtering is not an axis this atom offers, and the key is refused rather than ignored (Operation 22, Non-goal 22).

`read({disclosed_at: {after: "2026-06-01", before: "2026-03-01"}})` → `rejected(invalid-query)` (Operation 25).

`read({subject_ref: "patient-99999"})` → an empty record sequence. No disclosure of that subject's data has been recorded, which is itself the compliance answer (Operation 20).

### Regulated adversarial scenarios

- **Regulator audit.** A GDPR supervisory authority reviewing an Article 15 complaint asks which recipients received the complainant's data in 2026. `read({subject_ref: X, disclosed_at: {after: "2026-01-01", before: "2026-12-31"}})` answers the complete set in order, each with its authority. Invariant 3 is what makes the answer usable — every field on every record, so no entry has to be explained (Check 2.1, Check 2.2).
- **Disputed disclosure.** A data subject denies ever consenting to a research disclosure. The store yields the record and its `authority_reference: "consent-3301"`. That is where this atom's answer stops: it proves the calling system *claimed* that consent as the basis, and the [Consent](./consent.md) store is what proves the consent was granted, in scope and unrevoked at `disclosed_at`. The split is deliberate and it is named rather than hidden (External check 1, Non-goal 7).
- **Breach forensics.** An investigator reconstructing what left the system during an exposure window reads the store unfiltered across the window and groups by recipient. The store is monotonic (State 8, State 9), so a second read during a long investigation can only add records — nothing an earlier read showed can have quietly left. What the investigator cannot learn here is whether a transmission happened that nobody recorded; that is Invariant 5's gap, cleared against egress logs rather than against this store (External check 2).

---

## Generation acceptance

This atom's acceptance is what an external auditor can clear from the disclosure store alone, with no recourse to source code, runbooks or developer narration.

### Conformance checks

```text
Check 2.1: An auditor MUST find disclosure_id, subject_ref, recipient, scope, authority_type, authority_reference and disclosed_at on EVERY disclosure record (State 1, Invariant 3.1).
Check 2.2: An auditor MUST find a non-whitespace character in EVERY disclosure record's subject_ref, recipient, scope and authority_reference (Invariant 3.2).
Check 2.3: An auditor MUST find EVERY disclosure record's authority_type standing in the authority types (Invariant 2.1).
Check 3.1: An auditor MUST find a re-read disclosure record's fields unchanged from the prior read (Invariant 1.1).
Check 3.2: An auditor MUST find no disclosure record absent from a later unfiltered read (Invariant 6.1, State 9).
Check 4.1: An auditor MUST find [Record] answering unknown-authority-type for an authority_type standing outside the authority types (Operation 9).
Check 4.2: An auditor MUST find no disclosure record recorded by a refused [Record] (Operation 16).
Check 5.1: An auditor MUST find a subject_ref query answering EVERY disclosure record carrying the subject_ref (Operation 27).
Check 5.2: An auditor MUST find an authority_type query answering ONLY the disclosure records carrying the authority_type (Operation 28).
Check 5.3: An auditor MUST find an unmatched well-formed query answering an empty record sequence (Operation 20).
Check 6.1: An auditor MUST find [Record] answering invalid-request for a disclosed_at following now (Operation 7).
Check 6.2: An auditor MUST find no disclosure record's disclosed_at following the record's creation instant (Invariant 4.1).
```

NOTE: EVERY check names the rule the check tests.

### External checks

```text
External check 1: A deployment needing a disclosure's authority legitimacy cleared MUST read the composing authority store (Non-goal 7, Non-goal 8).
External check 2: A deployment needing Invariant 5.1 cleared MUST read the egress record beside the disclosure store.
External check 3: A deployment needing a backdated disclosed_at detected MUST read the composing [Event Log](./event-log.md)'s receipt instant (Clock semantics 4).
External check 4: A deployment needing EVERY issued disclosure_id found in the store MUST capture the recorded answers (Invariant 6.3).
```

WHY:
External check 4 is a check that left the conformance list. Finding every issued `disclosure_id` needs the ids, and only a test or audit environment capturing the `recorded` answers can enumerate them — a production auditor reading the store cannot, because the store is exactly what would be missing one. The store-alone assurance comes from the other direction through Check 3.2: no record present at an earlier read has since vanished. This is the split council read 22 forced on Capability, applied before a reader had to force it.

The three external checks are the audit boundary stated rather than left to be discovered, and each names where the question goes. Authority *legitimacy* is unclearable here by construction: a record carrying `{type: consent, reference: "consent-3301"}` proves the calling system claimed that consent, and whether the consent was granted, in scope and unrevoked at `disclosed_at` lives in [Consent](./consent.md)'s store — as does semantic agreement between the type and the reference, which this atom cannot judge on an opaque string. Invariant 5.1 is unclearable from inside because a gap is invisible to a query that sees only what was recorded; the store is the positive evidence and the negative evidence lives at the egress boundary. Backdating is unclearable because the atom stores the declared instant and no separate creation instant; the composing [Event Log](./event-log.md) entry carries the receipt instant, and a `disclosed_at` materially earlier than it is the audit signal. [Audit Trail](../compositions/audit-trail.md) is where that comparison is surfaced.

---

### Capability requirements

```text
Capability requirement 1: The deployment MUST supply now at the seam.
```

WHY:
What the deployment supplies, which is what the family means. The rule stood under `Operation` — one action's rules — while naming no action, because this spec was migrated before the standard family had a home in an atom; the five atoms migrated a day later put the same obligation here. The words are the words the rule carried (council read 76).

## Non-goals

```text
Non-goal 1: The atom MUST NOT retrieve a subject's data.
Non-goal 2: The atom MUST NOT redact a subject's data.
Non-goal 3: The atom MUST NOT transmit a subject's data.
Non-goal 4: The atom MUST NOT confirm that a scope names what a transmission carried.
Non-goal 5: The atom MUST NOT bound a scope's vocabulary.
Non-goal 6: The atom MUST NOT bound a recipient's vocabulary.
Non-goal 7: The atom MUST NOT confirm that an authority_reference names a live authority.
Non-goal 8: The atom MUST NOT confirm that an authority_reference agrees with the authority_type.
Non-goal 9: A deployment needing an authority's legitimacy confirmed MUST compose the authority's own pattern.
Non-goal 10: The atom MUST NOT decide who may call an action.
Non-goal 11: A deployment needing an authorization decision MUST compose [Permissions](./permissions.md).
Non-goal 12: The atom MUST NOT record who called [Record].
Non-goal 13: A deployment needing the recording actor bound MUST compose [Actor Identity](./actor-identity.md).
Non-goal 14: The atom MUST NOT read two [Record] calls carrying one field set as one disclosure.
Non-goal 15: A deployment needing at-most-once recording MUST compose [Duplicate Prevention](./duplicate-prevention.md).
Non-goal 16: The atom MUST NOT detect a rewrite under the store.
Non-goal 17: A deployment needing a rewrite detected MUST compose [Tamper Evidence](./tamper-evidence.md).
Non-goal 18: The atom MUST NOT bound a disclosure record's retention.
Non-goal 19: A deployment needing a retention bound MUST compose [Retention Window](./retention-window.md).
Non-goal 20: The atom MUST NOT decide whether a disclosure to the subject stands as a disclosure.
Non-goal 21: The atom MUST NOT bound disclosed_at from below.
Non-goal 22: The atom MUST NOT offer a filter axis over an authority_reference.
```

WHY:
Non-goal 4 is the one a reader most often mistakes for a defect. The `scope` is the calling system's declaration of what it shared, and the atom records it without checking it — a system recording `scope: "contact-fields-only"` while transmitting a full medical record has produced an inaccurate disclosure record, and that is a calling-system failure the atom cannot see. What the atom guarantees is that the declaration is durable, attributed to a subject and a recipient, and impossible to revise later.

Non-goal 5 and Non-goal 6 are where a structurally valid record can still fail the regulation. GDPR Article 15(1)(c) requires the recipients and the categories of data to be named in terms the data subject can act on; `scope: "tbl_disc_oncology_42"` and `recipient: "partner-AV7"` satisfy every rule here and satisfy no data subject. Choosing a vocabulary the regulatory audience can read is the calling system's obligation, and an auditor cannot clear it from the records without knowing that vocabulary.

Non-goal 20 leaves a live policy question open rather than settling it. An Article 15 response is itself a transmission of the subject's data — to the subject — and whether it belongs in the accounting is a regulatory interpretation the compliance team makes. [Resolve a Person's Data Rights](../compositions/resolve-a-persons-data-rights.md) settles it for the access-request case by recording the response as an accountable disclosure to the requester; outside that composition it stays open.

Non-goal 21 is deliberate asymmetry. `disclosed_at` is bounded above because a future disclosure has not happened, and unbounded below because a disclosure recognized long after the fact — a breach discovered in an audit, a transmission found in a log review — is exactly the case the accounting must be able to capture.

---

## Edge cases

### String policy

```text
String 1: The atom MUST compare a string input byte-exactly.
String 2: The atom MUST NOT trim a string input.
String 3: The atom MUST NOT normalize a string input.
String 4: The atom MUST NOT case-fold a string input.
String 5: The atom MUST read a whitespace-only string input as blank.
String 6: The atom MUST read an absent string input as blank.
String 7: The deployment MUST canonicalize an opaque reference.
```

Terms › `string input`: `subject_ref`, `recipient`, `scope`, `authority_reference` OR a filter's value — every caller-supplied string this atom accepts.

Terms › `blank`: a value that is absent, empty, or carries only whitespace — what every presence check in this atom refuses; a blank argument NOT EXISTS.

WHY:
Byte-exactness means callers own canonicalization (String 1, String 7): two subject references differing only in case are two subjects to this atom, and a [Read] filtered on one will not answer the other's records. In a store whose purpose is completeness, that is the failure mode worth naming — an Article 15 answer that is short by the records filed under a differently-cased reference is wrong in the one direction the regulation punishes.

NOTE: watch host obligations — this atom sets no maximum length on a string input, where [Duplicate Prevention](./duplicate-prevention.md) declares a cap and [Provenance](./provenance.md) obliges the deployment to set one. Three postures, and the *host obligations* docket row carries the count — a watch flag states the pressure, never a census nothing reads.

### Clock semantics

```text
Clock semantics 1: The deployment MUST own the clock's monotonicity.
Clock semantics 2: The deployment MUST own the clock's honesty.
Clock semantics 3: The deployment MUST own the clock's synchronization.
Clock semantics 4: The atom MUST NOT record a receipt instant.
Clock semantics 5: A deployment needing a verifiable time anchor MUST compose a trusted timestamping pattern.
```

WHY:
Clock skew between a caller and the seam can push a `disclosed_at` the caller believes is current past the injected reading, and Operation 7 rejects it. That is the correct rejection: the temporal invariant is enforced against the injected `now`, not against the caller's belief about the time.

Clock semantics 4 states the gap that makes backdating undetectable here rather than leaving it implicit. The atom stores the declared instant and nothing else, so a call made today with `disclosed_at: "2024-01-01"` produces a record that reads as a 2024 disclosure. The receipt instant lives in the composing [Event Log](./event-log.md) entry, and External check 3 is where the comparison is made.

### Concurrency

```text
Concurrency 1: The atom MUST NOT serialize two [Record] calls against one subject_ref.
Concurrency 2: A [Record] call's answer MUST NOT rest on a concurrent [Record] call's answer.
Concurrency 3: The implementation MUST issue EXACTLY ONE disclosure_id per admitted record.
```

WHY:
There is no shared mutable state for two [Record] calls to contend over — each appends its own record under its own injected id — so serialization across calls would buy nothing and cost throughput on exactly the batch disclosures regulated systems make most (a report covering many patients is one call per patient, per Non-goal 14's neighbourhood). The only serialization the atom asks for is within a single call's write.

### Correction by append

```text
Correction 1: The atom MUST NOT edit a disclosure record.
Correction 2: The atom MUST NOT remove a disclosure record.
Correction 3: A caller correcting a disclosure record MUST call [Record] again.
Correction 4: A correcting disclosure record's correction narrative MUST name the corrected disclosure record.
```

Terms › `correction narrative`: the `scope` OR the `authority_reference` a correcting disclosure record carries — the two fields that hold prose.

WHY:
A record capturing the wrong scope or the wrong recipient stands permanently, and the correction is a new record that narrates the relationship to it. An auditor reading both sees the full history including the correction, which is what regulated record-keeping asks for — the same posture [Legal Hold](./legal-hold.md) takes on a case-reference update. Immutability of the original is the structural guarantee that records cannot be silently altered after the fact, so exempting a correction would exempt the very edit the guarantee exists to prevent.

---

## Composition notes

```text
Composition note 1: A deployment MUST declare which composing patterns the deployment wired in.
Composition note 2: A composing pattern MUST own the authorization of a call.
Composition note 3: A composing pattern MUST own the attestation binding the recording actor.
Composition note 4: A composing pattern MUST own the legitimacy of an authority_reference.
Composition note 5: A composing pattern MUST own the tamper seal over the disclosure store.
Composition note 6: A composing pattern MUST own the retention of the disclosure store.
Composition note 7: A composing pattern MUST own at-most-once recording.
Composition note 8: A composing pattern closing Invariant 5.1 MUST own the only disclosure surface.
Composition note 9: A composing pattern reading the disclosure store MUST NOT write to the disclosure store.
```

WHY:
[Immutable Transaction Ledger](../compositions/immutable-transaction-ledger.md) (`grounded` 2026-06-08) is the composition that does what this atom cannot: it structurally closes Invariant 5.1 by making its own `disclose_subset` the only disclosure surface and having that surface always record (Composition note 8). The ledger is immutable, attributed and tamper-evident, and a subset can be disclosed to a counterparty both accountably — each disclosure is itself an immutable attributed event — and verifiably, without compromising the undisclosed remainder.

[Resolve a Person's Data Rights](../compositions/resolve-a-persons-data-rights.md) uses this atom in both directions: *read* to answer Article 15(1)(c)'s recipients limb, and *written* to record each fulfillment response as an accountable disclosure to the requester — which settles, for that case, the policy question Non-goal 20 leaves open.

[Audit Trail](../compositions/audit-trail.md) is the regulated-audit stack every [Record] call passes through in a regulated deployment, and it is where External check 3's backdating comparison is surfaced. [Consent](./consent.md) and [Legal Hold](./legal-hold.md) are the authority stores behind two of the three authority types, and they are composing peers rather than constituents — neither imports the other's semantics, and both may be live on one subject's records at once. [Actor Identity](./actor-identity.md) supplies the recording actor's attestation, [Tamper Evidence](./tamper-evidence.md) the cryptographic seal, [Retention Window](./retention-window.md) the lifecycle, [Permissions](./permissions.md) the scoped read access a store holding subject identities and disclosure patterns needs, and [Duplicate Prevention](./duplicate-prevention.md) at-most-once recording under retry.

---
## Terms

Each `[Term]` marker above links to its term entry here; a term entry states what the concept *is* and its **Kind**.

### Vocabulary

Terms › `actors`: the atom; the host; the transition; the implementation; the deployment; a composing pattern; a business caller; a caller; a guard; an auditor; a regulator; a data subject; the store; a disclosure record; a stored disclosure record; a correcting disclosure record; a refused [Record]; a query; a filter; a transmission; a rejection; a string input; an opaque reference; the store instance's record count; a field-level precondition.

Terms › `records`: `disclosure record` — one recorded disclosure, carrying `disclosure_id`, `subject_ref`, `recipient`, `scope`, `authority_type`, `authority_reference` and `disclosed_at`.

Terms › `record verbs`: identify, allocate, change, carry, stand, answer, record, resolve, take, stamp, leave, own, match, normalize, interpret, confirm, admit, offer, detect, route, share, precede, follow, exceed, compare, trim, case-fold, refuse, write, find, read, remove, edit, retract, sort, order, bound, decide, compose, declare, wire, rest, apply, supply, serialize, issue, name, claim, transmit, redact, retrieve, canonicalize, persist, fall, call, produce, choose, capture.

Terms › `value sets`: record answers = recorded(disclosure_id) | rejected(invalid-request | unknown-authority-type | storage-failure). read answers = the matching disclosure records | rejected(invalid-query). `authority_type` = consent | legal-hold | regulatory.

Terms › `bounds`: empty.

Terms › `cadences`: empty.

Terms › `qualifiers`: `migrated` — rewritten in GRACE lang v0.40 (2026-09-12).

Terms › `terms`: `disclosure record`, `disclosure_id`, `subject_ref`, `recipient`, `scope`, `store instance`, `seam`, `transition`, `now`, `business caller`, `authority`, `authority_type`, `authority types`, `authority_reference`, `disclosed_at`, `resolved disclosed_at`, `field-level precondition`, `filter axes`, `admitted record`, `string input`, `blank`.

#### Record

The behavior that appends one immutable disclosure record: it takes the injected `id_t` as the record's [Disclosure Id], stores [Subject Ref], [Recipient], [Scope], [Authority] (both [Authority Type] and [Authority Reference]), and [Disclosed At] (the injected clock `now` if not supplied; rejected [Invalid Request] if in the future), and returns `recorded(disclosure_id)`. Rejection priority: [Invalid Request] → [Unknown Authority Type] → [Storage Failure].

Kind: Operation

#### Read

The read-only query returning the matching disclosure records in [Disclosed At] then [Disclosure Id] ascending order, filtered by any of [Disclosure Id], [Subject Ref], [Recipient], [Authority Type], or a [Disclosed At] range. Never writes; an empty result is not a rejection. Rejected [Invalid Query] for a malformed filter.

Kind: Operation

#### Disclosure Id

The opaque, immutable identity of a disclosure record — the injected `id_t`, supplied at the I/O seam (fresh per call, never reused), byte-order sortable for deterministic [Read] ordering (Invariant 6). It is the record's identity; the other fields are properties.

Kind:     Field
Field of: the disclosure record
Projects: disclosure_id

#### Subject Ref

The opaque reference to the data subject whose data was disclosed. Set on [Record], immutable, non-whitespace (Invariant 3); the same subject may appear in many records.

Kind:     Field
Field of: the disclosure record
Projects: subject_ref

#### Recipient

The non-empty string naming the party the data was disclosed to. Set on [Record], immutable (Invariants 1 and 3); opaque and exact-match on [Read] (subject-recognizable naming is the calling system's obligation).

Kind:     Field
Field of: the disclosure record
Projects: recipient

#### Scope

The non-empty string naming what subset of the subject's data was disclosed, as declared by the calling system. Set on [Record], immutable; opaque (subject-comprehensible vocabulary is the calling system's obligation).

Kind:     Field
Field of: the disclosure record
Projects: scope

#### Authority

The structured field naming the legal basis for the disclosure — exactly two sub-fields, [Authority Type] and [Authority Reference]. Always present in structured form (Invariant 2). Set on [Record], immutable.

Kind:     Field
Field of: the disclosure record
Projects: authority

#### Authority Type

The kind of authority — exactly `consent`, `legal-hold`, or `regulatory` (any other value is [Unknown Authority Type]). The machine-queryable half of [Authority]; the [Read] filter axis of the same name matches on it.

Kind:     Field
Field of: the authority field
Projects: authority.type

#### Authority Reference

The opaque, non-whitespace string identifying the specific authority — a Consent id, a Legal Hold id, or a regulatory citation. The human-readable half of [Authority]; the atom validates its presence, not its legitimacy.

Kind:     Field
Field of: the authority field
Projects: authority.reference

#### Disclosed At

The timestamp of the disclosure event. Set on [Record] or defaulted to the injected clock `now`; immutable. Must not be in the future relative to the injected `now` (Invariant 4); may be backdated. Best-effort — the wall clock, not this atom, bounds its honesty.

Kind:     Field
Field of: the disclosure record
Projects: disclosed_at

#### Invalid Request

The rejection [Record] returns when a required field ([Subject Ref], [Recipient], [Scope], or [Authority Reference]) is missing or whitespace-only, [Authority] is structurally malformed, or the resolved [Disclosed At] is in the future.

Kind:      Member
Member of: the record rejection
Role:      Outcome
Projects:  invalid-request

#### Unknown Authority Type

The rejection [Record] returns when [Authority Type] is not one of `consent`, `legal-hold`, or `regulatory` — checked after all field-level validation passes.

Kind:      Member
Member of: the record rejection
Role:      Outcome
Projects:  unknown-authority-type

#### Storage Failure

The rejection [Record] returns when the store write fails after all preconditions pass; guarantees no partial record was persisted (Invariant 6).

Kind:      Member
Member of: the record rejection
Role:      Outcome
Projects:  storage-failure

#### Invalid Query

The rejection [Read] returns when a filter value is malformed — a null or whitespace [Disclosure Id], [Subject Ref], or [Recipient]; an [Authority Type] outside the three values; a reversed [Disclosed At] range; or an unrecognized filter key.

Kind:      Member
Member of: the read rejection
Role:      Outcome
Projects:  invalid-query

<!-- Term registry — shortcut-reference definitions. These produce no visible
     output; each resolves a [Term] marker to its term entry heading above (kramdown
     auto-generates the heading anchors on GitHub Pages). Standard CommonMark /
     kramdown; no plugin required. -->

[Record]: #record
[Read]: #read
[Disclosure Id]: #disclosure-id
[Subject Ref]: #subject-ref
[Recipient]: #recipient
[Scope]: #scope
[Authority]: #authority
[Authority Type]: #authority-type
[Authority Reference]: #authority-reference
[Disclosed At]: #disclosed-at
[Invalid Request]: #invalid-request
[Unknown Authority Type]: #unknown-authority-type
[Storage Failure]: #storage-failure
[Invalid Query]: #invalid-query

---

## Standards references

- **GDPR Article 15(1)(c)** — the data subject's right of access includes the right to know the recipients or categories of recipients to whom their personal data has been or will be disclosed. Selective Disclosure is the accountability layer that makes Article 15(1)(c) responses structurally answerable from records alone. Every disclosure record's [Recipient] field and [Authority] field are the data the Article 15 response draws from.
- **GDPR Article 30 (Records of processing activities)** — controllers must maintain records of processing activities, including categories of recipients to whom personal data has been or will be disclosed, and transfers to third countries or international organizations. Disclosure records under this atom are the processing-activity records Article 30 requires for the disclosure category of processing.
- **HIPAA §164.528 (Accounting of disclosures of protected health information)** — individuals have the right to receive an accounting of disclosures of their PHI (Protected Health Information — individually identifiable health data covered by HIPAA) made by a covered entity or business associate. The accounting must include the date of each disclosure, the name and address of the recipient, a brief description of the PHI disclosed, and a brief statement of the purpose. Each field maps directly: [Disclosed At] (date), [Recipient] (recipient name), [Scope] (description of PHI), [Authority Reference] (purpose statement). The atom is the structural implementation of §164.528's accounting obligation.
- **SEC Rule 17a-4** — broker-dealers must preserve records in non-rewriteable, non-erasable format, accessible to regulators on demand. Disclosure records for broker-dealer records are themselves required records under 17a-4. Composing with Tamper Evidence satisfies the non-rewriteable, non-erasable standard; this atom provides the disclosure record structure.

---

## Status

`grounded on Final Critique 5 — 2026-06-23` — see the Ledger.

## Ledger

```
status: grounded on Final Critique 5 — 2026-06-23
formal: not applicable — vote no 2026-06-03
last gate: 2026-06-23 — Final Critique 5, fresh reader — clean

open: none
```

## Decisions

Directional changes only — the turns a future reader must know the pattern took, and why. Everything smaller lives in the commit that made it: `git log -- atoms/selective-disclosure.md`.

- **2026-09-12 — Rewritten in GRACE lang v0.40; nothing but language changed.** *Chose:* the two actions as a signature block, Invariants 1–6 keeping their numbers, every success effect conditioned on a declared `admitted record` or `admitted read` so no effect binds a refused call (Hard invariant 16), the `disclosed_at` resolution routed through a declared `resolved disclosed_at` so no rule restates the default, the rejection precedence carried by `Operation 8` and `Operation 15` rather than by a prose *rejection priority* line repeated in three sections, the six acceptance areas opened into `Check 2.1–6.2` with the three named audit gaps raised to `External check 1–3`, the Non-goals-and-edge-cases prose split into a `Non-goal 1–22` family and four edge-case families (`String`, `Clock semantics`, `Concurrency`, `Correction`), the Composition notes prose raised to `Composition note 1–9` with the named compositions moved into the WHY. *Over:* the prose spec. *Because:* the migration plan; `cites.py --into selective-disclosure` found nothing in the corpus citing this atom by label, so the rewrite carried no frozen-number risk. 73.9 KB → 49.9 KB.

- **2026-09-12 — A filter's match semantics is a rule, not an assumption.** *Chose:* `Operation 27` (an admitted read answers every matching record) and `Operation 28` (an admitted read answers no record failing a filter). *Over:* the prose, which spelled out matching for the `authority_type` axis alone and left the other four to be inferred from the word *matching* in the action description. *Because:* the migration's Check 5.1 tests that a `subject_ref` query answers every record carrying the reference, and no rule in the spec owned that proposition — a check resting on an unowned invariant, the class the docket has been collecting since council read 12. The gap was invisible to both tools and surfaced only when each check was made to name the rule it tests, which is the discipline earning its keep rather than a finding against the atom.

- **2026-09-12 — Reference-level filtering is a non-goal, not an operation.** *Chose:* `Non-goal 22`. *Over:* an `Operation` rule saying [Read] must not offer the axis. *Because:* `Terms › filter axes` enumerates five axes and `Operation 22` rejects anything outside them, so the operation-level rule was entailed twice over (Authority 3); what is not entailed is the design claim — reference search is a composing-layer concept — and that belongs with the other surface refusals.

- **2026-09-12 — Six defects the tools passed, found by a self-read before a council read.** *Chose:* `Invariant 1.1` rewritten from a garbled sentence that barely parsed; `Concurrency 2` restored to the prose's claim — two concurrent calls are *independent*, which is what the spec said, not *non-blocking*, which is what I had written; `Correction 4` given a declared `correction narrative`, because naming the corrected record is unsatisfiable unless a field holds the naming and the prose named two; `Identity 15` changed from the deployment *allocating* an id (contradicting `Identity 2`, where the host allocates) to the deployment choosing the id *format*; `Operation 20`'s lower-case `where` replaced by an admitted `IF … THEN`; the former first conformance check moved to `External check 4`. *Over:* shipping a file both checkers called clean. *Because:* zero tool findings has never once predicted zero council findings, and three of the six were changes in meaning rather than infelicities. The last is the repeatable one: a check asking an auditor to find *every issued* `disclosure_id` cannot be cleared from the store, because the store is exactly what would be missing one — the same split council read 22 forced on Capability, applied here before a reader had to force it.

NOTE: End of Selective Disclosure.
