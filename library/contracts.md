---
title: Contracts
nav_order: 5
---

# Contracts

## What it is

An outside-world contract is what an app asks of a system that is not Grace's: a database, a service, a device (Scott, 2026-11-23 6:40 PM Central: "Proceed to the outside-world contract pattern so the 31 can shrink"). It is stated once, here, and tested at the edge, where the outside system connects, never trusted: what Grace does not prove inside itself is named here and checked there. An atom states a contract need the way it states a bond need ([Bonds](./bonds.md)), by the contract's name and the words of [the declaration space](./declarations.md), and never names the outside system. A Grace pattern an app composes is no outside system, and nor is the database the Execution Contract's Database rules already hold: neither is a contract.

## The contract line

Term contract need line: a `Term contract need <contract>:` declaration on an atom, under the atom's Needs, one for each contract the atom needs: each contract field as the field's name and the field's value, the fields separated by semicolons.

Term contract fields: asks, what the atom asks of the outside system; answers, the answers the outside system may give, and the atom reads no other; bound, the bound the outside system must answer within, a bound the atom declares.

Term edge test: the rules of a contract that a connection runs against the outside system before an app trusts an answer of the outside system; each contract states its own.

Term variant: a declared way an outside system keeps a contract differently, which the contract lists and an app declares among its bindings.

Term app: the app that composes the atoms whose contract needs name the contract, and that declares the contract's variants and binds its outside system.

Term connection: the link over which an app reaches the outside system that keeps a contract; the edge test runs on it.

Term unanswered: an answer of an outside system that does not arrive within the bound the contract need declares, that is none of the arms the outside system states, or that comes over a connection whose edge test has not passed.

```
Contract 1: A contract MUST NOT name the outside system that keeps the contract.
Contract 2: An app MUST NOT trust an answer of an outside system BEFORE the contract's edge test has passed on the connection the answer came over.
Contract 3: An app MUST declare a variant of a contract ONLY IF the contract lists the variant.
Contract 4: An app MUST NOT rely on a need no contract and no variant states BEFORE the app records the need as a finding against the app or as evidence for the contract's next revision.
Contract 5: The contract a contract need names MUST meet the need; no atom offers a contract, and the app meets the need at the edge (Contract 2).
Contract 6: A contract need MAY name an answer ONLY IF the contract states the answer.
```

## Commit

Term commit contract: the call that makes an act in a database that is not Grace's, under an act key, answering on arms the database states.

Term commit variants: minted key — the commit mints the act's key.

```
Commit 1: An app MUST transcribe EVERY arm of the commit as EXACTLY ONE OF pre-commit, committed, unknown, as the database states the arm.
Commit 2: An app MUST NOT write to the records the commit makes.
Commit 3: WHEN the commit mints the act's key:
    Commit 3a: The app MUST bind the key the app can name before the commit as the act key.
    Commit 3b: The app MUST declare the act probe that finds the minted record from the bound key.
    Commit 3c: IF no read of the database finds the minted record from the bound key THEN the app MUST declare the act probe undecidable for EVERY act the commit makes.
    Commit 3d: The app MUST declare the minted key variant.
Commit 4: IF the commit's answer is unanswered THEN the app MUST transcribe the commit as unknown.
```

### Commit edge test

```
Commit edge 1: A connection MUST show, from the database's own declaration of the commit's arms, that EVERY arm lands in EXACTLY ONE of pre-commit, committed and unknown.
Commit edge 2: A connection MUST show that a commit the database answers on a pre-commit arm leaves no record the act probe finds.
Commit edge 3: A connection MUST show that a commit the database answers on a committed arm leaves a record the act probe finds.
```

## Act probe

Term act probe contract: a read of the database the act was made in, keyed by act key and the pairing datum, that answers EXACTLY ONE OF committed (with the act's outcome), not-committed, undecidable, unavailable.

Term pairing datum: the value an app binds beside the act key so that the act probe tells one invocation's act from another's: a seam-injected now, an adopter-minted value the database stores, or none.

```
Act probe 1: An app MAY bind a seam-injected now as the pairing datum ONLY IF no two serialized invocations of one act key carry the same reading on any node of the instance.
Act probe 2: An app MUST declare the obligation Act probe 1 names where the pairing datum is a seam-injected now.
Act probe 3: WHEN the pairing datum EQUALS none:
    Act probe 3a: The act probe MUST NOT answer committed.
Act probe 4: IF a record under the act key EXISTS AND the pairing datum EQUALS none THEN the act probe MUST answer undecidable.
Act probe 5: IF the act probe's read is unanswered THEN the act probe MUST answer unavailable.
Act probe 6: IF more than one record of the database matches the pairing datum THEN the act probe MUST answer undecidable.
```

### Act probe edge test

```
Act probe edge 1: A connection MUST show that the act probe reads the database the commit writes to.
Act probe edge 2: A connection MUST show that the act probe answers unavailable, and never not-committed, to a read the database refuses.
Act probe edge 3: A connection MUST show that the act probe's read finds the record of EVERY commit the database answered committed before the read began.
Act probe edge 4: A connection MUST show that the act probe answers undecidable, and never committed, where the pairing datum EQUALS none and a record under the act key exists, and where more than one record matches the pairing datum.
```

## Status

`todo` — written by the unit `contracts: the outside world` (2026-11-24); passed Scott's design review (2026-11-23 9:41 PM Central). Final Critique 1 (2026-11-24), a full round of three readers in a scratch slot, frozen at ca124ecf, under the unit `pressure test: bonds, contracts, declarations, glue`: five foundational cured (the words the rules use declared, the act probe's four answers and undecidable with no pairing datum, an unanswered call landed, the edge tests made two-sided, a contract need met by the contract it names).

NOTE: End of Contracts.
