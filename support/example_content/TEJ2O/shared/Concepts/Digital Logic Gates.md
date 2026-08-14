---
title: Digital Logic Gates
publish: true
created: __CREATED__
tags:
  - concepts
enableToc: true
---
In [[Gates in Hardware]] you wired a chip that refused to light its
LED unless both buttons were pressed. That chip was making a
decision, and it was made of nothing but the two voltages from
[[Binary and Number Systems]] — a 1 and a 0 with opinions.

## Decisions cast in hardware

A logic gate is a circuit with one job: look at its inputs, each
either 0 or 1, and produce one output by a fixed rule. AND outputs 1
only when every input is 1 — both buttons pressed. OR outputs 1 when
at least one input is 1 — either button will do. NOT has a single
input and simply flips it. Every decision a computer appears to make
is billions of these tiny verdicts, wired together.

## Truth tables

A truth table is the gate's complete biography: every possible input
on the left, the verdict on the right. With two inputs there are only
four rows, so the whole story fits in one small table.

| A | B | A • B (AND) | A + B (OR) |
| --- | --- | ----------- | ---------- |
| 0 | 0 | 0           | 0          |
| 0 | 1 | 0           | 1          |
| 1 | 0 | 0           | 1          |
| 1 | 1 | 1           | 1          |

NOT is shorter still: input 0 gives 1, input 1 gives 0. Deriving a
table like this from a live circuit — press, observe, record — is
exactly what you did at the bench, whether you called it that or not.

## Writing it down

Each gate has a Boolean equation. For AND the output is Y = A • B;
for OR, Y = A + B; for NOT, $Y = \overline{A}$, the bar meaning
"flipped". The borrowed × and + symbols are fair warning that this is
arithmetic of a kind — just one where nothing exceeds 1. The other
standard gates are these three in trench coats: NAND and NOR are AND
and OR followed by NOT, and XOR outputs 1 when its inputs differ.
[[Logic Gates Practice]] builds fluency with all six, and
[[Predict the Circuit]] will ask you to run gates in your head before
current settles the argument.

%%curriculum-start%%
## Curriculum connection

![[A3.3]]

![[A3.4]]
%%curriculum-end%%
