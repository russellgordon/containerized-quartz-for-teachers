---
createdSection1: 2026-02-03T08:00:00.000-0500
draftSection1: false
createdSection2: 2026-02-05T08:00:00.000-0500
draftSection2: false
enableToc: true
tags:
  - reference
---
There are two kinds of page here, and knowing which is which makes the site
much easier to use.

## Class pages

Under **All Classes**, one page per class, in order. Each has:

- an **Agenda** — what we did, with links to everything we used
- **Things to do before our next class** — the homework, as a checklist

Class pages are the *narrative*: what happened, when.

## Reference pages

Everything else — Concepts, Investigations, Exercises, Tasks, Tutorials — is
*reference*. These pages are written once and linked from many class pages.

```mermaid
graph LR
    D1["Unit 3, Day 4"] --> OHM["Ohm's Law"]
    D2["Unit 3, Day 5"] --> OHM
    D3["Unit 3, Day 9"] --> OHM
    OHM --> BL["Backlinks show all three"]
```

> [!tip] Which page do I want?
> **"What did we do Tuesday?"** → a class page.
> **"How does that work again?"** → a concept page.
> **"When did we cover this?"** → open the concept page and read its backlinks.

## Why not just put everything on the class page?

Because then the explanation of Ohm's law would exist in three places, and
fixing an error would mean fixing it three times. It would be fixed once and
wrong twice.

Each idea lives in exactly one page. Everything else links to it.
