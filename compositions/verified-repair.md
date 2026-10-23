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

Verified Repair is the loop written so that none of the three happens without a rule refusing it. **No change to a canonical page lands unless it answers a reported failure read off one frozen snapshot, sorted twice where a count decides an outcome, aimed at the side the failure indicts, kept out of the page's claims, applied by one writer to the bytes it was read from, and recorded** — so that the whole chain, snapshot to verifier to verdict to finding to triage to patch to diff to commit, is provable.

What the composition is not. It is not a verifier: readers and engines are the deployment's, held to the verdict contract here. It is not a judge of meaning: a change to what a page claims is the maintainer's, and so is any easy decision a rule does not settle. It is not a write protocol: every commit it makes is a [Recoverable Invocation](./recoverable-invocation.md) act, so the one-writer rule, the intent before the commit, the yield on a lost reply and the sweep after a crash are that page's and are cited here, not restated. And it is not tied to an engine: Alloy, TLA+ and any heavier logic sit beneath one verdict contract, as readers do.

---

## Composes

- **[Recoverable Invocation](./recoverable-invocation.md)** — the protocol of the composition's one irreversible write, a commit to the repository.
- **[Audit Trail](./audit-trail.md)** — the journal of rounds, verdicts, triage records, rulings and escalations, and the protocol's journal.

```
Composes 1: EXACTLY ONE Recoverable Invocation instance MUST serve the composition.
Composes 2: EXACTLY ONE Audit Trail instance MUST serve the composition.
Composes 3: The Recoverable Invocation instance MUST journal to the composition's Audit Trail instance.
Composes 4: The composition MUST bind EXACTLY ONE act kind to the Recoverable Invocation instance: council.commit, under the commit binding.
Composes 5: The composition MUST NOT write the repository other than through the act kind council.commit.
Composes 6: The composition MUST record EVERY round, verdict, triage record, ruling AND escalation through Audit Trail's record_action.
Composes 7: The composition MUST NOT change a constituent's contract other than through a round on the constituent's page.
```

Term composition: this pattern's wiring of [Recoverable Invocation](./recoverable-invocation.md) and [Audit Trail](./audit-trail.md) — the round, the verdict contract, the triage, the repair and the escalations below.

Term constituents: [Recoverable Invocation](./recoverable-invocation.md), [Audit Trail](./audit-trail.md).

Term commit binding: the act kind's bindings, each under the name Recoverable Invocation gives it. act key — the repository. commit — the repository commit, read through the commit partition. commit fence — none. pairing datum — the council nonce, which the intent data carries and the database keeps in the commit's trailer: an adopter-minted nonce the database stores. repeatable — yes. probe — the commit probe. completion bound — the commit completion bound. commit round trip and probe round trip — the deployment's disclosed bounds. journal — the composition's Audit Trail instance, with council.commit.intended, the one outcome council.commit.committed, and council.commit.refused. retention period — the journal retention policy's, which places every council record under the same policy as the act kind's (Capability requirement 17). service identity — the sweep identity. outcome envelope — the commit envelope. retry terminus — lease. Deviations: none.

Term commit partition: committed — the database answers a commit id; pre-commit — the database refuses with nothing written, carrying lock-held, conflict where the head is not the commit's parent (Capability requirement 13) OR hook-rejected — the codes the database's contract declares pre-commit (Capability requirement 15); unknown — no answer, or a reply the database's contract does not declare.

Term commit probe: the repository's read by trailer value (Capability requirement 2) for the commits whose trailer carries the intent's council nonce — committed carrying council.commit.committed and the commit id where exactly one does, not-committed where none does, undecidable carrying the commit ids where more than one does, and unavailable where the read refuses or gives no answer. The read is scoped to the act key's repository, so every commit it finds carries the act key by construction (Recoverable Invocation probe 8).

Term commit envelope: the act kind's outcome envelope — the true maximum of the records the kind writes: the committed outcome, one commit id at its minted width, or a closing the sweep or the maintainer writes, whichever the substrate sizes largest, serialized as the substrate sizes it; the database candidates of a council.commit.escalated hold at most one commit, since no two commits carry one council nonce (Capability requirement 19). The intent, which alone carries the round key, the snapshot hash, every patch whole and the council nonce, is sized beside it by the invocation open (Recoverable Invocation Primitive policy 12).

Term council nonce: the nonce injected at the writer's seam for one [Repair] call, carried by no earlier council.commit intent and by no commit of the repository (Capability requirement 19, 21) — the act kind's pairing datum, carried in the intent data and in the commit's trailer.

Term council commit: a commit of the repository carrying a council trailer.

Term council trailer: the trailer a council commit carries — the council nonce and the intent event id the invocation open answered.

---

## Composition logic

### Composition state

```
Composition state 1: The composition MUST rebuild the round index, the triage index, the ruling index AND the round count from the journal's full enumeration, the sequence-range read Audit Trail passes through (Audit Trail Action wiring 1).
Composition state 2: The journal MUST hold EVERY round, verdict, triage record, ruling AND escalation the composition keeps.
```

Term round index: map from a page to the page's rounds — each round's id, key, snapshot and counted verdicts by pass, whether the round has settled, and the invocations whose intents carry its key. Derived index, rebuilt from what the journal still holds; past the journal's retention period a purged round drops out.

Term round key: the nonce injected at [Freeze]'s seam for one round and recorded with it — what an intent names the round by, minted by the council and not by the substrate or the repository (Recoverable Invocation Primitive policy 10), and unique (Capability requirement 24).

Term verdict key: the nonce injected at [Report]'s seam for one verdict and recorded with it — what a finding id names the verdict by (Capability requirement 24).

Term triage index: map from a round to the round's triage records, each finding's first, second and third records kept apart. Derived index, rebuilt from what the journal still holds; past the journal's retention period a purged triage record drops out.

Term ruling index: map from a page, and from a round and a patch id, to the maintainer's rulings naming them. Derived index, rebuilt from what the journal still holds; past the journal's retention period a purged ruling drops out.

Term round count: map from a page to the number of rounds frozen on the page since the page's latest clean round. Derived index. Past the journal's retention period a purged round drops out of the count, so a page whose unclean rounds outlive their records is re-admitted without a ruling: a limit this page accepts, which a deployment retaining council records longer than a page's unclean rounds span never meets. A round whose [Freeze] answered recording-failure(step-3) or no answer, and whose record landed, counts too: a cost this page accepts, the budget running one round short for each such loss.

### Capability requirement

```
Capability requirement 1: A deployment MUST supply a repository whose commit takes a tree, a parent AND a trailer, AND whose reply, where one comes, carries EXACTLY ONE OF a commit id, a refusal with nothing written.
Capability requirement 2: A deployment MUST supply a repository read that finds a commit by a trailer value.
Capability requirement 3: A deployment MUST supply EVERY reader the permitted ranges alone, the snapshot's permitted lines included.
Capability requirement 4: A deployment MUST NOT supply a reader the lines of a page that follow the page's Status heading.
Capability requirement 5: A deployment MUST NOT supply a reader the record of an earlier round of the page.
Capability requirement 6: A deployment MUST supply EVERY formal engine the model derived from the snapshot, the model's buggy twin AND the bound the run explores.
Capability requirement 7: A deployment MUST disclose the round budget, the patch cap, the commit completion bound, the commit round trip, the probe round trip, the permitted ranges, the writer's actor reference AND the maintainer's actor reference.
Capability requirement 8: A deployment MUST supply the maintainer's queue.
Capability requirement 9: A deployment MUST supply the corpus gate.
Capability requirement 10: A deployment MUST provision the sweep identity apart from EVERY other actor reference that writes the journal (Recoverable Invocation service identity 3).
Capability requirement 11: The repository MUST NOT remove a commit.
Capability requirement 12: The repository MUST NOT accept a push from the composition.
Capability requirement 13: The repository's commit MUST refuse with conflict where the head DOES NOT EQUAL the commit's parent.
Capability requirement 14: A deployment MUST settle EVERY council.commit.escalated through Recoverable Invocation's resolve, under the maintainer's actor reference, BEFORE the journal's retention period purges the escalated invocation's intent.
Capability requirement 15: The repository's refusal with nothing written MUST carry EXACTLY ONE OF lock-held, conflict, hook-rejected.
Deleted: Capability requirement 16. Execution Contract Database 2 and Execution Contract Database 3 own it: a read inside an action's transaction shows every record committed ahead of it, and a record whose write is still in flight commits behind every record a read has shown.
Capability requirement 17: A deployment MUST place EVERY council record under the retention policy the journal applies to the act kind council.commit.
Capability requirement 18: IF a commit carries a council trailer AND the committing actor DOES NOT EQUAL the writer THEN the repository MUST refuse the commit.
Capability requirement 19: IF a commit's council nonce IS IN the council nonces the repository's commits carry THEN the repository MUST refuse the commit.
Capability requirement 20: The repository MUST NOT move the head to a commit that does not descend from the head.
Capability requirement 21: A deployment MUST inject a council nonce that no council.commit intent has carried.
Capability requirement 22: IF the committing actor EQUALS the writer AND the commit carries no council trailer THEN the repository MUST refuse the commit.
Capability requirement 23: A deployment MUST set EVERY payload cap the journal applies above the largest verdict, triage record, ruling, escalation AND council.commit intent the deployment's verifiers, triagers, maintainer AND council produce, the intent's every patch whole included.
Capability requirement 24: A deployment MUST inject a round key AND a verdict key that the journal holds for no other record.
Capability requirement 25: A deployment MUST supply a repository read of a page at a commit that answers EXACTLY ONE OF the page's bytes, absent, a refusal.
Capability requirement 26: A deployment MUST supply a repository read of a commit by the commit id that answers EXACTLY ONE OF the commit's parent ids with the commit's trailer, absent, a refusal.
Capability requirement 27: A deployment MUST refuse EVERY record_action under the action references council.round, council.verdict, council.triage, council.ruling AND council.escalation from EVERY caller other than the composition's own actions.
Capability requirement 28: A deployment MUST supply the journal's database PER Execution Contract Database 1 through 3 and Execution Contract Refusal 1.
```

Term repository: the version-controlled database holding the canonical pages — one head, commits that carry trailers, a commit taken only on the head it names as its parent, a read by trailer, and a read of a commit's parents and trailer by its id.

Term permitted ranges: the lines a reader may read, each at the snapshot's base commit — the snapshot's lines ahead of its Status heading, the lines ahead of the Status heading of every page the snapshot's page composes, and the method's sections the deployment discloses (Capability requirement 7). A composed page that moves before the round's repair does not stale the round: a cost this page accepts and leaves to the next round's readers.

Term reader: a verifier that is a language model or a person running one pass of the method on a snapshot, having read no earlier round of the page.

Term formal engine: a verifier that checks the model derived from a page — Alloy, TLA+, or a heavier logic a property requires — through an adapter that answers the verdict contract.

Term verifier: a reader OR a formal engine.

Term maintainer: the person who holds the corpus's semantic authority.

Term maintainer's queue: the surface the maintainer reads the council's escalation records and Recoverable Invocation's council.commit.escalated closings from, each carrying the round, the finding, patch or page, and the one line that asks.

Term corpus gate: the deployment's whole-corpus surface check — `python3 tools/grace/check.py --gate` in this repository — answering its findings, each named by its file, code and message, the line aside.

Term round budget: the most rounds a page may run without a clean round before the composition escalates the page.

Term patch cap: the most patches one commit may carry.

Term admitted freeze: a [Freeze] call no rule refused.

Term admitted report: a [Report] call no rule refused.

Term admitted ruling: a [Rule] call no rule refused.

Term admitted triage: a [Triage] call no rule refused.

Term admitted repair: a [Repair] call no rule refused before the invocation open.

Term opened repair: an admitted repair whose invocation open answered an open result.

Term writer: the council's one writer to the repository, under the writer's own actor reference and credential; the sweep identity is not the writer.

Term diff check: Action wiring 25's comparison of the repair tree's diff from the head with the change set.

Term sweep identity: the commit binding's service identity, under which Recoverable Invocation's sweep closes the invocation of a council commit that died.

### Primitive policy

```
Primitive policy 1: IF the page OR the base commit EQUALS blank THEN [Freeze] MUST answer invalid-request.
Primitive policy 2: IF the page IS NOT IN the repository at the base commit THEN [Freeze] MUST answer not-known.
Primitive policy 3: IF a verdict carries no snapshot hash, no base commit, no verifier, no pass, no verdict value OR holds with a finding the verifier classed foundational THEN [Report] MUST answer invalid-request.
Primitive policy 4: IF the call carries no patch, a patch carries no patch id, no fragment OR a fragment with no target THEN [Repair] MUST answer invalid-request.
Primitive policy 5: IF the count of a commit's patches EXCEEDS the patch cap THEN [Repair] MUST answer invalid-request.
Primitive policy 6: The composition MUST compare a snapshot hash, a commit id, a finding id AND a fragment byte-exact.
Primitive policy 7: IF the repository's name OR the writer's actor reference EXCEEDS the reference length cap THEN [Repair] MUST answer invalid-request (Recoverable Invocation Primitive policy 1, 8).
Primitive policy 8: [Freeze], [Report], [Triage] AND [Rule] MUST NOT write the action's own record BEFORE EVERY rule of the action that answers a refusal has answered no refusal, other than Primitive policy 13, 15 AND 17, which answer the write's own failure.
Primitive policy 9: IF a round is given AND the round names no round the journal holds THEN [Report], [Triage], [Rule] AND [Repair] MUST answer not-known.
Primitive policy 10: IF a read of the repository refuses OR gives no answer THEN [Freeze] AND [Repair] MUST answer repository-unavailable; a read that answers absent is no refusal (Capability requirement 25).
Primitive policy 11: IF a read of the journal the action makes directly OR through Recoverable Invocation's read invocation refuses OR gives no answer THEN [Freeze], [Report], [Triage], [Rule] AND [Repair] MUST answer journal-unavailable.
Primitive policy 12: [Freeze], [Report], [Triage], [Rule] AND [Repair] MUST pass the caller's actor reference AND credential through to EVERY record_action the action calls directly.
Primitive policy 13: IF the record_action that writes the action's own record refuses at a step other than step-4 THEN [Freeze], [Report], [Triage], [Rule] AND [Repair] MUST answer record_action's code with the code's step.
Primitive policy 14: IF the page EQUALS blank, a patch comes with no round OR a round comes with no patch THEN [Rule] MUST answer invalid-request.
Primitive policy 15: IF an escalation's record_action refuses at a step other than step-4 THEN the escalating action MUST answer record_action's code in place of the escalating action's own answer; an escalation refused at step-4 stands, and that answer is given.
Primitive policy 16: IF a triage record carries no role, class, kind, blame, side OR disposition, OR carries the role third with no settling text, THEN [Triage] MUST answer invalid-request.
Primitive policy 17: IF the record_action that writes the action's own record refuses at step-4 THEN the action MUST answer as an admitted call, [Freeze] with the event id the refusal carries as the round id (Audit Trail record action step 7.16).
Primitive policy 18: IF a triage record's disposition DOES NOT EQUAL reject AND the disposition DOES NOT EQUAL the one Term disposition pairs with the record's kind THEN [Triage] MUST answer invalid-request.
Primitive policy 19: IF a triage record's disposition EQUALS cure AND the record carries no patch THEN [Triage] MUST answer invalid-request.
Primitive policy 20: IF the page of a round given to [Rule] DOES NOT EQUAL the ruling's page THEN [Rule] MUST answer not-known.
Primitive policy 21: IF the journal reports Purged for a given round's record THEN [Report], [Triage], [Rule] AND [Repair] MUST answer purged.
Primitive policy 22: IF the call gives no round AND the journal holds no round of the page THEN [Rule] MUST answer invalid-request.
```

### Action wiring

```
freeze(page, base_commit, actor_ref, credential)
  answers round id and snapshot
  refuses invalid-request | repository-unavailable | journal-unavailable | not-known | stale | budget-spent | invalid-request(step) | invalid-credential | recording-failure(step)

report(round, verdict, actor_ref, credential)
  answers recorded
  refuses invalid-request | journal-unavailable | purged | not-known | round-closed | stale | already-counted | invalid-request(step) | invalid-credential | recording-failure(step)

triage(round, finding, record, actor_ref, credential)
  answers recorded
  refuses invalid-request | invalid-request(step) | invalid-credential | not-known | purged | already-triaged | round-closed | journal-unavailable | recording-failure(step)

rule(page, round, patch, actor_ref, credential)
  answers recorded
  refuses invalid-request | invalid-request(step) | invalid-credential | not-known | purged | journal-unavailable | recording-failure(step)

repair(round, patches, actor_ref, credential)
  answers commit id
  refuses invalid-request | invalid-request(step) | invalid-credential | not-known | purged | stale | unsettled | unresolved | mismatch | gated | gate-red | repository-unavailable | lock-held | conflict | hook-rejected | act-in-flight(invocation_id) | section-unavailable | journal-unavailable | recording-failure(intent) | recording-failure(outcome) | already-accounted(closing_event_id) | recording-failure(refusal, constituent_code) | recording-failure(step)
```

#### [Freeze]

```
Deleted: Action wiring 1. Action wiring 2 owns it: the round is recorded from the page the repository holds at the base commit, never from a checked-out copy.
Action wiring 2: An admitted freeze MUST record the round with the page, the base commit, the snapshot hash, the round budget AND the round key.
Action wiring 3: An admitted freeze MUST answer the round id AND the snapshot: the snapshot hash AND the base commit.
Action wiring 34: WHEN the round budget DOES NOT EXCEED the page's round count AND the page carries no standing ruling:
    Action wiring 34a: [Freeze] MUST answer budget-spent.
    Action wiring 34b: [Freeze] MUST escalate the page to the maintainer's queue.
Action wiring 57: IF the page at the base commit DOES NOT EQUAL the page at the repository's head THEN [Freeze] MUST answer stale; a page absent at the head equals no page at the base commit.
Deleted: Action wiring 59. Execution Contract Refusal 1 owns it: the budget answers last, after Primitive policy and staleness.
Deleted: Action wiring 67. Execution Contract Refusal 1 owns it: staleness answers after Primitive policy 2.
Deleted: Action wiring 72. Execution Contract Refusal 1 owns it.
```

#### [Report]

```
Action wiring 4: IF the verdict's snapshot hash DOES NOT EQUAL the round's snapshot hash THEN [Report] MUST answer stale.
Action wiring 5: IF a counted verdict of the round carries the verdict's pass OR the verdict's verifier THEN [Report] MUST answer already-counted.
Action wiring 6: IF the verdict carries malformed THEN [Report] MUST escalate the verdict to the maintainer's queue.
Action wiring 7: An admitted report MUST record the verdict with the verdict key, the round id AND the round's position.
Action wiring 47: IF the round IS IN the round index's settled rounds THEN [Report] AND [Triage] MUST answer round-closed.
Deleted: Action wiring 48. Action wiring 34 and Execution Contract Database 2 own it: [Freeze]'s read of the round count and its record of the round are one transaction, so no round is recorded past the round budget but one a standing ruling admits.
Action wiring 51: [Report] MUST NOT evaluate Action wiring 6 BEFORE EVERY rule of the report refusal order has answered no refusal.
Deleted: Action wiring 58. Execution Contract Database 2 and Execution Contract Database 3 own it: every round ahead of the round's record committed ahead of it, so [Report] reads the round position with no round still landing.
Action wiring 60: [Report] MUST NOT evaluate Action wiring 7 BEFORE Action wiring 6 has answered.
Deleted: Action wiring 73. Execution Contract Refusal 1 owns it.
```

Term sound verdict: a recorded verdict of a round carrying holds or counterexample — a reader's or a formal engine's.

Term counted verdict: for each of the round's reader passes, grid, eos and linus, the earliest sound verdict recorded for the pass from a verifier no earlier counted verdict of the round carries — the verdicts a round counts (Invariant 1.2, Verdict 9); a later verdict for a pass or from a verifier already counted is refused (Action wiring 5).

Term counted finding: a finding a counted verdict carries, or a finding a reader's malformed verdict of the round carries where the round has no settling record or the verdict is recorded no later than the settling record — the malformed verdict counts for nothing, and the findings it carries stand (Verdict 9, the entry *A lapsed pass does not count* in `pressure-testing.md`).

Term round position: the number of rounds frozen on a page since the page's latest clean round preceding the round, counted in the journal's order up to and including the round.

Term ruled round: a round whose record follows a maintainer's ruling naming the page alone, with no other round of the page recorded between them.

Term report refusal order: Primitive policy 3, Primitive policy 11, Primitive policy 21, Primitive policy 9, Action wiring 47, Action wiring 4, Action wiring 5 — [Report]'s refusal rules, earliest first.

#### [Triage]

```
Action wiring 8: A triage record MUST carry the role, the finding's class, kind, blame, side AND disposition.
Action wiring 9: IF the finding came from a formal engine AND the record's side DOES NOT EQUAL model AND the record carries no reason the model is right THEN [Triage] MUST answer invalid-request.
Action wiring 10: An admitted triage MUST record the triage record under the triager's own actor reference.
Action wiring 11: IF the round's foundational count EQUALS zero THEN the composition MUST NOT count the round as settled BEFORE EVERY counted finding of the round carries a counted triage in the role second.
Action wiring 12: The second triager's brief MUST carry the findings, the first triage's downgraded and rejected findings, the method's test AND the blame rule, the test being the class definitions without the sentences that say what count grounds a page.
Action wiring 13: The second and third triagers' briefs MUST NOT carry the threshold the count is read against.
Action wiring 14: IF a counted finding IS IN the parted findings THEN the composition MUST NOT count the round as settled BEFORE the finding carries a counted triage in the role third carrying the text that settles the finding.
Action wiring 69: The composition MUST NOT count the round as settled BEFORE EVERY finding a formal engine's sound verdict of the round carries carries a counted triage.
Action wiring 35: IF the finding IS NOT IN the round's counted findings AND no formal engine's sound verdict of the round carries the finding THEN [Triage] MUST answer not-known.
Action wiring 36: IF the round carries a counted triage of the finding in the record's role THEN [Triage] MUST answer already-triaged.
Action wiring 37: IF the round carries a triage record of the finding in another role under the caller's actor reference THEN [Triage] MUST answer invalid-request.
Action wiring 43: IF the record's role EQUALS second AND the round carries no counted triage of the finding in the role first THEN [Triage] MUST answer invalid-request.
Action wiring 44: IF the record's role EQUALS third AND the finding IS NOT IN the parted findings THEN [Triage] MUST answer invalid-request.
Deleted: Action wiring 64. Action wiring 74 owns it: not-known is evaluated last.
Deleted: Action wiring 65. Action wiring 74 owns it: already-triaged is evaluated after the invalid requests.
Deleted: Action wiring 70. Action wiring 74 owns it: round-closed is evaluated ahead of the rest of [Triage]'s Action wiring.
Deleted: Action wiring 71. Action wiring 74 owns it: round-closed is evaluated after Primitive policy.
Action wiring 74: [Triage] MUST NOT evaluate a rule of the triage refusal order BEFORE EVERY earlier rule of the triage refusal order has answered no refusal.
```

Term class: foundational | refining | rhetorical — as the section titled What "grounded" means in `pressure-testing.md` defines each.

Term kind: A | B | C | D — the triage fields of `pressure-testing.md`.

Term blame: fresh | older — fresh where the site was written or changed within the page's last two rounds.

Term side: model | english | both — which text a finding indicts: the derived model, the page, or the two.

Term disposition: cure | route | reject | decline — cure for a kind-A finding, route for kind B or C, decline for kind D, reject where the text already answers it.

Term deciding count: a count an outcome turns on — a round's foundational count where it is zero, since a zero decides the round clean.

NOTE: open 2026-10-17-g — the entry A count that decides something is triaged twice in `pressure-testing.md` reaches every count an outcome turns on, a count above zero on the round that brings the page's round count to the round budget among them, where this Term names the zero count alone.

Term foundational count: the number of a round's counted findings whose settled triage carries the class foundational and a disposition other than reject.

Term parted finding: a finding whose earliest counted first and second triages differ on the class, the side or the disposition.

Term role: first | second | third — which triage of a finding a record is.

Term triage record: one triager's sorting of one finding of a round — the role, class, kind, blame, side and disposition, the patch whole where the disposition is cure, a reason where a formal engine's finding is sided other than model, and for a third triage the text that settles — recorded under the triager's actor reference.

Term counted triage: a triage record of a finding, up to the round's settling record, whose actor holds no earlier record of the finding in another role — the triage records every rule of this page reads.

Term settled triage: among a finding's counted triages, the earliest third where one exists, otherwise the earliest second, otherwise the earliest first.

Term settled round: a round with a settling record — reading the round's journal records in the journal's order, the first record after which the round carries a counted verdict for each reader pass and every counted finding and every finding a formal engine's sound verdict carries carries a settled triage, under Action wiring 11, 14 and 69.

Term settling record: the record at which a round settles.

Term triager: the agent OR person that sorts a finding.

Term triage refusal order: Primitive policy 16, Primitive policy 18, Primitive policy 19, Primitive policy 11, Primitive policy 21, Primitive policy 9, Action wiring 47, Action wiring 9, Action wiring 37, Action wiring 43, Action wiring 44, Action wiring 36, Action wiring 35 — [Triage]'s refusal rules, earliest first.

#### [Rule]

```
Action wiring 38: IF the actor reference DOES NOT EQUAL the maintainer's actor reference THEN [Rule] MUST answer invalid-credential.
Action wiring 39: An admitted ruling MUST record the ruling with the page, the page's latest round AND, where given, the round AND the patch whole.
Deleted: Action wiring 66. Action wiring 75 owns it: the maintainer's credential is evaluated after Primitive policy.
Action wiring 75: [Rule] MUST NOT evaluate a rule of the ruling refusal order BEFORE EVERY earlier rule of the ruling refusal order has answered no refusal.
```

Term maintainer's ruling: a ruling record under the maintainer's actor reference — carrying a page, a round and a patch whole, it admits that patch, byte for byte, into the claim families in that round; naming a page alone, it admits the page's next round past its round budget.

Term standing ruling: a maintainer's ruling naming a page alone, together with the round that was the page's latest when the ruling was recorded, standing while that round is still the page's latest — spent by the next [Freeze] it admits, whatever copy of it lands later.

Term ruling refusal order: Primitive policy 14, Primitive policy 11, Primitive policy 21, Primitive policy 9, Primitive policy 20, Primitive policy 22, Action wiring 38 — [Rule]'s refusal rules, earliest first.

#### [Repair]

```
Action wiring 15: IF the page at the repository's head DOES NOT EQUAL the snapshot's bytes THEN [Repair] MUST answer stale; a page absent at the head equals no snapshot.
Deleted: Action wiring 16. Action wiring 15 and Capability requirement 13 own it: the page at the head is the snapshot, and the commit lands only on the head it was built from.
Action wiring 17: IF the count of sites a fragment's target resolves to on the round's page DOES NOT EQUAL one THEN [Repair] MUST answer unresolved.
Action wiring 18: IF the count of a fragment's old text in the fragment's resolved site, verbatim, DOES NOT EQUAL one THEN [Repair] MUST answer mismatch.
Action wiring 19: IF a fragment's target IS IN the claim families AND no maintainer's ruling carries the round AND the fragment's patch byte-exact THEN [Repair] MUST answer gated.
Action wiring 20: IF a patch answers a finding whose settled triage's side EQUALS model THEN [Repair] MUST answer gated.
Deleted: Action wiring 21. Action wiring 34 owns it: the budget is read where a round starts.
Action wiring 22: An admitted repair MUST call the invocation open with the act kind, the repository as the act key, the writer's actor reference AND credential, AND the round key, the snapshot hash, EVERY patch whole AND the council nonce as intent data.
Action wiring 23: An admitted repair MUST build the repair tree from the head Action wiring 15 read, with EVERY fragment of EVERY patch applied as one change.
Action wiring 24: IF a finding the corpus gate reports over the repair tree IS NOT IN the gate's findings over the head Action wiring 15 read OR the gate gives no answer THEN [Repair] MUST answer gate-red.
Action wiring 25: IF the repair tree's diff from the head Action wiring 15 read DOES NOT EQUAL the change set THEN [Repair] MUST answer mismatch.
Action wiring 26: An opened repair MUST commit the repair tree with the head Action wiring 15 read as the parent AND the council trailer as the commit's trailer, WITHIN the call pause bound of the invocation open's return (Recoverable Invocation commit 14c).
Action wiring 27: IF the commit answers a commit id THEN [Repair] MUST call the invocation close with the act kind, the act key, the open result, the writer's actor reference AND credential, council.commit.committed AND the commit id as the outcome data (Recoverable Invocation close 5).
Action wiring 28: IF the commit's arm EQUALS pre-commit THEN [Repair] MUST call the invocation refusal with the act kind, the act key, the open result, the writer's actor reference AND credential, AND the database's code as the reason AND as the constituent code (Recoverable Invocation commit 2).
Action wiring 29: WHEN the commit's arm EQUALS unknown:
    Action wiring 29a: [Repair] MUST call the invocation yield with the act kind, the act key AND the invocation id, carrying the reply lost where the commit gave no answer and the reply answered where the commit's reply is one the database's contract does not declare (Recoverable Invocation yield 7).
    Action wiring 29b: [Repair] MUST answer recording-failure(outcome) (Recoverable Invocation commit 8d).
Action wiring 30: IF [Repair] answers gated under Action wiring 19, 56 OR 63 THEN [Repair] MUST escalate the patch to the maintainer's queue.
Action wiring 31: IF the round IS NOT IN the round index's settled rounds THEN [Repair] MUST answer unsettled.
Action wiring 32: [Repair] MUST NOT push.
Action wiring 33: [Repair] MUST NOT call the invocation open BEFORE the corpus gate AND the diff check have answered over the repair tree.
Action wiring 40: IF a patch answers a finding that carries no settled triage of the round with disposition cure THEN [Repair] MUST answer unresolved.
Action wiring 41: IF a patch answers no finding AND a fragment of the patch IS NOT IN the records fragments THEN [Repair] MUST answer unresolved.
Action wiring 42: IF the invocation open, close OR refusal refuses THEN [Repair] MUST answer the code Recoverable Invocation Action wiring 2 exports for the refusal.
Action wiring 45: IF the invocation refusal answers a refusal event id THEN [Repair] MUST answer the database's code (Recoverable Invocation commit 3).
Deleted: Action wiring 46. Action wiring 76 owns it: staleness and settlement are evaluated before every check on the patches.
Action wiring 49: IF the actor reference DOES NOT EQUAL the writer's actor reference THEN [Repair] MUST answer invalid-credential.
Deleted: Action wiring 50. Action wiring 76 owns it: the claim gate is evaluated last.
Deleted: Action wiring 52. Execution Contract Database 2 owns it: [Repair]'s read of the round's journal records and the intent its invocation open records are one transaction, so no record lands ahead of the settling record that read yields.
Action wiring 53: IF the stated count of a records fragment's new last gate line EQUALS blank OR the stated count DOES NOT EQUAL the round's foundational count THEN [Repair] MUST answer mismatch.
Action wiring 54: [Repair] MUST NOT evaluate Action wiring 31 BEFORE reading the round's journal records.
Action wiring 55: IF the old texts of two fragments of the change set share a byte of one site THEN [Repair] MUST answer mismatch.
Action wiring 56: IF a declared name of a fragment IS IN the claim families AND no maintainer's ruling carries the round AND the fragment's patch byte-exact THEN [Repair] MUST answer gated.
Action wiring 61: IF the change set carries no records fragment that replaces the Ledger's last gate line THEN [Repair] MUST answer invalid-request.
Action wiring 62: IF a patch answers a finding AND the patch DOES NOT EQUAL, byte-exact, the patch the finding's settled triage carries THEN [Repair] MUST answer unresolved.
Action wiring 63: IF a records fragment removes a Ledger open line AND no maintainer's ruling carries the round AND the fragment's patch byte-exact THEN [Repair] MUST answer gated.
Deleted: Action wiring 68. Action wiring 76 owns it: purged is evaluated before unsettled.
Action wiring 76: [Repair] MUST NOT evaluate a rule of the repair refusal order BEFORE EVERY earlier rule of the repair refusal order has answered no refusal.
```

Term patch: a patch id, the finding it answers, and one fragment for each sentence the change touches — the rule or Term the finding sits in and every sentence on the page that restates it; a patch carrying the round's records answers no finding.

Term fragment: a target, an old text and a new text — one sentence's change; an empty new text deletes.

Term declared name: a rule label or a Term name a fragment's new text declares.

Term target: the site a fragment changes.

Term claim families: Invariant, Check, External check — the page's claims — with every Term their rules name, directly or through another Term's definition, in the snapshot or in the repair tree, a rule naming a Term where the rule's text carries the Term's name, singular or plural, bare or possessive; the page's Intent; and the page's status line with the Ledger's status and formal lines.

Term round's records: the Ledger lines, the last gate line and the Decisions entry the round owes, written by the council; the status is the maintainer's (Term claim families).

Term records fragment: a fragment that replaces the page's status line or the Ledger's status, formal or last gate line, adds or removes a Ledger open line, or adds a Decisions entry ahead of the page's end marker — the shapes the round's records take.

Term stated count: the count a last gate line's leading entry states, as the numeral after the words foundational count — the entry a round's records write at the head of the line, a clean round's stating foundational count 0 beside the closing words the entry *A clean round is a sample* in `pressure-testing.md` asks; blank where the leading entry states no such numeral.

Term change set: every fragment of the patches one [Repair] call carries — the cures and the round's records; every line a council commit may change.

Term repair tree: the files of the head [Repair] read, with the change set applied — built by one [Repair] call apart from every other call's tree and every checked-out copy, and committed whole.

Term repair refusal order: Primitive policy 4, Primitive policy 5, Primitive policy 7, Primitive policy 10, Primitive policy 11, Primitive policy 21, Primitive policy 9, Action wiring 49, Action wiring 15, Action wiring 31, Action wiring 61, Action wiring 53, Action wiring 40, Action wiring 62, Action wiring 41, Action wiring 20, Action wiring 17, Action wiring 18, Action wiring 55, Action wiring 24, Action wiring 25, Action wiring 19, Action wiring 56, Action wiring 63 — [Repair]'s refusal rules ahead of the invocation open, earliest first; behind it the invocation's own codes answer (Action wiring 29, 42, 45).

WHY:
The escalation is the council's record, not the act's (Action wiring 30): it is written before any intent, so Recoverable Invocation Action wiring 6, which keeps an adopter's journal writes for the act to the protocol's own actions, does not reach it.

### Wiring decision

```
Wiring decision 1: The composition MUST NOT repair a round BEFORE the round settles.
Wiring decision 2: The composition MUST NOT change a site in the claim families without the maintainer's recorded ruling.
```

WHY:
*Principle.* A count is about one text, and a claim is the maintainer's. *Likely objection.* Repairing as findings arrive is faster, and an invariant the engine breaks is the invariant that is wrong. *Mechanism that resolves it.* Three passes over moving text is a search, not a round: each pass reads a text the last pass never saw, so no count compares with another (the section titled Order and iteration in `pressure-testing.md`). And the cheapest way to make an engine stop finding a counterexample is to weaken the claim it checks; a loop under pressure to converge will find that way if a rule does not close it. *Result.* Every pass is handed the snapshot (Capability requirement 3), and a repair lands after the round settles, on a head whose page is still the snapshot (Action wiring 15); a patch into an Invariant, a Check or an External check stops at the maintainer's queue until a ruling names it, whatever the round count.

### Verdict

```
Verdict 1: A verdict MUST carry EXACTLY ONE OF holds, counterexample, malformed.
Verdict 2: A verdict MUST carry the snapshot hash, the base commit, the verifier AND the pass.
Verdict 3: A verdict MUST carry EVERY finding the verifier reports, each with the finding's site, trace, class AND kind.
Verdict 4: A reader's verdict MUST carry holds where the reader read inside the permitted ranges AND reports no foundational finding.
Verdict 5: A reader's verdict MUST carry malformed where the reader read outside the permitted ranges.
Verdict 6: IF the model fails to compile, fails to type-check OR has no initial state THEN a formal engine's verdict MUST carry malformed.
Verdict 7: A formal engine's verdict MAY carry holds ONLY IF the buggy twin's run carried counterexample AND the explored state count stopped growing inside the bound.
Verdict 8: A formal engine's holds MUST carry the bound the run explored.
Verdict 9: IF a verdict carries malformed OR the pass formal THEN the verdict MUST NOT count toward a round.
Verdict 10: A formal engine's verdict MUST carry the pass formal.
Verdict 11: IF a formal engine's run finds no counterexample AND the buggy twin's run carried no counterexample THEN the verdict MUST carry malformed.
Verdict 12: IF a formal engine's run finds no counterexample AND the explored state count still grew at the bound THEN the verdict MUST carry malformed.
```

Term holds: the verdict that the verifier found no foundational finding — for a formal engine, within the bound it names and no further.

Term counterexample: the verdict carrying one or more foundational findings, each with a site and a trace.

Term malformed: the verdict that nothing was verified — a model that did not compile, a reader that read past its permitted ranges, an answer outside the contract.

Term finding: one failure a verifier reports — the site (the labels of the rules or Terms it sits in), the trace, and the reporter's class and kind — named by its finding id.

Term finding id: the verdict key of the verdict that carries the finding, and the finding's ordinal in it — minted by the council, so an intent may carry it (Recoverable Invocation Primitive policy 10).

Term site: a span of the page a finding or a fragment sits in, as the snapshot carries it — a rule label or a Term name with its text and its WHY, running to the next label, Term name or heading; for a sentence outside every rule and Term, a WHY under a block of rules among them, the heading of the section it falls under; and the records sites: the status line, the Ledger's status, formal and last gate lines, the Ledger's open list and the page's end marker.

Term pass: grid | eos | linus | formal — the reader's pass a verdict answers, as the method defines the three, or formal for a formal engine's run.

---

## Composition-level invariants

- **Invariant 1 — One text per round.**
  ```
  Invariant 1.1: A council commit MUST NOT answer a round BEFORE the round settles.
  Invariant 1.2: A verdict MUST count toward a round ONLY IF the verdict carries the round's snapshot hash.
  ```
- **Invariant 2 — A repair lands on the bytes the round read.**
  ```
  Invariant 2.1: EVERY council commit MUST change a page whose bytes at the commit's parent EQUAL the round's snapshot.
  Invariant 2.2: EVERY line a council commit changes MUST belong to the round's change set.
  ```
- **Invariant 3 — Claims are the maintainer's.**
  ```
  Invariant 3.1: A council commit MUST NOT change a site in the claim families without the maintainer's recorded ruling.
  ```
- **Invariant 4 — A repair answers the side indicted.**
  ```
  Invariant 4.1: A council commit MUST NOT change a page for a finding whose settled triage's side EQUALS model.
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
  Invariant 7.2: IF a check of this page reads the payload of a record the journal reports Purged THEN the check MUST answer unverifiable, carrying purged-horizon, for the subject the check was reading; a sequence number read through every purge is no payload.
  NOTE: open 2026-10-17-e — unverifiable and purged-horizon are declared nowhere the page reaches; Audit Trail's unverifiable answers its own record verification, under a closed set of reasons.
  Invariant 7.3: The intent event a council commit's trailer names MUST NOT PRECEDE, in the journal's order, the intent event the trailer of any council-commit ancestor of the commit names.
  ```
- **Invariant 8 — Repair is bounded.**
  ```
  Invariant 8.1: IF the round position a verdict's record carries EXCEEDS the round budget the round's record carries AND the round IS NOT IN the ruled rounds THEN the composition MUST NOT count the verdict toward the round.
  ```

---

## Examples

### Walkthrough — a clean round

The council freezes `compositions/immutable-transaction-ledger.md` at base commit `2f1b5c1`: [Freeze] reads the page at that commit from the repository and records round `r-14` with snapshot hash `a1a6621b…`. Three readers, none of whom has read an earlier round, are handed the snapshot and run GRID, EOS with the builder's reading, and Linus; each verdict carries `a1a6621b…`, its pass and its own verifier, so each counts (Invariant 1.2, Action wiring 5). The verdicts are holds, holds and counterexample — one foundational finding, an operator's closing never sized. The first triager rejects it: the protocol's open sizes against the kind's largest record, which Term true maximum on [Recoverable Invocation](./recoverable-invocation.md) makes the operator's closing too. The round's foundational count is now zero, so the count decides the round clean and is a deciding count: every counted finding goes to a second triager, another actor, whose brief carries the findings, the first triage's rejection, the method's test and the blame rule, and not the threshold (Action wiring 11 through 13, 37). The second triager rejects it on the same text, and the round settles. [Repair] then carries the round's records and the refining cures that add no rule: the page at the head is still the snapshot, every cure answers a finding settled as cure, every fragment resolves to one site on the page and its old text is found verbatim, none sits in the claim families — the records leave the status line to the maintainer's ruling — the gate reports nothing over the repair tree it does not report over the head, the tree's diff is exactly the change set, and the commit lands on the head it was built from, carrying the council trailer. The round is clean.

### Rejection path — the page moved under the round

A person commits a change to one of the page's capability requirements while round `r-15` is between its second and third passes. The third reader is handed the snapshot, so its verdict carries the snapshot hash and counts; but [Repair] reads the page at the head, finds it no longer equal to the snapshot, and answers stale (Action wiring 15). Nothing is written, and the round's patches are void: they were sorted against a text that is no longer the page. The round can never be clean (Term clean round), and the page's round count keeps it.

### Rejection path — the engine indicts an invariant

A TLA+ run on the derived model returns a counterexample against the model's rendering of Immutable Transaction Ledger Invariant 1.3. The triage record carries side model, since no record states why the model is right; [Repair] answers gated for a page patch (Action wiring 20), and the cure goes to the model's re-derivation. Had the triager shown the model faithful and proposed weakening Immutable Transaction Ledger Invariant 1.3 instead, [Repair] would still answer gated (Action wiring 19), and the patch would wait in the maintainer's queue until a ruling names it. The engine's verdict moves no round's count either way (Verdict 9).

### Rejection path — the model did not compile

An Alloy adapter answers malformed: the derived model fails to type-check. [Report] escalates the verdict (Action wiring 6); no triage runs, no patch is proposed, and the round's count does not move (Verdict 9).

### Regulated adversarial scenarios

**Regulator audit — "show me every automated change to this page and why it was made."** The auditor reads the repository's commits by the council's trailer and, for each, the intent the trailer names (Invariant 7.1): the round, the snapshot, the patches. From the round, the journal answers the verdicts with their verifiers, the triage records with both triagers where a count decided, and the findings each patch answers. A change with no trailer is not the council's; a council commit whose diff holds a line no patch and no record accounts for fails Check 2.2.

**Disputed change — "I never authorized that change to an invariant."** A council commit cannot change a rule in the claim families without the maintainer's recorded ruling (Invariant 3.1). The rebuttal is the ruling: the journal record under the maintainer's own credential, carrying the patch byte for byte. A claim-family change with no such record is a conformance failure Check 3.1 finds.

**Breach investigation — "the council's credential was compromised; what could it have done?"** It could commit, and every commit it made carries a trailer whose intent stands in the journal under the council's attestation; a commit with a council trailer and no intent is a write outside this composition. It could not push (Capability requirement 12), and a claim it changed with no ruling under the maintainer's credential is a conformance failure Check 3.1 finds. The forensic window is bounded by the journal: every intent, closing and escalation is sealed and attributed by [Audit Trail](./audit-trail.md).

---

## Generation acceptance

### Conformance checks

```
Check 1.1: An auditor MUST find no council commit whose intent PRECEDES the settling of the commit's round (Invariant 1.1).
Check 1.2: An auditor MUST find EVERY counted verdict carrying the round's snapshot hash (Invariant 1.2).
Check 2.1: An auditor MUST find EVERY council commit's parent carrying the round's snapshot bytes for the page (Invariant 2.1).
Check 2.2: An auditor MUST find EVERY line a council commit changes in the round's change set (Invariant 2.2).
Check 3.1: An auditor MUST find, for EVERY council commit changing a site in the claim families, a maintainer's ruling carrying the commit's round AND the patch byte for byte (Invariant 3.1).
Check 4.1: An auditor MUST find no council commit's page patch answering a finding whose settled triage's side EQUALS model (Invariant 4.1).
Check 5.1: An auditor MUST find two triages under two actor references for EVERY counted finding of a settled round whose foundational count is zero (Invariant 5.1).
Check 6.1: An auditor MUST find no council commit answering a formal engine's malformed verdict (Invariant 6.1).
Check 7.1: An auditor MUST find, for EVERY council commit, the intent event the commit's trailer names in the journal under the act kind council.commit, carrying the round key, the snapshot hash, EVERY patch whole AND the commit's council nonce (Invariant 7.1).
Check 7.2: An auditor MUST find EVERY check of this page whose reading met the payload of a record the journal reports Purged answering unverifiable for that subject (Invariant 7.2); a check reading only sequence numbers is not met by a purge.
Check 7.3: An auditor MUST find no council commit whose intent event PRECEDES, in the journal's order, the intent event the trailer of any council-commit ancestor of the commit names, the sequence numbers read through every purge (Invariant 7.3).
Check 8.1: An auditor MUST find no counted verdict whose recorded round position EXCEEDS the round budget the round's record carries, other than in the ruled rounds (Invariant 8.1).
```

NOTE: EVERY check names the rule the check tests.

### External checks

```
External check 1: An auditor MUST clear from external evidence that EVERY reader read the snapshot cold (Capability requirement 3 through 5).
External check 2: An auditor MUST clear from external evidence that EVERY formal engine's holds came with the buggy twin rejected (Verdict 7).
External check 3: An auditor MUST clear from external evidence that the second and third triagers' briefs carried no threshold (Action wiring 13).
External check 4: An auditor MUST clear from external evidence that the repository took no push from the composition (Capability requirement 12).
```

---

## Non-goals

```
Non-goal 1: The composition MUST NOT judge a page's meaning.
Non-goal 2: The composition MUST NOT choose the next page to verify.
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
Indeterminate outcome 1: The commit probe MUST answer Recoverable Invocation's sweep for a council commit whose reply was lost (Recoverable Invocation reconcile step 3).
Deleted: Indeterminate outcome 2. Action wiring 23 owns it: a repair builds its own tree, so a crash leaves nothing a later call reads.
```

NOTE: watch the lost answer (Indeterminate outcome 1).

---

## Terms

Each `[Term]` marker above links to its term entry here.

### Vocabulary

Term actors: the composition; the constituents; the deployment; the council; the writer; a reader; a formal engine; a verifier; a triager; the second triager; the third triager; the maintainer; an auditor; the sweep.

Term records: the rounds, verdicts, triage records, rulings and escalations the composition records through Audit Trail's record_action; the intents, outcomes, refusals, recovery intents and escalations Recoverable Invocation writes for the act kind council.commit.

NOTE: open 2026-10-10-j — the word escalation names the council's record (council.escalation) and Recoverable Invocation's closing (council.commit.escalated), and disposition and settle each name one thing here and another in the protocol.

Term record verbs: clear, answer, apply, bind, build, evaluate, exclude, inject, move, place, set, pass, repair, settle, call, carry, change, commit, compare, count, disclose, escalate, find, freeze, journal, provision, push, publish, rebuild, record, refuse, remove, rest, run, serialize, serve, supply, triage, write, accept, belong, privilege, judge, choose, close, hold.

Term value sets: verdict = holds | counterexample | malformed. class = foundational | refining | rhetorical. kind = A | B | C | D. blame = fresh | older. side = model | english | both. disposition = cure | route | reject | decline. pass = grid | eos | linus | formal. role = first | second | third. action reference = council.round | council.verdict | council.triage | council.ruling | council.escalation | council.commit.intended | council.commit.committed | council.commit.refused | council.commit.recovery_intended | council.commit.abandoned | council.commit.escalated.

Term bounds: round budget (round_budget), patch cap (patch_cap), commit completion bound (commit_completion_bound), commit round trip (commit_round_trip), probe round trip (probe_round_trip).

Term qualifiers: migrated — written in GRACE lang v0.63 from the first draft (2026-10-10).

Term terms: writer, diff check, admitted freeze, admitted report, admitted ruling, admitted repair, opened repair, change set, snapshot, snapshot hash, base commit, round, round id, search, clean round, settled round, repair tree, page, finding, site, pass, sound verdict, counted verdict, patch, fragment, claim families, side, role, triage record, settled triage, deciding count, round's records, records fragment, maintainer's queue, maintainer's ruling, standing ruling, round budget, patch cap, sweep identity, commit binding, commit partition, commit probe, commit envelope, council commit, council nonce, council trailer, finding id, counted finding, foundational count, round position, ruled round, target, settling record, declared name, blocking sibling, permitted ranges, round key, parted finding, verdict key, counted triage, admitted triage, round index, triage index, ruling index, round count, repository, corpus gate, report refusal order, triage refusal order, ruling refusal order, repair refusal order, stated count.

NOTE: open 2026-10-23-a — most declared terms carry no term entry, where spec-format's Terms item asks one per declared term (Term terms).

Term snapshot: a page's bytes at a base commit, named by the base commit and the snapshot hash.

Term snapshot hash: the SHA-256 of the page's bytes at the base commit.

Term base commit: the repository commit a round's snapshot was taken from.

Term round id: the event id of the round's record — what [Report], [Triage] and [Repair] name a round by.

Term page: a canonical document under the repository — a pattern file.

Term round: three passes — GRID, EOS with the builder's reading, Linus — by three readers, each handed one snapshot.

Term search: passes over moving text, each reading the page live rather than one snapshot; it counts toward nothing, and a round whose readers are handed the snapshot is never one.

Term clean round: a settled round whose foundational count is zero and one of whose repairs' invocations closed council.commit.committed, as Recoverable Invocation's read invocation answers it for the invocation id the round index carries (Recoverable Invocation read invocation 3a), with no blocking sibling at that repair's intent. A clean round decides council records — a round [Freeze] records, a verdict [Report] counts — and no write of the act kind council.commit, so Recoverable Invocation read invocation 15, which governs a write of the act decided on that read, does not reach it.

Term blocking sibling: another round of the same page and snapshot hash that, at a given instant, is settled with a foundational count above zero, or is unsettled with a counted finding its reporter classed foundational.

Term cited: open, close, refuse, yield, lost, answered, act kind, act key, commit, commit fence, pairing datum, repeatable, probe, completion bound, commit round trip, probe round trip, journal, retention period, service identity, outcome envelope, retry terminus, critical section, act-in-flight, section-unavailable, journal-unavailable, recording-failure, true maximum, database candidates, resolve, intent event id, read invocation, call pause bound, open result: Recoverable Invocation. record_action, read_record, reference length cap, full enumeration: Audit Trail. The entries A clean round is a sample and A lapsed pass does not count, and the sections titled Order and iteration, The formal-layer vote, What "grounded" means and Lawful destruction is answered before absence: `pressure-testing.md`. The section titled Composition state: `execution-contract.md`.

#### Freeze

The action that opens a round: it reads the page at the base commit from the repository, refuses a page past its round budget with no standing ruling, records the round, and answers the round id and the snapshot every verdict of the round must carry.

Kind: Operation

#### Report

The action that records one verifier's verdict against a round's snapshot, refuses a verdict about other bytes, or for a pass or from a verifier already counted, and escalates a malformed one.

Kind: Operation

#### Triage

The action that records one triager's sorting of one of a round's counted findings or of a formal engine's findings — role, class, kind, blame, side and disposition — first; second and blind, by another triager, where a count decides an outcome; and third, by a third triager, where the two part.

Kind: Operation

#### Rule

The action through which the maintainer records a ruling: one claim-family patch admitted, or one more round of a page past its round budget.

Kind: Operation

#### Repair

The action through which the council writes: it checks every precondition against the round's settled triages, the maintainer's rulings and the page at the head, builds its own tree from the head with the round's patches and records applied as one change, runs the corpus gate, checks the diff, and commits through [Recoverable Invocation](./recoverable-invocation.md) with the council trailer, on the head it built from.

Kind: Operation

<!-- Term registry — shortcut-reference definitions. -->

[Freeze]: #freeze
[Report]: #report
[Triage]: #triage
[Rule]: #rule
[Repair]: #repair

## Standards references

None. The composition makes no regulatory claim of its own; the records it keeps are [Audit Trail](./audit-trail.md)'s, and a deployment that needs a standard's evidence reads that page's references.

## Status

`draft` — see the Ledger.

## Ledger

```
status: draft
formal: verified — vote yes: one writer per repository, no repair before the round settles and the round's bounded repair; verified-repair.tla + 4 twins + 3 probes (the commit path, Invariant 2.1, 2.2, 7.3 and Concurrency 1: two rounds, two [Repair] calls a round with commits in flight and no commit fence, one person commit; 61,659 states, and 263,067 with two person commits, past the harness's cap), verified-repair-settle.tla + 3 twins + 2 probes (the round's settling, Invariant 1.1 and 5.1: two verifiers on one pass, three triage records, each call's read and its record one transaction; 628 states, and 2,824 with four triage records), verified-repair-budget.tla + 3 twins + 2 probes (the round budget, Invariant 8.1: three freezes and one ruling, each freeze's read of the count and its round one transaction; 56 states, and 399 with four freezes and two rulings), the two re-derived 2026-10-21 on the journal's store (Capability requirement 28), each with a twin that takes Execution Contract Store 2 and Store 3 away; the settling model found Term counted finding counting a malformed verdict written after the settling record, cured on the page; 2026-10-21
last gate: 2026-10-23 — Final Critique 19, the council's eighth round on the page and the first on its text since the store-contract rewrite and the trims (d87f0f7, rules 170 to 167) and the refusal-order sweep (c2f4e9a), three fresh readers through OpenCode Go (GRID Beam, the seat moved twice mid-round when a model's allowance ran out; EOS MiniMax M3; Linus GLM-5.3 Flash), each handed only the round's reading set, three passes on one text (frozen at ba1cc6d); the round rests on three counted passes — foundational count 0, held by the blind second triage (2026-10-23, one cold reader given the round's 18 reports, the method's test and the placement rule, and neither the threshold nor what the count decides, which placed none of them foundational); 7 foundational reports, none standing as the two triages settled them (3 sent down: one cured, closing open line 2026-10-17-v, one onto open line 2026-10-17-g, now flagged, and one rewritten; 4 rejected, two of them a second budget check that Execution Contract Database 2 already makes part of [Freeze]'s own transaction); 9 refining reports, 2 rhetorical reports; clean; every refining finding cured, routed or answered: [Freeze]'s budget refusal and [Repair]'s yield written one obligation a line, read_record cited, Term clean round reading the repair's invocation by its id, three open lines closed and 2026-10-23-a added, four open lines flagged on the page; the status is the maintainer's; one sample; 2026-10-19 — Final Critique 18, the council's seventh round on the page — foundational count 2, both cured, not clean
open:
- 2026-10-10-a · refining · the whole page · round 19, the first on the store-contract rewrite and the refusal-order sweep, counted all three passes and returned zero foundational on the settle's triage and again on a blind second triage, the council's first clean round on the page; the page keeps its own status the maintainer's (Term round's records), so the settle records the round and leaves the status as it stands → the maintainer's ruling on the status: grounded on Final Critique 19, on one sample, with the second round owed as the first scheduled rescan, or another step first
- 2026-10-10-b · refining · Term repository · the database the act commits to is a deployment's version-controlled repository, which no atom in this library owns → an atom for a versioned database, or the database's contract kept here
- 2026-10-10-d · refining · Term round count · a lawfully purged round, verdict or triage is answered not-known as if absent → a purged arm
- 2026-10-10-e · refining · Term fragment · a fragment, a patch id, a site and a trace carry no length cap of their own → caps under the reference length cap, sized where the intent is
- 2026-10-10-j · refining · Term maintainer's queue, Term records · "escalation", "disposition" and "settle" each name one thing here and another in the protocol → one word for each
- 2026-10-10-l · refining · Capability requirement 14 · the protocol's other operator duties — binding duplicates under journal fence none, findings on the compliance surface — have no owner here → the maintainer named for them, or the deployment
- 2026-10-10-m · refining · Action wiring 25, Term records sections · the diff check compares a line diff with sentence fragments, and a fragment in the records sections names no target or insertion point → the unit stated, and the records' targets
- 2026-10-10-n · refining · Action wiring 53 · a records fragment may write a last gate of zero for a round a blocking sibling keeps from being clean → the last gate read through Term clean round
- 2026-10-10-s · refining · Capability requirement 14 · the time between the sweep's escalation and the intent's purge is the protocol's, and no maintainer response bound is disclosed against it → the bound disclosed and checked against the retention period
- 2026-10-10-w · refining · Check 2.1, Check 2.2 · neither tests that a council commit changes the round's page, so the change set applied to another file whose lines match passes both → the page named in both checks
- 2026-10-10-x · refining · Action wiring 6, 30, 34 · every retried gated repair and every refused freeze writes a new escalation, an escalation record is never closed, and a malformed verdict's escalation has no answering action → one escalation per subject, closed by a ruling or a later round
- 2026-10-10-y · refining · Capability requirement 4 through 6, Action wiring 12 · "Status heading", "buggy twin", "the method's test" and "the blame rule" are named and declared nowhere → Terms, or the deployment's disclosures
- 2026-10-10-z · refining · Action wiring 9, 20 · a cure that indicts the model has no actor, action or record on this page, and the first, second and third triage is a dual-control shape that recurs elsewhere → the model's re-derivation named, and the triage shape considered for extraction
- 2026-10-17-e · refining · Invariant 7.2, Check 7.2, Term site, Action wiring 12, 13 · "unverifiable", "purged-horizon", "end marker", "threshold" and "downgraded" are used and declared nowhere the page reaches — Audit Trail's unverifiable answers its own record verification, and purged-horizon is a sibling page's → Terms, or the words they stand for
- 2026-10-17-f · refining · Primitive policy 13 · "record_action's code with the code's step" presupposes a step invalid-credential does not carry, the one route by which [Freeze], [Report] and [Triage] export it → the step carried where the code carries one
- 2026-10-17-g · refining · Invariant 5, Term deciding count, Term records fragment · the rule that a count deciding an outcome is sorted twice, owned by the method's entry of 2026-10-09, and the Ledger's grammar, owned by the section titled Where the journey gets recorded in `pressure-testing.md`, are used without citing them, and Invariant 5.1's every deciding count is wider than the one Term deciding count names; the entry reaches every count an outcome turns on, and on the round that brings the page's round count to the round budget a count above zero decides the next [Freeze]'s budget-spent (Action wiring 34a), a pre-registered stopping rule, which the page triages once → both cited, and the narrowing recorded as a cost the page accepts, or the deciding count widened to that round
- 2026-10-17-h · refining · Term disposition · route obliges no record and no open line, so a routed finding reaches the next round only if a builder chooses to write one → a counted route triage obliging a records fragment that adds the open line
- 2026-10-17-i · refining · Action wiring 19, 56, 63 · "no maintainer's ruling carries the round AND the fragment's patch byte-exact" reads as one condition on the ruling or as two conjuncts, and "carries the round" as the round given or the page's latest round, both of which Action wiring 39 records → "carries, as the round given, the round AND the patch, byte-exact"
- 2026-10-17-j · refining · Term settled round, Term foundational count, Term settling record · each is defined through the others with no order of evaluation, so a reading over each prefix of the journal's order and a reading over the whole round give two settling records → the count defined at each prefix
- 2026-10-17-k · refining · Capability requirement 19, 21, 24 · the uniqueness of the council nonce, the round key and the verdict key is put on the deployment and tested by no read or rule, so a reused nonce surfaces only as an undecidable probe at the sweep → a lookup by key where the keys are minted, or the checker named
- 2026-10-17-l · refining · Primitive policy 15, Action wiring 6, 30, 34 · an escalation whose record_action gives no answer has no arm on any action, so the maintainer's queue can miss a write whose whole purpose is to be read → the no-answer arm
- 2026-10-17-m · refining · Term page, Term reader · both words name something else one call away — a page of records and a reading caller in the constituents → words of their own
- 2026-10-17-n · refining · Composition logic, Composition state 1, Wiring decision 1, 2 · no Audit arm subsection maps the substrate's refusals, nothing reads or removes the derived indexes by rule, and both wiring decisions are prohibitions with no positive form → the subsection, the index rules and the positive form
- 2026-10-17-o · refining · Action wiring 24 · gate-red answers the caller for a gate that gave no answer, a deployment fault with no owner → the owner named
- 2026-10-17-q · refining · Composition state 1, 2, Action wiring 7, 8, Term triage record, Term round index, Term triage index, Term ruling index · the rebuild Composition state 1 obliges needs each verdict and triage record to name its round, and each triage record its finding, which Action wiring 7, 8 and Term triage record do not list; the three indexes state no past-horizon classification; and Composition state 2 reads as holding every record at all times though the retention policy purges → the fields listed, each index classified past the horizon, and Composition state 2 read within the retention period
- 2026-10-17-r · refining · Term records fragment, Term round's records · the page's status line is among the shapes "the round's records take" while the status is the maintainer's, so the gloss reads as dropping what the list includes → the status lines named as the records fragments only a ruling admits
- 2026-10-17-s · refining · Term writer · Recoverable Invocation's writer is an actor role and this page's writer is the council's one writer to the repository, one word with two meanings across the seam, as 2026-10-17-m → a word of its own
- 2026-10-17-t · refining · Term claim families · the closure over every Term the claims name takes in the round key, the verdict key and the finding id, which the page mints rather than claims → the minted Terms left out, or the cost stated
- 2026-10-17-u · refining · Action wiring 24, Term corpus gate · a gate finding is named by its file, code and message, and nothing says how a name over the repair tree is matched with one over the head → the match byte-exact, beside Primitive policy 6
- 2026-10-17-w · refining · Term clean round, Term round's records · no rule obliges a [Repair] of a settled round, nor says which round owes which Ledger line, so a settled round whose records are never written is never clean and its page's count never resets → the round's records owed by rule once the round settles
- 2026-10-17-x · refining · Action wiring 55 · "share a byte of one site" reads as two old texts overlapping or as two fragments in one site, and the two readings refuse different change sets → the overlap named
- 2026-10-17-y · refining · Term target · a target is called the site a fragment changes while Action wiring 17 and 18 resolve it to sites, so the Term reads as the site and the rules as a reference to one → the reference named
- 2026-10-17-z · refining · Term maintainer's ruling, Action wiring 63 · the Term states a ruling's effect on the claim families only, and the open list is none of them, though Action wiring 63 is lifted by a ruling that carries the round and the patch → the ruling's effect on a records patch stated
- 2026-10-17-aa · refining · Capability requirement 23, Action wiring 22 · the payload caps Capability requirement 23 sets cover the council's own records and leave the intent, which carries every patch whole, to the invocation open's sizing, and a round whose patches overflow the cap has no stated remedy → several repairs of one round named as the remedy
- 2026-10-17-ab · refining · Invariant 7.3, Check 7.3, Check 7.2 · the first council commit has no council-commit ancestor, and the comparison is met only by reading it so, and Check 7.2 tests the unverifiable without the purged-horizon its invariant requires → the no-ancestor case stated, and the qualifier tested
- 2026-10-17-ac · refining · Term round index · the index carries counted verdicts by pass, while Action wiring 35 and 69, Term counted finding and Term settled round also read a reader's malformed verdicts and a formal engine's sound verdicts → the verdicts the index carries named
- 2026-10-17-ae · refining · Primitive policy 5 · the patch cap is tested against "a commit's patches" before any commit exists → the call's patches
- 2026-10-17-af · refining · Invariant 7.2, Check 7.2 · "a check of this page" reads as an auditor's conformance check, while the WHY of Action wiring also calls [Repair]'s preconditions checks and no signature carries the answer unverifiable → the conformance checks named as the checks Invariant 7.2 governs
- 2026-10-17-ah · refining · Action wiring 51 · a malformed verdict that [Report] refuses round-closed or, since round 16, under a primitive policy is never escalated, so a late reader's report of a read outside its permitted ranges leaves no record → the escalation kept for a refused malformed verdict, or the loss stated
- 2026-10-17-aj · refining · Term standing ruling · "whatever copy of it lands later" covers a copy of the ruling's record and not a retried [Rule] call, which records the page's latest round anew and, landing after the freeze the first ruling admitted, admits one more round → the copy named, and a retried call's effect stated
- 2026-10-18-a · refining · Action wiring 12, 13, External check 3 · the second and third triagers' briefs are governed and audited, and no capability requirement names who supplies them, as Capability requirement 3 through 6 do for what readers and engines are handed → a capability requirement naming the deployment
- 2026-10-19-a · refining · Primitive policy 13 · the rule names [Repair], which writes no record of its own (Term records; Primitive policy 8 names the other four actions), so the clause binds nothing, and a builder looking for the arm of [Repair]'s recording-failure(step) finds it here as well as in Primitive policy 15, which owns the escalation's write → [Repair] taken out of the rule, keeping Primitive policy 17 off its escalation, or its own record named
- 2026-10-19-b · refining · Capability requirement 9, Term corpus gate, Action wiring 24, 33 · the gate runs over a repair tree [Repair] builds apart from every checked-out copy (Term repair tree), while the capability asks only that the deployment supply the gate and the Term names a command run in the repository → the gate's input named, a tree the call hands it
- 2026-10-19-c · refining · Verdict 5, Term counterexample, Term holds · a reader that read outside its permitted ranges carries malformed (Verdict 5, Term malformed), while Term counterexample, read alone, names any verdict carrying a foundational finding and Term holds any carrying none → each Term scoped to a reader inside its ranges and to a formal engine
- 2026-10-19-d · refining · Action wiring 23, Term admitted repair · an admitted repair builds the repair tree, while a call is admitted only once Action wiring 24 and 25 have answered over that tree, so the build's slot is read off Action wiring 33 alone → the rule's subject [Repair], the tree built once the repair refusal order reaches Action wiring 24
- 2026-10-19-e · refining · the Intent, Term formal engine, Term snapshot hash, Term round · GRID, EOS, TLA+ and SHA-256 are used without the gloss at first use that spec-format's acronym convention asks of every initialism off its whitelist → each spelled out and glossed where it first appears
- 2026-10-23-a · refining · Term terms; the Vocabulary · most declared terms carry no term entry (the five actions alone have one), where spec-format's Terms item asks one per declared term and every specification writes one per name a bracket marker lands on → add the entries, each with a Kind the term entry grammar admits, or read the item as the bracketed names
```

## Decisions

Directional changes only. Everything smaller lives in the commit that made it: `git log -- compositions/verified-repair.md`; the rounds, the maintainer's two rulings and the formal model's drafting that got it here are in [its history](./verified-repair.hist.md).

- **2026-10-10 — The council written as a page before any runtime installs it.** *Chose:* the repair loop as a composition of Recoverable Invocation and Audit Trail — every commit an act of the protocol, keyed by the repository, paired by the invocation id in the commit's trailer; one verdict contract for readers and engines; a triage record carrying the side a finding indicts; claims gated to the maintainer; deciding counts triaged twice, the second blind to the threshold. *Over:* a loop that commits a patch as its own write, outside the protocol, and an exact diff of one fragment. *Because:* the maintainer ruled that the process is part of the process, and every rule here is one the manual grind paid for, written where the machine that will run it can be held to it.

- **2026-10-21 — The store's guarantees cited, not restated, and every guard of the council's actions read inside the transaction that records it.** *Chose:* the journal's store supplied under Execution Contract Store 1 through 3 (Capability requirement 28), and the four rules that existed only for a store that read a guard apart from the write it decided, or showed a record only some time after it landed, tombstoned to their owner — to Store 2, [Report]'s second reading of the round budget, which refused the verdicts of a round two freezes had recorded on one count, now held by [Freeze]'s budget check alone (Action wiring 48), and [Repair]'s settle bound on the settling record, whose read now shares one transaction with the intent the open records (Action wiring 52); and to Store 2 and Store 3, [Report]'s too-young before it read a round's position and the visibility the deployment owed the journal reads (Action wiring 58, Capability requirement 16); with them every clause that named the three, or spoke of a record the store cannot now produce — a verdict recorded in a race, a malformed verdict recorded after the settling record, a triage record later than it (Action wiring 7, 54, Term counted verdict, counted finding, settled round, round position, the report and repair refusal orders, Term age); rules 170 to 167. *Over:* the earliest record counts and the journal's order decides — a round's verdicts, triages and budget settled by the order the journal keeps, with [Report] and [Repair] waiting out the settle bound, because a read-then-append the substrate could not make conditional could be raced and a record could show late (the history's Round 2 through Round 6, and the formal model's finding of 2026-10-17). *Because:* the maintainer ruled 2026-10-12 that the corpus takes a store's specification, never the store, and 2026-10-20 that Store 1 binds every store write of one composition action, its constituents' included, and that Store 2 covers a guard decided across another writer's record in the one store: the council's records and the protocol's are Audit Trail's, in one store, so the state each action's guards decide on — the round count, a counted verdict, a counted triage, a settled round — is read inside the transaction that writes the action's record, and two freezes on one count, two verdicts for one pass and a triage beside the settling record are serialized for every deployment; a record is readable once it commits, and a record committed later stands later in the journal's order, so no read waits for one still landing. The census asked the maintainer whether that design is the council's domain rule or race machinery for a store that did not serialize; the rulings decide it, as Authenticated Actor's unit read its revoke residue by Store 2's first sentence: the refusals the design backed are the domain and stay (Action wiring 5, 34, 36, 37, 47), and so do Invariant 8.1 and Check 8.1, the page's bounded repair, now resting on [Freeze]'s budget check under Store 2, with the round position a verdict's record carries; the Terms keep their selection — the earliest, up to the settling record, no earlier record in another role — which picks the one record the refusals let through. The settling and budget models are re-derived on the journal's store, each with a twin that takes Store 2 and Store 3 away. The repository commit stays an act outside the store, Recoverable Invocation's: the commit binding, Concurrency 1 and Indeterminate outcome 1 are unchanged, and Primitive policy 17 still answers Audit Trail's step-4 refusal, whose committed event the 2026-10-20 ruling keeps as evidence. What the composition does for its domain is unchanged.

- **2026-10-21 — Which refusal answers is the Execution Contract's, where a fixed line can say it.** *Chose:* [Freeze]'s and [Report]'s refuses lines listing their refusals in the order their refusal orders gave them — [Freeze] invalid-request, repository-unavailable, journal-unavailable, not-known, stale, budget-spent; [Report] invalid-request, journal-unavailable, purged, not-known, round-closed, stale, already-counted — with the codes the action's own record_action answers listed after them, since no record is written before every refusal has answered (Primitive policy 8), and the order cited from the Execution Contract (Capability requirement 28, Execution Contract Refusal 1); Action wiring 72 and Action wiring 73, which evaluated the two orders, deleted to Refusal 1, Term freeze refusal order deleted, and the tombstones of Action wiring 59 and 67 repointed from Action wiring 72 to Refusal 1; rules 167 to 165. Term report refusal order stays, since Action wiring 51 holds the escalation of a malformed verdict behind it. [Triage], [Rule] and [Repair] keep their orders (Action wiring 74 through 76): each answers one code at places no fixed line can hold, invalid-request before and after the journal reads on all three, not-known on both sides of round-closed on [Triage], and on [Repair] unresolved, mismatch and gated each in more than one place among the patch checks. *Over:* deleting the three orders to the contract's rule, which would answer each recurring code at its first place. *Because:* the maintainer ruled on 2026-10-21 that the Execution Contract states once that the refusal listed first on an action's refuses line answers, and that a page keeps its own rule only where its order depends on a condition a fixed line cannot express. What each action answers on every call is unchanged.

- **2026-10-23 — Clean on Final Critique 19, the status left to the maintainer.** *Chose:* the round recorded clean on one sample, its foundational count zero on the settle's triage and again on the blind second triage, of seven foundational reports (three sent down, four rejected); [Freeze]'s budget refusal and [Repair]'s yield written one obligation a line (Action wiring 34a and 34b, 29a and 29b); read_record cited as Audit Trail's read of a record's retention state, the read Primitive policy 21, Invariant 7.2 and Check 7.2 call the journal's report of Purged; Term clean round reading the repair's invocation by the id the round index carries, which the protocol's read answers under no count cap; and Primitive policy 15 naming the answer a refused escalation displaces as the escalating action's own answer. *Over:* the status written grounded, as a settle writes it for a page that reserves nothing; and a second budget check at [Report] or at the round's record, which two readers proposed. *Because:* the page keeps its status the maintainer's (Term round's records, Term claim families), so the clean round is recorded for the maintainer's ruling and the status stays draft; Execution Contract Database 2 holds [Freeze]'s read of the round count and its record of the round in one transaction, so no round is recorded past the round budget but one a standing ruling admits, as the rewrite of 2026-10-21 chose (Action wiring 48); and each cure obliges what its rule obliged.

NOTE: End of Verified Repair.
