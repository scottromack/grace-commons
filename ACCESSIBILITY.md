---
title: Accessibility
nav_order: 6
parent: Community
---

# Accessibility

## The commitment

The site aims at [WCAG 2.2](https://www.w3.org/TR/WCAG22/) level AA. It is plain text, and the specs are Markdown that a screen reader reads as written.

## What was checked

Lighthouse on the home page, 2026-11-05: Accessibility 96. Its one finding was the contrast of the theme's credit line in the sidebar, which `site: lighter search` removed.

Images: no page of the site carries an image file or an image tag, so none lacks a text alternative (checked by searching every page for image tags and Markdown images, 2026-11-06). The one drawing outside the diagrams below, the tree in the Undoing Undos exhibit, is an SVG with a text label. The Composition Graph page draws two diagrams by script, and neither has a text alternative of its own; the first diagram's edges are listed in tables on the same page, and the second diagram's 64 edges are not.

This is not yet a full audit: one page was measured with one tool, and no screen reader or keyboard-only pass has been done.

## Reporting a barrier

If a page is hard for you to use, [tell us which page and what stopped you](https://github.com/scottromack/grace-commons/issues/new?template=accessibility.yml). The maintainer reads every one.
