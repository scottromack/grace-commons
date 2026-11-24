---
title: Declarations
nav_order: 9
parent: The Library
has_toc: true
toc: true
---

# Declarations

## What it is

The declaration space: the words two or more atoms use, declared once and owned by no atom (Scott, 2026-11-23 5:23 PM Central: "I have no problems with some sort of global declaration space"; 5:26 PM: "it is a pattern not a 'page'"). An atom may use a word declared here, as it uses a word the Execution Contract declares; it may not use another atom's term. Each declaration is a name, a type and one line of meaning, in the corpus's own `Term` form, and the gate reads this page as it reads a pattern (`tools/grace/check.py`). It holds only the words the Needs and Offers lines of the atoms use as a field's value, and it is not [the glossary](./glossary.md), which defines English words for readers.

## Declarations

```
Declaration 1: EVERY declaration MUST carry a name, a type and one line of meaning.
Declaration 2: An atom MAY use a declared word ONLY IF the atom's Term cited line names the word under Declarations.
Declaration 3: An atom MUST NOT declare a word this page declares.
```

Term declaration type: opaque | duration.

Term opaque: a value compared by byte identity and never read for meaning.

Term duration: a length of time.

### The words

Term invocation id: opaque — injected at the adopter's seam alongside now, fresh per invocation, unique across every node of the instance for the journal's lifetime; every record written for the invocation carries it.

Term act key: opaque — the key an adopter gives an act, adopter-typed: the field or tuple under which two invocations are one act attempted twice where repeatable is no, and two acts where repeatable is yes; the critical section is keyed by it, the pre-check reads by it, and a finding names it.

Term critical section key: opaque — `(kind, act_key)`, the pair as one key of a guard, alike on every node of the instance.

Term critical section holder: opaque — the value naming one take of an act's critical section, so that no two takes carry one value: the invocation id for an invocation, the run id together with the examined intent's invocation id for a sweep run's take, and the operator run id for an operator's closing.

## Status

`todo` — written by the unit `bonds: the fifty` (2026-11-23); passed Scott's design review with the bond shape (2026-11-23 6:39 and 6:40 PM Central).

NOTE: End of Declarations.
