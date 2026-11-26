---
title: Invitation — history
nav_exclude: true
search_exclude: true
---

# Invitation — history

The dated record of how [Invitation](./invitation.md) got here, moved out of the spec on 2026-10-20 because a reader does not need it to use the spec today. The spec keeps every section `spec-format.md` requires and its `Deleted:` tombstones; everything smaller is in `git log -- atoms/invitation.md`.

## Decisions

Entries that record a migration rather than a turn the pattern took.

- **2026-06-21 — Expiry is derived at read time, never stored; this atom is the corpus's worked reference for the move.** *Chose:* the stored `Expired` state, the `expired_at` field and the `expire` action are removed; `Expired` is a read-time projection over the immutable expiry instant and the injected clock. *Over:* a stored terminal a scheduler or a lazy write has to reach. *Because:* an invitation's lapse is side-effect-free, so a status that can be inferred at read time should be, and a flag that lags the clock is the idealization pitfall the methodology names. [Provisional Commitment](./provisional-commitment.md)'s 2026-06-23 entry is the boundary from the other side: its lapse returns a resource, so its expiry stays a written transition.

- **2026-09-13 — The window boundary is declared once as a window reading, in the same two-member shape [Provisional Commitment](./provisional-commitment.md) uses.** *Chose:* live | lapsed, with the boundary instant declared onto the lapsed side, cited by the three resolving-write guards and by the effective-status projection. *Over:* repeating the comparison at each guard, which is how the prose carried it. *Because:* a spec pays for a proposition once (GRACE-lang Authority 3), and the arithmetic belongs in the declaration rather than in a rule (Hard invariant 24). The two atoms name the members differently — `open` there, live here — because the record differs; the *shape* being identical across two independent specs is a new instance of the absence-as-nonexistence class the grammar's watch list counts, and is flagged rather than unified, since nothing yet says a shared reading should have one owner.

- **2026-09-13 — The family is resolving write, not `resolving action`, and the difference from [Provisional Commitment](./provisional-commitment.md) is meant.** *Chose:* resolving write — [Accept], [Decline], [Revoke]. *Over:* `resolving action`, which is the name the same concept carries one atom over. *Because:* this atom has a [Read], so *action* would include a surface that resolves nothing and writes nothing, and the whole of the derived-expiry posture is that reading and writing are different things here. Provisional Commitment has no read, so nothing there needs the narrower word. The names diverge because the records do; a reader crossing between them should not assume the drift is carelessness (council read 39).

- **2026-09-13 — Single-resolution is stated as at-most-one, and the at-least-one half is `Non-goal 24`.** *Chose:* `Invariant 2.1` and `Invariant 2.2` alone. *Over:* a rule reading *exactly one write resolves an invitation*. *Because:* an invitation nobody answers is never written and reads expired forever, which is the designed outcome and not a stuck state — so *at least one* would be false here rather than merely unenforceable. Same decomposition [Provisional Commitment](./provisional-commitment.md) took, reached from the opposite direction.

- **2026-10-20 — The store's guarantees cited, not restated.** *Chose:* the invitation store supplied under Execution Contract Store 1 through 4 (Capability requirement 12), and the eleven rules that restated them tombstoned to their owner — Operation 34 and Invariant 3.2, a resolving write's status change and recorded fields committed in one transition, Invariant 10.2, no partial invitation on storage-failure, and Atomic writes 1, 3 and 4, a transition committed whole inside the implementation's transactional boundary and no repair of a dangling one, to Store 1; Atomic writes 2, an uncommitted transition discarded whole, to Store 1 and Store 3; Capability requirement 7, a write acknowledged only once it commits, to Store 3; Concurrency 1, the status check and the status change of a resolving write as one operation, to Store 1 and Store 2; Concurrency 2 and 3, the losing resolving write answering already-resolved and naming the stored terminal the winner committed, to Store 2; rules 172 to 162. *Over:* the atom restating, for its own store, what every deployment's store guarantees. *Because:* the maintainer ruled 2026-10-12 that the corpus takes a store's specification, never the store, and `execution-contract.md` writes it once as the Store contract. Single-resolution stays the atom's own (Invariant 2.1, Invariant 2.2, Operation 16, Operation 17), as do the store refusing a write carrying a token it holds (Capability requirement 6, Identity 6), a refused write recording nothing and leaving the invitation as the call found it (Operation 22, Operation 37 through 39), and the invitations the atom never removes and the count that never falls (State 13, Invariant 10.1). The effective status is a projection over the expiry instant each invitation carries and now (Invariant 12.2), every check that compares reads compares the auditor's own reads, and no rule orders two invitations' writes, so the atom cites neither History 1 nor Order 1. What the atom does for its domain is unchanged.

- **2026-10-21 — Which refusal answers is the Execution Contract's.** *Chose:* each refuses line kept as the page wrote it, already in the page's order — a resolving write answering not-known, already-resolved, expired, then invalid-request once every status check passes, and storage-failure last, answering only at the write — and the order cited from the Execution Contract (Capability requirement 12, Execution Contract Refusal 1); the pairs that only stated it deleted to Refusal 1: Operation 19 (already-resolved only for a token naming an invitation), Operation 21 (expired only on a pending invitation), Operation 26 (invalid-request only once every status check passes) and Operation 36 (storage-failure behind every precondition); rules 162 to 158. *Over:* the page stating for itself which of an action's refusals answers when several apply. *Because:* the maintainer ruled on 2026-10-21 that the Execution Contract states once that the refusal listed first on an action's refuses line answers. What each action answers on every call is unchanged.

- **2026-10-22 — An admitted call is the Execution Contract's.** *Chose:* the four admitted terms (initiate, accept, decline, revoke) citing Execution Contract Read 4 for what an action admits, in place of the commit clause each carried, so the admitted resolving write they make up reads as before; Read 4 cited on Capability requirement 12; the rule count stays at 156. *Over:* the page stating for itself which calls its effect rules reach. *Because:* the maintainer ruled on 2026-10-22 that five repeated cures are each stated once, the admitted effect among them, which seven atoms had written in one form, this page among them. What each action does and answers is unchanged.

- **2026-10-22 — A lapse is never written, so nothing forbids the deadline; a refused write leaves what it found; one identity may accept more than one invitation.** *Chose:* State 8 and Check 2.2 deleted to Invariant 12.1, under which the atom writes no field when an invitation lapses, with the State WHY naming State 7 and Invariant 12.1; Operation 39 deleted to Operation 37, a refused action leaving the invitation as the call found it; the Disputed onboarding scenario answering every invitation an identity accepted; Non-goal 27, the atom deciding no caller's authority; Operation 3 checking only a supplied ttl, and Capability requirement 4 obliging a default ttl inside the ttl bounds; Operation 10 recording an invitee reference only where one is not blank; the window readings compared with PRECEDES. *Over:* the noun-final pass's rename of `expires_at` to *expiry instant*, the noun State 8 and Check 2.2 had used for a recorded lapse, so that both forbade what State 1 and Check 6.1 require; a rule leaving every refused resolving write's invitation in pending, which an already-resolved refusal cannot; and a scenario reading Invariant 2.1, a bound on one invitation's terminals, as at most one resolved invitation per identity. *Because:* Final Critique 6 found each, and Final Critique 5's text decided the direction: no invitation record carries a stored expired status or an `expired_at` field, and no field is written when an invitation lapses; a refused write leaves the record as it stood; and its rules, like this page's, bound one invitation's resolution and not how many invitations one identity accepts, which its scenario misread the same way. Smaller fixes rode with it, none changing what a rule means: the Summary glosses a bearer token, and the Intent, Term ttl bounds and the Standards references their acronyms; Term invitation and the Invitation entry say resolved by at most one write again; Term value sets declares the effective status; the Now entry names every action that consumes now; Check 1.2 cites a range; and the New employee onboarding example says the record holds the identity the call supplied. Three questions no rule decides are open (2026-10-22-a through c). What each action answers on a well-formed call is unchanged; a blank ttl now reads the default without meeting the bounds check, and a whitespace-only invitee reference is no longer recorded.

- **2026-11-02 — The string cap has a default.** *Chose:* the string cap stated as 1,024 Unicode code points where a deployment declares none, Capability requirement 13 added, citing Execution Contract Input 2. *Over:* a bound the deployment must supply, or silence. *Because:* the maintainer ruled on 2026-11-01 that what the host must bound takes one posture, a corpus default a deployment may override; the string inputs run from references to an invitation context and a revocation reason, and 1,024 code points, the corpus's default for text (Personal Todo's description cap), holds a sentence or two.

- **2026-11-20 — A composing Actor Identity attests the actor behind a revoke, as behind an accept and an initiate.** *Chose:* Composition note 10, "A composing Actor Identity MUST attest the actor behind an admitted revoke"; the read's one clock reading is cited from the Execution Contract (Logic confinement 20) at Invariant 12.2 rather than stated here. *Over:* naming the deployment as the revoke's attestation owner (a revoke records a revoked by reference as an accept records an accepting identity reference, both acting references under Term acting reference, and Non-goal 15 leaves the binding of each to a composing pattern, so the one pattern that binds the other two binds this); stating the clock placement on the page (the contract owns it for every read that answers against now). *Because:* open lines 2026-10-22-c and 2026-11-03-a, closed by the page's own Term acting reference and Non-goal 15 and by Scott's direction of 2026-11-19 (rounds/open-line-choices-directions-3.md, item 132: "the Execution Contract states it once ... every page that carried the line cites it"); a decline records no actor (Non-goal 12) and so needs no attestation.

- **2026-11-20 — The record carries a digest of the token, never the live token.** *Chose:* State 14 and the Terms token digest and token material, with the page's keys (Identity 1, 4, 5 and 6, Capability requirement 6, Operation 15, Invariant 11.1, Check 7.1) reading the digest and Capability requirement 14 asking the deployment for it at the seam; the live token is answered by [Initiate] alone, and a read answers the digest, which a holder cannot present. *Over:* a Term-level clause that left every rule naming the token (EOS), and a rule that stops a read answering the token (Linus), which State 14 makes unnecessary. *Because:* Execution Contract Logic confinement 21 says a record carries a digest of a token, never the live value, and the page's State 1 carried the bearer credential itself, so a caller who read a pending invitation could accept it as their own identity (Final Critique 11: three readers, one finding).

- **2026-11-25 — The atom reorganised into the tree order and bonded: an invitation is to one list, between actor ids, and no pattern is named.** *Chose:* the tree order Task, List and Ordering stand in, every label kept and none renumbered, no rule added; the context is the list id of the list the invitee is invited to join, and the inviter and accepting identity references are actor ids, met by the needs `key list id; pairs invitations` and `key actor id; pairs inviters and accepters`; the journal need records invitation events (Composition note 4 appends one per admitted action); that an accepted invitation grants access to the list is the app's glue line, said in the Needs paragraph; the invitee reference stays opaque, since the invitee has no identity yet; Non-goal 2, 9, 16, 18 and 29 through 32 (each "MUST compose" a named pattern) tombstoned to the Non-goal that owns the declined job; Non-goal 26, Composition note 1 through 3, 6, 7, 9 and 10, External check 3, 4 and 7, Term redemption, Term composing pattern, the WHY, the owners NOTE, an example and the source lines name no pattern. *Over:* an opaque context and opaque references no atom offers, and a page naming eight other patterns. *Because:* Scott's ruling of 2026-11-25 9:49 AM Central ("Go with your 'task'"), the unit `atom: Invitation, bonded`.

- **2026-11-26 — A pending invitation ends with its list: [Revoke List Invitations], the list id need's on end.** *Chose:* one action taking the context alone (Bonds Key 3) that stands in revoked every pending invitation carrying it that reads live, recording the revocation instant alone, one invitation events record for each, and no write where none (Operation 53 through 59, State 15); State 5, Invariant 8.1 and 8.2 and Check 5.1 and 5.2 narrowed to an admitted revoke's invitations, Invariant 1.3 holding the new action to the properties as 1.1 holds a resolving write. Labelled rules 155 before, 164 after, measured before Status. *Over:* a fourth stored terminal, which would change the value sets, the filter and Check 1.2; and a fixed reason with an invented revoked by value, which would attest an actor no call names (Non-goal 15). *Because:* the to-do app's glue walk (unit `execution contract: the app page's sections classified`, 2026-11-26) found a pending invitation outliving its deleted list, and accepting it granted member on a list no record carries. Decided by the mayor under Scott's standing rule "fix findings in the pass that finds them"; Opus decided the record shape. Lapsed invitations are left: they already read expired.

## Migration notes

- **2026-09-13 — Invariant 1.2, tombstoned as a rule that could not bind.** A draft of the migration carried a second rule — *an admitted resolving write MUST NOT change a resolution field the write found* — and it could not bind. An admitted resolving write runs only on a pending invitation (Operation 16 refuses every other case), and a pending invitation carries no resolution field (State 6), so the set the rule quantified over is empty at every reachable state. Same class as the resource return [Provisional Commitment](./provisional-commitment.md) re-homed one atom earlier: a MUST that cannot be violated is decoration, and the cure is to find the rule that already makes it true rather than to keep a second copy that cannot fail (council read 39).

## Deleted rules

The spec's tombstones, moved here from the page on 2026-11-13 because the spec is done (GRACE-lang Hard invariant 25 and Hard invariant 27, since v0.71): each `Deleted:` line byte for byte and in the page's order, under the heading it stood under there. A tombstone carries no obligation, and each still reserves its label: no rule of [Invitation](./invitation.md) may carry it again.

### Structure › Identity model

```
Deleted: Identity 14. Execution Contract Database 7 owns it.
```

### Structure › State

```
Deleted: State 8. Invariant 12.1 owns it.
Deleted: State 13. Invariant 10.1 owns it.
```

### Structure › Capability requirement

```
Deleted: Capability requirement 7. Execution Contract Database 3 owns it.
Deleted: Capability requirement 8. Execution Contract Logic confinement 13 owns it.
Deleted: Capability requirement 10. Execution Contract Logic confinement 7 owns it.
Deleted: Capability requirement 11. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 4. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 1. Execution Contract Logic confinement 3 owns it.
Deleted: Clock semantics 2. Execution Contract Logic confinement 3 owns it.
Deleted: Clock semantics 3. Execution Contract Logic confinement 3 owns it.
Deleted: Clock semantics 5. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 6. Non-goal 25 owns it.
Deleted: Clock semantics 7. Non-goal 26 owns it.
```

### Structure › Operations

```
Deleted: Operation 19. Execution Contract Refusal 1 owns it.
Deleted: Operation 21. Execution Contract Refusal 1 owns it.
Deleted: Operation 22. Execution Contract Read 4 owns it: a refused call writes nothing.
Deleted: Operation 26. Execution Contract Refusal 1 owns it.
Deleted: Operation 34. Execution Contract Database 1 owns it.
Deleted: Operation 36. Execution Contract Refusal 1 owns it.
Deleted: Operation 37. Execution Contract Read 4 owns it: a refused call writes nothing.
Deleted: Operation 38. Execution Contract Read 4 owns it: a refused call writes nothing.
Deleted: Operation 39. Execution Contract Read 4 owns it: a refused call writes nothing.
Deleted: Operation 45. Execution Contract Logic confinement 3 owns it.
Deleted: Operation 46. Execution Contract Logic confinement 3 owns it.
Deleted: Operation 47. Term filter owns it: a filter naming a field whose value is blank matches no invitation.
```

### Structure › Invariants › Invariant 1 — Initiation immutability

```
  Deleted: Invariant 1.2. State 6 and Operation 16 leave a resolving write no resolution field to find.
```

### Structure › Invariants › Invariant 3 — Acceptance binds identity

```
  Deleted: Invariant 3.2. Execution Contract Database 1 owns it.
  Deleted: Invariant 4. Identity 13, State 2 and Operation 6 own the opaque invitee.
```

### Structure › Invariants › Invariant 10 — Invitation durability

```
  Deleted: Invariant 10.2. Execution Contract Database 1 owns it.
```

### Generation acceptance › Conformance checks

```
Deleted: Check 2.2. Invariant 12.1 owns it.
Deleted: Check 8.2. Check 8.1 owns it.
```

### Edge cases › Atomic writes

```
Deleted: Atomic writes 1. Execution Contract Database 1 owns it.
Deleted: Atomic writes 2. Execution Contract Database 1 and Execution Contract Database 3 own it.
Deleted: Atomic writes 3. Execution Contract Database 1 owns it.
Deleted: Atomic writes 4. Execution Contract Database 1 owns it.
```

### Edge cases › Concurrency

```
Deleted: Concurrency 1. Execution Contract Database 1 and Execution Contract Database 2 own it.
Deleted: Concurrency 2. Execution Contract Database 2 owns it.
Deleted: Concurrency 3. Execution Contract Database 2 owns it.
```
