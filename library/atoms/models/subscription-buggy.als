-- subscription-buggy.als
-- Deliberately broken twin of subscription.als for the Grace Commons harness.
--
-- WHAT IS BROKEN
-- The fact `AtMostOneActivePerKey` — Invariant 6, at most one Active subscription per
-- (subscriber_ref, event_scope) pair — is REMOVED: subscribe no longer refuses a second
-- Active subscription for a pair (already-subscribed), so two Active records can share
-- a pair. Rebuilt 2026-11-10 from the current subscription.als (its checks had drifted).
--
-- BREAKS: A_NoDualActiveForSameKey (two Active records for one pair).

module subscription_buggy

open util/integer

-- ─────────────────────────────────────────────────────────────────────────────
-- Signatures (types / record fields)
-- ─────────────────────────────────────────────────────────────────────────────

-- Status enum: the two states from the spec state machine.
abstract sig Status {}
one sig Active, Cancelled extends Status {}

-- Opaque reference types. Alloy generates instances freely; the atom treats
-- subscriber_ref and event_scope as opaque identifiers (exact match only).
abstract sig SubscriptionId  {}
abstract sig SubscriberRef   {}
abstract sig EventScope      {}

-- The subscription record. Fields mirror the spec's State section exactly.
-- "lone" = 0 or 1 (nullable in the spec: cancelled_at is absent while Active).
-- "one"  = always present.
sig SubscriptionRecord {
    sub_id        : one SubscriptionId,   -- opaque immutable system-generated id (Inv 1, 5)
    subscriber    : one SubscriberRef,    -- who holds the subscription, immutable (Inv 1)
    event_scope   : one EventScope,       -- what class of events, immutable (Inv 1)
    subscribed_at : one Int,              -- wall-time when recorded, immutable (Inv 1, 9)
    status        : one Status,           -- Active | Cancelled (Inv 2)
    cancelled_at  : lone Int              -- absent while Active; set on cancel (Inv 9)
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Structural well-formedness facts
-- (Alloy treats facts as always true for all instances — they define the valid
--  configuration space. Assertions below check that nothing in this space
--  violates the named invariants.)
-- ─────────────────────────────────────────────────────────────────────────────

-- Invariant 5: No id reuse.
-- No two subscription records share a subscription_id across the system's lifetime.
fact NoIdReuse {
    all disj r1, r2 : SubscriptionRecord | r1.sub_id != r2.sub_id
}

-- Invariant 6: At most one Active subscription per (subscriber_ref, event_scope) pair.
-- A second subscribe for a pair with an existing Active subscription is rejected as
-- already-subscribed; the atom enforces this structurally.
-- BUG: fact AtMostOneActivePerKey is removed (see the header).

-- Invariant 2 / 9: Status-field consistency.
-- cancelled_at is absent iff Active; present iff Cancelled.
-- (Invariant 2: Active → Cancelled is the only direction; enforced structurally.)
fact CancelledAtConsistency {
    all r : SubscriptionRecord | {
        r.status = Active    implies no  r.cancelled_at
        r.status = Cancelled implies one r.cancelled_at
    }
}

-- Invariant 9: Timestamp ordering (best-effort — see spec Edge cases).
-- For any Cancelled subscription, subscribed_at <= cancelled_at.
fact TimestampOrdering {
    all r : SubscriptionRecord |
        r.status = Cancelled implies r.subscribed_at <= r.cancelled_at
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Assertions
-- (Each "check" asks: is there any configuration satisfying the facts but
--  violating this assertion? UNSAT = the guarantee holds. SAT = spec finding.)
-- ─────────────────────────────────────────────────────────────────────────────

-- Invariant 5 is assumed by fact NoIdReuse. The checks A_NoIdReuse and A_IdsDistinctAcrossStatuses
-- restated that fact word for word, so no twin could break them; they went 2026-11-10.

-- Invariant 6 is assumed by fact AtMostOneActivePerKey. The check A_AtMostOneActivePerKey restated
-- that fact word for word; it went 2026-11-10. A_NoDualActiveForSameKey, below, states the rule
-- pairwise, and subscription-buggy.als (which drops the fact) breaks it.

-- A_CancelledHasCancelledAt: Structural half of Invariant 2 / 3.
-- Every Cancelled record carries a cancelled_at timestamp.
assert A_CancelledHasCancelledAt {
    all r : SubscriptionRecord |
        r.status = Cancelled implies one r.cancelled_at
}
check A_CancelledHasCancelledAt for 6

-- A_ActiveHasNoCancelledAt: Counterpart — Active records never have cancelled_at.
assert A_ActiveHasNoCancelledAt {
    all r : SubscriptionRecord |
        r.status = Active implies no r.cancelled_at
}
check A_ActiveHasNoCancelledAt for 6

-- Invariant 9 is assumed by fact TimestampOrdering. The check A_TimestampOrdering restated that
-- fact word for word, so no twin could break it; it went 2026-11-10.

-- A_CancelledKeyCanCoexistWithActive: Invariant 4 / 6 interaction.
-- Two records for the same (subscriber, scope) can coexist only when one is
-- Cancelled and the other is Active (the cancel-then-resubscribe case).
-- Stated contrapositively: two records for the same key cannot both be Active.
assert A_NoDualActiveForSameKey {
    all disj r1, r2 : SubscriptionRecord |
        (r1.subscriber = r2.subscriber and r1.event_scope = r2.event_scope)
            implies not (r1.status = Active and r2.status = Active)
}
check A_NoDualActiveForSameKey for 6

-- ─────────────────────────────────────────────────────────────────────────────
-- Satisfiability runs
-- (Confirm the configuration space is non-empty. SAT = non-vacuous.
--  UNSAT = a fact over-constrains the model — must be fixed.)
-- ─────────────────────────────────────────────────────────────────────────────

-- At least one Active subscription exists.
run ShowOneActive {
    some r : SubscriptionRecord | r.status = Active
} for 3 but 3 Int

-- At least one Cancelled subscription exists.
run ShowOneCancelled {
    some r : SubscriptionRecord | r.status = Cancelled
} for 3 but 3 Int

-- Both statuses coexist in the same store.
run ShowActiveAndCancelled {
    some disj r1, r2 : SubscriptionRecord | {
        r1.status = Active
        r2.status = Cancelled
    }
} for 4 but 3 Int

-- Cancel-then-resubscribe (Invariant 4): the same (subscriber, scope) pair has one
-- Cancelled record and one new Active record with a DISTINCT sub_id.
-- This is the key cancel-and-resubscribe scenario the spec describes.
run ShowCancelThenResubscribe {
    some disj old_rec, new_rec : SubscriptionRecord |
    some s : SubscriberRef | some e : EventScope | {
        -- old subscription was cancelled
        old_rec.subscriber  = s
        old_rec.event_scope = e
        old_rec.status      = Cancelled
        -- new subscription is Active for the same pair
        new_rec.subscriber  = s
        new_rec.event_scope = e
        new_rec.status      = Active
        -- the two records have distinct ids (Invariant 4 / 5)
        old_rec.sub_id != new_rec.sub_id
    }
} for 4 but 3 Int

-- Two subscribers, same scope, both Active — a valid fanout scenario.
-- Confirms the model allows multiple Active records for DIFFERENT subscribers
-- on the same scope (needed for subscribers_for to return a list).
run ShowTwoActiveSubscribersForSameScope {
    some disj r1, r2 : SubscriptionRecord |
    some e : EventScope | {
        r1.status      = Active
        r2.status      = Active
        r1.event_scope = e
        r2.event_scope = e
        r1.subscriber != r2.subscriber   -- different subscribers
        r1.sub_id     != r2.sub_id       -- distinct ids
    }
} for 4 but 3 Int

-- Active subscription: a single Active record with no cancelled_at.
run ShowActiveNoCancelledAt {
    some r : SubscriptionRecord | {
        r.status = Active
        no r.cancelled_at
    }
} for 3 but 3 Int

-- Cancelled subscription: a Cancelled record with cancelled_at >= subscribed_at.
run ShowCancelledWithTimestamp {
    some r : SubscriptionRecord | {
        r.status = Cancelled
        r.cancelled_at >= r.subscribed_at
    }
} for 3 but 3 Int
