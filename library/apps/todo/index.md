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
4. **Keep it the author's list.** Check: a non-author's add, edit, reorder, rename or delete is refused.

Two answers settle what the jobs leave open (Scott, 2026-11-25 7:15 PM Central):

- **No reopen.** A done task is a recorded fact with a week's display life ([Task](../../atoms/task.md)'s default window): a second check-off is refused, and the journal keeps who completed it. The app offers no reopen.
- **The author alone recalls or reassigns a claim.** The author may take a claim back ([Assignment](../../atoms/assignment.md)'s Recall) or give it to someone else (its Reassign), and the history is kept; a non-author may do neither. Reassign is an author action, not a glue line.

## Atoms

Ten, each used as it stands:

- **[Task](../../atoms/task.md)** — the tasks of a list: add, edit, complete, delete; mints the task id; saves the completer.
- **[List](../../atoms/list.md)** — makes a list, mints its list id, holds its name and its author.
- **[Ordering](../../atoms/ordering.md)** — one list's sequence: the author's order of priority, a new task at the bottom.
- **[Assignment](../../atoms/assignment.md)** — who is on a task: assign, recall, reassign, with its history.
- **[Permissions](../../atoms/permissions.md)** — who may do what on a list: grant, revoke, permitted.
- **[Invitation](../../atoms/invitation.md)** — bringing a person into a list: initiate, accept, decline.
- **[Actor Identity](../../atoms/actor-identity.md)** — who someone is; mints the actor id.
- **[Session](../../atoms/session.md)** — who is calling; mints the session id.
- **[Credential](../../atoms/credential.md)** — the proof checked at sign-in.
- **[Event Log](../../atoms/event-log.md)** — the history: the journal of task, assignment and invitation events.

Not in the app (the design of 2026-11-24): Capability (Permissions covers sharing), Party Identity (a team is a Permissions group in the first version), Restorable Delete (Task's plain delete in the first version).

## Bonds

Bond kinds are [the bonds page](../../bonds.md)'s, one source; this app names the one instance it writes and defines no kind.

Every need of the ten atoms but one meets exactly one offer of the ten, and that offer serves it with nothing written (Bond 8): the list id needs by List's offer, the actor id needs by Actor Identity's, and Assignment's task id need by Task's. The three journal needs, Task's, Assignment's and Invitation's, each meet the one journal offer, Event Log's, so the one Event Log serves all three with nothing written (Bond 8 and Bond 9). Ordering's item need is keyed on `opaque`, so it meets every key offer of the app's atoms (list id, task id, actor id, session id): an ambiguous need, served by the one instance below.

```
Bond instance 1: Ordering's key need that pairs entries MUST be served by Task's key offer of task id (Bonds Bond 7).
```

Cascades written: none. Deleting a list takes its tasks, their entries and their assignments, its sequence and its pending invitations, by the on end fields of the atoms' own lines (Bonds Key 3): List's Delete List ends the list id, so Task's Delete List Tasks, Ordering's Remove List Sequence and Invitation's Revoke List Invitations run; each task deleted ends its task id, so Ordering's Remove Item Everywhere (through Bond instance 1) and Assignment's Recall For Task run. Every one of these runs from an on end field, in Delete List's own transaction, so the cascade needs no glue line (Bonds Key 3, Key 4).

Not ended by deleting a list: the grants on it, since the permission scope is opaque, not a key. A grant on a deleted list reaches nothing: List's Read List of that list answers none, and the list id is never minted again (Bonds Key 16).

### The app's permission need

The app's gate is one rule set, stated as the app's own need line (Bonds Bond 13, Term app page need): the author may do everything on their list; anyone the list is shared with may read it, claim and complete, nothing else. The scope a check asks for is a list id paired with one of two standings, `author` or `member`; making a list gives its maker both, and accepting an invitation to it gives `member` (Glue, accept grants).

Term need permission: subject actor id; scope opaque; actions rename list, delete list, add task, edit task, move task, delete task, recall, reassign, invite, read list, claim, complete; calls permitted; arms permitted, denied.

```
App permission 1: rename list, delete list, add task, edit task, move task, delete task, recall, reassign and invite MUST be gated on the scope `author` of the list the action is on.
App permission 2: read list, claim and complete MUST be gated on the scope `member` of the list the action is on.
App permission 3: make list, accept, decline, sign in and sign out MUST NOT be gated.
```

Make list's grant is an effect of the generated action, not a gate: once List's Make List answers, make list calls Permissions' Grant of `author` and `member` on the new list to the caller, and no check is asked before it (App permission 3).

The subject of every check is the caller (Bonds permission 3), the actor id that [Session](../../atoms/session.md)'s Validate answers for the call's session.

## Glue

Three lines, counted. Each carries its birth tag and leaves by promoting, demoting or dying (the glue rule of 2026-11-23).

```
sign in: Credential's Verify, answering verified for a principal, MUST be followed by Session's Issue for that principal in the same app action. {birth: atom candidate}
accept grants: Invitation's Accept, answering accepted, MUST be followed by Permissions' Grant of the scope `member` on the invitation's list (its context) to the accepting actor in the same app action. {birth: bond candidate}
claim: claim MUST be Assignment's Assign whose assignee is the caller. {birth: bond candidate}
```

Sign-in waits for Login to be split into atoms; the grant on accept waits for the follow-up bond kind, which is not written yet; claim waits for a bond that carries the caller as a value.

## Actions

The app's API, generated, never written by hand. Every action but sign in is called with a session, and is gated as the permission need says.

| Action | Atoms' actions it calls |
|---|---|
| make list | List's Make List with the caller as author; Permissions' Grant of `author` and `member` on the new list to the caller |
| rename list | List's Rename List |
| delete list | List's Delete List (the on end calls follow) |
| add task | Task's Add; Ordering's Place Item, the new task at the bottom |
| edit task | Task's Edit |
| move task | Ordering's Move Item |
| delete task | Task's Delete (the on end calls follow) |
| claim | Assignment's Assign, the caller as assignee (Glue, claim) |
| recall | Assignment's Recall |
| reassign | Assignment's Reassign |
| complete | Task's Complete, the caller as completer |
| invite | Invitation's Initiate, the list id as its context |
| accept, decline | Invitation's Accept (Glue, accept grants) or Decline |
| sign in | Credential's Verify, then Session's Issue (Glue, sign in) |
| sign out | Session's Revoke |
| read list | List's Read List, Ordering's Read Order, Task's Read, Assignment's Active For |

Task, Assignment and Invitation each append their events to the one Event Log as their journal needs say; the app writes nothing for it.

## Status

`todo` — written by the unit `app: to-do` (2026-11-25, ruled by Scott 7:11 to 7:15 PM Central from the draft of his session); it pauses for his design review of the app page form before another app page is written. No render here: TARGET.md and CORNERS.md come with the render unit.

NOTE: End of Shared Todo as an app.
