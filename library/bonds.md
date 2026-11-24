---
title: Bonds
nav_order: 4
has_toc: true
toc: true
---

# Bonds

## What it is

A bond is how two atoms connect without either naming the other (Scott, 2026-11-23 5:17 PM Central, on the bond shape; 5:19 PM: "make atoms truely atomic"). A bond kind is stated once, here. Each atom states what it needs, on a Needs line, and what it offers, on an Offers line, each line of a kind this page states and typed by the words of [the declaration space](./declarations.md). Where an app picks two atoms and one's need meets exactly one offer, the bond forms and the app writes nothing; an app writes a bond only where a need could meet more than one offer. No bond instance lives outside an app, and no page stands between atoms as a container. This page names no atom.

It holds the kinds lines have landed on, and no others: guard and key, which the first fifty bond-candidate lines landed on, and journal. A kind is written here when a line lands on it, and not before, and only when a need cannot be said with the kinds that exist, shown in writing beside the kind (Scott, 2026-11-24 7:36 to 7:52 AM Central: "as small as possible but not smaller"). The law of the bonds: needs bind to kinds, offers stand on atoms, and no name crosses an edge.

## The bond line

Term need line: a `Term need <kind>:` declaration on an atom, one for each kind the atom needs: each need field of the kind as the field's name and the field's value, the fields separated by semicolons.

Term offer line: a `Term offer <kind>:` declaration on an atom, one for each kind the atom offers, in the need line's form, with the kind's offer fields.

Term typed field: a field whose value is a word the declaration space declares or a type it names; key, holder and span are typed fields.

Term list field: a field whose value is a list of words, separated by commas; calls, a need's arms, writes, carried by and pairs are list fields.

Term per-call field: a field whose value names, for each call of the line's calls, the call, a colon and the call's words as a list, the calls separated by slashes; an offer's arms is a per-call field.

Term ambiguous need: of an app, a need that meets one offer of the app's atoms and a second.

Term meets: a need meets an offer where the two lines satisfy Bond 1, Bond 2 and Bond 3.

Term unmet need: of an app, a need of one of the app's atoms that meets no offer of the app's atoms. A contract need is no bond need: the app meets it at the edge ([Contracts](./contracts.md), Contract 5).

Term bond instance: the line an app writes naming an ambiguous need and the one offer, of the offers the need meets, that serves it.

```
Bond 1: A need MAY meet an offer ONLY IF the two lines name one kind AND the two lines stand on two atoms.
Bond 2: A need MAY meet an offer ONLY IF, for EVERY typed field of the need, the need's field names the same word the offer's field of the same name names, or the offer's field of the same name names a declaration type and the need's field names a word of that type.
Bond 3: A need MAY meet an offer ONLY IF EVERY word of the need's calls IS IN the offer's calls AND EVERY word of the need's arms IS IN the arms the offer names for one or more of the calls the need's calls name AND EVERY word of the need's pairs IS IN the offer's carried by.
Bond 4: An app MAY write a bond instance ONLY IF a need of one of the app's atoms is an ambiguous need.
Bond 5: A bond instance MUST NOT stand outside an app.
Bond 6: A need line MUST NOT name an atom.
Bond 7: IF a need of one of the app's atoms is an ambiguous need THEN the app MUST write one bond instance for the need.
Bond 8: IF a need of one of the app's atoms meets EXACTLY ONE offer of the app's atoms THEN that offer MUST serve the need.
Bond 9: EXACTLY ONE instance of an atom MUST serve EVERY need of the app that meets one of the atom's offers AND is no ambiguous need.
Bond 10: IF a need of one of the app's atoms is an unmet need THEN the app's build MUST fail.
Bond 11: A need of an atom read alone, outside any app, MAY meet no offer.
Bond 12: IF a need of one of the app's atoms is an ambiguous need THEN EXACTLY ONE instance of the atom whose offer the need's bond instance names MUST serve the need.
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

Term key need fields: key, the value the needing atom pairs on; pairs, the records it pairs on the key.

Term key offer fields: key, the value the offering atom mints; carried by, every record that carries the value, whichever atom writes the record.

```
Key 1: EVERY record a key need names under pairs MUST carry the key the meeting offer mints.
Key 2: Two atoms of an app MUST NOT offer one key, an ambiguous need the app writes a bond instance for excepted (Bond 7).
```

## Journal

Why a kind: an atom that appends its records to a store it never changes and reads them back in order cannot say so with a guard, which is one holder over a key, or a key, which is a value records carry; so the need could not be said with the kinds that existed, and journal is written.

Term journal: records an atom appends, which the offer keeps, and which the atom reads back by range. The kind has three verbs and no more: append, keep, read by range.

Term journal need fields: records, the records the needing atom appends; calls, the journal calls it makes, and it makes no call the list leaves out; arms, the journal's answers it reads, and it discards a journal answer the list leaves out, while a failure the Execution Contract answers, such as state-unavailable or storage-failure, is no answer of the journal and the needing atom lands it as the Execution Contract says (Read 1, Constituent failure 1 and Constituent failure 3); keep, how long it needs each record it appends kept, where it needs a keeping period the offer's keep does not already give.

Term journal offer fields: calls, the journal calls offered; arms, every answer each of those calls gives, named per call; keep, how long the offer keeps a record, the type duration where the app sets it to the keep of the needs it serves; tamper, how a change to a kept record shows, or none where nothing shows it; order, the order a read by range answers in, per stream at least.

Term append: the journal call that adds one record at the end of a stream and answers the record's place in the stream's order.

Term read: the journal call that answers the records whose places lie in a range of one stream's order, in that order.

Term stream: the records one offer keeps in one order.

Term place: a record's position in its stream's order.

```
journal 1: An offer MUST keep EVERY record an append answered a place for, unchanged, for the keep of EVERY need the offer serves.
journal 2: A read MUST answer EVERY record whose place lies in the range AND no other record, in the stream's order.
journal 3: IF a read is issued after an append answered AND the read's range holds the appended record's place THEN the read MUST answer the appended record.
journal 4: A needing atom MUST read a range ONLY within one stream's order.
journal 5: A journal need MUST NOT ask for a record by the record's content AND MUST NOT ask to be told of a record appended later.
journal 6: An atom that needs a keeping period other than the offer's keep MUST state the period as the keep of the atom's need.
```

## Direction

Needs reach down; offers never look up (Scott, with GLM, 2026-11-24 7:54 AM Central: "this flattening will restore one way data flow"). An offering atom never learns which atom needs it: the only thing that ever pointed backwards was a name, and Bond 6 forbids it. A follow-up stays one-way by carrying its recipient as data, never as an edge.

Term layer order: keys at the bottom; journal and permission in the middle; the atoms that offer none of these on top.

Term admission check: an offering atom's own check of whether a call may happen.

A check whose answer lives inside the offering atom is a rule of its offer; a check that needs knowledge another atom owns, a policy that changes without a redeploy or a decision another atom makes, is a need and crosses the edge. An offer's own check is a rule: no new term is written for it, since every obligation is already a rule.

```
Direction 1: The edges that run from a needing atom to the atom whose offer serves the need MUST form no cycle in an app.
Direction 2: IF the edges of an app form a cycle THEN the app's build MUST fail.
Direction 3: An atom MUST sit at the layer of the kinds the atom offers AND MUST NOT sit at the layer of a kind the atom only needs.
Direction 4: An offering atom MUST state an admission check as a rule of the atom's offer AND MUST NOT declare an admission check as a need.
```

## Status

`todo` — written by the unit `bonds: the fifty` (2026-11-23); the bond shape passed Scott's design review (2026-11-23 6:39 and 6:40 PM Central) once the unit `bonds: three fixes` gave the guard its clock, cut an arm no offer carries from guard 2 and gave Key its two rules. Final Critique 1 (2026-11-24), a full round of three readers in a scratch slot, frozen at ca124ecf, under the unit `pressure test: bonds, contracts, declarations, glue`: four foundational cured (a bond now forms by rule, an ambiguous need gets one bond instance, the guard's answers are told from the Execution Contract's failures, one instance of an atom serves every need it meets), three filed as design questions for Scott (a need that meets no offer, key matching on pairs and carried by, arms tied to calls). Scott ruled on them (2026-11-23 10:56 PM Central, "as recommended") in the unit `bonds: five rulings` (2026-11-24): an unmet need fails an app's build (Bond 10, Bond 11), Bond 3 reads pairs within carried by, an offer names its arms per call, a guard call that answers no answer stops writes until a new take (guard 4), and a kind is written only when a line lands on it. Final Critique 2 (2026-11-24), a delta round of one reader (Linus) in a scratch slot, frozen at b6ad4b52 from diff base ca124ecf, under the unit `library: the files match the tree`: four foundational cured (an ambiguous need is served by the one instance its bond instance names, Bond 9 and Bond 12; guard 2 covers try_take; Bond 2 binds each field to the offer's field of the same name; Bond 3 reads each arm against any of the need's calls, as the gate does), two refining cured (a bond instance names an offer the need meets; an atom read alone may meet no offer); not clean, and its cures owe a delta round. The unit `bonds: journal` (2026-11-24) added the kind journal and the section *Direction* (one-way flow, the cycle the gate fails, the layer order and the admission check), ruled by Scott 2026-11-24 7:36 to 7:54 AM Central; it waits for his design review.

NOTE: End of Bonds.
