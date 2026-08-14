---
title: How Numbers Actually Fit
draft: false
created: __CREATED__
tags:
  - concepts
enableToc: true
---
Every number your program holds lives in a fixed number of bits. Most of
the time that is invisible. The rest of the time it produces a bug that
looks like the machine is lying to you, and the only defence is knowing
in advance where the edges are.

## The one everybody meets first

```python
>>> 0.1 + 0.2
0.30000000000000004
>>> 0.1 + 0.2 == 0.3
False
```

Nothing is broken. A `float` stores a number in binary, and 0.1 in
binary is a repeating fraction — the same way 1/3 is 0.333… in decimal.
It gets cut off, twice, and the error survives the addition.

The consequence for your code is a rule with no exceptions:

```python
# Never
if total == 0.3:

# Instead
if abs(total - 0.3) < 1e-9:
```

Comparing floats for exact equality is a bug even when it happens to
work, because it will stop working on different data.

## Where the edges are

| Representation | The edge | What it looks like when you hit it |
| --- | --- | --- |
| Fixed-width integer | A maximum value | Wraps to a negative number (C, Java); Python grows instead, but slowly |
| Float | About 15–17 significant digits | Digits past that are noise, silently |
| Float | Very large and very small together | `1e16 + 1` is `1e16`; the small one vanishes |
| Text | The encoding | A character arrives as mojibake, or a length is wrong |
| Any collection | Available memory | It works on your test file and dies on the real one |

Python spares you integer overflow — its integers grow as needed — which
makes it a poor place to *learn* that the edge exists. Every other
language you meet has it, and so does every database column you will
ever declare.

## Designing around the limits

The choices happen before the bug does:

1. **Money is not a float.** Store cents as integers, or use `Decimal`.
   Any program adding up prices in floats will eventually be out by a
   penny, and somebody will notice.
2. **Accumulate carefully.** Adding a million small floats to a large
   running total loses the small ones. Sum similar magnitudes together
   first if precision matters.
3. **Pick the type for the range, not for today's data.** "Nobody will
   ever have more than 32,767 of these" is on the tombstone of a lot of
   systems.
4. **Test at the boundary**, not in the middle: zero, one, the maximum,
   one past the maximum, and the empty case.

> [!note]- Why this is a Grade 12 idea rather than a Grade 11 one
> In [[Efficiency and Big-O]] you learned that an algorithm's cost grows
> with its input. This is the other axis: the *values themselves* have
> limits, independent of how many there are. An algorithm that is
> perfectly efficient and quietly wrong about its arithmetic is worse
> than a slow one, because nobody profiles for correctness.

## When it decides the algorithm

Some algorithms exist because of these limits. Sorting on a key that is
a float is fragile; sorting on an integer key is not. A running average
computed incrementally avoids holding a huge sum. Hash tables need the
hash to fit a machine word, which is why [[Dictionaries]] behave the way
they do. The representation is not a detail underneath your design — it
is frequently the reason for it.

%%curriculum-start%%
## Curriculum connection

![[A1.4]]

![[A1.1]]
%%curriculum-end%%
