# Beacon — its own specification

*What Beacon is, in plain words, apart from any stack. A render of Beacon is built from the library's patterns (the compositions and atoms named under [Built from](#built-from)) and from this file, and from nothing else: not from another render's code. Where Beacon needs something a pattern does not say, it is written here, once. Where it needs something that is true of every system, it is not written here: it belongs in a pattern, and this file names the gap under [What is not written yet](#what-is-not-written-yet).*

*Written 2026-11-16 for the unit `demo: Beacon's permissions are built from what is written, not patched`. Each line says where it comes from in square brackets: **plan** is [Demo2-plan.md](../clinical-trial-portal/Demo2-plan.md), **wiring** is [WIRING.md](../clinical-trial-portal/WIRING.md), a date is Scott's word that day, **live** is what the running Deno render does today where nothing else says (to be confirmed or changed at the comparison, never copied without a line saying so).*

*The clinical-trial-portal directory is the live render and deploys when it changes; this directory is beside it and deploys nothing.*

## What Beacon is

Beacon Clinical Research is one site running one Phase II trial, protocol `BCN-OX-201`, "Beacon Oncology Phase II Trial" [Section 1 of the plan, Section 3 of the plan]. The portal is the site's record of two things: who may do what on the study, and every action anyone takes on a subject's record. Three kinds of person use it [Section 1 of the plan]:

- **The principal investigator** holds the master account, invites people and gives them permissions. Seeded: Dr. Anya Okonkwo, `anya@beacon.clinical`, password `demo-pi`.
- **A study coordinator** enrolls subjects and records visits. Coordinators are never seeded: each is invited by email and sets a password on accepting.
- **The monitor** (clinical research associate) reads the audit trail and proves it has not been changed; never writes. Seeded: Jordan Lee, `jordan@beacon.clinical`, password `demo-cra`.

The two seeded accounts and their passwords are shown on the sign-in page, because this is a demonstration [live]. Subjects are synthetic codes only: no name or other personal detail is ever asked for or kept [Section 8.7 of the plan].

## Built from

Beacon wires these, and names no other pattern [wiring, RECIPE.md]:

| Pattern | What it owns in Beacon |
|---|---|
| [External Onboarding](../../compositions/external-onboarding.md) | an invitation, the party it names, the credential the person sets on accepting |
| [Login](../../compositions/login.md) | signing in and out |
| [Session-Gated Authorization](../../compositions/session-gated-authorization.md) | every page that needs a session or a permission |
| [Attributed Permissions Admin](../../compositions/attributed-permissions-admin.md) | giving a permission, taking one away, and who did it |
| [Audit Trail](../../compositions/audit-trail.md) | the attested, hash-chained record every action above writes to |

What Beacon keeps that is **its own and no library atom** [RECIPE.md]: the study, the subject, the visit, and the retention setting. They are specified in this file, and nowhere else.

## The permissions

A person holds a permission or does not; nothing more [Scott 2026-11-16, "remove that confusing shit"]. A person holds a given permission **at most once** [Scott 2026-11-16, "People can only have one of each boolean"]. Seven, with the words every screen uses [live, Scott 2026-11-16 "plainest wording"]:

| Permission | Words shown | What it lets a person do |
|---|---|---|
| `invite_actor` | Invite people | invite someone; revoke a pending invitation |
| `grant_permission` | Give and take away permissions | give any permission to any person; take any permission away |
| `enroll_subject` | Enroll subjects | enroll a subject |
| `record_visit` | Record visits | record a visit on a subject the person may see |
| `view_audit` | See everyone's audit events | read, filter, verify and export the whole audit trail |
| `view_own_audit` | See my own audit events | the same, over the events that person's own actions made |
| `view_all_subjects` | See every subject | see every subject; without it a person sees the subjects that person enrolled |

Who may give a permission: **a person who holds `grant_permission`** may give any permission to any person, themselves included, and take any away [Scott 2026-11-16 1:33 PM, "People with admin rights can set other peoples rights"]. No other rule limits who gives what; if one is wanted it is Scott's to say.

Giving a permission the person already holds is not an error and writes nothing: the screen answers as it would have, and there is no second grant and no second event [Scott 2026-11-16; Permissions Operation 33 and 34]. Two people giving the same permission at the same moment leave one grant [same ruling; Permissions Identity 7].

Taking a permission away takes it away whole: afterwards the person does not hold it, however it was given [Attributed Permissions Admin, [Revoke Permission]]. A person who lost a permission may be given it again, and that is a new grant [Permissions].

What the seeded people hold at the start [Section 3 of the plan, live]:

- Anya: `invite_actor`, `grant_permission`, `enroll_subject`, `record_visit`, `view_audit`, `view_all_subjects`.
- Jordan: `view_audit`.

## The study, subjects and visits

**The study.** One, `BCN-OX-201`, seeded. There is no screen to make another [Section 7 of the plan Phase 7: not in scope].

**A subject** has a code, a status, who enrolled it and when, and optional notes [Section 5 of the plan]. The code is `BCN-` and three digits, assigned by the system and never typed: one more than the highest code in use, starting at `BCN-001` [live]. The status starts as `screening`; the others (`enrolled`, `withdrawn`, `completed`) exist in the record and nothing in Beacon changes a status yet [live; Section 5 of the plan].

**A visit** has a kind, who recorded it and when, and optional notes. The kinds are `screening`, `week 4`, `week 12`, `week 24`, `end of study`; a visit with no kind is refused with "Visit type is required." [live]. Visits are listed on the subject, oldest first [live].

**Who sees which subject:** a person who holds `view_all_subjects` sees all of them; anyone else sees only the ones that person enrolled, and another's subject answers "Not Found." as if it did not exist [Scott 2026-11-16; live]. A subject is seen, and a visit recorded, only by a person who holds `enroll_subject` or `record_visit` to begin with [Section 4 of the plan, live].

**Who records a visit:** a person who holds `record_visit` [Section 4 of the plan]. The live render also lets a person who holds only `enroll_subject` do it; this file follows the plan, and the comparison reports the difference [live].

## The screens

Every screen is a page the server draws; every action works with no script running in the browser [Section 4 of the plan]. A person without a session who asks for any page but sign-in, accepting an invitation and the front page is sent to sign-in.

| Screen | Who may open it | What it shows and does |
|---|---|---|
| **Front page** `/` | anyone | sends the person to sign-in |
| **Sign in** `/login` | anyone; a person already signed in is sent to the dashboard | email and password, and the two demonstration accounts. Wrong email or wrong password both answer "Invalid email or password." and say nothing of which was wrong; an empty field answers "Email and password are required." |
| **Sign out** `/logout` | anyone | ends the session, clears the cookie, returns to the front page |
| **Accept an invitation** `/invitations/accept/:token` | anyone holding the link | a "Set up your account" form: the invited email, the intended role, a password (at least 8 characters) and its confirmation. A link that is unknown says "This invitation link is invalid."; one used or revoked says "This invitation has already been used or revoked."; one past its date says "This invitation has expired. Please ask for a new one." Accepting signs the person in |
| **Dashboard** `/dashboard` | a signed-in person | "Welcome, <name>", and a tile for each of People & Permissions, Subjects and Audit Trail that the person may open [Section 4 of the plan]. (The live render offers People & Permissions only to `invite_actor`, never to a person who holds only `grant_permission`, and Audit Trail only to `view_audit`, never to a person who holds only `view_own_audit`: the comparison reports both.) |
| **People & Permissions** `/people` | a person who holds `invite_actor` or `grant_permission` | see below |
| **Subjects** `/subjects` | `enroll_subject` or `record_visit` | the subjects the person may see (code, status, enrolled, notes) each with a link in; "Enroll the first subject." where there are none and the person may enroll |
| **Enroll Subject** `/subjects/new` | `enroll_subject` | the next code, shown and not editable, and an optional notes box |
| **A subject** `/subjects/:id` | as Subjects | the subject, its Visit History ("No visits recorded yet." where none), and a Record Visit form (visit type, optional notes) for a person who may record |
| **Audit Trail** `/audit` | `view_audit` or `view_own_audit` | the events newest first (number, time, action, target, actor, payload), filtered by action and by from and to date; Verify chain and Export CSV links; the retention switch. Opening it is itself an event |
| **Chain verification** `/audit/verify` | as Audit Trail | "Chain intact" with the number of events checked, or "Tampering detected" with the event, the hash recomputed and the hash found |
| **Audit export** `/audit/export.csv` | as Audit Trail | every event the person may see, oldest first, with both hashes; the file is named `beacon-audit-<date>.csv`. Exporting is itself an event |

A signed-in person who lacks a permission a page needs is answered with the page "Access denied", which names the permission or permissions that would open it, and a way back to the dashboard [Section 2 of the plan, live].

### People & Permissions

For a person who holds `invite_actor` or `grant_permission`, three parts [Scott 2026-11-16 1:27 to 1:35 PM; Section 4 of the plan]:

1. **People.** Each person once: name, email, and the permissions that person holds **now**, each shown once, in the words above, each with a mark that takes it away whole. The marks and the choice to give are offered only to a person who holds `grant_permission` [decided here; the live render shows them to everyone who opens the page and answers "Access denied" when one is used]. A person who holds none shows "none"; a person who holds all seven shows "holds every permission". Below each, the permissions the person does *not* hold are offered to give, and only those. No choice of reach is offered, because a permission has none.
2. **Permissions History.** Every permission ever given, oldest first: when, to whom, which permission, given by whom, and whether it is held now (the revoked ones marked). This is where several grants over time are read; it is a history and is headed so. It is attribution, never access [wiring, `attribution_for`].
3. **Pending Invitations**, and **Invite someone**: email, display name, role (a free word; the form suggests "coordinator"). Issuing an invitation shows the link to copy and share ("Invite link — copy and share this with the invitee:"), because Beacon sends no email in this render [Section 8.2 of the plan]. A pending invitation shows its email, role, expiry and link, and can be revoked by a person who holds `invite_actor`.

An invitation lasts seven days [live; plan]. A session lasts seven days [live; Section 3 of the plan]. A session is a random opaque value kept in a cookie the browser's scripts cannot read, and the session record, not the cookie, is what makes a person signed in [Section 8.4 of the plan].

## What each action writes to the audit trail

Every action that changes something writes its event in the same transaction as the change: either both are written or neither [Section 8.13 of the plan]. The events, as the live render writes them [live, which differs from Section 6 of the plan where marked]:

| Event | When | Target | Payload |
|---|---|---|---|
| `invitation.issued` | an invitation is made | the invitation | email, display name, role, expiry |
| `invitation.accepted` | it is accepted | the invitation | role |
| `actor.enrolled` | the same acceptance | the new actor | party, the invitation |
| `credential.created` | the same acceptance | the credential | kind |
| `session.opened` | the same acceptance | the session | actor, "onboard" |
| `invitation.revoked` | a pending invitation is revoked | the invitation | role |
| `login.succeeded` | a person signs in (plan said `session.opened`) | the actor | none |
| `login.failed` | a sign-in fails | none | email, why (`unknown_email`, `no_actor`, `no_credential`, `bad_password`), and the party where the email matched. Never attributed to the actor [Section 8.10 of the plan] |
| `session.revoked` | a person signs out through the system's own call (plan said `session.closed`) | the session | none |
| `grant.issued` | a permission is given where it was not held | the grant | grantee, permission |
| `grant.revoked` | a permission is taken away | the grant | reason; one event for each grant taken |
| `subject.enrolled` | a subject is enrolled | the subject | study, code |
| `visit.recorded` | a visit is recorded | the visit | subject, kind |
| `audit.viewed` | the audit page is opened | audit | filters, scope, result count |
| `audit.exported` | the export is made | audit | row count, scope |

Each event carries the actor and the session that made it where there is one, and a hash that covers the event and the hash before it; the first event's earlier hash is empty. The hash is SHA-256 over the event's fields written as canonical JSON (keys in order, no spaces, nulls kept) [Section 6 of the plan]. Retention filters what the page shows and **never deletes** an event [Sections 6 and 8.6 of the plan]; the setting is 2555 days, seven years, and **starts off** so the whole chain is visible, with a switch on the audit page [Section 8.6 of the plan; the live seed's `ensureDefault` starts it on, which the comparison reports].

## The data a render starts from

A render starts from its seed and nothing else: the two accounts, the seven permissions with their words, Anya's and Jordan's permissions, the study, and the retention setting. The old reach (`all` or `own`) does not exist in a render built from this file, so there is nothing to migrate. Before any render replaces the live demo, the live database is read for anything a person made that the seed does not hold, and the unit says what it found [unit step, 2026-11-16].

## People, and what Beacon gives the patterns where it asks nothing

**One identifier.** A person is the party [Party Identity](../../atoms/party-identity.md) enrolled, and the party's id is the person's actor reference, the principal of the person's credential, the principal a session names, and the one a permission is held by [decided here: one identifier runs through every pattern, so nothing maps one to another].

**The person's key.** A key is made for each person when the person is created (accepting an invitation, or the seed), kept by the server sealed under the person's password, unlocked at sign-in and held for the session; every grant and every taking-away is attested with it [Scott 2026-11-16 10:36 PM Central: "Yes to both." "Agree with the mayor."]. A server restart signs everyone out, since the unsealed key lives only in the running server [decided here].

**What Party Identity is given.** It records a name, a date of birth, a document type and a document reference [Party Identity Operation 1]; Beacon asks a person for none of the last three. Decided here, for Scott to confirm or change: the name is the person's display name, the date of birth is `1900-01-01`, the document type is `beacon-account` and the document reference is the person's email. They are placeholders that carry no personal detail, because Beacon asks for and keeps none [Section 8.7 of the plan].

**Email** is compared trimmed and in lower case [decided here].

## What is not written yet

Said here so a build neither invents nor drops them.

1. **How a person signs a grant.** [Attributed Permissions Admin](../../compositions/attributed-permissions-admin.md) has every grant and every taking-away carry an attestation by the person doing it, made with that person's credential through [Actor Identity](../../atoms/actor-identity.md) (Action wiring 2, 17; External check 2). The live render never did this: it wrote one event and a grant. What a person's credential is in Beacon is answered under People, above (a key kept by the server, sealed under the person's password).
2. **Roles.** Role-Based Access Control and Delegation are not written; Beacon grants one permission at a time and invents no role [wiring].
3. **Words for people.** Every word a screen shows is the plainest that keeps its meaning; a pattern carries none [Scott 2026-11-16 11:57 AM]. The words in this file are the live render's, for the render to improve and not to copy.
