---
title: Writing About Code
draft: false
created: __CREATED__
tags:
  - reference
enableToc: true
---
Half of this course happens at a keyboard. The other half happens when
you put technical thinking into words somebody else can follow — in
your [[Code Journal]], in the comments inside your programs, in the
written parts of every task, and eventually in the handover notes a
real client will read without you standing beside them. Writing about
code has one rule that does most of the work:

> [!important] Write for the next person, who might be you
> Every comment, entry, and explanation is addressed to somebody who
> cannot see inside your head — including the version of you who
> returns in three weeks remembering nothing. If it only makes sense
> with you there to narrate it, it is not finished.

## Precision is kindness

The same moments, described vaguely and then usefully:

| Instead of… | Try… |
| --- | --- |
| "It doesn't work" | "It crashes on line 12 when the input is empty" |
| "I fixed it" | "The loop ran once too often — `range(4)`, not `range(5)`" |
| "The AI helped" | "Asked an AI for a `while` example, rewrote the condition, noted it in a comment" |
| "It's done" | "Meets all criteria; known limit: negative hours untested" |
| "My client liked it" | "She used it twice without asking me anything, then asked for one extra column" |

Every phrase in the right-hand column can be checked by somebody else.
That is the whole standard, and it is the same one
[[Writing Code Others Can Read]] applies inside the program.

## Sentence stems that unlock a stuck page

- I expected the program to… but it actually… which tells me…
- The bug turned out to be… and the clue that found it was…
- A user who is not me would need… before this is genuinely usable.
- My client's real problem is… even though what they first asked for
  was…
- If I rebuilt this from scratch I would change… because…

## Writing for the person who will use it

Handover notes are a different genre from a journal entry, and the
audience is not a programmer. Three things belong in them: what the
program does in one sentence, how to run it step by step on their
machine, and what it will not handle. That last one is not an
admission of failure — a limit stated in advance is a limit somebody
can plan around, while a limit discovered in use is a broken promise.
[[Interviewing Your Client]] is where you learn what they will
actually need spelled out.

## Claims about technology need evidence too

When you write about accessibility, bias, or whether a thing should
exist at all, the standard does not soften. Specific beats sweeping,
sources get named, and "I read somewhere" is a bug. Strong writing
about technology sounds like a strong bug report: a claim, the
evidence, and an honest note about what you do not yet know — which is
exactly how the arguments in [[Should It Exist]] and
[[When Code Hurts]] are meant to be conducted.

## Reporting on something you researched

A brief, a talk, and a poster are three shapes for the same job:
telling somebody what you found out. Choose the shape for the audience
and the time — a two-page brief for a reader who will act on it, five
minutes for a room that has not thought about your topic, a poster for
people walking past. Whichever it is, the structure holds: the question,
what is genuinely known, the specific example that shows it, what
remains unsolved, and where you got it. Naming your sources where you
use them rather than in a heap at the end is what separates a report
from an essay of opinions, and it is what [[The Research Brief]] is
marked on.

%%curriculum-start%%
## Curriculum connection

![[D2.3]]
%%curriculum-end%%
