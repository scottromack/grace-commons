---
title: The Method
nav_order: 2
has_children: true
---

# The Method

How canonical intent gets authored, defended, verified, and compiled here. The four documents below are a **sequence, not a menu** — each assumes the one before it — and this ordering is the piece of intent a flat sidebar could never carry.

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

The AI vote on Alloy or TLA+ is a triage gate, not a loop: it decides what gets built, and everything below it loops.

Loops cost, so the cheap ones (1, 2, 4, 5) run on every commit, the expensive ones (3, 6, 7) only on what a change reaches, and experiments (8) only where a decision is open.

## The four documents

1. **[The Spec Layer](./the-spec-layer.md)** — the architecture: why structured natural language is the canonical artifact and code is derived.
2. **[Earning Source of Truth](./positioning.md)** — what that claim costs, and where this sits in the lineage of everyone who claimed it before.
3. **[Pressure Testing](./pressure-testing.md)** — the review discipline that takes a spec from draft to `grounded`, including the formal layer that proves it.
4. **[Execution Contract](./execution-contract.md)** — the deterministic compilation target a grounded spec lowers to.

Read in order.
