---
title: On the Shoulders of Giants
nav_order: 1.55
---

# On the Shoulders of Giants

Did we copy Daniel Jackson? Yes. We took his idea as far as we could, and it worked. We copied every good idea we could find, even NASA's.

Designers are taught to copy. The rule that goes with it: understand what you copy, or you copy the bad along with the good. So each line below says what we took and why.

- **Daniel Jackson, *The Essence of Software*.** The concept: one purpose, freestanding, composed with others. Our atoms and compositions are his.
- **NASA FRET.** A closed list of sentence forms, each with one fixed meaning. NASA did it for signals and timing; we are doing it for records.
- **TLA+ and Alloy.** Every claim a model can state, a model checks.
- **Eiffel's design by contract.** What must be true before, after, and always.
- **BDD and Gherkin.** Examples in structured English are a specification.
- **Unix.** Do one thing well, and work together: small pieces, loosely joined (David Weinberger's phrase). Concepts are the same idea one level up, so Jackson stood on shoulders too.
- **Grace Hopper's COBOL.** The business should be able to read what the system does.
- **Christopher Alexander, *A Pattern Language*.** A library of named patterns that compose. It inspired this one from afar; we knew to look there.

## Common practice, applied one layer up

None of these is ours, and none was a revelation. They are ordinary engineering practice for code. We apply them to the pattern above the code.

- **RFC 2119.** MUST, MUST NOT and MAY as words with fixed meaning.
- **Mutation testing** (DeMillo, Lipton and Sayward, 1978). Plant a fault and see whether the checks notice.
- **Hostile-world testing**, as Jepsen and FoundationDB's simulation do it: lost answers, failed writes, races.
- **The seam** (Michael Feathers, *Working Effectively with Legacy Code*), and recording what old code does before changing it.
- **Decide first, then act** (Gary Bernhardt's functional core, imperative shell).
- **The strangler fig** (Martin Fowler). Replace an old system a piece at a time.

## What we added

The patterns are the source and the code is derived.

The full lineage is on [The Spec Layer](the-spec-layer.html).
