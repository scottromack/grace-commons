---
title: Verified Repair
id: 27
audience: internal
parent: Conceptual Compositions
nav_order: 24
has_toc: true
toc: true
---

# Verified Repair

<details markdown="block">
<summary>Table of contents</summary>
{: .text-xs .font-medium .uppercase .tracking-wide .opacity-50 }
1. TOC
{:toc}
</details>

**Composes:** [Recoverable Invocation](./recoverable-invocation.md) · [Audit Trail](./audit-trail.md)

## Summary

Verified Repair is the rulebook for a council of automated reviewers that keeps a library's patterns correct while nobody is watching. In each round it freezes one exact copy of a pattern, has independent cold readers and automatic checkers (programs that test a mathematical model built from the frozen copy) report the failures they find in that copy, sorts their reports, and lets through only the fixes the sorting admits, recording every step. It is a composition, a pattern built by wiring simpler patterns together: [Recoverable Invocation](./recoverable-invocation.md) carries each fix into the pattern's version history, writing down what it is about to do before it does it, so that a crash or a lost reply never applies a fix twice, and [Audit Trail](./audit-trail.md) keeps the record of every round, report, decision and fix, tying each entry to whoever made it and sealing it so that any later alteration can be detected. Wired together, they let no change land on a pattern unless it answers a failure reported against the frozen copy or is the round's own record, lands after the round has settled and on the very text the cold readers read, never mends the pattern to fit a model that had fallen behind it, and never touches what the pattern claims without a recorded ruling by its maintainer, the person responsible for the library. Where a count of zero decides that a round found nothing serious, the reports are sorted twice, the second time by someone who does not know where the line falls, and past a set number of rounds on one pattern a further round counts only by the maintainer's ruling. Every saved change points to a record that names its round and the frozen copy and holds every fix it applied, so the whole chain from frozen copy to saved change can be shown from the records alone.

---

## Intent

A council of agents keeps a canonical pattern true. It freezes the pattern, sends verifiers over the frozen bytes — cold readers running one pass each, and formal engines checking the model derived from the pattern — sorts what they report, repairs what the sort admits, and records each step. Run by people, the loop held because people read what they changed and slept between steps. Run unattended, three things break first. A repair lands on text that moved after it was read. A repair lands on the wrong side, mending the pattern to fit a model that had fallen behind the pattern. And the pressure to finish rewards the cheapest repair there is, which is weakening the claim.

Verified Repair is the loop written so that none of the three happens without a rule refusing it. **No change to a canonical pattern lands unless it answers a reported failure, or is the round's own record, read off one frozen snapshot, sorted twice where a zero count decides a round clean, aimed at the side the failure indicts, kept out of the pattern's claims unless the maintainer has ruled on it, applied by the council writer to the bytes it was read from, and recorded** — so that the whole chain, snapshot to verifier to verdict to finding to triage to patch to diff to commit, is provable.

What the composition is not. It is not a verifier: cold readers and engines are the deployment's, held to the verdict contract here. It is not a judge of meaning: a change to what a pattern claims is the maintainer's, and so is any easy decision a rule does not settle. It is not a write protocol: every commit it makes is a [Recoverable Invocation](./recoverable-invocation.md) act, so the one-writer rule, the intent before the commit, the yield on a lost reply and the sweep after a crash are that pattern's and are cited here, not restated. And it is not tied to an engine: Alloy, TLA+ (the Temporal Logic of Actions, a language for specifying a system as its states and the steps between them, which a model checker explores) and any heavier logic sit beneath one verdict contract, as cold readers do.

---

## Composes

- **[Recoverable Invocation](./recoverable-invocation.md)** — the protocol of the composition's one irreversible write, a commit to the repository.
- **[Audit Trail](./audit-trail.md)** — the journal of rounds, verdicts, triage records, rulings and escalations, and the protocol's journal; the journal's enumeration is read from the Event Log instance it carries (Composes 8).

```
Composes 1: EXACTLY ONE Recoverable Invocation instance MUST serve the composition.
Composes 2: EXACTLY ONE Audit Trail instance MUST serve the composition.
Composes 3: The Recoverable Invocation instance MUST journal to the composition's Audit Trail instance.
Composes 4: The composition MUST bind EXACTLY ONE act kind to the Recoverable Invocation instance: council.commit, under the commit binding.
Composes 5: The composition MUST NOT write the repository other than through the act kind council.commit.
Composes 6: The composition MUST record EVERY round, verdict, triage record, ruling AND escalation through Audit Trail's record_action, the round under the action reference council.round, the verdict under council.verdict, the triage record under council.triage, the ruling under council.ruling AND the escalation under council.escalation.
Composes 7: The composition MUST NOT change a constituent's contract other than through a round on the constituent's pattern.
Composes 8: The composition MUST call Event Log's read by sequence-number range on the Event Log instance the wired Audit Trail instance carries, ONLY as the journal's full enumeration (Capability requirement 31), as a declared direct invocation of a substrate constituent's own declared query (the section titled Instance topology is declared in `execution-contract.md`).
```

Term composition: this pattern's wiring of [Recoverable Invocation](./recoverable-invocation.md) and [Audit Trail](./audit-trail.md) — the round, the verdict contract, the triage, the repair and the escalations below.

Term constituents: [Recoverable Invocation](./recoverable-invocation.md), [Audit Trail](./audit-trail.md).

Term commit binding: the act kind's bindings, each under the name Recoverable Invocation gives it. act key — the repository. commit — the repository commit, read through the commit partition. pairing datum — the council nonce, which the intent data carries and the database keeps in the commit's trailer: an adopter-minted nonce the database stores. repeatable — yes. act probe — the commit probe. invocation completion bound — the commit completion bound. commit round trip and probe round trip — the deployment's disclosed bounds. journal — the composition's Audit Trail instance, with council.commit.intended, the one outcome council.commit.committed, and council.commit.refused, the closings council.commit.recovery_intended, council.commit.abandoned and council.commit.escalated derived from the vocabulary (Recoverable Invocation journal 3). retention period — the journal retention policy's, which places every council record under the same policy as the act kind's (Capability requirement 17). settling period — the deployment's settling period for the maintainer's resolve (Capability requirement 14). service identity — the sweep identity. outcome envelope — the commit envelope. Deviations: none.

Term commit partition: committed — the database answers a commit id; pre-commit — the database refuses with nothing written, carrying lock-held, conflict where the head is not the commit's parent (Capability requirement 13) OR hook-rejected — the codes the database's contract declares pre-commit (Capability requirement 15); unknown — no answer, or a reply the database's contract does not declare.

Term commit probe: the repository's read by trailer value (Capability requirement 2) for the commits whose trailer carries the intent's council nonce — committed carrying council.commit.committed and the commit id where exactly one does, not-committed where none does, undecidable carrying the commit ids where more than one does, and unavailable where the read refuses or gives no answer; Capability requirement 19 keeps the undecidable arm empty for a conforming repository, and the arm stands as Recoverable Invocation's act probe names it. The read is scoped to the act key's repository, so every commit it finds carries the act key by construction (Recoverable Invocation act probe 8).

Term commit envelope: the act kind's outcome envelope — the true maximum of the records the kind writes: the committed outcome, one commit id at its minted width, or a closing the sweep or the maintainer writes, whichever the substrate sizes largest, serialized as the substrate sizes it; the database candidates of a council.commit.escalated hold at most one commit, since no two commits carry one council nonce (Capability requirement 19). The intent, which alone carries the round key, the snapshot hash, every patch whole and the council nonce, is sized beside it by the invocation open (Recoverable Invocation Primitive policy 12).

Term council nonce: the nonce injected at the council writer's seam for one [Repair] call, carried by no earlier council.commit intent and by no earlier commit of the repository (Capability requirement 19, 21) — the act kind's pairing datum, carried in the intent data and in the commit's trailer.

Term council commit: a commit of the repository carrying a council trailer; no action undoes it, since a later round's repair offsets it and the repository never removes a commit (Capability requirement 11), so no undo is owed (Execution Contract Undo 4).

Term council trailer: the trailer a council commit carries — the council nonce and the intent event id the invocation open answered.

---

## Composition logic

### Composition state

```
Composition state 1: The composition MUST rebuild the round index, the triage index, the ruling index AND the round count from the journal's full enumeration, Event Log's sequence-range read on the instance Audit Trail carries (Composes 8, Capability requirement 31).
Composition state 2: The journal MUST hold EVERY round, verdict, triage record, ruling AND escalation the composition keeps, WITHIN the retention period (Capability requirement 17).
Composition state 3: [Freeze], [Report], [Triage], [Rule] AND [Repair] MUST read the round index, the triage index, the ruling index AND the round count PER Execution Contract Derived index 1.
Composition state 4: The composition MAY remove a derived index at any time, AND Composition state 1 MUST rebuild the derived index.
```

Term round index: map from a pattern to the pattern's rounds — each round's id, key, snapshot, the verdicts it carries — counted verdicts by pass, a cold reader's malformed verdicts and a formal engine's sound verdicts — whether the round has settled, and the invocations whose intents carry its key. Derived index, rebuilt from what the journal still holds; past the journal's retention period a purged round drops out.

Term round key: the nonce injected at [Freeze]'s seam for one round and recorded with it — what an intent names the round by, minted by the council and not by the substrate or the repository (Recoverable Invocation Primitive policy 10), and unique (Capability requirement 24).

Term verdict key: the nonce injected at [Report]'s seam for one verdict and recorded with it — what a finding id names the verdict by (Capability requirement 24).

Term triage index: map from a round to the round's triage records, each finding's first, second and third records kept apart. Derived index, rebuilt from what the journal still holds; past the journal's retention period a purged triage record drops out.

Term ruling index: map from a pattern, and from a round and a patch id, to the maintainer's rulings naming them. Derived index, rebuilt from what the journal still holds; past the journal's retention period a purged ruling drops out.

Term round count: map from a pattern to the number of rounds frozen on the pattern since the pattern's latest clean round. Derived index. Past the journal's retention period a purged round drops out of the count, so a pattern whose unclean rounds outlive their records is re-admitted without a ruling: a limit this pattern accepts, which a deployment retaining council records longer than a pattern's unclean rounds span never meets. A round whose [Freeze] gave no answer, and whose record landed, counts too: a cost this pattern accepts, the budget running one round short for each such loss.

### Capability requirement

```
Capability requirement 1: A deployment MUST supply a repository whose commit takes a tree, a parent AND a trailer, AND whose reply, where one comes, carries EXACTLY ONE OF a commit id, a refusal with nothing written.
Capability requirement 2: A deployment MUST supply a repository read that finds a commit by a trailer value.
Capability requirement 3: A deployment MUST supply EVERY cold reader the permitted ranges alone, the snapshot's permitted lines included.
Capability requirement 4: A deployment MUST NOT supply a cold reader the lines of a pattern that follow the pattern's Status heading.
Capability requirement 5: A deployment MUST NOT supply a cold reader the record of an earlier round of the pattern.
Capability requirement 6: A deployment MUST supply EVERY formal engine the model derived from the snapshot, the model's buggy twin AND the bound the run explores.
Capability requirement 7: A deployment MUST disclose the round budget, the patch cap, the commit completion bound, the commit round trip, the probe round trip, the settling period, the gate's answer bound, the repair settling bound, the permitted ranges, the council writer's actor reference AND the maintainer's actor reference.
Capability requirement 8: A deployment MUST supply the maintainer's queue.
Capability requirement 9: A deployment MUST supply the corpus gate AND the corpus gate MUST answer within the gate's answer bound.
Capability requirement 10: A deployment MUST provision the sweep identity apart from EVERY other actor reference that writes the journal (Recoverable Invocation service identity 3).
Capability requirement 11: The repository MUST NOT remove a commit.
Capability requirement 12: The repository MUST NOT accept a push from the composition.
Capability requirement 13: The repository's commit MUST refuse with conflict where the head DOES NOT EQUAL the commit's parent.
Capability requirement 14: A deployment MUST settle EVERY council.commit.escalated through Recoverable Invocation's resolve, under the maintainer's actor reference, WITHIN the settling period of the closing's landing AND BEFORE the journal's retention period purges the escalated invocation's intent; Recoverable Invocation holds the retention period above the settling period counted from the examine window end of the intent's recording (Recoverable Invocation Term settling period, Check 4.1).
Capability requirement 15: The repository's refusal with nothing written MUST carry EXACTLY ONE OF lock-held, conflict, hook-rejected.
Capability requirement 17: A deployment MUST place EVERY council record under the retention policy the journal applies to the act kind council.commit.
Capability requirement 18: IF a commit carries a council trailer AND the committing actor DOES NOT EQUAL the council writer THEN the repository MUST refuse the commit.
Capability requirement 19: IF a commit's council nonce IS IN the council nonces the repository's commits carry THEN the repository MUST refuse the commit.
Capability requirement 20: The repository MUST NOT move the head to a commit that does not descend from the head.
Capability requirement 21: A deployment MUST inject a council nonce that no council.commit intent has carried (Execution Contract Logic confinement 16).
Capability requirement 22: IF the committing actor EQUALS the council writer AND the commit carries no council trailer THEN the repository MUST refuse the commit.
Capability requirement 23: A deployment MUST set EVERY payload cap the journal applies above the largest verdict, triage record, ruling, escalation AND council.commit intent the deployment's verifiers, triagers, maintainer AND council produce, the intent's every patch whole included, AND the patch cap above the most patches the deployment's triagers settle as cure for one round, AND the council writer MUST carry EVERY patch of a round in ONE [Repair] call (Action wiring 15, Invariant 2.1).
Capability requirement 24: A deployment MUST inject a round key that the journal holds for no other round AND a verdict key that the journal holds for no other verdict (Execution Contract Logic confinement 16).
Capability requirement 25: A deployment MUST supply a repository read of a pattern at a commit that answers EXACTLY ONE OF the pattern's bytes, absent, a refusal.
Capability requirement 26: A deployment MUST supply a repository read of a commit by the commit id that answers EXACTLY ONE OF the commit's parent id with the commit's trailer, absent, a refusal, the repository's first commit having no parent id.
Capability requirement 27: A deployment MUST refuse EVERY record_action under the action references council.round, council.verdict, council.triage, council.ruling AND council.escalation from EVERY caller other than the composition's own actions.
Capability requirement 28: A deployment MUST supply the journal's database PER Execution Contract Database 1 through 4, Execution Contract Order 1 and Execution Contract Refusal 1.
Capability requirement 29: A deployment MUST supply a repository read of the head that answers EXACTLY ONE OF the head's commit id, a refusal.
Capability requirement 30: A deployment MUST supply a repository read of the files at a commit that answers EXACTLY ONE OF the commit's files, a refusal.
Capability requirement 31: The Event Log instance the wired Audit Trail instance carries MUST answer the journal's full enumeration: Event Log's read by sequence-number range, from sequence 1 with an open upper bound, called directly on that instance (Composes 8).
Capability requirement 32: A deployment MUST supply EVERY second triager the briefs Action wiring 12 AND 13 describe AND EVERY third triager the briefs Action wiring 88 AND 13 describe.
Capability requirement 33: A deployment MUST inject at [Freeze]'s seam the snapshot hash the deployment's mechanism computes over the pattern's bytes at the base commit (Term snapshot hash, Execution Contract Logic confinement 8).
Capability requirement 34: A deployment MUST supply the Recoverable Invocation instance's compliance surface AND disclose the actor that reads the findings and hard alerts the instance writes to the compliance surface.
Capability requirement 35: A deployment MUST provision EVERY cold reader AND EVERY triager of a round an actor reference that no other cold reader AND no other triager of the round holds.
Capability requirement 36: A deployment MUST supply the coverage check that clears EVERY cold reader's report against EVERY part of the permitted ranges.
```

Term repository: the version-controlled database holding the canonical patterns — one head, commits that carry trailers, a commit taken only on the head it names as its parent, a read by trailer, and a read of a commit's parents and trailer by its id. It is the deployment's own: no atom in this library owns a version-controlled database, so what bears on the council's interoperability and audit is the contract Capability requirement 1, 2, 11 to 13, 15, 18 to 20, 22, 25, 26, 29 and 30 state here, and what is pure operating policy (its storage, hosting and hooks) is the deployment's.

Term permitted ranges: the lines a cold reader may read, each at the snapshot's base commit — the snapshot's lines ahead of its Status heading, the lines ahead of the Status heading of every pattern the snapshot's pattern composes, and the method's sections the deployment discloses (Capability requirement 7). A composed pattern that moves before the round's repair does not stale the round: a cost this pattern accepts and leaves to the next round's cold readers.

Term status heading: the heading of a pattern's Status section, `## Status`, the line from which a cold reader's lines are withheld (Capability requirement 4).

Term cold reader: a verifier that is a language model or a person running one pass of the method on a snapshot, having read no earlier round of the pattern.

Term formal engine: a verifier that checks the model derived from a pattern — Alloy, TLA+, or a heavier logic a property requires — through an adapter that answers the verdict contract.

Term buggy twin: the deliberately wrong sibling of the derived model that re-introduces a hazard the pattern defends against — the model a formal engine runs beside the derived one, and whose run carrying a counterexample is what lets the engine's verdict carry holds (Verdict 7, Verdict 11); the deployment supplies it (Capability requirement 6), as the section titled *Formal-model authoring pitfalls* in `pressure-testing.md` defines it.

Term verifier: a cold reader OR a formal engine.

Term maintainer: the person who holds the corpus's semantic authority.

Term council: the automated agents that keep a pattern true under the maintainer's authority — the verifiers, the triagers and the council writer; where a rule names the council's one actor that writes, it names the council writer.

Term maintainer's queue: the surface the maintainer reads the council's escalation records and Recoverable Invocation's council.commit.escalated closings from, each carrying the round, the finding, patch or pattern, and the one line that asks.

Term escalation: the council.escalation record this composition writes to the maintainer's queue (Composes 6, Capability requirement 27), written through Audit Trail's record_action as every council record is; Recoverable Invocation's closing council.commit.escalated, which the sweep or the maintainer's resolve writes, is always named by its action reference. Its subject is the pattern, for a [Freeze] that answers budget-spent; the round, the pass and the verifier, for a malformed verdict; the round and the patch id, for a patch gated.

Term open escalation: an escalation whose subject no later record has closed — a maintainer's ruling naming the pattern alone closes the escalation of a pattern, and one carrying the patch for the round closes the escalation of a patch; a counted verdict of the round for the same pass closes the escalation of a malformed verdict; a later round of the pattern closes every escalation of the pattern's earlier rounds. No record is written to close it: the journal's order says whether it is open.

Term corpus gate: the deployment's whole-corpus surface check — `python3 tools/grace/check.py --gate` in this repository — run over the tree the call hands it, the repair tree or the head [Repair] read, and answering its findings over that tree, each named by its file, code and message, the line aside.

Term round budget: the most rounds a pattern may run without a clean round before the composition escalates the pattern.

Term patch cap: the most patches one [Repair] call may carry, and so one commit.

Term repair settling bound: the longest a settled round waits, from its settling record's landing, for the council writer's [Repair] call, a bound the deployment discloses (Capability requirement 7, Action wiring 89).

Term admitted freeze: a [Freeze] call no rule refused and no rule answered budget-spent.

Term admitted report: a [Report] call no rule refused and no rule answered late-malformed.

Term admitted ruling: a [Rule] call no rule refused.

Term admitted triage: a [Triage] call no rule refused.

Term admitted repair: a [Repair] call no rule refused, and no rule answered gated, before the invocation open.

Term opened repair: an admitted repair whose invocation open answered an open result.

Term council writer: the council's one actor that writes to the repository, under its own actor reference and credential; the sweep identity is not the council writer. It is the actor whose commits alone may carry a council trailer (Capability requirement 18, 22) and whose actor reference [Repair] answers to (Action wiring 49). In Recoverable Invocation a writer is any actor that lands an act's journal records (its Term landing actor): for the act kind council.commit the council writer, the maintainer through resolve (Capability requirement 14) and the sweep identity, and the repository refuses a council commit from any of them but the council writer.

Term diff check: Action wiring 25's comparison of the repair tree's diff from the head with the change set, made by lines: the lines the diff changes in each file are exactly the lines each fragment's old text removes and new text adds in the fragment's target.

Term sweep identity: the commit binding's service identity, under which Recoverable Invocation's sweep closes the invocation of a council commit that died.

### Primitive policy

```
Primitive policy 1: IF the pattern OR the base commit EQUALS blank THEN [Freeze] MUST answer invalid-request.
Primitive policy 2: IF the pattern IS NOT IN the repository at the base commit THEN [Freeze] MUST answer not-known.
Primitive policy 3: IF a verdict carries no snapshot hash OR no base commit OR no verifier OR no pass OR the count of verdict values the verdict carries DOES NOT EQUAL one OR holds with a finding the verifier classed foundational OR counterexample with no finding the verifier classed foundational OR a finding of the verdict carries no site OR no trace OR no class OR no finding kind OR the name of a finding's site EXCEEDS the reference length cap THEN [Report] MUST answer invalid-request.
Primitive policy 4: IF the call carries no patch OR a patch carries no patch id OR two patches of the call carry one patch id OR a patch carries no fragment OR a fragment carries no target OR a patch id OR a fragment's target EXCEEDS the reference length cap THEN [Repair] MUST answer invalid-request.
Primitive policy 5: IF the count of the patches the call carries EXCEEDS the patch cap THEN [Repair] MUST answer invalid-request.
Primitive policy 6: The composition MUST compare a snapshot hash, a commit id, a finding id, a corpus gate finding's file, code AND message, AND a fragment byte-exact.
Primitive policy 7: IF the repository's name OR the council writer's actor reference EXCEEDS the reference length cap THEN [Repair] MUST answer invalid-request (Recoverable Invocation Primitive policy 1, 8).
Primitive policy 8: [Freeze], [Report], [Triage] AND [Rule] MUST NOT write the action's own record BEFORE EVERY rule of the action that answers a refusal has answered no refusal, other than Primitive policy 13, 15 AND 17, which answer the write's own failure.
Primitive policy 9: IF a round is given AND the round names no round the journal holds THEN [Report], [Triage], [Rule] AND [Repair] MUST answer not-known.
Primitive policy 10: IF a read of the repository refuses OR gives no answer THEN [Freeze] AND [Repair] MUST answer repository-unavailable; a read that answers absent is no refusal (Capability requirement 25).
Primitive policy 11: IF a read of the journal the action makes directly OR through Recoverable Invocation's read invocation answers state-unavailable, refuses OR gives no answer THEN [Freeze], [Report], [Triage], [Rule] AND [Repair] MUST answer journal-unavailable; a read a record_action makes of the journal is no read of either kind (Primitive policy 23).
Primitive policy 12: [Freeze], [Report], [Triage], [Rule] AND [Repair] MUST pass the caller's actor reference AND credential through to EVERY record_action the action calls directly.
Primitive policy 13: IF the record_action that writes the action's own record refuses with an invalid-credential, a recording-failure OR refuses at a step other than step-4 THEN [Freeze], [Report], [Triage] AND [Rule] MUST answer record_action's code, carrying the step and the committed ids the code carries.
Primitive policy 14: IF the pattern EQUALS blank, a patch comes with no round OR a round comes with no patch THEN [Rule] MUST answer invalid-request.
Primitive policy 15: IF an escalation's record_action refuses with an invalid-credential, a recording-failure OR refuses at a step other than step-4 THEN the escalating action MUST answer record_action's code, carrying the step and the committed ids the code carries, in place of the escalating action's own answer; an escalation refused with an invalid-request at step-4 stands, and the escalating action's own answer is given.
Primitive policy 16: IF a triage record carries no role OR no class OR no finding kind OR no blame OR no side OR no triage disposition, OR carries the role third with no settling text, THEN [Triage] MUST answer invalid-request.
Primitive policy 17: IF the record_action that writes the action's own record refuses with an invalid-request at step-4 THEN the action MUST answer as an admitted call answers: [Freeze] with the event id the refusal carries as the round id, [Report], [Triage] AND [Rule] recorded (Audit Trail record action step 7.11, 7.16).
NOTE: watch the retention step's recording failure (Primitive policy 13, Primitive policy 15, Primitive policy 17).
Primitive policy 18: IF a triage record's triage disposition DOES NOT EQUAL reject AND the triage disposition DOES NOT EQUAL the one Term triage disposition pairs with the record's finding kind THEN [Triage] MUST answer invalid-request.
Primitive policy 19: IF a triage record's triage disposition EQUALS cure AND the record carries no patch THEN [Triage] MUST answer invalid-request.
Primitive policy 20: IF the pattern of a round given to [Rule] DOES NOT EQUAL the ruling's pattern THEN [Rule] MUST answer not-known.
Primitive policy 21: IF the journal reports Purged for a given round's record, OR for a verdict record OR a triage record of the given round the call reads, THEN [Report], [Triage], [Rule] AND [Repair] MUST answer purged.
Primitive policy 22: IF the call gives no round AND the journal holds no round of the pattern THEN [Rule] MUST answer invalid-request.
Primitive policy 23: The composition MUST read a record_action that answers state-unavailable as a recording-failure carrying step-2, the first step of the writes, whichever step answered, since nothing is committed (Execution Contract Constituent failure 3 and Execution Contract Read 3).
Primitive policy 24: [Freeze], [Report] AND [Repair] MUST NOT write an escalation of a subject an open escalation already carries.
Primitive policy 25: IF an escalation's record_action answers nothing THEN the escalating action MUST answer nothing (Execution Contract Error model 1), AND the composition MUST apply Primitive policy 24 to the retry on the records the retry finds.
NOTE: watch the constituent's failed read (Primitive policy 11, Primitive policy 23).
```

### Audit arm

The substrate's record_action answers an event id, or refuses invalid-credential, invalid-request(step, committed_ids) or recording-failure(step); a read of it answers state-unavailable; and an answer can be lost. What the composition does with each, written once in the rules the last column names:

| record_action's answer | Written | A blind retry | The action answers | Lands |
|---|---|---|---|---|
| invalid-credential | nothing | refused again until the caller's credential is the deployment's to correct | invalid-credential | Primitive policy 13 |
| invalid-request at step-4 | the record, already appended | double-appends, so none is made | as an admitted call answers, with the event id the refusal carries | Primitive policy 17 |
| invalid-request at another step, recording-failure(step) | what the committed ids name | read the committed ids before a retry; the failure is a pageable deployment fault | record_action's code, with the step and the committed ids | Primitive policy 13 |
| state-unavailable | nothing | a retry reads again | recording-failure carrying step-2 | Primitive policy 23 |
| no answer | not known | a retry meets the records as it finds them (Execution Contract Error model 1) | no answer; for an escalation the retry meets Primitive policy 24 | Primitive policy 25 |

The same table serves an escalation's record_action, where Primitive policy 15 states the arms that differ.

### Action wiring

```
freeze(pattern, base_commit, actor_ref, credential)
  answers admitted-freeze(round_id, snapshot) | budget-spent
  refuses invalid-request | repository-unavailable | journal-unavailable | not-known | stale | invalid-request(step, committed_ids) | invalid-credential | recording-failure(step)

report(round, verdict, actor_ref, credential)
  answers recorded | late-malformed
  refuses invalid-request | journal-unavailable | purged | not-known | round-closed | stale | already-counted | invalid-request(step, committed_ids) | invalid-credential | recording-failure(step)

triage(round, finding, record, actor_ref, credential)
  answers recorded
  refuses invalid-request | journal-unavailable | purged | not-known | round-closed | already-triaged | invalid-request(step, committed_ids) | invalid-credential | recording-failure(step)

rule(pattern, optional round, optional patch, actor_ref, credential)
  answers recorded
  refuses invalid-request | journal-unavailable | purged | not-known | invalid-credential | invalid-request(step, committed_ids) | recording-failure(step)

repair(round, patches, actor_ref, credential)
  answers commit id | gated
  refuses invalid-request | repository-unavailable | journal-unavailable | purged | not-known | invalid-credential | stale | unsettled | mismatch | unresolved | gate-red | lock-held | conflict | hook-rejected | act-in-flight(invocation_id) | section-unavailable | recording-failure(intent) | recording-failure(outcome) | already-accounted(closing_event_id) | recording-failure(refusal, constituent_code) | invalid-request(step, committed_ids) | recording-failure(step)
```

#### Closure table

Every constituent call of [Freeze], [Report], [Triage], [Rule] and [Repair], and where each of its answers, refusals, failed reads and lost answers lands, with the rule that owns the landing. The repository's reads and its commit are the deployment's, met by Primitive policy 10, Term commit partition and Action wiring 26 through 29.

| Call | Answer | Lands | Owner |
|---|---|---|---|
| Audit Trail's record_action, an action's own record | an event id | the action's own answer: [Freeze] the round id and the snapshot, [Report], [Triage] and [Rule] recorded | Action wiring 3, 7, 10, 39, Primitive policy 12 |
| Audit Trail's record_action, an action's own record | invalid-credential, recording-failure(step), a refusal at a step other than step-4 | record_action's code, carrying the step and the committed ids | Primitive policy 13 |
| Audit Trail's record_action, an action's own record | invalid-request at step-4 | the action answers as an admitted call answers | Primitive policy 17 |
| Audit Trail's record_action, an action's own record | state-unavailable | recording-failure carrying step-2 | Primitive policy 23 |
| Audit Trail's record_action, an action's own record | no answer | no answer to give; a retry meets the records as it finds them, a recorded verdict refused already-counted | Execution Contract Error model 1, Action wiring 5 |
| Audit Trail's record_action, an escalation | invalid-credential, recording-failure(step), a refusal at a step other than step-4 | record_action's code, in place of the escalating action's own answer | Primitive policy 15 |
| Audit Trail's record_action, an escalation | invalid-request at step-4 | stands; the escalating action's own answer is given | Primitive policy 15 |
| Audit Trail's record_action, an escalation | no answer | no answer to give; the retry meets Primitive policy 24 | Primitive policy 25 |
| Event Log's read by sequence-number range, a rebuild or a read of the journal | state-unavailable, a refusal or no answer | journal-unavailable | Primitive policy 11 |
| Recoverable Invocation's invocation open | the open result | an opened repair, which commits | Action wiring 22, 26 |
| Recoverable Invocation's invocation open, close or refusal | a refusal | the code Recoverable Invocation exports for it | Action wiring 42 |
| Recoverable Invocation's invocation close | accepted, after a commit id | the commit id | Action wiring 27 |
| Recoverable Invocation's invocation refusal | a refusal event id | the database's code | Action wiring 28, 45 |
| Recoverable Invocation's invocation yield | accepted, after a commit of unknown arm | recording-failure(outcome) | Action wiring 29a, 29b |
| Recoverable Invocation's read invocation | the invocation's closing | the round clean or not | Term clean round |

#### [Freeze]

```
Action wiring 2: An admitted freeze MUST record the round with the pattern, the base commit, the snapshot hash, the round budget, the round's position AND the round key.
NOTE: a [Freeze] whose answer was lost (Execution Contract Error model 1) and is retried records a second round at the same base commit under a second round key (Capability requirement 24), and Term round count states the cost this pattern accepts.
Action wiring 3: An admitted freeze MUST answer the round id AND the snapshot: the snapshot hash AND the base commit.
Action wiring 34: WHEN the round budget DOES NOT EXCEED the pattern's round count AND the pattern carries no standing ruling AND no refusal [Freeze]'s refuses line lists applies to the call (Execution Contract Refusal 1):
    Action wiring 34a: [Freeze] MUST answer budget-spent.
    Action wiring 34b: IF no open escalation of the pattern EXISTS THEN [Freeze] MUST escalate the pattern to the maintainer's queue.
Action wiring 57: IF the pattern at the base commit DOES NOT EQUAL the pattern at the repository's head THEN [Freeze] MUST answer stale; a pattern absent at the head equals no pattern at the base commit.
```

#### [Report]

```
Action wiring 4: IF the verdict's snapshot hash DOES NOT EQUAL the round's snapshot hash OR the verdict's base commit DOES NOT EQUAL the round's base commit THEN [Report] MUST answer stale.
Action wiring 5: IF a counted verdict of the round carries the verdict's pass OR the verdict's verifier OR the call's actor reference, OR a verdict the round holds recorded EQUALS the verdict byte for byte apart from the verdict key, THEN [Report] MUST answer already-counted.
Action wiring 6: IF the verdict carries malformed AND no open escalation of the round, the pass and the verifier EXISTS THEN [Report] MUST escalate the verdict to the maintainer's queue, a malformed verdict answered late-malformed (Action wiring 90) included.
Action wiring 7: An admitted report MUST record the verdict with the verdict key, the round id AND the round's position the round's record carries.
Action wiring 47: IF the round IS IN the round index's settled rounds THEN [Triage] MUST answer round-closed, AND [Report] MUST answer round-closed where the verdict carries no malformed.
Action wiring 51: [Report] MUST NOT evaluate Action wiring 6 BEFORE EVERY rule of the report refusal order has answered no refusal.
Action wiring 60: [Report] MUST NOT evaluate Action wiring 7 BEFORE Action wiring 6 has answered.
Action wiring 90: WHEN the round IS IN the round index's settled rounds AND the verdict carries malformed AND no refusal [Report]'s refuses line lists applies to the call (Execution Contract Refusal 1):
    Action wiring 90a: [Report] MUST answer late-malformed.
    Action wiring 90b: [Report] MUST NOT record the verdict.
```

Term sound verdict: a recorded verdict of a round carrying holds or counterexample — a cold reader's or a formal engine's.

Term counted verdict: for each of the round's cold reader passes, grid (GRID, a nine-checkpoint check of structural completeness), eos (EOS, Essence of Software, a check of conceptual independence, run with the builder's reading) and linus (the adversarial pass), the earliest sound verdict recorded for the pass from a verifier and an actor reference no earlier counted verdict of the round carries — the verdicts a round counts (Invariant 1.2, Verdict 9); a later verdict for a pass or from a verifier already counted is refused (Action wiring 5).

Term counted finding: a finding a counted verdict carries, or a finding a cold reader's malformed verdict of the round carries where the round has no settling record or the verdict is recorded no later than the settling record — the malformed verdict counts for nothing, and the findings it carries stand (Verdict 9, the section titled What DONE means in `pressure-testing.md`).

Term round position: the number of rounds frozen on a pattern since the pattern's latest clean round, counted in the journal's order up to and including the round's record, a round counting as clean only by a record that precedes the round's record — the round count [Freeze] read (Action wiring 34) plus one, recorded with the round (Action wiring 2) and never recounted, so a clean round that settles after the round's record moves no position.

Term ruled round: a round whose record follows a maintainer's ruling naming the pattern alone, with no other round of the pattern recorded between them.

Term report refusal order: Primitive policy 3, Primitive policy 11, Primitive policy 21, Primitive policy 9, Action wiring 47, Action wiring 4, Action wiring 5 — [Report]'s refusal rules, earliest first.

#### [Triage]

```
Action wiring 8: A triage record MUST carry the role, the finding's class, finding kind, blame, side AND triage disposition.
Action wiring 9: IF the finding came from a formal engine AND the record's side DOES NOT EQUAL model AND the record carries no reason the model is right THEN [Triage] MUST answer invalid-request.
Action wiring 10: An admitted triage MUST record the triage record with the round id AND the finding id, under the triager's own actor reference.
Action wiring 11: IF the round's foundational count EQUALS zero THEN the composition MUST NOT count the round as settled BEFORE EVERY counted finding of the round carries a counted triage in the role second.
Action wiring 12: The second triager's brief MUST carry the findings, the first triage's downgraded findings and rejected findings, the method's test AND the blame rule (Term blame), the test being the class definitions without the sentences that say what count grounds a pattern.
Action wiring 13: The second and third triagers' briefs MUST NOT carry the threshold the count is read against.
Action wiring 88: The third triager's brief MUST carry the parted findings, the first and second triage records of each, the method's test AND the blame rule (Term blame).
Action wiring 89: IF a round IS IN the round index's settled rounds THEN the council writer MUST call [Repair] for the round WITHIN the repair settling bound of the round's settling record's landing.
Action wiring 14: IF a counted finding IS IN the parted findings THEN the composition MUST NOT count the round as settled BEFORE the finding carries a counted triage in the role third carrying the text that settles the finding.
Action wiring 69: The composition MUST NOT count the round as settled BEFORE EVERY finding a formal engine's sound verdict of the round carries carries a counted triage.
Action wiring 35: IF the finding IS NOT IN the round's counted findings AND no formal engine's sound verdict of the round carries the finding THEN [Triage] MUST answer not-known.
Action wiring 36: IF the round carries a counted triage of the finding in the record's role THEN [Triage] MUST answer already-triaged.
Action wiring 37: IF the round carries a triage record of the finding in another role under the caller's actor reference THEN [Triage] MUST answer invalid-request.
Action wiring 43: IF the record's role EQUALS second AND the round carries no counted triage of the finding in the role first THEN [Triage] MUST answer invalid-request.
Action wiring 44: IF the record's role EQUALS third AND the finding IS NOT IN the parted findings THEN [Triage] MUST answer invalid-request.
Action wiring 74: [Triage] MUST NOT evaluate a rule of the triage refusal order BEFORE EVERY earlier rule of the triage refusal order has answered no refusal.
Action wiring 82: [Triage] MUST NOT answer invalid-request BEFORE EVERY earlier rule of the triage refusal order has answered no refusal.
Action wiring 83: [Triage] MUST NOT answer not-known BEFORE EVERY earlier rule of the triage refusal order has answered no refusal.
```

Term class: foundational | refining | rhetorical — as the section titled What DONE means in `pressure-testing.md` defines each.

Term finding kind: A | B | C | D — the triage fields of `pressure-testing.md`.

Term blame: fresh | older — fresh where the site was written or changed within the pattern's last two rounds.

Term method's test: the class definitions of *What DONE means* in `pressure-testing.md`, a finding foundational when two conforming implementations can behave differently or an invariant can break, refining or rhetorical otherwise, without the sentences that say what count grounds a pattern (Term class).

Term side: model | english | both — which text a finding indicts: the derived model, the pattern, or the two.

Term triage disposition: cure | route | reject | decline — cure for a finding of finding kind A, route for finding kind B or C, decline for finding kind D, reject where the text already answers it.

Term deciding count: a count a round's cleanliness turns on — a round's foundational count where it is zero, since a zero decides the round clean. A count above zero is no deciding count here: it keeps the round unclean, and on the round that brings the pattern's round count to the round budget, and on every round a standing ruling admits past it, it decides the next [Freeze]'s budget-spent (Action wiring 34a) on the first triage alone, a cost this pattern accepts.

Term threshold: the number a deciding count is read against — zero, for a round's foundational count deciding the round clean.

Term downgraded finding: a counted finding whose first triage places it in a class below the class its reporter gave it, with a triage disposition other than reject.

Term foundational count: the number of a round's counted findings whose settled triage carries the class foundational and a triage disposition other than reject, counted over the records up to and including the record under test: the count at each prefix of the round's journal order.

NOTE: a formal engine's finding is no counted finding (Verdict 9), so it enters no foundational count; it is triaged once before the round settles (Action wiring 69, Term settled round), and the Ledger's formal line, not the count, holds the formal layer to the ground (`pressure-testing.md`, *Formal models*).

Term parted finding: a finding whose earliest counted first and second triages differ on the class, the side or the triage disposition.

Term role: first | second | third — which triage of a finding a record is.

Term triage record: one triager's sorting of one finding of a round — naming the round and the finding, the role, class, finding kind, blame, side and triage disposition, the patch whole where the triage disposition is cure, a reason the model is right where a formal engine's finding is sided other than model, and for a third triage the text that settles — recorded under the triager's actor reference.

Term counted triage: a triage record of a finding, where the round has no settling record or the triage record is recorded no later than the settling record, whose actor holds no earlier record of the finding in another role — the triage records every rule of this pattern reads.

Term settled triage: among a finding's counted triages, the earliest third where one exists, otherwise the earliest second, otherwise the earliest first.

Term settled round: a round with a settling record.

Term settling record: the first record of the round's journal order at which the round settles: reading only the records up to and including that record, the round carries a counted verdict for each cold reader pass and every counted finding and every finding a formal engine's sound verdict carries carries a settled triage, under Action wiring 11, 14 and 69; Recoverable Invocation's settling period and the settling a resolve does are its own, always named so.

Term triager: the agent OR person that sorts a finding.

Term triage refusal order: Primitive policy 16, Primitive policy 18, Primitive policy 19, Primitive policy 11, Primitive policy 21, Primitive policy 9, Action wiring 47, Action wiring 9, Action wiring 37, Action wiring 43, Action wiring 44, Action wiring 36, Action wiring 35 — [Triage]'s refusal rules, earliest first.

#### [Rule]

```
Action wiring 38: IF the actor reference DOES NOT EQUAL the maintainer's actor reference THEN [Rule] MUST answer invalid-credential.
Action wiring 39: An admitted ruling MUST record the ruling with the pattern, the pattern's latest round AND, where given, the round AND the patch whole.
Action wiring 75: [Rule] MUST NOT evaluate a rule of the ruling refusal order BEFORE EVERY earlier rule of the ruling refusal order has answered no refusal.
Action wiring 84: [Rule] MUST NOT answer invalid-request BEFORE EVERY earlier rule of the ruling refusal order has answered no refusal.
```

Term maintainer's ruling: a ruling record under the maintainer's actor reference — carrying a pattern, a round and a patch whole, it admits that patch, byte for byte, into the claim families in that round; naming a pattern alone, it admits the pattern's next round past its round budget; carrying a round and a patch whole that removes a Ledger open line, it lifts Action wiring 63 for that patch.

Term standing ruling: a maintainer's ruling naming a pattern alone, together with the round that was the pattern's latest when the ruling was recorded, standing while that round is still the pattern's latest — spent by the next [Freeze] it admits, whatever copy of the ruling's record lands later. A [Rule] call whose answer was lost is retried by the maintainer after reading the pattern's ruling index (Execution Contract Error model 1), and a retry that lands records a ruling anew against the pattern's latest round then, which stands as any ruling does. A ruling stands no more, unspent, once a [Freeze] the round budget admits records a later round of the pattern, and the pattern's next [Freeze] past the round budget then escalates the pattern again (Action wiring 34): a cost this pattern accepts.

Term ruling refusal order: Primitive policy 14, Primitive policy 11, Primitive policy 21, Primitive policy 9, Primitive policy 20, Primitive policy 22, Action wiring 38 — [Rule]'s refusal rules, earliest first.

#### [Repair]

```
Action wiring 15: IF the pattern at the repository's head DOES NOT EQUAL the snapshot's bytes THEN [Repair] MUST answer stale; a pattern absent at the head equals no snapshot.
Action wiring 17: IF the count of sites a fragment's target resolves to on the round's pattern AND, for a Decisions entry, on the pattern's history file (Term records fragment) DOES NOT EQUAL one THEN [Repair] MUST answer unresolved.
Action wiring 18: IF the count of a fragment's old text in the fragment's resolved site, verbatim, DOES NOT EQUAL one THEN [Repair] MUST answer mismatch.
Action wiring 19: IF a fragment's target IS IN the claim families AND no maintainer's ruling carries the fragment's patch byte-exact for the round THEN [Repair] MUST answer gated.
Action wiring 20: IF a patch answers a finding whose settled triage's side EQUALS model THEN [Repair] MUST answer gated.
NOTE: a patch answering a model-sided finding stops here (Action wiring 20) and goes to no queue: its cure is the model's re-derivation, which the deployment owns (Capability requirement 6) and no action of this pattern carries, so the pattern patch a model-sided triage of a finding of finding kind A carries (Primitive policy 18, 19) is never committed. The three triages — the first, the second blind to the threshold, the third where the two part — are this composition's own shape, considered for extraction against the composition-layer gates and not extracted: no other composition forces the same invariant (Gate 1 of the composition-layer extraction gate in `pressure-testing.md`).
Action wiring 22: An admitted repair MUST call the invocation open with the act kind, the repository as the act key, the council writer's actor reference AND credential, AND the round key, the snapshot hash, EVERY patch whole AND the council nonce as intent data.
Action wiring 23: [Repair] MUST build the repair tree, once the repair refusal order has answered no refusal ahead of Action wiring 24, from the head Action wiring 15 read, with EVERY fragment of EVERY patch applied as one change.
Action wiring 24: IF a finding the corpus gate reports over the repair tree IS NOT IN the gate's findings over the head Action wiring 15 read OR the gate gives no answer within the gate's answer bound THEN [Repair] MUST answer gate-red.
Action wiring 25: IF the repair tree's diff from the head Action wiring 15 read DOES NOT EQUAL the change set THEN [Repair] MUST answer mismatch.
Action wiring 26: An opened repair MUST commit the repair tree with the head Action wiring 15 read as the parent AND the council trailer as the commit's trailer, WITHIN Recoverable Invocation's pause bound of the invocation open's return (Recoverable Invocation commit 15).
Action wiring 27: IF the commit answers a commit id THEN [Repair] MUST call the invocation close with the act kind, the act key, the open result, the council writer's actor reference AND credential, council.commit.committed AND the commit id as the outcome data (Recoverable Invocation close 5).
Action wiring 28: IF the commit's arm EQUALS pre-commit THEN [Repair] MUST call the invocation refusal with the act kind, the act key, the open result, the council writer's actor reference AND credential, AND the database's code as the reason AND as the constituent code (Recoverable Invocation commit 2).
Action wiring 29: WHEN the commit's arm EQUALS unknown:
    Action wiring 29a: [Repair] MUST call the invocation yield with the act kind, the act key AND the invocation id, carrying the reply lost where the commit gave no answer and the reply answered where the commit's reply is one the database's contract does not declare (Recoverable Invocation yield 7).
    Action wiring 29b: [Repair] MUST answer recording-failure(outcome) (Recoverable Invocation commit 8d).
Action wiring 30: IF [Repair] answers gated THEN [Repair] MUST escalate to the maintainer's queue EVERY patch that carries a fragment gated under Action wiring 19, 56 or 63 in the call AND no open escalation of the round and the patch id EXISTS.
Action wiring 31: IF the round IS NOT IN the round index's settled rounds THEN [Repair] MUST answer unsettled.
Action wiring 32: [Repair] MUST NOT push.
Action wiring 33: [Repair] MUST NOT call the invocation open BEFORE the corpus gate AND the diff check have answered over the repair tree.
Action wiring 40: IF a patch answers a finding that carries no settled triage of the round with triage disposition cure THEN [Repair] MUST answer unresolved.
Action wiring 41: IF a patch answers no finding AND a fragment of the patch IS NOT a records fragment THEN [Repair] MUST answer unresolved.
Action wiring 42: IF the invocation open, close OR refusal refuses THEN [Repair] MUST answer the code Recoverable Invocation Action wiring 2 exports for the refusal.
Action wiring 45: IF the invocation refusal answers a refusal event id THEN [Repair] MUST answer the database's code (Recoverable Invocation commit 3).
Action wiring 49: IF the actor reference DOES NOT EQUAL the council writer's actor reference THEN [Repair] MUST answer invalid-credential.
Action wiring 53: IF the stated count of a records fragment's new last gate line EQUALS blank OR the stated count DOES NOT EQUAL the round's foundational count THEN [Repair] MUST answer mismatch.
Action wiring 86: IF the stated count of a records fragment's new last gate line EQUALS zero AND the line's leading entry carries no words not clean AND a blocking sibling of the round EXISTS THEN [Repair] MUST answer mismatch.
Action wiring 54: [Repair] MUST NOT evaluate Action wiring 31 BEFORE reading the round's journal records (Execution Contract Derived index 1).
Action wiring 55: IF a byte of one site lies in the old texts of two fragments of the change set THEN [Repair] MUST answer mismatch.
Action wiring 56: IF a declared name of a fragment IS IN the claim families AND no maintainer's ruling carries the fragment's patch byte-exact for the round THEN [Repair] MUST answer gated.
Action wiring 61: IF the change set carries no records fragment that replaces the Ledger's last gate line THEN [Repair] MUST answer invalid-request.
Action wiring 62: IF a patch answers a finding AND the patch DOES NOT EQUAL, byte-exact, the patch the finding's settled triage carries THEN [Repair] MUST answer unresolved.
Action wiring 63: IF a records fragment removes a Ledger open line AND no maintainer's ruling carries the fragment's patch byte-exact for the round THEN [Repair] MUST answer gated.
Action wiring 77: IF a finding of the round carries a settled triage with triage disposition route AND the change set carries no records fragment that adds a Ledger open line naming the finding id THEN [Repair] MUST answer unresolved.
Action wiring 87: IF a finding of the round carries a settled triage with triage disposition cure AND the change set carries no patch answering the finding AND the change set carries no records fragment that adds a Ledger open line naming the finding id THEN [Repair] MUST answer unresolved.
Action wiring 76: [Repair] MUST NOT evaluate a rule of the repair refusal order BEFORE EVERY earlier rule of the repair refusal order has answered no refusal.
Action wiring 78: [Repair] MUST NOT answer invalid-request BEFORE EVERY earlier rule of the repair refusal order has answered no refusal.
Action wiring 79: [Repair] MUST NOT answer mismatch BEFORE EVERY earlier rule of the repair refusal order has answered no refusal.
Action wiring 80: [Repair] MUST NOT answer unresolved BEFORE EVERY earlier rule of the repair refusal order has answered no refusal.
Action wiring 81: [Repair] MUST NOT answer gate-red BEFORE EVERY earlier rule of the repair refusal order has answered no refusal.
Action wiring 85: [Repair] MUST NOT answer gated BEFORE EVERY rule of the repair refusal order that obliges a refusal, ahead of the rule that obliges gated, has answered no refusal.
```

Term patch: a patch id, the finding it answers, and one fragment for each sentence the change touches — the rule or Term the finding sits in and every sentence on the pattern that restates it; a patch carrying the round's records answers no finding.

Term fragment: a target, an old text and a new text — one sentence's change; an empty new text deletes. Two fragments of one site whose old texts share no byte are admitted (Action wiring 55).

Term declared name: a rule label or a Term name a fragment's new text declares.

Term target: the reference a fragment carries to the site it changes, by the site's rule label, Term name, heading or records site; Action wiring 17 resolves it to the sites it names.

Term claim families: Invariant, Check, External check — the pattern's claims — with every Term their rules name, directly or through another Term's definition, in the snapshot or in the repair tree, a rule naming a Term where the rule's text carries the Term's name, singular or plural, bare or possessive; the pattern's Intent; and the pattern's status line with the Ledger's status and formal lines. The Terms the council mints — the round key, the verdict key and the finding id — are outside the closure.

Term round's records: the Ledger lines, the last gate line and the Decisions entry the round owes, the Ledger lines written in the pattern and the Decisions entry under the Decisions heading of the pattern's history file; the status is the maintainer's (Term claim families). Each settled round owes one last gate entry at the head of the last gate line (Term stated count), which the council writer lands in its one [Repair] call (Action wiring 89).

Term records fragment: a fragment that replaces the pattern's status line or the Ledger's status, formal or last gate line, adds or removes a Ledger open line, or adds a Decisions entry under the Decisions heading of the pattern's history file — the shapes the round's records take; one that replaces the status line or the Ledger's status or formal line is a records fragment only a maintainer's ruling admits (Term claim families, Action wiring 56). Its target is the line it replaces or removes, the Ledger's open list for a line added (the new line after the list's last line), and the Decisions heading of the history file for an entry (the new entry after the heading's last entry).

Term stated count: the count a last gate line's leading entry states, as the numeral after the words foundational count — the entry a round's records write at the head of the line, a clean round's stating foundational count 0 beside the word clean, and a round of count 0 with a blocking sibling stating it beside the words not clean; blank where the leading entry states no such numeral.

Term change set: every fragment of the patches one [Repair] call carries — the cures and the round's records; every line a council commit may change, each a line of the round's pattern or of the pattern's history file, the fragments' targets lying in no other file.

Term repair tree: the files of the head [Repair] read (Capability requirement 30), with the change set applied — built by one [Repair] call apart from every other call's tree and every checked-out copy, and committed whole.

Term repair refusal order: Primitive policy 4, Primitive policy 5, Primitive policy 7, Primitive policy 10, Primitive policy 11, Primitive policy 21, Primitive policy 9, Action wiring 49, Action wiring 15, Action wiring 31, Action wiring 61, Action wiring 53, Action wiring 86, Action wiring 40, Action wiring 77, Action wiring 87, Action wiring 62, Action wiring 41, Action wiring 20, Action wiring 17, Action wiring 18, Action wiring 55, Action wiring 24, Action wiring 25, Action wiring 19, Action wiring 56, Action wiring 63 — [Repair]'s refusal rules and the rules that answer gated (Action wiring 19, 20, 56 and 63) ahead of the invocation open, earliest first; behind it the invocation's own codes answer (Action wiring 29, 42, 45).

<details markdown="block">
<summary>WHY</summary>

The escalation is the council's record, not the act's (Action wiring 30): it is written before any intent, so Recoverable Invocation Action wiring 6, which keeps an adopter's journal writes for the act to the protocol's own actions, does not reach it.

</details>

### Wiring decision

```
Wiring decision 1: The composition MAY repair a round ONLY IF the round has settled.
Wiring decision 2: The composition MAY change a site in the claim families ONLY IF the maintainer's recorded ruling carries the change.
```

<details markdown="block">
<summary>WHY</summary>

*Principle.* A count is about one text, and a claim is the maintainer's. *Likely objection.* Repairing as findings arrive is faster, and an invariant the engine breaks is the invariant that is wrong. *Mechanism that resolves it.* Three passes over moving text is a search, not a round: each pass reads a text the last pass never saw, so no count compares with another (the section titled What DONE means in `pressure-testing.md`). And the cheapest way to make an engine stop finding a counterexample is to weaken the claim it checks; a loop under pressure to converge will find that way if a rule does not close it. *Result.* Every pass is handed the snapshot (Capability requirement 3), and a repair lands after the round settles, on a head whose pattern is still the snapshot (Action wiring 15); a patch into an Invariant, a Check or an External check stops at the maintainer's queue until a ruling names it, whatever the round count.

</details>

### Verdict

```
Verdict 1: A verdict MUST carry EXACTLY ONE OF holds, counterexample, malformed.
Verdict 2: A verdict MUST carry the snapshot hash, the base commit, the verifier AND the pass.
Verdict 3: A verdict MUST carry EVERY finding the verifier reports, each with the finding's site, trace, class AND finding kind.
Verdict 4: A cold reader's verdict MUST carry holds where the cold reader read inside the permitted ranges AND the coverage check cleared the cold reader's report against EVERY part of the permitted ranges AND the cold reader reports no foundational finding.
Verdict 5: IF the cold reader read outside the permitted ranges OR the coverage check did not clear the cold reader's report against EVERY part of the permitted ranges THEN a cold reader's verdict MUST carry malformed.
Verdict 6: IF the model fails to compile, fails to type-check OR has no initial state THEN a formal engine's verdict MUST carry malformed.
Verdict 7: A formal engine's verdict MAY carry holds ONLY IF the buggy twin's run carried counterexample AND the explored state count stopped growing inside the bound.
Verdict 8: A formal engine's holds MUST carry the bound the run explored AND the explored state count at each depth up to the bound.
Verdict 9: IF a verdict carries malformed OR the pass formal THEN the verdict MUST NOT count toward a round.
Verdict 10: A formal engine's verdict MUST carry the pass formal.
Verdict 11: IF a formal engine's run finds no counterexample AND the buggy twin's run carried no counterexample THEN the verdict MUST carry malformed.
Verdict 12: IF a formal engine's run finds no counterexample AND the explored state count still grew at the bound THEN the verdict MUST carry malformed.
Verdict 13: A cold reader's verdict MUST carry counterexample where the cold reader read inside the permitted ranges AND the coverage check cleared the cold reader's report against EVERY part of the permitted ranges AND the cold reader reports a foundational finding.
Verdict 14: A formal engine's verdict MUST carry counterexample where the engine's run finds a counterexample.
```

Term holds: the verdict that a verifier found no foundational finding — a cold reader that read inside the permitted ranges, or a formal engine within the bound it names and no further.

Term counterexample: the verdict of such a verifier carrying one or more foundational findings, each with a site and a trace.

Term explored state count: the count of distinct states a formal engine's run has reached at each depth of the run up to the bound it explored; it grows while a deeper step reaches a state the run has not reached, and it stops growing once a step reaches none.

Term malformed: the verdict that nothing was verified — a model that did not compile, a cold reader that read past its permitted ranges or whose report the coverage check did not clear, an answer outside the contract.

Term finding: one failure a verifier reports — the site as Term site names it, the trace, and the reporter's class and finding kind — named by its finding id; Recoverable Invocation's findings register and Audit Trail's reconciliation findings are always named so.

Term finding id: the verdict key of the verdict that carries the finding, and the finding's ordinal in it — minted by the council, so an intent may carry it (Recoverable Invocation Primitive policy 10).

Term site: a span of the pattern a finding or a fragment sits in, as the snapshot carries it — a rule label or a Term name with its text, running to the end of its fenced block or declaration line, or to the next label or Term name inside the block; for a sentence outside every rule and Term, a WHY under a block of rules and an invariant's title among them, the span of all sentences outside every rule and Term under the heading it falls under, named by that heading; and the records sites: the status line, the Ledger's status, formal and last gate lines and the Ledger's open list, each in the pattern, and the Decisions heading of the pattern's history file.

Term pass: grid | eos | linus | formal — the cold reader's pass a verdict answers, as the method defines the three, or formal for a formal engine's run.

Term builder's reading: the second reading of the eos pass, in which the cold reader walks every action the pattern declares as the engineer who must build it; the deployment's own brief for the pass sets it.

---

## Composition-level invariants

- **Invariant 1 — One text per round.**
  ```
  Invariant 1.1: A council commit's intent MUST NOT PRECEDE the settling record of the commit's round in the journal's order.
  Invariant 1.2: A verdict MUST count toward a round ONLY IF the verdict carries the round's snapshot hash.
  ```
- **Invariant 2 — A repair lands on the bytes the round read.**
  ```
  Invariant 2.1: EVERY council commit MUST change the round's pattern, whose bytes at the commit's parent EQUAL the round's snapshot.
  Invariant 2.2: EVERY line a council commit changes MUST belong to the round's change set.
  ```
- **Invariant 3 — Claims are the maintainer's.**
  ```
  Invariant 3.1: A council commit MUST NOT change a site in the claim families without the maintainer's recorded ruling.
  ```
- **Invariant 4 — A repair answers the side indicted.**
  ```
  Invariant 4.1: A council commit MUST NOT change a pattern for a finding whose settled triage's side EQUALS model.
  ```
- **Invariant 5 — A deciding count is sorted twice.**
  ```
  Invariant 5.1: EVERY deciding count MUST rest on two triages, by two triagers, of EVERY counted finding of the round, the second blind to the threshold.
  ```
- **Invariant 6 — Nothing repairs a failure nobody found.**
  ```
  Invariant 6.1: A council commit MUST NOT answer a formal engine's malformed verdict.
  ```
- **Invariant 7 — Every commit reads back.**
  ```
  Invariant 7.1: EVERY council commit MUST carry the council trailer whose intent event carries the round key, the snapshot hash AND EVERY patch whole.
  Invariant 7.2: IF a conformance check of this pattern (Check 1.1 through 8.1) reads the payload of a record the journal reports Purged THEN the check MUST answer unverifiable, carrying purged-horizon, for the subject the check was reading; a sequence number read through every purge is no payload.
  Invariant 7.3: IF a council commit has a council-commit ancestor THEN the intent event the commit's trailer names MUST NOT PRECEDE, in the journal's order, the intent event the trailer of any council-commit ancestor of the commit names.
  ```
- **Invariant 8 — Repair is bounded.**
  ```
  Invariant 8.1: IF the round position a verdict's record carries EXCEEDS the round budget the round's record carries AND the round IS NOT IN the ruled rounds THEN the composition MUST NOT count the verdict toward the round.
  ```

<details markdown="block">
<summary>WHY</summary>

No conforming [Freeze] admits a round past the round budget without a standing ruling (Action wiring 34), so the state Invariant 8.1 and Check 8.1 name is the one a [Freeze] that skipped Action wiring 34 leaves; the invariant is the guard that such a round's verdicts count toward nothing. The round-budget model checks it in both directions: it holds where [Freeze] reads the count and records the round in one transaction, and its twins that let the count go stale, admit a round on any ruling or leave the round unbounded each break it (the Ledger's formal line).

</details>

Term unverifiable: a check of this pattern's answer for a subject it can judge neither way, since the journal has purged, past its retention period, a payload the check had to read (Invariant 7.2); it carries the reason purged-horizon. It is this pattern's own answer, apart from Audit Trail's verification outcome `unverifiable(reason)`, which answers a record's verification and whose reasons are closed.

Term purged-horizon: the reason an unverifiable answer of this pattern carries — the journal reports Purged for a record whose payload the check had to read.

---

## Examples

### Walkthrough — a clean round

The council freezes `compositions/immutable-ledger.md` at base commit `2f1b5c1`: [Freeze] reads the pattern at that commit from the repository and records the round under round id `r-14`, the event id of its record, with snapshot hash `a1a6621b…`. Three cold readers, none of whom has read an earlier round, are handed the snapshot and run GRID (a nine-checkpoint check of structural completeness), EOS (Essence of Software, a check of conceptual independence) with the builder's reading, and Linus; each verdict carries `a1a6621b…`, its pass and its own verifier, so each counts (Invariant 1.2, Action wiring 5). The verdicts are holds, holds and counterexample — one foundational finding, an operator's closing never sized, beside refining ones. The first triager rejects it: the protocol's open sizes against the kind's largest record, which Term true maximum on [Recoverable Invocation](./recoverable-invocation.md) makes the operator's closing too. The round's foundational count is now zero, so the count decides the round clean and is a deciding count: every counted finding goes to a second triager, another actor, whose brief carries the findings, the first triage's rejection, the method's test and the blame rule (Term blame), and not the threshold (Action wiring 11 through 13, 37). The second triager rejects it on the same text, and the round settles. [Repair] then carries the round's records and the refining cures that add no rule: the pattern at the head is still the snapshot, every cure answers a finding settled as cure, every fragment resolves to one site on the pattern or its history file and its old text is found verbatim, none sits in the claim families — the records leave the status line to the maintainer's ruling — the gate reports nothing over the repair tree it does not report over the head, the tree's diff is exactly the change set, and the commit lands on the head it was built from, carrying the council trailer. The round is clean.

### Rejection path — the pattern moved under the round

A person commits a change to one of the pattern's capability requirements while round `r-15` is between its second and third passes. The third cold reader is handed the snapshot, so its verdict carries the snapshot hash and counts; but [Repair] reads the pattern at the head, finds it no longer equal to the snapshot, and answers stale (Action wiring 15). Nothing is written, and the round's patches are void: they were sorted against a text that is no longer the pattern. The round can never be clean (Term clean round), and the pattern's round count keeps it.

### Rejection path — the engine indicts an invariant

A TLA+ run on the derived model returns a counterexample against the model's rendering of Immutable Ledger Invariant 1.3. The triage record carries side model, since no record states why the model is right; [Repair] answers gated for a pattern patch (Action wiring 20), and the cure goes to the model's re-derivation. Had the triager shown the model faithful and proposed weakening Immutable Ledger Invariant 1.3 instead, [Repair] would still answer gated (Action wiring 19), and the patch would wait in the maintainer's queue until a ruling names it. The engine's verdict moves no round's count either way (Verdict 9).

### Rejection path — the model did not compile

An Alloy adapter answers malformed: the derived model fails to type-check. [Report] escalates the verdict (Action wiring 6); no triage runs, no patch is proposed, and the round's count does not move (Verdict 9).

### Rejection path — the budget is spent

A pattern has run its round budget of rounds since its latest clean round, and no maintainer's ruling names it. [Freeze] finds the round budget does not exceed the pattern's round count, answers budget-spent and escalates the pattern to the maintainer's queue (Action wiring 34); it is no admitted freeze, so no round is recorded and no verdict can be reported against one. The pattern's next [Freeze] is admitted only after the maintainer records a ruling naming the pattern alone, which stands until the [Freeze] it admits spends it (Term standing ruling).

### Regulated adversarial scenarios

**Regulator audit — "show me every automated change to this pattern and why it was made."** The auditor reads the repository's commits by the council's trailer and, for each, the intent the trailer names (Invariant 7.1): the round, the snapshot, the patches. From the round, the journal answers the verdicts with their verifiers, the triage records with both triagers where a count decided, and the findings each patch answers. A change with no trailer is not the council's; a council commit whose diff holds a line no patch and no record accounts for fails Check 2.2.

**Disputed change — "I never authorized that change to an invariant."** A council commit cannot change a rule in the claim families without the maintainer's recorded ruling (Invariant 3.1). The rebuttal is the ruling: the journal record under the maintainer's own credential, carrying the patch byte for byte. A claim-family change with no such record is a conformance failure Check 3.1 finds.

**Breach investigation — "the council's credential was compromised; what could it have done?"** It could commit, and every commit it made carries a council trailer (Capability requirement 18, 22): one whose trailer names an intent the journal holds under the council's attestation went through [Repair], and one whose trailer names no intent the journal holds is a write outside this composition, made with the compromised credential and found by Check 7.1. It could not push (Capability requirement 12), and a claim it changed with no ruling under the maintainer's credential is a conformance failure Check 3.1 finds. The forensic window is bounded by the journal: every intent, closing and escalation is sealed and attributed by [Audit Trail](./audit-trail.md).

---

## Generation acceptance

### Conformance checks

```
Check 1.1: An auditor MUST find no council commit whose intent PRECEDES the settling of the commit's round (Invariant 1.1).
Check 1.2: An auditor MUST find EVERY counted verdict carrying the round's snapshot hash (Invariant 1.2).
Check 2.1: An auditor MUST find EVERY council commit's parent carrying the round's snapshot bytes for the round's pattern AND the commit changing the round's pattern (Invariant 2.1).
Check 2.2: An auditor MUST find EVERY line a council commit changes in the round's change set, a line of the round's pattern or of the pattern's history file (Invariant 2.2).
Check 3.1: An auditor MUST find, for EVERY council commit changing a site in the claim families, a maintainer's ruling carrying the commit's round AND the patch byte for byte (Invariant 3.1).
Check 4.1: An auditor MUST find no council commit's pattern patch answering a finding whose settled triage's side EQUALS model (Invariant 4.1).
Check 5.1: An auditor MUST find two triages under two actor references for EVERY counted finding of a settled round whose foundational count is zero (Invariant 5.1).

Check 6.1: An auditor MUST find no council commit answering a formal engine's malformed verdict (Invariant 6.1).
Check 7.1: An auditor MUST find, for EVERY council commit, the intent event the commit's trailer names in the journal under the act kind council.commit, carrying the round key, the snapshot hash, EVERY patch whole AND the commit's council nonce (Invariant 7.1).
Check 7.2: An auditor MUST find EVERY conformance check of this pattern whose reading met the payload of a record the journal reports Purged answering unverifiable, carrying purged-horizon, for that subject (Invariant 7.2); a check reading only sequence numbers is not met by a purge.
Check 7.3: An auditor MUST find no council commit with a council-commit ancestor whose intent event PRECEDES, in the journal's order, the intent event the trailer of any council-commit ancestor of the commit names, the sequence numbers read through every purge (Invariant 7.3).
Check 8.1: An auditor MUST find no counted verdict whose recorded round position EXCEEDS the round budget the round's record carries, other than in the ruled rounds (Invariant 8.1).
```

NOTE: EVERY check names the rule the check tests.

### External checks

```
External check 1: An auditor MUST clear from external evidence that EVERY cold reader read the snapshot cold (Capability requirement 3 through 5).
External check 2: An auditor MUST clear from external evidence that EVERY formal engine's holds came with the buggy twin rejected (Verdict 7).
External check 3: An auditor MUST clear from external evidence that the second and third triagers' briefs carried no threshold (Action wiring 13).
External check 4: An auditor MUST clear from external evidence that the repository took no push from the composition (Capability requirement 12).
External check 5: An auditor MUST clear from external evidence that the host supplied every council nonce, every round key AND every verdict key to one call only (Capability requirement 21, 24).
External check 6: An auditor MUST clear from external evidence that no two cold readers AND no two triagers of a round held one actor reference (Capability requirement 35).
External check 7: An auditor MUST clear from external evidence that the coverage check cleared EVERY cold reader's report against EVERY part of the permitted ranges (Capability requirement 36).
```

---

## Non-goals

```
Non-goal 1: The composition MUST NOT judge a pattern's meaning.
Non-goal 2: The composition MUST NOT choose the next pattern to verify.
Non-goal 3: The composition MUST NOT publish a commit.
Non-goal 4: The composition MUST NOT run a verifier's internals.
Non-goal 5: The composition MUST NOT privilege a formal engine.
```

NOTE: the owners — the maintainer, through the roadmap (Non-goal 2); a person (Non-goal 3).

---

## Edge cases

### Concurrency

```
Concurrency 1: Two [Repair] calls on one repository MUST serialize on the act's critical section (Recoverable Invocation open step 2.1).
```

### Indeterminate outcome

```
Indeterminate outcome 1: The commit probe MUST answer Recoverable Invocation's sweep for a council commit whose reply was lost (Recoverable Invocation reconcile step 3, Execution Contract Error model 1).
```

---

## Terms

Each `[Term]` marker above links to its term entry here.

### Vocabulary

Term actors: the composition; the constituents; the deployment; the council; the council writer; a cold reader; a formal engine; a verifier; a triager; the second triager; the third triager; the maintainer; an auditor; the sweep.

Term records: the rounds, verdicts, triage records, rulings and escalations the composition records through Audit Trail's record_action; the intents, outcomes, refusals, recovery intents and escalations Recoverable Invocation writes for the act kind council.commit.

Term record verbs: clear, answer, apply, bind, build, evaluate, exclude, inject, move, place, set, pass, repair, settle, call, carry, change, commit, compare, count, disclose, escalate, find, freeze, journal, provision, push, publish, rebuild, record, refuse, remove, rest, run, serialize, serve, supply, triage, write, accept, belong, privilege, judge, choose, close, hold, read.

Term value sets: verdict = holds | counterexample | malformed. class = foundational | refining | rhetorical. finding kind = A | B | C | D. blame = fresh | older. side = model | english | both. triage disposition = cure | route | reject | decline. pass = grid | eos | linus | formal. role = first | second | third. action reference = council.round | council.verdict | council.triage | council.ruling | council.escalation | council.commit.intended | council.commit.committed | council.commit.refused | council.commit.recovery_intended | council.commit.abandoned | council.commit.escalated.

Term bounds: round budget (round_budget), patch cap (patch_cap), gate's answer bound (gate_answer_bound), repair settling bound (repair_settling_bound), commit completion bound (commit_completion_bound), commit round trip (commit_round_trip), probe round trip (probe_round_trip).

Term qualifiers: migrated — written in GRACE lang v0.63 from the first draft (2026-10-10).

Term terms: council writer, diff check, admitted freeze, admitted report, admitted ruling, admitted repair, opened repair, change set, snapshot, snapshot hash, base commit, round, round id, search, clean round, settled round, repair tree, pattern, finding, site, pass, sound verdict, counted verdict, patch, fragment, claim families, side, role, triage record, settled triage, deciding count, round's records, records fragment, maintainer's queue, maintainer's ruling, standing ruling, round budget, patch cap, sweep identity, commit binding, commit partition, commit probe, commit envelope, council commit, council nonce, council trailer, finding id, counted finding, foundational count, round position, ruled round, target, settling record, declared name, blocking sibling, permitted ranges, round key, parted finding, verdict key, counted triage, admitted triage, round index, triage index, ruling index, round count, repository, corpus gate, report refusal order, triage refusal order, ruling refusal order, repair refusal order, stated count, council, cold reader, builder's reading, status heading, buggy twin, method's test, threshold, downgraded finding, unverifiable, purged-horizon, escalation, open escalation, finding kind, triage disposition.

Term snapshot: a pattern's bytes at a base commit, named by the base commit and the snapshot hash.

Term snapshot hash: the SHA-256 (the Secure Hash Algorithm with a 256-bit digest) of the pattern's bytes at the base commit.

Term base commit: the repository commit a round's snapshot was taken from.

Term round id: the event id of the round's record — what [Report], [Triage], [Rule] and [Repair] name a round by.

Term pattern: a canonical document under the repository — one pattern's file.

Term round: three passes — GRID, EOS with the builder's reading, Linus — by three cold readers, each handed one snapshot.

Term search: passes over moving text, each reading the pattern live rather than one snapshot; it counts toward nothing, and a round whose cold readers are handed the snapshot is never one.

Term clean round: a settled round whose foundational count is zero and one of whose repairs' invocations closed council.commit.committed, as Recoverable Invocation's read invocation answers it for the invocation id the round index carries (Recoverable Invocation read invocation 3a), with no blocking sibling at that repair's intent. A clean round decides council records — a round [Freeze] records, a verdict [Report] counts — and no write of the act kind council.commit, so Recoverable Invocation read invocation 15, which governs a write of the act decided on that read, does not reach it.

Term blocking sibling: another round of the same pattern and snapshot hash that, at a given instant, is settled with a foundational count above zero, or is unsettled with a counted finding its reporter classed foundational.

Term cited: open, close, refuse, yield, lost, answered, act kind, act key, commit, pairing datum, repeatable, act probe, invocation completion bound, commit round trip, probe round trip, journal, retention period, settling period, compliance surface, hard alert, service identity, outcome envelope, critical section, act-in-flight, section-unavailable, journal-unavailable, recording-failure, true maximum, database candidates, resolve, intent event id, read invocation, pause bound, open result: Recoverable Invocation. record_action, read_record, reference length cap, full enumeration: Audit Trail. The sections titled What DONE means, Formal-model authoring pitfalls, Where the journey gets recorded and Lawful destruction is answered before absence: `pressure-testing.md`. The section titled Composition state: `execution-contract.md`.

#### Freeze

The action that opens a round: it reads the pattern at the base commit from the repository, answers budget-spent for a pattern past its round budget with no standing ruling and escalates it, records the round, and answers the round id and the snapshot every verdict of the round must carry.

Kind: Operation

#### Report

The action that records one verifier's verdict against a round's snapshot, refuses a verdict about other bytes, or for a pass or from a verifier already counted, and escalates a malformed one, a malformed verdict of a settled round answered late-malformed and never recorded.

Kind: Operation

#### Triage

The action that records one triager's sorting of one of a round's counted findings or of a formal engine's findings — role, class, finding kind, blame, side and triage disposition — first; second and blind, by another triager, where a count decides an outcome; and third, by a third triager, where the two part.

Kind: Operation

#### Rule

The action through which the maintainer records a ruling: one claim-family patch admitted, or one more round of a pattern past its round budget.

Kind: Operation

#### Repair

The action through which the council writes: it checks every precondition against the round's settled triages, the maintainer's rulings and the pattern at the head, builds its own tree from the head with the round's patches and records applied as one change, runs the corpus gate, checks the diff, and commits through [Recoverable Invocation](./recoverable-invocation.md) with the council trailer, on the head it built from.

Kind: Operation

<!-- Term registry — shortcut-reference definitions. -->

[Freeze]: #freeze
[Report]: #report
[Triage]: #triage
[Rule]: #rule
[Repair]: #repair

## Standards references

None. The composition makes no regulatory claim of its own; the records it keeps are [Audit Trail](./audit-trail.md)'s, and a deployment that needs a standard's evidence reads that pattern's references.

## Status

`doing` — see the Ledger.

<details markdown="block">
<summary>
    <h2 id="ledger" style="display: inline-block; margin-left: 1.5rem;">Ledger</h2>
</summary>

```
status: doing
formal: verified — vote yes: one writer per repository, no repair before the round settles and the round's bounded repair; verified-repair.tla + 4 twins + 3 probes (the commit path, Invariant 2.1, 2.2, 7.3 and Concurrency 1: two rounds, two [Repair] calls a round with commits in flight and no commit fence, one person commit; 61,659 states, and 263,067 with two person commits, past the harness's cap), verified-repair-settle.tla + 3 twins + 2 probes (the round's settling, Invariant 1.1 and 5.1: two verifiers on one pass, three triage records, each call's read and its record one transaction; 628 states, and 2,824 with four triage records), verified-repair-budget.tla + 3 twins + 2 probes (the round budget, Invariant 8.1: three freezes and one ruling, each freeze's read of the count and its round one transaction; 56 states, and 399 with four freezes and two rulings), the two re-derived 2026-10-21 on the journal's store (Capability requirement 28), each with a twin that takes Execution Contract Store 2 and Store 3 away; the settling model found Term counted finding counting a malformed verdict written after the settling record, cured on the page; verified-repair.als + 11 twins (the static data model, 2026-11-12: Invariant 1.2, 3.1, 4.1, 6.1 and 7.1 checked on every state the freezes, reports, triages, rulings and committed repairs can leave, Invariant 2.1 a cross-check with the commit path; nothing testable in Alloy for Invariant 7.2 (it says what an auditor's check answers over a purged payload, which no action writes); Invariant 1.1, 2.2, 5.1, 7.3 and 8.1 left to the TLA+ models (each an order the records alone do not keep); the model found that no capability requirement provisions the writer's actor reference apart from the maintainer's, as Capability requirement 10 does for the sweep identity, so one reference lets the writer record the ruling that admits its own claim-family patch); coverage 2026-11-10 (unit formal: more coverage for the yes votes), 2026-11-12: no owed rows, 2026-10-21
last gate: 2026-11-23 — Final Critique 34, a delta round, frozen at 26faf12 — foundational count 1, not clean, no sample (Linus's one report, filing three foundational items: one kept and cured, [Report]'s round-closed refusal obliged by Action wiring 6 to keep an escalation record that Execution Contract Read 4 and Read 7 erase for a refused call, cured by listing late-malformed on [Report]'s answers line for a malformed verdict of a settled round (Action wiring 47, 51, 90, Term admitted report), as Read 7 asks, with no change to the Execution Contract, and the same finding at [Repair] refuted, gated standing on its answers line; Capability requirement 14's window placed not foundational, since Recoverable Invocation's Instance start 5 and its closure-window invariant hold the retention period above the examine window end plus the settling period measured from the intent's recording, the sentence now saying so; Term deciding count's two sentences placed not foundational, its own second sentence deciding that a count above zero is no deciding count, the opening reworded; and four refining items and one rhetorical item cured: Capability requirement 23's citation of Action wiring 15 and Invariant 2.1, Term builder's reading's citation, Term council nonce's earlier commit, Capability requirement 26's one parent, Term round id's [Rule]); 2026-11-23 — Final Critique 33, a full round, frozen at 5561d41 — foundational count 9, not clean, one sample (GRID 6, EOS 4, Linus 4 reported; nine distinct kept and cured: a cold reader's verdict left open between counterexample and malformed where the coverage check did not clear (Verdict 5, 13, 14); Capability requirement 23's repair in more than one call against Action wiring 15 and Invariant 2.1, cured to one call; Composes 6's five action references; [Freeze]'s stale and budget-spent with no order (Action wiring 34); Action wiring 89 with no trigger or bound; an escalation obliged and forbidden for one subject (Action wiring 34b, 6, 30); Action wiring 86 keeping a round's records behind a blocking sibling; Action wiring 85 against Action wiring 76; Action wiring 17 for a history-file site; the walkthrough finding refuted, since a refining finding of finding kind A settles as cure, and the [Triage] refuses-line finding refuted by Action wiring 82 and Execution Contract Refusal 1; the refining items cured, and five citations of entries `pressure-testing.md` no longer holds re-pointed to What DONE means); 2026-11-16 — Final Critique 32, a delta round, frozen at 3935761 — foundational count 0 after the blind second triage, clean, no sample (Linus's one report, filing three foundational items, all placed not foundational: Primitive policy 16 and Primitive policy 3, a comma list read as all-missing or any-missing, placed refining B by the first triage and refuted by the second, since the grammar's flat OR and Verdict 3 and Action wiring 8 forbid the all-missing reading, and cured with one "no" for each item under OR, at Primitive policy 4 too; a change between [Freeze] and [Repair] breaking Invariant 2.1, refuted by Action wiring 15, which answers stale before the tree is built; and three refining items, Capability requirement 24 cured, Verdict 4's read bound a new open line 2026-11-16-h, and [Repair]'s gated answer refuted by the signature's answers line and Execution Contract Read 7); 2026-11-16 — Final Critique 31, frozen at ad6a8a3 — foundational count 3, not clean, one sample
open: none
```

</details>

<details markdown="block">
<summary>
    <h2 id="decisions" style="display: inline-block; margin-left: 1.5rem;">Decisions</h2>
</summary>

Decisions are kept in [the pattern's history](./verified-repair.hist.md#decisions), one dated entry for each turn the pattern took; everything smaller lives in the commit that made it: `git log -- compositions/verified-repair.md`.

</details>

NOTE: End of Verified Repair.
