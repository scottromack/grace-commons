---
title: Verified Repair
parent: Conceptual Compositions
nav_order: 24
has_toc: true
toc: true
---

# Verified Repair

<details markdown="block">
<summary>Table of contents</summary>
{: .text-delta }
1. TOC
{:toc}
</details>

**Composes:** [Recoverable Invocation](./recoverable-invocation.md) · [Audit Trail](./audit-trail.md)

## Intent

A council of agents keeps a canonical page true. It freezes the page, sends verifiers over the frozen bytes — cold readers running one pass each, and formal engines checking the model derived from the page — sorts what they report, repairs what the sort admits, and records each step. Run by people, the loop held because people read what they changed and slept between steps. Run unattended, three things break first. A repair lands on text that moved after it was read. A repair lands on the wrong side, mending the page to fit a model that had fallen behind the page. And the pressure to finish rewards the cheapest repair there is, which is weakening the claim.

Verified Repair is the loop written so that none of the three happens without a rule refusing it. **No change to a canonical page lands unless it answers a reported failure read off one frozen snapshot, sorted twice where a count decides an outcome, aimed at the side the failure indicts, kept out of the page's claims, applied by one writer to the bytes it was read from, and recorded** — so that the whole chain, snapshot to verifier to verdict to finding to triage to patch to diff to commit, reads back from the records alone.

What the composition is not. It is not a verifier: readers and engines are the deployment's, held to the verdict contract here. It is not a judge of meaning: a change to what a page claims is the maintainer's, and so is any easy decision a rule does not settle. It is not a write protocol: every write it makes is a [Recoverable Invocation](./recoverable-invocation.md) act, so the one-writer rule, the intent before the commit, the yield on a lost reply and the sweep after a crash are that page's and are cited here, not restated. And it is not tied to an engine: Alloy, TLA+ and any heavier logic sit beneath one verdict contract, as readers do.

---

## Composes

- **[Recoverable Invocation](./recoverable-invocation.md)** — the protocol of the composition's one irreversible write, a commit to the repository.
- **[Audit Trail](./audit-trail.md)** — the journal of rounds, verdicts, triage records and escalations, and the protocol's journal.

```
Composes 1: EXACTLY ONE Recoverable Invocation instance MUST serve the composition.
Composes 2: EXACTLY ONE Audit Trail instance MUST serve the composition.
Composes 3: The Recoverable Invocation instance MUST journal to the composition's Audit Trail instance.
Composes 4: The composition MUST bind EXACTLY ONE act kind to the Recoverable Invocation instance: council.commit, under the commit binding.
Composes 5: The composition MUST NOT write the repository other than through the act kind council.commit.
Composes 6: The composition MUST record EVERY round, verdict, triage record AND escalation through Audit Trail's record_action.
Composes 7: The composition MUST NOT change a constituent's spec.
```

Term composition: this pattern's wiring of [Recoverable Invocation](./recoverable-invocation.md) and [Audit Trail](./audit-trail.md) — the round, the verdict contract, the triage, the repair and the escalations below.

Term constituents: [Recoverable Invocation](./recoverable-invocation.md), [Audit Trail](./audit-trail.md).

Term commit binding: the act kind's bindings, each under the name Recoverable Invocation gives it. act key — the repository. commit — the repository commit, read through the commit partition. commit fence — none. pairing datum — the invocation id, which the store keeps as the commit's trailer, an adopter-minted nonce the store stores. repeatable — yes. probe — the commit probe. completion bound — the commit completion bound. commit round trip and probe round trip — the deployment's disclosed bounds. journal — the composition's Audit Trail instance, with council.commit.intended, the one outcome council.commit.committed, and council.commit.refused. retention period — the journal retention policy's. service identity — the sweep identity. outcome envelope — the commit envelope. retry terminus — lease. Deviations: none.

Term commit partition: committed — the store answers a commit id; pre-commit — the store refuses with nothing written, carrying lock-held, conflict OR hook-rejected; unknown — no answer, or a reply the store's contract does not declare.

Term commit probe: the repository read of the commits from the snapshot's base commit to the head, kept to the commits whose trailer carries the intent's invocation id — committed carrying council.commit.committed and the commit id where exactly one does, not-committed where none does, undecidable carrying the commit ids where more than one does, and unavailable where the read refuses or gives no answer.

Term commit envelope: the largest outcome the kind writes — the commit id, the snapshot hash, the base commit, the round id and the patch ids at the reference length cap each, the patch ids capped by the patch cap.

WHY:
**The repository is the store and the commit is the act** (Composes 4, 5). The one thing the council does that cannot be taken back is a commit, so the commit is the bound commit of the protocol, keyed by the repository because a repository has one head and two commits in flight on it are one writer too many. The invocation id rides the commit as a trailer, so a sweep that finds an intent with no closing reads the repository for the trailer and learns whether the commit landed — the store keeps the nonce, which is the pairing the protocol admits without a reading of now (Recoverable Invocation pairing datum 1, 2). A commit is never removed (Capability requirement 11), so no outcome outlives the record it names (Recoverable Invocation Binding 9).

---

## Composition logic

### Composition state

```
Composition state 1: The composition MUST rebuild the round index, the triage index AND the round count from the journal's range read.
Composition state 2: The journal MUST hold EVERY round, verdict AND triage record the composition keeps.
```

Term round index: map from a page to the page's open round — the snapshot and the passes reported against it. Derived index.

Term triage index: map from a round to the round's triage records, each first and second triage kept apart. Derived index.

Term round count: map from a page to the number of rounds the page has run since the page's last clean round. Derived index.

WHY:
Every element is rebuilt from the journal, so a council that restarts reads where it stood from the records and from nothing it remembered (the section titled Composition state in `execution-contract.md`). The snapshot lives in the round's record, the base commit and the content hash together, so the bytes a verdict was about can be named after the fact by anyone holding the repository.

### Capability requirement

```
Capability requirement 1: A deployment MUST supply a repository whose commit answers EXACTLY ONE OF a commit id, a refusal with nothing written.
Capability requirement 2: A deployment MUST supply a repository read that finds a commit by a trailer value.
Capability requirement 3: A deployment MUST supply EVERY reader the snapshot's bytes AND the permitted ranges alone.
Capability requirement 4: A deployment MUST NOT supply a reader the lines of a page that follow the page's Status heading.
Capability requirement 5: A deployment MUST NOT supply a reader the record of an earlier round of the page.
Capability requirement 6: A deployment MUST supply EVERY formal engine the model derived from the snapshot, the model's buggy twin AND the bound the run explores.
Capability requirement 7: A deployment MUST disclose the round budget, the patch cap, the commit completion bound, the commit round trip AND the probe round trip.
Capability requirement 8: A deployment MUST supply the maintainer's queue.
Capability requirement 9: A deployment MUST supply the corpus gate.
Capability requirement 10: A deployment MUST provision the sweep identity apart from EVERY other writer of the journal (Recoverable Invocation service identity 3).
Capability requirement 11: The repository MUST NOT remove a commit.
Capability requirement 12: The repository MUST NOT accept a push from the composition.
```

Term repository: the version-controlled store holding the canonical pages — one head, commits that carry trailers, and a read by trailer.

Term reader: a verifier that is a language model or a person running one pass of the method on a snapshot, having read no earlier round of the page.

Term formal engine: a verifier that checks the model derived from a page — Alloy, TLA+, or a heavier logic a property requires — through an adapter that answers the verdict contract.

Term verifier: a reader OR a formal engine.

Term maintainer: the person who holds the corpus's semantic authority.

Term maintainer's queue: the surface the maintainer reads escalations from, each carrying the round, the finding and the one line that asks.

Term corpus gate: the deployment's whole-corpus surface check — `python3 tools/grace/check.py --gate` in this repository — answering a finding count.

Term round budget: the most rounds a page may run without a clean round before the composition escalates the page.

Term patch cap: the most patches one commit may carry.

Term admitted freeze: a [Freeze] call no rule refused.

Term admitted report: a [Report] call no rule refused.

Term admitted repair: a [Repair] call no rule refused before the invocation open.

Term writer: the council's one writer to the repository, under the writer's own actor reference and credential; the sweep identity is not the writer.

Term diff check: Action wiring 25's comparison of the working copy's diff with the change set.

Term sweep identity: the commit binding's service identity, under which Recoverable Invocation's sweep closes a council commit whose invocation died.

WHY:
**Cold is a capability** (Capability requirement 3 through 5). A reader who has seen the Ledger re-finds nothing it lists and promotes nothing it hides, so its count is about the Ledger and not about the page; the composition cannot see what a reader was handed, so the deployment supplies the cold read and External check 1 is where an auditor clears it. **An engine without a twin proves nothing** (Capability requirement 6): a model that passes because its checks are vacuous passes for every page, and the twin the checker rejects is what makes the pass mean something (the section titled The formal-layer vote in `pressure-testing.md`). **The council never publishes** (Capability requirement 12): a commit stays where the maintainer can read it before anyone else can.

### Primitive policy

```
Primitive policy 1: IF the page OR the base commit EQUALS blank THEN [Freeze] MUST answer invalid-request.
Primitive policy 2: IF the page IS NOT IN the repository at the base commit THEN [Freeze] MUST answer not-known.
Primitive policy 3: IF a verdict carries no snapshot hash, no base commit OR no verifier THEN [Report] MUST answer invalid-request.
Primitive policy 4: IF a patch carries no target OR no new fragment THEN [Repair] MUST answer invalid-request.
Primitive policy 5: IF the count of a commit's patches EXCEEDS the patch cap THEN [Repair] MUST answer invalid-request.
Primitive policy 6: The composition MUST compare a snapshot hash, a commit id AND a fragment byte-exact.
Primitive policy 7: IF the repository's name OR the writer's actor reference EXCEEDS the reference length cap THEN [Repair] MUST answer invalid-request (Recoverable Invocation Primitive policy 1, 8).
Primitive policy 8: An action refused under Primitive policy MUST NOT write.
```

### Action wiring

```
freeze(page, base_commit)
  answers snapshot
  refuses invalid-request | not-known | dirty | journal-unavailable

report(round, verdict)
  answers recorded
  refuses invalid-request | stale | round-closed | journal-unavailable

triage(round, finding, triager, record)
  answers recorded
  refuses invalid-request | stale | journal-unavailable

repair(round, patches, actor_ref, credential)
  answers commit id
  refuses invalid-request | stale | unresolved | mismatch | gated | budget-spent | gate-red | act-in-flight(invocation_id) | section-unavailable | journal-unavailable | recording-failure(intent) | recording-failure(outcome, invocation_id) | recording-failure(refusal, constituent_code)
```

#### [Freeze]

```
Action wiring 1: IF the working copy's page differs from the page at the base commit THEN [Freeze] MUST answer dirty.
Action wiring 2: An admitted freeze MUST record the round with the page, the base commit AND the snapshot hash.
Action wiring 3: An admitted freeze MUST answer the snapshot: the snapshot hash AND the base commit.
```

#### [Report]

```
Action wiring 4: IF the verdict's snapshot hash DOES NOT EQUAL the round's snapshot hash THEN [Report] MUST answer stale.
Action wiring 5: IF the round carries three counted verdicts THEN [Report] MUST answer round-closed.
Action wiring 6: IF the verdict carries malformed THEN [Report] MUST escalate the verdict to the maintainer's queue.
Action wiring 7: An admitted report MUST record the verdict.
```

#### [Triage]

```
Action wiring 8: A triage record MUST carry the finding's class, kind, blame, side AND disposition.
Action wiring 9: A triage record's side MUST carry model where the finding came from a formal engine AND the record states no reason the model is right.
Action wiring 10: A triage record MUST carry the triager.
Action wiring 11: The composition MUST NOT record a deciding count BEFORE a second triager has triaged EVERY finding the round's verdicts carry.
Action wiring 12: The second triager's brief MUST carry the findings, the first triage's downgraded and rejected findings, the method's test AND the blame rule.
Action wiring 13: The second triager's brief MUST NOT carry the threshold the count is read against.
Action wiring 14: IF the two triages part on a finding THEN the composition MUST record both triages AND the text that settles the finding.
```

Term class: foundational | refining | rhetorical — as the section titled What "grounded" means in `pressure-testing.md` defines each.

Term kind: A | B | C | D — the triage fields of `pressure-testing.md`.

Term blame: fresh | older — fresh where the site was written or changed within the page's last two rounds.

Term side: model | english | both — which text a finding indicts: the derived model, the page, or the two.

Term disposition: cure | route | reject | decline — cure for a kind-A finding, route for kind B or C, decline for kind D, reject where the text already answers it.

Term deciding count: a count an outcome turns on — the foundational count of a round that would be clean, the count a pre-registered rule reads.

Term triager: the agent OR person that sorts a finding.

#### [Repair]

```
Action wiring 15: IF the working copy's page DOES NOT EQUAL the snapshot's bytes THEN [Repair] MUST answer stale.
Action wiring 16: IF the repository's head DOES NOT EQUAL the round's base commit THEN [Repair] MUST answer stale.
Action wiring 17: IF the count of sites a patch's target resolves to DOES NOT EQUAL one THEN [Repair] MUST answer unresolved.
Action wiring 18: IF a patch's old fragment IS NOT IN the resolved site verbatim THEN [Repair] MUST answer mismatch.
Action wiring 19: IF a patch's target IS IN the claim families THEN [Repair] MUST answer gated.
Action wiring 20: IF a patch answers a finding whose side EQUALS model THEN [Repair] MUST answer gated.
Action wiring 21: IF the round count EXCEEDS the round budget THEN [Repair] MUST answer budget-spent.
Action wiring 22: An admitted repair MUST call the invocation open with the act kind, the repository as the act key, the writer's actor reference AND credential, AND the round, the snapshot AND the patch ids as intent data.
Action wiring 23: An admitted repair MUST apply EVERY patch to the working copy as one change.
Action wiring 24: IF the corpus gate's finding count over the changed working copy EXCEEDS zero THEN [Repair] MUST answer gate-red AND restore the snapshot's bytes.
Action wiring 25: IF the working copy's diff DOES NOT EQUAL the change set THEN [Repair] MUST answer mismatch AND restore the snapshot's bytes.
Action wiring 26: An admitted repair MUST commit the working copy with the invocation id as the commit's trailer.
Action wiring 27: IF the commit answers a commit id THEN [Repair] MUST call the invocation close with the act kind, the act key, the invocation pair, the writer's actor reference AND credential, council.commit.committed AND the commit envelope.
Action wiring 28: IF the commit refuses THEN [Repair] MUST call the invocation refusal with the act kind, the act key, the invocation pair, the writer's actor reference AND credential, AND the store's refusal as the reason AND as the constituent code.
Action wiring 29: IF the commit gives no answer THEN [Repair] MUST call the invocation yield with the act kind, the act key AND the invocation id, carrying lost.
Action wiring 30: IF [Repair] answers gated OR budget-spent THEN [Repair] MUST escalate the patch to the maintainer's queue.
Action wiring 31: [Repair] MUST NOT call the invocation open BEFORE the round's three verdicts are counted.
Action wiring 32: [Repair] MUST NOT push.
Action wiring 33: [Repair] MUST NOT call the invocation open BEFORE the corpus gate AND the diff check have answered over the changed working copy.
```

Term patch: a target, an old fragment and a new fragment for each sentence the change touches — the rule or Term the finding sits in and every sentence on the page that restates it — with the finding it answers.

Term claim families: Invariant, Check, External check — the page's claims.

Term round's records: the Ledger lines, the last gate line, the Decisions entry and the status the round owes, written by the council.

Term change set: the accepted patches' fragments and the round's records — every line a council commit may change.

WHY:
**Every check is evaluated by the writer, from what the writer holds** (Action wiring 15 through 21). The writer holds the snapshot from the round's record, the head from the repository, the patch from the triager, and the round count from the journal; no precondition asks it to know what a verifier thought. **A patch is the rule and every sentence that restates it** (Term patch): a third of one round's findings in this corpus were sentences left saying what a rule used to say, so the exact-diff check (Action wiring 25) compares the commit with the whole set and not with one fragment. **The side decides the target** (Action wiring 9, 20): a model is derived and falls behind the page, and a counterexample read straight into a page patch mends the truth to match its shadow; a finding from an engine is the model's until the triage record says why the model is right.

### Wiring decision

```
Wiring decision 1: The composition MUST NOT change a page between two passes of one round.
Wiring decision 2: The composition MUST NOT change a rule in the claim families without the maintainer's recorded ruling.
```

WHY:
*Principle.* A count is about one text, and a claim is the maintainer's. *Likely objection.* Repairing as findings arrive is faster, and an invariant the engine breaks is the invariant that is wrong. *Mechanism that resolves it.* Three passes over moving text is a search, not a round: each pass reads a text the last pass never saw, so no count compares with another (the section titled Order and iteration in `pressure-testing.md`). And the cheapest way to make an engine stop finding a counterexample is to weaken the claim it checks; a loop under pressure to converge will find that way if a rule does not close it. *Result.* Repairs land between rounds, after the third pass, on the text all three read; a patch into an Invariant, a Check or an External check stops at the maintainer's queue whatever the round count.

### Verdict

```
Verdict 1: A verdict MUST carry EXACTLY ONE OF holds, counterexample, malformed.
Verdict 2: A verdict MUST carry the snapshot hash, the base commit AND the verifier.
Verdict 3: A counterexample MUST carry EVERY foundational finding the verifier reports, each with the finding's site AND trace.
Verdict 4: A reader's verdict MUST carry holds where the reader reports no foundational finding.
Verdict 5: A reader's verdict MUST carry malformed where the reader read outside the permitted ranges.
Verdict 6: IF the model fails to compile, fails to type-check OR has no initial state THEN a formal engine's verdict MUST carry malformed.
Verdict 7: A formal engine's verdict MAY carry holds ONLY IF the buggy twin's run carried counterexample AND the explored state count stopped growing inside the bound.
Verdict 8: A formal engine's holds MUST carry the bound the run explored.
Verdict 9: A malformed verdict MUST NOT count toward a round.
```

Term holds: the verdict that the verifier found no foundational finding — for a formal engine, within the bound it names and no further.

Term counterexample: the verdict carrying one or more foundational findings, each with a site and a trace.

Term malformed: the verdict that nothing was verified — a model that did not compile, a reader that read past its permitted ranges, an answer outside the contract.

Term finding: one failure a verifier reports — the site (the labels of the rules or Terms it sits in), the trace, and the reporter's class and kind.

Term site: the rule labels and Term names a finding sits in — a label that never renumbers, a retired label surviving as a tombstone (GRACE-lang Hard invariant 26, 27).

WHY:
**Three answers, and one of them is not a failure** (Verdict 1, 9). A model that did not compile has no counterexample in it, and a reader who saw the Ledger has read a different text; either one, repaired against, produces a patch for a failure nobody found. Malformed goes to the maintainer and counts toward nothing (Action wiring 6). **Holds is a sample, not a proof**: a reader's holds is one draw (the entry *A clean round is a sample* in `pressure-testing.md`), and an engine's holds is good inside the bound it names (Verdict 8).

---

## Composition-level invariants

- **Invariant 1 — One text per round.**
  ```
  Invariant 1.1: A council commit MUST NOT change a page between two passes of one round.
  Invariant 1.2: A verdict MUST count toward a round ONLY IF the verdict carries the round's snapshot hash.
  ```
  WHY: the round's count is about the snapshot every pass read. *Rests on* Wiring decision 1, Action wiring 4 and 31.
- **Invariant 2 — A repair lands on the bytes the round read.**
  ```
  Invariant 2.1: EVERY council commit MUST change a page whose bytes at the commit's parent EQUAL the round's snapshot.
  Invariant 2.2: EVERY line a council commit changes MUST belong to the round's change set.
  ```
  WHY: no stale mutation and no stowaway. *Rests on* Action wiring 15, 16, 25 and Recoverable Invocation's one writer per act key.
- **Invariant 3 — Claims are the maintainer's.**
  ```
  Invariant 3.1: A council commit MUST NOT change a rule in the claim families without the maintainer's recorded ruling.
  ```
  WHY: the claims are what the page is for. *Rests on* Wiring decision 2 and Action wiring 19.
- **Invariant 4 — A repair answers the side indicted.**
  ```
  Invariant 4.1: A council commit MUST NOT change a page for a finding whose side EQUALS model.
  ```
  WHY: a derived model falls behind the page it was derived from. *Rests on* Action wiring 9 and 20.
- **Invariant 5 — A deciding count is sorted twice.**
  ```
  Invariant 5.1: EVERY deciding count MUST rest on two triages of EVERY finding the round's verdicts carry, the second blind to the threshold.
  ```
  WHY: a count that decides an outcome is the count a triager is most tempted by. *Rests on* Action wiring 11 through 14.
- **Invariant 6 — Nothing repairs a failure nobody found.**
  ```
  Invariant 6.1: A council commit MUST NOT answer a malformed verdict.
  ```
  WHY: a model that did not compile has nothing in it to repair. *Rests on* Verdict 9 and Action wiring 6.
- **Invariant 7 — Every commit reads back.**
  ```
  Invariant 7.1: EVERY council commit MUST carry the invocation id whose intent names the round, the snapshot AND the patches.
  ```
  WHY: from a commit to its intent, from the intent to its round, from the round to its verdicts and triage records. *Rests on* Action wiring 22, 26 and Recoverable Invocation Invariant 1.
- **Invariant 8 — Repair is bounded.**
  ```
  Invariant 8.1: IF a page's round count EXCEEDS the round budget THEN the composition MUST NOT run a round on the page BEFORE recording the maintainer's ruling.
  ```
  WHY: a page that does not converge is a decision for a person. *Rests on* Action wiring 21 and 30.

---

## Examples

### Walkthrough — a clean round grounds a page

The council freezes `compositions/immutable-transaction-ledger.md` at base commit `2f1b5c1`: [Freeze] finds the working copy's page equal to the page at that commit and records round `r-14` with snapshot hash `a1a6621b…`. Three readers, none of whom has read an earlier round, run GRID, EOS with the builder's reading, and Linus; each verdict carries `a1a6621b…`, so each counts (Invariant 1.2). The verdicts are holds, holds and counterexample — one foundational finding, an operator's closing never sized. The foundational count of a round that would be clean is a deciding count, so the finding goes to a second triager whose brief carries the finding, the method's test and the blame rule, and not the threshold (Action wiring 11 through 13). The second triager rejects it — the protocol's open sizes against the kind's largest record, which Term true maximum on [Recoverable Invocation](./recoverable-invocation.md) makes the operator's closing too — the first triager checks that text and agrees, and both triages and the settling text are recorded (Action wiring 14). The round is clean. [Repair] then carries the round's records and the refining cures that add no rule: the head is still `2f1b5c1`, every target resolves to one site, every old fragment is found verbatim, none sits in the claim families, the gate answers zero, the diff is exactly the patches and the records, and the commit lands with the invocation id as its trailer.

### Rejection path — the page moved under the round

A person edits one of the page's capability requirements by hand while round `r-15` is between its second and third passes. The third reader's verdict still carries the snapshot hash it was given, so it counts; but [Repair] reads the working copy, finds the page no longer equal to the snapshot, and answers stale (Action wiring 15). Nothing is written, and the round's patches are void: they were sorted against a text that no longer exists.

### Rejection path — the engine indicts an invariant

A TLA+ run on the derived model returns a counterexample against the model's rendering of Immutable Transaction Ledger Invariant 1.3. The triage record carries side model, since no record states why the model is right; [Repair] answers gated for a page patch (Action wiring 20), and the cure goes to the model's re-derivation. Had the triager shown the model faithful and proposed weakening Immutable Transaction Ledger Invariant 1.3 instead, [Repair] would still answer gated (Action wiring 19), and the patch would wait in the maintainer's queue.

### Rejection path — the model did not compile

An Alloy adapter answers malformed: the derived model fails to type-check. [Report] escalates the verdict (Action wiring 6); no triage runs, no patch is proposed, and the round's count does not move (Verdict 9).

### Regulated adversarial scenarios

**Regulator audit — "show me every automated change to this page and why it was made."** The auditor reads the repository's commits by the council's trailer and, for each, the intent the trailer names (Invariant 7.1): the round, the snapshot, the patches. From the round, the journal answers the verdicts with their verifiers, the triage records with both triagers where a count decided, and the findings each patch answers. A change with no trailer is not the council's; a council commit whose diff holds a line no patch and no record accounts for fails Check 2.2.

**Disputed change — "I never authorized that change to an invariant."** A council commit cannot change a rule in the claim families without the maintainer's recorded ruling (Invariant 3.1). The rebuttal is the ruling: the journal record under the maintainer's own credential, naming the patch. A claim-family change with no such record is a conformance failure Check 3.1 finds.

**Breach investigation — "the council's credential was compromised; what could it have done?"** It could commit, and every commit it made carries a trailer whose intent stands in the journal under the council's attestation; a commit with a council trailer and no intent is a write outside this composition. It could not push (Capability requirement 12), and it could not have changed a claim without a ruling only the maintainer's credential attests. The forensic window is bounded by the journal: every intent, closing and escalation is sealed and attributed by [Audit Trail](./audit-trail.md).

---

## Generation acceptance

### Conformance checks

```
Check 1.1: An auditor MUST find no council commit changing a page between two verdicts of one round (Invariant 1.1).
Check 1.2: An auditor MUST find EVERY counted verdict carrying the round's snapshot hash (Invariant 1.2).
Check 2.1: An auditor MUST find EVERY council commit's parent carrying the round's snapshot bytes for the page (Invariant 2.1).
Check 2.2: An auditor MUST find EVERY line a council commit changes in the round's change set (Invariant 2.2).
Check 3.1: An auditor MUST find a maintainer's ruling for EVERY council commit changing a rule in the claim families (Invariant 3.1).
Check 4.1: An auditor MUST find no council commit's page patch answering a finding whose side EQUALS model (Invariant 4.1).
Check 5.1: An auditor MUST find two triages for EVERY finding the verdicts of a round with a recorded deciding count carry (Invariant 5.1).
Check 6.1: An auditor MUST find no council commit answering a malformed verdict (Invariant 6.1).
Check 7.1: An auditor MUST find EVERY council commit's trailer naming an intent in the journal (Invariant 7.1).
Check 8.1: An auditor MUST find a maintainer's ruling for EVERY round a page ran with a round count that EXCEEDS the round budget (Invariant 8.1).
```

NOTE: EVERY check names the rule the check tests.

### External checks

```
External check 1: An auditor MUST clear from external evidence that EVERY reader read the snapshot cold (Capability requirement 3 through 5).
External check 2: An auditor MUST clear from external evidence that EVERY formal engine's holds came with the buggy twin rejected (Verdict 7).
External check 3: An auditor MUST clear from external evidence that the second triager's brief carried no threshold (Action wiring 13).
External check 4: An auditor MUST clear from external evidence that the repository took no push from the composition (Capability requirement 12).
```

WHY:
The checks read the repository and the journal and nothing else. What the records cannot show is what a verifier was handed: a brief is not a record of this composition, so cold reading, a twin's run and a blind brief are cleared from the deployment's own evidence.

---

## Non-goals

```
Non-goal 1: The composition MUST NOT judge a page's meaning.
Non-goal 2: The composition MUST NOT choose the next page to verify.
Non-goal 3: The composition MUST NOT publish a commit.
Non-goal 4: The composition MUST NOT run a verifier's internals.
Non-goal 5: The composition MUST NOT privilege a formal engine.
```

WHY:
Meaning is the maintainer's, and so is the order of the work (the roadmap is its single source). Publishing is a person's act. A verifier is the deployment's, held to the verdict contract; an engine is one adapter among several, and no repair loop may swap the engine that found a failure for one that does not.

---

## Edge cases

### Concurrency

```
Concurrency 1: Two [Repair] calls on one repository MUST serialize on the act's critical section (Recoverable Invocation open step 2.1).
```

WHY: one repository has one head; the protocol's one writer per act key is the whole answer.

### Indeterminate outcome

```
Indeterminate outcome 1: Recoverable Invocation's sweep MUST close a council commit whose reply was lost, through the commit probe.
Indeterminate outcome 2: [Freeze] MUST answer dirty for a page a crashed [Repair] left changed and uncommitted.
```

WHY: a commit that landed with its reply lost carries its trailer, so the probe finds it; a working copy a crash left half-changed is not the snapshot, and the next round cannot start on it until a person or the next [Repair] restores it.

---

## Terms

Each `[Term]` marker above links to its term entry here.

### Vocabulary

Term actors: the composition; the constituents; the deployment; the council; the writer; a reader; a formal engine; a verifier; a triager; the second triager; the maintainer; an auditor; the sweep.

Term records: the rounds, verdicts, triage records and escalations the composition records through the audit write; the intents, outcomes, refusals, recovery intents and escalations Recoverable Invocation writes for the act kind council.commit.

Term record verbs: clear, answer, apply, bind, call, carry, change, commit, compare, count, disclose, escalate, find, freeze, journal, provision, push, publish, rebuild, record, refuse, remove, rest, restore, run, serialize, serve, supply, triage, write, accept, belong, privilege, judge, choose, close, hold.

Term value sets: verdict = holds | counterexample | malformed. class = foundational | refining | rhetorical. kind = A | B | C | D. blame = fresh | older. side = model | english | both. disposition = cure | route | reject | decline. action reference = council.round | council.verdict | council.triage | council.escalation | council.commit.intended | council.commit.committed | council.commit.refused | council.commit.recovery_intended | council.commit.abandoned | council.commit.escalated.

Term bounds: round budget (round_budget), patch cap (patch_cap), commit completion bound (commit_completion_bound), commit round trip (commit_round_trip), probe round trip (probe_round_trip).

Term qualifiers: migrated — written in GRACE lang v0.63 from the first draft (2026-10-10).

Term terms: writer, diff check, admitted freeze, admitted report, admitted repair, change set, snapshot, snapshot hash, base commit, round, search, clean round, working copy, page, finding, site, patch, claim families, side, deciding count, round's records, maintainer's queue, round budget, patch cap, sweep identity, commit binding, commit partition, commit probe, commit envelope.

Term snapshot: a page's bytes at a base commit, named by the base commit and the snapshot hash.

Term snapshot hash: the SHA-256 of the page's bytes at the base commit.

Term base commit: the repository commit a round's snapshot was taken from.

Term working copy: the repository's checked-out files the writer changes and commits.

Term page: a canonical document under the repository — a pattern file.

Term round: three passes — GRID, EOS with the builder's reading, Linus — by three readers, over one snapshot, with no change to the page between them.

Term search: passes over a page a change moved between them; it counts toward nothing.

Term clean round: a round whose deciding count of foundational findings is zero.

Term cited: open, close, refuse, yield, act kind, act key, commit, commit fence, pairing datum, repeatable, probe, completion bound, commit round trip, probe round trip, journal, retention period, service identity, outcome envelope, retry terminus, critical section, act-in-flight, section-unavailable, journal-unavailable, recording-failure, true maximum: Recoverable Invocation. record_action, range read, reference length cap: Audit Trail. Hard invariant 26, Hard invariant 27: GRACE-lang. The entry A clean round is a sample, and the sections titled Order and iteration, The formal-layer vote and What "grounded" means: `pressure-testing.md`. The section titled Composition state: `execution-contract.md`.

#### Freeze

The action that opens a round: it checks that the working copy's page equals the page at the base commit, records the round, and answers the snapshot every verdict of the round must carry.

Kind: Operation

#### Report

The action that records one verifier's verdict against a round's snapshot, refuses a verdict about other bytes, and escalates a malformed one.

Kind: Operation

#### Triage

The action that records one triager's sorting of one finding — class, kind, blame, side and disposition — first and, where a count decides an outcome, second and blind.

Kind: Operation

#### Repair

The action through which the council writes: it checks every precondition against the round's snapshot and the repository's head, applies the round's accepted patches and records as one change, runs the corpus gate, checks the diff, and commits through [Recoverable Invocation](./recoverable-invocation.md) with the invocation id as the commit's trailer.

Kind: Operation

<!-- Term registry — shortcut-reference definitions. -->

[Freeze]: #freeze
[Report]: #report
[Triage]: #triage
[Repair]: #repair

## Standards references

None. The composition makes no regulatory claim of its own; the records it keeps are [Audit Trail](./audit-trail.md)'s, and a deployment that needs a standard's evidence reads that page's references.

## Status

`draft` — see the Ledger.

## Ledger

```
status: draft
formal: pending — vote yes: one writer per repository, no change between passes and the round's bounded repair are ordering and safety claims; no model is drafted
last gate: none
open:
- 2026-10-10-a · refining · the whole page · drafted from the grind that grounded Immutable Transaction Ledger and from Grok's verification-loop draft with GLM's three closures; no pass has read it → a round of three passes on the frozen page
- 2026-10-10-b · refining · Term repository · the store the act commits to is a deployment's version-controlled repository, which no atom in this library owns → an atom for a versioned store, or the store's contract kept here
```

## Decisions

Directional changes only. Everything smaller lives in the commit that made it: `git log -- compositions/verified-repair.md`.

- **2026-10-10 — The council written as a page before any runtime installs it.** *Chose:* the repair loop as a composition of Recoverable Invocation and Audit Trail — every commit an act of the protocol, keyed by the repository, paired by the invocation id in the commit's trailer; one verdict contract for readers and engines; a triage record carrying the side a finding indicts; claims gated to the maintainer; deciding counts triaged twice, the second blind to the threshold. *Over:* a loop that commits a patch as its own write, outside the protocol, and an exact diff of one fragment. *Because:* the maintainer ruled that the process is part of the process, and every rule here is one the manual grind paid for, written where the machine that will run it can be held to it.

NOTE: End of Verified Repair.
