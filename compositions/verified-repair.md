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
Composes 7: The composition MUST NOT change a constituent's spec.
```

Term composition: this pattern's wiring of [Recoverable Invocation](./recoverable-invocation.md) and [Audit Trail](./audit-trail.md) — the round, the verdict contract, the triage, the repair and the escalations below.

Term constituents: [Recoverable Invocation](./recoverable-invocation.md), [Audit Trail](./audit-trail.md).

Term commit binding: the act kind's bindings, each under the name Recoverable Invocation gives it. act key — the repository. commit — the repository commit, read through the commit partition. commit fence — none. pairing datum — the council nonce, which the intent data carries and the store keeps in the commit's trailer: an adopter-minted nonce the store stores. repeatable — yes. probe — the commit probe. completion bound — the commit completion bound. commit round trip and probe round trip — the deployment's disclosed bounds. journal — the composition's Audit Trail instance, with council.commit.intended, the one outcome council.commit.committed, and council.commit.refused. retention period — the journal retention policy's. service identity — the sweep identity. outcome envelope — the commit envelope. retry terminus — lease. Deviations: none.

Term commit partition: committed — the store answers a commit id; pre-commit — the store refuses with nothing written, carrying lock-held, conflict (the head is not the commit's parent) OR hook-rejected; unknown — no answer, or a reply the store's contract does not declare.

Term commit probe: the repository read of the commits from the snapshot's base commit to the head, kept to the commits whose trailer carries the intent's council nonce — committed carrying council.commit.committed and the commit id where exactly one does, not-committed where none does, undecidable carrying the commit ids where more than one does, and unavailable where the read refuses or gives no answer. The read is scoped to the act key's repository, so every commit it finds carries the act key by construction (Recoverable Invocation probe 8).

Term commit envelope: the act kind's outcome envelope — the largest outcome payload the kind writes, one commit id at its minted width, serialized as the substrate sizes it. The intent, which alone carries the round id, the snapshot, every patch whole and the council nonce, is sized beside it by the invocation open (Recoverable Invocation Primitive policy 12).

Term council nonce: the nonce the writer mints for one [Repair] call, unique across every commit of the repository — the act kind's pairing datum, carried in the intent data and in the commit's trailer.

Term council trailer: the trailer a council commit carries — the council nonce and the intent event id the invocation open answered.

WHY:
**The repository is the store and the commit is the act** (Composes 4, 5). The one thing the council does that cannot be taken back is a commit, so the commit is the bound commit of the protocol, keyed by the repository because a repository has one head and two commits in flight on it are one writer too many. The council nonce rides the intent and the commit's trailer, so a sweep that finds an intent with no closing reads the repository for the nonce and learns whether the commit landed — the store keeps the nonce, which is the pairing the protocol admits without a reading of now (Recoverable Invocation pairing datum 1, 2). The nonce is not the invocation id: the protocol's own joins pair on the invocation id and never on the pairing datum (Recoverable Invocation Primitive policy 5, pairing datum 3), so the two stay two fields. The trailer also carries the intent event id, so an auditor holding a commit reads the intent's retention state after the purge has destroyed every payload that names the nonce (Invariant 7.2). A commit is never removed (Capability requirement 11), so no outcome outlives the record it names (Recoverable Invocation Binding 9).

---

## Composition logic

### Composition state

```
Composition state 1: The composition MUST rebuild the round index, the triage index, the ruling index AND the round count from the journal's open-upper-bound sequence-range read (Recoverable Invocation Capability requirement 1).
Composition state 2: The journal MUST hold EVERY round, verdict, triage record AND ruling the composition keeps.
```

Term round index: map from a page to the page's rounds — each round's id, snapshot and counted verdicts by pass, and whether the round has settled. Derived index.

Term triage index: map from a round to the round's triage records, each finding's first, second and settling records kept apart. Derived index.

Term ruling index: map from a page, and from a round and a patch id, to the maintainer's rulings naming them. Derived index.

Term round count: map from a page to the number of rounds frozen on the page since the page's latest clean round. Derived index.

WHY:
Every element is rebuilt from the journal, so a council that restarts reads where it stood from the records and from nothing it remembered (the section titled Composition state in `execution-contract.md`). The snapshot lives in the round's record, the base commit and the content hash together, so the bytes a verdict was about can be named after the fact by anyone holding the repository. Whether a round settled, and whether it was clean, is read off its triage records and its commit, so the round count needs no record of its own.

### Capability requirement

```
Capability requirement 1: A deployment MUST supply a repository whose commit takes a tree, a parent AND a trailer, AND whose reply, where one comes, carries EXACTLY ONE OF a commit id, a refusal with nothing written.
Capability requirement 2: A deployment MUST supply a repository read that finds a commit by a trailer value.
Capability requirement 3: A deployment MUST supply EVERY reader the snapshot's bytes AND the permitted ranges alone.
Capability requirement 4: A deployment MUST NOT supply a reader the lines of a page that follow the page's Status heading.
Capability requirement 5: A deployment MUST NOT supply a reader the record of an earlier round of the page.
Capability requirement 6: A deployment MUST supply EVERY formal engine the model derived from the snapshot, the model's buggy twin AND the bound the run explores.
Capability requirement 7: A deployment MUST disclose the round budget, the patch cap, the commit completion bound, the commit round trip, the probe round trip AND the maintainer's actor reference.
Capability requirement 8: A deployment MUST supply the maintainer's queue.
Capability requirement 9: A deployment MUST supply the corpus gate.
Capability requirement 10: A deployment MUST provision the sweep identity apart from EVERY other writer of the journal (Recoverable Invocation service identity 3).
Capability requirement 11: The repository MUST NOT remove a commit.
Capability requirement 12: The repository MUST NOT accept a push from the composition.
Capability requirement 13: The repository's commit MUST refuse with conflict where the head DOES NOT EQUAL the commit's parent.
Capability requirement 14: A deployment MUST settle EVERY council.commit.escalated through Recoverable Invocation's resolve, under the maintainer's actor reference, BEFORE the journal's retention period purges the escalated invocation's intent.
```

Term repository: the version-controlled store holding the canonical pages — one head, commits that carry trailers, a commit taken only on the head it names as its parent, and a read by trailer.

Term reader: a verifier that is a language model or a person running one pass of the method on a snapshot, having read no earlier round of the page.

Term formal engine: a verifier that checks the model derived from a page — Alloy, TLA+, or a heavier logic a property requires — through an adapter that answers the verdict contract.

Term verifier: a reader OR a formal engine.

Term maintainer: the person who holds the corpus's semantic authority.

Term maintainer's queue: the surface the maintainer reads the council's escalation records and Recoverable Invocation's council.commit.escalated closings from, each carrying the round, the finding, patch or page, and the one line that asks.

Term corpus gate: the deployment's whole-corpus surface check — `python3 tools/grace/check.py --gate` in this repository — answering its findings.

Term round budget: the most rounds a page may run without a clean round before the composition escalates the page.

Term patch cap: the most patches one commit may carry.

Term admitted freeze: a [Freeze] call no rule refused.

Term admitted report: a [Report] call no rule refused.

Term admitted ruling: a [Rule] call no rule refused.

Term admitted repair: a [Repair] call no rule refused before the invocation open.

Term opened repair: an admitted repair whose invocation open answered an open result.

Term writer: the council's one writer to the repository, under the writer's own actor reference and credential; the sweep identity is not the writer.

Term diff check: Action wiring 25's comparison of the repair tree's diff from the head with the change set.

Term sweep identity: the commit binding's service identity, under which Recoverable Invocation's sweep closes a council commit whose invocation died.

WHY:
**Cold is a capability** (Capability requirement 3 through 5). A reader who has seen the Ledger re-finds nothing it lists and promotes nothing it hides, so its count is about the Ledger and not about the page; the composition cannot see what a reader was handed, so the deployment supplies the cold read and External check 1 is where an auditor clears it. **An engine without a twin proves nothing** (Capability requirement 6): a model that passes because its checks are vacuous passes for every page, and the twin the checker rejects is what makes the pass mean something (the section titled The formal-layer vote in `pressure-testing.md`). **The council never publishes** (Capability requirement 12): a commit stays where the maintainer can read it before anyone else can. **A commit lands only on the head it was built from** (Capability requirement 13): every precondition is read before the protocol's critical section is taken, so the repository's compare of head and parent is what keeps a head that moved meanwhile — another repair's commit, a person's — from carrying a tree built on the one before. **An escalated commit has an owner** (Capability requirement 14): with no commit fence, every invocation that dies ahead of its commit is escalated by the sweep (Recoverable Invocation commit 14b), and an escalation still open when its intent is purged is stranded (Recoverable Invocation resolve 12), so the deadline is put on the maintainer here.

### Primitive policy

```
Primitive policy 1: IF the page OR the base commit EQUALS blank THEN [Freeze] MUST answer invalid-request.
Primitive policy 2: IF the page IS NOT IN the repository at the base commit THEN [Freeze] MUST answer not-known.
Primitive policy 3: IF a verdict carries no snapshot hash, no base commit, no verifier OR no pass THEN [Report] MUST answer invalid-request.
Primitive policy 4: IF a patch carries no patch id, no fragment, a fragment with no target OR a fragment with no new text THEN [Repair] MUST answer invalid-request.
Primitive policy 5: IF the count of a commit's patches EXCEEDS the patch cap THEN [Repair] MUST answer invalid-request.
Primitive policy 6: The composition MUST compare a snapshot hash, a commit id AND a fragment byte-exact.
Primitive policy 7: IF the repository's name OR the writer's actor reference EXCEEDS the reference length cap THEN [Repair] MUST answer invalid-request (Recoverable Invocation Primitive policy 1, 8).
Primitive policy 8: An action refused under Primitive policy MUST NOT write.
Primitive policy 9: IF the round names no round the journal holds THEN [Report], [Triage] AND [Repair] MUST answer not-known.
Primitive policy 10: IF a read of the repository refuses OR gives no answer THEN [Freeze] AND [Repair] MUST answer repository-unavailable.
Primitive policy 11: IF a read of the journal refuses OR gives no answer THEN [Freeze], [Report], [Triage], [Rule] AND [Repair] MUST answer journal-unavailable.
Primitive policy 12: [Freeze], [Report], [Triage], [Rule] AND [Repair] MUST pass the caller's actor reference AND credential through to EVERY record_action the action calls.
Primitive policy 13: IF record_action refuses THEN [Freeze], [Report], [Triage], [Rule] AND [Repair] MUST answer record_action's code with the code's step.
Primitive policy 14: IF the page EQUALS blank OR a patch comes with no round THEN [Rule] MUST answer invalid-request.
Primitive policy 15: IF an escalation's record_action refuses THEN the escalating action MUST answer record_action's code in place of the refusal that escalated.
```

### Action wiring

```
freeze(page, base_commit, actor_ref, credential)
  answers round id and snapshot
  refuses invalid-request | invalid-request(step) | invalid-credential | not-known | budget-spent | repository-unavailable | journal-unavailable | recording-failure(step)

report(round, verdict, actor_ref, credential)
  answers recorded
  refuses invalid-request | invalid-request(step) | invalid-credential | not-known | stale | already-counted | journal-unavailable | recording-failure(step)

triage(round, finding, record, actor_ref, credential)
  answers recorded
  refuses invalid-request | invalid-request(step) | invalid-credential | not-known | already-triaged | journal-unavailable | recording-failure(step)

rule(page, round, patch, actor_ref, credential)
  answers recorded
  refuses invalid-request | invalid-request(step) | invalid-credential | journal-unavailable | recording-failure(step)

repair(round, patches, actor_ref, credential)
  answers commit id
  refuses invalid-request | invalid-request(step) | invalid-credential | not-known | stale | unsettled | unresolved | mismatch | gated | gate-red | repository-unavailable | lock-held | conflict | hook-rejected | act-in-flight(invocation_id) | section-unavailable | journal-unavailable | recording-failure(intent) | recording-failure(outcome) | already-accounted(closing_event_id) | recording-failure(refusal, constituent_code) | recording-failure(step)
```

#### [Freeze]

```
Deleted: Action wiring 1. Primitive policy 2 owns it: the snapshot is read from the repository at the base commit, never from a checked-out copy.
Action wiring 2: An admitted freeze MUST record the round with the page, the base commit AND the snapshot hash.
Action wiring 3: An admitted freeze MUST answer the round id AND the snapshot: the snapshot hash AND the base commit.
Action wiring 34: IF the round budget DOES NOT EXCEED the page's round count AND the page carries no standing ruling THEN [Freeze] MUST answer budget-spent AND escalate the page to the maintainer's queue.
```

#### [Report]

```
Action wiring 4: IF the verdict's snapshot hash DOES NOT EQUAL the round's snapshot hash THEN [Report] MUST answer stale.
Action wiring 5: IF a counted verdict of the round carries the verdict's pass THEN [Report] MUST answer already-counted.
Action wiring 6: IF the verdict carries malformed THEN [Report] MUST escalate the verdict to the maintainer's queue.
Action wiring 7: An admitted report MUST record the verdict.
```

Term sound verdict: a recorded verdict of a round carrying holds or counterexample — a reader's or a formal engine's.

Term counted verdict: the earliest sound verdict recorded for each of the round's reader passes, grid, eos and linus — the verdicts a round counts (Invariant 1.2, Verdict 9); a later verdict for a pass already counted is recorded and counts for nothing.

#### [Triage]

```
Action wiring 8: A triage record MUST carry the role, the finding's class, kind, blame, side AND disposition.
Action wiring 9: A triage record's side MUST carry model where the finding came from a formal engine AND the record states no reason the model is right.
Action wiring 10: The composition MUST record a triage record under the triager's own actor reference.
Action wiring 11: IF the round's settled triages carry no foundational class THEN the composition MUST NOT count the round as settled BEFORE a second triager has triaged EVERY finding the round's counted verdicts carry.
Action wiring 12: The second triager's brief MUST carry the findings, the first triage's downgraded and rejected findings, the method's test AND the blame rule.
Action wiring 13: The second triager's brief MUST NOT carry the threshold the count is read against.
Action wiring 14: IF the first and second triages of a finding differ on the class, the side OR the disposition THEN the composition MUST NOT count the round as settled BEFORE a third triager records a settling triage record carrying the text that settles the finding.
Action wiring 35: IF no sound verdict of the round carries the finding THEN [Triage] MUST answer not-known.
Action wiring 36: IF the round carries a triage record of the finding in the record's role THEN [Triage] MUST answer already-triaged.
Action wiring 37: IF the round carries a triage record of the finding in another role under the caller's actor reference THEN [Triage] MUST answer invalid-request.
Action wiring 43: IF the record's role EQUALS second AND the round carries no first triage of the finding THEN [Triage] MUST answer invalid-request.
Action wiring 44: IF the record's role EQUALS settling AND the round carries no second triage of the finding THEN [Triage] MUST answer invalid-request.
```

Term class: foundational | refining | rhetorical — as the section titled What "grounded" means in `pressure-testing.md` defines each.

Term kind: A | B | C | D — the triage fields of `pressure-testing.md`.

Term blame: fresh | older — fresh where the site was written or changed within the page's last two rounds.

Term side: model | english | both — which text a finding indicts: the derived model, the page, or the two.

Term disposition: cure | route | reject | decline — cure for a kind-A finding, route for kind B or C, decline for kind D, reject where the text already answers it.

Term deciding count: a count an outcome turns on — the foundational count of a round whose settled triages carry no foundational class.

Term role: first | second | settling — which triage of a finding a record is.

Term triage record: one triager's sorting of one finding of a round — the role, class, kind, blame, side and disposition, and for a settling record the text that settles — recorded under the triager's actor reference.

Term settled triage: a finding's earliest settling triage record where one exists, otherwise its earliest second, otherwise its earliest first.

Term settled round: a round carrying a counted verdict for each reader pass, every finding of which carries a settled triage, under Action wiring 11 and 14.

Term triager: the agent OR person that sorts a finding.

#### [Rule]

```
Action wiring 38: IF the actor reference DOES NOT EQUAL the maintainer's actor reference THEN [Rule] MUST answer invalid-credential.
Action wiring 39: An admitted ruling MUST record the ruling with the page AND, where given, the round AND the patch whole.
```

Term maintainer's ruling: a ruling record under the maintainer's actor reference — carrying a page, a round and a patch whole, it admits that patch, byte for byte, into the claim families in that round; naming a page alone, it admits the page's next round past its round budget.

Term standing ruling: a maintainer's ruling naming a page alone, recorded later than the page's latest round — spent by the next [Freeze] it admits.

#### [Repair]

```
Action wiring 15: IF the page at the repository's head DOES NOT EQUAL the snapshot's bytes THEN [Repair] MUST answer stale.
Deleted: Action wiring 16. Action wiring 15 and Capability requirement 13 own it: the page at the head is the snapshot, and the commit lands only on the head it was built from.
Action wiring 17: IF the count of sites a fragment's target resolves to on the round's page DOES NOT EQUAL one THEN [Repair] MUST answer unresolved.
Action wiring 18: IF the count of a fragment's old text in the fragment's resolved site, verbatim, DOES NOT EQUAL one THEN [Repair] MUST answer mismatch.
Action wiring 19: IF a fragment's target IS IN the claim families AND no maintainer's ruling carries the round AND the fragment's patch byte-exact THEN [Repair] MUST answer gated.
Action wiring 20: IF a patch answers a finding whose settled triage's side EQUALS model THEN [Repair] MUST answer gated.
Deleted: Action wiring 21. Action wiring 34 owns it: the budget is read where a round starts.
Action wiring 22: An admitted repair MUST call the invocation open with the act kind, the repository as the act key, the writer's actor reference AND credential, AND the round id, the snapshot, EVERY patch whole AND the council nonce as intent data.
Action wiring 23: An admitted repair MUST build the repair tree from the head Action wiring 15 read, with EVERY fragment of EVERY patch applied as one change.
Action wiring 24: IF a finding the corpus gate reports over the repair tree IS NOT IN the gate's findings over the head OR the gate gives no answer THEN [Repair] MUST answer gate-red.
Action wiring 25: IF the repair tree's diff from the head DOES NOT EQUAL the change set THEN [Repair] MUST answer mismatch.
Action wiring 26: An opened repair MUST commit the repair tree with the head Action wiring 15 read as the parent AND the council trailer as the commit's trailer, WITHIN the call pause bound of the invocation open's return (Recoverable Invocation commit 14c).
Action wiring 27: IF the commit answers a commit id THEN [Repair] MUST call the invocation close with the act kind, the act key, the invocation pair, the writer's actor reference AND credential, council.commit.committed AND the commit id as the outcome data (Recoverable Invocation close 5).
Action wiring 28: IF the commit's arm EQUALS pre-commit THEN [Repair] MUST call the invocation refusal with the act kind, the act key, the invocation pair, the writer's actor reference AND credential, AND the store's code as the reason AND as the constituent code (Recoverable Invocation commit 2).
Action wiring 29: IF the commit's arm EQUALS unknown THEN [Repair] MUST call the invocation yield with the act kind, the act key AND the invocation id, carrying the reply that Recoverable Invocation yield 7 names for the arm, AND answer recording-failure(outcome) (Recoverable Invocation commit 8d).
Action wiring 30: IF [Repair] answers gated under Action wiring 19 THEN [Repair] MUST escalate the patch to the maintainer's queue.
Action wiring 31: IF the round IS NOT IN the round index's settled rounds THEN [Repair] MUST answer unsettled.
Action wiring 32: [Repair] MUST NOT push.
Action wiring 33: [Repair] MUST NOT call the invocation open BEFORE the corpus gate AND the diff check have answered over the repair tree.
Action wiring 40: IF a patch answers a finding that carries no settled triage of the round with disposition cure THEN [Repair] MUST answer unresolved.
Action wiring 41: IF a patch answers no finding AND a fragment's target IS NOT IN the records sections THEN [Repair] MUST answer unresolved.
Action wiring 42: IF the invocation open, close OR refusal refuses THEN [Repair] MUST answer the code Recoverable Invocation Action wiring 2 exports for the refusal.
Action wiring 45: IF the invocation refusal answers a refusal event id THEN [Repair] MUST answer the store's code (Recoverable Invocation commit 3).
Action wiring 46: [Repair] MUST NOT evaluate Action wiring 17 through 20, 40 AND 41 BEFORE Primitive policy, Action wiring 15 AND Action wiring 31 have answered no refusal.
```

Term patch: a patch id, the finding it answers, and one fragment for each sentence the change touches — the rule or Term the finding sits in and every sentence on the page that restates it; a patch carrying the round's records answers no finding.

Term fragment: a target, an old text and a new text — one sentence's change.

Term claim families: Invariant, Check, External check — the page's claims.

Term round's records: the Ledger lines, the last gate line, the Decisions entry and the status the round owes, written by the council.

Term records sections: the page's Status, Ledger and Decisions — where the round's records are written.

Term change set: every fragment of the patches one [Repair] call carries — the cures and the round's records; every line a council commit may change.

Term repair tree: the files of the head [Repair] read, with the change set applied — built by one [Repair] call apart from every other call's tree and every checked-out copy, and committed whole.

WHY:
**Every check is evaluated by the writer, from what the writer holds** (Action wiring 15 through 20, 31, 40, 41). The writer holds the snapshot from the round's record, the head from the repository, the patch from the triager, and the settled triages and rulings from the journal; no precondition asks it to know what a verifier thought. **A patch is the rule and every sentence that restates it** (Term patch): a third of one round's findings in this corpus were sentences left saying what a rule used to say, so every fragment is resolved, matched and gated on its own (Action wiring 17 through 19), and the exact-diff check (Action wiring 25) compares the commit with the whole set. **The repair builds its own tree** (Action wiring 23, 26): a working copy two calls share carries one call's lines into the other's commit, and a working copy a refused call left changed blocks every call after it; a tree built from the head and committed whole leaves nothing behind but itself, and the repository takes it only on that head (Capability requirement 13). **Refusals in order** (Action wiring 46): a patch sorted against a page that moved, or in a round that has not settled, is not the maintainer's to read, so staleness and settlement are answered before any gate escalates. **The escalation is the council's record, not the act's** (Action wiring 30): it is written before any intent, so Recoverable Invocation Action wiring 6, which keeps an adopter's journal writes for the act to the protocol's own actions, does not reach it. **The side decides the target** (Action wiring 9, 20): a model is derived and falls behind the page, and a counterexample read straight into a page patch mends the truth to match its shadow; a finding from an engine is the model's until the triage record says why the model is right.

### Wiring decision

```
Wiring decision 1: The composition MUST NOT repair a round BEFORE the round settles.
Wiring decision 2: The composition MUST NOT change a rule in the claim families without the maintainer's recorded ruling.
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
```

Term holds: the verdict that the verifier found no foundational finding — for a formal engine, within the bound it names and no further.

Term counterexample: the verdict carrying one or more foundational findings, each with a site and a trace.

Term malformed: the verdict that nothing was verified — a model that did not compile, a reader that read past its permitted ranges, an answer outside the contract.

Term finding: one failure a verifier reports — the site (the labels of the rules or Terms it sits in), the trace, and the reporter's class and kind.

Term site: the rule labels and Term names a finding sits in, as the snapshot carries them.

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
  WHY: the round's count is about the snapshot every pass read, and a repair answers the whole count. *Rests on* Wiring decision 1, Action wiring 4, 5 and 31, Verdict 9.
- **Invariant 2 — A repair lands on the bytes the round read.**
  ```
  Invariant 2.1: EVERY council commit MUST change a page whose bytes at the commit's parent EQUAL the round's snapshot.
  Invariant 2.2: EVERY line a council commit changes MUST belong to the round's change set.
  ```
  WHY: no stale mutation and no stowaway. *Rests on* Action wiring 15, 23, 25, 26, Capability requirement 13 and Recoverable Invocation's one writer per act key.
- **Invariant 3 — Claims are the maintainer's.**
  ```
  Invariant 3.1: A council commit MUST NOT change a rule in the claim families without the maintainer's recorded ruling.
  ```
  WHY: the claims are what the page is for. *Rests on* Wiring decision 2, Action wiring 19 and 38.
- **Invariant 4 — A repair answers the side indicted.**
  ```
  Invariant 4.1: A council commit MUST NOT change a page for a finding whose settled triage's side EQUALS model.
  ```
  WHY: a derived model falls behind the page it was derived from. *Rests on* Action wiring 9, 20 and 40.
- **Invariant 5 — A deciding count is sorted twice.**
  ```
  Invariant 5.1: EVERY deciding count MUST rest on two triages, by two triagers, of EVERY finding the round's counted verdicts carry, the second blind to the threshold.
  ```
  WHY: a count that decides an outcome is the count a triager is most tempted by. *Rests on* Action wiring 11 through 14 and 37.
- **Invariant 6 — Nothing repairs a failure nobody found.**
  ```
  Invariant 6.1: A council commit MUST NOT answer a malformed verdict.
  ```
  WHY: a model that did not compile has nothing in it to repair. *Rests on* Verdict 9, Action wiring 35 and 40.
- **Invariant 7 — Every commit reads back.**
  ```
  Invariant 7.1: EVERY council commit MUST carry the council trailer whose intent event carries the round, the snapshot AND EVERY patch whole.
  Invariant 7.2: IF the journal reports Purged for a council commit's intent event, round record, triage record OR ruling THEN EVERY check MUST exclude the commit.
  ```
  WHY: from a commit to its intent, from the intent to its round, from the round to its verdicts and triage records. Invariant 7.2 is Recoverable Invocation Invariant 7.3 read from the commit's side and widened to the council's own records, which are written before the intent and so purge first under one retention period: a check reads a commit only while every record it reads for the commit stands. *Rests on* Action wiring 22, 26 and Recoverable Invocation Invariant 1 and 7.
- **Invariant 8 — Repair is bounded.**
  ```
  Invariant 8.1: IF the round budget DOES NOT EXCEED a page's round count THEN the composition MUST NOT freeze a round on the page BEFORE recording a maintainer's ruling later than the page's latest round.
  ```
  WHY: a page that does not converge is a decision for a person. *Rests on* Action wiring 34 and 38.

---

## Examples

### Walkthrough — a clean round grounds a page

The council freezes `compositions/immutable-transaction-ledger.md` at base commit `2f1b5c1`: [Freeze] reads the page at that commit from the repository and records round `r-14` with snapshot hash `a1a6621b…`. Three readers, none of whom has read an earlier round, are handed the snapshot and run GRID, EOS with the builder's reading, and Linus; each verdict carries `a1a6621b…` and its pass, so each counts (Invariant 1.2, Action wiring 5). The verdicts are holds, holds and counterexample — one foundational finding, an operator's closing never sized. The first triager rejects it: the protocol's open sizes against the kind's largest record, which Term true maximum on [Recoverable Invocation](./recoverable-invocation.md) makes the operator's closing too. The round's settled triages now carry no foundational class, so the count decides the round clean and is a deciding count: the finding goes to a second triager, another actor, whose brief carries the finding, the first triage's rejection, the method's test and the blame rule, and not the threshold (Action wiring 11 through 13, 37). The second triager rejects it on the same text, and the round settles. [Repair] then carries the round's records and the refining cures that add no rule: the page at the head is still the snapshot, every cure answers a finding settled as cure, every fragment resolves to one site on the page and its old text is found verbatim, none sits in the claim families, the gate reports nothing over the repair tree it does not report over the head, the tree's diff is exactly the change set, and the commit lands on the head it was built from, carrying the council trailer. The round is clean.

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
Check 3.1: An auditor MUST find a maintainer's ruling for EVERY council commit changing a rule in the claim families (Invariant 3.1).
Check 4.1: An auditor MUST find no council commit's page patch answering a finding whose settled triage's side EQUALS model (Invariant 4.1).
Check 5.1: An auditor MUST find two triages under two actor references for EVERY finding of a settled round whose first triages carry no foundational class (Invariant 5.1).
Check 6.1: An auditor MUST find no council commit answering a malformed verdict (Invariant 6.1).
Check 7.1: An auditor MUST find EVERY council commit's trailer naming an intent event in the journal (Invariant 7.1).
Check 7.2: IF the journal reports Purged for a council commit's intent event, round record, triage record OR ruling THEN an auditor MUST exclude the commit from every check (Invariant 7.2).
Check 8.1: An auditor MUST find, for EVERY round frozen on a page whose round count the round budget DOES NOT EXCEED, a maintainer's ruling later than the page's previous round (Invariant 8.1).
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

WHY: one repository has one head. The protocol's one writer per act key serializes the invocations — with no commit fence it bounds when a commit is issued, not when it lands — and a call whose tree was built on a head that moved before its open meets the repository's conflict (Capability requirement 13), which the protocol records as a refusal with nothing written.

### Indeterminate outcome

```
Indeterminate outcome 1: Recoverable Invocation's sweep MUST close a council commit whose reply was lost, through the commit probe.
Deleted: Indeterminate outcome 2. Action wiring 23 owns it: a repair builds its own tree, so a crash leaves nothing a later call reads.
```

WHY: a commit that landed with its reply lost carries its council trailer, so the probe finds it. A crash ahead of the commit leaves only the dead call's own tree, which no later call reads; the intent it opened is the sweep's, which escalates it, the kind having no commit fence (Recoverable Invocation commit 14b), and the maintainer settles the escalation inside the retention period (Capability requirement 14).

---

## Terms

Each `[Term]` marker above links to its term entry here.

### Vocabulary

Term actors: the composition; the constituents; the deployment; the council; the writer; a reader; a formal engine; a verifier; a triager; the second triager; the maintainer; an auditor; the sweep.

Term records: the rounds, verdicts, triage records, rulings and escalations the composition records through Audit Trail's record_action; the intents, outcomes, refusals, recovery intents and escalations Recoverable Invocation writes for the act kind council.commit.

Term record verbs: clear, answer, apply, bind, build, evaluate, exclude, pass, repair, settle, call, carry, change, commit, compare, count, disclose, escalate, find, freeze, journal, provision, push, publish, rebuild, record, refuse, remove, rest, run, serialize, serve, supply, triage, write, accept, belong, privilege, judge, choose, close, hold.

Term value sets: verdict = holds | counterexample | malformed. class = foundational | refining | rhetorical. kind = A | B | C | D. blame = fresh | older. side = model | english | both. disposition = cure | route | reject | decline. pass = grid | eos | linus | formal. role = first | second | settling. action reference = council.round | council.verdict | council.triage | council.ruling | council.escalation | council.commit.intended | council.commit.committed | council.commit.refused | council.commit.recovery_intended | council.commit.abandoned | council.commit.escalated.

Term bounds: round budget (round_budget), patch cap (patch_cap), commit completion bound (commit_completion_bound), commit round trip (commit_round_trip), probe round trip (probe_round_trip).

Term qualifiers: migrated — written in GRACE lang v0.63 from the first draft (2026-10-10).

Term terms: writer, diff check, admitted freeze, admitted report, admitted ruling, admitted repair, opened repair, change set, snapshot, snapshot hash, base commit, round, round id, search, clean round, settled round, repair tree, page, finding, site, pass, sound verdict, counted verdict, patch, fragment, claim families, side, role, triage record, settled triage, deciding count, round's records, records sections, maintainer's queue, maintainer's ruling, standing ruling, round budget, patch cap, sweep identity, commit binding, commit partition, commit probe, commit envelope, council nonce, council trailer.

Term snapshot: a page's bytes at a base commit, named by the base commit and the snapshot hash.

Term snapshot hash: the SHA-256 of the page's bytes at the base commit.

Term base commit: the repository commit a round's snapshot was taken from.

Term round id: the event id of the round's record — what [Report], [Triage] and [Repair] name a round by.

Term page: a canonical document under the repository — a pattern file.

Term round: three passes — GRID, EOS with the builder's reading, Linus — by three readers, each handed one snapshot.

Term search: passes over a page a change moved between them; it counts toward nothing.

Term clean round: a settled round whose settled triages carry no foundational class and whose repair's invocation closed council.commit.committed, as Recoverable Invocation's read invocation answers it.

Term cited: open, close, refuse, yield, act kind, act key, commit, commit fence, pairing datum, repeatable, probe, completion bound, commit round trip, probe round trip, journal, retention period, service identity, outcome envelope, retry terminus, critical section, act-in-flight, section-unavailable, journal-unavailable, recording-failure, true maximum, resolve, intent event id, read invocation, call pause bound, open-upper-bound sequence-range read: Recoverable Invocation. record_action, reference length cap: Audit Trail. The entry A clean round is a sample, and the sections titled Order and iteration, The formal-layer vote and What "grounded" means: `pressure-testing.md`. The section titled Composition state: `execution-contract.md`.

#### Freeze

The action that opens a round: it reads the page at the base commit from the repository, refuses a page past its round budget with no standing ruling, records the round, and answers the round id and the snapshot every verdict of the round must carry.

Kind: Operation

#### Report

The action that records one verifier's verdict against a round's snapshot, refuses a verdict about other bytes or for a pass already counted, and escalates a malformed one.

Kind: Operation

#### Triage

The action that records one triager's sorting of one finding of a round's counted verdicts — role, class, kind, blame, side and disposition — first; second and blind, by another triager, where a count decides an outcome; and settling, by a third, where the two part.

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
last gate: 2026-10-10 — Final Critique 2, three fresh readers, three passes on one text (round 1's cures, frozen at 660ecec) — 13 foundational after deduplication (25 reports), nine reached by two or three passes, all fresh, ten of them in text round 1's cures wrote; 35 refining reports, 9 rhetorical reports; not clean, so no count decided anything; every foundational finding cured in place; 2026-10-10 — Final Critique 1, three fresh readers, three passes on one text (the first draft, frozen at 47128cc) — 12 foundational after deduplication, every one reported by two or three passes, all fresh; 32 refining reports, 9 rhetorical reports; not clean, so no count decided anything and no second triage was owed (Action wiring 11); every foundational finding cured in place
open:
- 2026-10-10-a · refining · the whole page · round 2 read round 1's cures; its own cures made the earliest record count in place of a lock, gave a ruling the patch it admits, counted frozen rounds against the budget, widened the purge exclusion to the council's own records and ordered [Repair]'s refusals → round 3 on the cured page
- 2026-10-10-b · refining · Term repository · the store the act commits to is a deployment's version-controlled repository, which no atom in this library owns → an atom for a versioned store, or the store's contract kept here
- 2026-10-10-c · refining · Verdict 6, Verdict 7 · "the explored state count stopped growing" is a reading [Report] has no input for, and an engine run whose twin is not rejected, or whose count still grows, fits no verdict → the adapter reports its state counts and such a run answers malformed, or Verdict 7 moves to External check 2
- 2026-10-10-d · refining · Term round count · the council's records live by the journal's retention, so past the horizon the count reads a shorter history than the page ran, and Invariant 7.2 excludes a commit whose records purged first; a [Freeze] retried after a lost reply records a second round that counts against the budget → a council retention no shorter than council.commit's and at least the round budget's span, and a freeze retry that reads its round back
- 2026-10-10-e · refining · Term fragment · a fragment, a patch id, a site and a trace carry no length cap of their own, and a verdict past the substrate's payload cap can never be recorded → caps under the reference length cap, sized where the intent and the verdict are
- 2026-10-10-g · refining · [Freeze] · a base commit behind the head is admitted, and a page changed since can never be repaired → a freeze whose page differs at the head answers stale
- 2026-10-10-h · refining · Term commit probe · a person's cherry-pick copies the council trailer, so the probe answers undecidable for a commit the council made once → the copy named a write outside the composition, or a probe that reads the commit's parent
- 2026-10-10-i · refining · Composes 7 · read literally, it bars a round on Recoverable Invocation's, Audit Trail's or this page from landing its cures → Composes 7 scoped to the wiring, or such rounds ruled by the maintainer
- 2026-10-10-j · refining · Term maintainer's queue · "escalation", "disposition" and "settle" each name one thing here and another in the protocol → one word for each
- 2026-10-10-k · refining · Action wiring 22 · the intent carries the round id and the base commit, ids the substrate and the repository minted, and the page does not say why Recoverable Invocation Primitive policy 10 admits them → the admission stated, or the ids moved out of the intent
- 2026-10-10-l · refining · Capability requirement 14 · the protocol's other operator duties — binding duplicates under journal fence none, findings on the compliance surface — have no owner here → the maintainer named for them, or the deployment
- 2026-10-10-m · refining · Action wiring 25, Term records sections · the diff check compares a line diff with sentence fragments, and a fragment in the records sections names no target or insertion point → the unit stated, and the records' targets
- 2026-10-10-n · refining · Term round · one commit per round is implied by staleness and never stated, and nothing stops one reader running two passes of a round → both stated
- 2026-10-10-o · refining · Term claim families · a fragment that redefines a Term an Invariant reads is not in the claim families, so a claim can be weakened through its vocabulary with no ruling → the gate widened to the Terms the claim families read, or the cost stated
```

## Decisions

Directional changes only. Everything smaller lives in the commit that made it: `git log -- compositions/verified-repair.md`.

- **2026-10-10 — The council written as a page before any runtime installs it.** *Chose:* the repair loop as a composition of Recoverable Invocation and Audit Trail — every commit an act of the protocol, keyed by the repository, paired by the invocation id in the commit's trailer; one verdict contract for readers and engines; a triage record carrying the side a finding indicts; claims gated to the maintainer; deciding counts triaged twice, the second blind to the threshold. *Over:* a loop that commits a patch as its own write, outside the protocol, and an exact diff of one fragment. *Because:* the maintainer ruled that the process is part of the process, and every rule here is one the manual grind paid for, written where the machine that will run it can be held to it.

- **2026-10-10 — Round 1: a repair builds its own tree, a round counts by pass, and the maintainer rules through an action.** *Chose:* [Repair] builds its tree from the head and the repository takes it only on that head; a verdict names its pass and a round counts one verdict per pass; the settled triage and the round's own commit decide whether a round was clean; the maintainer's ruling is a record [Rule] writes, read where a round starts and where a claim is patched; the council nonce is the pairing datum, and the intent event id rides the trailer beside it. *Over:* a shared working copy restored on failure, three verdicts of any kind closing a round, and a ruling no action could record. *Because:* the first round's three passes found the shared copy, the count and the ruling broken from two or three directions each, and every cure that deleted state beat a cure that guarded it.

- **2026-10-10 — Round 2: the earliest record counts, and a ruling carries what it admits.** *Chose:* the earliest sound verdict of each reader pass, and the earliest triage record of each role, as the ones that count, with one actor to one record of a finding; a maintainer's ruling that carries the round and the patch whole, compared byte for byte; the round budget counted over frozen rounds, a page's standing ruling spent by the freeze it admits; a commit excluded from every check once any record a check reads for it is purged; [Repair]'s staleness and settlement answered before any gate escalates. *Over:* a lock around the journal's read-then-append, a ruling that names a patch id, and a budget over settled rounds. *Because:* a read-then-append the substrate cannot make conditional is settled by an order the journal already keeps, and a ruling on a name is a ruling on whatever later carries the name.

NOTE: End of Verified Repair.
