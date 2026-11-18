# The render compared with the live Beacon

The unit asks that the build be compared to the patch, behavior by behavior, each difference a finding: either the written intent (SPEC.md) lacks something, or the live code did something nobody wrote. This is that comparison, **by reading, not by running both**: the live demo is `demos/clinical-trial-portal` (Hono on Deno over SQLite; its routes, middleware and domain files read whole, its views not), and the render is this directory. The two were not started side by side, so a word on a screen the live views carry and the routes do not is not compared; the last section names what was not.

## Where SPEC.md already says the render differs (the comparison confirms each)

| # | Live (`demos/clinical-trial-portal`) | Render | Written in SPEC.md |
|---|---|---|---|
| 1 | Retention window starts on (`domain/retention_policy.ts`, `ensureDefault`) | starts off | *What each action writes* |
| 2 | A visit may be recorded by a person who holds `record_visit` or `enroll_subject` (`routes/subjects.ts:113-117`) | `record_visit` only | *The study, subjects and visits* |
| 3 | Events `audit.viewed`, `audit.exported`; a hash chain with a hash on each event, shown by Verify | `beacon.audit_viewed`, `beacon.audit_exported`, `beacon.retention_switched`; a seal over each slice, no hash on an event | *What each action writes*; *Chain verification and the export* |
| 4 | Dashboard tiles by the live render's own narrower tests | a tile for each page the person may open | *The screens*, Dashboard |
| 5 | The reach (all or own on a grant) was retired from the live code by 7080a8cd (`domain/grants.ts`, `domain/permission_catalog.ts`'s one-time migration) | none | *The permissions* |

## Differences this comparison found

| # | Live | Render | Verdict |
|---|---|---|---|
| 6 | An unknown subject id answers `Subject not found.` (404, `routes/subjects.ts:92`) and another person's subject answers `Not Found.` (404, line 98): the two words tell a person which ids exist | both answer `Not Found.` | **The live code leaks.** SPEC says only that another's subject "answers as if it did not exist"; the render does that for both, the stronger reading. Not a gap in SPEC. |
| 7 | A subject id that is not a number redirects to `/subjects` (`routes/subjects.ts:89`) | answers `Not Found.` like any unknown id | SPEC names neither; the render's is the one rule, so it goes in (it is the render's, said here). |
| 8 | The access-denied page is titled `403 Forbidden`, heads `Access denied` and names the permission codes (`middleware/require_permission.ts`: "requires the view_audit or view_own_audit permission") | `Access denied`, names the permissions in the words every screen uses | SPEC (*The screens*) says the page names the permission or permissions "that would open it" and the words are the screens' own: the render follows it; the live shows codes a person does not read. |
| 9 | The accept form's refusals read "Password must be at least 8 characters." and "Passwords do not match." (`routes/invitations.ts:92-93`) | "Choose a password of at least 8 characters." and "The two passwords do not match." | SPEC names the 8 and no wording; the render's words are its own, decided in SPEC (*People*, an invitation). A difference of words only. |
| 10 | Giving and taking away address a person by integer id and a permission by integer id (`/grants`, `/permissions/revoke`: `grantee_actor_id`, `permission_id`); an invitation by integer id | a person by party id, a permission by its code, an invitation by its token | The one identifier (SPEC, *People*): the render has no integer ids. A difference of the wire, not of behavior; any bookmark or script of the live form breaks. |
| 11 | Post paths: `/subjects` (create), `/invitations`, `/invitations/:id/revoke`, `/grants`, `/permissions/revoke`, `/audit/toggle-retention`; the invite form's role field is `intended_role` | `/subjects/new`, `/people/invite`, `/people/invitations/:token/revoke`, `/people/give`, `/people/take`, `/audit/retention`; the field is `role` | Paths and field names are the render's own, since SPEC names the pages and not the posts. |
| 12 | An email is trimmed (`routes/auth.ts:42`); no lower-casing is read anywhere in `routes/`, `domain/`, `lib/` or `middleware/` | trimmed and lower-cased on invitation, sign-in and the person | SPEC decides it (*People*, "Email is compared trimmed and in lower case"); the live code keeps the email as typed where it reads none. |
| 13 | SQLite (`datetime('now')`), one process, integer keys | XTDB over the Postgres wire, string keys, every action's change and event in one transaction except the grant events (SPEC, *What is not written yet*, 3) | The stack. |
| 14 | A grant's event is written with the grant (one transaction in the live code) | after the grant, not in its transaction | The render's one weaker guarantee; a pattern change (a plan form on Attributed Permissions Admin) would remove it. SPEC says so. |
| 15 | The session cookie is `HttpOnly`, `SameSite=Lax`, path `/`, with `expires` from the session (`routes/auth.ts:17-22, 59`) | the same flags, `maxAge` seven days | No difference found in the flags; the seven days is SPEC's and the live session's lifetime was not read. |

## What was not compared

The live views (`views/*.tsx`) and styles; every word on a screen they carry beyond the messages greped in the routes; the migrations; the seed's wording; how each screen looks. Nothing was run on the live side. A comparison by running both, with the same requests sent to each and the answers diffed, would close this, and needs Deno and the live database's shape; it is not done.
