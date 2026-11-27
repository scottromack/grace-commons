---
title: Shared Todo as an app
audience: common
nav_exclude: true
---

# Shared Todo as an app

<details markdown="block">
<summary>Table of contents</summary>
1. TOC
{:toc}
</details>

## What it is

Shared Todo is an app: an author sends a set of to-dos to a team, in the author's order of priority, and the team sees them, claims them and checks them off; the first check-off wins and who did it is saved. It is built from ten atoms wired by their own need and offer lines, one bond instance and two counted lines of glue. It is the first app in the bond shape; the composition [Shared Todo](../../compositions/shared-todo.md) stays as it stands, the frozen reference, until the review of this page.

<details markdown="block">
<summary>WHY</summary>

The app is the 1.0 target (Scott, 2026-11-21 to 2026-11-25): one whole app built from the tree, end to end. Every need of its atoms but one meets exactly one offer of its atoms, so the bonds form and the app writes nothing for them ([Bonds](../../bonds.md), Bond 8); the one need that meets several offers is the one bond the app writes (Bond 7). What no atom or bond carries yet is the glue below, counted, each line tagged with its exit.

</details>

## Jobs

Each job has one acceptance check, the test that says the app does it.

1. **Hand out work in priority order.** Check: the team reads the list in the author's order.
2. **Know who is on what.** Check: a claimed task shows its assignee; a reassign keeps the history; a reassign to someone the list is not shared with is refused.
3. **Know what is done and by whom.** Check: a completed task shows its completer and stays crossed out a week; a second check-off is refused.
4. **Keep it the author's list.** Check: a non-author's rename, delete list, add, edit, reorder, delete, recall, reassign or invite is refused.

Two answers settle what the jobs leave open (Scott, 2026-11-25 7:15 PM Central):

- **No reopen.** A done task is a recorded fact with a week's display life (the window of one week that read list passes to [Task](../../atoms/task.md)'s Read): a second check-off is refused, and the journal keeps who completed it. The app offers no reopen.
- **The author alone recalls or reassigns a claim.** The author may take a claim back ([Assignment](../../atoms/assignment.md)'s Recall For Task) or give it to someone the list is shared with (its Reassign, through its Active For; App check 2), and the history is kept; a non-author may do neither, and a reassign to someone the list is not shared with is refused. Reassign is an author action, not a glue line.

## Atoms

Ten, each used as it stands:

- **[Task](../../atoms/task.md)** — the tasks of a list: add, edit, complete, delete; mints the task id; saves the completer.
- **[List](../../atoms/list.md)** — makes a list, mints its list id, holds its name and its author.
- **[Ordering](../../atoms/ordering.md)** — one list's sequence: the author's order of priority, a new task at the bottom.
- **[Assignment](../../atoms/assignment.md)** — who is on a task: assign, recall, reassign, with its history.
- **[Permissions](../../atoms/permissions.md)** — who may do what on a list: grant, revoke, permitted.
- **[Invitation](../../atoms/invitation.md)** — bringing a person into a list: initiate, accept, decline.
- **[Actor Identity](../../atoms/actor-identity.md)** — who someone is; offers the actor id the app's actions carry.
- **[Session](../../atoms/session.md)** — who is calling; mints the session id.
- **[Credential](../../atoms/credential.md)** — the proof checked at sign-in.
- **[Event Log](../../atoms/event-log.md)** — the history: the journal of task, assignment and invitation events.

Not in the app (the design of 2026-11-24): Capability (Permissions covers sharing), Party Identity (a team is a Permissions group in the first version), Restorable Delete (Task's plain delete in the first version). Four calls of the atoms are left to no action of this version, on purpose: Actor Identity's Mint Actor Id and Credential's Register (the actor id and the credential of a person who signs in are provisioned outside the app, and the app takes an actor id as given; each such actor id is minted by Actor Identity's Mint Actor Id outside the app's actions, on the one Actor Identity instance the app's actor id needs meet (Bonds Bond 9)), Permissions' Revoke (a grant is never taken back: a member stays a member until the list is deleted) and Invitation's Revoke (a pending invitation ends by accept, decline, its expiry or the deletion of its list).

## Bonds

Bond kinds are [the bonds page](../../bonds.md)'s, one source; this app names the one instance it writes and defines no kind.

The [connector diagram](./connections.md) draws these bonds and the glue below, generated from the atoms' need and offer lines and never drawn by hand.

Every need of the ten atoms but one meets exactly one offer of the ten, and that offer serves it with nothing written (Bond 8): the list id needs by List's offer, the actor id needs by Actor Identity's, and Assignment's task id need by Task's. The three journal needs, Task's, Assignment's and Invitation's, each meet the one journal offer, Event Log's, so the one Event Log serves all three with nothing written, each need's records in a stream of its own (Bond 8, Bond 9 and journal 8). Permissions' follow-up need meets one follow-up offer of the ten, Invitation's accept, so an accept answering accepted is followed by Permissions' Grant of the accepting identity on the scope the invitation offers, in the accept's transaction, with nothing written (Bonds Follow-up 1, Follow-up 3, Bond 8). Ordering's item need is keyed on `opaque`, so it meets every key offer of the app's atoms (list id, task id, actor id, session id): an ambiguous need, served by the one instance below.

```
Bond instance 1: Ordering's key need that pairs entries MUST be served by Task's key offer of task id (Bonds Bond 7).
```

Cascades written: none. Delete list reads the list's task ids by Ordering's Read Order inside its own transaction (Execution Contract Database 1). The sequence holds every task of the list, the done tasks past Task's one-week window included, since add task places each task it adds and no action of the app takes an entry out but through a task's deletion. Delete list then calls Task's Delete of each id. Each Delete ends its task id, so Ordering's Remove Item Everywhere (through Bond instance 1) and Assignment's Recall For Task run with that id (Bonds Key 3). It then calls List's Delete List, which ends the list id, so Task's Delete List Tasks (finding no task, it answers ok and writes nothing, Bonds Key 7), Ordering's Remove List Sequence and Invitation's Revoke List Invitations run. The read supplies only the app's own calls of Task's Delete, never an on end call (Bonds Key 6, Execution Contract Atom interface 1), and the tasks are deleted one by one ahead of Delete List because Task's Delete List Tasks answers no task id. The app action's one transaction spans the read, every call and every on end call, so the cascade needs no glue line (Bonds Key 3, Key 4).

Not ended by deleting a list: the grants on it, since the permission scope is opaque, not a key. A grant on a deleted list reaches nothing: App check 3 answers `not-known` on it, every other action the grant admits finds no list, task or entry to act on, and the list id is never minted again (Bonds Key 16).

### The app's permission need

The app's gate is one rule set, stated as the app's own need line (Bonds Bond 13, Term app page need): the author may do everything on their list; anyone the list is shared with may read it, claim and complete, nothing else. The scope a check asks for is a list id paired with one of two standings, `author` or `member`, written as the list id, a colon and the standing (`<list id>:author`), the same bytes in every grant and every check; making a list gives its maker both, and accepting an invitation to it gives `member`: invite offers the scope `member` of the list, and the follow-up on accept grants it (Bonds Follow-up 1).

Term need permission: subject actor id; scope opaque; actions rename list, delete list, add task, edit task, move task, delete task, recall, reassign, invite, read list, claim, complete; calls permitted; arms permitted, denied.

```
App permission 1: rename list, delete list, add task, edit task, move task, delete task, recall, reassign and invite MUST be gated on the scope `author` of the list the action is on.
App permission 2: read list, claim and complete MUST be gated on the scope `member` of the list the action is on.
App permission 3: make list, accept, decline, sign in and sign out MUST NOT be gated.
App permission 4: The host MUST supply EVERY list id at a length that, with the 7 code points of the colon and the standing added, DOES NOT EXCEED Permissions' string cap AND DOES NOT EXCEED Invitation's string cap.
```

Make list's grant is an effect of the generated action, not a gate: once List's Make List answers, make list calls Permissions' Grant of `author` and `member` on the new list to the caller, and no check is asked before it (App permission 3).

The subject of every check is the caller (Bonds permission 3), the actor id that [Session](../../atoms/session.md)'s Validate answers for the call's session. Every input that names the acting party (the author, the inviter, the completer, the accepting identity, the revoker, and the assignee a claim binds) is that same actor id, never a value the call carries (Bonds Key 19); the subject of the grant that follows an accept is the accepting identity Invitation's Accept answers, so it is that actor id too (Bonds Follow-up 2). One value the call carries is no acting party: a reassign's new assignee, which App check 2 admits only where it answers permitted. App check 2 is a call of Permissions' Check in reassign's flow after the gate, as make list's Grant is a call, and no permission check of the app's need: the gate of reassign is App permission 1's, asked of the caller (Bonds permission 2, Bonds permission 3).

### The app's checks and answers

An action that acts on a task names its task id and the list id of its gate, and the gate is asked of that list. Edit task, delete task, claim, complete, recall and reassign each run App check 1 right after the gate and before any call to an atom's action; Task's Read of the list is the existence read of the task id (Bonds Key 21 to Key 26). Reassign runs App check 2 right after App check 1: the new assignee must be someone the list is shared with. Add task, invite and read list run App check 3 right after the gate and before any call to an atom's action, since the list id they carry is a key the app's write or read meets (Bonds Key 21). Move task needs none: Ordering's Move Item refuses unknown-item for a task its list's sequence does not hold.

```
App check 1: edit task, delete task, claim, complete, recall and reassign MUST confirm, in the action's one transaction, that Task's Read of the list id the call carries, with a window of one week (Term one week), answers the task id, and MUST answer `not-known` and commit nothing where it does not.
App check 2: reassign MUST confirm, in the action's one transaction, that Permissions' Check of the new assignee's actor id on the scope `member` of the list the call carries answers permitted, and MUST answer `denied` and commit nothing where it does not.
App check 3: add task, invite and read list MUST confirm, in the action's one transaction, that List's Read List of the list id the call carries answers the list, and MUST answer `not-known` and commit nothing where it answers none (Bonds Key 21, Bonds Key 24; Execution Contract Refusal 3).
App answer 1: an action called with a session whose Validate answers invalid MUST answer invalid with Validate's failure as it stands, MUST call no atom's action and MUST commit nothing.
App answer 2: sign in, where Credential's Verify answers failed-verification, MUST answer failed-verification with Verify's failure as it stands and MUST call no Session action.
```

Term one week: the window the app passes to Task's Read, 604800 seconds (seven days of 86400 seconds each, no calendar and no timezone); a done task lies inside it where its completion instant does not precede now by more than that, the instant exactly one week back included (Task's Read; Execution Contract Query 2).

A done task past its week stands on no list the app reads, so every action that runs App check 1 answers `not-known` on it, a second check-off included (refused either way). Task's Add still counts such a task in the active set of its list, so add task of its description answers `duplicate-active` while it stands, and only delete list ends it. Every other answer of an action is the answer of the atom's call that gave it, each rejection passed through unchanged (Execution Contract Constituent failure 1 to Constituent failure 3), with `denied` for a failed gate and for a reassign App check 2 refuses, Check's own answer.

## Glue

Two lines, counted. Each carries its birth tag and leaves by promoting, demoting or dying (the glue rule of 2026-11-23). A third, accept grants, left by demoting: it is the follow-up bond (Bonds Follow-up), written in the unit `bonds: the follow-up bond kind, accept grants first` (Scott, 2026-11-27 11:17 AM Central).

```
sign in: Credential's Verify, answering verified for a principal, MUST be followed by Session's Issue for that principal, the app's name `shared todo` as the issue's issued_by_ref, in the same app action. {birth: atom candidate}
claim: claim MUST be Assignment's Assign whose assignee is the caller. {birth: bond candidate}
```

Sign-in waits for Login to be split into atoms; claim waits for a bond that carries the caller as a value.

## Actions

The app's API (application programming interface), generated, never written by hand. Every action but sign in is called with a session, and is gated as the permission need says.

| Action | Atoms' actions it calls |
|---|---|
| make list | List's Make List with the caller as author; Permissions' Grant of `author` and `member` on the new list to the caller |
| rename list | List's Rename List |
| delete list | Ordering's Read Order of the list, then Task's Delete of each task id it answers (the on end calls of each follow), then List's Delete List (the on end calls follow), in the one transaction |
| add task | App check 3, then Task's Add; Ordering's Place Item, the new task at the bottom |
| edit task | App check 1, then Task's Edit |
| move task | Ordering's Move Item, the place counted in the sequence Ordering's Read Order gives, the done tasks past the week included |
| delete task | App check 1, then Task's Delete (the on end calls follow) |
| claim | App check 1, then Assignment's Assign, the caller as assignee (Glue, claim) |
| recall | App check 1, then Assignment's Recall For Task |
| reassign | App check 1, then App check 2, then Assignment's Active For of the task id, then Assignment's Reassign of the assignment it answers (`not-known` where it answers none) |
| complete | App check 1, then Task's Complete, the caller as completer |
| invite | App check 3, then Invitation's Initiate, the caller as inviter, the list id as its context, the scope `member` of the list (`<list id>:member`) as its offered scope |
| accept | Invitation's Accept, the caller as accepting identity; Permissions' Grant follows it, of the accepting identity on the offered scope Accept answers (Bonds Follow-up 1, Follow-up 2) |
| decline | Invitation's Decline |
| sign in | Credential's Verify, then Session's Issue (Glue, sign in; App answer 2) |
| sign out | Session's Revoke of the call's session, the caller as revoked_by_ref, the reason `signed out` |
| read list | List's Read List (App check 3), Ordering's Read Order, Task's Read with a window of one week (Term one week), Assignment's Active For and History For of each task answered; the answer carries the tasks Task's Read answered, each with its active assignment, its history and its place in the sequence Ordering's Read Order gives, the done tasks past the week counted, in that order, and no entry Task's Read did not answer |

Invite passes Invitation's Initiate no invitee and no ttl, so the ttl is Invitation's default, which the deployment declares (the capability Invitation states for it); a deployment that declares none answers every invite `invalid-request`, Initiate's own refusal. Sign in passes Session's Issue no session duration, so the duration is Session's default session duration, which the deployment declares; a deployment that declares none answers every sign in `invalid-request`, Issue's own refusal.

Task, Assignment and Invitation each append their events to the one Event Log, each in a stream of its own, as their journal needs say; the app writes nothing for it.

## Status

`todo` — written by the unit `app: to-do` (2026-11-25, ruled by Scott 7:11 to 7:15 PM Central from the draft of his session); it pauses for his design review of the app page form before another app page is written. The unit `bonds: the follow-up bond kind, accept grants first` (2026-11-27) replaced the glue line accept grants with the follow-up bond: invite offers the scope `member` of the list, and Permissions' Grant follows Invitation's Accept with nothing written. No render here: TARGET.md and CORNERS.md come with the render unit.

last gate: 2026-11-27 — Final Critique 3, a delta round, one reader (Linus anthropic/claude-sonnet-5-5), frozen at 7bee90c7 — foundational count 5, not clean, no sample (the list id keys a write and a read of the app that no action checked, so add task and invite on a deleted list wrote an orphan and read list had no answer: App check 3 answers not-known, and the grants on a deleted list reach nothing through it; App check 2's new-assignee check read as a permission check whose subject was not the caller, so the page says it is a call and no check of the need; a scope the host builds from a list id could outrun Permissions' string cap, so App permission 4 bounds the list id; the actor id's key check has no existence read on Actor Identity's offer, which the page cannot cure: its page-only half is the minting statement, and the read is Needs Scott; refining cured: move task counts its place in the sequence the done tasks past the week are in and read list answers each task's place, a done task past its week blocks its description's re-add which only delete list ends, accept reads the invitation's context before it grants, App check 1 and 2 run in the action's one transaction, sign in's default session duration is the deployment's; refining older, already under Needs Scott: a done task within its week still admits claim, recall, reassign and move; refuted: a retried make list, invite or sign in makes a second record on every build, and Duplicate Prevention owns the job); last gate: 2026-11-27 — Final Critique 2, a delta round, one reader (Linus opencode/beam-free), frozen at 00ef299b — foundational count 2, both cured, not clean, no sample (the party-input sentence forbade every carried id while a reassign's new assignee is one, so the sentence names the acting party and says the one carried value; the week of Task's Read window was stated in no unit, so Term one week gives it as 604800 seconds with both ends in; one finding placed refining: claim, recall, reassign and move task on a done task within its week all admit, which no rule decides, filed under Needs Scott; refining cured: App check 1 names the six actions that run it, and invite's default ttl is the deployment's; two refuted: recall with no active assignment answers ok as Assignment's Recall For Task does, and read list's omission of an entry Task's Read did not answer is stated in its row; rhetorical wordings left); 2026-11-26 — Final Critique 1, a full round (GRID opencode-go/glm-5.3-flash, EOS opencode-go/minimax-m3, Linus opencode-go/mimo-v2.6-pro), frozen at da9bc143 — foundational count 7 after the triage, not clean; the cures are in this text and the page's next round is a delta round. The tools read atoms and compositions only, so no tool has read this page.

NOTE: End of Shared Todo as an app.
