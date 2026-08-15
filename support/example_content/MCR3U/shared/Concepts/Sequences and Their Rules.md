---
title: Sequences and Their Rules
publish: true
created: __CREATED__
tags:
  - concepts
enableToc: true
---
In [[Patterns That Count]], three groups described the same growing
pattern three different ways — "start at 3 and double", "term $n$ is
$3 \cdot 2^{n-1}$", and a table — and a good argument broke out about
whether they had found the same rule. They had. A *sequence* is an
ordered list of numbers, and its rule can be written in several
costumes, each revealing something the others hide.

## A function that walks in steps

A sequence is secretly a function whose domain is the natural numbers:
term 1, term 2, term 3, with nothing in between. That makes it a
*discrete* function — graph one and you get equally spaced dots, not
a connected curve. Compare $f(x) = 2x$ on all real numbers (a solid
line) with $f(n) = 2n$ on the naturals (a string of dots climbing the
same slope). Same rule, different domain, different object — a
distinction [[Domain and Range]] taught you to respect, and one that
matters when a model counts things that only come whole.

## Three ways to write the rule

For the sequence $3, 6, 12, 24, \ldots$:

| Representation | Written as | What it shows best |
| --- | --- | --- |
| Recursion formula | $t_1 = 3$, $t_n = 2t_{n-1}$ | how each term grows from the last |
| General term | $t_n = 3 \cdot 2^{n-1}$ | any term directly — no climbing |
| Function notation | $f(n) = 3 \cdot 2^{n-1}$ | it is a discrete function |

The recursion is how patterns *feel* — "double the last one" — but it
makes you climb through every rung to reach term 40. The general term
teleports straight there. Fluency means translating freely: given any
one representation, produce the others.

## Arithmetic, geometric, or neither

Two families dominate this unit. An **arithmetic** sequence adds a
common difference $d$ each step, and its general term is

$$
t_n = a + (n - 1)d
$$

— a discrete cousin of the linear function. A **geometric** sequence
multiplies by a common ratio $r$ each step:

$$
t_n = ar^{n-1}
$$

— a discrete cousin of [[The Exponential Function]]. To classify,
interrogate consecutive terms: equal gaps mean arithmetic, equal
ratios mean geometric, and plenty of good sequences — $1, 4, 9, 16$,
or the Fibonacci numbers — are honestly neither. The photographs in
[[Visual Patterns]] keep this classifying eye sharp all semester.

[[Series]] asks the natural next question — what do the terms *add*
to? — and [[Sequences, Series, and Interest Practice]] covers this
whole arc.

%%curriculum-start%%
## Curriculum connection

![[C1.1]]

![[C1.4]]

![[C2.1]]

![[C2.2]]
%%curriculum-end%%
