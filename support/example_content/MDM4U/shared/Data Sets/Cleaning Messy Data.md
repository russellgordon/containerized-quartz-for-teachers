---
title: Cleaning Messy Data
publish: true
created: __CREATED__
tags:
  - data-sets
enableToc: true
---
Nobody warns you that most of a data investigation is not analysis. It
is opening a file, discovering that the same bus route is spelled four
ways, that one respondent gave their commute as "about half an hour",
and that row 47 is a repeat of row 46 with one digit changed. This is
normal. Professionals spend more time here than anywhere else, and the
decisions you make in this stage shape your results more than the
statistics you run afterwards.

The rule that governs the whole page: **clean a copy, never the
original, and write down every decision as you make it.**

## What messy actually looks like

The table below is invented, but every flaw in it is one you will
meet.

> [!example]- Five rows of a survey, before cleaning
> | id | grade | mode | commute_min | dist_km |
> | --- | --- | --- | --- | --- |
> | 1 | 11 | Bus | 24 | 6.2 |
> | 2 | 11 | bus  | 24 | 6.2 |
> | 3 | 12 | BUS | about 30 | 8 |
> | 4 | 9 | Car | 15 | -1 |
> | 5 | 99 | walk | 0 | 0.4 |
>
> Rows 1 and 2 are probably one person entered twice — same
> everything, different capitalization. `Bus`, `bus`, and `BUS` are
> three categories to a computer and one to you. `about 30` is text
> in a numerical column, so the whole column may have been read as
> text and will refuse to average. `-1` is a missing-value code
> masquerading as a distance. `99` is a missing-value code
> masquerading as a grade. A commute of `0` minutes needs a human
> to decide whether it is real.

## A cleaning order that works

Doing these out of order creates work. Doing them in order takes about
an hour on a student-sized data set.

1. **Save an untouched original.** Name it clearly and never open it
   again except to start over.
2. **Read the documentation.** [[Reading a Data Dictionary]] first —
   half of what looks like mess is a code you have not decoded.
3. **Fix structure.** One header row, one row per observation, one
   variable per column, no merged cells, no blank spacer rows, no
   totals row hiding at the bottom pretending to be data.
4. **Standardize categories.** Choose one spelling and one case for
   each category and apply it everywhere. Watch for trailing spaces;
   they are invisible and they split categories.
5. **Force numerical columns to be numerical.** Remove thousands
   separators, currency symbols, and stray units. A number stored as
   text will sort alphabetically and put $100$ before $9$.
6. **Convert missing codes to genuinely empty cells,** and record how
   many there were in each column.
7. **Find duplicates** by sorting on the columns that should be
   unique, and decide — with a reason — whether each is a genuine
   repeat or two people who legitimately match.
8. **Range-check every numerical column.** Look at the minimum,
   maximum, and a quick histogram. Impossible values surface
   immediately.

Steps 4 through 8 are exactly the sort of repetitive work
[[Using a Spreadsheet for Statistics]] is built for, and doing them
with formulas rather than by hand means you can redo them when you
find a mistake — which you will.

## Deciding about outliers and blanks

An **outlier** is a value far from the rest. It is not automatically
an error, and deleting it is not automatically allowed. Three
possibilities, three responses:

A **data-entry error** — a commute of 340 minutes, a height of 17 cm.
If you can verify it is wrong, correct it if you know the true value
and remove it if you do not. Say so in your report.

A **different population sneaking in** — the one respondent who
commutes from another city. Legitimate data, but it may not belong to
the group you are describing. You may exclude it, provided you state
the exclusion and the reason.

A **genuine extreme value** — a real person with a real long commute.
Keep it. This is the most common case, and it is where the resistant
summaries from [[One-Variable Statistics]] earn their keep: report the
median alongside the mean and let the reader see the effect.

**Blanks** need a decision too. Removing every row with any missing
value is simple and can quietly delete a quarter of your data — and
not a random quarter, which is the real problem. At this level the
defensible approach is to analyse each variable with whatever data it
has, report the number of responses for every statistic you quote, and
say plainly what you dropped. Never invent a value to fill a hole.

## Keep a cleaning log

Write it as you go, in the same document as your report. Three
columns: what you found, what you did, why. It should read something
like *"Rows 1 and 2 identical apart from capitalization; removed row 2
as a duplicate entry; 84 responses became 83."*

The log costs almost nothing and does three jobs. It makes your work
**reproducible**, so someone else could get your numbers. It makes it
**defensible**, so a question in [[The Data Symposium]] has an answer
that is not "I think I deleted something". And it makes your
limitations section write itself, which is one of the five things
[[The Culminating Investigation]] is actually assessed on.

Every one of these decisions is a small act of judgement that changes
your results. Getting one wrong is ordinary — [[Mistakes Are Data]] —
but only if it is written down where you can find it again.

%%curriculum-start%%
## Curriculum connection

![[C2.5]]

![[E1.3]]

![[E1.4]]
%%curriculum-end%%
