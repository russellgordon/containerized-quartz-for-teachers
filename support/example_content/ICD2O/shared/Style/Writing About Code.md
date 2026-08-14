---
title: Writing About Code
publish: true
created: __CREATED__
tags:
  - reference
---
Half this course happens at a keyboard; the other half happens when you
put technical thinking into words someone else can follow — in your
[[Dev Journal]], in your code's comments, and in the written parts of
every task. Writing about code has one rule that does most of the work:

> [!important] Write for the next person, who might be you
> Every comment, journal entry, and explanation is addressed to someone
> who cannot see inside your head — including future-you, who in three
> weeks will remember nothing. If it only makes sense with you standing
> beside it, it is not finished.

## Precision is kindness

Vague and precise descriptions of the same moment:

| Instead of… | Try… |
| --- | --- |
| "It doesn't work" | "It crashes on line 12 when the input is empty" |
| "I fixed it" | "The loop ran once too often — `range(4)`, not `range(5)`" |
| "The AI helped" | "Asked an AI for a comparison example; rewrote it and noted it in a comment" |
| "It's done" | "It meets all criteria; known limit: negative numbers untested" |

The same habit lives inside programs as
[[Writing Good Comments|comments]] — explaining *why*, crediting
sources, and marking what is unfinished — which the curriculum treats
as [[C2.7|part of programming itself]], not an add-on.

## Sentence stems that unlock a stuck entry

- I expected the program to… but it actually… which tells me…
- The bug turned out to be… and the clue that found it was…
- A user who is not me would need… before this is genuinely usable.
- If I rebuilt this from scratch, I would change… because…

## Claims about technology need evidence too

When we write about [[Who Owns Your Data|data]],
[[Can a Machine Be Biased|bias]], or
[[Will AI Take the Jobs|automation]], the standard is the same as for
code: specific beats sweeping, sources get named, and "I read
somewhere" is a bug. Strong technology writing sounds like strong
debugging — claim, evidence, and an honest note about what you do not
yet know.

%%curriculum-start%%
## Curriculum connection

![[C2.7]]

![[C3.5]]
%%curriculum-end%%
