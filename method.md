---
title: The Method
nav_order: 2
has_children: true
---

# The Method

How canonical intent gets authored, defended, verified, and compiled here. The two documents below are a **sequence, not a menu** — each assumes the one before it — and this ordering is the piece of intent a flat sidebar could never carry.

## Grace closes loops

Every boundary between layers is a seam where drift can hide, and every seam gets a loop: the downstream artifact proves itself against the source above it, never the reverse.

```
  INTENT   what we want
     │                                             ▲
     ▼                                             │
  SPEC  ◄── 1  grammar     check.py + lint.py   ✓  │
   │    ◄── 2  IR          ir.py --check        ✓  │
   │    ◄── 3  readers     council rounds       ✓  │
   │                                               │
   ├──►  FORMAL MODELS                             │
   │       ◄── 4  buggy twins                   ✓  │
   │       ◄── 6  normalizer + reverse diff     ◐  │
   │                                               │
   ├──►  TESTS + GHOST SCENARIOS                   │
   │       ◄── 5  generated suites              ✓  │
   ▼                                               │
  RENDERED CODE                                    │
   │    ──► 7  loop-back: ghost run, seam          │
   │           trace checked against spec       …  │
   ▼                                               │
  LIVE USERS ── 8  experiments + UX testing  ○  ───┘

  ✓ enforced   ◐ advisory   … building   ○ planned
```

Loops cost, so the cheap ones (1, 2, 4, 5) run on every commit, the expensive ones (3, 6, 7) only on what a change reaches, and experiments (8) only where a decision is open.

## Principles

### The information-management triad

**The information-management triad** is the architecture's specific contribution. These three principles produce most of the Spec Layer's shape when applied at the intent level rather than the code level:

- **DRY** (Don't Repeat Yourself) → *Don't Repeat Intent.* Every concept is defined once and referenced, not duplicated. The atom-and-composition split makes this structural rather than aspirational: an atom is freestanding intent named in one place; a composition names the atoms it composes by reference, never by re-stating them.
- **SSOT** (Single Source of Truth) → *One Canonical Intent Layer.* The spec is canonical; code, tests, documentation, contracts, runbooks are derived. Competing sources of truth disappear by construction — there is one place where the system's intent lives, and everything else regenerates from it.
- **Explicit over Implicit** → *No Hidden Semantics Across Boundaries.* The load-bearing decisions — identity, normalization, atomicity, clock semantics, what an action returns, what gets rejected and why — are stated, not inferred. Decisions deferred dressed up as ambiguity are a defect that pressure-testing catches.

These three together solve the multi-artifact-truth-distribution problem the Spec Layer exists to solve. They are what makes this architecture different from existing requirements engineering, BDD, design-by-contract, and the other traditions the Inheritance section names. Each of those touches one or two of the three; only the synthesis applies all three simultaneously.

### The bridge test

**The litmus test for every future addition:** *Does this build a bridge, or does it build a wall?* Walls exclude an audience to optimize for another. Bridges accommodate both. The architecture optimizes for bridges by default — that is what *appropriate technology* means in this context.

## The two documents

1. **[Pressure Testing](./pressure-testing.md)** — the review discipline that takes a spec from draft to `grounded`, including the formal layer that proves it.
2. **[Execution Contract](./execution-contract.md)** — the deterministic compilation target a grounded spec lowers to.

Read in order.
