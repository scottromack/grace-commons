# Forum — Demo 1.0

**Status:** Sketch (pencil, no version) — 2026-10-31. Nothing here binds a spec. The council grinds the existing queue through Nov 14; from Nov 15 the demo patterns come first (2026-10-31 ruling). The 50% mark no longer gates this work.

**Covers:** the first product built from the corpus — a forum — what it needs that the corpus lacks, what ships in 1.0, what is deferred, and the timeline.

---

## Why a forum

- It is the one application whose plumbing the corpus already holds: Login, Session, Party Identity, Invitation, Subscription, Notification Fanout, Message Preference, Permissions, Consent, Audit Trail, Actor Suspension.
- The builder base lives in the product; every thread is a live demo. The Discord goes away.
- One composition, two deployments: the Grace Commons forum and the Bible study forum are the same spec with different data. If the second costs a config file and not a rewrite, "intent is canonical" is demonstrated, not argued.
- The launch video, "Look at what I'm not doing", is the blog-in-fifteen-minutes demo twenty years on: the fifteen minutes is dictating, and the comments under the video are the demo.

## Reverse-engineered from CMS, blog and forum

Content is markdown. That alone removes Template (markdown renders itself), shrinks Attachment to an upload that returns an address, and makes Mention a markdown convention the Post parses. Slug folds into Post (derived from the title, author may overwrite, the old address redirects). Menu folds into Category (derived from the tree, editor may reorder or hide). A blog is a CMS with one category and comments on.

Twelve atoms the corpus lacks:

| # | Atom | One line |
|---|------|----------|
| 1 | Post | markdown body, revisions, publish state; slug derived, editable, redirects |
| 2 | Comment | reply tree on a target |
| 3 | Category | tree, one home per post, carries menu order |
| 4 | Role | named scope set; assign resolves to Permissions grants, remove revokes (Permissions Non-goal 1 holds no role) |
| 5 | Moderation | flag, hide, lock, pin; a Role over a target |
| 6 | Restorable Delete | tombstone with a restore window; not Jackson's Trash, which is a place (a folder with rules, so a composition) — the store remembers where the thing was, so only the rules remain |
| 7 | Reaction | one per actor per target |
| 8 | Scheduled Publish | valid-from instant flips the Post |
| 9 | Tag | flat label, many-to-many |
| 10 | Attachment | upload returning an address |
| 11 | Search | derived index; never returns what the actor's own read would refuse |
| 12 | Reputation | derived score from reactions and accepted answers |

The Store's default history makes four nearly free: Post revisions are the record's history, Trash restores the prior version, Scheduled Publish is a valid-from instant, Reputation is a query. Search lives outside the store and needs an index contract. Moderation is permissions that change by target, not by actor, which is why Role is admitted first.

## 1.0 — the core seven

Post, Comment, Category, Role, Moderation, Restorable Delete, Reaction. A forum cannot open without them. No scope creep: the Forum composition's Non-goals name the five below as forthcoming.

## Deferred — one atom a week, each an episode

1.1 Scheduled Publish · 1.2 Tag · 1.3 Attachment · 1.4 Search · 1.5 Reputation. Each episode is the same shape: dictate the atom through the connector on camera, the council grounds it off camera, the feature appears.

## Drafting — one pass, inherited rulings

Draft all seven in one connector sitting; they share shape (a body on a target, an actor, a state). Each atom inherits these rulings instead of rediscovering them mid-draft:

- Transaction boundary: one transaction per action (Store 1); a sweep's transaction is each act's closure, not the run (2026-10-31).
- Refused attempts a page keeps as evidence stay, written in the refusal's transaction and answered as outcomes, not refusals (2026-10-20, 2026-10-31).
- Roles: Permissions holds grants only (Non-goal 1); Role resolves to grants and never bypasses them.
- Soft delete: Restorable Delete is a tombstone; restore reads the Store's history; purge removes every version (Store 5).
- Derived state (slug, menu order, reputation, search index) is rebuildable and never canonical; an override is a stored field, the derivation is not.

A finding a round re-finds is cured in the text, never with a note (2026-10-31 00:34Z). Whether that rule stops the re-finding loops is the number that decides the pace; it is reported daily.

## Timeline (estimate; assumes one to two pages a day)

- Nov 1–14: the council grinds the existing queue; we get what we get
- Nov 15–17: draft the seven atoms through the connector, one sitting
- Nov 18–30: ground them, demo atoms at the head of the queue
- Dec 1–3: draft the Forum composition
- Dec 4–10: ground it
- Dec 11–18: generate the default render, host on Fly, dogfood with real threads
- Dec 19–24: record the video; publish forum and video together — **Dec 25 or bust**
- Jan 5, 12, 19, 26, Feb 2: episodes 1.1 to 1.5

Slack is two weeks before Christmas; if grounding runs slow the video slips into the first week of January and nothing else moves. The target stays hard.

## Release marker

The forum ships with Grace V1 (2026-10-31 ruling: the corpus marks releases V1 and each major after, beside per-atom SemVer).
