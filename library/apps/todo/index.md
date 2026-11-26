---
title: Shared Todo as an app
audience: common
nav_exclude: true
has_toc: true
toc: true
---

# Shared Todo as an app

<details markdown="block">
<summary>Table of contents</summary>
{: .text-xs .font-medium .uppercase .tracking-wide .opacity-50 }
1. TOC
{:toc}
</details>

## What it is

Shared Todo is an app: an author sends a set of to-dos to a team, in the author's order of priority, and the team sees them, claims them and checks them off; the first check-off wins and who did it is saved. It is built from ten atoms wired by their own need and offer lines, one bond instance and three counted lines of glue. It is the first app in the bond shape; the composition [Shared Todo](../../compositions/shared-todo.md) stays as it stands, the frozen reference, until the review of this page.

<details markdown="block">
<summary>WHY</summary>

The app is the 1.0 target (Scott, 2026-11-21 to 2026-11-25): one whole app built from the tree, end to end. Every need of its atoms but one meets exactly one offer of its atoms, so the bonds form and the app writes nothing for them ([Bonds](../../bonds.md), Bond 8); the one need that meets several offers is the one bond the app writes (Bond 7). What no atom or bond carries yet is the glue below, counted, each line tagged with its exit.

</details>

## Jobs

Each job has one acceptance check, the test that says the app does it.

1. **Hand out work in priority order.** Check: the team reads the list in the author's order.
2. **Know who is on what.** Check: a claimed task shows its assignee; a reassign keeps the history.
3. **Know what is done and by whom.** Check: a completed task shows its completer and stays crossed out a week; a second check-off is refused.
4. **Keep it the author's list.** Check: a non-author's rename, delete list, add, edit, reorder, delete, recall, reassign or invite is refused.

Two answers settle what the jobs leave open (Scott, 2026-11-25 7:15 PM Central):

- **No reopen.** A done task is a recorded fact with a week's display life (the window of one week that read list passes to [Task](../../atoms/task.md)'s Read): a second check-off is refused, and the journal keeps who completed it. The app offers no reopen.
- **The author alone recalls or reassigns a claim.** The author may take a claim back ([Assignment](../../atoms/assignment.md)'s Recall For Task) or give it to someone else (its Reassign, through its Active For), and the history is kept; a non-author may do neither. Reassign is an author action, not a glue line.

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

Not in the app (the design of 2026-11-24): Capability (Permissions covers sharing), Party Identity (a team is a Permissions group in the first version), Restorable Delete (Task's plain delete in the first version). Four calls of the atoms are left to no action of this version, on purpose: Actor Identity's Mint Actor Id and Credential's Register (the actor id and the credential of a person who signs in are provisioned outside the app, and the app takes an actor id as given), Permissions' Revoke (a grant is never taken back: a member stays a member until the list is deleted) and Invitation's Revoke (a pending invitation ends by accept, decline, its expiry or the deletion of its list).

## Bonds

Bond kinds are [the bonds page](../../bonds.md)'s, one source; this app names the one instance it writes and defines no kind.

Every need of the ten atoms but one meets exactly one offer of the ten, and that offer serves it with nothing written (Bond 8): the list id needs by List's offer, the actor id needs by Actor Identity's, and Assignment's task id need by Task's. The three journal needs, Task's, Assignment's and Invitation's, each meet the one journal offer, Event Log's, so the one Event Log serves all three with nothing written, each need's records in a stream of its own (Bond 8, Bond 9 and journal 8). Ordering's item need is keyed on `opaque`, so it meets every key offer of the app's atoms (list id, task id, actor id, session id): an ambiguous need, served by the one instance below.

```
Bond instance 1: Ordering's key need that pairs entries MUST be served by Task's key offer of task id (Bonds Bond 7).
```

Cascades written: none. Delete list reads the list's task ids by Ordering's Read Order inside its own transaction (Execution Contract Database 1). The sequence holds every task of the list, the done tasks past Task's one-week window included, since add task places each task it adds and no action of the app takes an entry out but through a task's deletion. Delete list then calls Task's Delete of each id. Each Delete ends its task id, so Ordering's Remove Item Everywhere (through Bond instance 1) and Assignment's Recall For Task run with that id (Bonds Key 3). It then calls List's Delete List, which ends the list id, so Task's Delete List Tasks (finding no task, it answers ok and writes nothing, Bonds Key 7), Ordering's Remove List Sequence and Invitation's Revoke List Invitations run. The read supplies only the app's own calls of Task's Delete, never an on end call (Bonds Key 6, Execution Contract Atom interface 1), and the tasks are deleted one by one ahead of Delete List because Task's Delete List Tasks answers no task id. The app action's one transaction spans the read, every call and every on end call, so the cascade needs no glue line (Bonds Key 3, Key 4).

Not ended by deleting a list: the grants on it, since the permission scope is opaque, not a key. A grant on a deleted list reaches nothing: List's Read List of that list answers none, and the list id is never minted again (Bonds Key 16).

### The app's permission need

The app's gate is one rule set, stated as the app's own need line (Bonds Bond 13, Term app page need): the author may do everything on their list; anyone the list is shared with may read it, claim and complete, nothing else. The scope a check asks for is a list id paired with one of two standings, `author` or `member`, written as the list id, a colon and the standing (`<list id>:author`), the same bytes in every grant and every check; making a list gives its maker both, and accepting an invitation to it gives `member` (Glue, accept grants).

Term need permission: subject actor id; scope opaque; actions rename list, delete list, add task, edit task, move task, delete task, recall, reassign, invite, read list, claim, complete; calls permitted; arms permitted, denied.

```
App permission 1: rename list, delete list, add task, edit task, move task, delete task, recall, reassign and invite MUST be gated on the scope `author` of the list the action is on.
App permission 2: read list, claim and complete MUST be gated on the scope `member` of the list the action is on.
App permission 3: make list, accept, decline, sign in and sign out MUST NOT be gated.
```

Make list's grant is an effect of the generated action, not a gate: once List's Make List answers, make list calls Permissions' Grant of `author` and `member` on the new list to the caller, and no check is asked before it (App permission 3).

The subject of every check is the caller (Bonds permission 3), the actor id that [Session](../../atoms/session.md)'s Validate answers for the call's session. Every input that names a party (the author, the inviter, the assignee, the completer, the accepting identity, the revoker) is that same actor id, never a value the call carries (Bonds Key 19).

### The app's checks and answers

An action that acts on a task names its task id and the list id of its gate, and the gate is asked of that list. Edit task, delete task, claim, complete, recall and reassign each run App check 1 right after the gate and before any call to an atom's action; Task's Read of the list is the existence read of the task id (Bonds Key 21 to Key 26). Move task needs none: Ordering's Move Item refuses unknown-item for a task its list's sequence does not hold.

```
App check 1: an action that names a task id MUST confirm, in its own transaction, that Task's Read of the list id the call carries, with a window of one week, answers the task id, and MUST answer `not-known` and commit nothing where it does not.
App answer 1: an action called with a session whose Validate answers invalid MUST answer invalid with Validate's failure as it stands, MUST call no atom's action and MUST commit nothing.
App answer 2: sign in, where Credential's Verify answers failed-verification, MUST answer failed-verification with Verify's failure as it stands and MUST call no Session action.
```

A done task past its week stands on no list the app reads, so every action that runs App check 1 answers `not-known` on it, a second check-off included (refused either way). Every other answer of an action is the answer of the atom's call that gave it, each rejection passed through unchanged (Execution Contract Constituent failure 1 to Constituent failure 3), with `denied` for a failed gate.

## Glue

Three lines, counted. Each carries its birth tag and leaves by promoting, demoting or dying (the glue rule of 2026-11-23).

```
sign in: Credential's Verify, answering verified for a principal, MUST be followed by Session's Issue for that principal, the app's name `shared todo` as the issue's issued_by_ref, in the same app action. {birth: atom candidate}
accept grants: Invitation's Accept, answering accepted, MUST be followed by Permissions' Grant of the scope `member` on the invitation's list (its context) to the accepting identity, which is the caller's actor id, in the same app action. {birth: bond candidate}
claim: claim MUST be Assignment's Assign whose assignee is the caller. {birth: bond candidate}
```

Sign-in waits for Login to be split into atoms; the grant on accept waits for the follow-up bond kind, which is not written yet; claim waits for a bond that carries the caller as a value.

## Actions

The app's API (application programming interface), generated, never written by hand. Every action but sign in is called with a session, and is gated as the permission need says.

| Action | Atoms' actions it calls |
|---|---|
| make list | List's Make List with the caller as author; Permissions' Grant of `author` and `member` on the new list to the caller |
| rename list | List's Rename List |
| delete list | Ordering's Read Order of the list, then Task's Delete of each task id it answers (the on end calls of each follow), then List's Delete List (the on end calls follow), in the one transaction |
| add task | Task's Add; Ordering's Place Item, the new task at the bottom |
| edit task | App check 1, then Task's Edit |
| move task | Ordering's Move Item |
| delete task | App check 1, then Task's Delete (the on end calls follow) |
| claim | App check 1, then Assignment's Assign, the caller as assignee (Glue, claim) |
| recall | App check 1, then Assignment's Recall For Task |
| reassign | App check 1, then Assignment's Active For of the task id, then Assignment's Reassign of the assignment it answers (`not-known` where it answers none); the new assignee is any actor id the author names, whose standing the app does not check, so a reassign to a person the list is not shared with leaves the task unread by them until it is |
| complete | App check 1, then Task's Complete, the caller as completer |
| invite | Invitation's Initiate, the caller as inviter, the list id as its context |
| accept, decline | Invitation's Accept, the caller as accepting identity (Glue, accept grants), or Decline |
| sign in | Credential's Verify, then Session's Issue (Glue, sign in; App answer 2) |
| sign out | Session's Revoke of the call's session, the caller as revoked_by_ref, the reason `signed out` |
| read list | List's Read List, Ordering's Read Order, Task's Read with a window of one week, Assignment's Active For and History For of each task answered; the answer carries the tasks Task's Read answered, each with its active assignment and its history, in the order Ordering's Read Order gives, and no entry Task's Read did not answer |

Task, Assignment and Invitation each append their events to the one Event Log, each in a stream of its own, as their journal needs say; the app writes nothing for it.

## Status

`todo` — written by the unit `app: to-do` (2026-11-25, ruled by Scott 7:11 to 7:15 PM Central from the draft of his session); it pauses for his design review of the app page form before another app page is written. No render here: TARGET.md and CORNERS.md come with the render unit.

last gate: 2026-11-26 — Final Critique 1, a full round (GRID opencode-go/glm-5.3-flash, EOS opencode-go/minimax-m3, Linus opencode-go/mimo-v2.6-pro), frozen at da9bc143 — foundational count 7 after the triage, not clean; the cures are in this text and the page's next round is a delta round. The tools read atoms and compositions only, so no tool has read this page.

NOTE: End of Shared Todo as an app.
