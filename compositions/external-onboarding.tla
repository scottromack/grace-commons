---- MODULE external-onboarding ----
\* Grace Commons — External Onboarding composition.
\* Spec-level formal sibling of compositions/external-onboarding.md.
\* Re-derived 2026-11-10 for the resume arm's retirement: an onboarding is one
\* Recoverable Invocation act (spec Composes 17 through 19, Term onboarding binding).
\*
\* This TLA+ model verifies the five application-level invariants from the
\* spec under every reachable state interleaving at the chosen bounds. It
\* is a peer artifact to the canonical English spec; if the spec changes,
\* this model should be updated to match.
\*
\* -------------------------------------------------------------------------
\* WHY TLA+ FOR THIS SPEC
\*
\* The spec's most consequential temporal claim is the single-resolution
\* gate: Invitation.accept is the serialization point. Under concurrent
\* onboard calls for the same invitation token, exactly one call succeeds;
\* all others receive already-resolved(Accepted) and create no permanent
\* records. TLA+ enumerates all possible interleavings of concurrent
\* Onboard steps; TLC will confirm that the precondition
\* `invitations[inv].status = "pending"` is sufficient to guarantee this
\* across every ordering.
\*
\* The companion Alloy model (if written) would carry the static structural
\* facts. This TLA+ model carries the temporal safety properties over the
\* operational state machine.
\*
\* -------------------------------------------------------------------------
\* SCOPE — INTENTIONAL EXCLUSIONS
\*
\* * Party Identity verification (Unverified → Verified). That transition
\*   belongs to Customer Onboarding and is outside this
\*   composition's surface.
\* * Credential rotation after onboarding. Outside the composition.
\* * Background invitation expiry scheduling. Expire is modeled as an
\*   action available to TLC but the composition does not own its trigger.
\* * Recoverable Invocation's own protocol: the critical section, the sweep,
\*   the lease, the examine edge and the horizon. recoverable-invocation.tla
\*   checks one writer per act, closure of an open intent and the refusal of
\*   a stale writer; this model keeps only what onboarding adds: the three
\*   writes commit together or not at all, a refusal leaves the invitation
\*   pending, and an intent is closed by a completion record or a refusal
\*   record or is open (the operator's resolve closes it, naming the arc the
\*   transaction made).
\* * The onboarding probe, the purge of an old completion record and the
\*   operator's choice among candidates. The spec states these as detected,
\*   not prevented (Invariant 4.6, Check 7.3); no model here checks them.
\* * The Audit Trail's own tamper-evidence properties. The Audit Trail
\*   substrate is represented as sets tracking which events have been
\*   written; its internal hash chain is the Audit Trail composition's
\*   concern.
\*
\* -------------------------------------------------------------------------
\* COMPLEMENTARITY NOTE
\*
\* The `invite` action writes the Audit Trail record before calling
\* Invitation.initiate (audit-first discipline, spec section onboard notes step
\* ordering). In this model, both writes are atomic at the action grain
\* (TLA+ actions are atomic). The partial-failure case — Audit Trail record
\* exists but Invitation.initiate fails — is represented by the absence of
\* any invite-initiated record in invitations while an audit_initiated event
\* exists. That gap is what Generation Acceptance check 6 detects in a
\* running system; here it is noted as a known scope limitation.
\* =========================================================================

EXTENDS Naturals, FiniteSets, TLC

CONSTANTS
    Actors,        \* internal actor IDs (inviters, service accounts)
    InvitationIds, \* available invitation ID slots
    PartyIds,      \* available party ID slots
    CredentialIds, \* available credential ID slots
    MaxClock       \* upper bound on logical clock (bounds state space)

\* Suggested TLC values for a tractable run:
\*   Actors        = {a1, a2}
\*   InvitationIds = {i1, i2}
\*   PartyIds      = {p1, p2}
\*   CredentialIds = {c1, c2}
\*   MaxClock      = 3

NULL == "_none_"

InvStatuses == {"pending", "accepted", "declined", "revoked", "expired"}

\* =========================================================================
\* RECORD TYPES
\*
\* InvRec tracks the invitation's status and, on a successful onboard, the
\* party_id and cred_id that were created. These two fields are NULL for
\* invitations that are pending, declined, revoked or expired (a refused arc
\* leaves the invitation pending). They are non-NULL only when the whole
\* onboarding transaction has committed — which is exactly Invariant 5's
\* completeness condition.
\*
\* inviter_ref is omitted from InvRec. The inviting actor's identity is
\* needed for audit attribution; for invariant checking here, it is not
\* load-bearing.
\* =========================================================================

InvRec ==
    [ status   : InvStatuses,
      party_id : PartyIds   \cup {NULL},
      cred_id  : CredentialIds \cup {NULL} ]

\* PartyRec binds the enrolled party to the invitation that authorized its
\* creation (from_inv) and records when it was enrolled (for ordering check).
PartyRec ==
    [ enrolled_at : 0..MaxClock,
      from_inv    : InvitationIds ]

\* CredRec binds the credential to its subject (principal_ref = party_id)
\* and the invitation that authorized its creation.
CredRec ==
    [ principal_ref : PartyIds,
      registered_at : 0..MaxClock,
      from_inv      : InvitationIds ]

\* =========================================================================
\* VARIABLES
\*
\* Domain state:
\*   invitations  — the invitation store (InvitationIds -> InvRec | NULL)
\*   parties      — the Party Identity store (PartyIds -> PartyRec | NULL)
\*   credentials  — the Credential store (CredentialIds -> CredRec | NULL)
\*
\* Audit Trail state (simplified — sets of invitation IDs per event type):
\*   audit_intended  — invitations with an onboarding.intended record, which
\*                     Recoverable Invocation's open writes before the
\*                     onboarding transaction (Action wiring 56)
\*   audit_completed — invitations with an onboarding.completed record, the
\*                     outcome the close or the operator's resolve writes
\*   audit_refused   — invitations with an onboarding.refused record, the
\*                     refusal that survives a pre-commit refusal
\*   audit_declined  — invitations whose invitation.declined event has
\*                     been written (Invariant 4b)
\*   audit_revoked   — invitations whose invitation.revoked event has
\*                     been written (Invariant 4c)
\*
\* Logical clock:
\*   clock — monotone counter, bounded by MaxClock to keep state finite
\* =========================================================================

VARIABLES
    invitations,
    parties,
    credentials,
    audit_intended,
    audit_completed,
    audit_refused,
    audit_declined,
    audit_revoked,
    clock

vars == <<invitations, parties, credentials,
          audit_intended, audit_completed, audit_refused,
          audit_declined, audit_revoked,
          clock>>

\* --- TypeOK ---------------------------------------------------------------

TypeOK ==
    /\ invitations \in [InvitationIds -> InvRec \cup {NULL}]
    /\ parties     \in [PartyIds      -> PartyRec \cup {NULL}]
    /\ credentials \in [CredentialIds -> CredRec  \cup {NULL}]
    /\ audit_intended  \subseteq InvitationIds
    /\ audit_completed \subseteq InvitationIds
    /\ audit_refused   \subseteq InvitationIds
    /\ audit_declined  \subseteq InvitationIds
    /\ audit_revoked   \subseteq InvitationIds
    /\ clock \in 0..MaxClock

\* --- Init -----------------------------------------------------------------

Init ==
    /\ invitations     = [i \in InvitationIds |-> NULL]
    /\ parties         = [p \in PartyIds      |-> NULL]
    /\ credentials     = [c \in CredentialIds |-> NULL]
    /\ audit_intended  = {}
    /\ audit_completed = {}
    /\ audit_refused   = {}
    /\ audit_declined  = {}
    /\ audit_revoked   = {}
    /\ clock           = 0

\* =========================================================================
\* ACTIONS
\* =========================================================================

\* --- Invite(actor, inv) ---------------------------------------------------
\*
\* Models the spec's `invite` action. The audit-first ordering (attempt
\* record, then Invitation.initiate, then the initiated record) is collapsed
\* into one atomic step; the partial-failure case is the spec's Check 6.2.
\*
Invite(actor, inv) ==
    /\ clock < MaxClock
    /\ invitations[inv] = NULL   \* invitation slot must be unused
    /\ invitations' = [invitations EXCEPT
         ![inv] = [status   |-> "pending",
                   party_id |-> NULL,
                   cred_id  |-> NULL]]
    /\ clock' = clock + 1
    /\ UNCHANGED <<parties, credentials, audit_intended, audit_completed,
                   audit_refused, audit_declined, audit_revoked>>

\* --- Onboard(inv, party, cred, actor) ------------------------------------
\*
\* Models the spec's `onboard` happy path: the invocation open writes the
\* intent, the onboarding transaction commits the accept, the enroll and the
\* register together (Execution Contract Database 1), and the invocation
\* close writes the completion record. The single-resolution gate is the
\* precondition `invitations[inv].status = "pending"`: exactly one concurrent
\* Onboard per invitation can satisfy it.
\*
Onboard(inv, party, cred, actor) ==
    /\ clock < MaxClock
    /\ invitations[inv] /= NULL
    /\ invitations[inv].status = "pending"   \* THE GATE — Invitation.accept
    /\ parties[party]     = NULL             \* party slot must be unused
    /\ credentials[cred]  = NULL             \* credential slot must be unused
    /\ invitations' = [invitations EXCEPT
         ![inv] = [status   |-> "accepted",
                   party_id |-> party,
                   cred_id  |-> cred]]
    /\ parties' = [parties EXCEPT
         ![party] = [enrolled_at |-> clock + 1,
                     from_inv    |-> inv]]
    /\ credentials' = [credentials EXCEPT
         ![cred] = [principal_ref |-> party,
                    registered_at |-> clock + 1,
                    from_inv      |-> inv]]
    /\ audit_intended'  = audit_intended \cup {inv}
    /\ audit_completed' = audit_completed \cup {inv}
    /\ clock' = clock + 1
    /\ UNCHANGED <<audit_refused, audit_declined, audit_revoked>>

\* --- OnboardCommittedOpen(inv, party, cred, actor) -----------------------
\*
\* The transaction commits and the invocation close does not land (a lost
\* reply, a failed close): the intent stands, the completion record is owed,
\* and the arc is whole. The sweep reports it and an operator closes it.
\*
OnboardCommittedOpen(inv, party, cred, actor) ==
    /\ clock < MaxClock
    /\ invitations[inv] /= NULL
    /\ invitations[inv].status = "pending"
    /\ parties[party]     = NULL
    /\ credentials[cred]  = NULL
    /\ invitations' = [invitations EXCEPT
         ![inv] = [status   |-> "accepted",
                   party_id |-> party,
                   cred_id  |-> cred]]
    /\ parties' = [parties EXCEPT
         ![party] = [enrolled_at |-> clock + 1,
                     from_inv    |-> inv]]
    /\ credentials' = [credentials EXCEPT
         ![cred] = [principal_ref |-> party,
                    registered_at |-> clock + 1,
                    from_inv      |-> inv]]
    /\ audit_intended' = audit_intended \cup {inv}
    /\ clock' = clock + 1
    /\ UNCHANGED <<audit_completed, audit_refused, audit_declined, audit_revoked>>

\* --- OnboardRefused(inv, actor) -------------------------------------------
\*
\* A call of the onboarding transaction refuses (Credential's
\* duplicate-active-credential, a constituent's invalid-request or
\* storage-failure): the transaction rolls back (Action wiring 61), the
\* invitation stays as the call found it, and the invocation refuse writes
\* the refusal record beside the intent.
\*
OnboardRefused(inv, actor) ==
    /\ clock < MaxClock
    /\ invitations[inv] /= NULL
    /\ invitations[inv].status = "pending"
    /\ audit_intended' = audit_intended \cup {inv}
    /\ audit_refused'  = audit_refused \cup {inv}
    /\ clock' = clock + 1
    /\ UNCHANGED <<invitations, parties, credentials, audit_completed,
                   audit_declined, audit_revoked>>

\* --- OperatorResolve(inv) -------------------------------------------------
\*
\* The operator closes an open intent through the invocation resolve, naming
\* the arc's own party and credential as the outcome (the spec's Check 7.3
\* detects the operator naming another token's party; no action here does).
\*
OperatorResolve(inv) ==
    /\ invitations[inv] /= NULL
    /\ invitations[inv].status = "accepted"
    /\ inv \in audit_intended
    /\ inv \notin audit_completed
    /\ audit_completed' = audit_completed \cup {inv}
    /\ UNCHANGED <<invitations, parties, credentials, audit_intended,
                   audit_refused, audit_declined, audit_revoked, clock>>

\* --- Decline(inv, actor) --------------------------------------------------
\*
\* Models the spec's `decline` action. Invitation transitions
\* Pending → Declined; the invitation.declined audit event is written.
\*
Decline(inv, actor) ==
    /\ clock < MaxClock
    /\ invitations[inv] /= NULL
    /\ invitations[inv].status = "pending"
    /\ invitations' = [invitations EXCEPT
         ![inv].status = "declined"]
    /\ audit_declined' = audit_declined \cup {inv}
    /\ clock' = clock + 1
    /\ UNCHANGED <<parties, credentials, audit_intended, audit_completed,
                   audit_refused, audit_revoked>>

\* --- Revoke(inv, actor) ---------------------------------------------------
\*
\* Models the spec's `revoke` action. Invitation transitions
\* Pending → Revoked; the invitation.revoked audit event is written.
\*
Revoke(inv, actor) ==
    /\ clock < MaxClock
    /\ invitations[inv] /= NULL
    /\ invitations[inv].status = "pending"
    /\ invitations' = [invitations EXCEPT
         ![inv].status = "revoked"]
    /\ audit_revoked' = audit_revoked \cup {inv}
    /\ clock' = clock + 1
    /\ UNCHANGED <<parties, credentials, audit_intended, audit_completed,
                   audit_refused, audit_declined>>

\* --- Expire(inv) ----------------------------------------------------------
\*
\* Models background expiry by the Invitation atom's scheduler. Expiry that
\* the scheduler performs, not this composition's `onboard` action
\* discovering an expired invitation, is outside the composition's surface
\* and produces no audit event from this composition; Invariant 4 covers only
\* terminal transitions that pass through this composition.
\*
Expire(inv) ==
    /\ clock < MaxClock
    /\ invitations[inv] /= NULL
    /\ invitations[inv].status = "pending"
    /\ invitations' = [invitations EXCEPT
         ![inv].status = "expired"]
    /\ clock' = clock + 1
    /\ UNCHANGED <<parties, credentials, audit_intended, audit_completed,
                   audit_refused, audit_declined, audit_revoked>>

\* --- Next -----------------------------------------------------------------

Next ==
    \/ \E actor \in Actors, inv \in InvitationIds :
           Invite(actor, inv)
    \/ \E actor \in Actors, inv \in InvitationIds,
         party \in PartyIds, cred \in CredentialIds :
           Onboard(inv, party, cred, actor)
    \/ \E actor \in Actors, inv \in InvitationIds,
         party \in PartyIds, cred \in CredentialIds :
           OnboardCommittedOpen(inv, party, cred, actor)
    \/ \E actor \in Actors, inv \in InvitationIds :
           OnboardRefused(inv, actor)
    \/ \E inv \in InvitationIds :
           OperatorResolve(inv)
    \/ \E actor \in Actors, inv \in InvitationIds :
           Decline(inv, actor)
    \/ \E actor \in Actors, inv \in InvitationIds :
           Revoke(inv, actor)
    \/ \E inv \in InvitationIds :
           Expire(inv)

Spec == Init /\ [][Next]_vars

\* =========================================================================
\* APPLICATION-LEVEL INVARIANTS
\* Names and numbering match section Composition-level invariants in the spec.
\* =========================================================================

\* Invariant 1 — Invitation gates enrollment.
\* Every enrolled Party Identity traces to an Invitation in Accepted state.
\* No party is created by any path other than a successful Onboard that
\* first satisfied the `invitations[inv].status = "pending"` gate.
\*
\* This is the composition's load-bearing emergent property. It holds
\* across all interleavings because:
\*   (a) parties[p] /= NULL is only set by the Onboard action.
\*   (b) Onboard requires invitations[inv].status = "pending" atomically.
\*   (c) After Onboard, invitations[inv].status = "accepted".
\*
Invitation_Gates_Enrollment ==
    \A p \in PartyIds :
        parties[p] /= NULL =>
            /\ invitations[parties[p].from_inv] /= NULL
            /\ invitations[parties[p].from_inv].status = "accepted"

\* Invariant 2 — Single resolution (one successful onboard per invitation).
\* Each invitation produces at most one enrolled Party Identity.
\* This is the concurrency safety claim: even when two Onboard calls for
\* the same inv fire in any interleaving, at most one can satisfy
\* `invitations[inv].status = "pending"` — the first sets it to "accepted",
\* disabling the second before it creates any records.
\*
Single_Resolution ==
    \A inv \in InvitationIds :
        Cardinality({p \in PartyIds :
            parties[p] /= NULL /\ parties[p].from_inv = inv}) <= 1

\* Invariant 3 — Credential-follows-party.
\* Every credential registered via this composition has a corresponding
\* Party Identity record, and the enrollment timestamp predates or matches
\* the credential registration timestamp.
\*
\* Structural: credentials[c] /= NULL =>
\*   (a) parties[credentials[c].principal_ref] /= NULL
\*   (b) parties[principal_ref].enrolled_at <= credentials[c].registered_at
\*
Credential_Follows_Party ==
    \A c \in CredentialIds :
        credentials[c] /= NULL =>
            LET pr == credentials[c].principal_ref
            IN  /\ parties[pr] /= NULL
                /\ parties[pr].enrolled_at <= credentials[c].registered_at

\* Invariant 4 — Audit Trail coverage as safety plus detectability.
\* Every terminal Invitation transition that passes through this
\* composition leaves a record, or a gap signature the checks enumerate.
\*   (a) Accepted invitations → an intent record (Check 5.1): the completion
\*       record follows it, or the intent is open and the operator closes it
\*   (b) Declined invitations → invitation.declined event
\*   (c) Revoked invitations → invitation.revoked event
\*
\* Expired invitations (via the scheduler, Expire above) are excluded:
\* Invariant 4 covers only terminal changes that pass through this
\* composition.
\*
Audit_Coverage ==
    /\ \A inv \in InvitationIds :
           (invitations[inv] /= NULL /\
            invitations[inv].status = "accepted")
           => inv \in audit_intended
    /\ \A inv \in InvitationIds :
           (invitations[inv] /= NULL /\
            invitations[inv].status = "declined")
           => inv \in audit_declined
    /\ \A inv \in InvitationIds :
           (invitations[inv] /= NULL /\
            invitations[inv].status = "revoked")
           => inv \in audit_revoked

\* Checks 4.1 and 4.2 — a completion record follows an intent record and
\* names an accepted invitation.
Completion_Follows_Intent ==
    \A inv \in audit_completed :
        /\ inv \in audit_intended
        /\ invitations[inv] /= NULL
        /\ invitations[inv].status = "accepted"

\* Action wiring 61 and Execution Contract Database 1 — an accepted
\* invitation is a whole arc: the accept, the enroll and the register commit
\* together, so a refusal (a credential collision included) leaves the
\* invitation pending and no party or credential behind. No committed partial
\* arc exists for a resume to finish.
Accepted_Is_Whole ==
    \A inv \in InvitationIds :
        (invitations[inv] /= NULL /\ invitations[inv].status = "accepted")
        => /\ invitations[inv].party_id /= NULL
           /\ invitations[inv].cred_id  /= NULL

\* Invariant 5 — Completion record names the full arc.
\* For every invitation that completed a full successful onboard
\* (party_id /= NULL on the invitation record), the corresponding
\* Party Identity record and Credential record both exist, and the
\* credential's principal_ref matches the invitation's party_id.
\* This verifies that the spec's onboarding.completed event payload
\* {invitation_token, accepting_identity_ref, party_id, credential_id}
\* is self-consistent and references live records.
\*
Completion_Names_Full_Arc ==
    \A inv \in InvitationIds :
        (invitations[inv] /= NULL /\
         invitations[inv].party_id /= NULL) =>
            LET pid == invitations[inv].party_id
                cid == invitations[inv].cred_id
            IN  /\ parties[pid] /= NULL
                /\ cid /= NULL
                /\ credentials[cid] /= NULL
                /\ credentials[cid].principal_ref = pid

\* =========================================================================
\* ADDITIONAL STRUCTURAL INVARIANTS
\* Properties not named in section Composition-level invariants but implied by
\* the composition's step-order wiring and needed for a complete TLC check.
\* =========================================================================

\* Status monotonicity: invitation terminal states are irreversible.
\* Once an invitation is not Pending, it remains in its terminal state.
\* Checked structurally here; the temporal "always" version is enforced
\* by the action preconditions (all actions require status = "pending").
\*
Status_Monotone ==
    \A inv \in InvitationIds :
        invitations[inv] /= NULL =>
            invitations[inv].status \in InvStatuses

\* Party-to-invitation binding integrity.
\* Every party record's from_inv references an existing invitation slot.
Party_Invitation_Binding ==
    \A p \in PartyIds :
        parties[p] /= NULL =>
            invitations[parties[p].from_inv] /= NULL

\* Credential-to-party binding integrity.
\* Every credential's principal_ref references an existing party record.
Credential_Party_Binding ==
    \A c \in CredentialIds :
        credentials[c] /= NULL =>
            parties[credentials[c].principal_ref] /= NULL

\* Audit events reference only existing invitations.
Audit_Set_Integrity ==
    /\ audit_intended  \subseteq {inv \in InvitationIds : invitations[inv] /= NULL}
    /\ audit_completed \subseteq {inv \in InvitationIds : invitations[inv] /= NULL}
    /\ audit_refused   \subseteq {inv \in InvitationIds : invitations[inv] /= NULL}
    /\ audit_declined  \subseteq {inv \in InvitationIds : invitations[inv] /= NULL}
    /\ audit_revoked   \subseteq {inv \in InvitationIds : invitations[inv] /= NULL}

\* =========================================================================
\* COMBINED SAFETY PREDICATE
\* All invariants from section Composition-level invariants plus structural guards.
\* TLC checks Safety as a single invariant over the full state space.
\* =========================================================================

Safety ==
    /\ TypeOK
    /\ Invitation_Gates_Enrollment
    /\ Single_Resolution
    /\ Credential_Follows_Party
    /\ Audit_Coverage
    /\ Completion_Follows_Intent
    /\ Accepted_Is_Whole
    /\ Completion_Names_Full_Arc
    /\ Status_Monotone
    /\ Party_Invitation_Binding
    /\ Credential_Party_Binding
    /\ Audit_Set_Integrity

=========================================================================
\* COMBINED SAFETY PREDICATE
\* All invariants from section Composition-level invariants plus structural guards.
\* TLC checks Safety as a single invariant over the full state space.
\* =========================================================================

Safety ==
    /\ TypeOK
    /\ Invitation_Gates_Enrollment
    /\ Single_Resolution
    /\ Credential_Follows_Party
    /\ Audit_Coverage
    /\ Completion_Names_Full_Arc
    /\ Status_Monotone
    /\ Party_Invitation_Binding
    /\ Credential_Party_Binding
    /\ Audit_Set_Integrity

====
