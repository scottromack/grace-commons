---
title: Declarations
nav_order: 2
has_toc: true
toc: true
---

# Declarations

## What it is

The declaration space: the words two or more atoms use, declared once and owned by no atom (Scott, 2026-11-23 5:23 PM Central: "I have no problems with some sort of global declaration space"; 5:26 PM: "it is a pattern not a 'page'"). An atom may use a word declared here, as it uses a word the Execution Contract declares; it may not use another atom's term. Each declaration is a name, a type and one line of meaning, in the corpus's own `Term` form, and the gate reads this page as it reads a pattern (`tools/grace/check.py`). It holds the words the Needs and Offers lines of the atoms use as a field's value, every id an atom mints ([Bonds](./bonds.md) Key 18), and the record types an atom appends to a journal, which one atom alone may append (Scott's to-do design, 2026-11-24 2:03 PM Central, "Declarations owed"). A word only a contract's rules use is that contract's, stated on [Contracts](./contracts.md), as the pairing datum is. It is not [the glossary](../how/glossary.md), which defines English words for readers.

## Declarations

```
Declaration 1: EVERY declaration of a word MUST carry a name, a type and one line of meaning.
Declaration 2: A specification MAY use a declared word ONLY IF the specification's Term cited line names the word under Declarations.
Declaration 3: A specification MUST NOT declare a word this page declares.
Declaration 4: A declared word that a key offer names as the offer's key MUST name ONE key in an app AND ONE atom of the app MUST mint the key (Bonds Key 2).
```

Term declaration type: opaque | duration.

Term opaque: a value compared by byte identity and never read for meaning.

Term duration: a length of time.

### The words

Term sealed: opaque — the tamper evidence a record carries when a seal covers it, so that a change to the record shows when the seal is checked.

Term closing record: opaque — the record type of a record that closes an invocation: an outcome record, a `<kind>.refused`, a `<kind>.abandoned` or a `<kind>.escalated`; a `<kind>.recovery_intended` is none.

Term invocation journal: opaque — the stream of a journal that holds every record of an invocation's act, its intent and every closing of it, whoever writes them.

Term invocation id: opaque — injected at the adopter's seam alongside now, fresh per invocation, unique across every node of the instance for the journal's lifetime; every record written for the invocation carries it.

Term act key: opaque — the key an adopter gives an act, adopter-typed: the field or tuple under which two invocations are one act attempted twice where repeatable is no, and two acts where repeatable is yes; the critical section is keyed by it, the pre-check reads by it, and a finding names it.

Term critical section key: opaque — the act's kind and its act key as one key of a guard, in an encoding that gives two different pairs two different values, the same on every node of the instance.

Term critical section holder: opaque — the value naming one take of an act's critical section, so that no two takes carry one value: the invocation id for an invocation, the run id together with the examined intent's invocation id for a sweep run's take, and the operator run id for an operator's closing.

Term actor id: opaque — the one value naming a party who acts, the same in every record that names that party.

Term task id: opaque — the one value naming a task, minted when the task is made and never reused.

Term session id: opaque — the one value naming one session, minted by the host when the session opens; it grants nothing.

Term list id: opaque — the one value naming a list of tasks, minted when the list is made and never reused.

Term workflow id: opaque — the one value naming one running workflow, minted when the workflow is made and never reused.

Term history entry id: opaque — the one value naming one recorded transition of a running workflow, minted when the history entry is appended and never reused in its workflow.

Term party id: opaque — the one value naming one external party, minted when the party is enrolled and never reused.

Term chain id: opaque — the one value naming one custody chain, minted when the chain is originated and never reused.

Term preference id: opaque — the one value naming one preference record, minted when the record is set and never reused in one database instance.

Term place id: opaque — the one value naming one place where dates are read, minted when the place is opened and never reused.

Term task events: opaque — the record type of the journal records a to-do app appends for a task's actions; plain, carrying no seal.

Term assignment events: opaque — the record type of the journal records a to-do app appends for an assignment's actions; plain, carrying no seal.

Term invitation events: opaque — the record type of the journal records a to-do app appends for an invitation's actions; plain, carrying no seal.

## Status

`todo` — written by the unit `bonds: the fifty` (2026-11-23); passed Scott's design review with the bond shape (2026-11-23 6:39 and 6:40 PM Central). Final Critique 1 (2026-11-24), a full round of three readers in a scratch slot, frozen at ca124ecf, under the unit `pressure test: bonds, contracts, declarations, glue`: three foundational cured (Declaration 1 binds a word's declaration, Declaration 2 and 3 bind every specification, the critical section key's encoding keeps two pairs apart), one held for Scott (the meanings use words the page does not declare). The unit `bonds: the fixes` (2026-11-25, ruled by Scott 10:48 AM Central) declared `closing record` and `invocation journal`, which three atoms' need lines use. The unit `bonds: every atom mints its id` (2026-11-25, ruled by Scott 3:22 PM Central) made the page hold every id an atom mints (Bonds Key 18); the scope line owes a delta round.

NOTE: End of Declarations.
