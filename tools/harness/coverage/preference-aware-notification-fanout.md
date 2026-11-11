# Coverage matrix — `preference-aware-notification-fanout`

- **Pattern:** `compositions/preference-aware-notification-fanout.md`
- **Model:** two models. `preference-aware-notification-fanout.tla` follows one disposition pair through its two writers, the lease, the gap run and the cap, with sixteen buggy twins, `preference-aware-notification-fanout-<name>-buggy.tla` for `ghost-write`, `foreign-admit`, `no-reread`, `redispose-live`, `cap-split`, `young-gap`, `no-intent`, `abandon-disposed`, `redispose-abandoned`, `answer-unwritten`, `silent-suppress`, `create-on-suppress`, `double-initiate`, `no-initiation`, `payload-mismatch`, `refuse-writes`. `preference-aware-notification-fanout-batch.tla` follows the invocation's loop over two subscribers, with five twins, `preference-aware-notification-fanout-batch-<name>-buggy.tla` for `lapse-keeps-going`, `early-return`, `answer-twice`, `refuse-writes`, `answer-unwritten`. Each `.tla` has its `.cfg`; five reachability probes, `…-probe-<name>.tla` and `…-batch-probe-foreign-yield.tla`, are rejected by design.
- **Reviewer / date:** the model's author, the session that landed it — 2026-11-09. Not a fresh-context read; the next scheduled rescan owes one.
- **Formal-layer vote load-bearing claims:** the vote was cast yes in 2026-06 for the frequency-cap race (Invariant 4) and the model re-derived 2026-11-09 over what the Ledger's `formal:` line named: the invocation and [Reconcile Gaps] as two processes over one disposition under a per-disposition exclusion whose lease expiry is the holder's terminus, and the gap leg bounded in age. The deliver pair is no longer ordered (Execution Contract Database 1: one commit), so the model has no orphan. The model takes every composition-level Invariant that is not a pure function of the record as load-bearing: Invariant 1.1, 2.1, 4.1, 4.2, 5.1, 5.2, 8.1, 9.1, 10.1, 10.2.

## Step 1 — harness re-run (must pass)

- Correct models: `node check.mjs ../../compositions/preference-aware-notification-fanout.tla` → `HOLDS` ✓ *(20,514 states)*; `node check.mjs ../../compositions/preference-aware-notification-fanout-batch.tla` → `HOLDS` ✓ *(4,233 states)*
- Buggy twins: each `node check.mjs ../../compositions/preference-aware-notification-fanout[-batch]-<name>-buggy.tla --buggy` → `CAUGHT` ✓ *(Step 2 names the check that finds each)*
- `node audit.mjs --only compositions/preference-aware-notification-fanout`: the result is recorded in the commit that lands the model.

## Step 2 — coverage matrix

The pair model has one subscriber, two writers and the clock. The writers are the invocation and the redisposer (a [Redispose] caller, or the gap run calling it as the holder); each takes the pair's exclusion with a lease of length D, reads the pair's latest disposition event, runs the gate and commits as three separate steps, so the clock can run between them and a lease can lapse. A lapsed writer's only move is to yield. The gap run is a reconcile intent (once the invocation is no longer young) and then, in one of two modes, a repair (a [Redispose] call for a gap principal) or an abandonment. The transport ends a Pending record (delivered, failed, expired); another fanout delivers to the same principal under the per-principal exclusion. The gate is a nondeterministic verdict (deliver, only below the cap; suppress with and without retry eligibility; fail). The model keeps what the journal's reads derive (the pair's operative event, the latest record's status, earlier records still live, the committed delivery count), no history: a property of the state is an invariant over the state, and a property of a step is a name `viol` takes when the step breaks it. The batch model has the invocation, the clock, a foreign holder of a pair (the redisposer abstracted to what the invocation sees) and Event Log refusing an append. Fourteen entries in the pair `.cfg`, four in the batch's.

| Spec invariant (no. + name) | Load-bearing (vote)? | Verdict | Model construct / reason |
|---|---|---|---|
| Invariant 1.1 — the lists partition the queried list | YES | `checked` **covered** | pair: `Invariant_1_1` (once the invocation returns, the subscriber is answered; a yielded one was written for by no one in the invocation; a created, failed or suppressed answer names a disposition event). Twins `-answer-unwritten`, `-refuse-writes`, `-silent-suppress`. batch: `Invariant_1_1` (every subscriber answered, once), `Action_13_LapseYieldsRemaining`, `Invariant_1_1_Once`; twins `-lapse-keeps-going`, `-early-return`, `-answer-twice`, `-refuse-writes`, `-answer-unwritten` Broken by `preference-aware-notification-fanout-batch-answer-unwritten-buggy.tla` (`Invariant_1_1`), `preference-aware-notification-fanout-batch-early-return-buggy.tla` (`Action_13_LapseYieldsRemaining`), `preference-aware-notification-fanout-batch-answer-twice-buggy.tla` (`Invariant_1_1_Once`). |
| Invariant 1.2 — a principal outside the queried list appears in no list | no | `unstatable` by-construction | the answer is a function of the queried subscribers; the model has no other principal |
| Invariant 2.1 — a suppressed subscriber gets no create in the pass | YES | `checked` **covered** | `Invariant_2_1` (the commit of a suppress or fail verdict changes no record). Twin `-create-on-suppress` Broken by `preference-aware-notification-fanout-create-on-suppress-buggy.tla`. |
| Invariant 2.2 — the suppression carries the first precedence rule that fired | no | `owed` out-of-scope | the gate is a pure function of the record, the now and the history (Shaping gate 2 through 4, 21); the model takes its verdict as a free choice |
| Invariant 3.1, 3.2 — quiet-window safety | no | `owed` out-of-scope | per-record predicates over the observed record and the now, with no cross-writer surface; the first model's scope exclusion, kept |
| Invariant 4.1 — every delivery's observed count falls below the cap | YES | `checked` **covered** | `Invariant_4_1` (the principal's committed deliveries, this fanout's and another's, never pass the cap). Twins `-cap-split`, `-foreign-admit`, `-ghost-write` Broken by `preference-aware-notification-fanout-ghost-write-buggy.tla`. |
| Invariant 4.2 — under serialized-per-principal, the observed count is the preceding deliveries | YES | `checked` **covered** | `Invariant_4_2` (no delivery lands while a writer holds the exclusion over a deliver verdict). Twin `-cap-split` (another fanout's cap evaluation ignores the exclusion) Broken by `preference-aware-notification-fanout-cap-split-buggy.tla`. |
| Invariant 4.3 — under best-effort, every overshoot has an overshoot record within the window | no | `owed` out-of-scope | a recount over the journal with a deadline; the model takes the serialized arm and the twin that splits the observation from the commit (the first model's choice, kept). Reconciliation 30 through 32, 35 and 38 go with it |
| Invariant 5.1, 5.2 — no silent disposition | YES | `checked` **covered** | `Invariant_5` (a suppression or failure answered names a journaled event) and `Invariant_1_1`. Twins `-silent-suppress`, `-answer-unwritten`. The model reads that the event exists, not the fields it carries (reason, preference id, evaluation inputs, retry eligibility): those are the event's shape, checked at Check 3.1 through 3.4 Broken by `preference-aware-notification-fanout-answer-unwritten-buggy.tla` (`Invariant_5`), `preference-aware-notification-fanout-batch-answer-unwritten-buggy.tla` (`Invariant_1_1`). |
| Invariant 7.1 — every verdict-bearing event replays to its recorded verdict | no | `owed` out-of-scope | the gate is a pure function; replay is that function applied to recorded inputs (Verdict replay 1 through 5) |
| Invariant 8.1 — every created record carries the content the digest names | YES | `checked` **covered** | `Invariant_8_1`; [Redispose] and the gap run carry a payload, and a mismatch is refused (Action wiring 40, Reconciliation 7). Twin `-payload-mismatch` Broken by `preference-aware-notification-fanout-payload-mismatch-buggy.tla`. |
| Invariant 9.1 — a disposition pair carries no two live records | YES | `checked` **covered** | `Invariant_9_1` (the latest record's status, and earlier records still live, never sum past one). Twins `-foreign-admit` (the exclusion admits a foreign holder), `-ghost-write` (a lapsed writer commits), `-no-reread` (the invocation gates over an existing event), `-redispose-live` (a live record is retryable), `-create-on-suppress` Broken by `preference-aware-notification-fanout-foreign-admit-buggy.tla`. |
| Invariant 10.1 — one initiation entry per fanout id | YES | `checked` **covered** | `Invariant_10_1`. Twin `-double-initiate` Broken by `preference-aware-notification-fanout-double-initiate-buggy.tla`. |
| Invariant 10.2 — no disposition before the initiation entry | YES | `checked` **covered** | `Invariant_10_2` (no event, record, abandonment or intent while `ninit` is 0). Twin `-no-initiation` Broken by `preference-aware-notification-fanout-no-initiation-buggy.tla`. |
| Action wiring 10 through 12 — the read under the exclusion finds an event and writes nothing | no | `checked` **covered** | the `GateSeen` step; read as Invariant 9.1. Twin `-no-reread` Broken by `preference-aware-notification-fanout-no-reread-buggy.tla`. |
| Action wiring 13, 14, 43, 44; Reconciliation 25 — a lapsed lease writes nothing and yields | no | `checked` **covered** | the `Lapse` step and the lease check on `CommitWrite`; read as Invariant 9.1 and 4.1 (pair) and `Action_13_LapseYieldsRemaining` (batch). Twins `-ghost-write`, `-lapse-keeps-going` Broken by `preference-aware-notification-fanout-batch-early-return-buggy.tla`. |
| Action wiring 24, 30, 56; Reconciliation 18 — a refused append writes nothing | no | `checked` **covered** | the `CommitRefuse` step; read as Invariant 1.1. Twins `-answer-unwritten`, `-refuse-writes` Broken by `preference-aware-notification-fanout-refuse-writes-buggy.tla` (`Invariant_1_1`), `preference-aware-notification-fanout-answer-unwritten-buggy.tla`. |
| Action wiring 45, Term abandonment record — no disposition lands on an abandoned pair | no | `checked` **covered** | `Action_45`. Twins `-redispose-abandoned`, and `-ghost-write` and `-young-gap` reach it through a write after the abandonment Broken by `preference-aware-notification-fanout-redispose-abandoned-buggy.tla`. |
| Action wiring 46, 47 — what is retryable | no | `checked` **covered** | `Retryable`; read as Invariant 9.1. Twin `-redispose-live` Broken by `preference-aware-notification-fanout-redispose-live-buggy.tla`. |
| Action wiring 60, Capability requirement 36 through 38 — a foreign holder yields the subscriber | no | `checked` **covered** | `InvYield` and `FreeFor`; read as Invariant 9.1. Twin `-foreign-admit`; the batch model has the foreign holder's lease as `fh` Broken by `preference-aware-notification-fanout-foreign-admit-buggy.tla` (`Invariant_9_1`). |
| Capability requirement 16 through 18 — the per-principal exclusion binds every cap evaluation | no | `checked` **covered** | `Pex` and `Other`; read as Invariant 4.1 and 4.2. Twin `-cap-split` Broken by `preference-aware-notification-fanout-cap-split-buggy.tla` (`Invariant_4_2`), `preference-aware-notification-fanout-ghost-write-buggy.tla` (`Invariant_4_1`). |
| Reconciliation 3, 4 — the gap run writes nothing for a young invocation | no | `checked` **covered** | `Reconciliation_3_4` (a gap commit or abandonment at `now` below `Lower`, the invocation duration bound and the create latency). Twin `-young-gap` Broken by `preference-aware-notification-fanout-young-gap-buggy.tla`. |
| Reconciliation 8 — no repair before the reconcile intent | no | `checked` **covered** | `Reconciliation_8`. Twin `-no-intent` Broken by `preference-aware-notification-fanout-no-intent-buggy.tla`. |
| Reconciliation 11 — a re-read under the exclusion that finds an event writes nothing | no | `owed` **covered** | `GateSeen` for the gap call; read as Invariant 9.1 No check of this model states it, so no twin can be said to break it (2026-11-10, unit `tooling: every check has a twin that breaks it`): an action's shape and a probe that reaches it. |
| Reconciliation 20 — the gap run abandons a gap principal only | no | `checked` **covered** | `Reconciliation_20`. Twin `-abandon-disposed` Broken by `preference-aware-notification-fanout-abandon-disposed-buggy.tla`. |
| Composition state 12, Check 1.1; Capability requirement 29, Term liveness sum — every queried subscriber carries a disposition event or an abandonment inside the window | no | `owed` out-of-scope | an eventual claim across repeated runs and clock arithmetic. A safety model cannot assert it, and a run's refused write is carried to the next run (Reconciliation 18), so the window holds only while the legs' writes land. The page's start refusal owns the arithmetic |
| Composes 1 through 13; Composition state 1 through 11, 13 through 15; Capability requirement 1 through 15, 19 through 30, 39 through 54 | no | `unstatable` out-of-scope | wiring, derived indexes and deployment configuration the model fixes: it holds the journal's reads, not the indexes, and one instance of each constituent. The cap serialization is the one setting it reads, as the exclusion's presence |
| Shaping gate 1 through 22; Verdict replay 1 through 5; Primitive policy 1 through 13; Action wiring 1 through 9, 15 through 23, 25 through 29, 31 through 44, 48 through 59, 61 | no | `owed` out-of-scope | the pure gate and its journaled inputs, the refusals before any write, and the event shapes. The gate is a free verdict: deliver below the cap, suppress with or without retry eligibility, fail |
| Non-goal 1 through 12; Clock semantics; Concurrency 1, 3; Payload retention; Per-channel caps; Staleness | no | `unstatable` out-of-scope, or read above | they bound the claim (legal permission, attribution, transport, authorization, sealing) or state deployment duties; Concurrency 1 is read as Invariant 9.1 and 4.1 |

Each twin against the checks that reject it, measured by running every twin against every check alone (the second column is the first check to fail with the whole list on, with the states searched when it did; the third names every other check that rejects the twin by itself):

| Twin (the rule it breaks) | First check to fail (states) | Also rejected by |
|---|---|---|
| `-ghost-write` (Action wiring 43, Reconciliation 25: a lapsed writer commits) | `Invariant_4_1` (1,483) | `Invariant_9_1`, `Action_45` |
| `-foreign-admit` (Capability requirement 38: the exclusion admits a foreign holder) | `Invariant_9_1` (1,266) | `Invariant_4_1` |
| `-no-reread` (Action wiring 10 through 12: the invocation gates over an existing event) | `Invariant_9_1` (966) | — |
| `-redispose-live` (Action wiring 46: a live record is retryable) | `Invariant_9_1` (865) | — |
| `-cap-split` (Capability requirement 16 through 18: another fanout's cap evaluation ignores the exclusion) | `Invariant_4_2` (55) | `Invariant_4_1` |
| `-young-gap` (Reconciliation 3, 4: no lower edge) | `Reconciliation_3_4` (19) | `Action_45` |
| `-no-intent` (Reconciliation 8: repair without the intent landing) | `Reconciliation_8` (210) | — |
| `-abandon-disposed` (Reconciliation 20: abandoning a pair that has an event) | `Reconciliation_20` (1,803) | — |
| `-redispose-abandoned` (Action wiring 45: an abandoned pair is admitted) | `Action_45` (1,834) | — |
| `-answer-unwritten` (Action wiring 24, 30: a refused disposition answered as made) | `Invariant_5` (58) | `Invariant_1_1` |
| `-silent-suppress` (Invariant 5.1, 5.2: a suppression with no event) | `Invariant_5` (57) | `Invariant_1_1` |
| `-create-on-suppress` (Invariant 2.1: a suppression that creates) | `Invariant_2_1` (57) | `Invariant_9_1` |
| `-double-initiate` (Invariant 10.1) | `Invariant_10_1` (5) | — |
| `-no-initiation` (Action wiring 37, 38: an unknown fanout id is written for) | `Invariant_10_2` (38) | — |
| `-payload-mismatch` (Action wiring 40, Reconciliation 7) | `Invariant_8_1` (95) | — |
| `-refuse-writes` (Action wiring 14: a refused disposition written anyway) | `Invariant_1_1` (156) | — |

And the batch model's twins:

| Twin (the rule it breaks) | First check to fail (states) | Also rejected by |
|---|---|---|
| `-lapse-keeps-going` (Action wiring 13: a lapse yields only the held subscriber) | `Invariant_1_1` (144) | `Action_13_LapseYieldsRemaining` |
| `-early-return` (Invariant 1.1, Action wiring 8: the invocation returns with a subscriber unreached) | `Invariant_1_1` (4) | `Action_13_LapseYieldsRemaining` |
| `-answer-twice` (Invariant 1.1: a subscriber answered twice) | `Invariant_1_1_Once` (383) | `Invariant_1_1` |
| `-refuse-writes` (Action wiring 14) | `Invariant_1_1` (810) | — |
| `-answer-unwritten` (Action wiring 24, 30) | `Invariant_1_1` (939) | — |

Every check in both `.cfg` files is rejected by at least one twin by itself, so no check is vacuous. Reachability probes (each a copy of the model with one negated fact added, rejected by design): the gap run's repair delivers (`-probe-gap-repair`), a delivery whose record failed is redisposed toward a second record (`-probe-retry`), the invocation answers a pair from an event another writer left (`-probe-seen`), an abandonment record covers a gap principal (`-probe-abandon`), a foreign holder holds a pair at the invocation's read (`-batch-probe-foreign-yield`).

## Step 3 — bound saturation

Raise the model's scope once and confirm the explored-state count does not grow:

- Pair model, `Cap` 2 → 3: 20,514 → 30,098 states, exhaustive, holds. `D` 2 → 3: 32,981 states, holds. `Cr` 1 → 2: 25,637 states, holds. The clock counts to the gap leg's lower edge and holds there, and each lease counts down to expiry, so there is no clock bound to raise. The count grows with each bound, as the first model's did (10 → 29 states): a larger bound adds behaviors. What is recorded is that each larger configuration is exhaustive and still holds. Two subscribers pass the checker's 200,000-state cap with both writers present, which is why the loop is its own model.
- Batch model, two subscribers → three: 4,233 → 116,369 states, exhaustive, holds.

## Outcome

- GAP rows: none.
- by-construction flags on load-bearing invariants: none (Invariant 1.2 is by construction and is not load-bearing).
- Result: clean. Two readings recorded, not counterexamples:
  - The lease bounds the held pair and nothing between pairs. The invocation takes a new pair only inside its invocation duration bound in the model (Term invocation duration bound, "the longest a [Fanout Shaped] may run"); a deployment whose invocation stalled between pairs and resumed after the gap leg's lower edge could write a disposition for a pair the gap run abandoned, and the page has no rule that stops it beyond the bound itself.
  - Composition state 12 and Check 1.1 read unconditionally, while Reconciliation 18 carries a principal a run could not write for to the next run; the window holds only while the legs' writes land (see the out-of-scope row).
  *"Coverage cross-check 2026-11-09 — clean (all load-bearing invariants covered; every check rejects a twin; bounds raised)."*
