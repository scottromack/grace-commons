---
title: Shared Todo — history
nav_exclude: true
search_exclude: true
---

# Shared Todo — history

The dated record of how [Shared Todo](./index.md) got here, moved out of the app page because a reader does not need it to use the page today. Everything smaller is in `git log -- library/apps/todo/index.md`.

## Decisions

- **2026-11-26 — Sign-up stays outside, and a reassign goes only to someone the list is shared with.** *Chose:* no sign-up in the first version, so Actor Identity's Mint Actor Id and Credential's Register stay left to no action and the app takes an actor id as given; and a reassign whose new assignee holds no `member` grant on the list is refused `denied` (App check 2) *Over:* sign-up in the app, and a reassign to any actor id the author names, whose standing the app did not check *Because:* Scott's ruling of 2026-11-26 3:59 PM Central ("Yta", yes to the ask of 20:54Z): sign-up stays outside the app for the first version, and a reassign to someone the list is not shared with is refused, one more check of App check 1's kind; the old row left such a task unread by its new assignee until the list was shared.
