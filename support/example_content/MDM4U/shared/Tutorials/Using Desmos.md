---
title: Using Desmos
publish: true
created: __CREATED__
tags:
  - tutorials
---
Desmos is free, runs in any browser, and is the fastest way in the
world to see what a set of data looks like. Treat it as a thinking
tool — a place to test whether a summary deserves belief — not an
answer machine you obey.

## A table, a line, and the residuals

Start a table and type your data into the $x_1$ and $y_1$ columns —
say six students' study minutes against their quiz marks:
$(20, 62)$, $(35, 64)$, $(45, 73)$, $(60, 72)$, $(75, 84)$,
$(90, 86)$. The points plot themselves. Then, on a new line, type a
regression: `y_1 ~ m*x_1 + b`. That tilde is not an equals sign; it
means *find the values of $m$ and $b$ that fit best*. Desmos returns
them, along with $r$ and $r^2$ — here about $0.96$ and $0.92$, and a
line close to $y = 0.37x + 53.6$.

Now do the part most people skip. Plot the **residuals**: add
$(x_1, y_1 - (m x_1 + b))$ as a new expression and look at the
leftover distance between each point and the line. In a healthy
linear fit those leftovers scatter above and below zero with no
pattern. If they curve — all negative in the middle and positive at
both ends — the relationship was never straight, and a high $r^2$ was
covering for it. Residuals are the graph that tells you when the
summary lied, which is why [[Two-Variable Statistics]] treats them as
part of the answer rather than an extra.

> [!warning] The line will answer questions it has no right to
> Ask that line about 180 minutes of study and it predicts a mark of
> about 120%. Desmos will not object; the algebra is fine. A model
> earns belief only inside the range of the data that built it, and
> saying where it stops is your job, not the software's — the exact
> standard [[What Makes a Model Good]] argues for.

## Sliders on a distribution

Type a normal curve with sliders for its two parameters and drag
them. Watch $\mu$ slide the whole curve sideways without changing its
shape at all, and $\sigma$ stretch or pinch it around a fixed centre
while the area underneath stubbornly stays at 1 — because it has to,
since it accounts for every possible outcome. Two minutes of dragging
builds the intuition behind [[The Normal Distribution]] faster than
an hour of tables.

Predict before you drag, every time. "If I double $\sigma$, the peak
must get *lower*, because the area cannot grow" is a conjecture the
slider will settle in one second. Sliding without predicting is just
television.

## When your head is faster

Desmos shines when the question is about *shape*: does this cloud
look linear, is this distribution symmetric, what happens to the
curve when the spread doubles, do these residuals have a pattern. It
is slower than your head for a single value of $\binom{10}{3}$, for
deciding whether two events are independent, for reading the
68–95–99.7 rule off a curve you already understand, and for
everything [[Estimation Duels]] trains. It is also the wrong tool
entirely for a dataset of 500 rows — that is what
[[Using a Spreadsheet for Statistics]] is for. Reaching for a tool
you do not need is its own kind of slow; the skill is knowing which
moment you are in.
