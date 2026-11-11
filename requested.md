---
title: Requested patterns
nav_order: 3
has_toc: false
---

# Requested patterns

**Try and pre-break it before we pre-bake it.**

This is the list of patterns people have asked for, or that the library's own work has pointed at, and that are not yet in the library. Each row is a name, what the pattern would do, who raised it and where, and how far it has come: *requested* (named, nothing drafted), *drafting*, *in rounds* (the review rounds have it), or *grounded* (it has stood up to them). A name here is a working name, nothing more.

The point of the list is to find the gaps before the writing starts. If you can think of a case a requested pattern would get wrong, or a way two of them would collide, say so now, in the thread a row links to or in a [discussion](https://github.com/scottromack/grace-commons/discussions). A gap you find in a pattern that is already grounded goes to that pattern's next review round instead: open a [finding](https://github.com/scottromack/grace-commons/issues/new?template=finding.yml) naming the pattern, the line, and what it could mean two ways ([how to contribute](./community.md)). A bug in one of the running demos goes where the demos report them, not here.

A post quoted below is cited, not answered. Where the library answers one, the answer is posted in that thread.

## Raised on the Concept Design Community forum

Daniel Jackson's [Concept Design Community forum](https://forum.essenceofsoftware.com/c/concept-catalog/5) has a Concept catalog category where members propose concepts and comment on each other's. These are the questions raised there that the library has no pattern for. Each is credited to the member who started the topic.

| Pattern | The question as raised there | Raised by, and where | State |
|---|---|---|---|
| Like | What is a "like", as a concept? A reply there reads it as a composition of other concepts, an upvote among them. Requested as [Reaction](#what-a-forum-would-need), the one row for the like, the upvote and the rest. | dmax, [What is a "like"?](https://forum.essenceofsoftware.com/t/what-is-a-like/66) | requested |
| Upvote | A sample catalog entry for the concept, listed there as also known as Like. Requested as [Reaction](#what-a-forum-would-need), the same row as Like. | dnj, [Upvote: sample concept catalog entry](https://forum.essenceofsoftware.com/t/upvote-sample-concept-catalog-entry/32) | requested |
| Favorite | A user saves an item for their own review later. See also the case below. The library reads this as two patterns: Favorite, a toggle (usually drawn as a heart, and always named "Favorite") that marks what a person likes best, such as a song or a product; and Save for Later, the private list to come back to, below. | spdegabrielle, [Favorite(media): in which a user saves item for later review](https://forum.essenceofsoftware.com/t/favorite-media-in-which-a-user-saves-item-for-later-review/30) | requested |
| Presence | Whether a user is on a system now, as Slack, Microsoft Teams and Skype show it. | kimmeyh, [Concept Ideas: Presence (of a user on a system)](https://forum.essenceofsoftware.com/t/concept-ideas-presence-of-a-user-on-a-system-example-concept-idea/50) | requested |
| Save for Later | Put an item on a private list to come back to, as YouTube's "Save" does; the list says "Save for later" in words, and the item leaves it when the person is done. Raised in the same thread as Favorite. | spdegabrielle, [Favorite(media): in which a user saves item for later review](https://forum.essenceofsoftware.com/t/favorite-media-in-which-a-user-saves-item-for-later-review/30) | requested |
| Comments, Notes and Tags | Highlight, tag and reference as concepts, and how they sit beside comments and notes. The library reads the thread's seventeen boxes as four concepts: [Segment, Reference, Comment and Suggestion](#what-a-forum-would-need). A note (a Comment only its author sees) and an annotation (a Comment by someone who cannot edit the item) are requested as Comment, whose row gains the two settings, who can see it and whether its author can edit the item. A mention and a citation are References drawn differently; inline and anchored are where a reference is drawn, a rendering. A clip is Save for Later on a Segment. Their "label" is our Tag. | pwilczynski, [Comments, Notes and Tags](https://forum.essenceofsoftware.com/t/comments-notes-and-tags/82) | requested |
| Order | Whether an order is a concept or an app. | Henri, ["Order" as an app](https://forum.essenceofsoftware.com/t/order-as-an-app/88) | requested |

**Favorite, a case from practice.** At Norwex a private favorites list became a shared one because its users asked for it. That is the shape [Shared Cart](./compositions/shared-cart.md) now holds: a list one person keeps that others can come to share. The Favorite row asks whether the single-owner list underneath it is a pattern of its own.

## What a forum would need

The first product the library is meant to build is a forum, and a sketch of it lists twelve patterns the library does not yet have. They are the maintainer's, from the forum sketch of 2026-10-31 ([the sketch](https://github.com/scottromack/grace-commons/blob/main/working-ideas/forum-demo.md)). The first seven are the core of version 1.0; the rest follow one a week. Three more rows (Segment, Reference and Suggestion) come from the Comments, Notes and Tags thread above, and are not the sketch's.

| Pattern | What it would do | State |
|---|---|---|
| Post | A markdown body with its revisions and publish state; the address is derived from the title, the author may change it, and the old one redirects. | requested |
| Comment | A reply tree on a target. Two settings make it the thread's note and annotation as well: who can see it (everyone, or only its author, a note), and whether its author can edit the item (an annotation is a Comment by someone who cannot). | requested |
| Category | A tree; one home per post; carries the menu order. | requested |
| Role | A named set of permissions; assigning it grants them and removing it revokes them. | requested |
| Moderation | Flag, hide, lock and pin: a role over a target. | requested |
| Restorable Delete | A removal that can be undone for a while, then is final. | requested |
| Reaction | Facebook's shape: one click gives the default reaction ("Like"); the others open from it, on hover or a long press; a person holds one reaction per item, choosing another replaces it, and clicking it again takes it back; all of it can be undone. The set of reactions is the deployment's choice, from one (a like or an upvote), through up and down, to a small set of emotions. The deployment makes one more choice: one reaction per person on an item (the shape above), or one of each reaction per person, so one person adds several reactions to one item (Slack, Discord and GitHub); the pattern is the same, only what a person may hold once changes, the item or the reaction on the item. Every control is named by its words: a thumb is "Like", a heart is "Favorite". This one row covers the Like and Upvote requests above. | requested |
| Scheduled Publish | A post goes live at a time it names. | requested |
| Tag | A flat label, many to many. | requested |
| Attachment | An upload that returns an address. | requested |
| Search | A derived index that never returns what the searcher could not read directly. | requested |
| Reputation | A score derived from reactions and accepted answers. | requested |
| Segment | A part of an item, of two kinds only ("inline and block. All else is trouble"): a block (a paragraph, heading or list item, anchored like a verse) or an inline span within one block, never a range across blocks. It is what comments, references and a plain highlight hang on. To pre-break: what happens to a segment when the text it spans is edited? and may two segments overlap, or does a new one merge with or replace the one beneath it, as most Bible software does? Raised in the thread [Comments, Notes and Tags](https://forum.essenceofsoftware.com/t/comments-notes-and-tags/82) by pwilczynski, with the concept map dnj commented on. | requested |
| Reference | One item points to another, and the target can list what points to it. A mention and a citation are References drawn differently. To pre-break: does a reference survive its target's deletion? Raised in the thread [Comments, Notes and Tags](https://forum.essenceofsoftware.com/t/comments-notes-and-tags/82) by pwilczynski, with the concept map dnj commented on. | requested |
| Suggestion | A proposed change on a segment, accepted or rejected by someone who can edit the item. Raised in the thread [Comments, Notes and Tags](https://forum.essenceofsoftware.com/t/comments-notes-and-tags/82) by pwilczynski, with the concept map dnj commented on. | requested |

## Compositions the library has imagined

From the maintainer's [list of compositions worth building](https://github.com/scottromack/grace-commons/blob/main/working-ideas/dream-compositions.md), 2026-06-12: combinations of patterns already in the library. One has since been built.

| Composition | What it would do | State |
|---|---|---|
| Break-Glass Access | Emergency access as a designed feature, not a hole: a time-boxed permission issued outside the normal route, only after who asked is recorded and the oversight group is told, and expiring by itself. | requested |
| Delegation with Recall | Authority handed from one person to another for a time, possibly passed on again, with a recall that closes the whole chain at once. | requested |
| Closed-Loop Medication Administration | An order, a pharmacist's check, then the administration, which reads the order, the check and any contraindication together before it is recorded. | requested |
| Recall and Containment | A defective item is quarantined, the records that exist are preserved as evidence, and everyone downstream is told, found from the item's own history. | requested |
| Maker-Checker Disjointness | Separation of duties as a property checked across stores: the people who approve a subject and the people who made it or benefit from it never overlap. | requested |
| Consent-Scoped Observation | Data collected under consent that can change: each observation is tied to the consent that allowed it, withdrawal stops new collection without voiding what was lawfully collected, and each disclosure is checked against consent at that moment. | requested |
| Saga | A sequence of steps across systems, each with an undo, that ends all done or all undone. | grounded as [Compensable Workflow](./compositions/compensable-workflow.md) |
| Capacity-Held Admission | Holding a place against a limit (a bed, a seat, a quota) so holds and confirmed places never exceed it. | requested |
| Invitation-Gated Enrollment with Expiry Hygiene | One live invitation per invitee per context; accepting one creates exactly one identity. | requested |
| Attested Configuration Change | A change to a system's settings with its approvals sealed so they cannot be altered afterward. | requested |

## Money

Money and ledgers: amounts, the books that add up, and the rules around them. The maintainer put money first among the hard patterns still to come (2026-11-06), the first being the one a benchmark in fancy accounting needs. The library's nearest pattern is the [Immutable Ledger](./compositions/immutable-ledger.md), which holds a record no one can rewrite and none of the arithmetic on top of it.

| Pattern | What it would do | State |
|---|---|---|
| Money | Amounts of money held and moved, to be drafted as small patterns first and wired into compositions after. | requested |
