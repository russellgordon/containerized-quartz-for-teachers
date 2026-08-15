---
title: Moving a Line
publish: true
created: __CREATED__
tags:
  - concepts
enableToc: true
---
Once you can graph $y = ax$, you can graph a whole family of lines
without plotting a single new point — because every other line in the
family is that one, moved. Knowing which move goes with which change in
the equation is worth more than any table of values.

## The two lines that are not tilted

Before the moving starts, two special cases that catch everybody:

- $x = k$ is a **vertical** line through $k$ on the $x$-axis. Every
  point on it has the same $x$, whatever $y$ does.
- $y = k$ is a **horizontal** line through $k$ on the $y$-axis. Every
  point has the same $y$.

The trap is that $x = 3$ *looks* like it should be horizontal, because
$x$ is the horizontal axis. It is not. Say it out loud instead: "every
point where $x$ is three" — and there they are, stacked vertically.

## Starting from $y = ax$

$y = ax$ always passes through the origin, and $a$ is the steepness: how
far up for every one across. Now the three moves.

**Translate — slide it up or down.** Adding a number moves the whole
line vertically:

$$y = ax + b$$

Every point rises by $b$. The steepness does not change, so the new
line is parallel to the old one. This is the only move that changes
where the line crosses the $y$-axis without changing its tilt.

**Reflect — flip it over an axis.** Replacing $a$ with $-a$ gives

$$y = -ax$$

which is the mirror image in the $y$-axis, and also in the $x$-axis —
for a line through the origin the two reflections land in the same
place. A line that rose to the right now falls to the right, at the same
steepness.

**Rotate — turn it about the origin.** Changing the size of $a$ turns
the line: a larger $|a|$ swings it towards vertical, a smaller $|a|$
towards horizontal. $y = x$ rotated towards the $y$-axis becomes
$y = 2x$, then $y = 5x$; rotated the other way, $y = 0.5x$, then
$y = 0.1x$, approaching the $x$-axis but never lying on it.

| Change to the equation | What happens to the line |
| --- | --- |
| $y = ax \rightarrow y = ax + b$ | Slides up by $b$ (down if $b$ is negative) |
| $y = ax \rightarrow y = -ax$ | Reflects — the tilt reverses |
| $a$ gets bigger | Rotates towards vertical, steeper |
| $a$ gets smaller | Rotates towards horizontal, flatter |
| $a = 0$ | Flat: $y = 0$, the $x$-axis itself |

## Try it before you trust it

Open [[Using Desmos]] and put $y = 2x$ on the screen. Then add
$y = 2x + 3$, $y = -2x$, and $y = 5x$ one at a time, predicting each
before you press enter. The prediction is the learning; the graph only
tells you whether you were right.

> [!question]- Why does $y = ax + b$ not rotate as well as slide?
> Because $b$ is added AFTER the multiplying. Every point moves up by
> exactly the same amount, so the shape is unchanged and only its
> position moves. If $b$ depended on $x$ — say $y = ax + x$ — you would
> be changing the steepness instead, which is a rotation wearing a
> disguise. Multiply and you turn it; add and you slide it.

## Where this shows up

Every "starting amount plus a rate" situation in [[Linear Relations]] is
a translated line: the start-up fee slides the plan's line up, and the
per-gigabyte cost tilts it. In [[Which Phone Plan]] the two lines cross
exactly where the sliding and the tilting balance out, which is why the
answer is a break-even point rather than a winner.

%%curriculum-start%%
## Curriculum connection

![[C4.2]]

![[C4.3]]

![[C4.1]]
%%curriculum-end%%
