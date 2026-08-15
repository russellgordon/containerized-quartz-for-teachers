---
title: The Efficiency Case
publish: true
created: __CREATED__
tags:
  - tasks
enableToc: true
---
> [!abstract] At a glance
> Pairs · launched in Unit 2 and due five classes later · three working
> periods · one slow program made fast, measured properly, and argued as
> an environmental case rather than a technical one

## What you are making

Take a program that is genuinely slow — one of yours, one from
[[The Inherited Program]], or one I supply — and make it substantially
faster. Then write the case for the change in the terms a decision-maker
would use: time, cost, energy, and what it means at scale.

Three deliverables: the **improved program**, a **measurement table**,
and a **two-page case**.

## What must be in it

**1. The baseline, measured.** Time the original on inputs of several
sizes — not one. [[Profiling and Timing Code]] is the method; a single
timing on one input is an anecdote, and the shape of the growth is the
whole point.

**2. The bottleneck, identified before it is fixed.** Say which part
dominated and how you know. Guessing and then improving something is not
a case; it is a coincidence.

**3. The change, and its complexity.** State the before and after in
Big-O and say what you traded — memory for speed, precision for speed,
generality for speed. There is always a trade.

**4. The measurement table**, with the same inputs on both versions:

| Input size | Before (s) | After (s) | Ratio |
| --- | --- | --- | --- |
| 1 000 | | | |
| 10 000 | | | |
| 100 000 | | | |

**5. Correctness, proven.** A faster wrong answer is worthless. Show the
tests that pass on both versions, including the boundary cases — and
watch for the arithmetic traps in [[How Numbers Actually Fit]], because
"optimising" a sum into floats is a classic way to get fast and wrong at
the same time.

**6. The environmental argument.** Scale your measurement: if this ran
ten thousand times a day on a server, what does the saving amount to in
energy over a year, and what would you compare it with? Be honest about
the uncertainty in that estimate — an order of magnitude, defensible, is
worth more than a precise-looking number you cannot justify.

**7. What else you would change**, beyond the code: batching, caching,
scheduling, supporting older devices, and where equipment goes at end of
life. [[Computing's Footprint]] names the Ontario programs and
agencies to cite, and expects you to verify them rather than trust the
page.

## The working periods

| Day | What it is for |
| --- | --- |
| 1 | Baseline measured across input sizes; bottleneck identified |
| 2 | The rewrite, with tests passing on both versions |
| 3 | Measurement table completed; the case drafted and challenged by another pair |

## How this is assessed

| Quality | What it looks like |
| --- | --- |
| Measured, not guessed | Several input sizes, before and after |
| Bottleneck found first | The evidence precedes the fix |
| Complexity stated | Before and after, with the trade named |
| Still correct | Tests pass on both, boundaries included |
| Scaled honestly | An estimate with its uncertainty admitted |
| Beyond the code | At least one non-code measure, correctly sourced |

## Reflect

A [[Code Journal]] entry: what did you assume was slow before you
measured, and what actually was? Then: does the environmental argument
change how you would write the next program, or is it a story told after
the fact?

%%curriculum-start%%
## Curriculum connection

![[D1.1]]

![[D1.2]]

![[A1.4]]

![[A1.2]]
%%curriculum-end%%
