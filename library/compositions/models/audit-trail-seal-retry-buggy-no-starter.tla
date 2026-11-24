---- MODULE audit-trail-seal-retry-buggy-no-starter ----
\* BUGGY TWIN: per-event cadence has no retry starter (seal cadence 6 dropped, the page before 2026-11-19):
\* a failed step-6 seal waits for a later [Record Action], and on a log gone quiet none comes.
\* BREAKS: SealCadence6_RetrySealsTail.
\* The per-event cadence's retry of a failed step-6 seal (seal cadence 3, seal cadence 6; record action
\* step 6.1, 6.4 through 6.6), derived from compositions/audit-trail.md on 2026-11-19 (the cure of Ledger
\* line 2026-10-25-b).
\* Under per-event cadence every [Record Action] seals the unsealed tail at its step 6 through [Seal Now];
\* a failed seal does not reject the call and leaves its event in the tail with the alert of record action
\* step 6.5 standing. The log may then go quiet: no further [Record Action] comes. Seal cadence 6 has the
\* deployment's starter run [Seal Now] once per reconciliation cadence (Execution Contract Scheduled leg 1),
\* so the tail is sealed within a bounded time of the failure once the mechanism answers again.
\* The mechanism fails at most MaxFail times in all (each failure the alert of a cause the deployment
\* clears); past that every seal lands.
\* NOT MODELED: the sealing lock and its lease, the uncovered mark and the rebuild (seal now 13 through 28:
\* a [Seal Now] here is one step that lands or fails whole); slice cap (a seal covers the whole tail);
\* interval-based and on-demand cadence; Defensible Retention's cascade, whose step 0 also seals; the
\* scan, whose run seals nothing (seal cadence 6 is a leg of its own). Time stands while the starter's run
\* is due, so the run starts on its cadence (the starter keeps the cadence, Scheduled leg 1).
EXTENDS Naturals

CONSTANTS MaxEv, MaxFail, Cadence, MaxTime

VARIABLES now, appended, sealedTo, failAt, fails, lastRun
vars == <<now, appended, sealedTo, failAt, fails, lastRun>>

\* failAt = 0 means no failed seal stands; otherwise it is one more than the instant at which the oldest
\* event still in the unsealed tail had its step-6 seal fail (instants count from 0).
NoFail == 0

TypeOK ==
    /\ now \in 0..MaxTime
    /\ appended \in 0..MaxEv
    /\ sealedTo \in 0..MaxEv
    /\ sealedTo <= appended
    /\ failAt \in 0..(MaxTime + 1)
    /\ fails \in 0..MaxFail
    /\ lastRun \in 0..MaxTime

Init ==
    /\ now = 0
    /\ appended = 0
    /\ sealedTo = 0
    /\ failAt = NoFail
    /\ fails = 0
    /\ lastRun = 0

Due == now - lastRun >= Cadence

\* A [Record Action] appends its event and seals the tail at step 6 (record action step 6.1); the seal lands.
RecordSealed ==
    /\ appended < MaxEv
    /\ appended' = appended + 1
    /\ sealedTo' = appended + 1
    /\ failAt' = NoFail
    /\ UNCHANGED <<now, fails, lastRun>>

\* The same [Record Action] whose step-6 seal fails: the call is not rejected (record action step 6.4),
\* the event stays in the tail and the alert stands (record action step 6.5, seal cadence 3).
RecordSealFails ==
    /\ appended < MaxEv
    /\ fails < MaxFail
    /\ appended' = appended + 1
    /\ fails' = fails + 1
    /\ failAt' = IF failAt = NoFail THEN now + 1 ELSE failAt
    /\ UNCHANGED <<now, sealedTo, lastRun>>

\* The starter's run of seal cadence 6, once per reconciliation cadence: [Seal Now] seals the tail.
RetrySealed ==
    /\ Due
    /\ sealedTo' = appended
    /\ failAt' = NoFail
    /\ lastRun' = now
    /\ UNCHANGED <<now, appended, fails>>

\* The same run whose [Seal Now] fails: the tail stands and the next run retries (record action step 6.6).
RetryFails ==
    /\ Due
    /\ sealedTo < appended
    /\ fails < MaxFail
    /\ fails' = fails + 1
    /\ lastRun' = now
    /\ UNCHANGED <<now, appended, sealedTo, failAt>>

\* Time moves while the starter's run is not due.
Tick ==
    /\ now < MaxTime
    /\ now' = now + 1
    /\ UNCHANGED <<appended, sealedTo, failAt, fails, lastRun>>

Next == RecordSealed \/ RecordSealFails \/ Tick   \* DEFECT: no starter runs [Seal Now]

Spec == Init /\ [][Next]_vars

\* seal cadence 6: an event whose step-6 seal failed leaves the unsealed tail within MaxFail runs of the
\* starter, each one reconciliation cadence apart, though no [Record Action] follows it.
SealCadence6_RetrySealsTail == (failAt # NoFail) => (now - (failAt - 1) <= MaxFail * Cadence)
====
