---
title: Communication — history
nav_exclude: true
search_exclude: true
---

# Communication — history

The dated record of how [Communication](./communication.md) got here, moved out of the spec on 2026-11-16 because a reader does not need it to use the spec today. Everything smaller is in `git log -- atoms/communication.md`.

## Decisions

- **2026-11-16 — Drafted through the Grace connector mirroring Reaction.** *Chose:* one communication per exchange that already happened, read in the order things happened, with Active and Withdrawn as the two statuses *Over:* a log read in the order entries were written, or a delete *Because:* a phone call logged on Friday for Tuesday belongs on Tuesday, and a communication logged by mistake should leave the history without leaving the file.
- **2026-11-16 — Active and Withdrawn.** *Chose:* Active and Withdrawn, the maintainer's pair *Over:* Valid and Void, Standing and Withdrawn *Because:* Active is the library's one word for in force and Withdrawn its word for taken back and still on file, while valid already means passes the checks.
- **2026-11-16 — A reason for each refusal, no wording.** *Chose:* a refusal of its own for each detail a person can fix *Over:* one refusal for every bad input, or wording kept in the pattern *Because:* the maintainer ruled one global statement, that software talks to its users in the plainest possible language, and the screen words each reason.
- **2026-11-16 — Medium, and phone as a medium.** *Chose:* medium for how an exchange happened, and phone where a phone call is meant *Over:* channel, way, kind, call *Because:* channel is Message Preference's word for a delivery route, way reads as everyday prose, kind is a term-entry field, and call already means a call on an action in every pattern.
