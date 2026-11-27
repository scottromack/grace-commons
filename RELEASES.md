# Releases

Grace Commons is versioned by minor version on the way to 1.0.0: 0.1 bonds and every atom converted, 0.2 the grammar at 100% (every rule line one tree), 0.3 the Lean statements generated from the trees, 0.4 code and tests from the trees, 1.0.0 the shared to-do app shipped; dissolving the compositions comes after 1.0.0. The minor versions are numbered in the order they close (Scott, 2026-11-27). Atoms keep their own semantic versions. Each entry is generated from the commit subjects between two tags (`assets/release-notes.py` in grace-council), never written by hand.

v0.1.0 closes the first milestone: every atom converted to the bond shape, key bonds checked on write, and every pattern's numbers stated as measured.

## v0.1.0 — 2026-11-27

263 commits since v0.0.0.

### atom

- atom: Notification, review cures — Invariant 2.4 states the read, the Needs position, the ledger restored, 759 lines (5e64b614)
- atom: Lease, review cures — the joiner's rule, the ledger reconciled, the need position stated, 562 lines (75092da5)
- atom: Party Identity, GLM's remaining items — the lost-enroll read returns candidates, the rejection groupings defined, one owner noun (1fe5e1b4)
- atom: Retention Window, converted — the bond shape, its id, 865 lines, over 800 (da9bc143)
- atom: Capacity Constraint Enforcement, converted — the bond shape, its id, 1255 lines, over 800 (f6b08fd4)
- atom: Lease, converted — the bond shape, its id, 549 lines (81f09b8b)
- atom: Role, converted — the bond shape, its id, 637 lines (426120e9)
- atom: Comment, converted — the bond shape, its id, 633 lines (fec4f031)
- atom: Erasure Tombstone, converted — the bond shape, its id, 600 lines (3cdb980f)
- atom: Moderation, converted — the bond shape, its id, 630 lines (98c98bca)
- atom: Subscription, converted — the bond shape, its id, 650 lines (c733aac1)
- atom: Selective Disclosure, converted — the bond shape, its id, 608 lines (5f7552ac)
- atom: Category, converted — the bond shape, its id, 778 lines (25d92174)
- atom: Cart, converted — the bond shape, its id, 728 lines (c1ac5f24)
- atom: Condition Register, converted — the bond shape, its id, 763 lines (ae6d2e48)
- atom: Notification, converted — the bond shape, its id, 745 lines (2ad5341b)
- atom: Tenure, converted — the bond shape, its id, 759 lines (43c8520f)
- atom: Owed Record, converted — the bond shape, its id, 743 lines (c2bb7a0b)
- atom: Legal Hold, converted — the bond shape, its id, 736 lines (c5c5da22)
- atom: Waitlist, converted — the bond shape, its id, 783 lines (d0951829)
- atom: Money, converted — the bond shape, its id, 765 lines (ed8252ce)
- atom: Tamper Evidence, converted — the bond shape, its id, 730 lines (c8022f4f)
- atom: Communication, converted — the bond shape, its id, 784 lines (d943599b)
- atom: Provisional Commitment, converted — the bond shape, its id, 800 lines (722a01c0)
- atom: Recurrence, converted — the bond shape, its id, 869 lines, over 800 (81b43b67)
- atom: Capability, converted — the bond shape, its id, 881 lines, over 800 (da39461b)
- atom: Observation, converted — the bond shape, its id, 850 lines, over 800 (c674e555)
- atom: Approval Step, converted — the bond shape, its id, 863 lines, over 800 (ca7095b1)
- atom: Consent, converted — the bond shape, its id, 871 lines, over 800 (b8844734)
- atom: Medication Order, converted — the bond shape, its id, 1407 lines, over 800 (efaa2bcb)
- atom: Invitation, a pending invitation ends with its list — on end for the list id (45e3af35)
- atom: Party Identity, review cures — the journal is a need, every label tombstoned, 961 lines (7058080c)
- atom: State Machine, review cures — the actor gate, every label tombstoned, the history refusals owned, 1022 lines (772fe781)
- atom: Calendar Time, converted — the bond shape, its id, under 800 (9b2b0933)
- atom: Message Preference, converted — the bond shape, its id, under 800 (6f81bf69)
- atom: Provenance, converted — the bond shape, its id, under 800 (7c871bf7)
- atom: Party Identity, converted — the bond shape, its id, under 800 (2a39051c)
- atom: State Machine, converted — the bond shape, its id, under 800 (c00e24f8)
- atom: Session, bonded — a session carries its actor id (01e90572)
- atom: Invitation, bonded — to one list, between actor ids (4d95b1af)
- atom: Permissions, bonded — grants keyed on actor id (eb0663cb)
- atom: Assignment, bonded — a task id, an actor id, a journal (153bc911)
- atom: Credential, bonded — a credential belongs to one actor id (8d6e8a86)
- atom: Actor Identity, bonded — it mints the actor id (ce2ea9c5)
- atom: Personal Todo becomes Task (47c9ab5b)
- atom: Personal Todo, bonded — one list's tasks, its task id, its completer (6015eb7f)
- atom: List — makes a list, mints its id, holds its author (793bcdf0)
- atom: Ordering — one list's sequence, nothing more (2bf3e50e)

### bonds

- bonds: a key is checked on write — not-known on a missing record, through the offer's read (4151edcc)
- bonds: every atom mints its id — offered from birth, named for what it names, granting nothing (cd02f4c3)
- bonds: on end for lists and assignments — a deleted list takes its tasks, its sequence and their assignments (a9ea2e68)
- bonds: on end — a deleted task leaves no entry in Ordering (9b5fcf31)
- bonds: the fixes — needs meet both ways, offers name their own records, the journal's other writers, one pairing datum (45912569)
- bonds: the plane — any atom of the app; the flow writes no edges (c4c6068d)
- bonds: one plane of siblings — the route is the app's (1b90c8c2)
- bonds: permission — the fourth bond kind, and an app's page may carry needs (c9e42fba)
- bonds: the word is bond kind — Event Log's Offers line, held until its round settled (e54ae34e) (594d216a)
- bonds: the word is bond kind — never bare kind for a type of bond (1f757b57)
- bonds: journal, finished — one-record reads, the seal and keep on the need, layers by need; the attested append held for review (097687f5)
- bonds: journal — append, keep, read by range; Event Log offers it; Invitation converted; needs reach down, a cycle fails the app (0ea88b89)
- bonds: five rulings — an unmet need fails the app, key lists match, arms per call, silence voids the grant, kinds only as they land (811b07ff)
- bonds: Final Critique 1 — a bond forms by rule, an ambiguous need gets one bond instance, the guard's answers told from the Execution Contract's failures, one instance serves every need (b7074bda)
- bonds: three fixes — the guard's clock is the host's, guard 2's arms, the key's two rules (d82b6bd9)
- bonds: the fifty — kinds on the bonds page, needs and offers on the atoms (bca1baa7)

### Durable Intent

- Durable Intent: Final Critique 10 — a clean delta round; the cure of Final Critique 9 stands; the atom is done (2fe1b251)
- Durable Intent: Final Critique 9 — a start under a payload cap or an intent candidates cap that no longer holds the largest closing is refused, Primitive policy 13a; the page is doing (50e16153)
- Durable Intent: Final Critique 8 — the intent payload is what is sized, a bad outcome reference binds only where no closing stands, a check pairs over the journal; the page is doing (37bf244f)
- Durable Intent: Final Critique 7 — a delta round, clean; close step 2.2e and 2.2f in the blank form, one landing actor per outcome (d2567ff5)
- Durable Intent: Final Critique 6 — an operator's closing needs no recovery_intended and may have one; intent data named in the payload-cap refusal (fb5fbf96)
- Durable Intent: Final Critique 5 — a delta round, clean; Which closing stands 3 states the field, resolving actor declared (ca124ecf)
- Durable Intent: Final Critique 4 — a closing supersedes only a closing of its own invocation (3fe39f42)
- Durable Intent: Final Critique 3 — outcome data keeps the composition's closing fields out, grouping on the act key is no join, an entry needs a readable intent, act closings drop on retention, closing event id defined (2d539a5f)
- Durable Intent: Final Critique 2 — [Resolve]'s closings sized, the composition's own fields kept out of the caller's data, the completion bound holds [Open]'s write (1f9e50a4)
- Durable Intent: Final Critique 1 — [Refuse] and [Close] keep a failed closing's intent open, the page declares what its rules read (c58a26aa)

### site

- site: the .idd extension on Role — a pattern file pretested (04a65399)
- site: the table-of-contents line off every page — the stylesheet styles the label (b8697292)
- site: has_toc and toc dropped on every page — the table of contents renders from its block (88b2bd68)
- site: the table-of-contents label styled by the stylesheet — Role first (09de2f3a)
- site: the bond graph, layer 0 split — only atoms with bonds drawn (d6959a83)
- site: the bond graph made readable — hubs as tags, atoms by layer (299d65c4)
- site: has_toc and toc dropped on Role — the table of contents renders from its block alone (bd35b8ce)
- site: Join Us matches the menu — theme pin to the shared nav link look (ba771d94)
- site: Join Us in the navigation — the Discord invite, last at the top level (3c5732e6)

### Ordering

- Ordering: Final Critique 6 — a clean delta round; the atom stays done (7748eafc)
- Ordering: Final Critique 5 — a clean delta round; the example gains a rejected move of the removed item; the atom stays done (c652bbe8)
- Ordering: Final Critique 4 — a clean delta round; one refining cure, the atom is done (1cb3a905)
- Ordering: Final Critique 3 — one foundational cured (an action reads and writes only its own list's entries) (2f4dd26f)
- Ordering: Final Critique 2 — one foundational cured (the scope of an entry held) (6092edd6)
- Ordering: list id is the declared word — the local term goes, the list need names it (40741406)
- Ordering: Final Critique 1 — three foundational cured, sixteen refining, two rhetorical (ebcf718d)

### tooling

- tooling: grammar tree, the grammar's own cures — 5752/6219 rules one tree (f003ae83)
- tooling: grammar tree, the corpus coverage run — 5532/6185 rules one tree (dd1e9342)
- tooling: grammar tree, the pretest with English words — Money 79/80, State Machine 184/191 (6873ff06)
- tooling: grammar tree, the Money pretest — 64/80 one tree (d04c8af7)
- tooling: rounds read an app page — its atoms, bonds and declarations; the gate reads a bond instance (7c0c8f5b)
- tooling: the catalog — one generated line per atom, and the bond graph, for an AI to load first (9d266a5d)
- tooling: version tags and release notes — v0.0.0 tagged, notes generated from commit subjects (2ded87bc)

### Resolve a Person's Data Rights

- Resolve a Person's Data Rights: Final Critique 15 — Action wiring 43 and 44 read the request's latest intent of the act kind, the commit round trip's floor counts the commit's reads before the first planned call (4c758dc5)
- Resolve a Person's Data Rights: Final Critique 14 — the erasure's fulfilled event owns an invalid-credential, the purge retry runs to the first answer other than storage-failure, an obliged record names the retention that obliges, the re-entry bind runs once (b10cbf31)
- Resolve a Person's Data Rights: Final Critique 13 — the universe enumeration carries the route, the entry bound counts the run in flight, the retry's answer is stated (7537d5a1)
- Resolve a Person's Data Rights: Final Critique 12 — the re-entry bind's fulfilled event carries the enumeration instant by rule, the universe enumeration is every record a registered source answers for (5c30f3ef)
- Resolve a Person's Data Rights: Final Critique 11 — a blank request id answers not-known only where the state read answers (2080ac74)
- Resolve a Person's Data Rights: Final Critique 10 — Selective Disclosure's storage-failure, the refuse, open and close answers and the act-landed arm land by rule, the host delete re-read stops on a retention (c57445e7)

### Invitation

- Invitation: Final Critique 18 — a clean delta round; the Invalid Request description scoped by the Operations that oblige it, Operation 3 in the admitted form, the atom is done (83ab9a34)
- Invitation: Final Critique 17 — Term string cap cites Execution Contract Input 2, TTL glossed (0f3a7969)
- Invitation: Final Critique 15 — the journal append is the four writes' Operation 52, not a note on every action; a deleted Non-goal's cite dropped (0ab4b598)
- Invitation: Final Critique 14 — a clean delta round; two wording cures, the atom is done (de545159)
- Invitation: Final Critique 13 — a refused action's event is the composing pattern's, not the atom's; the page is doing (48225590)

### Lease

- Lease: Final Critique 13 — a clean delta round; the atom is done (7bee90c7)
- Lease: Final Critique 12 — a full round, foundational count 2, cured: a waiter that stood across a host restart is dropped from the line, and a blocking take's no-answer window is the longest duration plus the call pause bound (2f287cf7)
- Lease: Final Critique 11 — a delta round, clean; the citations in Term waiter's bound and Term waiter's last reading name the rule that states each sum (6ca28f5e)
- Lease: Final Critique 10 — a delta round; a [Take] arriving as a waiter is admitted joins the line behind the waiter (1ba131fd)
- Lease: Final Critique 9 — a delta round, clean; the admitted waiter stopped standing at its admission, Check 4.4 tests Operation 1a (7a2a4731)

### List

- List: Final Critique 4 — a clean delta round; no cure, the atom stays done (ac1904ad)
- List: Final Critique 3 — a clean delta round; List 2 and List 7 become tombstones, the atom stays done (f404c94b)
- List: GLM's critique cured — invalid-request, no named sibling, the lost heading (4a4063ea)
- List: Final Critique 2 — a clean delta round; five wording cures, the atom is done (0c6f8aaa)
- List: Final Critique 1 — the host owns the list id's no-reuse, names compare as exact code points, Delete List ends the record and says what undoes a write (51e582da)

### Sweep

- Sweep: Final Critique 5 — a clean delta round; the six refining findings are each decided by a rule of the corpus; the page is done (0d91df79)
- Sweep: Final Critique 4 — reconcile step 3.10 no longer says a cap of 1 carries a range naming one reference twice, Term acting actor reference and Term sweep closed ids read what their rules reach; the page is doing (699fb37e)
- Sweep: Final Critique 3 — a clean delta round, the page is done (d729c078)
- Sweep: Final Critique 2 — a read-back that fails has its own arm, Invariant 4.2 excepts what Escalation Check 3.3 exempts, a failed remaining query reads as not exceeding write floor (07887353)
- Sweep: Final Critique 1 — a refused credential is tried again by the next run, each journal write of an act is its own transaction, Term cited names its owners, the candidates are capped at the first of them, the read-back after invalid-request(step-4) has both arms (817faf2c)

### Task

- Task: Final Critique 15 — the lists the new action left out now name it, and its case rows cite what they should; the page stays done (6d3d7648)
- Task: Final Critique 14 — the window is only the call's, Operation 46 is guarded as Operation 45 is; the page is done (4b89d32b)
- Task: Final Critique 13 — a blank window is omitted and takes the default window, so Operation 49 no longer answers no tasks to an omitted window; the page is doing (b7c0204c)
- Task: Final Critique 12 — a window that is not a duration is malformed, the window start is declared arithmetic, Check 2.4 reads the state; the page is done (028724ad)
- Task: Final Critique 11 — a window is never below zero and a day is twenty-four hours, Non-goal 10 and Read 5's answer order, Operations 28, 45 and 49, Check 2.4; the page stays doing (985bb27d)

### Verified Repair

- Verified Repair: Final Critique 38 — a round read once for every invocation id its index carries, recording-failure(step) retried, caller pinned (4bff9b7d)
- Verified Repair: Final Critique 37 — recording-failure(intent) retried, a composed pattern's finding routed, hook-rejected and gate-red escalated, the reference documents read, one call with its substitute, purged read through read_record (469eeed1)
- Verified Repair: Final Critique 36 — a model-sided finding of kind A is routed to a Ledger open line, not cured with a patch that cannot land (3c3aeb6b)
- Verified Repair: Final Critique 35 — a repair call refused with nothing written is called again within the repair settling bound of its answer (772105bf)
- Verified Repair: Final Critique 34 — a malformed verdict of a settled round is answered late-malformed, so its escalation commits, and four citations and two terms are made exact (a8f8ddee)

### Assignment

- Assignment: Final Critique 15 — a clean delta round; State 11's wording and Capability requirement 5 are reached and no cure is owed, the atom stays done (7db4cd76)
- Assignment: Final Critique 14 — a clean delta round; the App model's Conformance 9 change reaches three rules and no cure is owed, the atom stays done (8ad90f98)
- Assignment: Final Critique 13 — a clean delta round; the journal refusal of Recall For Task joins the storage-failure case and member, the atom stays done (ca294625)
- Assignment: Final Critique 12 — the journal's refusal is a case of the table; the page is done (08afa062)

### Legal Hold

- Legal Hold: Final Critique 14 — a clean delta round; Invariant 4.3 moves to Check 4.2, the [Active] entry carries no purge duty, Non-goal 17 says what the atom does not carry, the owners NOTE names Non-goal 9's case-management system; the atom is done (08949685)
- Legal Hold: Final Critique 13 — a delta round, two foundational findings cured: Invariant 4.3 binds the auditor and Composition note 10 blocks a purge on an active hold, and a record's database instance is fixed (61926dd4)
- Legal Hold: Final Critique 12 — a full round, three foundational findings cured: a hold id over the string cap answers invalid-request, a blank case reference is omitted, and a hold's database instance is routed to (79cac81e)
- Legal Hold: Final Critique 11 — a clean delta round; Invariant 4.3 binds its instant by the Term, the Term reads the stored fields as they stand, Instance 7 compares names, External check 6 reads a back-dated instant's weight; the atom stays done (6ffa1560)

### Notification

- Notification: Final Critique 17 — a delta round, foundational count 2, cured: Invariant 2.4 promises what the read's commit holds, Capability requirement 8 keeps the failing and expiring outcomes disjoint, Deliver persistence 3 covers a repeat after a lost reply (1487fb36)
- Notification: Final Critique 16 — a delta round, one foundational finding cured: Term pending at an instant reads each field as the record stood at the commit the read answers from, so Invariant 2.4 judges a read by the version it answers (adacf14e)
- Notification: Final Critique 15 — a full round, two foundational findings cured: a bulk expiry calls [Expire] only for an outcome the declared policy names for expiring, and a storage-failure from [Fail] or [Expire] is retried as [Deliver]'s is (6f28782a)
- Notification: Final Critique 14 — a delta round, foundational count 0, clean; the atom is done (9aa57b81)

### Permissions

- Permissions: Final Critique 18 — a delta round, foundational count 0, clean; the atom is done (dd0f4487)
- Permissions: Final Critique 17 — [Revoke] reads a grant id that is not a string, as one over the cap, as naming no grant; the page stays doing (0b14fcfc)
- Permissions: Final Critique 16 — [Revoke] answers a grant id over the string cap as naming no grant, Composition note 1 is deleted to Conformance 9, and the page is doing again (1114a2b0)
- Permissions: Final Critique 15 — the string cap cites its floor, an active grant carries no revocation instant, and the page is done again (3d75337e)

### Tamper Evidence

- Tamper Evidence: Final Critique 24 — a delta round, foundational count 1, cured: a cached verification result is answered only while the evidence exists (6e106ac9)
- Tamper Evidence: Final Critique 23 — a delta round, two foundational findings cured: Invariant 7.1 answers alike only over one record set match and a standing evidence, and a mechanism failure has a value for any other cause (fb874224)
- Tamper Evidence: Final Critique 22 — a full round, one foundational finding cured: Operation 15 answers not-known for an evidence id over the string cap, and the refining cures (4dbbf72c)
- Tamper Evidence: Final Critique 21 — a clean delta round; Capability requirement 2 cites the Database and Read rules the page relies on, Composition note 1 is deleted to Conformance 9, and the atom stays done (e535e3e8)

### Approval Step

- Approval Step: Final Critique 22 — a clean delta round; the atom is done (79b69293)
- Approval Step: Final Critique 21 — a delta round, one foundational finding cured: Operation 66 applies the string cap to the string axes only, as Operation 45 and Execution Contract Query 5 do (77e6708a)
- Approval Step: Final Critique 20 — a full round, two foundational findings cured: Term string cap cites Input 2 and Query 5 for its measure, Term reference names the reasons it leaves out (bad327c5)

### Capability

- Capability: Final Critique 16 — a delta round, foundational count 2, cured: Invariant 12.2 judges another capability's digest, and Capability requirement 14 counts the digest's bits (dc8a1d17)
- Capability: Final Critique 15 — a delta round, foundational count 2 after the blind second triage, cured: the token cap is not declared below a live capability's token material, and the token digest is a one-way, collision-resistant function (ea0506c6)
- Capability: Final Critique 14 — a full round, one foundational finding cured: the record carries a digest of the capability token, never the live token (ee65f777)

### Credential

- Credential: Final Critique 25 — the effective status is computed from the credential and now; the page is done (9104a811)
- Credential: Final Critique 24 — delta round on the whole page; expiry and the equal-instant verify written out (178bdb64)
- Credential: the Decisions entry says Composition note 4 through 11 (F-range-form) (470fcfe9)

### Customer Onboarding

- Customer Onboarding: Final Critique 12 — Primitive policy 18 excepts a trigger set (026a5439)
- Customer Onboarding: Final Critique 11 — a delta round reads clean, the page is done (7049d0ef)
- Customer Onboarding: Final Critique 10 — a policy removal is serialized with every placement under it (26faf123)

### Escalation

- Escalation: Final Critique 3 — a clean delta round; the intent candidates cap cites Logic confinement 15 for its required setting; the atom stays done (fe3c8388)
- Escalation: Final Critique 2 — a clean delta round, the page is done; Check 3.4 says what the healthy gap is (b396cdd4)
- Escalation: Final Critique 1 — the terms the rules read are declared or cited, refusal order of a malformed call fixed once, Check 3.5 and findings 5 narrowed (b8a27b32)

### Event Log

- Event Log: Final Critique 21 — a clean delta round; no cure, the atom is done (33cd63a5)
- Event Log: Final Critique 20 — the append answers the sequence number, the offer's place (e4a04ffc)
- Event Log: Final Critique 19 — a negative payload cap is no cap, and omitted or non-byte data answers invalid-payload (e54ae34e)

### Medication Order

- Medication Order: Final Critique 10 — a clean delta round; the atom is done (4b61fe97)
- Medication Order: Final Critique 9 — a delta round, foundational count 1, cured: Operation 13 leaves [Hold] and [Reinstate] out of the on-hold refusal, so a held order's reinstate is admitted (93cf2d33)
- Medication Order: Final Critique 8 — a full round, six foundational findings cured: the order events record's hold and reinstate content named, state excepted from the write-once invariant, State 13 and Check 5.4 read by presence and by value, [Amend]'s dose and the optional dosing strings answered, a lost [Order] left to the app (ea9725b2)

### Provisional Commitment

- Provisional Commitment: Final Critique 20 — a clean delta round; no cure to a rule; the atom is done (817d9115)
- Provisional Commitment: Final Critique 19 — a full round, two foundational findings cured: the reclamation window bounds the lag of a commitment no storage-failure stands for, and an unread registry verdict answers registry-unavailable (1bce03e9)
- Provisional Commitment: Final Critique 18 — a clean delta round; no cure to a rule; the atom stays done (e2fe1742)

### Selective Disclosure

- Selective Disclosure: Final Critique 24 — a delta round, foundational count 1, cured: the receipt instant term and Invariant 4.1 both read the future bound (809bd644)
- Selective Disclosure: Final Critique 23 — a full round, foundational count 1, cured: a disclosure instant is checked against the future bound, now and the clock allowance, as Execution Contract Offline 1 keeps an offline device's claim (62e7e4d4)
- Selective Disclosure: Final Critique 22 — a delta round, foundational count 0, clean; the atom stays done (46d1cca8)

### Shared Todo as an app

- Shared Todo as an app: Final Critique 3 — a delta round, foundational count 5, cured: App check 3 keys the list id, App permission 4 bounds it, App check 2 is no permission check of the need (ceb077d5)
- Shared Todo as an app: Final Critique 2 — a delta round, foundational count 2, cured: the party-input sentence names the acting party and says a reassign's new assignee is the one carried value, and Term one week gives the window 604800 seconds (80f302f3)
- Shared Todo as an app: Final Critique 1 — a full round, seven foundational findings cured: the list a task action names is confirmed by Task's Read, read list passes a one-week window and answers in the sequence's order, delete list deletes each task by id, every party input is the caller, the failure arms of sign in and of a session are owned, sign-up is left outside on purpose (ee003d56)

### State Machine

- State Machine: Final Critique 25 — Check 9.1 carries one obligation; the page is done (6cba3a6f)
- State Machine: Final Critique 24 — two workflows recorded in one commit are ordered by workflow id; the page stays doing (729206be)
- State Machine: Final Critique 23 — a malformed guard satisfied or actor reference on a fire is answered as a firing fault; the page stays doing (7fb8deb7)

### declarations

- declarations: where a word lives — the record types ruled in, contract words stay on Contracts, one pairing datum (23f6d394)
- declarations: actor id, task id, list id, and the to-do record types (d5afc02f)
- declarations: Final Critique 1 — a word's declaration carries a type, every specification is bound, the section key's encoding keeps two pairs apart (d0b16ac5)

### library

- library: grammar page cures, one batch — 261 lines on 49 pages, 1 word into declarations.md (4c409f2e)
- library: atoms/ holds atoms — the taxonomy note is _TAXONOMY.md, the helper convention stated (46f65bec)
- library: the files match the tree — every menu section is a folder, old URLs redirect, requests go through the connector (b6ad4b52)

### Actor Identity

- Actor Identity: Final Critique 23 — a clean delta round; a NOTE no longer cites the deleted Invariant 6.2; the atom stays done (65987fe9)
- Actor Identity: Final Critique 22 — a clean delta round; the atom is done (78805e2a)

### Capacity Constraint Enforcement

- Capacity Constraint Enforcement: Final Critique 14 — a clean delta round; Non-goal 28's owner is marked forthcoming, Suspend, Resume and Close gain their invalid-request row; the atom is done (5a40d0f3)
- Capacity Constraint Enforcement: Final Critique 13 — a full round, foundational count 1, cured: an audit event a composed retention pattern purged stands as carried by every rule that obliges the log to carry it (00ef299b)

### Cart

- Cart: Final Critique 12 — clean, done; the id entries cite Logic confinement 22, External check 3 names the seam as the source (51483476)
- Cart: Final Critique 11 — a full round, foundational count 1, cured: Check 2.1 reads the committed versions, so a cart another pattern removed and a reissue of its id no longer pass a check that claims to catch Identity 3 (3d8116fe)

### Category

- Category: Final Critique 6 — a clean delta round; Term items declares the arm [List Items] answers; the atom is done (6f0e7b8a)
- Category: Final Critique 5 — a full round, foundational count 4, cured: Check 2.1 reads only the atom's own writes, Place's two operations name the no-home and other-home cases, Reorder changes no other category's position, and a category id has a canonical form (cf9777df)

### Comment

- Comment: Final Critique 5 — a clean delta round; the atom is done, four citations repaired (344a9219)
- Comment: Final Critique 4 — a full round, foundational count 2, cured: [Read Comment] answers blank text for a retracted comment, and a comment id has a canonical form beside the references' (9e5cfc06)

### Communication

- Communication: Final Critique 6 — a clean delta round; no cure to a rule; the atom is done (3325bd22)
- Communication: Final Critique 5 — a full round, two foundational findings cured: an occurred instant is checked against now plus the clock allowance, and the communication id has a cap (e5104028)

### Condition Register

- Condition Register: Final Critique 7 — a clean delta round; the atom is done (40c04769)
- Condition Register: Final Critique 6 — last run id kept on close, Concurrency 2 and listed-status answers stated, Undo 4 and lost-answer entries added (7f80ebd6)

### Erasure Tombstone

- Erasure Tombstone: Final Critique 7 — a clean delta round; the atom is done (eabfe4a9)
- Erasure Tombstone: Final Critique 6 — a full round, foundational count 2, cured: a listing's pages are no snapshot (Non-goal 16, External check 3), and Invariant 4 claims erasure tombstones, not destructions (c3c7c1b0)

### Immutable Ledger

- Immutable Ledger: Final Critique 22 — the horizon counts the settling period, the outcome event is found through the invocation read and an abandoned closing is checked against the disclosure read, a seal mismatch never answers not-in-ledger, the run bound lands the ledger enumeration, the finding surface answers one finding (cc6bd934)
- Immutable Ledger: Final Critique 21 — the reissue answer declared, the horizon arithmetic named, the verifier reads the bundle's own declaration (e3888695)

### Money

- Money: Final Critique 7 — a clean delta round; two terms cite the exact-arithmetic rule instead of restating it; the atom is done (fb30325e)
- Money: Final Critique 6 — a full round, foundational count 1, cured: a Split whose shares are no list answers invalid-shares through Term share count, a part is bounded by the number cap, a rounding is compared codepoint for codepoint, and the wording cures (77bd58f5)

### Observation

- Observation: Final Critique 11 — a delta round, foundational count 0 after the blind second triage, clean, done: Capability requirement 6 cites Query 5, and the retry sentence says where no other call changed the observation (2f35e8a8)
- Observation: Final Critique 10 — a full round, two foundational findings cured: Capability requirement 6 names Database 5, Term reference names the observation id, and the wording cures (db605d70)

### Owed Record

- Owed Record: Final Critique 6 — a clean delta round; no cure to a rule; the atom is done (a6b07caa)
- Owed Record: Final Critique 5 — a full round, foundational count 2, cured: an owing pattern or owed id over its cap answers invalid-request on Discharge, Flag and Read Owed, Clock dependence 2 excepts a continuation key's instant, and the checks and wording cures (3e5074a7)

### Party Identity

- Party Identity: Final Critique 15 — a clean delta round; the page is done (61aed933)
- Party Identity: Final Critique 14 — Check 1.1 and Check 3.4 demand the whole set; three checks and six refining cures; the page stays doing (a0801491)

### Recurrence

- Recurrence: Final Critique 4 — a delta round, foundational count 0 after the blind second triage, clean, done: the Example names Operation 14 among the blank reads, and ISO and DTSTART are glossed at first use (4c5fd15f)
- Recurrence: Final Critique 3 — a full round, foundational count 1, cured: Term end bound orders a bound of none after every date, and the wording cures (d7cd02ca)

### Retention Window

- Retention Window: Final Critique 16 — a clean delta round, three refining cures; the atom is done (349da746)
- Retention Window: Final Critique 15 — a full round, foundational count 1, cured: the degenerate duration and max purge delay are values Operation 7 and Operation 8 already refuse, Operation 7a and 8b are deleted, and the policy registry keeps every placement's record (d577f2b9)

### Session

- Session: Final Critique 30 — a clean delta round; Operation 65 says the default is no window length; the page is done (e4533925)
- Session: Final Critique 29 — [Issue] answers the session id, [Read] names its tie order; the page stays doing (88366445)

### Subscription

- Subscription: Final Critique 15 — a full round, foundational count 3, two cured: Operation 23 is deleted and Execution Contract Read 5 owns the answer's order, and the string cap is counted per Input 2; the subscription id's bearer capability waits on Scott (58d7582d)
- Subscription: Final Critique 14 — a delta round, foundational count 0, clean; the atom is done (277087a7)

### Tenure

- Tenure: Final Critique 6 — a clean delta round; the repeated-[Begin] recovery sentence holds while the first tenure stands; the atom is done (429ffb48)
- Tenure: Final Critique 5 — a full round, foundational count 1, cured: the example's unreachable seed replaced, serialization named for every pair of writing calls, and the wording and checks cures (c21239ed)

### app

- app: to-do, review cures — the journal sentence, make list's grant is an effect, Shared Todo superseded (e3809934)
- app: to-do — ten atoms, one bond line, three glue lines, four jobs (fed5f632)

### contract

- contract: Final Critique 1 of Order 2, Offline 1 and Atom budget 1 — one position per commit, the lower position wins, an offline claim checked and ordered, carrying defined (7444de6d)
- contract: one order decides, offline time is a claim, an atom carries at most one of failure or concurrency (75a0f408)

### contracts

- contracts: Final Critique 1 — the words declared, the probe's four answers, an unanswered call landed, two-sided edge tests, a contract need met by its contract (6c28b263)
- contracts: the outside world — what an app asks of systems that are not Grace's, tested at the edge (cb0c954b)

### execution contract

- execution contract: the app page's sections classified; the to-do glue walked (7a43e1e6)
- execution contract: the app model replaces the composition model (cb98fa3c)

### execution-contract

- execution-contract: an id's canonical form stated once — Logic confinement 22, seven specifications cite it (29e021c7)
- execution-contract: Logic confinement 16 says what the stronger reading excludes — held cure of Legal Hold Final Critique 12 (20258c18)

### execution-contract.md

- execution-contract.md: the wiring examples name Task, not PersonalTodo — held cure of Task Final Critique 11 (f5f4ab98)
- execution-contract.md: Constituent failure 2 drops Provisional Commitment's place hold from its example list — held cure of Idempotent Reservation Final Critique 14 (3572dfae)

### other

- shorter comments (84c8d7bd)
- config (668e1fe8)

### pivot

- pivot: shake out the other ten to-do atoms — restated rules cut to their owners (49b7bbbe)
- pivot: shake out Personal Todo — the first to-do atom, stops for review (1bc66377)

### Calendar Time

- Calendar Time: Final Critique 2 — a delta round, foundational count 1, cured: Shift's out-of-range applies to a whole amount; resolutions read on the clock; six acronyms spelled out (2a9e0206)

### Consent

- Consent: Final Critique 23 — a clean full round; Composition note 1 and Invariant 3.3 moved to their owners, Term metadata says opaque content, the Undo 4 sentence added, the atom is done (e61252c6)

### Idempotent Reservation

- Idempotent Reservation: Final Critique 14 — clean, done: place_hold stops answering the registry-unavailable Provisional Commitment never gives (424a0464)

### Moderation

- Moderation: Final Critique 3 — a full round, foundational count 0 after the blind second triage, clean, done: Database 8 is cited, show, unlock and unpin take the condition that a standing exists, the canonical form stands in place of Logic confinement 13, and the wording cures (b01d13fb)

### Notification Fanout

- Notification Fanout: Final Critique 12 — a delta round, foundational count 0, clean; the composition is done (94e63358)

### Personal Todo

- Personal Todo: Final Critique 10 — Operations 28 and 45 hold for a window that is not malformed, Operation 10 for a text that is not malformed, two entries reworded; the page is doing (c0f22be5)

### Role

- Role: Final Critique 4 — a full round, foundational count 0 after the blind second triage, clean, done: the [Ask] replay is an external check, Database 8 is cited, the person reference's canonical form stands in place of Logic confinement 13, and the wording cures (cf85dbb0)

### Shared Cart

- Shared Cart: Final Critique 5 — a clean delta round; the Premodel no longer restates spec-format, the Cart binding row names Cart's Composition note 2; the page stays done (b54aa06c)

### Shared Todo

- Shared Todo: a reassign to someone the list is not shared with is refused (App check 2); sign-up stays outside (d6385350)

### Tag

- Tag: Final Critique 5 — a clean delta round; the atom stays done, pinned to this round (5cfcc040)

### Waitlist

- Waitlist: Final Critique 5 — a full round, foundational count 0, clean, done: a spot's join number above every earlier one is an invariant and a check, External check 4 reads the id source, Database 8 is cited, and the wording cures (89f4f0cf)

### atoms

- atoms: a held reference is a key need — the rule stated, Tag first (bc5b5b34)

### bonds.md

- bonds.md: Final Critique 2 — one instance serves an ambiguous need, guard 2 covers try_take, Bond 2 per field, Bond 3 per arm (85828533)

### docs

- docs: the map of Grace's parts — one screen of every kind of part (dada24ab)

### glue

- glue: Final Critique 1 of the 19 lines — two move to Sweep, the probe's two-match and no-datum edges, Bond 2 read one way, dangling citations repointed (719dc917)

### invitation

- invitation: Final Critique 16 — a clean delta round; Non-goal 13 no longer contradicts the journal, the atom is done (c3eb9d0f)

### process

- process: the reading stack moves — the gate's steps leave the checklists, GRID re-aimed, a bare ok stated once (4816dcd5)

### spec-format

- spec-format: a computed value's term entry takes Kind Field, a term entry's kind stated once (4d017e95)

### split

- split: Recoverable Invocation into Durable Intent, Sweep and Escalation — first split, stops for review (18c7609b)

## v0.0.0 — 2026-11-23

The baseline before the full stack: 74 patterns (48 atoms, 26 compositions), 52 of them done (43 atoms, 9 compositions), as the Status lines read at this tag. Versions before it are the whole-number history (V1, v2, v3), kept in the roadmap and the history files as they were written. Each later minor version is tagged by the unit that closes its milestone.
