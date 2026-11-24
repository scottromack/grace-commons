---
title: Recoverable Invocation as an app
audience: common
nav_exclude: true
has_toc: true
toc: true
---

# Recoverable Invocation as an app

<details markdown="block">
<summary>Table of contents</summary>
{: .text-xs .font-medium .uppercase .tracking-wide .opacity-50 }
1. TOC
{:toc}
</details>

## What it is

Recoverable Invocation is an app: the protocol a regulated action follows when it changes something it cannot take back and must leave a trustworthy account of having done so. It is built from three atoms, [Durable Intent](../../atoms/durable-intent.md) (the intent before the act, the outcome after, one standing closing), [Sweep](../../atoms/sweep.md) (the clean-up run that finishes an account the process left open) and [Escalation](../../atoms/escalation.md) (the findings and the operator's closing), with [Lease](../../atoms/lease.md) as it stands, wired by four bonds, and a short marked residue of glue that belongs to no atom yet. It was one composition page, [compositions/recoverable-invocation.md](../../compositions/recoverable-invocation.md), until the split of 2026-11-23; that page stays as the frozen reference until the review of this one.

<details markdown="block">
<summary>WHY</summary>

An irreversible act and its account are two writes no transaction spans (the library's rule since 2026-08-27: an atomic set may not contain a write the host cannot take back). The order — intent, act, outcome — leaves exactly one reachable partial: the act committed, its record owed. Something must close it after the process that opened it is dead.

By 2026-08-30 twenty compositions had each solved this in their own words, and two days of fresh-reader gates found the same defects in every one: two writers landing an outcome for one act; a sweep reading in-flight work as a crash; a sweep re-emitting an outcome it could not have known; a rejection code saying nothing had committed when something had; a closure window that could not be met. One protocol, carried once. The rule: **one act, one intent, one standing closing, one writer at a time** — the invocation while it holds the critical section, the sweep after the invocation has yielded, an operator through [Resolve] under the same section, never two at once.

It is not a transaction, the adopter's database, an audit journal or a class. An adopter names it in *Composes*, binds its parameters, declares any deviation, and deletes the paragraphs this pattern replaces.

</details>

### Atoms

- **[Lease](../../atoms/lease.md)** — the per-key grant of exclusive standing whose terminus is an instant. The act's critical section is a lease. This pattern binds the atom's parameters — which key, which holder, how long, which arm maps to which code — and restates none of its semantics but the sizing the atom obliges a composer to state as its own (act section 16). What the atom refuses to own and this pattern adds: which key protects which work, and how long a grant must last.
- **[Event Log](../../atoms/event-log.md)** — the journal. Durable Intent's journal need meets its offer by type alone: append and read by range, in sequence order, every act kind's records in the one stream `invocation journal`. The app sets the offer's keep to the retention period of the kinds it serves, and its tamper to sealed (the seal a deployment composes over the kept records); a kind whose retention period exceeds the keep leaves the need unmet (Bonds journal 9).
- **The attested append** — held, not a bond yet. [Audit Trail](../../compositions/audit-trail.md) is the substrate that makes it: `record_action(action_ref, actor_ref, credential, data)` answers event id and refuses `invalid-credential | invalid-request(step, committed_ids) | recording-failure(step)`, for every record this pattern writes (Durable Intent Term attested append). The journal kind carries no actor and no credential, so the actor key and the credential check wait for the unit `bonds: permission` (see *Glue*, The attested append).
- **The bound act** — not a constituent. The adopter's constituent commit call, supplied as a binding together with the read that tells whether it committed. The constituent's own contract governs the commit.
- **The act's critical section** — keyed by the act, supplied by the deployment (*Capability requirement*, act section). No constituent's records provide it: Lease states what it is, and the deployment supplies the host.

### Bonds

Bond kinds are [the bonds page](../../bonds.md)'s, one source; this app names the kinds it instantiates and defines none.

- **guard** — [Lease](../../atoms/lease.md): one writer per act. The critical section is keyed by `(kind, act_key)`; the invocation, the sweep and an operator's [Resolve] each take it before they write a closing (Durable Intent act section 8 through 10; Sweep act section 11 through 13; Bonds guard 1).
- **key** — invocation id: every record the three atoms write for an invocation carries it, and every check and journal join pairs on it and no other field (Durable Intent Primitive policy 4 and 5; Invariant 3.1 and 3.2 of Durable Intent).
- **journal** — [Event Log](../../atoms/event-log.md): every record Durable Intent appends and every read of an act's records goes to the one stream `invocation journal` (Durable Intent's journal need, Bonds journal 1 through 9). One keep per instance (the retention period) and one tamper (sealed): kinds with different retention periods run under different instances.
- **follow-up** — [Sweep](../../atoms/sweep.md) follows an aged intent of [Durable Intent](../../atoms/durable-intent.md); [Escalation](../../atoms/escalation.md) follows what the sweep cannot settle (the `<kind>.escalated` record and the closure-at-risk finding).
- **range** — the closure window as the sum of the declared bounds: Instance start 4 below holds it above the worst closure, and Instance start 5 holds the retention period above the retention floor.

### The closure table

The closure table of the old page (every input an action takes and every answer its calls can meet, with where the action lands it and the rule that owns the landing, 135 lines) is not carried as prose. It is generated from the contracts of the three atoms and is **planned**: until the generator exists, the landings are read from each action's rules (Durable Intent open, close, refuse, yield and read invocation; Sweep reconcile; Escalation resolve).

## Glue

What belongs to no atom yet, moved from the old page as it stood. Every line carries its birth tag: `bond candidate`, `atom candidate`, `data` or `dead`; each leaves by one of three exits (promote, demote, die), and a line older than one minor version without a ruling warns (Scott, ruling of 2026-11-23 05:35Z). The glue is shape in the tree and loose only in meaning.

### Capability requirement

```
Deleted: Capability requirement 11. Bonds journal 2 owns the range read, Bonds journal 3 the read-your-writes, and the guard need of Durable Intent the act section.
```
### The attested append

Held for the review of the unit `bonds: journal, finished` (its step 4 stopped): the journal kind says append, keep and read by range, and an actor key a record carries, and a credential checked before the append with an invalid-credential answer, are neither (no journal offer's record carries an actor, the attribution being a separate record paired to the event, and the check is a call whose answer another atom decides). The lines below are what the kind cannot say; each leaves when the unit `bonds: permission` states how a need of another atom's decision is said.

```
attested append 1: A record this composition appends MUST carry the actor reference the caller's credential validates for. {birth: bond candidate}
attested append 2: IF the caller's credential does not validate for the actor reference THEN the substrate MUST refuse invalid-credential AND MUST append nothing. {birth: bond candidate}
attested append 3: The sweep's service identity MUST validate as a caller's credential validates. {birth: bond candidate}
```

### The act's critical section

- **act section**
  ```
  act section 16: The composition MUST bind Lease Sizing 1 through 9 for EVERY unfenced write under the critical section, with pause bound as the atom's call pause bound, lease spend and sweep lease spend, each on the path with no retry and no lost reply, as the atom's work bounds, write floor and commit floor as the atom's start floors, and journal write bound and commit round trip, each behind one pause, as the units' bounds (Lease Composition note 8a). {birth: bond candidate}
  ```

### Bounds the deployment declares

- **closure window**
  Term closure window: the duration within which the sweep closes an act whose invocation died, from the intent's recording instant. Conditions 1 and 2; rearranged, the at-risk threshold of [Reconcile] step 5. *Default:* none. {birth: data}

- **clock allowance**
  Term clock allowance: the allowance for comparing a reading from one clock with a stamp or instant from another; the section titled *Where the allowance goes* owns where it is spent. *Default:* none. {birth: data}

- **retention period**
  Term retention period: the keep the instance's journal need asks of each record of a kind, a per-kind binding (*Bindings*, journal 6); [Reconcile] step 1 and condition 2 read it. *Default:* none. {birth: data}

- **compliance surface**
  Term compliance surface: the deployment's surface for the instance's findings (*Composition state* owns the contract); check 3 reads both branches on it. *Default:* none. {birth: data}

### Constituent invariants and the guard

- **Invariant 9 — Constituent invariants preserved.**
  ```
  Deleted: Invariant 9.1. Bonds journal 1 owns a kept record's immutability, the journal need's tamper the seal, and the held attested append the attribution.
  ```
### Checks that read the app

```
Check 4.1: An auditor MUST confirm all five conditions of instance start, as the section titled Instance start states the conditions, for EVERY bound act kind from the kind's invocation completion bound, commit round trip, probe round trip, retention period and settling period, and the instance's clock allowance, sweep cadence, run bound, closure latency, read bound, journal write bound, pause bound and closure window. {birth: data}
```
```
Deleted: Check 8.1. The journal offer's own checks and the tamper of the journal need own the traversal.
```
```
External check 2: An auditor MUST clear from external evidence that act section is shared across every node of the instance and implemented as a lease of the declared length. {birth: data}
External check 3: An auditor MUST clear from external evidence that closure latency, invocation completion bound, commit round trip, probe round trip, read bound, pause bound, journal write bound, clock allowance and run bound were set from observed worst cases with headroom, run bound over the largest backlog the deployment sizes for. {birth: data}
External check 4: An auditor MUST clear from external evidence that the adopter's act probe reads the database the act was made in. {birth: data}
```
```
External check 8: An auditor MUST clear from external evidence that no writer other than this composition's actions uses an adopter's journal vocabulary. {birth: data}
External check 9: IF repeatable EQUALS no THEN an auditor MUST clear from external evidence that the adopter's bound commit refuses, on an arm the constituent declares pre-commit, EVERY call whose act key a record of the adopter's database carries (repeatable 2). {birth: data}
```
```
External check 12: An auditor MUST clear from external evidence that the obligation pairing datum 4 names held where the datum is a seam-injected now. {birth: data}
```
### Non-goals

```
Non-goal 3: This composition MUST NOT add to the substrate's contract. {birth: dead}
```
```
Non-goal 5: A deployment whose regulator requires the account to outlive the act's own retention MUST set the keep of the journal need accordingly. {birth: dead}
Non-goal 6: This composition MUST NOT govern the lifecycle of the adopter's constituent records. {birth: dead}
```
### Clock semantics

```
Clock semantics 3: The composition MUST NOT time the lease. {birth: dead}
```
### Declared deviations

```
Deviation 1: An adopter MUST declare a deviation as EXACTLY ONE OF: minted key; journal without attribution. {birth: bond candidate}
Deleted: Deviation 5. Bond 10 owns it: a journal need whose tamper no offer meets fails the app's build.
```
### Repeatable and non-repeatable acts

The adopter's declaration; [Open]'s act-landed refusal fires only for `repeatable = no`. The composition does not guess. A second attempt of a non-repeatable act meets [Open]'s act-landed where act closings holds the act's outcome, and the commit's own refusal wherever the adopter's database holds the act (repeatable 2): past the horizon, which destroys the outcome's payload, and under an escalation over an act that committed. Where neither holds the act — its outcome's payload destroyed, and its record removed from the adopter's database, which Binding 9 permits once the journal's retention of the outcome has ended — no rule refuses the attempt: how long a second attempt stays refused past the horizon is how long the adopter's database keeps the act.

### Wiring decision

*One act, one writer at a time, one standing closing.*

<details markdown="block">
<summary>WHY</summary>

An irreversible act and its account are two writes no transaction spans, and closing the partial after the opening process is dead is a second writer by definition. The protocol is sound exactly when the two writers cannot both write for one act, the second cannot mistake in-flight work for a dead invocation's, and the second cannot write what it did not read — properties of the critical section, the edges and the act probe, none of the adopter's act. A methodology rule does not stop twenty authors writing it twenty ways or spare the formal layer twenty models; the higher-order composition test's threshold is five exact instances and this clears it several times over ([`tools/survey/protocol_prose.py`](https://github.com/scottromack/grace-commons/blob/main/tools/survey/protocol_prose.py)). What differs between adopters is the binding set; anything else is a deviation from a closed list. One pattern carries the protocol, one model proves it, one gate attacks it; an adopter's action shrinks to *validate, open, commit, close*.

</details>

### Bindings

An adopter binds the parameters below once per **act kind**. The instance's bindings Configuration entry is the table of bound kinds — configuration, not state.

```
Binding 1: [Reconcile] MUST read invocation completion bound, act probe, service identity, retention period, settling period and the `<kind>.*` vocabulary of every intent from the bindings table by the intent's kind, the retention period of an intent Binding 14a names excepted. {birth: data}
Binding 2: The deployment MUST refuse a configuration change that unbinds a kind with an open intent. {birth: data}
Binding 3: The refusal Binding 2 names MUST land on compliance surface as a hard alert naming an open intent of the kind. {birth: data}
Binding 4: [Reconcile] step 1 MUST surface EVERY `<kind>.intended` record whose kind the bindings table does not serve and whose invocation id no `<kind>.*` record names, the intent and the intent's `<kind>.recovery_intended` records excepted, once per run, on compliance surface. {birth: data}
Binding 5: [Reconcile] MUST NOT close an intent Binding 4 surfaces. {birth: data}
Binding 6: [Reconcile] MUST bound the pass Binding 4 names by the instance's longest retention period. {birth: data}
Binding 7: The adopter MUST declare EVERY binding in the adopter's own Composes entry for this composition. {birth: data}
Binding 8: The adopter MUST declare a need outside the bindings as a deviation (Edge cases, Declared deviations). {birth: data}
Binding 9: An adopter MUST NOT bind a kind whose database removes a record ahead of the keep of the journal need for the record's outcome. {birth: data}
Binding 10: EVERY action but [Reconcile] MUST read the bindings of the kind the action takes from the bindings table by that kind, the retention period of an intent Binding 14a names excepted. {birth: data}
Binding 11: A change to a kind's retention period MUST NOT take effect on a running instance BEFORE EVERY Instance start rule reading retention period has passed against the change. {birth: data}
Binding 11a: IF a requested change to a kind's retention period has not taken effect THEN the deployment MUST refuse a further change to the kind's retention period. {birth: data}
Binding 12: A lengthening of a kind's retention period MUST NOT take effect BEFORE EVERY record placed under the old period before the lengthening was requested is past the retention end the old period gives the record. {birth: data}
Binding 12a: The keep of the journal offer MUST be the new period for EVERY record appended from the instant a lengthening of a kind's retention period is requested. {birth: data}
Binding 13: A shortening of a kind's retention period MAY take effect at once, Binding 11 holding. {birth: data}
Binding 14: EVERY rule of this pattern reading retention period MUST read the retention period in force, the old period until Binding 11 and Binding 12 let a change to a kind's retention period take effect, a record Binding 14a names excepted. {birth: data}
Binding 14a: EVERY rule of this pattern reading the retention period of a `<kind>.*` record placed from the instant a lengthening of the kind's retention period is requested MUST read the new period (Binding 12a). {birth: data}
```
- **act key**
  Term act key: the key an adopter gives an act, opaque and adopter-typed, with equality by byte-identity: the field or tuple under which two invocations are one act attempted twice where repeatable is no, and two acts where repeatable is yes. The critical section is keyed by it; the sweep pairs by it; the pre-check reads by it. {birth: data}

- **commit**
  Term commit: the adopter's constituent call that makes the act, with its rejection arms partitioned by the adopter. {birth: data}

  ```
  commit 1: The adopter MUST partition the constituent's arms as EXACTLY ONE OF pre-commit, committed, unknown. {birth: atom candidate}
  commit 2: The adopter MUST close a pre-commit arm through [Refuse]. {birth: atom candidate}
  commit 3: The adopter MUST return the constituent's own code for a pre-commit arm. {birth: atom candidate}
  commit 4: The adopter MUST close a committed arm through [Close]. {birth: atom candidate}
  commit 5: The adopter MUST transcribe the constituent's partition as the constituent states the partition. {birth: atom candidate}
  commit 6: The adopter MUST treat a lost reply as unknown. {birth: atom candidate}
  commit 7: The adopter MUST treat a reply the constituent's contract declares neither pre-commit nor committed as unknown. {birth: atom candidate}
  commit 8: WHEN the arm EQUALS unknown: {birth: atom candidate}
      commit 8a: The adopter MUST NOT call [Close]. {birth: atom candidate}
      commit 8b: The adopter MUST NOT call [Refuse]. {birth: atom candidate}
      commit 8c: The adopter MUST call [Yield]. {birth: atom candidate}
      commit 8d: The adopter MUST return recording-failure(outcome) to the caller. {birth: atom candidate}
  commit 9: The adopter MAY call [Refuse] ONLY IF the constituent declares the arm pre-commit. {birth: atom candidate}
  commit 15: The adopter MUST issue the bound commit WITHIN pause bound of [Open]'s return. {birth: atom candidate}
  ```
- **pairing datum**
  Term pairing datum: the field the intent record and the constituent's record both carry by construction: the seam-injected now passed into commit, or an adopter-minted nonce stored by the constituent. {birth: data}

  <details markdown="block">
  <summary>WHY</summary>

  a journal join is a join between two records this composition writes; an adopter's own lookup of its intent by act key and pairing datum is the adopter's read, not a join of this pattern's.

  </details>
- **repeatable**

  Term repeatable: `yes` or no: whether two invocations against one act key are two acts or one act attempted twice. {birth: data}

  ```
  repeatable 1: [Open]'s act-landed refusal MAY fire ONLY IF repeatable EQUALS no. {birth: data}
  repeatable 2: IF repeatable EQUALS no THEN the commit MUST refuse, on an arm the constituent declares pre-commit, EVERY call whose act key a record of the adopter's database carries. {birth: data}
  ```
- **act probe**
  Term act probe: a read of the adopter's database keyed by act key and pairing datum, answering for the sweep: did the act commit, and with what outcome. {birth: data}

  ```
  act probe 1: act probe MUST answer EXACTLY ONE OF committed(outcome action reference, outcome data), not-committed, undecidable(candidates), unavailable. {birth: atom candidate}
  act probe 2: act probe MAY answer committed ONLY IF exactly one database record matches pairing datum. {birth: atom candidate}
  act probe 3: act probe MAY answer undecidable(candidates) ONLY IF more than one record matches pairing datum OR payload match holds OR act probe 7 applies OR the adopter declared act probe set to undecidable under the commit contract's minted key variant (Contracts Commit 3c). {birth: atom candidate}
  act probe 3a: IF payload match holds OR more than one record matches pairing datum THEN act probe MUST answer undecidable(candidates), a constituent read rejection excepted (act probe 4). {birth: atom candidate}
  act probe 4: act probe MUST map EVERY constituent read rejection to unavailable. {birth: atom candidate}
  act probe 5: act probe MUST NOT map a constituent read rejection to not-committed. {birth: atom candidate}
  act probe 6: outcome data MUST carry only what the database re-derives. {birth: atom candidate}
  act probe 7: WHEN the outcome's authoritative datum exists nowhere but in the dead invocation's memory: {birth: atom candidate}
      act probe 7a: act probe MUST answer undecidable. {birth: atom candidate}
  act probe 8: act probe MAY answer committed ONLY IF the matching database record carries EVERY field of act key. {birth: atom candidate}
  act probe 9: act probe MAY answer committed ONLY IF the outcome action reference IS IN the kind's enumerated outcome refs. {birth: atom candidate}
  ```
  Term payload match: pairing datum EQUALS none AND at least one database record matches the intent's payload. {birth: data}

- **invocation completion bound**
  Term invocation completion bound: the longest a conforming invocation of the kind takes from [Open]'s critical section take to [Close]'s last write, including the constituent round-trip. The lease length of the critical section, the lower edge of the sweep, the first term of the liveness inequality. Read against the seam clock [Open] was injected with. {birth: data}

- **commit round trip**
  Term commit round trip: the longest one commit call takes from issue to reply; charged by lease spend. {birth: data}

- **journal**
  Term journal: the Event Log instance the records go to, Durable Intent's journal need met, and the action reference vocabulary of the kind (Durable Intent Primitive policy 46 through 49). {birth: data}

  ```
  Deleted: journal 1. The stream of Durable Intent's journal need owns it: every act kind's records go to the one stream `invocation journal`.
  Deleted: journal 2. Durable Intent Primitive policy 46 owns it.
  Deleted: journal 2a. Durable Intent Primitive policy 46a owns it.
  Deleted: journal 3. Durable Intent Primitive policy 47 owns it.
  Deleted: journal 4. Durable Intent Primitive policy 48 owns it.
  Deleted: journal 5. Durable Intent Primitive policy 49 owns it.
  journal 6: The keep of the journal need MUST be one retention period for EVERY `<kind>.*` record of the instance, a record Binding 12a names excepted. {birth: data}
  journal 7: IF the retention periods of two kinds differ THEN the kinds MUST run under different Recoverable Invocation instances. {birth: data}
  ```
- **service identity**
  Term service identity: a registered actor (actor reference and credential) under which the sweep writes, or none; the substrate validates its credential as it validates a caller's (the held attested append). {birth: data}

  ```
  service identity 1: WHEN service identity EQUALS none: {birth: data}
      service identity 1a: The sweep MUST NOT write to the journal. {birth: data}
      service identity 1b: The sweep MUST surface EVERY aged open intent on compliance surface. {birth: data}
  service identity 2: PROVISIONAL: Invariant 4's liveness arm DEGRADES TO surfaced under service identity EQUALS none. {birth: data}
  service identity 3: A writer other than the sweep MUST NOT write to the journal under the service identity. {birth: data}
  ```
### Instance start

```
Instance start 1: This section IS AUTHORITATIVE FOR the conditions of instance start. {birth: data}
NOTE: watch addressable sections — a section title as the subject of an authority claim (Instance start 1, Allowance 2, Durable Intent Which closing stands 1, Durable Intent Invariant 2.6).
Instance start 2: The instance MUST check EVERY condition at start for EVERY bound act kind. {birth: data}
Instance start 3: IF any condition fails for any bound kind THEN the instance MUST NOT start. {birth: data}
Instance start 3a: IF read bound EQUALS blank OR journal write bound EQUALS blank OR pause bound EQUALS blank OR closure latency EQUALS blank OR run bound EQUALS blank THEN the instance MUST NOT start (Execution Contract Logic confinement 15). {birth: data}
```
Term worst closure: `(((invocation_completion_bound + (2 * clock_allowance)) + (2 * sweep_cadence)) + (3 * run_bound))` — invocation completion bound the kind's, the rest the instance's, the allowance counted twice for every kind. {birth: data}

Term examine window end: `((invocation_completion_bound + clock_allowance) + closure_window)` — measured from an intent's recording instant, the end of a closure window counted from the intent's examine edge; it lies the examine edge's offset past the end of the window Term closure window counts from the recording instant. {birth: data}

Term retention floor: `((examine_window_end + settling_period) + run_bound)` — the retention period condition 2 holds a kind above: the kind's settling period and one run's age past the examine window end. {birth: data}

Term lease spend: `((((2 * read_bound) + (2 * journal_write_bound)) + commit_round_trip) + (9 * pause_bound))` — the invocation's work under its lease on the path with no retry and no lost reply: two re-reads ([Open] step 3, [Close] step 2), two journal writes (the intent, the outcome), the commit, and nine pauses, a reading and the issue behind it counting as one (Durable Intent pause bound 2, Term write floor) — the take, the intent's reading and issue, the commit's reading and issue, the hand from [Open]'s return to the commit, [Close]'s step-1 reading, the outcome's own reading and issue after the re-read (Durable Intent journal write bound 1, Durable Intent pause bound 2), the release, and Lease Sizing 4's two. A retry or a lost reply's read-back runs past it, under the write gate (Durable Intent journal write bound 1), to the terminus, and lands the position's recording-failure arm where the lease runs out (Durable Intent Primitive policy 29, 30). {birth: data}

Term run floor: `(max(invocation_completion_bound, (closure_latency + journal_write_bound)) + closure_latency)`. {birth: data}

Term sweep lease spend: `max((((read_bound + (2 * journal_write_bound)) + probe_round_trip) + (7 * pause_bound)), (((2 * read_bound) + journal_write_bound) + (6 * pause_bound)))` — the sweep's closure, or [Resolve]'s work under the same lease, whichever is longer, each on the path with no retry and no lost reply, its pauses counted as lease spend's: seven for the closure — the take, Sweep reconcile step 2.7's reading, the recovery_intended's reading and issue, the closing's reading and issue, the release, and Lease Sizing 4's two — and six for [Resolve]'s — the take, Escalation resolve 7's reading, the closing's reading and issue, the release, and Lease Sizing 4's two; a retry or a lost reply's read-back runs past it as past lease spend. {birth: data}

```
Instance start 4: The instance MAY start ONLY IF closure window EXCEEDS worst closure. {birth: data}
Instance start 5: The instance MAY start ONLY IF retention period EXCEEDS retention floor. {birth: data}
Instance start 6: The instance MAY start ONLY IF invocation completion bound EXCEEDS lease spend. {birth: data}
Instance start 7: The instance MAY start ONLY IF run floor DOES NOT EXCEED run bound. {birth: data}
Instance start 8: The instance MAY start ONLY IF closure latency EXCEEDS sweep lease spend. {birth: data}
```
Term conditions of instance start: condition 1 is Instance start 4; condition 2 is Instance start 5; condition 3 is Instance start 6; condition 4 is Instance start 7; condition 5 is Instance start 8. {birth: data}

### Where the allowance goes

```
Allowance 2: This section IS AUTHORITATIVE FOR where the allowance is spent. {birth: bond candidate}
NOTE: watch addressable sections (Instance start 1).
Allowance 4: A cross-seam comparison MUST take the allowance at the reading. {birth: bond candidate}
Allowance 6: A cross-seam comparison MAY exclude a record from a pass. {birth: bond candidate}
```
Term cross-seam comparison: a comparison between a reading taken at one seam and a stamp or instant minted at another (Execution Contract Logic confinement 18). {birth: bond candidate}

Six clocks meet on this pattern: the adopter's seam ([Open] step 1 and step 3), the sweep's seam ([Reconcile]), the operator's seam ([Resolve]), the reader's seam ([Read Invocation]), the substrate's recording instant, and the critical section host's expiry instant. One allowance covers every pair, set to cover the widest.

Every cross-seam comparison on this pattern takes the allowance at the reading: [Open]'s age of an open intent, at step 1 and step 3; the retention drop on every read of open invocations; [Resolve]'s too-young guard; the sequence high water advance; the sweep's edges and window; [Read Invocation]'s rebuild. Those that gate a write are read under the critical section the writer holds, after the re-read under it (Durable Intent open step 2.1, Durable Intent open step 3.1, Escalation resolve 4, Escalation resolve 8), and the sweep's edges exclude a record from a pass (Allowance 6).

### Walkthrough — a disclosure, three ways

The adopter is [Immutable Ledger](../../compositions/immutable-ledger.md)'s `disclose_subset`, the pilot adopter, as that pattern binds the kind `ledger.disclosure`:

- act key = `(subject_ref, recipient, scope, authority)` — the minted-key deviation, the disclosure id being minted by the commit.
- commit = `SelectiveDisclosure.record(subject_ref, recipient, scope, authority, disclosed_at = now)`; invalid-request, `unknown-authority-type` and `storage-failure` are pre-commit as the constituent declares them; a lost reply is unknown.
- pairing datum = `disclosed_at`, the seam-injected now, carried in intent data and passed into commit. Selective Disclosure admits no nonce, so the binding declares pairing datum 4's obligation on its host — no equal now injected into two invocations of one act key, on one node or two — with Selective Disclosure's seam given the invocation's own reading (Immutable Ledger Capability requirement 28, Immutable Ledger Capability requirement 25). One way a host meets it is a per-node monotonic source whose low bits carry the node.
- act probe = read Selective Disclosure's records by `subject_ref`, `recipient` and `disclosed_at` as a range of that one instant, and keep, in the adopter's code, the records whose `scope` and authority equal the intent's: `committed(ledger.disclosure.disclosed, {disclosure_id, subject_ref, recipient, scope, authority, disclosed_at})` on exactly one match, not-committed on none, `undecidable(candidates)` on several, unavailable on any read outage — the constituent's `invalid-query` is unavailable to the sweep and surfaced on compliance surface.
- `repeatable = yes`; `invocation_completion_bound = 30 s`; `commit_round_trip = 1 s`; `probe_round_trip = 1 s`; `service_identity = ledger-reconciler`; `settling_period = 7 d`.
- Instance: `sweep_cadence = 60 s`; `clock_allowance = 2 s`; `closure_latency = 12 s`; `run_bound = 135 s` (a backlog of three orphans, sequentially, each at worst one holder's remaining lease and one closure: `3 × (30 + 12) = 126 s`, the balance headroom); `journal_write_bound = 3 s`; `read_bound = 2 s`; `pause_bound = 0.25 s`; `closure_window = 10 min`.

**The five conditions of instance start, against these numbers:**

1. `30 + 2×2 + 2×60 + 3×135 = 559 s < 600 s`.
2. `30 + 2 + 600 + 7 d + 135 < retention_period` — `ledger.disclosure.*` carries a period above seven days and 767 s.
3. `30 s > 2×2 + 2×3 + 1 + 9×0.25 = 13.25 s`.
4. `135 s ≥ max(30, 12 + 3) + 12 = 42 s`.
5. `12 s > 2 + 2×3 + 1 + 7×0.25 = 10.75 s`, the sweep's closure being the longer; [Resolve]'s work is `2×2 + 3 + 6×0.25 = 8.5 s`.

The sweep's lease is `12 + 3 = 15 s`; one closure inside it spends `2 + 1 + 3 + 3 = 9 s` and seven call pauses, clearing the gate — a write floor of `3 + 3×0.25 = 3.75 s` — before both writes. The instance starts.

### Terms

Term external evidence: evidence outside the records, as [Audit Trail](../../compositions/audit-trail.md) declares it. {birth: data}

## Status

`todo` — written by the split of Recoverable Invocation (grace-commons 4c758dc5); the tools read atoms and compositions only, so no tool has read this page yet.

NOTE: End of Recoverable Invocation as an app.
