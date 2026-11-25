---
title: Bonds
nav_order: 4
has_toc: true
toc: true
---

# Bonds

## What it is

A bond is how two atoms connect without either naming the other (Scott, 2026-11-23 5:17 PM Central, on the bond shape; 5:19 PM: "make atoms truely atomic"). A bond kind is stated once, here. Each atom states what it needs, on a Needs line, and what it offers, on an Offers line, each line of a bond kind this page states and typed by the words of [the declaration space](./declarations.md). Where an app picks two atoms and one's need meets exactly one offer, the bond forms and the app writes nothing; an app writes a bond only where a need could meet more than one offer. No bond instance lives outside an app, and no page stands between atoms as a container. An app's page states a need the same way, and never an offer. This page names no atom.

Atoms are siblings on one plane (Scott, with GLM, 2026-11-24). Each knows only its own joint: its needs and offers by bond kind. The route through them is the app's, and the app may call any atom of the app at any point of its flow, the same atom more than once. Bond kinds are the only doors between atoms. Direction 2 fails a cycle of needs, never an app calling an atom twice: the app's flow writes no edges.

It holds the bond kinds lines have landed on, and no others: guard and key, which the first fifty bond-candidate lines landed on, journal, and permission, which the offer line of an atom that holds grants landed on. A bond kind is written here when a line lands on it, and not before, and only when a need cannot be said with the bond kinds that exist, shown in writing beside the bond kind (Scott, 2026-11-24 7:36 to 7:52 AM Central: "as small as possible but not smaller"). The law of the bonds: needs bind to bond kinds, offers stand on atoms, and no name crosses an edge.

## The bond line

Term need line: a `Term need <kind>:` declaration on an atom or on an app's page, one for each need of the bond kind the atom or the app has: each need field of the bond kind as the field's name and the field's value, the fields separated by semicolons.

Term offer line: a `Term offer <kind>:` declaration on an atom, one for each offer of the bond kind the atom makes, in the need line's form, with the bond kind's offer fields.

Term typed field: a field whose value is a word the declaration space declares or a type it names; key, holder, span, keep, tamper, subject and scope are typed fields.

Term list field: a field whose value is a list of words, separated by commas; calls, a need's arms, writes, carried by, pairs, actions and ends are list fields, and on end is a list field of one action.

Term per-call field: a field whose value names, for each call of the line's calls, the call, a colon and the call's words as a list, the calls separated by slashes; an offer's arms is a per-call field.

Term ambiguous need: of an app, a need that meets one offer of the app's atoms and a second.

Term meets: a need meets an offer where the two lines satisfy Bond 1, Bond 2 and Bond 3.

Term unmet need: of an app, a need of one of the app's atoms that meets no offer of the app's atoms. A contract need is no bond need: the app meets it at the edge ([Contracts](./contracts.md), Contract 5).

Term app page need: a need line on an app's page, which every rule on this page reads as a need of one of the app's atoms and the app's page as a needing atom.

Term bond instance: the line an app writes naming an ambiguous need and the one offer, of the offers the need meets, that serves it.

```
Bond 1: A need MAY meet an offer ONLY IF the two lines name one bond kind AND the two lines stand on two atoms.
Bond 2: A need MAY meet an offer ONLY IF, for EVERY typed field of the need, the need's field and the offer's field of the same name name one word, or one of the two fields names a declaration type and the other names a word of that type.
Bond 3: A need MAY meet an offer ONLY IF EVERY word of the need's calls IS IN the offer's calls AND EVERY word of the need's arms IS IN the arms the offer names for one or more of the calls the need's calls name.
Bond 4: An app MAY write a bond instance ONLY IF a need of one of the app's atoms is an ambiguous need.
Bond 5: A bond instance MUST NOT stand outside an app.
Bond 6: A need line MUST NOT name an atom.
Bond 7: IF a need of one of the app's atoms is an ambiguous need THEN the app MUST write one bond instance for the need.
Bond 8: IF a need of one of the app's atoms meets EXACTLY ONE offer of the app's atoms THEN that offer MUST serve the need.
Bond 9: EXACTLY ONE instance of an atom MUST serve EVERY need of the app that meets one of the atom's offers AND is no ambiguous need.
Bond 10: IF a need of one of the app's atoms is an unmet need THEN the app's build MUST fail.
Bond 11: A need of an atom read alone, outside any app, MAY meet no offer.
Bond 12: IF a need of one of the app's atoms is an ambiguous need THEN EXACTLY ONE instance of the atom whose offer the need's bond instance names MUST serve the need.
Bond 13: An app's page MUST NOT carry an offer line.
```

## Guard

Term guard: one holder at a time over a key, from a take until the holder releases the guard or the guard's instant passes.

Term guard need fields: key, the key the needing atom takes the guard on; holder, the value its take names; span, how long its take asks for; calls, the guard calls it makes, and it makes no call the list leaves out; arms, the guard's answers it reads, and it discards a guard answer the list leaves out, while a failure the Execution Contract answers, such as state-unavailable or storage-failure, is no answer of the guard and the needing atom lands it as the Execution Contract says (Read 1, Constituent failure 1 and Constituent failure 3); writes, the records it writes under the guard.

Term guard offer fields: key, the keys the guard is given over; holder, the holder values a take may name; span, the length a take may ask for; calls, the guard calls offered; arms, every answer each of those calls gives, named per call.

Term take: the guard call that asks for the guard on a key, for a holder and a span, and waits while another holder holds the key.

Term try_take: the guard call that asks for the guard without waiting.

Term remaining: the guard call that answers how much of a holder's grant is left, or none.

Term expiry instant: the instant a grant ends at unless the holder releases the guard first.

Term call in flight: a call a holder issued under a grant that has returned neither an answer nor a refusal.

Term no answer: a guard call that returns neither its answers nor a refusal within the call pause bound the needing pattern declares.

```
guard 1: A writer MUST write a record a guard need names under writes ONLY IF the writer holds the guard on the need's key.
guard 2: IF a take, a try_take, a remaining or a release on a guard answers no answer THEN the holder MUST read remaining as none for the rest of the grant.
guard 3: A needing atom MUST NOT read a guard's instant or a span on the guard from a clock other than the offering host's (Execution Contract Logic confinement 7).
guard 4: IF a guard call answers no answer THEN the holder MUST NOT write a record the need names under writes BEFORE the holder holds the guard by a new take.
```

## Key

Term key bond: a value one atom's records carry that another atom's records are paired on.

Term key need fields: key, the value the needing atom pairs on; pairs, the records it pairs on the key; on end, the one action of the needing atom's own that the app calls when an action the meeting offer's ends names ends a value the need pairs on, where the need names one.

Term key offer fields: key, the value the offering atom mints; carried by, the offering atom's own records that carry the value; ends, the offering atom's own actions that end the record a value names, where the offer names any.

Term ended value: the value whose record an action an offer's ends names ends.

Term on end call: the app's call of a need's on end action for one ended value.

Term minted id: the value an atom mints for one of its records when the record is made, naming that record alone.

Term link record: a record whose only identity is the ids of the records it joins, as an entry joining a list id and an item id.

Term extension record: a record that extends exactly one record of another atom, one to one.

```
Key 1: EVERY record a key need names under pairs MUST carry the key the meeting offer mints.
Key 2: Two atoms of an app MUST NOT offer one key, an ambiguous need the app writes a bond instance for excepted (Bond 7).
Key 3: IF an action the meeting offer's ends names ends a value THEN the app MUST make the on end call once, with the ended value as the on end action's one input, in the ending action's flow AND in the ending action's transaction (Execution Contract Database 1).
Key 4: An app MUST NOT write a line for an on end call (Bond 8).
Key 5: An on end action MUST find the records the needing atom pairs on the ended value in the needing atom's own state.
Key 6: An app MUST NOT read an atom's records to make an on end call (Execution Contract Atom interface 1).
Key 7: IF the needing atom holds no record paired on the ended value THEN the on end action MUST answer ok AND MUST NOT write.
Key 8: IF an on end call refuses THEN the ending action MUST commit nothing.
Key 9: IF an atom's actions act on the atom's records one at a time THEN the atom MUST mint an id for EVERY record the atom makes, in the action that makes the record, a link record and an extension record excepted (Key 11).
Key 10: An atom that mints an id MUST offer the minted id as a key from the atom's first version, whether or not a need meets the offer.
Key 11: An atom MUST NOT mint an id for a link record or for an extension record.
Key 12: A link record MUST carry the ids the link record joins as the link record's name.
Key 13: An extension record MUST carry the id of the record the extension record extends.
Key 14: An atom MUST NOT offer an id the atom carries and does not mint.
Key 15: The host MUST supply EVERY minted id at the atom's seam, fresh and opaque.
Key 16: An atom MUST NOT reuse a minted id.
Key 17: EVERY minted id's word MUST name the record the minted id names, followed by "id".
Key 18: EVERY minted id's word MUST stand under Declarations.
Key 19: An action MUST NOT take an id as the action's authority to act.
Key 20: An atom MUST NOT use a name, an email address or a token digest as a record's id.
```

The on end call is a call the app makes in the ending action's flow, from the need line's declaration; the database runs no cascade (Execution Contract Database 4), and there is no event bus and no callback out of an atom. Each field names only its own atom's actions, so nothing looks up and no atom is named (Bond 6, Direction). Since an on end action that finds no record writes nothing (Key 7), two on end calls that reach one record in one transaction leave it as either order would.

Every key starts on the atom that mints it (Scott, 2026-11-25 3:22 PM Central, "Yes", on "Think what a good DB would do"): as every table of a good database has a key from its first row, and any key can be referenced without the referenced table opting in, an atom offers its records' id before any need meets it, and an atom added later needs it without the offering atom changing. The host mints the id at the seam, as it injects now, so the atom's actions stay pure. An id is named for what it names: task id, list id, actor id, invocation id, session id. An id grants nothing: a token, a permission or a credential grants, and each is its own atom's. A name, an email address or a token digest may be a unique field of a record, never the record's id.

## Journal

Why a bond kind: an atom that appends its records to a store it never changes and reads them back in order cannot say so with a guard, which is one holder over a key, or a key, which is a value records carry; so the need could not be said with the bond kinds that existed, and journal is written.

Term journal: records an atom appends, which the offer keeps, and which the atom reads back by range. The bond kind has three verbs and no more: append, keep, read by range.

Term journal need fields: records, the records the needing atom appends; calls, the journal calls it makes, and it makes no call the list leaves out; arms, the journal's answers it reads, and it discards a journal answer the list leaves out, while a failure the Execution Contract answers, such as state-unavailable or storage-failure, is no answer of the journal and the needing atom lands it as the Execution Contract says (Read 1, Constituent failure 1 and Constituent failure 3); keep, how long it needs each record it appends kept, where it needs a keeping period the offer's keep does not already give; tamper, how it needs a change to a kept record to show, where it needs the change to show; stream, the stream it appends to and reads from, where it names one.

Term journal offer fields: calls, the journal calls offered; arms, every answer each of those calls gives, named per call; keep, how long the offer keeps a record, the type duration where the app sets it to the keep of the needs it serves; tamper, how a change to a kept record shows: a word of the declaration space, or the type opaque where the app sets it to the evidence of the needs it serves, as keep is set; order, the order a read by range answers in, per stream at least.

Term append: the journal call that adds one record at the end of a stream and answers the record's place in the stream's order.

Term read: the journal call that answers the records whose places lie in a range of one stream's order, in that order. A read of one record is a read of the range that holds the record's place and no other: the place an append answered names the record, and no call of its own looks a record up by that place.

Term stream: the records one offer keeps in one order.

Term place: a record's position in its stream's order.

```
journal 1: An offer MUST keep EVERY record an append answered a place for, unchanged, for the keep of EVERY need the offer serves.
journal 2: A read MUST answer EVERY record whose place lies in the range AND no other record, in the stream's order.
journal 3: IF a read is issued after an append answered AND the read's range holds the appended record's place THEN the read MUST answer the appended record.
journal 4: A needing atom MUST read a range ONLY within one stream's order.
journal 5: A journal need MUST NOT ask for a record by the record's content AND MUST NOT ask to be told of a record appended later.
journal 6: An atom that needs a keeping period other than the offer's keep MUST state the period as the keep of the atom's need.
journal 7: IF a record is wanted by the place an append answered THEN the read MUST name the range whose first place and last place are that place.
journal 8: EVERY need an offer serves MUST keep the need's records in a stream of the need's own, unless the need names a stream.
journal 9: IF the keep of a need EXCEEDS the keep of an offer THEN the need MUST NOT meet the offer.
```

## Permission

Why a kind: a pattern that gates an action on a standing it does not own, a grant given and taken back with no redeploy, cannot say so with the kinds that existed. A guard is asked for on a span, one holder at a time over a key, and ends by the holder's release or at an instant; its question, remaining, answers how much of a holder's grant is left, not whether a party holds a standing. A key is a value records carry, and its fields are that value and the records alone: no call and no answer. A journal is records an atom appends and reads back by range, which a need may not ask for by content (journal 5) and which the offer keeps unchanged (journal 1), so a standing withdrawn would leave its record standing. So the need could not be said, and permission is written.

Term permission: a subject's standing to take an action of one scope, asked of the atom that holds the grants and answered permitted or denied. The kind has one verb and no more: permitted.

Term permission need fields: subject, the party the gated action is called for, as a declared word or a type; scope, the declared word or type of the action scopes its permission checks ask for, the scope of each action being the needing atom's to state; actions, the actions the need gates, and the atom gates no action the list leaves out; calls, the permission calls it makes, and it makes no call the list leaves out; arms, the permission's answers it reads, and it discards a permission answer the list leaves out, while a failure the Execution Contract answers, such as state-unavailable or storage-failure, is no answer of the permission and the needing atom lands it as the Execution Contract says (Read 1, Constituent failure 1 and Constituent failure 3).

Term permission offer fields: subject, the subject values a permission check may be asked for; scope, the action scopes a permission check may be asked for; calls, the permission calls offered; arms, every answer each of those calls gives, named per call.

Term permitted: the permission call that asks whether the subject holds the scope.

Term gated action: an action a permission need names under actions.

Term permission check: one permitted call, asked for one gated action under one scope.

Where a permission need stands: on an atom that gates an action of another atom, which is the check the paragraph after Term admission check lets cross the edge, and on an app's page, for an action the app gates before it calls an atom's action. An atom whose own call is gated declares no permission need: that check is its admission check, a rule of its offer, and the answer the atom lacks is an input the call takes (Direction 4). An app's gate is no atom's admission check: the app's page offers nothing (Bond 13), so its need runs down and nothing runs back to it.

```
permission 1: An offer MUST answer permitted ONLY IF the offer's records hold the check's subject with the check's scope in force AND MUST answer denied where the offer's records hold none.
permission 2: A needing atom MUST ask, ahead of EVERY call of a gated action, a permission check for EVERY scope the action is gated on AND MUST NOT take the action where a permission check answers denied.
permission 3: A needing atom MUST ask a permission check with, as the subject, the caller of the action the check is asked for.
permission 4: A needing atom MUST NOT read a permission check's answer for a later call of the action AND MUST NOT read one check's answer under a second scope.
permission 5: IF a permission check answers no answer THEN the needing atom MUST NOT take the action the check was asked for.
```

## Direction

Needs reach down; offers never look up (Scott, with GLM, 2026-11-24 7:54 AM Central: "this flattening will restore one way data flow"). An offering atom never learns which atom needs it: the only thing that ever pointed backwards was a name, and Bond 6 forbids it. A follow-up stays one-way by carrying its recipient as data, never as an edge.

Term layer: of an atom in an app, a whole number: 0 where no need of the atom is of a layered bond kind; otherwise one above the highest layer among the atoms whose offers serve the atom's needs of a layered bond kind. An atom sits at its layer by what it needs and never by what it offers.

Term layered bond kind: guard, journal and permission, the middle bond kinds, each one a need on another atom's offer for something the needing atom cannot keep itself. A key is data a record carries and sets no layer, so an atom's key need and key offer never move it.

Term admission check: an offering atom's own check of whether a call may happen.

A check whose answer lives inside the offering atom is a rule of its offer; a check on another atom's action that needs knowledge another atom owns, a policy that changes without a redeploy or a decision another atom makes, is a permission need and crosses the edge. An offering atom's own admission check is always a rule of its offer: where the check would need knowledge from outside the atom, that knowledge is a parameter of the offer, never a need. An offer's own check is a rule: no new term is written for it, since every obligation is already a rule.

```
Direction 1: The edges that run from a needing atom to the atom whose offer serves the need MUST form no cycle in an app.
Direction 2: IF the edges of an app form a cycle THEN the app's build MUST fail.
Direction 3: An app's build MUST compute the layer of EVERY atom from the atom's needs of the layered bond kinds ONLY.
Direction 4: An offering atom MUST state an admission check as a rule of the atom's offer AND MUST NOT declare an admission check as a need.
Direction 5: A need of a layered bond kind MUST meet an offer of an atom whose layer lies below the layer of the needing atom.
Direction 6: IF a need of a layered bond kind meets an offer of an atom whose layer does not lie below the layer of the needing atom THEN the app's build MUST fail.
```

## Status

`todo` — written by the unit `bonds: the fifty` (2026-11-23); the bond shape passed Scott's design review (2026-11-23 6:39 and 6:40 PM Central) once the unit `bonds: three fixes` gave the guard its clock, cut an arm no offer carries from guard 2 and gave Key its two rules. Final Critique 1 (2026-11-24), a full round of three readers in a scratch slot, frozen at ca124ecf, under the unit `pressure test: bonds, contracts, declarations, glue`: four foundational cured (a bond now forms by rule, an ambiguous need gets one bond instance, the guard's answers are told from the Execution Contract's failures, one instance of an atom serves every need it meets), three filed as design questions for Scott (a need that meets no offer, key matching on pairs and carried by, arms tied to calls). Scott ruled on them (2026-11-23 10:56 PM Central, "as recommended") in the unit `bonds: five rulings` (2026-11-24): an unmet need fails an app's build (Bond 10, Bond 11), Bond 3 reads pairs within carried by, an offer names its arms per call, a guard call that answers no answer stops writes until a new take (guard 4), and a bond kind is written only when a line lands on it. Final Critique 2 (2026-11-24), a delta round of one reader (Linus) in a scratch slot, frozen at b6ad4b52 from diff base ca124ecf, under the unit `library: the files match the tree`: four foundational cured (an ambiguous need is served by the one instance its bond instance names, Bond 9 and Bond 12; guard 2 covers try_take; Bond 2 binds each field to the offer's field of the same name; Bond 3 reads each arm against any of the need's calls, as the gate does), two refining cured (a bond instance names an offer the need meets; an atom read alone may meet no offer); not clean, and its cures owe a delta round. The unit `bonds: journal` (2026-11-24) added the bond kind journal and the section *Direction* (one-way flow, the cycle the gate fails, the layer order and the admission check), ruled by Scott 2026-11-24 7:36 to 7:54 AM Central; it passed his design review (2026-11-24 9:47 AM Central, "AR"). The unit `bonds: journal, finished` (2026-11-24) followed the ruling and GLM's review of this page: a read of one record is a read of the range that holds its place (journal 7), the tamper and the stream are need fields (journal 8; the tamper a typed field), a need whose keep exceeds the offer's keep meets nothing (journal 9), an atom's layer is computed from its needs of the layered bond kinds and a key sets none (Direction 3, 5 and 6, the gate's B-app-layer), an offering atom's own admission check is always a rule of its offer (Direction 4's text); step 4 of the ruling, the attested append as a need field, stopped for his review: no journal offer's record carries an actor and the credential check is a call whose answer another atom decides, so the held lines wait on the app page for `bonds: permission`. The unit `bonds: permission` (2026-11-24, from GLM's pin-down of the kind, as Scott's session designed it) wrote the kind: an app's page may carry a need line and never an offer line (Bond 13, Term app page need, the gate's B-app-offer), subject and scope are typed fields, and Permissions offers it; no guard, key or journal can say a standing given and taken back with no redeploy (the paragraph *Why a kind* under Permission). The unit `bonds: the fixes` (2026-11-25, ruled by Scott 10:48 AM Central and designed in his session): Bond 2 reads both ways, so a need naming a declaration type meets an offer naming a word of it, as the gate already matched; Bond 3 no longer reads a key need's pairs against the offer's carried by, and carried by names only the offering atom's own records, reversing that clause of `bonds: five rulings` by his later rulings on Direction (2026-11-24 7:54 AM Central) and the to-do design (2026-11-24 2:03 PM Central), since an offer would otherwise have to list the records of every atom that needs it; Key 1 still binds the needing atom's records. The unit `bonds: on end` (2026-11-25, ruled by Scott 10:48 AM Central, "basic DB stuff applied at the source" at 10:33 AM, step 2 reshaped by GLM's cross-check at 11:45 AM): the key offer gains ends and the key need on end, the follow-up of a deleted record as two fields of the key bond rather than a new bond kind (Key 3 through 8); it runs on Task and Ordering only and waits for his design review before any other atom takes the fields. The unit `bonds: every atom mints its id` (2026-11-25, ruled by Scott 3:22 PM Central, "Yes") wrote Key 9 through 20: an atom whose records are acted on one at a time mints and offers an id from birth, a link record and an extension record mint none, the id is named for what it names and declared, and an id grants nothing; the atoms take their ids as the bonding converter rewrites them, and the Key section owes a delta round.

NOTE: End of Bonds.
