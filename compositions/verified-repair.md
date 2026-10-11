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

Term commit binding: the act kind's bindings, each under the name Recoverable Invocation gives it. act key — the repository. commit — the repository commit, read through the commit partition. commit fence — none. pairing datum — the council nonce, which the intent data carries and the store keeps in the commit's trailer: an adopter-minted nonce the store stores. repeatable — yes. probe — the commit probe. completion bound — the commit completion bound. commit round trip and probe round trip — the deployment's disclosed bounds. journal — the composition's Audit Trail instance, with council.commit.intended, the one outcome council.commit.committed, and council.commit.refused. retention period — the journal retention policy's, which places every council record under the same policy as the act kind's (Capability requirement 17). service identity — the sweep identity. outcome envelope — the commit envelope. retry terminus — lease. Deviations: none.

Term commit partition: committed — the store answers a commit id; pre-commit — the store refuses with nothing written, carrying lock-held, conflict where the head is not the commit's parent (Capability requirement 13) OR hook-rejected — the codes the store's contract declares pre-commit (Capability requirement 15); unknown — no answer, or a reply the store's contract does not declare.

Term commit probe: the repository's read by trailer value (Capability requirement 2) for the commits whose trailer carries the intent's council nonce — committed carrying council.commit.committed and the commit id where exactly one does, not-committed where none does, undecidable carrying the commit ids where more than one does, and unavailable where the read refuses or gives no answer. The read is scoped to the act key's repository, so every commit it finds carries the act key by construction (Recoverable Invocation probe 8).

Term commit envelope: the act kind's outcome envelope — the largest outcome payload the kind writes, one commit id at its minted width, serialized as the substrate sizes it. The intent, which alone carries the round key, the snapshot hash, every patch whole and the council nonce, is sized beside it by the invocation open (Recoverable Invocation Primitive policy 12).

Term council nonce: the nonce injected at the writer's seam for one [Repair] call, carried by no earlier council.commit intent and by no commit of the repository (Capability requirement 19, 21) — the act kind's pairing datum, carried in the intent data and in the commit's trailer.

Term council commit: a commit of the repository carrying a council trailer.

Term council trailer: the trailer a council commit carries — the council nonce and the intent event id the invocation open answered.

WHY:
**The repository is the store and the commit is the act** (Composes 4, 5). The one thing the council does that cannot be taken back is a commit, so the commit is the bound commit of the protocol, keyed by the repository because a repository has one head and two commits in flight on it are one writer too many. The council nonce rides the intent and the commit's trailer, so a sweep that finds an intent with no closing reads the repository for the nonce and learns whether the commit landed — the store keeps the nonce, which is the pairing the protocol admits without a reading of now (Recoverable Invocation pairing datum 1, 2). The nonce is not the invocation id: the protocol's own joins pair on the invocation id and never on the pairing datum (Recoverable Invocation Primitive policy 5, pairing datum 3), so the two stay two fields. The trailer also carries the intent event id, so an auditor holding a commit reads the intent's retention state after the purge has destroyed every payload that names the nonce (Invariant 7.2). A commit is never removed (Capability requirement 11), so no outcome outlives the record it names (Recoverable Invocation Binding 9).

---

## Composition logic

### Composition state

```
Composition state 1: The composition MUST rebuild the round index, the triage index, the ruling index AND the round count from the journal's full enumeration, the sequence-range read Audit Trail passes through (Audit Trail Action wiring 1).
Composition state 2: The journal MUST hold EVERY round, verdict, triage record, ruling AND escalation the composition keeps.
```

Term round index: map from a page to the page's rounds — each round's id, key, snapshot and counted verdicts by pass, whether the round has settled, and the invocations whose intents carry its key. Derived index.

Term round key: the nonce injected at [Freeze]'s seam for one round and recorded with it — what an intent names the round by, minted by the council and not by the substrate or the repository (Recoverable Invocation Primitive policy 10), and unique (Capability requirement 24).

Term verdict key: the nonce injected at [Report]'s seam for one verdict and recorded with it — what a finding id names the verdict by (Capability requirement 24).

Term triage index: map from a round to the round's triage records, each finding's first, second and third records kept apart. Derived index.

Term ruling index: map from a page, and from a round and a patch id, to the maintainer's rulings naming them. Derived index.

Term round count: map from a page to the number of rounds frozen on the page since the page's latest clean round. Derived index. Past the journal's retention period a purged round drops out of the count, so a page whose unclean rounds outlive their records is re-admitted without a ruling: a limit this page accepts, which a deployment retaining council records longer than a page's unclean rounds span never meets. A round whose [Freeze] answered recording-failure(step-3) or no answer, and whose record landed, counts too: a cost this page accepts, the budget running one round short for each such loss.

WHY:
Every element is rebuilt from the journal, so a council that restarts reads where it stood from the records and from nothing it remembered (the section titled Composition state in `execution-contract.md`). The snapshot lives in the round's record, the base commit and the content hash together, so the bytes a verdict was about can be named after the fact by anyone holding the repository. Whether a round settled, and whether it was clean, is read off its triage records and its commit, so the round count needs no record of its own.

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
Capability requirement 16: A deployment MUST supply EVERY journal read the composition makes with the guarantee Recoverable Invocation Capability requirement 7 AND 8 put on the protocol's own range reads.
Capability requirement 17: A deployment MUST place EVERY council record under the retention policy the journal applies to the act kind council.commit.
Capability requirement 18: IF a commit carries a council trailer AND the committing actor DOES NOT EQUAL the writer THEN the repository MUST refuse the commit.
Capability requirement 19: IF a commit's council nonce IS IN the council nonces the repository's commits carry THEN the repository MUST refuse the commit.
Capability requirement 20: The repository MUST NOT move the head to a commit that does not descend from the head.
Capability requirement 21: A deployment MUST inject a council nonce that no council.commit intent has carried.
Capability requirement 22: IF the committing actor EQUALS the writer AND the commit carries no council trailer THEN the repository MUST refuse the commit.
Capability requirement 23: A deployment MUST set EVERY payload cap the journal applies above the largest verdict, triage record, ruling AND escalation the deployment's verifiers, triagers and maintainer produce.
Capability requirement 24: A deployment MUST inject a round key AND a verdict key that the journal holds for no other record.
Capability requirement 25: A deployment MUST supply a repository read of a page at a commit that answers EXACTLY ONE OF the page's bytes, absent, a refusal.
```

Term repository: the version-controlled store holding the canonical pages — one head, commits that carry trailers, a commit taken only on the head it names as its parent, and a read by trailer.

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

WHY:
**Cold is a capability** (Capability requirement 3 through 5). A reader who has seen the Ledger re-finds nothing it lists and promotes nothing it hides, so its count is about the Ledger and not about the page; the composition cannot see what a reader was handed, so the deployment supplies the cold read and External check 1 is where an auditor clears it. **An engine without a twin proves nothing** (Capability requirement 6): a model that passes because its checks are vacuous passes for every page, and the twin the checker rejects is what makes the pass mean something (the section titled The formal-layer vote in `pressure-testing.md`). **The council never publishes** (Capability requirement 12): a commit stays where the maintainer can read it before anyone else can. **A commit lands only on the head it was built from** (Capability requirement 13): every precondition is read before the protocol's critical section is taken, so the repository's compare of head and parent is what keeps a head that moved meanwhile — another repair's commit, a person's — from carrying a tree built on the one before. **An escalated commit has an owner** (Capability requirement 14): with no commit fence, every invocation that dies ahead of its commit is escalated by the sweep (Recoverable Invocation commit 14b), and an escalation still open when its intent is purged is stranded (Recoverable Invocation resolve 12), so the deadline is put on the maintainer here.

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
Primitive policy 15: IF an escalation's record_action refuses at a step other than step-4 THEN the escalating action MUST answer record_action's code in place of the answer the escalating rule gives; an escalation refused at step-4 stands, and that answer is given.
Primitive policy 16: IF a triage record carries no role, class, kind, blame, side OR disposition, OR carries the role third with no settling text, THEN [Triage] MUST answer invalid-request.
Primitive policy 17: IF the record_action that writes the action's own record refuses at step-4 THEN the action MUST answer as an admitted call, with the event id the refusal carries (Audit Trail record action step 7.16).
Primitive policy 18: IF a triage record's disposition DOES NOT EQUAL reject AND the disposition DOES NOT EQUAL the one Term disposition pairs with the record's kind THEN [Triage] MUST answer invalid-request.
Primitive policy 19: IF a triage record's disposition EQUALS cure AND the record carries no patch THEN [Triage] MUST answer invalid-request.
Primitive policy 20: IF the page of a round given to [Rule] DOES NOT EQUAL the ruling's page THEN [Rule] MUST answer not-known.
Primitive policy 21: IF the journal reports Purged for a given round's record THEN [Report], [Triage], [Rule] AND [Repair] MUST answer purged.
```

### Action wiring

```
freeze(page, base_commit, actor_ref, credential)
  answers round id and snapshot
  refuses invalid-request | invalid-request(step) | invalid-credential | not-known | stale | budget-spent | repository-unavailable | journal-unavailable | recording-failure(step)

report(round, verdict, actor_ref, credential)
  answers recorded
  refuses invalid-request | invalid-request(step) | invalid-credential | not-known | purged | stale | already-counted | round-closed | budget-spent | too-young | journal-unavailable | recording-failure(step)

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
Action wiring 34: IF the round budget DOES NOT EXCEED the page's round count AND the page carries no standing ruling THEN [Freeze] MUST answer budget-spent AND escalate the page to the maintainer's queue.
Action wiring 57: IF the page at the base commit DOES NOT EQUAL the page at the repository's head THEN [Freeze] MUST answer stale; a page absent at the head equals no page at the base commit.
Action wiring 59: [Freeze] MUST NOT evaluate Action wiring 34 BEFORE Primitive policy AND Action wiring 57 have answered no refusal.
```

#### [Report]

```
Action wiring 4: IF the verdict's snapshot hash DOES NOT EQUAL the round's snapshot hash THEN [Report] MUST answer stale.
Action wiring 5: IF a counted verdict of the round carries the verdict's pass THEN [Report] MUST answer already-counted.
Action wiring 6: IF the verdict carries malformed THEN [Report] MUST escalate the verdict to the maintainer's queue.
Action wiring 7: An admitted report MUST record the verdict with the verdict key AND the round's position Action wiring 48 read.
Action wiring 47: IF the round IS IN the round index's settled rounds THEN [Report] AND [Triage] MUST answer round-closed.
Action wiring 48: IF the round's position EXCEEDS the round budget the round's record carries AND the round IS NOT IN the ruled rounds THEN [Report] MUST answer budget-spent.
Action wiring 51: [Report] MUST NOT evaluate Action wiring 6 BEFORE Action wiring 4, 5, 47, 48 AND 58 have answered no refusal.
Action wiring 58: IF the settle bound EXCEEDS the age of the round's record THEN [Report] MUST answer too-young.
Action wiring 60: [Report] MUST NOT evaluate Action wiring 7 BEFORE Action wiring 6 has answered.
```

Term sound verdict: a recorded verdict of a round carrying holds or counterexample — a reader's or a formal engine's.

Term counted verdict: the earliest sound verdict recorded for each of the round's reader passes, grid, eos and linus — the verdicts a round counts (Invariant 1.2, Verdict 9); a later verdict for a pass already counted is refused (Action wiring 5) or, recorded in a race, counts for nothing.

Term counted finding: a finding a counted verdict of the round carries.

Term round position: the number of rounds frozen on a page since the page's latest clean round preceding the round, counted in the journal's order up to and including the round, read once the round's record is older than the settle bound (Action wiring 58).

Term ruled round: a round whose record follows a maintainer's ruling naming the page alone, with no other round of the page recorded between them.

#### [Triage]

```
Action wiring 8: A triage record MUST carry the role, the finding's class, kind, blame, side AND disposition.
Action wiring 9: IF the finding came from a formal engine AND the record's side DOES NOT EQUAL model AND the record carries no reason the model is right THEN [Triage] MUST answer invalid-request.
Action wiring 10: An admitted triage MUST record the triage record under the triager's own actor reference.
Action wiring 11: IF the round's foundational count EQUALS zero THEN the composition MUST NOT count the round as settled BEFORE EVERY counted finding of the round carries a counted triage in the role second.
Action wiring 12: The second triager's brief MUST carry the findings, the first triage's downgraded and rejected findings, the method's test AND the blame rule, the test being the class definitions without the sentences that say what count grounds a page.
Action wiring 13: The second and third triagers' briefs MUST NOT carry the threshold the count is read against.
Action wiring 14: IF a counted finding IS IN the parted findings THEN the composition MUST NOT count the round as settled BEFORE the finding carries a counted triage in the role third carrying the text that settles the finding.
Action wiring 35: IF no sound verdict of the round carries the finding THEN [Triage] MUST answer not-known.
Action wiring 36: IF the round carries a counted triage of the finding in the record's role THEN [Triage] MUST answer already-triaged.
Action wiring 37: IF the round carries a triage record of the finding in another role under the caller's actor reference THEN [Triage] MUST answer invalid-request.
Action wiring 43: IF the record's role EQUALS second AND the round carries no counted triage of the finding in the role first THEN [Triage] MUST answer invalid-request.
Action wiring 44: IF the record's role EQUALS third AND the finding IS NOT IN the parted findings THEN [Triage] MUST answer invalid-request.
```

Term class: foundational | refining | rhetorical — as the section titled What "grounded" means in `pressure-testing.md` defines each.

Term kind: A | B | C | D — the triage fields of `pressure-testing.md`.

Term blame: fresh | older — fresh where the site was written or changed within the page's last two rounds.

Term side: model | english | both — which text a finding indicts: the derived model, the page, or the two.

Term disposition: cure | route | reject | decline — cure for a kind-A finding, route for kind B or C, decline for kind D, reject where the text already answers it.

Term deciding count: a count an outcome turns on — a round's foundational count where it is zero, since a zero decides the round clean.

Term foundational count: the number of a round's counted findings whose settled triage carries the class foundational and a disposition other than reject.

Term parted finding: a finding whose earliest counted first and second triages differ on the class, the side or the disposition.

Term role: first | second | third — which triage of a finding a record is.

Term triage record: one triager's sorting of one finding of a round — the role, class, kind, blame, side and disposition, the patch whole where the disposition is cure, a reason where a formal engine's finding is sided other than model, and for a third triage the text that settles — recorded under the triager's actor reference.

Term counted triage: a triage record of a finding, up to the round's settling record, whose actor holds no earlier record of the finding in another role — the triage records every rule of this page reads.

Term settled triage: among a finding's counted triages, the earliest third where one exists, otherwise the earliest second, otherwise the earliest first.

Term settled round: a round with a settling record — reading the round's records in the journal's order, the first record after which the round carries a counted verdict for each reader pass and every counted finding carries a settled triage, under Action wiring 11 and 14; a triage record later in the order counts for nothing.

Term settling record: the record at which a round settles.

Term age: the time from a record's recording instant to the reading of now at the acting action's seam.

Term triager: the agent OR person that sorts a finding.

#### [Rule]

```
Action wiring 38: IF the actor reference DOES NOT EQUAL the maintainer's actor reference THEN [Rule] MUST answer invalid-credential.
Action wiring 39: An admitted ruling MUST record the ruling with the page, the page's latest round AND, where given, the round AND the patch whole.
```

Term maintainer's ruling: a ruling record under the maintainer's actor reference — carrying a page, a round and a patch whole, it admits that patch, byte for byte, into the claim families in that round; naming a page alone, it admits the page's next round past its round budget.

Term standing ruling: a maintainer's ruling naming a page alone, together with the round that was the page's latest when the ruling was recorded, standing while that round is still the page's latest — spent by the next [Freeze] it admits, whatever copy of it lands later.

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
Action wiring 28: IF the commit's arm EQUALS pre-commit THEN [Repair] MUST call the invocation refusal with the act kind, the act key, the open result, the writer's actor reference AND credential, AND the store's code as the reason AND as the constituent code (Recoverable Invocation commit 2).
Action wiring 29: IF the commit's arm EQUALS unknown THEN [Repair] MUST call the invocation yield with the act kind, the act key AND the invocation id, carrying the reply that Recoverable Invocation yield 7 names for the arm, AND answer recording-failure(outcome) (Recoverable Invocation commit 8d).
Action wiring 30: IF [Repair] answers gated under Action wiring 19, 56 OR 63 THEN [Repair] MUST escalate the patch to the maintainer's queue.
Action wiring 31: IF the round IS NOT IN the round index's settled rounds THEN [Repair] MUST answer unsettled.
Action wiring 32: [Repair] MUST NOT push.
Action wiring 33: [Repair] MUST NOT call the invocation open BEFORE the corpus gate AND the diff check have answered over the repair tree.
Action wiring 40: IF a patch answers a finding that carries no settled triage of the round with disposition cure THEN [Repair] MUST answer unresolved.
Action wiring 41: IF a patch answers no finding AND a fragment of the patch IS NOT IN the records fragments THEN [Repair] MUST answer unresolved.
Action wiring 42: IF the invocation open, close OR refusal refuses THEN [Repair] MUST answer the code Recoverable Invocation Action wiring 2 exports for the refusal.
Action wiring 45: IF the invocation refusal answers a refusal event id THEN [Repair] MUST answer the store's code (Recoverable Invocation commit 3).
Action wiring 46: [Repair] MUST NOT evaluate Action wiring 17 through 20, 40, 41, 53 AND 55 BEFORE Primitive policy, Action wiring 15, 31, 49 AND 52 have answered no refusal.
Action wiring 49: IF the actor reference DOES NOT EQUAL the writer's actor reference THEN [Repair] MUST answer invalid-credential.
Action wiring 50: [Repair] MUST NOT evaluate Action wiring 19, 56 AND 63 BEFORE Action wiring 17, 18, 20, 24, 25, 40, 41, 53, 55, 61 AND 62 have answered no refusal.
Action wiring 52: IF the settle bound EXCEEDS the age, at Action wiring 54's read, of the settling record that read yields THEN [Repair] MUST answer unsettled.
Action wiring 53: IF the foundational count a records fragment's new last gate line carries DOES NOT EQUAL the round's foundational count THEN [Repair] MUST answer mismatch.
Action wiring 54: [Repair] MUST NOT evaluate Action wiring 31 AND 52 BEFORE reading the round's journal records (Capability requirement 16).
Action wiring 55: IF the old texts of two fragments of the change set share a byte of one site THEN [Repair] MUST answer mismatch.
Action wiring 56: IF a declared name of a fragment IS IN the claim families AND no maintainer's ruling carries the round AND the fragment's patch byte-exact THEN [Repair] MUST answer gated.
Action wiring 61: IF the change set carries no records fragment that replaces the Ledger's last gate line THEN [Repair] MUST answer invalid-request.
Action wiring 62: IF a patch answers a finding AND the patch DOES NOT EQUAL, byte-exact, the patch the finding's settled triage carries THEN [Repair] MUST answer unresolved.
Action wiring 63: IF a records fragment removes a Ledger open line AND no maintainer's ruling carries the round AND the fragment's patch byte-exact THEN [Repair] MUST answer gated.
```

Term patch: a patch id, the finding it answers, and one fragment for each sentence the change touches — the rule or Term the finding sits in and every sentence on the page that restates it; a patch carrying the round's records answers no finding.

Term fragment: a target, an old text and a new text — one sentence's change; an empty new text deletes.

Term declared name: a rule label or a Term name a fragment's new text declares.

Term target: the site a fragment changes.

Term claim families: Invariant, Check, External check — the page's claims — with every Term their rules name, directly or through another Term's definition, in the snapshot or in the repair tree, a rule naming a Term where the rule's text carries the Term's name, singular or plural, bare or possessive; the page's Intent; and the page's status line with the Ledger's status and formal lines.

Term round's records: the Ledger lines, the last gate line and the Decisions entry the round owes, written by the council; the status is the maintainer's (Term claim families).

Term records fragment: a fragment that replaces the page's status line or the Ledger's status, formal or last gate line, adds or removes a Ledger open line, or adds a Decisions entry ahead of the page's end marker — the shapes the round's records take.

Term change set: every fragment of the patches one [Repair] call carries — the cures and the round's records; every line a council commit may change.

Term repair tree: the files of the head [Repair] read, with the change set applied — built by one [Repair] call apart from every other call's tree and every checked-out copy, and committed whole.

WHY:
**Every check is evaluated by the writer, from what the writer holds** (Action wiring 15 through 20, 31, 40, 41). The writer holds the snapshot from the round's record, the head from the repository, the patch from the triager, and the settled triages and rulings from the journal; no precondition asks it to know what a verifier thought. **A patch is the rule and every sentence that restates it** (Term patch): a third of one round's findings in this corpus were sentences left saying what a rule used to say, so every fragment is resolved, matched and gated on its own (Action wiring 17 through 19), and the exact-diff check (Action wiring 25) compares the commit with the whole set. **The repair builds its own tree** (Action wiring 23, 26): a working copy two calls share carries one call's lines into the other's commit, and a working copy a refused call left changed blocks every call after it; a tree built from the head and committed whole leaves nothing behind but itself, and the repository takes it only on that head (Capability requirement 13). **Refusals in order** (Action wiring 46): a patch sorted against a page that moved, or in a round that has not settled, is not the maintainer's to read, so staleness and settlement are answered before any gate escalates, and the claim gate is read last, so the maintainer is asked only about a patch nothing else refuses. **A settled round stays settled** (Term settled round, Action wiring 52): a triage that lands after the round settled counts for nothing, and [Repair] waits out the protocol's settle bound and then reads the round from the journal, whose reads the deployment holds to the protocol's own visibility guarantee (Capability requirement 16), so a record the journal had not yet shown cannot reorder the round under the commit. **The escalation is the council's record, not the act's** (Action wiring 30): it is written before any intent, so Recoverable Invocation Action wiring 6, which keeps an adopter's journal writes for the act to the protocol's own actions, does not reach it. **The side decides the target** (Action wiring 9, 20): a model is derived and falls behind the page, and a counterexample read straight into a page patch mends the truth to match its shadow; a finding from an engine is the model's until the triage record says why the model is right.

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

WHY:
**Three answers, and one of them is not a failure** (Verdict 1, 9). A model that did not compile has no counterexample in it, and a reader who saw the Ledger has read a different text; either one, repaired against, produces a patch for a failure nobody found. Malformed goes to the maintainer and counts toward nothing (Action wiring 6). **An engine is the formal layer, not a pass** (Verdict 9, 10): a round is three readers' passes; an engine's verdict is recorded and triaged, its findings indict the model first (Action wiring 9), and it moves no round's count. **Holds is a sample, not a proof**: a reader's holds is one draw (the entry *A clean round is a sample* in `pressure-testing.md`), and an engine's holds is good inside the bound it names (Verdict 8).

---

## Composition-level invariants

- **Invariant 1 — One text per round.**
  ```
  Invariant 1.1: A council commit MUST NOT answer a round BEFORE the round settles.
  Invariant 1.2: A verdict MUST count toward a round ONLY IF the verdict carries the round's snapshot hash.
  ```
  WHY: the round's count is about the snapshot every pass read, and a repair answers the whole count. *Rests on* Wiring decision 1, Action wiring 4, 5, 31 and 52, Verdict 9.
- **Invariant 2 — A repair lands on the bytes the round read.**
  ```
  Invariant 2.1: EVERY council commit MUST change a page whose bytes at the commit's parent EQUAL the round's snapshot.
  Invariant 2.2: EVERY line a council commit changes MUST belong to the round's change set.
  ```
  WHY: no stale mutation and no stowaway. *Rests on* Action wiring 15, 23, 25, 26, Capability requirement 13 and Recoverable Invocation's one writer per act key.
- **Invariant 3 — Claims are the maintainer's.**
  ```
  Invariant 3.1: A council commit MUST NOT change a site in the claim families without the maintainer's recorded ruling.
  ```
  WHY: the claims are what the page is for. *Rests on* Wiring decision 2, Action wiring 19, 38 and 56.
- **Invariant 4 — A repair answers the side indicted.**
  ```
  Invariant 4.1: A council commit MUST NOT change a page for a finding whose settled triage's side EQUALS model.
  ```
  WHY: a derived model falls behind the page it was derived from. *Rests on* Action wiring 9, 20 and 40.
- **Invariant 5 — A deciding count is sorted twice.**
  ```
  Invariant 5.1: EVERY deciding count MUST rest on two triages, by two triagers, of EVERY counted finding of the round, the second blind to the threshold.
  ```
  WHY: a count that decides an outcome is the count a triager is most tempted by. *Rests on* Action wiring 11 through 14 and 37.
- **Invariant 6 — Nothing repairs a failure nobody found.**
  ```
  Invariant 6.1: A council commit MUST NOT answer a malformed verdict.
  ```
  WHY: a model that did not compile has nothing in it to repair. *Rests on* Verdict 9, Action wiring 35 and 40.
- **Invariant 7 — Every commit reads back.**
  ```
  Invariant 7.1: EVERY council commit MUST carry the council trailer whose intent event carries the round key, the snapshot hash AND EVERY patch whole.
  Invariant 7.2: IF a check of this page reads a record the journal reports Purged THEN the check MUST answer unverifiable, carrying purged-horizon, for the subject the check was reading.
  Invariant 7.3: The intent event a council commit's trailer names MUST NOT PRECEDE, in the journal's order, the intent event the trailer of the commit's nearest council-commit ancestor names.
  ```
  WHY: from a commit to its intent, from the intent to its round, from the round to its verdicts and triage records. Invariant 7.2 does for this page's checks what Recoverable Invocation Invariant 7.3 does for the protocol's, and reaches no check of that page: a purge destroys what a record named, so a check that meets one cannot say what the record would have shown, and says so rather than passing or failing what it cannot read. Check 7.3 reads only sequence numbers, which a purge keeps, so a forged trailer naming a purged intent is still caught. *Rests on* Action wiring 22, 26 and Recoverable Invocation Invariant 1 and 7.
- **Invariant 8 — Repair is bounded.**
  ```
  Invariant 8.1: IF the round position a verdict's record carries EXCEEDS the round budget the round's record carries AND the round IS NOT IN the ruled rounds THEN the composition MUST NOT count the verdict toward the round.
  ```
  WHY: a page that does not converge is a decision for a person. Two [Freeze] calls that read one count both record a round, so the journal's order, not [Freeze]'s read, decides which of them is past the budget, and the later one's verdicts are refused. *Rests on* Action wiring 34, 38 and 48.

---

## Examples

### Walkthrough — a clean round

The council freezes `compositions/immutable-transaction-ledger.md` at base commit `2f1b5c1`: [Freeze] reads the page at that commit from the repository and records round `r-14` with snapshot hash `a1a6621b…`. Three readers, none of whom has read an earlier round, are handed the snapshot and run GRID, EOS with the builder's reading, and Linus; each verdict carries `a1a6621b…` and its pass, so each counts (Invariant 1.2, Action wiring 5). The verdicts are holds, holds and counterexample — one foundational finding, an operator's closing never sized. The first triager rejects it: the protocol's open sizes against the kind's largest record, which Term true maximum on [Recoverable Invocation](./recoverable-invocation.md) makes the operator's closing too. The round's foundational count is now zero, so the count decides the round clean and is a deciding count: every counted finding goes to a second triager, another actor, whose brief carries the findings, the first triage's rejection, the method's test and the blame rule, and not the threshold (Action wiring 11 through 13, 37). The second triager rejects it on the same text, and the round settles. [Repair] then carries the round's records and the refining cures that add no rule: the page at the head is still the snapshot, every cure answers a finding settled as cure, every fragment resolves to one site on the page and its old text is found verbatim, none sits in the claim families — the records leave the status line to the maintainer's ruling — the gate reports nothing over the repair tree it does not report over the head, the tree's diff is exactly the change set, and the commit lands on the head it was built from, carrying the council trailer. The round is clean.

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
Check 6.1: An auditor MUST find no council commit answering a malformed verdict (Invariant 6.1).
Check 7.1: An auditor MUST find, for EVERY council commit, the intent event the commit's trailer names in the journal under the act kind council.commit, carrying the round key, the snapshot hash, EVERY patch whole AND the commit's council nonce (Invariant 7.1).
Check 7.2: An auditor MUST find EVERY check of this page whose reading met a record the journal reports Purged answering unverifiable for that subject (Invariant 7.2).
Check 7.3: An auditor MUST find no council commit whose intent event PRECEDES, in the journal's order, the intent event the trailer of the commit's nearest council-commit ancestor names, the sequence numbers read through every purge (Invariant 7.3).
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

WHY: one repository has one head. The protocol's one writer per act key serializes the invocations — with no commit fence it bounds when a commit is issued, not when it lands — and a call whose tree was built on a head that moved before its open meets the repository's conflict (Capability requirement 13), which the protocol records as a refusal with nothing written.

### Indeterminate outcome

```
Indeterminate outcome 1: The commit probe MUST answer Recoverable Invocation's sweep for a council commit whose reply was lost (Recoverable Invocation reconcile step 3).
Deleted: Indeterminate outcome 2. Action wiring 23 owns it: a repair builds its own tree, so a crash leaves nothing a later call reads.
```

WHY: a commit that landed with its reply lost carries its council trailer, so the probe finds it. A crash ahead of the commit leaves only the dead call's own tree, which no later call reads; the intent it opened is the sweep's, which escalates it, the kind having no commit fence (Recoverable Invocation commit 14b), and the maintainer settles the escalation inside the retention period (Capability requirement 14).

---

## Terms

Each `[Term]` marker above links to its term entry here.

### Vocabulary

Term actors: the composition; the constituents; the deployment; the council; the writer; a reader; a formal engine; a verifier; a triager; the second triager; the third triager; the maintainer; an auditor; the sweep.

Term records: the rounds, verdicts, triage records, rulings and escalations the composition records through Audit Trail's record_action; the intents, outcomes, refusals, recovery intents and escalations Recoverable Invocation writes for the act kind council.commit.

Term record verbs: clear, answer, apply, bind, build, evaluate, exclude, inject, move, place, set, pass, repair, settle, call, carry, change, commit, compare, count, disclose, escalate, find, freeze, journal, provision, push, publish, rebuild, record, refuse, remove, rest, run, serialize, serve, supply, triage, write, accept, belong, privilege, judge, choose, close, hold.

Term value sets: verdict = holds | counterexample | malformed. class = foundational | refining | rhetorical. kind = A | B | C | D. blame = fresh | older. side = model | english | both. disposition = cure | route | reject | decline. pass = grid | eos | linus | formal. role = first | second | third. action reference = council.round | council.verdict | council.triage | council.ruling | council.escalation | council.commit.intended | council.commit.committed | council.commit.refused | council.commit.recovery_intended | council.commit.abandoned | council.commit.escalated.

Term bounds: round budget (round_budget), patch cap (patch_cap), commit completion bound (commit_completion_bound), commit round trip (commit_round_trip), probe round trip (probe_round_trip).

Term qualifiers: migrated — written in GRACE lang v0.63 from the first draft (2026-10-10).

Term terms: writer, diff check, admitted freeze, admitted report, admitted ruling, admitted repair, opened repair, change set, snapshot, snapshot hash, base commit, round, round id, search, clean round, settled round, repair tree, page, finding, site, pass, sound verdict, counted verdict, patch, fragment, claim families, side, role, triage record, settled triage, deciding count, round's records, records fragment, maintainer's queue, maintainer's ruling, standing ruling, round budget, patch cap, sweep identity, commit binding, commit partition, commit probe, commit envelope, council commit, council nonce, council trailer, finding id, counted finding, foundational count, round position, ruled round, target, settling record, age, declared name, blocking sibling, permitted ranges, round key, parted finding, verdict key, counted triage, admitted triage.

Term snapshot: a page's bytes at a base commit, named by the base commit and the snapshot hash.

Term snapshot hash: the SHA-256 of the page's bytes at the base commit.

Term base commit: the repository commit a round's snapshot was taken from.

Term round id: the event id of the round's record — what [Report], [Triage] and [Repair] name a round by.

Term page: a canonical document under the repository — a pattern file.

Term round: three passes — GRID, EOS with the builder's reading, Linus — by three readers, each handed one snapshot.

Term search: passes over moving text, each reading the page live rather than one snapshot; it counts toward nothing, and a round whose readers are handed the snapshot is never one.

Term clean round: a settled round whose foundational count is zero and one of whose repairs' invocations closed council.commit.committed, as Recoverable Invocation's read invocation answers it, with no blocking sibling at that repair's intent. A clean round decides council records — a round [Freeze] records, a verdict [Report] counts — and no write of the act kind council.commit, so Recoverable Invocation read invocation 15, which governs a write of the act decided on that read, does not reach it.

Term blocking sibling: another round of the same page and snapshot hash that, at a given instant, is settled with a foundational count above zero, or is unsettled with a counted finding its reporter classed foundational.

Term cited: open, close, refuse, yield, act kind, act key, commit, commit fence, pairing datum, repeatable, probe, completion bound, commit round trip, probe round trip, journal, retention period, service identity, outcome envelope, retry terminus, critical section, act-in-flight, section-unavailable, journal-unavailable, recording-failure, true maximum, resolve, intent event id, read invocation, call pause bound, open result, settle bound: Recoverable Invocation. record_action, reference length cap, full enumeration: Audit Trail. The entry A clean round is a sample, and the sections titled Order and iteration, The formal-layer vote and What "grounded" means: `pressure-testing.md`. The section titled Composition state: `execution-contract.md`.

#### Freeze

The action that opens a round: it reads the page at the base commit from the repository, refuses a page past its round budget with no standing ruling, records the round, and answers the round id and the snapshot every verdict of the round must carry.

Kind: Operation

#### Report

The action that records one verifier's verdict against a round's snapshot, refuses a verdict about other bytes or for a pass already counted, and escalates a malformed one.

Kind: Operation

#### Triage

The action that records one triager's sorting of one finding of a round's counted verdicts — role, class, kind, blame, side and disposition — first; second and blind, by another triager, where a count decides an outcome; and third, by a third triager, where the two part.

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
formal: pending — vote yes: one writer per repository, no repair before the round settles and the round's bounded repair are ordering and safety claims; no model is drafted
last gate: 2026-10-11 — Final Critique 11, three fresh readers, three passes on one text (round 10's cures, frozen at 844317f), no lapse — 4 foundational after deduplication (5 reports), two in text rounds 9 and 10 wrote and two older; 51 refining reports, 13 rhetorical reports; not clean; every foundational finding cured in place; 2026-10-10 — Final Critique 10, three fresh readers, three passes on one text (round 9's cures, frozen at 4a1cdcd), no lapse — 8 foundational after deduplication (9 reports), two in text rounds 8 and 9 wrote and six older; 52 refining reports, 10 rhetorical reports; not clean; every foundational finding cured in place; 2026-10-10 — Final Critique 9, three fresh readers, three passes on one text (round 8's cures, frozen at ac06b93), no lapse — 9 foundational after deduplication (10 reports), four in text rounds 7 and 8 wrote, five older; 49 refining reports, 10 rhetorical reports; not clean; every foundational finding cured in place, each report given its own triage row first; 2026-10-10 — Final Critique 8, three fresh readers, three passes on one text (round 7's cures, frozen at e9edaa7) — the Linus reader lapsed in form only, cutting one search's output, with no read outside its ranges, so its verdict counts — 9 foundational after deduplication (11 reports), four in text rounds 6 and 7 wrote and five older, one of the older a round-5 report the round-5 triage dropped (a third triage overturning two that agreed); 54 refining reports, 13 rhetorical reports; not clean; every foundational finding cured in place; 2026-10-10 — Final Critique 7, three fresh readers, three passes on one text (round 6's cures, frozen at baede42), no lapse — 9 foundational after deduplication (11 reports), six in text rounds 5 and 6 wrote, three older; 50 refining reports, 16 rhetorical reports; not clean; every foundational finding cured in place; 2026-10-10 — Final Critique 6, three fresh readers, three passes on one text (round 5's cures, frozen at c63ce69) — the structural reader lapsed in form only, cutting long lines and joining two reads, with no read outside its ranges, so Verdict 5 does not reach it and its verdict counts — 9 foundational after deduplication (13 reports), seven in text rounds 4 and 5 wrote, two older; 53 refining reports, 13 rhetorical reports; not clean; every foundational finding cured in place; 2026-10-10 — Final Critique 5, three fresh readers, three passes on one text (round 4's cures, frozen at 1aa5a6e), no lapse — 10 foundational after deduplication (14 reports), six in text rounds 3 and 4 wrote, four older; 49 refining reports, 10 rhetorical reports; not clean; every foundational finding cured in place; 2026-10-10 — Final Critique 4, three fresh readers, three passes on one text (round 3's cures, frozen at 8795298), no lapse — 8 foundational after deduplication (15 reports), six in text rounds 2 and 3 wrote, two older; 51 refining reports, 10 rhetorical reports; not clean; every foundational finding cured in place; 2026-10-10 — Final Critique 3, three fresh readers, three passes on one text (round 2's cures, frozen at fa017b5) — 12 foundational after deduplication from the two sound passes (16 reports), six of them in text round 2's cures wrote and six older; the Linus reader lapsed, reading the Status heading and its one line past its range and no Ledger line, so under Verdict 5 its verdict is malformed and counts for nothing: the four of its findings the sound passes also reported are cured on theirs, and its one other is routed, not cured (Invariant 6.1); 46 refining reports, 12 rhetorical reports; not clean; every foundational finding of a sound pass cured in place; 2026-10-10 — Final Critique 2, three fresh readers, three passes on one text (round 1's cures, frozen at 660ecec) — 13 foundational after deduplication (25 reports), nine reached by two or three passes, all fresh, ten of them in text round 1's cures wrote; 35 refining reports, 9 rhetorical reports; not clean, so no count decided anything; every foundational finding cured in place; 2026-10-10 — Final Critique 1, three fresh readers, three passes on one text (the first draft, frozen at 47128cc) — 12 foundational after deduplication, every one reported by two or three passes, all fresh; 32 refining reports, 9 rhetorical reports; not clean, so no count decided anything and no second triage was owed (Action wiring 11); every foundational finding cured in place
open:
- 2026-10-10-a · refining · the whole page · round 11 read round 10's cures; its own cures held every council action's own record behind all its refusals, limited a third triage's hold to counted findings, replaced the purge exclusion with an unverifiable answer and deleted Term bears on, and put the removal of a Ledger open line under the maintainer's ruling → round 12 on the cured page
- 2026-10-10-b · refining · Term repository · the store the act commits to is a deployment's version-controlled repository, which no atom in this library owns → an atom for a versioned store, or the store's contract kept here
- 2026-10-10-d · refining · Term round count · a lawfully purged round, verdict or triage is answered not-known as if absent → a purged arm
- 2026-10-10-e · refining · Term fragment · a fragment, a patch id, a site and a trace carry no length cap of their own → caps under the reference length cap, sized where the intent is
- 2026-10-10-j · refining · Term maintainer's queue · "escalation", "disposition" and "settle" each name one thing here and another in the protocol → one word for each
- 2026-10-10-l · refining · Capability requirement 14 · the protocol's other operator duties — binding duplicates under journal fence none, findings on the compliance surface — have no owner here → the maintainer named for them, or the deployment
- 2026-10-10-m · refining · Action wiring 25, Term records sections · the diff check compares a line diff with sentence fragments, and a fragment in the records sections names no target or insertion point → the unit stated, and the records' targets
- 2026-10-10-n · refining · Term round · nothing stops one reader running two passes of a round, Action wiring 46 leaves Action wiring 15, 31 and 52 unordered against each other, and [Report], [Triage] and [Repair] state no order among most of their own refusals, so the answer code can differ though nothing written does; a records fragment may write a last gate of zero for a round a blocking sibling keeps from being clean → the one-reader rule, the orders, and the last gate read through Term clean round
- 2026-10-10-s · refining · Capability requirement 14 · the time between the sweep's escalation and the intent's purge is the protocol's, and no maintainer response bound is disclosed against it → the bound disclosed and checked against the retention period
- 2026-10-10-u · refining · Term clean round · how the round's repair invocation is found through the protocol's read is unstated, and the page's precondition reads assume the journal reads its own writes, which the protocol declares only for its own instance → both stated
- 2026-10-10-w · refining · Check 2.1, Check 2.2 · neither tests that a council commit changes the round's page, so the change set applied to another file whose lines match passes both → the page named in both checks
- 2026-10-10-x · refining · Action wiring 6, 30, 34 · every retried gated repair and every refused freeze writes a new escalation, an escalation record is never closed, and a malformed verdict's escalation has no answering action → one escalation per subject, closed by a ruling or a later round
- 2026-10-10-y · refining · Capability requirement 4 through 6, Action wiring 12 · "Status heading", "buggy twin", "the method's test" and "the blame rule" are named and declared nowhere → Terms, or the deployment's disclosures
- 2026-10-10-z · refining · Action wiring 9, 20 · a cure that indicts the model has no actor, action or record on this page, and the first, second and third triage is a dual-control shape that recurs elsewhere → the model's re-derivation named, and the triage shape considered for extraction
```

## Decisions

Directional changes only. Everything smaller lives in the commit that made it: `git log -- compositions/verified-repair.md`.

- **2026-10-10 — The council written as a page before any runtime installs it.** *Chose:* the repair loop as a composition of Recoverable Invocation and Audit Trail — every commit an act of the protocol, keyed by the repository, paired by the invocation id in the commit's trailer; one verdict contract for readers and engines; a triage record carrying the side a finding indicts; claims gated to the maintainer; deciding counts triaged twice, the second blind to the threshold. *Over:* a loop that commits a patch as its own write, outside the protocol, and an exact diff of one fragment. *Because:* the maintainer ruled that the process is part of the process, and every rule here is one the manual grind paid for, written where the machine that will run it can be held to it.

- **2026-10-10 — Round 1: a repair builds its own tree, a round counts by pass, and the maintainer rules through an action.** *Chose:* [Repair] builds its tree from the head and the repository takes it only on that head; a verdict names its pass and a round counts one verdict per pass; the settled triage and the round's own commit decide whether a round was clean; the maintainer's ruling is a record [Rule] writes, read where a round starts and where a claim is patched; the council nonce is the pairing datum, and the intent event id rides the trailer beside it. *Over:* a shared working copy restored on failure, three verdicts of any kind closing a round, and a ruling no action could record. *Because:* the first round's three passes found the shared copy, the count and the ruling broken from two or three directions each, and every cure that deleted state beat a cure that guarded it.

- **2026-10-10 — Round 2: the earliest record counts, and a ruling carries what it admits.** *Chose:* the earliest sound verdict of each reader pass, and the earliest triage record of each role, as the ones that count, with one actor to one record of a finding; a maintainer's ruling that carries the round and the patch whole, compared byte for byte; the round budget counted over frozen rounds, a page's standing ruling spent by the freeze it admits; a commit excluded from every check once any record a check reads for it is purged; [Repair]'s staleness and settlement answered before any gate escalates. *Over:* a lock around the journal's read-then-append, a ruling that names a patch id, and a budget over settled rounds. *Because:* a read-then-append the substrate cannot make conditional is settled by an order the journal already keeps, and a ruling on a name is a ruling on whatever later carries the name.

- **2026-10-10 — Round 3: the journal's order decides the budget, and a settled round is closed.** *Chose:* a round's position in the journal's order, not [Freeze]'s read of a count, as what puts a round past the budget, its verdicts refused; a settled round closed to later reports and triages; every count scoped to the findings counted verdicts carry, a rejected finding counting for nothing; a finding named by its verdict and ordinal; the round's records narrowed to the shapes they take; [Repair]'s caller held to the writer. *Over:* a lock around [Freeze], and a round whose settledness later records could undo. *Because:* the same race the second round closed for verdicts reappeared at [Freeze], and the same order closes it; and a fact a commit rested on must not change after the commit.

- **2026-10-10 — Round 4: a settled round stays settled, and the status is a claim.** *Chose:* a round settles at the first record in the journal's order that settles it, with later triage records counting for nothing and [Repair] waiting out the protocol's settle bound; the claim families widened to every Term their rules name and to the status line, so a page's grounding is ruled by the maintainer; the target and the records sites declared, and the last gate line checked against the round's count; the store's codes returned bare, an undeclared refusal left to the protocol's unknown arm. *Over:* a lock around [Triage], a claim gate keyed to three label families, and a wrapped store code. *Because:* every race this page met had the same shape and the same cure, and the cheapest way to weaken a claim was to change the words it is written in.

- **2026-10-10 — Round 5: a council commit is any commit with the trailer, and the page's own records land like the protocol's.** *Chose:* the checks' population named by the trailer alone, so a forged trailer is found rather than defined away; the repository's pre-commit codes closed to three; the page's own writes ordered after its input checks, a step-4 record answered as written; the council's journal reads held to the visibility the protocol guarantees its own; a clean round read across every settled round of its snapshot; the round budget written into the round it governs. *Over:* a population defined by its own validity, an open code set, and a budget read from today's disclosure. *Because:* a check that cannot fail is not a check, and every number a later check reads has to be the one the action read.

- **2026-10-10 — Round 6: a clean round is judged when its repair opens, and what a check reads is fixed when the action reads it.** *Chose:* a round's cleanness judged against its blocking siblings at its repair's intent, never revised by a sibling that settles later; a freeze refused on a page the head has moved; a report's position read only once the round's record is past the settle bound; the settling record aged as the journal read yields it; every council record under the act kind's retention policy; the claim families read over the snapshot and the repair tree, with the Intent and the Ledger's status lines among them. *Over:* a clean status any later record could revise, and a claim gate read over the snapshot alone. *Because:* a fact a commit or a count rests on has to stop moving at the moment it is used, and a claim can be weakened by what a patch adds as easily as by what it changes.

- **2026-10-10 — Round 7: the repository guards the trailer, and a verdict carries the position it was counted at.** *Chose:* a repository that refuses a council trailer from anyone but the writer or with a nonce already used, and never moves its head off its history; a verdict recorded with the round position it was counted at, so a later purge cannot recount it; a claim gate over sites, not rules; a reader handed the permitted ranges alone; a site that runs to the next label. *Over:* uniqueness asserted by a Term, and a position recomputed from whatever the journal still holds. *Because:* a property a check relies on has to be one the store enforces or one a record froze.

- **2026-10-10 — Round 8: an intent names its round by the council's own key, and a third triage runs only where two parted.** *Chose:* a round key minted at [Freeze]'s seam in place of the event id and the base commit the substrate and the repository mint, with the probe reading by trailer alone; a council nonce fresh for every call; the permitted ranges read at the base commit; a third triage admitted only on a parted finding, its brief blind as the second's is. *Over:* stating why the protocol's ban on minted fields did not reach this intent, and a third triage any triager could add. *Because:* the cheapest way to honour a constituent's rule is to stop needing what it forbids, and a tie-breaker that can overrule an agreement is a third vote, not a tie-breaker.

- **2026-10-10 — Round 9: the triager who disposes a cure carries the patch, and a commit's intent follows its ancestor's.** *Chose:* the settled triage carrying the cure's patch whole, [Repair] refusing any other; every triage rule reading the same counted triages; a council commit whose trailer names an intent older than its ancestor's caught by sequence numbers a purge keeps. *Over:* a patch the writer assembles beside the triage, and an exclusion that let a forged trailer naming a purged intent pass every check. *Because:* a fragment no triager saw is a stowaway whatever the diff check says, and the one fact a purge leaves standing is the order the journal wrote things in.

- **2026-10-10 — Round 10: a ruling names the round it was given against, and a purged record bears on what its neighbours bracket.** *Chose:* a page-alone ruling recorded with the page's latest round and standing only while that round is latest; a purged record's reach settled by the sequence numbers a purge keeps; a purged round answered as purged; a triage written only once admitted. *Over:* a ruling read as "later than the latest round", which a late copy satisfies twice, and an exclusion that needed content the purge had destroyed. *Because:* the fresh share fell to two in eight, and what remained were the draft's own assumptions about time and identity.

- **2026-10-11 — Round 11: a check that meets a purge says unverifiable, and closing a debt is the maintainer's.** *Chose:* a check of this page that reads a purged record answering unverifiable, carrying purged-horizon, as Chain of Custody's checks already do; Term bears on deleted; every council action's own record written only after all its refusals; removing a Ledger open line gated to a ruling. *Over:* an exclusion that had to know, after the purge, what the purged record had named. *Because:* the count fell to four, and the cheapest cure for the last purge finding was to stop guessing what a destroyed record said.

NOTE: End of Verified Repair.
