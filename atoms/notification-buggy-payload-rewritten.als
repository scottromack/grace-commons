-- notification-buggy-payload-rewritten.als
-- DELIBERATELY WRONG twin of notification.als (unit: every check has a twin that breaks it).
--
-- INJECTED DEFECT: deliver does not carry the payload through — it stores what the
-- transport rendered over the original payload (Invariant 1: a notification's
-- recipient_ref and payload are immutable).
--
-- BREAKS: A_Trans_ImmutableFieldsPreserved.

module notification_buggy_payload_rewritten

-- ─────────────────────────────────────────────────────────────────────────────
-- Status enum
-- Four named states from the spec (the section titled *State* in notification.md).
-- ─────────────────────────────────────────────────────────────────────────────

abstract sig Status {}
-- Pending: created, delivery not yet confirmed, failed, or expired.
one sig Pending extends Status {}
-- Delivered: transport confirmed receipt. Terminal.
one sig Delivered extends Status {}
-- Failed: delivery attempted, definite negative outcome. Terminal.
one sig Failed extends Status {}
-- Expired: delivery window elapsed with no recorded outcome. Terminal.
one sig Expired extends Status {}

-- Convenience function: the three terminal statuses.  Used in assertions.
fun terminals : set Status { Delivered + Failed + Expired }

-- ─────────────────────────────────────────────────────────────────────────────
-- Opaque reference types
-- The atom treats these as opaque; Alloy generates instances freely.
-- ─────────────────────────────────────────────────────────────────────────────

abstract sig NotificationId {}  -- opaque, immutable, system-generated (Inv 5)
abstract sig RecipientRef {}    -- who the notification is addressed to
abstract sig Payload {}         -- what is being communicated (opaque)

-- Abstract timestamp marker.  We only care about presence/absence; actual
-- wall-clock ordering is out of scope for this structural snapshot model.
abstract sig Timestamp {}

-- ─────────────────────────────────────────────────────────────────────────────
-- The notification record
-- Mirrors the State section of the spec.
-- "one" = exactly one value (always present).
-- "lone" = zero or one (nullable in the spec; 0 or 1).
-- ─────────────────────────────────────────────────────────────────────────────

sig NotificationRecord {
    -- Immutable identity and creation fields (Invariants 1, 5)
    notification_id : one NotificationId,
    recipient_ref   : one RecipientRef,
    payload         : one Payload,
    -- Mutable status field; advances only forward (Invariant 2)
    status          : one Status,
    -- Terminal timestamps; at most one present per record (Invariants 3, 4).
    delivered_at    : lone Timestamp,
    failed_at       : lone Timestamp,
    expired_at      : lone Timestamp
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Store sig: snapshot of the live notification set.
-- Store-level facts (uniqueness, well-formedness) apply within one snapshot.
-- ─────────────────────────────────────────────────────────────────────────────

sig Store {
    records : set NotificationRecord
}

-- Invariant 6: within one store, no two records share a notification_id.
fact StoreIdUniqueness {
    all s : Store |
        all disj r1, r2 : s.records |
            r1.notification_id != r2.notification_id
}

-- Invariants 3 + 4: every record in any store satisfies timestamp-status coherence.
-- delivered_at present iff Delivered; failed_at iff Failed; expired_at iff Expired.
fact TimestampStatusCoherence {
    all r : NotificationRecord | {
        (one r.delivered_at) iff r.status = Delivered
        (one r.failed_at)    iff r.status = Failed
        (one r.expired_at)   iff r.status = Expired
    }
}

-- Timestamp atoms are only reachable via NotificationRecord fields.
-- Prevents free-floating Timestamp atoms from satisfying assertions vacuously.
fact TimestampsAreUsed {
    all t : Timestamp | some r : NotificationRecord |
        r.delivered_at = t or r.failed_at = t or r.expired_at = t
}

-- Every NotificationRecord belongs to at least one Store.
-- This keeps the store and record layers connected.
fact RecordsInStores {
    all r : NotificationRecord | some s : Store | r in s.records
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Transition predicates
-- Pre/post record pairs modeling valid state changes.
-- These are predicates, NOT facts — Alloy does not assume they hold globally.
-- Pre and post represent the same logical notification before and after an action;
-- they are allowed to share a notification_id (they represent successive states
-- of one record, not two co-resident store entries).
-- ─────────────────────────────────────────────────────────────────────────────

-- deliver: Pending → Delivered.
-- Precondition: pre must be in Pending (spec: rejected(not-pending) otherwise).
-- Immutable fields carry through unchanged (Invariant 1 + Invariant 5).
pred deliver[pre, post : NotificationRecord] {
    -- precondition
    pre.status = Pending
    -- immutable fields preserved
    post.notification_id = pre.notification_id
    post.recipient_ref   = pre.recipient_ref
    -- BUG: the payload is not carried through
    -- status advances to Delivered
    post.status = Delivered
    -- exactly delivered_at is set; others absent
    one post.delivered_at
    no  post.failed_at
    no  post.expired_at
}

-- fail: Pending → Failed.
-- Identical preconditions to deliver; different terminal state.
pred fail[pre, post : NotificationRecord] {
    pre.status = Pending
    post.notification_id = pre.notification_id
    post.recipient_ref   = pre.recipient_ref
    post.payload         = pre.payload
    post.status = Failed
    no  post.delivered_at
    one post.failed_at
    no  post.expired_at
}

-- expire: Pending → Expired.
-- Identical preconditions to deliver and fail; different terminal state.
pred expire[pre, post : NotificationRecord] {
    pre.status = Pending
    post.notification_id = pre.notification_id
    post.recipient_ref   = pre.recipient_ref
    post.payload         = pre.payload
    post.status = Expired
    no  post.delivered_at
    no  post.failed_at
    one post.expired_at
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Assertions
-- Each "check" asks: is there any configuration satisfying the facts but
-- violating this assertion?  UNSAT = guarantee holds.  SAT = spec finding.
-- ─────────────────────────────────────────────────────────────────────────────

-- ── Invariant 2: Status monotonicity ────────────────────────────────────────

-- A notification in any terminal state cannot be deliver-transitioned.
assert A_Inv2_TerminalNotDeliverable {
    all pre, post : NotificationRecord |
        pre.status in terminals implies not deliver[pre, post]
}
check A_Inv2_TerminalNotDeliverable for 6

-- A notification in any terminal state cannot be fail-transitioned.
assert A_Inv2_TerminalNotFailable {
    all pre, post : NotificationRecord |
        pre.status in terminals implies not fail[pre, post]
}
check A_Inv2_TerminalNotFailable for 6

-- A notification in any terminal state cannot be expire-transitioned.
assert A_Inv2_TerminalNotExpirable {
    all pre, post : NotificationRecord |
        pre.status in terminals implies not expire[pre, post]
}
check A_Inv2_TerminalNotExpirable for 6

-- No inter-terminal transition: Delivered cannot move to Failed.
assert A_Inv2_DeliveredNotFailable {
    all pre, post : NotificationRecord |
        pre.status = Delivered implies not fail[pre, post]
}
check A_Inv2_DeliveredNotFailable for 6

-- No inter-terminal transition: Failed cannot move to Delivered.
assert A_Inv2_FailedNotDeliverable {
    all pre, post : NotificationRecord |
        pre.status = Failed implies not deliver[pre, post]
}
check A_Inv2_FailedNotDeliverable for 6

-- All transitions require Pending as precondition (combined form).
assert A_Inv2_AllTransitionsRequirePending {
    all pre, post : NotificationRecord | {
        deliver[pre, post] implies pre.status = Pending
        fail[pre, post]    implies pre.status = Pending
        expire[pre, post]  implies pre.status = Pending
    }
}
check A_Inv2_AllTransitionsRequirePending for 6

-- ── Invariant 3: Terminal states are exclusive ───────────────────────────────

-- No notification has more than one terminal timestamp set simultaneously.
assert A_Inv3_AtMostOneTerminalTimestamp {
    all r : NotificationRecord | {
        not (one r.delivered_at and one r.failed_at)
        not (one r.delivered_at and one r.expired_at)
        not (one r.failed_at    and one r.expired_at)
    }
}
check A_Inv3_AtMostOneTerminalTimestamp for 6

-- A Delivered record has delivered_at and neither of the other two.
assert A_Inv3_DeliveredHasOnlyDeliveredAt {
    all r : NotificationRecord |
        r.status = Delivered implies
            (one r.delivered_at and no r.failed_at and no r.expired_at)
}
check A_Inv3_DeliveredHasOnlyDeliveredAt for 6

-- A Failed record has failed_at and neither of the other two.
assert A_Inv3_FailedHasOnlyFailedAt {
    all r : NotificationRecord |
        r.status = Failed implies
            (no r.delivered_at and one r.failed_at and no r.expired_at)
}
check A_Inv3_FailedHasOnlyFailedAt for 6

-- An Expired record has expired_at and neither of the other two.
assert A_Inv3_ExpiredHasOnlyExpiredAt {
    all r : NotificationRecord |
        r.status = Expired implies
            (no r.delivered_at and no r.failed_at and one r.expired_at)
}
check A_Inv3_ExpiredHasOnlyExpiredAt for 6

-- A Pending record has none of the three terminal timestamps.
assert A_Inv3_PendingHasNoTimestamps {
    all r : NotificationRecord |
        r.status = Pending implies
            (no r.delivered_at and no r.failed_at and no r.expired_at)
}
check A_Inv3_PendingHasNoTimestamps for 6

-- ── Invariant 4: Timestamp-status coherence (biconditional) ─────────────────

-- delivered_at is present iff status is Delivered.
assert A_Inv4_DeliveredAtIffDelivered {
    all r : NotificationRecord |
        (one r.delivered_at) iff r.status = Delivered
}
check A_Inv4_DeliveredAtIffDelivered for 6

-- failed_at is present iff status is Failed.
assert A_Inv4_FailedAtIffFailed {
    all r : NotificationRecord |
        (one r.failed_at) iff r.status = Failed
}
check A_Inv4_FailedAtIffFailed for 6

-- expired_at is present iff status is Expired.
assert A_Inv4_ExpiredAtIffExpired {
    all r : NotificationRecord |
        (one r.expired_at) iff r.status = Expired
}
check A_Inv4_ExpiredAtIffExpired for 6

-- ── Transition correctness assertions ────────────────────────────────────────

-- deliver transition produces a Delivered post-record.
assert A_Trans_DeliverProducesDelivered {
    all pre, post : NotificationRecord |
        deliver[pre, post] implies post.status = Delivered
}
check A_Trans_DeliverProducesDelivered for 6

-- fail transition produces a Failed post-record.
assert A_Trans_FailProducesFailed {
    all pre, post : NotificationRecord |
        fail[pre, post] implies post.status = Failed
}
check A_Trans_FailProducesFailed for 6

-- expire transition produces an Expired post-record.
assert A_Trans_ExpireProducesExpired {
    all pre, post : NotificationRecord |
        expire[pre, post] implies post.status = Expired
}
check A_Trans_ExpireProducesExpired for 6

-- Transitions preserve immutable fields (notification_id, recipient_ref, payload).
assert A_Trans_ImmutableFieldsPreserved {
    all pre, post : NotificationRecord | {
        deliver[pre, post] implies {
            post.notification_id = pre.notification_id
            post.recipient_ref   = pre.recipient_ref
            post.payload         = pre.payload
        }
        fail[pre, post] implies {
            post.notification_id = pre.notification_id
            post.recipient_ref   = pre.recipient_ref
            post.payload         = pre.payload
        }
        expire[pre, post] implies {
            post.notification_id = pre.notification_id
            post.recipient_ref   = pre.recipient_ref
            post.payload         = pre.payload
        }
    }
}
check A_Trans_ImmutableFieldsPreserved for 6

-- ── Invariant 6: Store-level id uniqueness ────────────────────────────────────

-- Invariant 6 is assumed by fact StoreIdUniqueness. The check A_Inv6_StoreIdUniqueness restated
-- that fact word for word, so no twin could break it; it went 2026-11-10.

-- ─────────────────────────────────────────────────────────────────────────────
-- Satisfiability runs (non-vacuity guards)
-- Each run must return at least one instance (SAT).
-- ─────────────────────────────────────────────────────────────────────────────

-- Each lifecycle state is individually reachable.
run ShowPending {
    some r : NotificationRecord | r.status = Pending
} for 4

run ShowDelivered {
    some r : NotificationRecord | r.status = Delivered
} for 4

run ShowFailed {
    some r : NotificationRecord | r.status = Failed
} for 4

run ShowExpired {
    some r : NotificationRecord | r.status = Expired
} for 4

-- All four states coexist in one store snapshot.
run ShowAllFourStatuses {
    some s : Store |
    some disj r1, r2, r3, r4 : s.records | {
        r1.status = Pending
        r2.status = Delivered
        r3.status = Failed
        r4.status = Expired
    }
} for 6

-- A valid deliver transition: a pre-record in Pending and a post-record in Delivered.
run ShowDeliverTransition {
    some pre, post : NotificationRecord |
        deliver[pre, post]
} for 6

-- A valid fail transition: Pending → Failed.
run ShowFailTransition {
    some pre, post : NotificationRecord |
        fail[pre, post]
} for 6

-- A valid expire transition: Pending → Expired.
run ShowExpireTransition {
    some pre, post : NotificationRecord |
        expire[pre, post]
} for 6

-- Two independent notifications for the same recipient (different ids) in one store.
run ShowTwoNotificationsOneRecipient {
    some s : Store |
    some disj r1, r2 : s.records | {
        r1.recipient_ref = r2.recipient_ref
        r1.notification_id != r2.notification_id
        r1.status = Pending
        r2.status = Delivered
    }
} for 6
