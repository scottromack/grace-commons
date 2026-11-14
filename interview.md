---
title: A real interview
nav_exclude: true
---

# A real interview

This is Grace asking the questions, start to finish, for one small pattern. Nothing is staged: these are the questions as asked and the answers as given on November 14, 2026, mistakes included. The person answering is Scott Romack, who started Grace. The pattern is Favorite – the heart you tap to save something for later. It came from a list of ideas on Daniel Jackson's concept design forum, and nothing in the library covered it.

It took about fifteen minutes.

## The questions

**Grace: What exactly does a person favorite?** A starting answer: any one item the business shows them, such as a product, a recipe or an article. One tap marks it, a second tap unmarks it, and the favorite belongs to that one person. Nobody else sees it.

**Scott:** Remove "Nobody else sees it." Most humans would miss that.

He was right. Who else can see a favorite is exactly what a person would not think to say – so it should be a question Grace asks, not something slipped into an answer. It comes back below.

**Grace: What must never be possible?** A starting answer: the same person can never have the same item in their favorites twice. Tapping an item that's already a favorite just leaves it a favorite.

**Scott:** Tapping an item that's already a favorite does nothing.

That collided with the first answer – "a second tap unmarks it." Both could not be true of the same tap, so Grace stopped and asked which.

**Scott:** Sorry, your question confused me. It is a simple toggle, usually a heart filled and unfilled.

Recorded as he said it. Grace settled one detail itself, because a rule of the library already decides it: if the same tap arrives twice over a slow connection, the second changes nothing.

**Grace: Who can see a person's favorites?** A starting answer: only that person. Sharing a list with someone else is its own pattern, left for later.

**Scott:** Yep.

**Grace: When a person opens their favorites, what do they see?**

**Scott:** Their favorites listed. They can edit the list also.

**Grace: What can they change when they edit it?** A starting answer: they can take items off, one at a time.

**Scott:** They can toggle the list, but the items stay in the list in an un-toggled state until refresh? The idea there is the oops factor.

A slip is fixed with one more tap instead of a hunt for the item. That raised a question the pattern had to answer.

**Grace: If they fill the heart again, where does the item go?**

**Scott:** Not following. It never "moves" in my mind.

So it never moves. A favorite keeps the place it first had, whatever happens to its heart.

**Grace: What if a favorited item is no longer offered?** A starting answer: it stays in their favorites, shown as no longer available. It never silently disappears.

**Scott:** Yes. Product availability status (default is in stock; discontinued, backorder, probably others?) should be shown.

Grace made one call here and said why: the list of statuses is not Favorite's to own. It belongs to the catalogue. Favorite keeps only which item was saved, which is what lets it work for recipes and articles, which have no stock at all.

**Grace: Is there a limit to how many favorites a person can have?**

**Scott:** None. I can't think of a business that would want to limit your hearts.

## What Grace read back

- Tap the heart on any item to favorite it; tap again to unfavorite it.
- An item is in a person's favorites once or not at all, never twice.
- Emptying a heart keeps the favorite's place, so filling it again puts everything back as it was.
- A favorite never silently disappears, even when the item is discontinued.
- The same tap arriving twice changes nothing the second time.
- No limit on how many.
- Left to other patterns: availability, who is signed in, sharing a list, counting likes.

**Scott:** Way better than I would have sketched it, yes!

## What happened next

Grace wrote the pattern from those answers and checked its wording against the library's rules. It was sent for review the same morning, in public: [see where it stands](https://github.com/scottromack/grace-intake/issues/5). It is not in the library yet. It gets there only when independent reviewers and the machine checks find nothing left to fix.

One thing the writing caught that the conversation had not: Favorite keeps each person's list separate, but it cannot itself tell who is tapping. Checking that is the sign-in pattern's job, and the pattern says so.
