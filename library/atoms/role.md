---
title: Role
id: 74
audience: common
has_toc: true
toc: true
---

# Role

<details markdown="block">
<summary>Table of contents</summary>
{: .text-xs .font-medium .uppercase .tracking-wide .opacity-50 }
1. TOC
{:toc}
</details>

## What it is

Role lets a business name sets of allowed actions — member, moderator, admin — and put people in them. Asking whether a person may take an action answers allow or deny from the roles the person holds, where the read answers, and nothing else: an action no role lists is denied, always. Putting a person in a role and taking the person out are themselves actions, so only someone whose own roles allow it can do either, and doing either twice changes nothing. A business may switch on a parent for a role, so a moderator allows everything a member allows. Every grant and every removal is kept with who did it and when. Who the person is, what a person may do to one particular item, roles that run out on their own, and the roles a new person starts with each belong to another pattern, which is why one role list serves a forum, a shop's staff and a team's workspace alike.

<details markdown="block">
<summary>WHY</summary>

Giving each person each permission one at a time works for a handful of people and fails for a community: a forum with a thousand members needs to say "moderators may hide posts" once. This atom is that and nothing more. Three decisions carry the weight. Deny is the default and cannot be switched off: an action listed by no role a person holds is denied under every setting, so a missing line is never a hole. An ask only reads: it answers from the holdings as they stand, reads no clock and writes nothing, and where its read answers it answers allow or deny, a failed read answering state-unavailable (Execution Contract Read 1), so every page can gate on it the same way. And granting and removing a role are actions the table itself governs, so who may hand out power is written in the same place as everything else, and the very first holders come from onboarding, outside the atom. A permission is read once, at the ask: an action already allowed finishes even if the role is taken away mid-way, and the next ask denies.

</details>

## What it keeps

### The holdings

```
Identity 1: The atom MUST identify a holding by the holding's holding id.
Identity 2: The atom MUST NOT normalize a person reference.
Identity 3: The atom MUST compare two person references codepoint for codepoint.
Identity 4: The atom MUST compare two role names codepoint for codepoint.
Identity 5: The atom MUST compare two action names codepoint for codepoint.
```

Term holding: one person in one role, from a grant, kept after the person leaves the role — a [Holding].

Term granter reference: the person reference of the person who calls [Grant] or [Revoke] — a [Granter Reference].

Term role name: the name a call or a holding gives a role, held in the role table or not, such as moderator — a [Role Name].

Term action name: the name a call gives an action, listed by a role or not, such as hide-post — an [Action Name].

Term allowed actions: the action names a role lists, together with, where the hierarchy is on, the allowed actions of the role's parent role, an action name listed more than once counted once.

```
State 1: EVERY holding MUST carry holding id, person reference, role name, granter reference, granted instant and status.
State 2: EVERY holding MUST stand in EXACTLY ONE OF held, revoked.
State 3: EVERY revoked holding MUST carry a revoker reference AND a revoked instant.
State 4: The atom MUST NOT remove a holding.
```

Term status: where a holding stands, held or revoked — the [Status].

Term held: the status of a holding the person keeps — [Held]; the holding counts in an ask.

Term revoked: the status of a holding the person left — [Revoked]; the holding counts in no ask.

Term granted instant: the instant of the [Grant] call that recorded the holding — the [Granted Instant].

Term revoker reference: the person reference of the person whose [Revoke] stood the holding in revoked — the [Revoker Reference].

Term revoked instant: the instant of the [Revoke] call that stood the holding in revoked — the [Revoked Instant].

#### Holding

One person in one role: recorded by [Grant], stood in [Revoked] by [Revoke]; never removed by the atom.

Kind: Type

#### Decision

What [Ask] answers where its read answers: allow or deny; a failed read answers state-unavailable (Execution Contract Read 1).

Kind:       Type
Projection: decision

#### Holding Id

Names one holding, supplied by the host at the seam for the [Grant] that records it; never changed.

Kind:       Field
Field of:   Holding
Projection: holding_id

#### Person Reference

Names the person a holding belongs to, in the deployment's own scheme. Stored as supplied and compared codepoint for codepoint.

Kind:       Field
Field of:   Holding
Projection: person_reference

#### Role Name

The name of the role a holding is in or a call names, spelled as the role table spells it where the table holds the role.

Kind:       Field
Field of:   Holding
Projection: role_name

#### Action Name

The name of an action a call asks about or a role allows, spelled as the role table spells it where a role lists it; an action the table lists nowhere is denied.

Kind:       Type
Projection: action_name

#### Granter Reference

The person reference of the person whose [Grant] recorded the holding; never changed.

Kind:       Field
Field of:   Holding
Projection: granter_reference

#### Granted Instant

The instant of the [Grant] that recorded the holding, stamped from the injected now; never changed.

Kind:       Field
Field of:   Holding
Projection: granted_instant

#### Revoker Reference

The person reference of the person whose [Revoke] stood the holding in revoked; never changed.

Kind:       Field
Field of:   Holding
Projection: revoker_reference

#### Revoked Instant

The instant of the [Revoke] that stood the holding in revoked, stamped from the injected now; never changed.

Kind:       Field
Field of:   Holding
Projection: revoked_instant

#### Status

Where a holding stands: [Held] or [Revoked].

Kind:       Field
Field of:   Holding
Projection: status

#### Held

The status of a holding the person keeps; it counts in every [Ask].

Kind:       Member
Member of:  the status
Projection: held

#### Revoked

The status of a holding the person left; it counts in no ask and never changes again.

Kind:       Member
Member of:  the status
Projection: revoked

Term decision: what [Ask] answers where its read answers, allow or deny — a [Decision].

Term holding id: the string the host supplies at the seam for the [Grant] that records a holding — a [Holding Id].

Term person reference: the string naming a person, in the deployment's own scheme — a [Person Reference]; the atom reads no scheme in it.

## What people do

### Every action

```
Operation 1: IF the person reference EQUALS blank OR the person reference EXCEEDS the string cap THEN a holding action MUST answer invalid-person-reference.
Operation 2: IF the granter reference EQUALS blank OR the granter reference EXCEEDS the string cap THEN a holding action MUST answer invalid-person-reference.
Operation 3: IF the role name is malformed OR the role table holds no role carrying the role name THEN a holding action MUST answer invalid-role.
Operation 6: IF the self-grant EQUALS off AND the granter reference EQUALS the person reference THEN a holding action MUST answer not-authorized.
Operation 14: A holding action MUST answer ok.
Operation 20: A reading action MUST NOT write.
Operation 22: IF the person reference OR the granter reference is malformed THEN a holding action MUST answer invalid-person-reference (Execution Contract Input 1).
```

Term holding action: [Grant] | [Revoke] — the actions that change a holding.

Term reading action: [Ask] | [Look Up] | [Look Up Role] — the actions that change nothing.

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect |
|---|---|---|---|
| a holding action | the granter's roles do not allow the act, or no role anywhere does | [Not Authorized] | none (Operation 4, Operation 5) |
| a holding action | self-grant off and the granter names themself | [Not Authorized] | none (Operation 6) |
| a holding action | the role table holds no such role, or the role name is not a string | [Invalid Role] | none (Operation 3) |
| a holding action | a reference blank, over the string cap, or not a string | [Invalid Person Reference] | none (Operation 1, Operation 2, Operation 22) |
| any writing call | database refuses the write | [Storage Failure] | none (Execution Contract Read 4) |
| any call | its read of the database fails | `state-unavailable` | none (Execution Contract Read 1, Execution Contract Read 3) |
| any call | more than one refusal applies | the refusal listed first on the action's refuses line | none (Execution Contract Refusal 1) |

- `grant("bo", "", "member")` — rejected as [Invalid Person Reference]: the reference is blank.
- `grant("bo", "ada", "king")` — rejected as [Invalid Role]: the role table holds no king.
- `grant("ada", "cy", "member")` — rejected as [Not Authorized]: Ada's roles do not allow grant.
- `grant("bo", "bo", "member")` — rejected as [Not Authorized]: self-grant is off.
- `ask("cy", "launch-rockets")` — answers deny: an action listed nowhere is denied.

This covers every refusal but [Storage Failure], which answers when the database refuses a write.

#### Invalid Person Reference

The refusal of a blank person or granter reference, one over the string cap, or one that is not a string (Operation 1, Operation 2, Operation 22).

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: invalid-person-reference

#### Invalid Role

The refusal of a [Role Name] the role table does not hold, or that is not a string (Operation 3).

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: invalid-role

#### Not Authorized

The refusal of a [Grant] or a [Revoke] whose granter's roles do not allow the act, or that names the granter themself with self-grant off (Operation 4 through 6).

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: not-authorized

#### Storage Failure

The refusal a writing call answers when the database refuses its write after every precondition passes: the Execution Contract's Step 3 failure.

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: storage-failure

### Grant

#### Grant

Puts a person in a role: records a [Holding] in [Held], with the [Granter Reference] and the [Granted Instant], where the person holds no such role; refused where the granter's own roles do not allow grant. A role already held is left as it is. Answers ok.

Kind: Operation

```
grant(granter_reference, person_reference, role_name)
  answers ok
  refuses invalid-person-reference | invalid-role | not-authorized | storage-failure
```

```
Operation 4: IF no held holding of the granter reference names a role whose allowed actions carry the action name grant THEN [Grant] MUST answer not-authorized.
Operation 7: IF no held holding EXISTS for the person reference AND the role name THEN [Grant] MUST record EXACTLY ONE holding carrying the holding id supplied at the seam, the person reference, the role name AND the granter reference of the call.
Operation 8: IF no held holding EXISTS for the person reference AND the role name THEN [Grant] MUST stamp granted instant from the injected now.
Operation 9: IF no held holding EXISTS for the person reference AND the role name THEN [Grant] MUST stand the holding in held.
Operation 10: IF a held holding EXISTS for the person reference AND the role name THEN [Grant] MUST NOT write.
```

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect |
|---|---|---|---|
| [Grant] | the granter's roles allow grant, the role exists, the person holds no such role | ok | one holding lands, held, with the granter and now (Operation 7 through 9) |
| [Grant] | the person already holds the role | ok | none, no write (Operation 10) |
| [Grant] | the person held the role once and was revoked | ok | a new holding lands; the old one stays revoked (Operation 7 through 9, State 4) |

### Revoke

#### Revoke

Takes a person out of a role: stands the held [Holding] in [Revoked], with the [Revoker Reference] and the [Revoked Instant]; refused where the granter's own roles do not allow revoke. A role not held is left as it is. Answers ok.

Kind: Operation

```
revoke(granter_reference, person_reference, role_name)
  answers ok
  refuses invalid-person-reference | invalid-role | not-authorized | storage-failure
```

```
Operation 5: IF no held holding of the granter reference names a role whose allowed actions carry the action name revoke THEN [Revoke] MUST answer not-authorized.
Operation 11: IF a held holding EXISTS for the person reference AND the role name THEN [Revoke] MUST stand the holding in revoked.
Operation 12: IF a held holding EXISTS for the person reference AND the role name THEN [Revoke] MUST stamp the revoker reference from the granter reference AND the revoked instant from the injected now.
Operation 13: IF no held holding EXISTS for the person reference AND the role name THEN [Revoke] MUST NOT write.
```

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect |
|---|---|---|---|
| [Revoke] | the granter's roles allow revoke, the person holds the role | ok | the holding stands revoked, with the revoker and now; nothing removed (Operation 11, Operation 12) |
| [Revoke] | the person does not hold the role | ok | none, no write (Operation 13) |

### Ask

#### Ask

Answers a [Decision], allow or deny, for one person and one [Action Name], from the held holdings and the role table alone; reads no clock and writes nothing.

Kind: Operation

```
ask(person_reference, action_name)
  answers decision
```

```
Operation 15: IF a held holding of the person reference names a role whose allowed actions carry the action name THEN [Ask] MUST answer allow.
Operation 16: IF no held holding of the person reference names a role whose allowed actions carry the action name THEN [Ask] MUST answer deny.
Operation 21: [Ask] MUST NOT read now.
Operation 23: IF the person reference is malformed OR the person reference EQUALS blank OR the person reference EXCEEDS the string cap THEN [Ask] MUST answer deny (Execution Contract Query 5).
Operation 24: IF the action name is malformed OR the action name EQUALS blank THEN [Ask] MUST answer deny (Execution Contract Query 5).
```

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect |
|---|---|---|---|
| [Ask] | a role the person holds allows the action, directly or through a parent role | allow | none (Operation 15) |
| [Ask] | no role the person holds allows the action, the person holds no role, the action is listed nowhere, or a reference is bad | deny | none (Operation 16, Operation 23, Operation 24) |

### Look Up

#### Look Up

Answers every [Role Name] one person holds now, and changes nothing.

Kind: Operation

```
look_up(person_reference)
  answers roles(role_name)
```

```
Operation 17: [Look Up] MUST answer the role name of EVERY held holding carrying the person reference, in the order of Execution Contract Logic confinement 10.
Operation 25: IF the person reference is malformed OR the person reference EQUALS blank OR the person reference EXCEEDS the string cap THEN [Look Up] MUST answer an empty list (Execution Contract Query 5).
```

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect |
|---|---|---|---|
| [Look Up] | any | the roles the person holds | none (Operation 17, Operation 25) |

### Look Up Role

#### Look Up Role

Answers every [Action Name] one role allows, its parent role's included where the hierarchy is on, and changes nothing.

Kind: Operation

```
look_up_role(role_name)
  answers actions(action_name)
```

```
Operation 18: [Look Up Role] MUST answer the allowed actions of the role carrying the role name, in the order of Execution Contract Logic confinement 10.
Operation 19: IF the role name is malformed OR the role table holds no role carrying the role name THEN [Look Up Role] MUST answer an empty list.
```

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect |
|---|---|---|---|
| [Look Up Role] | any | the role's allowed actions; an empty list for no such role or a role name that is not a string | none (Operation 18, Operation 19) |

### Read Holding

#### Read Holding

Answers one holding by its [Holding Id] and changes nothing: its holding id, person reference, role name, granter reference, granted instant, status and, once revoked, revoker reference and revoked instant. It is the read an app's key check makes on a holding id (Bonds Key 26).

Kind: Operation

```
read_holding(holding_id)
  answers holding
  refuses not-known
```

```
Operation 30: [Read Holding] MUST answer the holding's holding id, person reference, role name, granter reference, granted instant, status AND, for a revoked holding, the revoker reference and the revoked instant.
Operation 31: IF no holding carries the holding id OR the holding id is malformed THEN [Read Holding] MUST answer not-known.
Operation 32: [Read Holding] MUST NOT write.
```

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect |
|---|---|---|---|
| [Read Holding] | a holding carries the holding id | the holding, every field | none (Operation 30, Operation 32) |
| [Read Holding] | the holding id is malformed or names no holding | [Not Known] | none (Operation 31) |

#### Not Known

The refusal [Read Holding] answers where the holding id is malformed or names no holding (Operation 31). Nothing is written.

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: not-known

## What is and what should never be (Invariants)

- **Invariant 1 — Deny is the default.**
  ```
  Invariant 1.1: [Ask] MUST NOT answer allow for an action name the allowed actions of no role the person holds carry.
  ```
- **Invariant 2 — A person holds a role once or not at all.**
  ```
  Invariant 2.1: Two held holdings MUST NOT share a person reference AND a role name.
  ```
- **Invariant 3 — A grant or a removal, once landed, is a fact.**
  ```
  Invariant 3.1: The atom MUST NOT change a holding's person reference.
  Invariant 3.2: The atom MUST NOT change the status of a revoked holding.
  Invariant 3.3: The atom MUST NOT change a holding's role name.
  Invariant 3.4: The atom MUST NOT change a holding's granter reference.
  Invariant 3.5: The atom MUST NOT change a holding's granted instant.
  Invariant 3.6: The atom MUST NOT change a holding's revoker reference.
  Invariant 3.7: The atom MUST NOT change a holding's revoked instant.
  Invariant 3.8: The atom MUST NOT change a holding's holding id.
  ```

## When something happens

### Concurrency

Two [Grant] calls for one person and one role are serialized (Execution Contract Database 2): the later meets the earlier's held holding and writes nothing, so the person holds the role once. A [Revoke] that lands while an action the person was allowed is running does not stop the action: the permission is read once, at the ask, and the next [Ask] denies. A compensable-workflow pattern reads a permission the same way; a difference between the two pages is a finding on one of them.

### Indeterminate outcome

A caller whose answer is lost may call again, and the repeat is a second call (Execution Contract Error model 1). A repeated [Grant] or [Revoke] where the first landed writes nothing and answers ok. [Ask], [Look Up] and [Look Up Role] write nothing and may be repeated freely.

### A role table that changes

A deployment that removes an action from a role, or a role from the table, changes every [Ask] after the instance's next start (Execution Contract Logic confinement 17): the holdings stand, and an action no role now lists is denied. A holding of a role the table no longer holds counts in no ask and can still be revoked only by adding the role back, so a deployment retiring a role revokes its holdings first, if it wants none stranded, and gives each of its child roles another parent role or none, as Capability requirement 10 requires.

### What undoes a write

[Revoke] undoes [Grant], and a new [Grant] undoes a [Revoke] with a new holding; the old holding stays as the record of what happened (Execution Contract Undo 4).

## Optional

```
Capability requirement 1: The deployment MUST supply the database PER Execution Contract Database 1 through 7, Execution Contract Read 1 through 6, Execution Contract Refusal 1, Execution Contract Input 1 and Execution Contract Query 5.
Capability requirement 2: The deployment MUST supply now at the seam PER Execution Contract Logic confinement 11.
Capability requirement 3: The deployment MUST declare the role table PER Execution Contract Logic confinement 17.
Capability requirement 4: The deployment MAY declare the hierarchy PER Execution Contract Logic confinement 17.
Capability requirement 5: The deployment MAY declare the self-grant PER Execution Contract Logic confinement 17.
Capability requirement 6: The deployment MAY declare the string cap PER Execution Contract Input 2 and Execution Contract Logic confinement 17.
Capability requirement 7: The deployment MUST NOT normalize a person reference at the seam.
Capability requirement 8: The deployment MUST NOT declare a role table in which a role is the role's own parent role through any chain of parent roles.
Capability requirement 9: The deployment MUST supply at the seam a holding id no holding has carried PER Execution Contract Logic confinement 3.
Capability requirement 10: The deployment MUST NOT declare a role table in which a role names a parent role the role table does not hold.
```

Term role table: the deployment's declaration of every role, each role's action names and, where the hierarchy is on, each role's parent role.

Term parent role: the role a role inherits from, where the hierarchy is on; a role allows every action the role's parent role allows.

Term hierarchy: the deployment's setting for parent roles, on or off; off where a deployment declares none.

Term self-grant: the deployment's setting for whether a person may grant or revoke a role for the person's own person reference, on or off; off where a deployment declares none.

Term string cap: the bound on a person reference's length in Unicode code points; 1,024 code points where a deployment declares none.

Term seam: the atom's input and output boundary as the section titled Logic Confinement Principle in `execution-contract.md` declares it; the host injects the clock reading, now, and the holding id at the seam.

## Offers

The bond this atom offers, of a bond kind [Bonds](../bonds.md) states.

Term offer key: key holding id; carried by holdings; calls Read Holding.

## Left to others

```
Non-goal 1: The atom MUST NOT tell who a person is.
Non-goal 2: The atom MUST NOT allow an action on one particular item.
Non-goal 3: The atom MUST NOT end a holding on a clock.
Non-goal 4: The atom MUST NOT choose the roles a new person starts with.
Non-goal 5: The atom MUST NOT name the first holders of grant.
Non-goal 6: The atom MUST NOT hold a person's job in a thing.
```

NOTE: the owners — an attestation pattern and a session pattern (Non-goal 1); the app's permission for one person and one item, a bearer-token pattern for an outsider holding a link (Non-goal 2); a lease pattern (Non-goal 3); an onboarding pattern and the forthcoming Forum, which seeds the deployment (Non-goal 4, 5); a tenure pattern, whose "role" is a person's position in a customer, a deal or a club, not a set of allowed actions (Non-goal 6).

Where the atom breaks down: a permission on one item — this post, this cart — which is the app's permission; a right that anyone holding a link may use, which is a bearer-token pattern's.

```
Composition note 1: A composing pattern MUST own what this atom declines.
Composition note 2: A composing pattern MUST supply the granter reference of the caller the composing pattern authenticated.
Composition note 3: A composing pattern MUST call [Ask] once per action, at the start of the action.
```

NOTE: composing patterns — none yet. Forthcoming: Forum, Moderation.

## Example

The same pattern in two domains, then the rejection paths.

### Forum

A photo forum, its hierarchy on, declares two roles: member allows post and comment; moderator has member as its parent role and adds hide-post, grant and revoke. Bo holds moderator; Ada holds member; Cy holds nothing. Bo calls `grant("bo", "ada", "moderator")`: ok, and a second identical call answers ok and writes nothing. `ask("cy", "hide-post")` answers deny: Cy holds no role. `ask("ada", "hide-post")` answers allow, and `ask("ada", "post")` answers allow through member, the parent role. Bo revokes Ada's moderator while Ada's hide is running: the hide finishes, and Ada's next `ask("ada", "hide-post")` answers deny.

### Shop staff

A shop declares cashier and manager, the hierarchy off. Only manager lists grant. A cashier tries to make a friend a manager: [Not Authorized]. The manager tries to make herself an owner the table does not hold: [Invalid Role].

## Source

Role is a primitive with no regulatory anchor. It inherits from:

- **Daniel Jackson, *The Essence of Software*** — the concept as a freestanding, composable unit of software design.
- **Sandhu, Coyne, Feinstein and Youman, "Role-Based Access Control Models,"** IEEE (Institute of Electrical and Electronics Engineers) Computer, 1996, and the NIST (National Institute of Standards and Technology) standard built on it, ANSI (American National Standards Institute) INCITS 359-2004 — roles as named sets of permissions, people assigned to roles, and an optional role hierarchy.

---

## Proof

### Generation acceptance

Acceptable when the checks below are provable to an external auditor from the holdings the database holds, with their earlier versions, and the role table (Execution Contract Database 5, Execution Contract Generation acceptance 1). The atom is not regulated and carries no adversarial scenarios.

#### Conformance checks

```
Check 1.1: An auditor MUST find EVERY holding carrying holding id, person reference, role name, granter reference, granted instant AND status (State 1).
Check 1.2: An auditor MUST find EVERY holding standing in EXACTLY ONE OF held, revoked (State 2).
Check 1.3: An auditor MUST find EVERY revoked holding carrying a revoker reference AND a revoked instant (State 3).
Check 2.1: An auditor MUST find no two held holdings sharing a person reference AND a role name (Invariant 2.1).
Check 3.1: An auditor MUST find EVERY version of a holding carrying the holding id, person reference, role name, granter reference AND granted instant of the holding's first version (Invariant 3.1, Invariant 3.3 through 3.5, Invariant 3.8).
Check 3.2: An auditor MUST find EVERY version of a holding later than a revoked version standing in revoked AND carrying the revoker reference AND the revoked instant of the revoked version (Invariant 3.2, Invariant 3.6, Invariant 3.7).
Check 4.1: An auditor replaying [Ask] over the holdings AND the role table MUST find no allow for an action name the allowed actions of no held role carry (Invariant 1.1).
```

Term version: a record as it stood at the commit that wrote it, which Execution Contract Database 5 keeps readable after the record changes and Execution Contract Generation acceptance 1 has a check read.

NOTE: EVERY check names the rule the check tests. Invariant 1.1 and Operation 15 never meet: [Ask] answers allow only where a held role's allowed actions carry the action name (advisory read by hand).

### Vocabulary

Each `[Term]` marker above links to its term entry here; a term entry states what the concept *is* and its **Kind**.

Term actors: the atom; the host; the deployment (also: a deployment); a composing pattern; the database; a holding; a holding action; a reading action; an auditor.

Term records: holding — one person in one role, carrying holding id, person reference, role name, granter reference, granted instant, status and, once revoked, revoker reference and revoked instant.

Term record verbs: identify, normalize, compare, carry, stand, remove, supply, declare, record, stamp, answer, change, write, read, share, find, tell, allow, end, choose, name, hold, own, call, replay.

Term value sets: holding action and reading action are declared above and cited here (GRACE-lang Closed vocabulary 15); status — held | revoked; decision — allow | deny; hierarchy — on | off; self-grant — on | off; action rejection — invalid-person-reference | invalid-role | not-authorized | storage-failure.

Term bounds: string cap (the bound on a person reference's length in Unicode code points, 1,024 where a deployment declares none).

Term cadences: empty.

Term qualifiers: migrated — drafted in GRACE lang (2026-11-18) through the Grace connector, from GLM's rough draft.

Term terms: holding, holdings, holding id, person reference, granter reference, role name, role names, action name, action names, role table, parent role, allowed actions, hierarchy, self-grant, string cap, seam, status, held, revoked, granted instant, revoker reference, revoked instant, holding action, reading action, decision, version.

<!-- Term registry — shortcut-reference definitions. These produce no visible
     output; each resolves a [Term] marker to its term entry heading above. -->

[Grant]: #grant
[Revoke]: #revoke
[Ask]: #ask
[Look Up]: #look-up
[Look Up Role]: #look-up-role
[Read Holding]: #read-holding
[Not Known]: #not-known
[Holding]: #holding
[Holding Id]: #holding-id
[Decision]: #decision
[Person Reference]: #person-reference
[Role Name]: #role-name
[Action Name]: #action-name
[Granter Reference]: #granter-reference
[Granted Instant]: #granted-instant
[Revoker Reference]: #revoker-reference
[Revoked Instant]: #revoked-instant
[Status]: #status
[Held]: #held
[Revoked]: #revoked
[Invalid Person Reference]: #invalid-person-reference
[Invalid Role]: #invalid-role
[Not Authorized]: #not-authorized
[Storage Failure]: #storage-failure

---

## Status

`doing` — see the Ledger.

<details markdown="block">
<summary>
    <h2 id="ledger" style="display: inline-block; margin-left: 1.5rem;">Ledger</h2>
</summary>

```
status: doing
formal: pending — no model yet
last gate: 2026-11-19 — Final Critique 3, a delta round, one reader (Linus claude-sonnet-5-5), frozen at 7e7453c4 — foundational count 0 after the blind second triage, clean, one sample; Linus's report claimed 0 foundational, 3 refining, 1 rhetorical, and the blind triage agreed on the count (its press of Final Critique 2's cure, Capability requirement 10 and the paragraph on a role table that changes, found no two builds that diverge); refining cured: Capability requirement 10 reads a role that names a parent role the role table does not hold, so a role with no parent role is a lawful root, a retiring role's children take another parent role or none, and the revoke-first clause is a deployment's own practice stated as such and cites the rule that requires the reparent (the blind triage refuted the clause's finding as a state the page names and explains); rhetorical left (counts in no ask is Term held and Term revoked's own idiom); 2026-11-19 — Final Critique 2, a delta round, one reader (Linus opencode/beam-free), frozen at bcecf938 — foundational count 1, cured by the settle, not clean, no sample; Linus's first foundational kept Kind A by the first triage (Opus 5.5 decided it): Capability requirement 8 forbade only a parent cycle, so a role table whose role named a parent the table does not hold left Term allowed actions without an answer, and one build let the missing parent add nothing where another refused the call, for [Ask], [Look Up Role] and the grant and revoke checks alike; cured as the finder proposed in a requirement of its own (Capability requirement 10, so Capability requirement 8 gains no `or`), less its clause on a parent that is not a string, which cannot name a role the table holds (Identity 4), and the paragraph on a role table that changes now has a retiring deployment reparent the role's children; its second foundational (Operation 22 against the [Ask] and [Look Up] rows) refuted by Term holding action, which lists [Grant] and [Revoke] only, so Operation 23 and Operation 25 answer a malformed reference there; its three refining items refuted or owed no cure (Term hierarchy and Term reading action define what the reader said was undefined, and an empty list for an unknown role and for a role with no actions are both defined); 2026-11-18 — Final Critique 1, frozen at 66927df3 — foundational count 7, cured by the settle, not clean, no sample

open: none
```

</details>

<details markdown="block">
<summary>
    <h2 id="decisions" style="display: inline-block; margin-left: 1.5rem;">Decisions</h2>
</summary>

- **2026-11-18 — From GLM's rough draft, drafted through the Grace connector mirroring Reaction.** *Chose:* GLM's shape — a role table the deployment declares, holdings with who and when, an ask that only reads and answers allow or deny, deny by default under every setting, grant and revoke governed by the same table, an optional parent role and an optional self-grant. *Over:* resolving roles into Permissions grants, as the forum sketch first had it. *Because:* an atom stands alone; Permissions answers for one person on one item and Role for a whole class of action, and the composing pattern chooses which to ask. Changed from the rough draft: the first holders and a new person's roles go to External Onboarding, not Customer Onboarding; a cycle in parent roles is refused when the deployment declares the table, since the table is the deployment's and grant never writes it; Tenure is named so its other sense of "role" stays apart.

</details>

NOTE: End of Role.
