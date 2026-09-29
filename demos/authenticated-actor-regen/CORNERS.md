# CORNERS — Authenticated Actor, cold regeneration

A **finding** names a contradiction or a gap inside the specs and goes to the review channel; a **preference** is a choice where the specs leave room (the section titled *Implementation-discovered findings* in `contributing.md`).

---

## Findings

All nine are closed in the spec (council read 256). Seven are the 2026-09-14 rewrite's: the prose spec it replaced decided 1, 2, 3, 4, 6, 8 and 9, and the rewrite, claiming nothing but language changed, dropped them. 5 was a gap in the prose too; 7 came in with a later naming sweep.

**1. An optional argument no call could omit.** The signature makes credential type optional and Capability requirement 2 sets a default, but no rule read the default, and Primitive policy 4 refused a blank credential type, which in GRACE includes an absent one. *Closed:* Action wiring 30 passes the default for an absent type; Primitive policy 4 refuses a blank type the caller supplies. A test registers with and without one.

**2. Credential's refusals had no landing.** The signature carries storage-failure naming the credential, and no rule said when; an unknown credential type, refused by Credential and not by the boundary, had no answer at all. *Closed:* Action wiring 31, 32. A test drives both.

**3. The re-run guard's other half.** A lapsed holder re-runs the guard (Action wiring 12), and only a bound principal had an answer (13). A bound actor reference fell to the guard's own answer, namespace-conflict naming the guard, which says nothing committed — and the credential had. *Closed:* Action wiring 33 answers namespace-conflict naming the binding. A test lapses the lease and binds the actor in between.

**4. What a refused entry carries, stated nowhere.** Check 3.2 required the observed status on a credential-not-active entry and cited Composition state 8, which says only that an entry is appended. Action wiring 24 required the gate's credential id on every admitted entry, including not-bound, which reads no gate. *Closed:* Action wiring 24 is scoped to a call passing the gate; Action wiring 34 puts the observed status and the most recent record's credential id on the refused entry; Check 3.2 cites it.

**5. A failed append on a refusal.** Action wiring 25 answered any failed append with attest-failed naming the log *and the attestation id*, which no refusal has, and Invariant 4.1 said every call appends exactly one entry while 4.2 names the call that cannot. *Closed:* Action wiring 25 is the success entry's; Action wiring 35 answers a refusal's failed append with attest-failed naming a bare log, which means nothing committed; Invariant 4.1 covers the calls not answering it. A test fails the append on a not-bound call.

**6. Every rotation filed as an orphan.** The binding stores the initial credential id, and Housekeeping 6 and Check 6.1 reported a credential no binding names. A rotation's successor is named by none, so the leg reported every rotated credential, while the gate — keyed on the pair, not the id (Composes 9, 10) — correctly kept it open. *Closed:* the leg and the check key on the pair. A test rotates, attests under the successor and finds no orphan.

**7. A term from another page.** Term attest credential said *the credential the composition presents to the journal*; this composition has no journal and presents nothing — the caller does. *Closed:* the signing material the caller presents for Actor Identity's attest, never the credential material. Action wiring 17 now says the *bound* credential type, the one the gate reads.

**8. Verify resolved only a verified attestation.** Action wiring 27 resolved *the verified attestation's* actor reference, where the prose resolved any known attestation's — an auditor reading a proof-invalid attestation still needs whom it names. *Closed:* a known attestation's. A test retires the actor from the registry and still finds the principal.

**9. The attest lease's termini, left to a WHY.** Registration's lapse is a rule (Action wiring 12); the attestation's was only Capability requirement 6's WHY, where the prose had two steps: a lapse before the attestation re-reads the gate, and a lapse after it re-takes the section before the append. *Closed:* Action wiring 36, 37. A test revokes during a lapse and finds the second gate read closed.

## Preferences

- **An attestation whose actor reference the inverse map does not carry** answers its actor reference and no principal reference (Non-goal 13).
- **Credential's read** is the gate's surface, filtered in composition code; the observed status is the most recent record's effective status.
- **The critical section** is a lease on the host clock; a live holding meets no second taker in these single-threaded tests.
- **Not rendered:** the reconciliation cadence's scheduling (the leg is a call, run at start), Credential's length bound (String 7 through 9), Credential's own critical section over the pair, and the three seams' clock offset (one clock serves all three).
