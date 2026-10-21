---- MODULE recoverable-invocation ----
\* Grace Commons — Recoverable Invocation: the protocol every regulated
\* composition follows around an irreversible act. Spec-level formal sibling of
\* compositions/recoverable-invocation.md. Derived validator; the English spec
\* is the single source of truth. On any disagreement, diagnose per
\* the entry *The conflict protocol* in pressure-testing.md.
\*
\* VERSION 7 (2026-10-20) takes the journal fence out. The maintainer ruled
\* 2026-10-20 that Execution Contract Database 2 covers a guard decided across a
\* lease check: a writer's re-read, its lease check and its append are one
\* transaction, because the lease's grant and the journal live in the one
\* store. A take is a write to the grant, so a journal write that has not
\* returned when another holder takes the section is refused, and no append
\* lands beside a closing or an intent another writer committed after its
\* take. Nothing is refused for time alone: a write whose lease has run out
\* with no taker still lands, beside nothing, since every other writer takes
\* the section first. v7 carries that refusal in every take (RefuseOvertaken,
\* below) and drops what the page dropped with the fence: JournalFence,
\* JournalSkew, FenceMargin and PerWriteFence (the fence, its skew and the two
\* instants it was judged against) and RetryUnanswered (a lost-reply write is
\* never issued again, the page's Primitive policy 37b, under every
\* deployment). The second invocation of SecondOpen now takes the section as
\* any writer does. Inv7_OneLiveIntent and Inv8_IntentUnderItsSection are
\* restated for the refusal: a second invocation's take leaves the first's
\* intent in flight nowhere, and an intent is in flight only under its own
\* invocation's grant, its instant passed or not. One new constant:
\*   TakeRefuses — TRUE: a take refuses every journal write it overtakes, the
\*                 store as the contract states it. FALSE is the vacuity
\*                 guard recoverable-invocation-buggy-journal, a journal
\*                 that lands a write after another holder's take.
\* v7 holds at the main constants (23,962 states). There a late closing is out
\* of reach either way — with TakeRefuses = FALSE, Inv2_OneWriter alone still
\* holds (26,015 states) — so the refusal's work on the closing is measured at
\* a nine-tick horizon (CompletionBound = 6, SweepLease = 6, MaxLand = 4,
\* MaxTime = 9, Cadence = 10, LateLanding = 2, OpenBy = 0, MaxSweepDeaths = 0,
\* MaxPauses = 0), where Inv2_OneWriter is VIOLATED with TakeRefuses = FALSE
\* (23,321 states: the invocation's outcome lands after the sweep's take,
\* beside the sweep's) and holds with it (25,286).
\*
\* VERSION 6 (2026-10-07) brings the invocation's lost-reply path into step
\* with the grounded Lease atom, which forbids a holder to release a grant
\* under which a call is in flight (its Composition note 5c) and to issue a
\* second time, under one lease, an unfenced call that answered no answer (its
\* Sizing 8). v3 to v5 released after the read-back and at [Yield], as the page
\* did. Two constants:
\*   HoldUnanswered  — TRUE: an invocation one of whose calls has not answered
\*                     — a commit still in flight at [Yield], an outcome write
\*                     whose reply was lost, whether the read-back found it,
\*                     missed it, or a retry then landed — does not release;
\*                     the grant runs to its instant. FALSE is the page through
\*                     2026-10-06.
\*   RetryUnanswered — TRUE: a write whose reply was lost is issued again when
\*                     the read-back finds nothing. The page keeps that where
\*                     the journal fence is declared, the per-write instant
\*                     being what makes it safe, and forbids it where the
\*                     fence is none, the write then being unfenced.
\* The main configuration is the fenced deployment: TRUE and TRUE. No twin
\* file is added for HoldUnanswered. Flipped alone it holds — at the main
\* constants (21,974 states, v5's count) and at the longer horizon below —
\* because every other writer here waits for the examine edge, which is never
\* earlier than the invocation's own expiry. Flipped together with the
\* operator's reading one tick ahead (OperatorSkew = 1, ServiceIdentity =
\* FALSE: the -buggy-opclock defect) it is what lets the false abandonment
\* land: at the main constants Inv5_NoFalseAbandon is VIOLATED with
\* HoldUnanswered = FALSE (3,642 states) and holds with TRUE (28,114). So the
\* hold is a second defence against the operator's clock, and -buggy-opclock,
\* a copy of v4, is rejected for a race this version no longer has. The rule
\* itself is the constituent's and its rejected twin is the constituent's own
\* (atoms/lease-buggy-release.tla). What this version adds is the other
\* direction — holding to the instant breaks nothing here — and three runs at
\* a horizon long enough to reach the retry race (CompletionBound = 6,
\* SweepLease = 6, MaxLand = 4, MaxTime = 9, Cadence = 10, LateLanding = 2,
\* OpenBy = 0, MaxSweepDeaths = 0, MaxPauses = 0, the type invariant left out
\* because a sweep's next run leaves its range at that cadence), each with
\* PerWriteFence = FALSE:
\*   retry kept             — Inv2_OneWriter VIOLATED: the -buggy-perwrite race.
\*   retry dropped          — every invariant holds.
\*   retry dropped, early release — every invariant holds.
\* So the retry and the per-write instant stand or fall together: either the
\* instant is minted or the write is not issued twice. The page keeps the pair
\* under a declared fence and has neither under none; whether the pair earns
\* its place is an open line in the page's Ledger.
\* What the retry's safety rests on here is narrower than "the retry holds":
\* with the instant minted a read-back never misses a write this model has
\* issued (Probe_ReadBackNeverMisses holds at the main constants, 22,158
\* states, and at the longer horizon, 18,162), so the retry branch is not
\* reached and RetryUnanswered changes no state under the main configuration.
\* The retry the page keeps is of a write that never landed, and this model
\* issues no such write.
\*
\* VERSION 5 (2026-09-09) splits [OPEN] and raises the resolve budget. The
\* tenth gate found the first MODEL-WRONG finding since the sixth: v4 made the
\* intent's return and visibility one event on the argument that the section
\* holds off every racing reader, and that argument does not survive [Open]'s
\* own steps — the under-section pre-check read has no disclosed bound and the
\* intent write is exempt from the lease gate, so the read can consume the
\* lease and the write can land after the section has passed on. Two new
\* constants, each FALSE/large being the page as written:
\*   IntentGated — TRUE: the intent write passes the same
\*                 `remaining >= JournalWriteBound` gate as every other write.
\*                 FALSE is the page as written ("every journal write AFTER the
\*                 invocation's first"), and admits a second live intent for one
\*                 act_key that no duplicate surface detects, since all three
\*                 key on invocation_id and two invocations carry two of those.
\*   ReadBound   — the disclosed bound on the under-section pre-check read. The
\*                 page discloses none, which is ReadBound = CompletionBound:
\*                 the read may consume the whole lease. THE MAIN
\*                 CONFIGURATION SETS IT TO 1 and factors the read's duration
\*                 out, exactly as Inv4's window is factored out: a read that
\*                 consumes the lease is the variable under test in the
\*                 Inv7_OneLiveIntent configurations, and carrying it in the
\*                 main run as well costs a state space the harness cannot
\*                 finish. "All invariants hold" here therefore says nothing
\*                 about a long read, and the Inv7 pair is where that is said.
\* And the tenth gate's other in-frame finding was a behaviour v4 could express
\* and a CONFIGURATION CONSTANT excluded — a supersession chain needs two
\* resolutions against MaxResolves = 1. v5 raises it, counts supersession
\* TRANSITIVELY (the standing closing is the one no other closing names), and
\* adds a second-occurrence probe. A probe that asks whether a thing ever
\* happens does not ask whether it happens twice, and in a concurrency model
\* the second occurrence is where the defects live.
\*
\* VERSION 4 (2026-09-08) brings [RESOLVE] — the operator, the protocol's
\* THIRD writer — inside the frame. v1-v3 modelled two writers against a page
\* that always had three, and the ninth gate returned five of seven
\* foundational findings on [Resolve] and the purge, both of which v3's NOT
\* MODELED list named. Two of those five are in the model's own domain and are
\* carried here as constants, so that the twin with each turned off is the page
\* as written:
\*   SupersedesNamed — TRUE: a resolution written over an existing closing
\*                    carries `supersedes` naming that record, so the pair is
\*                    one act closed twice on purpose. FALSE is the page as
\*                    written for the ESCALATED case, where the resolution
\*                    carries only `resolved_by` — which names the operator and
\*                    not a record, so the precedence rule and the acceptance
\*                    check have no referent and both read a lawful resolution
\*                    as a duplicate (gate 9, F6).
\*   OperatorSkew   — how far the operator's own reading may run ahead of the
\*                    true instant. 0 is a declared operator seam, injecting
\*                    `now` as every other reading on the page is injected.
\*                    Non-zero is the page as written, where [Resolve]'s
\*                    too-young guard compares a reading no seam supplies
\*                    (gate 9, F7).
\*
\* VERSION 3 (2026-08-30) extends v2 to the two things the seventh gate found
\* in the frame's declared holes — the fence's two clocks, and the lost reply
\* with its read-back and retry. Both reproduce; and the remedy the gate
\* prescribed for the second one FAILED here until the fence margin was applied
\* to the per-write instant as well as the lease's, which is the same skew
\* defect a second time.
\*
\* VERSION 2 (2026-08-30). Version 1 held, rejected three twins, and corrected
\* the prose twice — and then the sixth fresh-reader gate found three
\* foundational timing defects the model had passed over. All three had one
\* cause: AT EACH POINT THE MODEL WAS MORE DISCIPLINED THAN THE PROSE, so the
\* model was validating a better spec than the one anybody would implement.
\*   - v1's IssueOutcome FUSED the lease check with the write, so no time could
\*     pass between passing `remaining >= journal_write_bound` and issuing. The
\*     pause the spec itself admits was unrepresentable, and "a write issued
\*     inside the lease lands inside it" was a modeling primitive rather than a
\*     derived fact. v2 splits EVERY journal write into a Prepare (the gate) and
\*     an Issue (the write), with Tick free to fire between them.
\*   - v1's sweep held the section until its write LANDED; the spec releases on
\*     `record_action`'s RETURN, and the visibility it declares is time-based
\*     (visible once journal_write_bound has elapsed since issue), so a waiter
\*     admitted at the release may read before the write is visible. v2 gives
\*     every write a return tick AND a visibility tick, return <= visible, and
\*     releases the section at return.
\*   - v1 gave the sweep a lease of CompletionBound; the spec's is
\*     max(completion_bound, closure_latency). v2 carries SweepLease as its own
\*     constant, so the closure arithmetic is derived rather than assumed.
\*
\* The two candidate remedies are CONSTANTS, so the model answers not only
\* "is this a defect" but "does the proposed fix close it":
\*   JournalFence   — the substrate honours a deadline on a journal write (a
\*                    write that would become visible past the writer's lease
\*                    expiry is refused, as a store-level commit_fence refuses a
\*                    late commit). FALSE is the corpus as it stands today:
\*                    record_action(action_ref, actor_ref, credential, data)
\*                    carries no deadline and no fence is declared anywhere.
\*   VisibleOnReturn — a write whose record_action has RETURNED is visible to
\*                    every subsequent range read of the instance from any node.
\*                    FALSE is the requirement as the spec declares it today
\*                    (visibility bounded only by time since issue).
\* The main model sets both TRUE and holds. Each set FALSE is a twin the
\* checker must reject — and each of those twins IS THE PROSE AS WRITTEN, which
\* is the point.
\*
\* FIVE COMPONENTS over ONE act:
\*   - the INVOCATION: opens (takes the section, issues the intent), issues the
\*     bound commit, prepares and issues the outcome, and may crash or pause at
\*     any point — a pause is time advancing while it does nothing;
\*   - the SECTION HOST: a lease per holder — CompletionBound for the
\*     invocation, SweepLease for a sweep run — released on the holder's return
\*     and otherwise at its expiry. A holder's death is not an event the host
\*     sees: the lease runs out;
\*   - the STORE: the adopter's constituent. With a FENCE it never applies a
\*     write past the fence instant it was given; without one a write may land
\*     any time within LateLanding;
\*   - the JOURNAL: Audit Trail. A write returns to its caller within
\*     JournalWriteBound of issue and becomes visible to other readers no
\*     earlier than it returns and no later than JournalWriteBound after issue;
\*   - the SWEEP: TWO runs on two nodes, each on its own cadence, over the same
\*     section: select at the edge, block on the take, re-read, probe, prepare,
\*     issue, release at return. A run may die at any point.
\*
\* INVARIANTS (named as the spec names them)
\*   Inv1_IntentFirst    — the store never receives the commit before the
\*                         intent record is appended.
\*   Inv2_OneWriter      — at most one outcome record ever exists for the act,
\*                         and at most one closing of any kind.
\*   Inv4_BoundedClosure — once the intent is older than the window and the
\*                         invocation will not close it, a closing is visible.
\*   Inv5_NoFalseAbandon — an abandonment is never contradicted by a commit
\*                         that lands later.
\*
\* THE HORIZON IS PART OF THE CLAIM, AND THE CLAIM IS BOUNDED BY IT.
\* v5's four-phase [Open] costs roughly a factor of ten in states per tick, and
\* the main configuration does not finish at MaxTime 6 or 7 inside the
\* harness's window. It runs at MaxTime = 5. "All invariants hold" therefore
\* means HOLD WITHIN FIVE TICKS OF DISCRETE TIME AT THESE CONSTANTS, and
\* nothing more: no monotonicity argument is offered here that would make five
\* sufficient for a longer behaviour, and none should be assumed.
\*
\* What makes that bound usable rather than a shrug is that each property's
\* WITNESS LENGTH is measured rather than guessed. A twin that still fails at a
\* horizon is proof that the horizon covers that property's witness — the twin
\* exhibits the violation, so the chain that produces it fits. So the twin
\* suite is re-run at every horizon change and its results are the evidence
\* that the main run is not vacuous for the invariant each twin attacks. Where
\* a property's witness does NOT fit — F6's needs a take, a read, a write that
\* lands past the lease, the section expiring, and a second take, which is
\* about seven ticks at these constants — the property gets its own
\* configuration with a horizon that covers it, exactly as Inv4's window does.
\* A property checked only in the main run and never exhibited by a twin is
\* checked at five ticks and claimed at five ticks.
\*
\* WHAT THE MAIN CONFIGURATION ACTUALLY CHECKS. Inv1, Inv2 and Inv5 fire at the
\* main constants. Inv4 does NOT: its antecedent needs `now >= intentAt +
\* Window`, and a Window the model can both reach and satisfy needs a horizon
\* several times the main one — so at these constants the Inv4 conjunct of
\* Safety is VACUOUS, and "all invariants hold" must not be read as evidence for
\* it. Inv4 is checked in its own configurations, where the horizon exceeds the
\* window and the bound is derived by controlled variation: tools/harness's
\* window_probe.sh and delta_probe.sh, which is where the closure arithmetic in
\* the page's Configuration section comes from. This is the vacuity trap in its
\* arithmetic form and it is written here because it caught this model once.
\*
\* MODELING CHOICES
\* - Discrete time. A write carries the ticks it will return and become visible
\*   on, chosen when it is ISSUED — not when its gate was passed.
\* - The sweeps are scheduled, not fair: time does not advance past a due run, a
\*   take that can succeed, or a run's re-read and probe (one instant, inside
\*   run_bound). Time DOES advance freely between a prepare and its issue: that
\*   is the pause, and making it representable is the whole of v2.
\* - The intent's return and visibility are one event. Justified, not assumed:
\*   the intent is written by the sole holder at the start of its lease, and the
\*   only readers who could race it — a second [Open], a sweep run — are held
\*   off by the section itself, so the gap cannot produce a second writer. Every
\*   write where a handoff DOES depend on the gap (outcome, closing) carries
\*   both ticks.
\* - The act kind (fenced store or not) is chosen at Init: one run covers both.
\* - No skew is modeled. Until v6 it was, between the two clocks the journal
\*   fence spanned; v7 has no journal fence, and the store judges a writer's
\*   grant inside the append's own transaction, where no instant is compared
\*   across clocks. Every comparison reads one clock; the spec's
\*   clock_offset_allowance widens those edges by a constant and the model
\*   checks their shape, not their width.
\* - A pause is free EXCEPT where it would let a run outrun `run_bound`: a
\*   sweep run that pauses past its own lease is charged a death, because a run
\*   that does not complete inside run_bound is not a conforming run. Without
\*   that charge the checker starves every act at every window, which is a
\*   statement about non-conforming runs and not about the protocol.
\*
\* NOT MODELED — and this list is not a disclaimer but a PREDICTION: the sixth
\* and seventh gates found their foundational defects almost exactly here, so
\* what follows is where the next ones will be. The eighth and ninth gates
\* found theirs here too — the ninth returned FIVE of seven on [Resolve] and
\* the purge — so v4 takes [Resolve] off this list and the list keeps its
\* record. What remains, with the gate-9 finding each one hid:
\* pairing; retention purge and the sweep's upper edge, and with it [Resolve]'s
\* `purged` arm (F5); the refusal path; the escalation's candidate list; the
\* recovery_intended record; the bindings table's lifecycle, and with it the
\* `kind` half of the section's key — one act of one kind here, so a signature
\* that omits the kind is invisible to this model (F1); the rejection-code
\* taxonomy, since the model counts records and never names a code (F2); the
\* derived indexes and what a delta-bounded read can still see (F3); the
\* compliance surface and outage reporting (F4);
\* the call pause bound and the sizing the page binds from Lease — the gates
\* here compare against JournalWriteBound alone, which stands for the page's
\* write floor, and the bound commit is issued ungated, which is wider than the
\* page's reading before it;
\* and the SWEEP's own lost-reply read-back — the read-back path is modeled for the
\* invocation's outcome only, so a run whose closing write's reply is lost is
\* outside the frame exactly as the invocation's was before v3.
\*
\* TWINS (each must be REJECTED by the checker):
\*   recoverable-invocation-buggy-reread.tla   — the sweep skips its re-read.
\*   recoverable-invocation-buggy-fence.tla    — abandons a fenceless act.
\*   recoverable-invocation-buggy-journal.tla  — TakeRefuses = FALSE (v7): a
\*                                               journal that lands a write
\*                                               after another holder's take.
\*   recoverable-invocation-buggy-visible.tla  — VisibleOnReturn = FALSE (gate 6, F3).
\*   recoverable-invocation-buggy-supersede.tla — SupersedesNamed = FALSE (gate 9, F6).
\*   recoverable-invocation-buggy-opclock.tla  — OperatorSkew > 0 (gate 9, F7).
\* -buggy-journal is this module at the main constants with the one constant
\* flipped (1,431 states, caught where a second invocation's intent lands beside
\* the first's). The other five are full copies of v4 at their own
\* constants, seven ticks, and still carry v4's journal fence as a constant
\* set TRUE; none of their defects turns on it. Run instead as configurations
\* of THIS module at the main constants (v7, 2026-10-20), VisibleOnReturn
\* (19,069 states) and SupersedesNamed (20,759) are rejected and OperatorSkew
\* holds (29,826), its race needing the early release v6 removed: with
\* HoldUnanswered = FALSE as well it is rejected (4,510). The other two are
\* structural and have no constant here. IntentGated = FALSE (gate 10,
\* F6) holds as a configuration of this module (27,045 states): the store's
\* refusal, not the lease gate, keeps a second invocation's intent off the
\* first's, and the page keeps the gate as every write's lease check.
\* Retired at v7, their bugs having lived in a late append the store now
\* refuses: -buggy-death (the host releases on death: ported to v7 it holds,
\* 27,500 states, the next holder's take refusing the dead holder's write,
\* and is rejected only with TakeRefuses = FALSE as well, 227 states),
\* -buggy-skew and -buggy-perwrite (the fence's two instants, which v7 does
\* not mint), and the six intent files that weighed the fence against the
\* lease gate (-probe-fenced-intent, -probe-fenced-ungated-intent,
\* -probe-fenceless-intent, -probe-intentgate-clean, -probe-intentgate-off,
\* -reach-intentneverinflightunheld).

EXTENDS Naturals

CONSTANTS
    CompletionBound,    \* the invocation's lease; the sweep's lower edge
    SweepLease,         \* the sweep's own lease: max(completion_bound, closure_latency)
    JournalWriteBound,  \* a journal write returns, and is visible, within this
    StoreLatency,       \* a fenced store applies a write within this many ticks
    LateLanding,        \* a fenceless store may apply a write up to this late
    Cadence,            \* ticks between a node's sweep runs
    Window,             \* compensation_window
    MaxTime,            \* the horizon of the model
    OpenBy,             \* the invocation opens by this tick
    MaxSweepDeaths,     \* how many sweep runs may die
    MaxPauses,          \* how many ticks a process may spend paused mid-write
    TakeRefuses,        \* TRUE: a take refuses every journal write it overtakes
    VisibleOnReturn,    \* TRUE: a returned write is visible to every later read
    MaxLand,            \* the true worst case for a journal write (>= JournalWriteBound)
    ServiceIdentity,    \* TRUE: the sweep closes acts; FALSE: report-only
    MaxResolves,        \* how many [Resolve] calls the model admits
    SupersedesNamed,    \* TRUE: a resolution names the record it closes over
    OperatorSkew,       \* how far the operator's own reading may run ahead
    IntentGated,        \* TRUE: the intent write passes the lease gate too
    ReadBound,          \* the disclosed bound on the under-section pre-check read
    HoldUnanswered      \* TRUE: no release while a call is in flight or unanswered

Sweeps == {"A", "B"}

VARIABLES
    now,
    fence,            \* TRUE: the act kind declares a commit_fence
    invPhase,         \* idle opened committed prepared closing done crashed yielded
    holder,           \* "none" "inv" "A" "B" "op" "sec"
    invExpiry,        \* the invocation's lease expiry: its fence instant
    heldUntil,        \* the current holder's lease expiry (0 when free)
    intentState,      \* "absent" "pending" "returned" "visible"
    intentReturnAt,   \* the tick its record_action returns to [Open]
    intentAt,         \* the intent's recorded_at
    intentVisibleAt,
    storeState,       \* "none" "pending" "committed" "dropped"
    storeLandAt,
    outcomeState,     \* "absent" "pending" "returned" "visible"
    outcomeIssuedAt,  \* the tick the outcome in flight was issued
    outcomeReplyLost, \* TRUE: its caller never learns it returned
    outcomeReturnAt,
    outcomeVisibleAt,
    outcomeRecords,   \* outcome records that landed or will land
    closingKind,      \* "none" "abandoned" "escalated"
    closingState,     \* "absent" "pending" "returned" "visible"
    closingReturnAt,
    closingVisibleAt,
    closingRecords,
    sweepNextA,
    sweepNextB,
    sweepPhaseA,      \* idle waiting holding prepOutcome prepClosing issued
    sweepPhaseB,
    sweepDeaths,
    pauses,           \* ticks spent by a process between its gate and its write
    opPhase,          \* idle waiting holding prepared issued done
    opKind,           \* none outcome abandoned  — the operator's disposition
    opState,          \* absent pending returned visible
    opReturnAt,
    opVisibleAt,
    opRecords,        \* the operator's closing records
    opSuperseded,     \* how many records those resolutions superseded BY NAME
    opPendingNamed,   \* TRUE: the operator's write in flight names a record
    secondOpened      \* TRUE: a second invocation of this act got past its
                      \* own under-section pre-check while the first's intent
                      \* was still in flight

vars == <<now, fence, invPhase, holder, invExpiry, heldUntil,
          intentState, intentAt, intentReturnAt, intentVisibleAt, storeState, storeLandAt,
          outcomeState, outcomeIssuedAt, outcomeReplyLost, outcomeReturnAt,
          outcomeVisibleAt, outcomeRecords,
          closingKind, closingState, closingReturnAt, closingVisibleAt,
          closingRecords, sweepNextA, sweepNextB, sweepPhaseA, sweepPhaseB,
          sweepDeaths, pauses,
          opPhase, opKind, opState, opReturnAt, opVisibleAt, opRecords,
          opSuperseded, opPendingNamed, secondOpened>>

opVars == <<opPhase, opKind, opState, opReturnAt, opVisibleAt, opRecords,
            opSuperseded, opPendingNamed, secondOpened>>

Horizon == MaxTime + SweepLease + LateLanding + MaxLand

TypeOK ==
    /\ now \in 0..MaxTime
    /\ fence \in BOOLEAN
    /\ invPhase \in {"idle", "reading", "checked", "prepIntent", "issuing", "opened", "committed", "prepared", "closing", "readback", "done", "crashed", "yielded"}
    /\ holder \in {"none", "inv", "A", "B", "op", "sec"}
    /\ invExpiry \in 0..Horizon
    /\ heldUntil \in 0..Horizon
    /\ intentState \in {"absent", "pending", "returned", "visible"}
    /\ intentReturnAt \in 0..Horizon
    /\ intentAt \in 0..Horizon
    /\ intentVisibleAt \in 0..Horizon
    /\ storeState \in {"none", "pending", "committed", "dropped"}
    /\ storeLandAt \in 0..Horizon
    /\ outcomeState \in {"absent", "pending", "returned", "visible"}
    /\ outcomeIssuedAt \in 0..Horizon
    /\ outcomeReplyLost \in BOOLEAN
    /\ outcomeReturnAt \in 0..Horizon
    /\ outcomeVisibleAt \in 0..Horizon
    /\ outcomeRecords \in 0..3
    /\ closingKind \in {"none", "abandoned", "escalated"}
    /\ closingState \in {"absent", "pending", "returned", "visible"}
    /\ closingReturnAt \in 0..Horizon
    /\ closingVisibleAt \in 0..Horizon
    /\ closingRecords \in 0..3
    /\ sweepNextA \in 0..Horizon
    /\ sweepNextB \in 0..Horizon
    /\ sweepPhaseA \in {"idle", "waiting", "holding", "prepOutcome", "prepClosing", "issued"}
    /\ sweepPhaseB \in {"idle", "waiting", "holding", "prepOutcome", "prepClosing", "issued"}
    /\ sweepDeaths \in 0..MaxSweepDeaths
    /\ pauses \in 0..MaxPauses
    /\ opPhase \in {"idle", "waiting", "holding", "prepared", "issued", "done"}
    /\ opKind \in {"none", "outcome", "abandoned"}
    /\ opState \in {"absent", "pending", "returned", "visible"}
    /\ opReturnAt \in 0..Horizon
    /\ opVisibleAt \in 0..Horizon
    /\ opRecords \in 0..MaxResolves
    /\ opSuperseded \in 0..MaxResolves
    /\ opPendingNamed \in BOOLEAN
    /\ secondOpened \in BOOLEAN

Init ==
    /\ now = 0
    /\ fence \in BOOLEAN
    /\ invPhase = "idle"
    /\ holder = "none"
    /\ invExpiry = 0
    /\ heldUntil = 0
    /\ intentState = "absent"
    /\ intentReturnAt = 0
    /\ intentAt = 0
    /\ intentVisibleAt = 0
    /\ storeState = "none"
    /\ storeLandAt = 0
    /\ outcomeState = "absent"
    /\ outcomeIssuedAt = 0
    /\ outcomeReplyLost = FALSE
    /\ outcomeReturnAt = 0
    /\ outcomeVisibleAt = 0
    /\ outcomeRecords = 0
    /\ closingKind = "none"
    /\ closingState = "absent"
    /\ closingReturnAt = 0
    /\ closingVisibleAt = 0
    /\ closingRecords = 0
    /\ sweepNextA = Cadence
    /\ sweepNextB \in 1..Cadence
    /\ sweepPhaseA = "idle"
    /\ sweepPhaseB = "idle"
    /\ sweepDeaths = 0
    /\ pauses = 0
    /\ opPhase = "idle"
    /\ opKind = "none"
    /\ opState = "absent"
    /\ opReturnAt = 0
    /\ opVisibleAt = 0
    /\ opRecords = 0
    /\ opSuperseded = 0
    /\ opPendingNamed = FALSE
    /\ secondOpened = FALSE

\* ---- helpers -------------------------------------------------------------

PhaseOf(s) == IF s = "A" THEN sweepPhaseA ELSE sweepPhaseB
SetPhase(s, ph) ==
    /\ sweepPhaseA' = IF s = "A" THEN ph ELSE sweepPhaseA
    /\ sweepPhaseB' = IF s = "B" THEN ph ELSE sweepPhaseB
NextOf(s) == IF s = "A" THEN sweepNextA ELSE sweepNextB
SetNext(s, t) ==
    /\ sweepNextA' = IF s = "A" THEN t ELSE sweepNextA
    /\ sweepNextB' = IF s = "B" THEN t ELSE sweepNextB
\* Free when nobody holds it, or the holder's lease has run out. The host does
\* not learn of a death; the lease is what ends a hold.
SectionFree == holder = "none" \/ now >= heldUntil

\* The gate every journal write after the first must pass: the holder's
\* remaining lease covers the write bound. NOTE: passing this gate is now a
\* separate step from issuing the write.
InvGateOpen == holder = "inv" /\ now + JournalWriteBound <= invExpiry
SweepGateOpen(s) == holder = s /\ now + JournalWriteBound <= heldUntil

\* What a reader of the journal sees.
OutcomeVisible == outcomeState = "visible"
ClosingVisible == closingState = "visible"
OpVisible == opState = "visible"
Closed == OutcomeVisible \/ ClosingVisible \/ OpVisible

\* A write returns to its caller at r and becomes visible at v, with
\* now < r <= v <= now + JournalWriteBound. Under VisibleOnReturn the two
\* coincide: a returned write is visible to everyone.
\* A write returns at r and becomes visible at v. JournalWriteBound is the
\* deployment's DISCLOSED bound — an SLO with headroom, which the page's own
\* commit_fence doctrine says decides nothing — so the true worst case is
\* MaxLand. What decides whether a late write lands is the next take.
LegalWrite(r, v) ==
    /\ r \in (now + 1)..(now + MaxLand)
    /\ v \in r..(now + MaxLand)
    /\ VisibleOnReturn => v = r


SweepScheduled(s) == now >= NextOf(s) /\ PhaseOf(s) = "idle"
AnySweepScheduled == SweepScheduled("A") \/ SweepScheduled("B")
AnyTakeReady == \E s \in Sweeps : PhaseOf(s) = "waiting" /\ SectionFree
\* A run in `holding` re-reads and probes in one instant (inside run_bound).
AnySweepDeciding == (sweepPhaseA = "holding" /\ holder = "A") \/ (sweepPhaseB = "holding" /\ holder = "B")

\* A process is BETWEEN ITS GATE AND ITS WRITE: it has decided to write and has
\* not yet issued. Time passing here is the pause — the thing v1 could not
\* represent, and the thing the spec's own commit_fence text says nothing
\* bounds. It is budgeted rather than free: a pause is an exceptional event (a
\* stop-the-world collection, a migration), so MaxPauses of them may happen and
\* no more. Left unbudgeted, "pause for ever" is a behaviour of every model
\* without fairness and starves the act at every window — a statement about
\* fairness, not about this protocol.
PreparedPhase(s) == PhaseOf(s) \in {"prepOutcome", "prepClosing"}
Preparing == invPhase \in {"prepared", "reading", "prepIntent"} \/ PreparedPhase("A") \/ PreparedPhase("B") \/ opPhase = "prepared"

\* v7. A TAKE IS A WRITE TO THE GRANT, AND THE STORE REFUSES WHAT IT
\* OVERTAKES. A writer's re-read, lease check and append are one transaction
\* (Execution Contract Database 2), the lease's grant living in the one store with
\* the journal. So a journal write a writer issued and that has not returned,
\* or one it passed its gate for and has not yet issued, is refused when
\* another holder takes the section — the take committed against the grant
\* the write's transaction read — and its writer takes its own arm: the
\* invocation returns its position's arm and leaves the act to the sweep, a
\* sweep run leaves the act for the next run, the operator may call again.
\* Nothing is refused for time alone, and a write that has returned has
\* committed and stays (Execution Contract Database 3).
Late(st) == TakeRefuses /\ st = "pending"
InvOvertaken ==
    /\ TakeRefuses
    /\ \/ invPhase = "prepared"
       \/ (invPhase = "issuing" /\ intentState = "pending")
       \/ (invPhase = "closing" /\ outcomeState = "pending")
SweepOvertaken(s) ==
    /\ TakeRefuses
    /\ \/ PreparedPhase(s)
       \/ (PhaseOf(s) = "issued" /\ (outcomeState = "pending" \/ closingState = "pending"))
OpOvertaken ==
    /\ TakeRefuses
    /\ \/ opPhase = "prepared"
       \/ (opPhase = "issued" /\ opState = "pending")

\* What every take does to the journal's writes in flight and to the
\* invocation it overtakes. The take sets holder, heldUntil and the sweep and
\* operator phases itself.
RefuseOvertaken ==
    /\ intentState' = IF Late(intentState) THEN "absent" ELSE intentState
    /\ intentReturnAt' = IF Late(intentState) THEN 0 ELSE intentReturnAt
    /\ intentVisibleAt' = IF Late(intentState) THEN 0 ELSE intentVisibleAt
    /\ outcomeState' = IF Late(outcomeState) THEN "absent" ELSE outcomeState
    /\ outcomeReturnAt' = IF Late(outcomeState) THEN 0 ELSE outcomeReturnAt
    /\ outcomeVisibleAt' = IF Late(outcomeState) THEN 0 ELSE outcomeVisibleAt
    /\ outcomeRecords' = IF Late(outcomeState) THEN outcomeRecords - 1 ELSE outcomeRecords
    /\ closingState' = IF Late(closingState) THEN "absent" ELSE closingState
    /\ closingReturnAt' = IF Late(closingState) THEN 0 ELSE closingReturnAt
    /\ closingVisibleAt' = IF Late(closingState) THEN 0 ELSE closingVisibleAt
    /\ closingRecords' = IF Late(closingState) THEN closingRecords - 1 ELSE closingRecords
    /\ closingKind' = IF Late(closingState) /\ closingRecords = 1 THEN "none" ELSE closingKind
    /\ opState' = IF Late(opState) THEN "absent" ELSE opState
    /\ opReturnAt' = IF Late(opState) THEN 0 ELSE opReturnAt
    /\ opVisibleAt' = IF Late(opState) THEN 0 ELSE opVisibleAt
    /\ opRecords' = IF Late(opState) THEN opRecords - 1 ELSE opRecords
    /\ opSuperseded' = IF Late(opState) /\ opPendingNamed THEN opSuperseded - 1 ELSE opSuperseded
    /\ opPendingNamed' = IF Late(opState) THEN FALSE ELSE opPendingNamed
    /\ invPhase' = IF InvOvertaken THEN "yielded" ELSE invPhase
OpAfterRefusal == IF opRecords' < MaxResolves THEN "idle" ELSE "done"

\* ---- the invocation -------------------------------------------------------

\* [Open]: take the section, issue the intent. Its return and its visibility
\* are one event here (see MODELING CHOICES).
\* [Open] step 2: TAKE THE SECTION. The lease starts here, and everything
\* below runs inside it.
OpenTake ==
    /\ invPhase = "idle"
    /\ now <= OpenBy
    /\ SectionFree
    /\ holder' = "inv"
    /\ invExpiry' = now + CompletionBound
    /\ heldUntil' = now + CompletionBound
    /\ invPhase' = "reading"
    /\ UNCHANGED <<now, fence, intentState, intentAt, intentReturnAt, intentVisibleAt,
                   storeState, storeLandAt,
                   outcomeState, outcomeReturnAt, outcomeVisibleAt,
                   outcomeRecords, closingKind, closingState, closingReturnAt,
                   closingVisibleAt, closingRecords, sweepNextA, sweepNextB,
                   sweepPhaseA, sweepPhaseB, sweepDeaths, pauses,
                   outcomeIssuedAt, outcomeReplyLost, opPhase, opKind, opState,
                   opReturnAt, opVisibleAt, opRecords, opSuperseded, opPendingNamed, secondOpened>>

\* [Open] step 3: THE UNDER-SECTION PRE-CHECK READ COMPLETES. It is a journal
\* range read and it takes time. The page discloses no bound on it anywhere —
\* JournalWriteBound covers writes, closure_latency covers the sweep — which is
\* ReadBound = CompletionBound here: the read may consume the whole lease.
\* Time passes freely while invPhase = "reading"; this action is the read
\* RETURNING, and its guard is the bound.
OpenRead ==
    /\ invPhase = "reading"
    /\ now <= invExpiry - CompletionBound + ReadBound
    /\ invPhase' = "checked"
    /\ UNCHANGED <<now, fence, holder, invExpiry, heldUntil,
                   intentState, intentAt, intentReturnAt, intentVisibleAt, storeState,
                   storeLandAt, outcomeState, outcomeReturnAt, outcomeVisibleAt,
                   outcomeRecords, closingKind, closingState, closingReturnAt,
                   closingVisibleAt, closingRecords, sweepNextA, sweepNextB,
                   sweepPhaseA, sweepPhaseB, sweepDeaths, pauses,
                   outcomeIssuedAt, outcomeReplyLost, opPhase, opKind, opState,
                   opReturnAt, opVisibleAt, opRecords, opSuperseded, opPendingNamed, secondOpened>>

\* [Open] step 4a: THE GATE. Every other journal write on this page passes
\* `remaining >= journal_write_bound` before it is issued. The page exempts
\* this one — "every journal write AFTER the invocation's first" — which is
\* IntentGated = FALSE, and is the page as written.
PrepareIntent ==
    /\ invPhase = "checked"
    /\ IntentGated => InvGateOpen
    /\ invPhase' = "prepIntent"
    /\ UNCHANGED <<now, fence, holder, invExpiry, heldUntil,
                   intentState, intentAt, intentReturnAt, intentVisibleAt, storeState,
                   storeLandAt, outcomeState, outcomeReturnAt, outcomeVisibleAt,
                   outcomeRecords, closingKind, closingState, closingReturnAt,
                   closingVisibleAt, closingRecords, sweepNextA, sweepNextB,
                   sweepPhaseA, sweepPhaseB, sweepDeaths, pauses,
                   outcomeIssuedAt, outcomeReplyLost, opPhase, opKind, opState,
                   opReturnAt, opVisibleAt, opRecords, opSuperseded, opPendingNamed, secondOpened>>

\* [Open] step 4b: THE INTENT WRITE. Return and visibility are separate
\* instants like every other write — v4 made them one and justified it by the
\* section holding off every racing reader, which the read above refutes.
IssueIntent ==
    /\ invPhase = "prepIntent"
    /\ \E r \in (now + 1)..(now + MaxLand) :
         \E v \in r..(now + MaxLand) :
            /\ LegalWrite(r, v)
            /\ intentReturnAt' = r
            /\ intentVisibleAt' = v
    /\ intentState' = "pending"
    /\ intentAt' = now
    /\ invPhase' = "issuing"
    /\ UNCHANGED <<now, fence, holder, invExpiry, heldUntil,
                   storeState, storeLandAt,
                   outcomeState, outcomeReturnAt, outcomeVisibleAt,
                   outcomeRecords, closingKind, closingState, closingReturnAt,
                   closingVisibleAt, closingRecords, sweepNextA, sweepNextB,
                   sweepPhaseA, sweepPhaseB, sweepDeaths, pauses,
                   outcomeIssuedAt, outcomeReplyLost, opPhase, opKind, opState,
                   opReturnAt, opVisibleAt, opRecords, opSuperseded, opPendingNamed, secondOpened>>

\* [Open] RETURNS TO ITS CALLER. Not when the write is issued — when it has
\* returned. This is what lets the section be released safely later: the page's
\* read-your-writes clause is stated on the record_action's RETURN, so a
\* released section hands the next reader a journal that already shows the
\* intent. v5's first cut set this phase at ISSUE, which let [Yield] free the
\* section with the write in flight — a state the protocol does not admit,
\* since [Yield] is the adopter's `unknown` partition and runs long after
\* [Open] returned.
OpenReturn ==
    /\ invPhase = "issuing"
    /\ intentState \in {"returned", "visible"}
    /\ invPhase' = "opened"
    /\ UNCHANGED <<now, fence, holder, invExpiry, heldUntil,
                   intentState, intentAt, intentReturnAt, intentVisibleAt,
                   storeState, storeLandAt, outcomeState, outcomeReturnAt,
                   outcomeVisibleAt, outcomeRecords, closingKind, closingState,
                   closingReturnAt, closingVisibleAt, closingRecords,
                   sweepNextA, sweepNextB, sweepPhaseA, sweepPhaseB,
                   sweepDeaths, pauses, outcomeIssuedAt, outcomeReplyLost,
                   opPhase, opKind, opState, opReturnAt, opVisibleAt,
                   opRecords, opSuperseded, opPendingNamed, secondOpened>>

\* The lease will not cover the intent write, because the read consumed it.
\* [Open] HAS NO DECLARED ARM FOR THIS STATE — which is itself a prose finding —
\* so the model gives it the only safe behaviour: release, write nothing.
OpenYield ==
    /\ invPhase = "checked"
    /\ IntentGated
    /\ ~InvGateOpen
    /\ invPhase' = "yielded"
    /\ holder' = IF holder = "inv" THEN "none" ELSE holder
    /\ heldUntil' = IF holder = "inv" THEN 0 ELSE heldUntil
    /\ UNCHANGED <<now, fence, invExpiry,
                   intentState, intentAt, intentReturnAt, intentVisibleAt, storeState,
                   storeLandAt, outcomeState, outcomeReturnAt, outcomeVisibleAt,
                   outcomeRecords, closingKind, closingState, closingReturnAt,
                   closingVisibleAt, closingRecords, sweepNextA, sweepNextB,
                   sweepPhaseA, sweepPhaseB, sweepDeaths, pauses,
                   outcomeIssuedAt, outcomeReplyLost, opPhase, opKind, opState,
                   opReturnAt, opVisibleAt, opRecords, opSuperseded, opPendingNamed, secondOpened>>

\* A SECOND INVOCATION of the same act. Modelled as one atomic step, because
\* what matters for the invariant is whether it can get past its own
\* under-section pre-check while the first invocation's intent is still in
\* flight — not what it does afterwards. It takes the section (so it is free),
\* re-reads (so no intent is visible), and appends its own intent. v7: its
\* take is a write to the grant, so the store refuses the first invocation's
\* intent still in flight, and the first [Open] returns with nothing written.
SecondOpen ==
    /\ ServiceIdentity
    /\ ~secondOpened
    /\ SectionFree
    /\ intentState = "pending"       \* not yet visible to its range read
    /\ ~Closed
    /\ secondOpened' = TRUE
    /\ holder' = "sec"
    /\ heldUntil' = now + CompletionBound
    /\ RefuseOvertaken
    /\ sweepPhaseA' = IF SweepOvertaken("A") THEN "idle" ELSE sweepPhaseA
    /\ sweepPhaseB' = IF SweepOvertaken("B") THEN "idle" ELSE sweepPhaseB
    /\ opPhase' = IF OpOvertaken THEN OpAfterRefusal ELSE opPhase
    /\ UNCHANGED <<now, fence, invExpiry, intentAt, storeState, storeLandAt,
                   sweepNextA, sweepNextB, sweepDeaths, pauses,
                   outcomeIssuedAt, outcomeReplyLost, opKind>>

\* The bound commit. Not gated on the lease — a paused process may issue it
\* late — which is why the store-level fence exists.
IssueCommit ==
    /\ invPhase = "opened"
    /\ intentState = "visible"
    /\ storeState = "none"
    /\ invPhase' = "committed"
    /\ \/ /\ fence
          /\ \E d \in 1..StoreLatency :
                IF now + d <= invExpiry
                THEN storeState' = "pending" /\ storeLandAt' = now + d
                ELSE storeState' = "dropped" /\ storeLandAt' = 0
       \/ /\ ~fence
          /\ \E d \in 1..LateLanding :
                storeState' = "pending" /\ storeLandAt' = now + d
    /\ UNCHANGED <<now, fence, holder, invExpiry, heldUntil,
                   intentState, intentAt, intentReturnAt, intentVisibleAt, outcomeState,
                   outcomeReturnAt, outcomeVisibleAt, outcomeRecords,
                   closingKind, closingState, closingReturnAt, closingVisibleAt,
                   closingRecords, sweepNextA, sweepNextB, sweepPhaseA,
                   sweepPhaseB, sweepDeaths, pauses, outcomeIssuedAt, outcomeReplyLost, opPhase, opKind, opState,
                   opReturnAt, opVisibleAt, opRecords, opSuperseded, opPendingNamed, secondOpened>>

\* [Close] steps 1 and 2: the commit landed, the lease covers a write, no
\* outcome is visible — the invocation decides to write. THE WRITE IS NOT
\* ISSUED YET. Time may pass here: this is the pause the spec admits.
PrepareOutcome ==
    /\ invPhase = "committed"
    /\ storeState = "committed"
    /\ InvGateOpen
    /\ ~OutcomeVisible
    /\ outcomeState = "absent"
    /\ invPhase' = "prepared"
    /\ UNCHANGED <<now, fence, holder, invExpiry, heldUntil,
                   intentState, intentAt, intentReturnAt, intentVisibleAt, storeState,
                   storeLandAt, outcomeState, outcomeReturnAt, outcomeVisibleAt,
                   outcomeRecords, closingKind, closingState, closingReturnAt,
                   closingVisibleAt, closingRecords, sweepNextA, sweepNextB,
                   sweepPhaseA, sweepPhaseB, sweepDeaths, pauses, outcomeIssuedAt, outcomeReplyLost, opPhase, opKind, opState,
                   opReturnAt, opVisibleAt, opRecords, opSuperseded, opPendingNamed, secondOpened>>

\* [Close] step 3: the write goes out. The lease is NOT re-checked — nothing
\* re-checks it in the spec either, and a relative gate cannot bind a process
\* that has already passed it.
IssueOutcomeInv ==
    /\ invPhase = "prepared"
    /\ \E r \in (now + 1)..(now + MaxLand) :
         \E v \in r..(now + MaxLand) :
            /\ LegalWrite(r, v)
            /\ outcomeReturnAt' = r
            /\ outcomeVisibleAt' = v
    /\ outcomeState' = "pending"
    /\ outcomeIssuedAt' = now
    /\ outcomeReplyLost' \in BOOLEAN
    /\ outcomeRecords' = outcomeRecords + 1
    /\ invPhase' = "closing"
    /\ UNCHANGED <<now, fence, holder, invExpiry, heldUntil,
                   intentState, intentAt, intentReturnAt, intentVisibleAt, storeState,
                   storeLandAt, closingKind, closingState, closingReturnAt,
                   closingVisibleAt, closingRecords, sweepNextA, sweepNextB,
                   sweepPhaseA, sweepPhaseB, sweepDeaths, pauses, opPhase, opKind, opState,
                   opReturnAt, opVisibleAt, opRecords, opSuperseded, opPendingNamed, secondOpened>>

\* [Close] step 1, the other arm: the lease no longer covers a write. Yield.
Yield ==
    /\ invPhase \in {"opened", "committed"}
    /\ ~InvGateOpen
    /\ invPhase' = "yielded"
    /\ holder' = IF holder = "inv" /\ ~(HoldUnanswered /\ invPhase = "committed" /\ storeState = "pending") THEN "none" ELSE holder
    /\ heldUntil' = IF holder = "inv" /\ ~(HoldUnanswered /\ invPhase = "committed" /\ storeState = "pending") THEN 0 ELSE heldUntil
    /\ UNCHANGED <<now, fence, invExpiry, intentState,
                   intentAt, intentReturnAt, intentVisibleAt, storeState, storeLandAt,
                   outcomeState, outcomeReturnAt, outcomeVisibleAt,
                   outcomeRecords, closingKind, closingState, closingReturnAt,
                   closingVisibleAt, closingRecords, sweepNextA, sweepNextB,
                   sweepPhaseA, sweepPhaseB, sweepDeaths, pauses, outcomeIssuedAt, outcomeReplyLost, opPhase, opKind, opState,
                   opReturnAt, opVisibleAt, opRecords, opSuperseded, opPendingNamed, secondOpened>>

\* Primitive policies 32 through 37b: a `record_action` whose reply is LOST is
\* never issued again. The caller waits out the disclosed bound and reads back;
\* it adopts the record where the read-back finds it and otherwise lands its
\* position's arm, leaving the act to the sweep. A write still in flight can
\* read as absent: nothing is issued twice, and the next take refuses it.
ReadBackDue ==
    /\ invPhase = "closing"
    /\ outcomeReplyLost
    /\ now >= outcomeIssuedAt + JournalWriteBound
    /\ invPhase' = "readback"
    /\ UNCHANGED <<now, fence, holder, invExpiry, heldUntil, intentState,
                   intentAt, intentReturnAt, intentVisibleAt, storeState, storeLandAt,
                   outcomeState, outcomeIssuedAt, outcomeReplyLost,
                   outcomeReturnAt, outcomeVisibleAt, outcomeRecords,
                   closingKind, closingState, closingReturnAt, closingVisibleAt,
                   closingRecords, sweepNextA, sweepNextB, sweepPhaseA,
                   sweepPhaseB, sweepDeaths, pauses, opPhase, opKind, opState,
                   opReturnAt, opVisibleAt, opRecords, opSuperseded, opPendingNamed, secondOpened>>

\* The read-back finds it: adopt, release, return.
ReadBackFound ==
    /\ invPhase = "readback"
    /\ outcomeState = "visible"
    /\ invPhase' = "done"
    /\ holder' = IF holder = "inv" /\ ~HoldUnanswered THEN "none" ELSE holder
    /\ heldUntil' = IF holder = "inv" /\ ~HoldUnanswered THEN 0 ELSE heldUntil
    /\ UNCHANGED <<now, fence, invExpiry, intentState, intentAt,
                   intentReturnAt, intentVisibleAt, storeState, storeLandAt, outcomeState,
                   outcomeIssuedAt, outcomeReplyLost, outcomeReturnAt,
                   outcomeVisibleAt, outcomeRecords, closingKind, closingState,
                   closingReturnAt, closingVisibleAt, closingRecords,
                   sweepNextA, sweepNextB, sweepPhaseA, sweepPhaseB,
                   sweepDeaths, pauses, opPhase, opKind, opState,
                   opReturnAt, opVisibleAt, opRecords, opSuperseded, opPendingNamed, secondOpened>>

\* v6. The read-back does not find it and the write is NOT issued again: a call
\* that answered no answer is never re-issued under one lease (Lease Sizing 8).
\* The act is the sweep's, and the grant runs to its instant.
ReadBackGiveUp ==
    /\ invPhase = "readback"
    /\ outcomeState /= "visible"
    /\ invPhase' = "yielded"
    /\ holder' = IF holder = "inv" /\ ~HoldUnanswered THEN "none" ELSE holder
    /\ heldUntil' = IF holder = "inv" /\ ~HoldUnanswered THEN 0 ELSE heldUntil
    /\ UNCHANGED <<now, fence, invExpiry, intentState, intentAt,
                   intentReturnAt, intentVisibleAt, storeState, storeLandAt, outcomeState,
                   outcomeIssuedAt, outcomeReplyLost, outcomeReturnAt,
                   outcomeVisibleAt, outcomeRecords, closingKind, closingState,
                   closingReturnAt, closingVisibleAt, closingRecords,
                   sweepNextA, sweepNextB, sweepPhaseA, sweepPhaseB,
                   sweepDeaths, pauses, opPhase, opKind, opState,
                   opReturnAt, opVisibleAt, opRecords, opSuperseded, opPendingNamed, secondOpened>>

\* [Close] step 4: the write RETURNED. Release and return — not "the write is
\* visible": nothing tells the caller that.
\* v7: no write is issued twice, so the invocation that reaches here had its
\* one outcome answered and has no call in flight.
FinishInv ==
    /\ invPhase = "closing"
    /\ ~outcomeReplyLost
    /\ outcomeState \in {"returned", "visible"}
    /\ invPhase' = "done"
    /\ holder' = IF holder = "inv" THEN "none" ELSE holder
    /\ heldUntil' = IF holder = "inv" THEN 0 ELSE heldUntil
    /\ UNCHANGED <<now, fence, invExpiry, intentState,
                   intentAt, intentReturnAt, intentVisibleAt, storeState, storeLandAt,
                   outcomeState, outcomeReturnAt, outcomeVisibleAt,
                   outcomeRecords, closingKind, closingState, closingReturnAt,
                   closingVisibleAt, closingRecords, sweepNextA, sweepNextB,
                   sweepPhaseA, sweepPhaseB, sweepDeaths, pauses, outcomeIssuedAt, outcomeReplyLost, opPhase, opKind, opState,
                   opReturnAt, opVisibleAt, opRecords, opSuperseded, opPendingNamed, secondOpened>>

\* The process dies. A write already issued still lands, unless a take refuses
\* it first. The host does not see the death: the lease runs out.
Crash ==
    /\ invPhase \in {"issuing", "opened", "committed", "prepared", "closing", "readback"}
    /\ invPhase' = "crashed"
    /\ UNCHANGED <<now, fence, holder, invExpiry, heldUntil,
                   intentState, intentAt, intentReturnAt, intentVisibleAt, storeState,
                   storeLandAt, outcomeState, outcomeReturnAt, outcomeVisibleAt,
                   outcomeRecords, closingKind, closingState, closingReturnAt,
                   closingVisibleAt, closingRecords, sweepNextA, sweepNextB,
                   sweepPhaseA, sweepPhaseB, sweepDeaths, pauses, outcomeIssuedAt, outcomeReplyLost, opPhase, opKind, opState,
                   opReturnAt, opVisibleAt, opRecords, opSuperseded, opPendingNamed, secondOpened>>

\* ---- the sweep ------------------------------------------------------------

\* [Reconcile] step 1: enumerate past the lower edge, nothing closed.
SweepDue(s) ==
    /\ SweepScheduled(s)
    /\ intentState = "visible"
    /\ now >= intentAt + CompletionBound
    /\ ~Closed

\* The run selects the act and calls the blocking take; time passes while it
\* waits (bounded by the holder's remaining lease — the section frees itself).
SweepSelect(s) ==
    /\ SweepDue(s)
    /\ SetPhase(s, "waiting")
    /\ SetNext(s, now + Cadence)
    /\ UNCHANGED <<now, fence, invPhase, holder, invExpiry, heldUntil,
                   intentState, intentAt, intentReturnAt, intentVisibleAt, storeState,
                   storeLandAt, outcomeState, outcomeReturnAt, outcomeVisibleAt,
                   outcomeRecords, closingKind, closingState, closingReturnAt,
                   closingVisibleAt, closingRecords, sweepDeaths, pauses, outcomeIssuedAt, outcomeReplyLost, opPhase, opKind, opState,
                   opReturnAt, opVisibleAt, opRecords, opSuperseded, opPendingNamed, secondOpened>>

\* The take succeeds. The run's lease is SweepLease, not the act's bound. v7:
\* the take refuses every journal write it overtakes (RefuseOvertaken).
SweepTake(s) ==
    /\ PhaseOf(s) = "waiting"
    /\ SectionFree
    /\ holder' = s
    /\ heldUntil' = now + SweepLease
    /\ RefuseOvertaken
    /\ sweepPhaseA' = IF s = "A" THEN "holding"
                      ELSE IF SweepOvertaken("A") THEN "idle" ELSE sweepPhaseA
    /\ sweepPhaseB' = IF s = "B" THEN "holding"
                      ELSE IF SweepOvertaken("B") THEN "idle" ELSE sweepPhaseB
    /\ opPhase' = IF OpOvertaken THEN OpAfterRefusal ELSE opPhase
    /\ UNCHANGED <<now, fence, invExpiry, intentAt, storeState, storeLandAt,
                   sweepNextA, sweepNextB, sweepDeaths, pauses,
                   outcomeIssuedAt, outcomeReplyLost, opKind, secondOpened>>

\* [Reconcile] step 2: the re-read under the section finds a visible closing.
\* Nothing to do; release.
SweepSeen(s) ==
    /\ PhaseOf(s) = "holding"
    /\ holder = s
    /\ Closed
    /\ SetPhase(s, "idle")
    /\ holder' = "none"
    /\ heldUntil' = 0
    /\ UNCHANGED <<now, fence, invPhase, invExpiry,
                   intentState, intentAt, intentReturnAt, intentVisibleAt, storeState,
                   storeLandAt, outcomeState, outcomeReturnAt, outcomeVisibleAt,
                   outcomeRecords, closingKind, closingState, closingReturnAt,
                   closingVisibleAt, closingRecords, sweepNextA, sweepNextB,
                   sweepDeaths, pauses, outcomeIssuedAt, outcomeReplyLost, opPhase, opKind, opState,
                   opReturnAt, opVisibleAt, opRecords, opSuperseded, opPendingNamed, secondOpened>>

\* The lease will not cover a write: write nothing, leave it for the next run.
SweepYield(s) ==
    /\ PhaseOf(s) = "holding"
    /\ holder = s
    /\ ~Closed
    /\ ~SweepGateOpen(s)
    /\ SetPhase(s, "idle")
    /\ holder' = "none"
    /\ heldUntil' = 0
    /\ UNCHANGED <<now, fence, invPhase, invExpiry,
                   intentState, intentAt, intentReturnAt, intentVisibleAt, storeState,
                   storeLandAt, outcomeState, outcomeReturnAt, outcomeVisibleAt,
                   outcomeRecords, closingKind, closingState, closingReturnAt,
                   closingVisibleAt, closingRecords, sweepNextA, sweepNextB,
                   sweepDeaths, pauses, outcomeIssuedAt, outcomeReplyLost, opPhase, opKind, opState,
                   opReturnAt, opVisibleAt, opRecords, opSuperseded, opPendingNamed, secondOpened>>

\* The probe answers committed: the run decides on the outcome record.
SweepPrepareOutcome(s) ==
    /\ PhaseOf(s) = "holding"
    /\ holder = s
    /\ ~Closed
    /\ SweepGateOpen(s)
    /\ ServiceIdentity
    /\ storeState = "committed"
    /\ SetPhase(s, "prepOutcome")
    /\ UNCHANGED <<now, fence, invPhase, holder, invExpiry, heldUntil,
                   intentState, intentAt, intentReturnAt, intentVisibleAt, storeState,
                   storeLandAt, outcomeState, outcomeReturnAt, outcomeVisibleAt,
                   outcomeRecords, closingKind, closingState, closingReturnAt,
                   closingVisibleAt, closingRecords, sweepNextA, sweepNextB,
                   sweepDeaths, pauses, opPhase, opKind, opState,
                   opReturnAt, opVisibleAt, opRecords, opSuperseded, opPendingNamed, secondOpened>>

\* The probe answers not-committed: abandoned under a fence, escalated without.
SweepPrepareClosing(s) ==
    /\ PhaseOf(s) = "holding"
    /\ holder = s
    /\ ~Closed
    /\ SweepGateOpen(s)
    /\ ServiceIdentity
    /\ storeState \in {"none", "pending", "dropped"}
    /\ SetPhase(s, "prepClosing")
    /\ UNCHANGED <<now, fence, invPhase, holder, invExpiry, heldUntil,
                   intentState, intentAt, intentReturnAt, intentVisibleAt, storeState,
                   storeLandAt, outcomeState, outcomeReturnAt, outcomeVisibleAt,
                   outcomeRecords, closingKind, closingState, closingReturnAt,
                   closingVisibleAt, closingRecords, sweepNextA, sweepNextB,
                   sweepDeaths, pauses, opPhase, opKind, opState,
                   opReturnAt, opVisibleAt, opRecords, opSuperseded, opPendingNamed, secondOpened>>

SweepIssueOutcome(s) ==
    /\ PhaseOf(s) = "prepOutcome"
    /\ \E r \in (now + 1)..(now + JournalWriteBound) :
         \E v \in r..(now + JournalWriteBound) :
            /\ LegalWrite(r, v)
            /\ outcomeReturnAt' = r
            /\ outcomeVisibleAt' = v
    /\ outcomeState' = "pending"
    /\ outcomeIssuedAt' = now
    /\ outcomeReplyLost' = FALSE
    /\ outcomeRecords' = outcomeRecords + 1
    /\ SetPhase(s, "issued")
    /\ UNCHANGED <<now, fence, invPhase, holder, invExpiry, heldUntil,
                   intentState, intentAt, intentReturnAt, intentVisibleAt, storeState,
                   storeLandAt, closingKind, closingState, closingReturnAt,
                   closingVisibleAt, closingRecords, sweepNextA, sweepNextB,
                   sweepDeaths, pauses, opPhase, opKind, opState,
                   opReturnAt, opVisibleAt, opRecords, opSuperseded, opPendingNamed, secondOpened>>

SweepIssueClosing(s) ==
    /\ PhaseOf(s) = "prepClosing"
    /\ \E r \in (now + 1)..(now + JournalWriteBound) :
         \E v \in r..(now + JournalWriteBound) :
            /\ LegalWrite(r, v)
            /\ closingReturnAt' = r
            /\ closingVisibleAt' = v
    /\ closingKind' = IF fence THEN "abandoned" ELSE "escalated"
    /\ closingState' = "pending"
    /\ closingRecords' = closingRecords + 1
    /\ SetPhase(s, "issued")
    /\ UNCHANGED <<now, fence, invPhase, holder, invExpiry, heldUntil,
                   intentState, intentAt, intentReturnAt, intentVisibleAt, storeState,
                   storeLandAt, outcomeState, outcomeReturnAt, outcomeVisibleAt,
                   outcomeRecords, sweepNextA, sweepNextB, sweepDeaths, pauses, outcomeIssuedAt, outcomeReplyLost, opPhase, opKind, opState,
                   opReturnAt, opVisibleAt, opRecords, opSuperseded, opPendingNamed, secondOpened>>

\* The run's write RETURNED: release and return. Not "became visible" — the
\* spec releases on the holder's return.
SweepReturn(s) ==
    /\ PhaseOf(s) = "issued"
    /\ \/ outcomeState \in {"returned", "visible"}
       \/ closingState \in {"returned", "visible"}
    /\ SetPhase(s, "idle")
    /\ holder' = IF holder = s THEN "none" ELSE holder
    /\ heldUntil' = IF holder = s THEN 0 ELSE heldUntil
    /\ UNCHANGED <<now, fence, invPhase, invExpiry,
                   intentState, intentAt, intentReturnAt, intentVisibleAt, storeState,
                   storeLandAt, outcomeState, outcomeReturnAt, outcomeVisibleAt,
                   outcomeRecords, closingKind, closingState, closingReturnAt,
                   closingVisibleAt, closingRecords, sweepNextA, sweepNextB,
                   sweepDeaths, pauses, outcomeIssuedAt, outcomeReplyLost, opPhase, opKind, opState,
                   opReturnAt, opVisibleAt, opRecords, opSuperseded, opPendingNamed, secondOpened>>

\* A run dies. Its pending write still lands unless a take refuses it first;
\* its lease runs out.
SweepCrash(s) ==
    /\ PhaseOf(s) \in {"waiting", "holding", "prepOutcome", "prepClosing", "issued"}
    /\ sweepDeaths < MaxSweepDeaths
    /\ sweepDeaths' = sweepDeaths + 1
    /\ SetPhase(s, "idle")
    /\ UNCHANGED <<now, fence, invPhase, holder, invExpiry, heldUntil,
                   intentState, intentAt, intentReturnAt, intentVisibleAt, storeState,
                   storeLandAt, outcomeState, outcomeReturnAt, outcomeVisibleAt,
                   outcomeRecords, closingKind, closingState, closingReturnAt,
                   closingVisibleAt, closingRecords, sweepNextA, sweepNextB, pauses, outcomeIssuedAt, outcomeReplyLost, opPhase, opKind, opState,
                   opReturnAt, opVisibleAt, opRecords, opSuperseded, opPendingNamed, secondOpened>>

\* A scheduled run with nothing to examine reschedules.
SweepSkip(s) ==
    /\ SweepScheduled(s)
    /\ ~SweepDue(s)
    /\ SetNext(s, now + Cadence)
    /\ UNCHANGED <<now, fence, invPhase, holder, invExpiry, heldUntil,
                   intentState, intentAt, intentReturnAt, intentVisibleAt, storeState,
                   storeLandAt, outcomeState, outcomeReturnAt, outcomeVisibleAt,
                   outcomeRecords, closingKind, closingState, closingReturnAt,
                   closingVisibleAt, closingRecords, sweepPhaseA, sweepPhaseB,
                   sweepDeaths, pauses, outcomeIssuedAt, outcomeReplyLost, opPhase, opKind, opState,
                   opReturnAt, opVisibleAt, opRecords, opSuperseded, opPendingNamed, secondOpened>>


\* ---- the operator: [Resolve] ----------------------------------------------

\* THE OPERATOR'S OWN READING. Every other reading on this page is injected at
\* a seam and compared under one allowance; the page enumerates its clocks
\* exhaustively, twice, and [Resolve] is at none of them — yet its too-young
\* guard compares a present reading against the substrate's `recorded_at`.
\* OperatorSkew is how far that reading may run ahead of the true instant: 0 is
\* a declared operator seam, and anything more is the page as written, where
\* the only way to close the step is a clock read inside the action.
\* The existential is the adversary: the reading may be ANY value in the range,
\* so the protocol must be safe for all of them.
OpReadings == now..(now + OperatorSkew)

OpGateOpen == holder = "op" /\ now + JournalWriteBound <= heldUntil

\* Whether the record this resolution writes NAMES the record it closes over.
\* The page requires `supersedes` over an abandonment. Over an ESCALATION it
\* requires only `resolved_by` — which names the operator and not a record, so
\* the precedence rule and the acceptance check have no referent. That is
\* SupersedesNamed = FALSE, and it is the page as written (gate 9, F6).
OpWouldName ==
    IF ~(ClosingVisible \/ OutcomeVisible) THEN FALSE
    ELSE IF closingKind = "abandoned" THEN TRUE
    ELSE SupersedesNamed

\* There is something for an operator to do. Two arms, and which is available
\* is a property of the deployment, not a budget: an escalation they have
\* investigated (any deployment), or — ONLY where the sweep writes nothing,
\* `service_identity = none` — an open intent past the edge on their own
\* reading. In a deployment whose sweep closes acts, an operator does not race
\* it to an open intent; they resolve what it escalated. Keeping the second arm
\* available everywhere is both unfaithful and the reason v4's first cut did not
\* terminate: the operator then interleaves with both sweeps across most of the
\* reachable space.
OpDue ==
    /\ opPhase = "idle"
    /\ opRecords < MaxResolves
    /\ intentState = "visible"
    /\ \/ (ClosingVisible /\ closingKind = "escalated")
       \/ (~ServiceIdentity /\ ~Closed
           /\ \E r \in OpReadings : r >= intentAt + CompletionBound)

OpSelect ==
    /\ OpDue
    /\ opPhase' = "waiting"
    /\ UNCHANGED <<now, fence, invPhase, holder, invExpiry, heldUntil,
                   intentState, intentAt, intentReturnAt, intentVisibleAt, storeState,
                   storeLandAt, outcomeState, outcomeIssuedAt, outcomeReplyLost,
                   outcomeReturnAt, outcomeVisibleAt, outcomeRecords,
                   closingKind, closingState, closingReturnAt, closingVisibleAt,
                   closingRecords, sweepNextA, sweepNextB, sweepPhaseA,
                   sweepPhaseB, sweepDeaths, pauses,
                   opKind, opState, opReturnAt, opVisibleAt, opRecords, opSuperseded, opPendingNamed, secondOpened>>

\* [Resolve] takes the SAME section on the same key, for the same reason — it
\* is a writer like the others and is serialized like the others. v7: the take
\* refuses every journal write it overtakes (RefuseOvertaken).
OpTake ==
    /\ opPhase = "waiting"
    /\ SectionFree
    /\ holder' = "op"
    /\ heldUntil' = now + SweepLease
    /\ RefuseOvertaken
    /\ opPhase' = "holding"
    /\ sweepPhaseA' = IF SweepOvertaken("A") THEN "idle" ELSE sweepPhaseA
    /\ sweepPhaseB' = IF SweepOvertaken("B") THEN "idle" ELSE sweepPhaseB
    /\ UNCHANGED <<now, fence, invExpiry, intentAt, storeState, storeLandAt,
                   sweepNextA, sweepNextB, sweepDeaths, pauses,
                   outcomeIssuedAt, outcomeReplyLost, opKind, secondOpened>>

\* The re-read under the section finds an outcome: nothing left to resolve.
OpSeen ==
    /\ opPhase = "holding"
    /\ holder = "op"
    /\ OutcomeVisible
    /\ opPhase' = "done"
    /\ holder' = "none"
    /\ heldUntil' = 0
    /\ UNCHANGED <<now, fence, invPhase, invExpiry,
                   intentState, intentAt, intentReturnAt, intentVisibleAt, storeState,
                   storeLandAt, outcomeState, outcomeIssuedAt, outcomeReplyLost,
                   outcomeReturnAt, outcomeVisibleAt, outcomeRecords,
                   closingKind, closingState, closingReturnAt, closingVisibleAt,
                   closingRecords, sweepNextA, sweepNextB, sweepPhaseA,
                   sweepPhaseB, sweepDeaths, pauses,
                   opKind, opState, opReturnAt, opVisibleAt, opRecords, opSuperseded, opPendingNamed, secondOpened>>

\* The lease will not cover the write: [Resolve] gates on `remaining` as
\* [Close] does, and writes nothing.
OpYield ==
    /\ opPhase = "holding"
    /\ holder = "op"
    /\ ~OutcomeVisible
    /\ ~OpGateOpen
    /\ opPhase' = "done"
    /\ holder' = "none"
    /\ heldUntil' = 0
    /\ UNCHANGED <<now, fence, invPhase, invExpiry,
                   intentState, intentAt, intentReturnAt, intentVisibleAt, storeState,
                   storeLandAt, outcomeState, outcomeIssuedAt, outcomeReplyLost,
                   outcomeReturnAt, outcomeVisibleAt, outcomeRecords,
                   closingKind, closingState, closingReturnAt, closingVisibleAt,
                   closingRecords, sweepNextA, sweepNextB, sweepPhaseA,
                   sweepPhaseB, sweepDeaths, pauses,
                   opKind, opState, opReturnAt, opVisibleAt, opRecords, opSuperseded, opPendingNamed, secondOpened>>

\* The operator ran the probe themselves and it says the act happened: they
\* write the closing the sweep could not, over whatever record stands.
OpPrepareOutcome ==
    /\ opPhase = "holding"
    /\ holder = "op"
    /\ ~OutcomeVisible
    /\ OpGateOpen
    /\ storeState = "committed"
    /\ opKind' = "outcome"
    /\ opPhase' = "prepared"
    /\ UNCHANGED <<now, fence, invPhase, holder, invExpiry, heldUntil,
                   intentState, intentAt, intentReturnAt, intentVisibleAt, storeState,
                   storeLandAt, outcomeState, outcomeIssuedAt, outcomeReplyLost,
                   outcomeReturnAt, outcomeVisibleAt, outcomeRecords,
                   closingKind, closingState, closingReturnAt, closingVisibleAt,
                   closingRecords, sweepNextA, sweepNextB, sweepPhaseA,
                   sweepPhaseB, sweepDeaths, pauses,
                   opState, opReturnAt, opVisibleAt, opRecords, opSuperseded, opPendingNamed, secondOpened>>

\* The operator attests the act did not happen. The page gates this on the
\* intent being older than the edge — compared against THE OPERATOR'S OWN
\* READING, which is the whole of gate 9's F7.
OpPrepareAbandon ==
    /\ opPhase = "holding"
    /\ holder = "op"
    /\ ~OutcomeVisible
    /\ OpGateOpen
    /\ fence
    /\ storeState \in {"none", "pending", "dropped"}
    /\ \E r \in OpReadings : r >= intentAt + CompletionBound
    /\ opKind' = "abandoned"
    /\ opPhase' = "prepared"
    /\ UNCHANGED <<now, fence, invPhase, holder, invExpiry, heldUntil,
                   intentState, intentAt, intentReturnAt, intentVisibleAt, storeState,
                   storeLandAt, outcomeState, outcomeIssuedAt, outcomeReplyLost,
                   outcomeReturnAt, outcomeVisibleAt, outcomeRecords,
                   closingKind, closingState, closingReturnAt, closingVisibleAt,
                   closingRecords, sweepNextA, sweepNextB, sweepPhaseA,
                   sweepPhaseB, sweepDeaths, pauses,
                   opState, opReturnAt, opVisibleAt, opRecords, opSuperseded, opPendingNamed, secondOpened>>

OpIssue ==
    /\ opPhase = "prepared"
    /\ \E r \in (now + 1)..(now + JournalWriteBound) :
         \E v \in r..(now + JournalWriteBound) :
            /\ LegalWrite(r, v)
            /\ opReturnAt' = r
            /\ opVisibleAt' = v
    /\ opState' = "pending"
    /\ opRecords' = opRecords + 1
    /\ opSuperseded' = opSuperseded + (IF OpWouldName THEN 1 ELSE 0)
    /\ opPendingNamed' = OpWouldName
    /\ opPhase' = "issued"
    /\ UNCHANGED <<now, fence, invPhase, holder, invExpiry, heldUntil,
                   intentState, intentAt, intentReturnAt, intentVisibleAt, storeState,
                   storeLandAt, outcomeState, outcomeIssuedAt, outcomeReplyLost,
                   outcomeReturnAt, outcomeVisibleAt, outcomeRecords,
                   closingKind, closingState, closingReturnAt, closingVisibleAt,
                   closingRecords, sweepNextA, sweepNextB, sweepPhaseA,
                   sweepPhaseB, sweepDeaths, pauses, opKind, secondOpened>>

\* The write RETURNED: release. Not "became visible" — the page releases on the
\* holder's return, which is the handoff the read-your-writes clause covers.
OpReturn ==
    /\ opPhase = "issued"
    /\ opState \in {"returned", "visible"}
    \* THE OPERATOR RE-ARMS. An operator who resolves an act may be called
    \* again on it — that is how a false abandonment is corrected, and it is
    \* the page's own section check 6 path. v5's first cut left this phase terminal,
    \* so MaxResolves was never the binding constraint and raising it changed
    \* nothing: the SWITCH THAT WAS OFF WAS A PHASE, NOT THE CONSTANT NAMED IN
    \* THE CONFIGURATION. The chain probe is what found that, by holding twice.
    /\ opPhase' = IF opRecords < MaxResolves THEN "idle" ELSE "done"
    /\ holder' = IF holder = "op" THEN "none" ELSE holder
    /\ heldUntil' = IF holder = "op" THEN 0 ELSE heldUntil
    /\ UNCHANGED <<now, fence, invPhase, invExpiry,
                   intentState, intentAt, intentReturnAt, intentVisibleAt, storeState,
                   storeLandAt, outcomeState, outcomeIssuedAt, outcomeReplyLost,
                   outcomeReturnAt, outcomeVisibleAt, outcomeRecords,
                   closingKind, closingState, closingReturnAt, closingVisibleAt,
                   closingRecords, sweepNextA, sweepNextB, sweepPhaseA,
                   sweepPhaseB, sweepDeaths, pauses,
                   opKind, opState, opReturnAt, opVisibleAt, opRecords, opSuperseded, opPendingNamed, secondOpened>>

\* ---- time -----------------------------------------------------------------

\* Writes return and become visible at their ticks. Time does not advance past
\* a scheduled run, a take that can succeed, or a run's re-read and probe. It
\* DOES advance between a prepare and its issue: that is the pause.
NextIntent == IF intentState = "pending" /\ intentReturnAt = now + 1
              THEN (IF intentVisibleAt = now + 1 THEN "visible" ELSE "returned")
              ELSE IF intentState \in {"pending", "returned"} /\ intentVisibleAt = now + 1
              THEN "visible" ELSE intentState
AfterIntentRet == IF intentState = "pending" /\ intentReturnAt = now + 1
                  THEN 0 ELSE intentReturnAt
AfterIntentVis == IF intentState \in {"pending", "returned"} /\ intentVisibleAt = now + 1
                  THEN 0 ELSE intentVisibleAt
NextStore == IF storeState = "pending" /\ storeLandAt = now + 1
             THEN "committed" ELSE storeState
AfterStoreLand == IF storeState = "pending" /\ storeLandAt = now + 1
                  THEN 0 ELSE storeLandAt
AfterOutcomeRet == IF outcomeState = "pending" /\ outcomeReturnAt = now + 1
                   THEN 0 ELSE outcomeReturnAt
AfterOutcomeVis == IF outcomeState \in {"pending", "returned"} /\ outcomeVisibleAt = now + 1
                   THEN 0 ELSE outcomeVisibleAt
AfterClosingRet == IF closingState = "pending" /\ closingReturnAt = now + 1
                   THEN 0 ELSE closingReturnAt
AfterClosingVis == IF closingState \in {"pending", "returned"} /\ closingVisibleAt = now + 1
                   THEN 0 ELSE closingVisibleAt
NextOutcome == IF outcomeState = "pending" /\ outcomeReturnAt = now + 1
               THEN (IF outcomeVisibleAt = now + 1 THEN "visible" ELSE "returned")
               ELSE IF outcomeState = "returned" /\ outcomeVisibleAt = now + 1
               THEN "visible" ELSE outcomeState
AfterOpRet == IF opState = "pending" /\ opReturnAt = now + 1
              THEN 0 ELSE opReturnAt
AfterOpVis == IF opState \in {"pending", "returned"} /\ opVisibleAt = now + 1
              THEN 0 ELSE opVisibleAt
NextOp == IF opState = "pending" /\ opReturnAt = now + 1
          THEN (IF opVisibleAt = now + 1 THEN "visible" ELSE "returned")
          ELSE IF opState \in {"pending", "returned"} /\ opVisibleAt = now + 1
          THEN "visible" ELSE opState

NextClosing == IF closingState = "pending" /\ closingReturnAt = now + 1
               THEN (IF closingVisibleAt = now + 1 THEN "visible" ELSE "returned")
               ELSE IF closingState = "returned" /\ closingVisibleAt = now + 1
               THEN "visible" ELSE closingState

Tick ==
    /\ now < MaxTime
    /\ ~AnySweepScheduled
    /\ ~AnyTakeReady
    /\ ~AnySweepDeciding
    /\ ~(opPhase = "waiting" /\ SectionFree)
    /\ ~(opPhase = "holding" /\ holder = "op")
    /\ IF Preparing THEN pauses < MaxPauses /\ pauses' = pauses + 1
                     ELSE pauses' = pauses
    /\ now' = now + 1
    /\ intentState' = NextIntent
    /\ storeState' = NextStore
    /\ outcomeState' = NextOutcome
    /\ closingState' = NextClosing
    /\ intentReturnAt' = AfterIntentRet
    /\ intentVisibleAt' = AfterIntentVis
    /\ storeLandAt' = AfterStoreLand
    /\ outcomeReturnAt' = AfterOutcomeRet
    /\ outcomeVisibleAt' = AfterOutcomeVis
    /\ closingReturnAt' = AfterClosingRet
    /\ closingVisibleAt' = AfterClosingVis
    /\ opState' = NextOp
    /\ opReturnAt' = AfterOpRet
    /\ opVisibleAt' = AfterOpVis
    /\ UNCHANGED <<fence, invPhase, holder, invExpiry, heldUntil,
                   intentAt, outcomeIssuedAt, outcomeReplyLost,
                   outcomeRecords, closingKind, closingRecords,
                   sweepNextA, sweepNextB, sweepPhaseA, sweepPhaseB,
                   sweepDeaths, opPhase, opKind, opRecords, opSuperseded, opPendingNamed, secondOpened>>

Next ==
    \/ OpenTake
    \/ OpenRead
    \/ PrepareIntent
    \/ IssueIntent
    \/ OpenReturn
    \/ OpenYield
    \/ SecondOpen
    \/ IssueCommit
    \/ PrepareOutcome
    \/ IssueOutcomeInv
    \/ Yield
    \/ ReadBackDue
    \/ ReadBackFound
    \/ ReadBackGiveUp
    \/ FinishInv
    \/ Crash
    \/ \E s \in Sweeps : SweepSelect(s)
    \/ \E s \in Sweeps : SweepTake(s)
    \/ \E s \in Sweeps : SweepSeen(s)
    \/ \E s \in Sweeps : SweepYield(s)
    \/ \E s \in Sweeps : SweepPrepareOutcome(s)
    \/ \E s \in Sweeps : SweepPrepareClosing(s)
    \/ \E s \in Sweeps : SweepIssueOutcome(s)
    \/ \E s \in Sweeps : SweepIssueClosing(s)
    \/ \E s \in Sweeps : SweepReturn(s)
    \/ \E s \in Sweeps : SweepCrash(s)
    \/ \E s \in Sweeps : SweepSkip(s)
    \/ OpSelect
    \/ OpTake
    \/ OpSeen
    \/ OpYield
    \/ OpPrepareOutcome
    \/ OpPrepareAbandon
    \/ OpIssue
    \/ OpReturn
    \/ Tick

Spec == Init /\ [][Next]_vars

\* ---- invariants -----------------------------------------------------------

Inv1_IntentFirst ==
    (storeState /= "none") => intentState = "visible"

\* Supersession is counted TRANSITIVELY: the standing closing is the one no
\* other closing names, and everything reachable through `supersedes` counts
\* with it as one. Gate 10's F5 is that the page's rules are stated over PAIRS,
\* so a chain — an escalation superseded by an abandonment superseded by an
\* outcome — double-counts its middle record and leaves two standing. A chain
\* needs two resolutions, which MaxResolves = 1 had switched off.
ClosingCount == outcomeRecords + closingRecords + opRecords - opSuperseded

Inv2_OneWriter ==
    /\ outcomeRecords <= 1
    /\ ClosingCount <= 1

Inv4_BoundedClosure ==
    (/\ intentState = "visible"
     /\ invPhase \in {"crashed", "yielded"}
     /\ now >= intentAt + Window)
    => Closed

Inv5_NoFalseAbandon ==
    /\ (closingKind = "abandoned") => storeState \in {"none", "dropped"}
    /\ (opKind = "abandoned" /\ opRecords > 0)
         => storeState \in {"none", "dropped"}

\* Gate 9, F6. A resolution written over an existing closing must NAME it:
\* without the name the precedence rule and Generation acceptance check 2 have
\* no referent, and both read a lawful resolution as a duplicate.
Inv6_SupersessionNamed ==
    (opRecords > 0 /\ closingRecords + outcomeRecords > 0) => opSuperseded > 0

\* Gate 10, F6, stated DIRECTLY. An intent must never be in flight under
\* another holder's grant: the next [Open] reads a journal that does not show
\* it. Until v6 this read "while its own invocation no longer holds the
\* section", its instant included, and the journal fence earned it. v7: the
\* store's refusal earns it, and an intent in flight past its own instant, or
\* after a release, with no taker harms nothing — it lands beside no other
\* writer's record.
Inv8_IntentUnderItsSection ==
    ~(intentState = "pending" /\ holder \notin {"inv", "none"})

\* Gate 10, F6. Under a declared service identity [Open] refuses any open
\* intent, so at most one invocation of an act is ever between its intent and
\* its closing. A second one getting past its own pre-check means two live
\* intents on one act_key, which degrades `probe` to undecidable for both and
\* which no rule of the page could then end. v7: the second invocation's take
\* refuses the first's intent still in flight, so a second invocation past its
\* pre-check leaves no first intent to land beside its own.
Inv7_OneLiveIntent == ServiceIdentity => ~(secondOpened /\ intentState /= "absent")

Safety == TypeOK /\ Inv1_IntentFirst /\ Inv2_OneWriter /\ Inv4_BoundedClosure
          /\ Inv5_NoFalseAbandon /\ Inv6_SupersessionNamed
          /\ Inv7_OneLiveIntent /\ Inv8_IntentUnderItsSection

\* ---- reachability probes --------------------------------------------------
\* Each of these is a DELIBERATE FALSEHOOD, and the checker must REJECT it.
\* They exist because this model has already been caught holding an invariant
\* whose antecedent could not fire inside the horizon (Inv4, above), and
\* "all invariants hold" is worth nothing for a behaviour the configuration
\* cannot reach. A new component earns its invariants only after its probe
\* fails. Run with --buggy: a violation is the pass.
Probe_OperatorNeverWrites == opRecords = 0
Probe_OperatorNeverSupersedes ==
    ~(opRecords > 0 /\ closingRecords + outcomeRecords > 0)
Probe_OperatorNeverHoldsSection == holder /= "op"
\* SECOND-OCCURRENCE probes. Gate 10's F5 was a behaviour the model could
\* express and a budget constant excluded, and the first round of probes did
\* not catch it because they asked whether a thing ever happens. These ask
\* whether it happens TWICE, which is where a concurrency defect lives.
Probe_NeverTwoResolutions == opRecords < 2
Probe_NeverASupersessionChain == ~(opSuperseded >= 2)

====
