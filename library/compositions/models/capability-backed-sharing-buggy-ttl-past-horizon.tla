---- MODULE capability-backed-sharing-buggy-ttl-past-horizon ----
\* BUGGY TWIN (ttl-past-horizon): [Authorize Sharing] admits a supplied ttl past the audit horizon, the out-of-bounds envelope Primitive policy 3 refuses (Term ttl cap), so a token stays live after its authorization event ages (Lapse_before_aged). The checker must reject it. Everything else is the correct model.
\* Grace Commons — Capability-Backed Sharing.
\* Capability + Selective Disclosure + Audit Trail (substrate) + Recoverable Invocation.
\* Spec-level formal sibling of compositions/capability-backed-sharing.md.
\* Derived validator; the English spec is the single source of truth. On any
\* disagreement, diagnose per the entry *The conflict protocol* in pressure-testing.md.
\*
\* Re-derived 2026-11-10 for the page's composition of Recoverable Invocation (Composes 16
\* to 20, Term sharing bindings). The model of 2026-08-27 read [Redeem And Disclose] as one
\* clean commit beside an unsealed partial and its compensating seal, and checked Invariant 2
\* alone. Both premises are gone: a sharing action is an open, a commit and a close, three
\* commits and not one transaction (Non-goal 9; Recoverable Invocation Non-goal 1), and the
\* closing of an act whose outcome never landed is Recoverable Invocation's sweep's. So this
\* one model follows the split arc for all three acting actions, and the allocation half the
\* old model left out ([Authorize Sharing], [Revoke Sharing], Invariant 3 and 4.2) is in it.
\*
\* Extended 2026-11-10 for the ttl cap (Scott's ruling, "cap it"): an effective ttl no longer
\* than the ttl cap, `(audit horizon - (2 * clock offset allowance))` (Term ttl cap; Primitive
\* policy 3 for a supplied ttl, Capability requirement 33 for the default, checked at the
\* instance's start), and [Redeem And Disclose] reading the capability-to-sharing index only
\* for a live token (Action wiring 65, 66).
\*
\* RECOVERABLE INVOCATION, AS A CONTRACT. Nothing of its mechanism is modelled: no lease, no
\* critical section, no examine edge, no horizon, no clock arithmetic. What this model takes
\* from it, and recoverable-invocation.tla checks:
\*   - [Open] writes the intent before the commit, and refuses act-in-flight while an intent
\*     of the same (kind, act key) stands open (open step 1.7, 3.5): one live or yielded
\*     invocation per act key here. The authorization key and the disclosure key are each one
\*     value here (one allocator, one sharing descriptor); the revocation key is the token.
\*   - The commit answers committed, pre-commit or unknown (commit 1); committed goes to
\*     [Close], pre-commit to [Refuse] (a refusal record), unknown to [Yield] (commit 8). An
\*     unknown arm may or may not have written: the environment chooses.
\*   - A close that fails, or an invocation that dies after its commit, leaves the intent
\*     open for the sweep (Cross-record consistency 1).
\*   - The sweep examines only an intent whose invocation is gone, runs the page's act probe,
\*     and writes the recovered outcome (behind a recovery intent, flagged as recovery, under
\*     the recovery identity: one step here, reconcile step 3.2a) on committed, or an
\*     escalation on not-committed or undecidable (reconcile step 3.2, 3.5, 3.8). An
\*     unavailable probe writes nothing, which is a stutter step.
\*   - An operator, through the invocation resolve, may close an open or escalated intent
\*     with an outcome naming any record id of the kind the operator chooses, or abandon it,
\*     and may supersede an abandonment with an outcome (resolve 14 to 16, 32). The resolve
\*     does not check the outcome against Capability or Selective Disclosure (resolve 28, 31).
\*
\* WHAT THIS MODEL CHECKS
\* Two capability tokens, three bound invocations, one write outside every invocation (an
\* allocation, a revocation or a disclosure record), and whatever order the invocations, the
\* sweep, the operator, the outside write, the two index rebuilds and the write-ownership leg
\* take:
\*   - Owed_outcome             an invocation whose commit wrote stands open or beside a
\*                              closing (an outcome, an escalation, an abandonment), never a
\*                              refusal (Invariant 2.3; Cross-record consistency 1).
\*   - Outcome_names_record     every outcome the invocation or the sweep wrote names a record
\*                              of its kind: an allocated capability, a disclosure record, the
\*                              intent's token revoked (Invariant 2.1, 3.1; Recoverable
\*                              Invocation act probe 4, 5).
\*   - Disclosure_attested      every disclosure record an invocation wrote is under a token
\*                              whose authorization outcome the invocation's own close wrote
\*                              under the allocator's credential, never a recovered one
\*                              (Invariant 3.3, 3.5; Composition state 6; Action wiring 18).
\*   - Consumed_equals_disclosed  a token's consumed uses equal the disclosure records the
\*                              invocations wrote under it (Invariant 4.2; Action wiring 59).
\*   - Pairing_unique           the sweep answers committed only for the intent whose own
\*                              commit wrote the record (Capability requirement 22, 23;
\*                              Recoverable Invocation pairing datum 2, 4).
\*   - Write_ownership_finding  the leg opens a finding for every record a write outside every
\*                              invocation made, and for no other (Reconciliation 31 to 34).
\*   - False_closing_alert      the leg alerts exactly the records whose own intent an
\*                              abandonment or a refusal closed (Reconciliation 35).
\*   - Seal_alert               the disclosure-to-redemption rebuild alerts every disclosure
\*                              outcome naming no disclosure record, and two naming one
\*                              (Composition state 17; Invariant 2.1, 2.2 NOTE).
\*   - Duplicate_detected       the capability-to-sharing rebuild alerts two authorization
\*                              outcomes naming one token (Composition state 18; Invariant 3.2
\*                              NOTE).
\*   - Lapse_before_aged        every capability an allocator attested lapses no later than its
\*                              authorization event becomes an aged event: its expiry instant
\*                              does not pass `(recording instant + audit horizon) - clock offset
\*                              allowance` (Term ttl cap, Term aged event; Primitive policy 3,
\*                              Capability requirement 33). Capability's lapse and the aged
\*                              event both hold from the instant they reach, so the inequality
\*                              is the claim at every reading of now: no live token outlives the
\*                              record of its authorization, a ttl equal to the cap included.
\*   - Index_read_live          [Redeem And Disclose] reads the capability-to-sharing index only
\*                              for a token whose capability stands allocated (Action wiring 65,
\*                              66), so, with Lapse_before_aged, only while the token's
\*                              authorization event is inside the audit horizon.
\*
\* BOUND
\* Tokens 1..NT = 1..2, minted at an allocation's commit (an invocation's or the outside
\* write's). MaxRed = 1 use per token. N = 3 bound invocations, taken in slot order, each an
\* authorization, a redemption or a revocation, or a redemption refused not-authorized-sharing
\* ahead of its open (no record). MaxDirect = 1 write outside any invocation. Each invocation
\* takes a fresh now from an ordinal clock as its pairing datum (the host's injection,
\* Capability requirement 14, 22, 23), which Capability stamps as the allocation or
\* revocation instant and Selective Disclosure as the disclosure instant; a write outside any
\* invocation reads the same clock. Exhaustive.
\* The ttl cap's arithmetic: Hz = 3 is the audit horizon and A = 1 the clock offset
\* allowance, both in the clock's units, so the cap is 1; an authorization supplies no ttl
\* (the default, DefTtl = 1, the cap exactly), the cap exactly, or Hz + 1, past the horizon.
\* The substrate stamps the authorization event's recording instant at the close from its own
\* clock, any value within A of the reading then (the allowance covering every pair of clocks).
\* The clock is ordinal, so no token lapses in the model: the cap is checked as the inequality
\* Lapse_before_aged states, at the stamps the close can give.
\*
\* HOW A STEP IS READ
\* A bound invocation is a slot; its status `st` is none, rejected (refused ahead of its open,
\* nothing written), live (the intent landed), committed, dead (yielded, died, or its close
\* failed: the intent open, the sweep's), closed (an outcome names it), refused (a refusal
\* record), escalated or abandoned. `cby` says who wrote the closing (the invocation, the sweep
\* or the operator) and `oe` which record its outcome names (a token, or a disclosure id; 0:
\* none). `cw` says the invocation's own commit wrote, `ie` what (ghosts); `cmint`, `crby` and
\* `dby` say which invocation wrote a capability, a revocation and a disclosure record (0: a
\* write outside every invocation; ghosts), and `dtok` the token a disclosure consumed (a
\* ghost: a disclosure record carries no token). The leg's and the rebuilds' answers are
\* compared with the ghosts by a name the step adds to `viol`: the step answers by the page's
\* rule and the name compares that answer with the truth.
\*
\* NOT MODELLED (named)
\* - Recoverable Invocation's mechanism and its own invariants (one writer per act, the
\*   recovery intent before a recovered outcome, the recovery flag, the service identity's
\*   attestation, the closure window, the horizon edge, the escalation's candidates):
\*   recoverable-invocation.tla, inherited here.
\* - The clock's passage: a lapse, the young and aged records (Reconciliation 29, 30), the
\*   sweep cadence, an event aging past the audit horizon (Invariant 1.4), and so Composition
\*   state 7 and 21 and [Authorization Provenance]; the ttl and the horizon enter only as the
\*   inequality Lapse_before_aged checks. A commit landing after its invocation yielded is the
\*   unknown arm that wrote; the operator's abandonment over it stands for Recoverable
\*   Invocation's stall.
\* - Fields: the sharing descriptor, the allocator, the recipient, the scope and the authority
\*   (Invariant 1, 4.1) are one value; no redeemer identity exists to record (Invariant 1.2).
\*   The capability-to-sharing index is read only through its rule (Composition state 6);
\*   the disclosure-to-redemption index is read only for its rebuild's alert.
\* - Validation ahead of the open (Primitive policy, Action wiring 12 to 22) other than a
\*   supplied ttl over the cap, the spent token and the unattested token; an allocation's
\*   pre-commit arms (a Capability storage-failure writes
\*   what a refused redemption writes); Capability's not-known (the model opens only on a
\*   token Capability holds).
\* - The read-only queries, which write nothing (Action wiring 53).

EXTENDS Naturals, FiniteSets

CONSTANTS NT, N, MaxRed, MaxDirect, Hz, A, DefTtl

Ts == 1..NT
Is == 1..N
MaxT == N + MaxDirect
MaxD == N + MaxDirect
Ds == 1..MaxD
OpenSt == {"live", "committed", "dead"}

\* Term ttl cap: the audit horizon less twice the clock offset allowance.
Cap == Hz - 2 * A
\* The ttl an authorization supplies: none (0, the default applies), the cap, past the horizon.
Offers == {0, Cap, Hz + 1}
\* The substrate's recording instant for a reading c of the composition's clock (Term clock
\* offset allowance: any pair of clocks within A).
Stamps(c) == {s \in 0..(c + A) : s >= c - A}

VARIABLES
    cst, cat, crt, crem, cmint, crby,          \* the Capability records
    cexp, crec,                                 \* expiry instants; authorization events' stamps
    nd, dtok, dat, dby,                         \* the Selective Disclosure records
    ik, itok, inow, st, iw, cw, ie, oe, cby,    \* the bound invocations
    ittl, iread,                                \* effective ttl; the index read's token (ghost)
    nx, clk, ndir,                              \* the next slot, the clock, outside writes
    viol
vars == <<cst, cat, crt, crem, cmint, crby, cexp, crec, nd, dtok, dat, dby,
          ik, itok, inow, st, iw, cw, ie, oe, cby, ittl, iread, nx, clk, ndir, viol>>

cap == <<cst, cat, crt, crem, cmint, crby>>
sd == <<nd, dtok, dat, dby>>
inv == <<ik, itok, inow, st, iw, cw, ie, oe, cby>>
tt == <<cexp, crec>>
gx == <<ittl, iread>>

Discs == 1..nd

\* The act key's open intent: [Open] refuses act-in-flight while one stands. The
\* authorization key and the disclosure key are one value each here; the revocation key is
\* the token.
OpenOn(k, tk) ==
    \E j \in Is : ik[j] = k /\ st[j] \in OpenSt /\ (k = "rev" => itok[j] = tk)

Unused == {t \in Ts : cst[t] = "none"}
NextTok == CHOOSE t \in Unused : \A u \in Unused : t <= u

\* --- the capability-to-sharing index's rule (Composition state 6): a token is attested
\* only by an authorization outcome the invocation's own close wrote, under the allocator's
\* credential, never by one carrying the recovery flag (the sweep's or an operator's).
AttestedRule(t) == \E j \in Is : ik[j] = "auth" /\ st[j] = "closed" /\ cby[j] = "inv" /\ oe[j] = t

\* --- the truth the checks compare with: the allocator's own attestation.
AllocatorAttested(t) == \E j \in Is : ik[j] = "auth" /\ st[j] = "closed" /\ cby[j] = "inv" /\ oe[j] = t

\* --- Term carried record: an intent of the record's act kind whose act key the record
\* carries and whose pairing datum equals the record's instant.
CarriesAlloc(i, t) == ik[i] = "auth" /\ iw[i] /\ inow[i] = cat[t]
CarriesRev(i, t) == ik[i] = "rev" /\ iw[i] /\ itok[i] = t /\ inow[i] = crt[t]
CarriesDisc(i, d) == ik[i] = "disc" /\ iw[i] /\ inow[i] = dat[d]

\* --- the write-ownership leg's reading (Reconciliation 31 to 35) ---
LegFindsAlloc(t) == ~(\E i \in Is : CarriesAlloc(i, t))
LegFindsRev(t) == ~(\E i \in Is : CarriesRev(i, t))
LegFindsDisc(d) == ~(\E i \in Is : CarriesDisc(i, d))
Closed0 == {"abandoned", "refused"}
LegAlertsAlloc(t) == \E i \in Is : CarriesAlloc(i, t) /\ st[i] \in Closed0
LegAlertsRev(t) == \E i \in Is : CarriesRev(i, t) /\ st[i] \in Closed0
LegAlertsDisc(d) == \E i \in Is : CarriesDisc(i, d) /\ st[i] \in Closed0

\* --- the truth the leg's answers are compared with ---
FalseAlloc(t) == cmint[t] # 0 /\ st[cmint[t]] \in Closed0
FalseRev(t) == crby[t] # 0 /\ st[crby[t]] \in Closed0
FalseDisc(d) == dby[d] # 0 /\ st[dby[d]] \in Closed0

\* --- the rebuilds' readings (Composition state 17, 18) ---
DiscNamers(x) == {i \in Is : ik[i] = "disc" /\ st[i] = "closed" /\ oe[i] = x}
AuthNamers(t) == {i \in Is : ik[i] = "auth" /\ st[i] = "closed" /\ oe[i] = t}
SealWrong(x) == (DiscNamers(x) # {} /\ x > nd) \/ Cardinality(DiscNamers(x)) >= 2
SealAlerts(x) == (DiscNamers(x) # {} /\ x > nd) \/ Cardinality(DiscNamers(x)) >= 2
DupWrong(t) == Cardinality(AuthNamers(t)) >= 2
DupAlerts(t) == Cardinality(AuthNamers(t)) >= 2

\* --- the act probes (Term authorization probe, disclosure probe, revocation probe) ---
MatchAuth(i) == {t \in Ts : cst[t] # "none" /\ cat[t] = inow[i]}
MatchDisc(i) == {d \in Discs : dat[d] = inow[i]}
MatchRev(i) == IF cst[itok[i]] = "revoked" /\ crt[itok[i]] = inow[i] THEN {itok[i]} ELSE {}
Matches(i) == IF ik[i] = "auth" THEN MatchAuth(i) ELSE IF ik[i] = "disc" THEN MatchDisc(i) ELSE MatchRev(i)

TypeOK ==
    /\ cst \in [Ts -> {"none", "alloc", "revoked", "redeemed"}]
    /\ cat \in [Ts -> 0..MaxT]
    /\ crt \in [Ts -> 0..MaxT]
    /\ crem \in [Ts -> 0..MaxRed]
    /\ cmint \in [Ts -> 0..N]
    /\ crby \in [Ts -> 0..N]
    /\ nd \in 0..MaxD
    /\ dtok \in [Ds -> 0..NT]
    /\ dat \in [Ds -> 0..MaxT]
    /\ dby \in [Ds -> 0..N]
    /\ ik \in [Is -> {"-", "auth", "disc", "rev"}]
    /\ itok \in [Is -> 0..NT]
    /\ inow \in [Is -> 0..MaxT]
    /\ st \in [Is -> {"none", "rejected", "live", "committed", "dead", "closed", "refused",
                      "escalated", "abandoned"}]
    /\ iw \in [Is -> BOOLEAN]
    /\ cw \in [Is -> BOOLEAN]
    /\ ie \in [Is -> 0..MaxD]
    /\ oe \in [Is -> 0..MaxD]
    /\ cby \in [Is -> {"-", "inv", "sweep", "op"}]
    /\ nx \in 1..(N + 1)
    /\ clk \in 0..MaxT
    /\ ndir \in 0..MaxDirect
    /\ viol \subseteq {"finding-false", "finding-missed", "alert-wrong", "seal-missed", "dup-missed"}
    /\ cexp \in [Ts -> 0..(MaxT + Hz + 1)]
    /\ crec \in [Ts -> 0..(MaxT + A)]
    /\ ittl \in [Is -> 0..(Hz + 1)]
    /\ iread \in [Is -> {"-", "live", "spent"}]

Init ==
    /\ cst = [t \in Ts |-> "none"]
    /\ cat = [t \in Ts |-> 0]
    /\ crt = [t \in Ts |-> 0]
    /\ crem = [t \in Ts |-> 0]
    /\ cmint = [t \in Ts |-> 0]
    /\ crby = [t \in Ts |-> 0]
    /\ nd = 0
    /\ dtok = [d \in Ds |-> 0]
    /\ dat = [d \in Ds |-> 0]
    /\ dby = [d \in Ds |-> 0]
    /\ ik = [i \in Is |-> "-"]
    /\ itok = [i \in Is |-> 0]
    /\ inow = [i \in Is |-> 0]
    /\ st = [i \in Is |-> "none"]
    /\ iw = [i \in Is |-> FALSE]
    /\ cw = [i \in Is |-> FALSE]
    /\ ie = [i \in Is |-> 0]
    /\ oe = [i \in Is |-> 0]
    /\ cby = [i \in Is |-> "-"]
    /\ nx = 1
    /\ clk = 0
    /\ ndir = 0
    /\ viol = {}
    /\ cexp = [t \in Ts |-> 0]
    /\ crec = [t \in Ts |-> 0]
    /\ ittl = [i \in Is |-> 0]
    /\ iread = [i \in Is |-> "-"]
    \* Capability requirement 33: the instance starts only with a default ttl inside the cap.
    /\ DefTtl <= Cap

\* ---------------------------------------------------------------------------------------
\* The sharing actions: validate, open, commit, close (Recoverable Invocation Action wiring 4).

\* The pairing datum the host injects: a fresh now (Capability requirement 14, 22, 23).
Nows == {clk + 1}

\* [Open] for an authorization (Action wiring 2): the intent lands under the allocator,
\* carrying the now, the effective ttl, and no token (Recoverable Invocation Primitive policy
\* 10). A supplied ttl over the cap is an out-of-bounds envelope, refused invalid-request
\* with nothing written (Primitive policy 3, 14): no step.
OpenAuth(t, x) ==
    LET i == nx IN
    /\ i <= N
    /\ ~OpenOn("auth", 0)
    /\ ik' = [ik EXCEPT ![i] = "auth"]
    /\ inow' = [inow EXCEPT ![i] = t]
    /\ ittl' = [ittl EXCEPT ![i] = IF x = 0 THEN DefTtl ELSE x]
    /\ clk' = t
    /\ iw' = [iw EXCEPT ![i] = TRUE]
    /\ st' = [st EXCEPT ![i] = "live"]
    /\ nx' = i + 1
    /\ UNCHANGED <<itok, cw, ie, oe, cby, ndir, cap, sd, viol, tt, iread>>

\* [Redeem And Disclose]'s validation ahead of the open (Action wiring 12 to 22, 65, 66). A
\* spent token (Capability's read answers it redeemed or revoked; a lapse is the clock's) is
\* refused invalid carrying its redemption failure, the index unread, and nothing is written
\* (Action wiring 65, 66, 22).
RejectSpent(tk) ==
    LET i == nx IN
    /\ i <= N
    /\ cst[tk] \in {"redeemed", "revoked"}
    /\ ik' = [ik EXCEPT ![i] = "disc"]
    /\ itok' = [itok EXCEPT ![i] = tk]
    /\ st' = [st EXCEPT ![i] = "rejected"]
    /\ nx' = i + 1
    /\ UNCHANGED <<inow, iw, cw, ie, oe, cby, clk, ndir, cap, sd, viol, tt, gx>>

\* A live token the capability-to-sharing index does not attest is refused
\* not-authorized-sharing, and nothing is written (Action wiring 18, 22). The index is read
\* here, and the ghost records whether the token stood allocated when it was.
Reject(tk) ==
    LET i == nx IN
    /\ i <= N
    /\ cst[tk] = "alloc"
    /\ ~AttestedRule(tk)
    /\ ik' = [ik EXCEPT ![i] = "disc"]
    /\ itok' = [itok EXCEPT ![i] = tk]
    /\ st' = [st EXCEPT ![i] = "rejected"]
    /\ iread' = [iread EXCEPT ![i] = IF cst[tk] = "alloc" THEN "live" ELSE "spent"]
    /\ nx' = i + 1
    /\ UNCHANGED <<inow, iw, cw, ie, oe, cby, clk, ndir, cap, sd, viol, tt, ittl>>

\* [Open] for a live, attested token's redemption (Action wiring 23): the intent lands under
\* the redemption identity, carrying the token and the now.
OpenDisc(tk, t) ==
    LET i == nx IN
    /\ i <= N
    /\ cst[tk] = "alloc"
    /\ AttestedRule(tk)
    /\ ~OpenOn("disc", 0)
    /\ ik' = [ik EXCEPT ![i] = "disc"]
    /\ itok' = [itok EXCEPT ![i] = tk]
    /\ inow' = [inow EXCEPT ![i] = t]
    /\ iread' = [iread EXCEPT ![i] = IF cst[tk] = "alloc" THEN "live" ELSE "spent"]
    /\ clk' = t
    /\ iw' = [iw EXCEPT ![i] = TRUE]
    /\ st' = [st EXCEPT ![i] = "live"]
    /\ nx' = i + 1
    /\ UNCHANGED <<cw, ie, oe, cby, ndir, cap, sd, viol, tt, ittl>>

\* [Open] for a revocation (Action wiring 40): no refusal for a token the index does not
\* carry (Action wiring 48); the intent lands under the revoker, carrying the token and now.
OpenRev(tk, t) ==
    LET i == nx IN
    /\ i <= N
    /\ cst[tk] # "none"
    /\ ~OpenOn("rev", tk)
    /\ ik' = [ik EXCEPT ![i] = "rev"]
    /\ itok' = [itok EXCEPT ![i] = tk]
    /\ inow' = [inow EXCEPT ![i] = t]
    /\ clk' = t
    /\ iw' = [iw EXCEPT ![i] = TRUE]
    /\ st' = [st EXCEPT ![i] = "live"]
    /\ nx' = i + 1
    /\ UNCHANGED <<cw, ie, oe, cby, ndir, cap, sd, viol, tt, gx>>

\* The commits. a = "committed" or "unk-done" writes (the latter yields, the write landed).
\* The authorization's commit: Capability's allocate, the now injected at its seam
\* (Action wiring 4; Capability requirement 22).
CommitAuth(i, a) ==
    LET t == NextTok IN
    /\ st[i] = "live"
    /\ ik[i] = "auth"
    /\ Unused # {}
    /\ cst' = [cst EXCEPT ![t] = "alloc"]
    /\ cat' = [cat EXCEPT ![t] = inow[i]]
    /\ crem' = [crem EXCEPT ![t] = MaxRed]
    /\ cmint' = [cmint EXCEPT ![t] = i]
    /\ cexp' = [cexp EXCEPT ![t] = inow[i] + ittl[i]]
    /\ itok' = [itok EXCEPT ![i] = t]
    /\ cw' = [cw EXCEPT ![i] = TRUE]
    /\ ie' = [ie EXCEPT ![i] = t]
    /\ st' = [st EXCEPT ![i] = IF a = "committed" THEN "committed" ELSE "dead"]
    /\ UNCHANGED <<crt, crby, sd, ik, inow, iw, oe, cby, nx, clk, ndir, viol, crec, gx>>

\* The disclosure transaction: Capability's redeem, then Selective Disclosure's record with
\* disclosed_at the now, in one transaction (Term disclosure transaction; Action wiring 29).
CommitDisc(i, a) ==
    LET tk == itok[i]
        d == nd + 1
    IN
    /\ st[i] = "live"
    /\ ik[i] = "disc"
    /\ cst[tk] = "alloc"
    /\ crem[tk] > 0
    /\ d <= MaxD
    /\ crem' = [crem EXCEPT ![tk] = crem[tk] - 1]
    /\ cst' = [cst EXCEPT ![tk] = IF crem[tk] = 1 THEN "redeemed" ELSE "alloc"]
    /\ nd' = d
    /\ dtok' = [dtok EXCEPT ![d] = tk]
    /\ dat' = [dat EXCEPT ![d] = inow[i]]
    /\ dby' = [dby EXCEPT ![d] = i]
    /\ cw' = [cw EXCEPT ![i] = TRUE]
    /\ ie' = [ie EXCEPT ![i] = d]
    /\ st' = [st EXCEPT ![i] = IF a = "committed" THEN "committed" ELSE "dead"]
    /\ UNCHANGED <<cat, crt, cmint, crby, ik, itok, inow, iw, oe, cby, nx, clk, ndir, viol, tt, gx>>

\* The revocation's commit: Capability's revoke, the now injected at its seam (Action wiring
\* 41; Capability requirement 22).
CommitRev(i, a) ==
    LET tk == itok[i] IN
    /\ st[i] = "live"
    /\ ik[i] = "rev"
    /\ cst[tk] = "alloc"
    /\ cst' = [cst EXCEPT ![tk] = "revoked"]
    /\ crt' = [crt EXCEPT ![tk] = inow[i]]
    /\ crby' = [crby EXCEPT ![tk] = i]
    /\ cw' = [cw EXCEPT ![i] = TRUE]
    /\ ie' = [ie EXCEPT ![i] = tk]
    /\ st' = [st EXCEPT ![i] = IF a = "committed" THEN "committed" ELSE "dead"]
    /\ UNCHANGED <<cat, crem, cmint, sd, ik, itok, inow, iw, oe, cby, nx, clk, ndir, viol, tt, gx>>

\* A pre-commit arm Capability's own guard gives: a redeem answered invalid (exhausted,
\* revoked), a revoke answered already-terminal. Closed through [Refuse] with its refusal
\* record, nothing written (Action wiring 26, 42; Recoverable Invocation commit 2, 3).
CommitPre(i) ==
    /\ st[i] = "live"
    /\ ik[i] \in {"disc", "rev"}
    /\ (cst[itok[i]] # "alloc" \/ (ik[i] = "disc" /\ crem[itok[i]] = 0))
    /\ st' = [st EXCEPT ![i] = "refused"]
    /\ UNCHANGED <<cap, sd, ik, itok, inow, iw, cw, ie, oe, cby, nx, clk, ndir, viol, tt, gx>>

\* Selective Disclosure refuses the record (a foreclosed disclosure refusal): the disclosure
\* transaction fails whole, so the redeem rolls back and nothing is consumed; closed through
\* [Refuse] (Action wiring 31, 32; Execution Contract Database 1).
SdRefuse(i) ==
    LET tk == itok[i] IN
    /\ st[i] = "live"
    /\ ik[i] = "disc"
    /\ cst[tk] = "alloc"
    /\ crem[tk] > 0
    /\ st' = [st EXCEPT ![i] = "refused"]
    /\ UNCHANGED <<cap, sd, ik, itok, inow, iw, cw, ie, oe, cby, nx, clk, ndir, viol, tt, gx>>

\* An unknown arm that wrote nothing: the invocation yields (Action wiring 60).
CommitLost(i) ==
    /\ st[i] = "live"
    /\ st' = [st EXCEPT ![i] = "dead"]
    /\ UNCHANGED <<cap, sd, ik, itok, inow, iw, cw, ie, oe, cby, nx, clk, ndir, viol, tt, gx>>

\* [Close] after a committed arm: the outcome names what the commit wrote (Action wiring 8,
\* 36, 46). It may fail, or the invocation may die first: the intent stays open for the
\* sweep (Action wiring 61; Cross-record consistency 1). The substrate stamps an
\* authorization event's recording instant from its own clock, within A of the reading.
Close(i, o, s) ==
    /\ st[i] = "committed"
    /\ \/ /\ o = "ok"
          /\ st' = [st EXCEPT ![i] = "closed"]
          /\ cby' = [cby EXCEPT ![i] = "inv"]
          /\ oe' = [oe EXCEPT ![i] = ie[i]]
          /\ IF ik[i] = "auth"
                THEN /\ s \in Stamps(clk)
                     /\ crec' = [crec EXCEPT ![ie[i]] = s]
                ELSE /\ s = clk
                     /\ UNCHANGED crec
       \/ /\ o = "fail"
          /\ s = clk
          /\ st' = [st EXCEPT ![i] = "dead"]
          /\ UNCHANGED <<cby, oe, crec>>
    /\ UNCHANGED <<cap, sd, ik, itok, inow, iw, cw, ie, nx, clk, ndir, viol, cexp, gx>>

\* ---------------------------------------------------------------------------------------
\* Recoverable Invocation's sweep and the operator's resolve, as contracts.

\* The sweep on an intent whose invocation is gone: the act probe answers committed where
\* exactly one record matches, and the sweep writes the recovered outcome naming it.
SweepClose(i) ==
    /\ st[i] = "dead"
    /\ Cardinality(Matches(i)) = 1
    /\ st' = [st EXCEPT ![i] = "closed"]
    /\ cby' = [cby EXCEPT ![i] = "sweep"]
    /\ oe' = [oe EXCEPT ![i] = CHOOSE x \in Matches(i) : TRUE]
    /\ UNCHANGED <<cap, sd, ik, itok, inow, iw, cw, ie, nx, clk, ndir, viol, tt, gx>>

\* Otherwise (none, or several) it escalates.
SweepEscalate(i) ==
    /\ st[i] = "dead"
    /\ Cardinality(Matches(i)) # 1
    /\ st' = [st EXCEPT ![i] = "escalated"]
    /\ UNCHANGED <<cap, sd, ik, itok, inow, iw, cw, ie, oe, cby, nx, clk, ndir, viol, tt, gx>>

\* The operator's resolve: an abandonment of an open or escalated intent.
OpAbandon(i) ==
    /\ st[i] \in {"dead", "escalated"}
    /\ st' = [st EXCEPT ![i] = "abandoned"]
    /\ cby' = [cby EXCEPT ![i] = "op"]
    /\ UNCHANGED <<cap, sd, ik, itok, inow, iw, cw, ie, oe, nx, clk, ndir, viol, tt, gx>>

\* The operator's resolve: an outcome naming any record id of the kind the operator
\* chooses, superseding an abandonment where one stands (resolve 14 to 16, 21, 32).
OpOutcome(i, x) ==
    /\ st[i] \in {"dead", "escalated", "abandoned"}
    /\ x \in (IF ik[i] = "disc" THEN Ds ELSE Ts)
    /\ st' = [st EXCEPT ![i] = "closed"]
    /\ cby' = [cby EXCEPT ![i] = "op"]
    /\ oe' = [oe EXCEPT ![i] = x]
    /\ UNCHANGED <<cap, sd, ik, itok, inow, iw, cw, ie, nx, clk, ndir, viol, tt, gx>>

\* ---------------------------------------------------------------------------------------
\* A write outside every invocation, with no intent and no outcome, stamped from the same
\* clock: a capability allocated, a capability revoked, or a disclosure record.
DirectAlloc ==
    LET t == NextTok IN
    /\ ndir < MaxDirect
    /\ Unused # {}
    /\ cst' = [cst EXCEPT ![t] = "alloc"]
    /\ cat' = [cat EXCEPT ![t] = clk + 1]
    /\ crem' = [crem EXCEPT ![t] = MaxRed]
    /\ cmint' = [cmint EXCEPT ![t] = 0]
    /\ clk' = clk + 1
    /\ ndir' = ndir + 1
    /\ UNCHANGED <<crt, crby, sd, inv, nx, viol, tt, gx>>

DirectRevoke(tk) ==
    /\ ndir < MaxDirect
    /\ cst[tk] = "alloc"
    /\ cst' = [cst EXCEPT ![tk] = "revoked"]
    /\ crt' = [crt EXCEPT ![tk] = clk + 1]
    /\ crby' = [crby EXCEPT ![tk] = 0]
    /\ clk' = clk + 1
    /\ ndir' = ndir + 1
    /\ UNCHANGED <<cat, crem, cmint, sd, inv, nx, viol, tt, gx>>

DirectDisclose ==
    LET d == nd + 1 IN
    /\ ndir < MaxDirect
    /\ d <= MaxD
    /\ nd' = d
    /\ dtok' = [dtok EXCEPT ![d] = 0]
    /\ dat' = [dat EXCEPT ![d] = clk + 1]
    /\ dby' = [dby EXCEPT ![d] = 0]
    /\ clk' = clk + 1
    /\ ndir' = ndir + 1
    /\ UNCHANGED <<cap, inv, nx, viol, tt, gx>>

\* The write-ownership leg (Reconciliation 31 to 35): every capability and disclosure record
\* read against the intents, on an answered read. It opens a finding and alerts by the page's
\* rule; the names it adds compare the rule's answer with what the records hold.
LegRun ==
    LET alloc == {t \in Ts : cst[t] # "none"}
        revd == {t \in Ts : cst[t] = "revoked"}
    IN
    /\ viol' = viol
         \cup (IF \/ \E t \in alloc : LegFindsAlloc(t) /\ cmint[t] # 0
                  \/ \E t \in revd : LegFindsRev(t) /\ crby[t] # 0
                  \/ \E d \in Discs : LegFindsDisc(d) /\ dby[d] # 0
               THEN {"finding-false"} ELSE {})
         \cup (IF \/ \E t \in alloc : ~LegFindsAlloc(t) /\ cmint[t] = 0
                  \/ \E t \in revd : ~LegFindsRev(t) /\ crby[t] = 0
                  \/ \E d \in Discs : ~LegFindsDisc(d) /\ dby[d] = 0
               THEN {"finding-missed"} ELSE {})
         \cup (IF \/ \E t \in alloc : LegAlertsAlloc(t) # FalseAlloc(t)
                  \/ \E t \in revd : LegAlertsRev(t) # FalseRev(t)
                  \/ \E d \in Discs : LegAlertsDisc(d) # FalseDisc(d)
               THEN {"alert-wrong"} ELSE {})
    /\ UNCHANGED <<cap, sd, inv, nx, clk, ndir, tt, gx>>

\* The two index rebuilds (Composition state 16 to 18): the seal alert and the
\* duplicate-authorization alert.
Rebuild ==
    /\ viol' = viol
         \cup (IF \E x \in Ds : SealWrong(x) /\ ~SealAlerts(x) THEN {"seal-missed"} ELSE {})
         \cup (IF \E t \in Ts : DupWrong(t) /\ ~DupAlerts(t) THEN {"dup-missed"} ELSE {})
    /\ UNCHANGED <<cap, sd, inv, nx, clk, ndir, tt, gx>>

Next ==
    \/ \E t \in Nows, x \in Offers : OpenAuth(t, x)
    \/ \E tk \in Ts : RejectSpent(tk)
    \/ \E tk \in Ts : Reject(tk)
    \/ \E tk \in Ts, t \in Nows : OpenDisc(tk, t)
    \/ \E tk \in Ts, t \in Nows : OpenRev(tk, t)
    \/ \E i \in Is, a \in {"committed", "unk-done"} : CommitAuth(i, a)
    \/ \E i \in Is, a \in {"committed", "unk-done"} : CommitDisc(i, a)
    \/ \E i \in Is, a \in {"committed", "unk-done"} : CommitRev(i, a)
    \/ \E i \in Is : CommitPre(i)
    \/ \E i \in Is : SdRefuse(i)
    \/ \E i \in Is : CommitLost(i)
    \/ \E i \in Is, o \in {"ok", "fail"}, s \in Stamps(clk) : Close(i, o, s)
    \/ \E i \in Is : SweepClose(i)
    \/ \E i \in Is : SweepEscalate(i)
    \/ \E i \in Is : OpAbandon(i)
    \/ \E i \in Is, x \in Ds : OpOutcome(i, x)
    \/ DirectAlloc
    \/ \E tk \in Ts : DirectRevoke(tk)
    \/ DirectDisclose
    \/ LegRun
    \/ Rebuild
Spec == Init /\ [][Next]_vars

\* --- composition-level safety invariants ---

\* Invariant 2.3, Cross-record consistency 1: an invocation whose commit wrote stands open or
\* beside a closing, never a refusal.
Owed_outcome ==
    \A i \in Is : cw[i] => st[i] \in {"committed", "dead", "closed", "escalated", "abandoned"}

\* Invariant 2.1, 3.1: an outcome the invocation or the sweep wrote names a record of its
\* kind. An operator's is detected (Composition state 17, 18; Check 2.1, 3.2).
Outcome_names_record ==
    \A i \in Is : (st[i] = "closed" /\ cby[i] # "op") =>
        IF ik[i] = "auth" THEN oe[i] \in Ts /\ cst[oe[i]] # "none"
        ELSE IF ik[i] = "disc" THEN oe[i] \in Discs
        ELSE oe[i] = itok[i] /\ oe[i] \in Ts /\ cst[oe[i]] = "revoked"

\* Invariant 3.3, 3.5, Check 3.4: every disclosure record an invocation wrote is under a
\* token the allocator's own attestation authorized, never a recovered one (G1).
Disclosure_attested ==
    \A d \in Discs : dby[d] # 0 => AllocatorAttested(dtok[d])

\* Invariant 4.2: a token's consumed uses equal the disclosure records the invocations wrote
\* under it, so no use is consumed without its disclosure record.
Consumed_equals_disclosed ==
    \A t \in Ts : cst[t] # "none" =>
        (MaxRed - crem[t]) = Cardinality({d \in Discs : dtok[d] = t})

\* Capability requirement 22, 23: the sweep answers committed only for the intent whose own
\* commit wrote the record.
Writer(i, x) ==
    IF ik[i] = "auth" THEN cmint[x] ELSE IF ik[i] = "disc" THEN dby[x] ELSE crby[x]
Pairing_unique ==
    \A i \in Is : (st[i] = "closed" /\ cby[i] = "sweep" /\ oe[i] \in (IF ik[i] = "disc" THEN Discs ELSE Ts))
                     => Writer(i, oe[i]) = i

\* Reconciliation 32 to 34: a finding for every record a write outside every invocation
\* made, and for no other.
Write_ownership_finding == ~("finding-false" \in viol) /\ ~("finding-missed" \in viol)

\* Reconciliation 35: an alert for exactly the records whose own intent an abandonment or a
\* refusal closed.
False_closing_alert == ~("alert-wrong" \in viol)

\* Composition state 17: the seal alert opens for every disclosure outcome naming no
\* disclosure record, and for two naming one.
Seal_alert == ~("seal-missed" \in viol)

\* Composition state 18: the duplicate-authorization alert opens for two authorization
\* outcomes naming one token.
Duplicate_detected == ~("dup-missed" \in viol)

\* Term ttl cap, Primitive policy 3, Capability requirement 33: a capability an allocator
\* attested lapses no later than its authorization event ages (Term aged event), so no live
\* token outlives the record of its authorization.
Lapse_before_aged ==
    \A t \in Ts : AllocatorAttested(t) => cexp[t] <= (crec[t] + Hz) - A

\* Action wiring 65, 66: the redemption reads the capability-to-sharing index only for a
\* token whose capability stands allocated.
Index_read_live == \A i \in Is : iread[i] # "spent"

====
