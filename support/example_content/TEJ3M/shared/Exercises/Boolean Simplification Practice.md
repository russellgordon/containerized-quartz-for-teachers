---
title: Boolean Simplification Practice
draft: false
created: __CREATED__
tags:
  - exercises
---
These follow [[Boolean Algebra]]. The rule for this whole page: simplify
with algebra, then **verify with a truth table**. Algebra is fast and
occasionally careless; a truth table cannot be argued with, and every
answer below carries one.

Notation: $\overline{A}$ means NOT A, a dot or nothing at all means AND,
and a plus sign means OR.

## Simplify these

1. $A + AB$
2. $AB + A\overline{B}$
3. $A + \overline{A}B$
4. $(A + B)(A + \overline{B})$
5. $\overline{A}\,\overline{B}C + \overline{A}BC + A\overline{B}C + ABC$

## Prove and apply

6. Simplify $AB + \overline{A}C + BC$. This one has a term that looks
   essential and is not — prove your answer with a full eight-row table.
7. Use De Morgan's laws to simplify $\overline{\overline{A} + \overline{B}}$,
   and state the result in plain words.
8. **Design.** A motor should run when the system is enabled and there is
   no fault, or when the system is enabled and an operator holds the
   override. Write the expression with $E$ for enabled, $F$ for fault and
   $V$ for override, simplify it, verify it, and say how many gates each
   version needs.

## Answers

> [!success]- Answer 1
> $A + AB = A(1 + B) = A \cdot 1 = A$, since $1 + B = 1$ for any $B$. This is the absorption law.
>
> | A | B | $AB$ | $A + AB$ | $A$ |
> | --- | --- | --- | --- | --- |
> | 0 | 0 | 0 | 0 | 0 |
> | 0 | 1 | 0 | 0 | 0 |
> | 1 | 0 | 0 | 1 | 1 |
> | 1 | 1 | 1 | 1 | 1 |
>
> The last two columns match in all four rows. In words: if A alone is
> enough to make the output 1, adding a term that also requires A cannot
> add anything.

> [!success]- Answer 2
> Factor: $AB + A\overline{B} = A(B + \overline{B}) = A \cdot 1 = A$.
>
> | A | B | $AB$ | $A\overline{B}$ | sum | $A$ |
> | --- | --- | --- | --- | --- | --- |
> | 0 | 0 | 0 | 0 | 0 | 0 |
> | 0 | 1 | 0 | 0 | 0 | 0 |
> | 1 | 0 | 0 | 1 | 1 | 1 |
> | 1 | 1 | 1 | 0 | 1 | 1 |
>
> B appears in both terms, once each way, so B does not matter at all —
> the output depends only on A. Two AND gates and an OR gate reduce to a
> wire.

> [!success]- Answer 3
> $A + \overline{A}B = A + B$.
>
> | A | B | $\overline{A}B$ | $A + \overline{A}B$ | $A + B$ |
> | --- | --- | --- | --- | --- |
> | 0 | 0 | 0 | 0 | 0 |
> | 0 | 1 | 1 | 1 | 1 |
> | 1 | 0 | 0 | 1 | 1 |
> | 1 | 1 | 0 | 1 | 1 |
>
> The reasoning without a table: if A is 1 the whole thing is 1 anyway,
> so the second term only ever contributes when A is 0 — and when A is 0,
> $\overline{A}B$ is just B. So the expression is "A, or else B", which
> is $A + B$. This one surprises people, so check it every time you use
> it.

> [!success]- Answer 4
> Multiply out: $(A + B)(A + \overline{B}) = AA + A\overline{B} + BA + B\overline{B}$. Now $AA = A$, and $B\overline{B} = 0$, leaving $A + A\overline{B} + AB = A(1 + \overline{B} + B) = A$.
>
> | A | B | $A + B$ | $A + \overline{B}$ | product | $A$ |
> | --- | --- | --- | --- | --- | --- |
> | 0 | 0 | 0 | 1 | 0 | 0 |
> | 0 | 1 | 1 | 0 | 0 | 0 |
> | 1 | 0 | 1 | 1 | 1 | 1 |
> | 1 | 1 | 1 | 1 | 1 | 1 |
>
> Confirmed. Note the two identities doing the work: a variable ANDed
> with itself is itself, and a variable ANDed with its own complement is
> always 0.

> [!success]- Answer 5
> Group in pairs and factor twice.
>
> $\overline{A}C(\overline{B} + B) + AC(\overline{B} + B) = \overline{A}C + AC = C(\overline{A} + A) = C$.
>
> | A | B | C | $F$ | $C$ |
> | --- | --- | --- | --- | --- |
> | 0 | 0 | 0 | 0 | 0 |
> | 0 | 0 | 1 | 1 | 1 |
> | 0 | 1 | 0 | 0 | 0 |
> | 0 | 1 | 1 | 1 | 1 |
> | 1 | 0 | 0 | 0 | 0 |
> | 1 | 0 | 1 | 1 | 1 |
> | 1 | 1 | 0 | 0 | 0 |
> | 1 | 1 | 1 | 1 | 1 |
>
> Four AND gates, an OR gate, and two inverters collapse into a piece of
> wire. The tell was in the original expression: all four combinations of
> A and B appear, each with C, so between them they cover every case
> where C is 1 and no case where it is 0.

> [!success]- Answer 6
> The answer is $AB + \overline{A}C$ — the $BC$ term is redundant. This
> is the consensus theorem, and the reasoning is worth following: for
> $BC$ to matter, both B and C must be 1. If A is also 1 then $AB$ is
> already 1. If A is 0 then $\overline{A}C$ is already 1. There is no
> case left over, so $BC$ can never be the only term making the output 1.
>
> | A | B | C | $AB$ | $\overline{A}C$ | $BC$ | full | reduced |
> | --- | --- | --- | --- | --- | --- | --- | --- |
> | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
> | 0 | 0 | 1 | 0 | 1 | 0 | 1 | 1 |
> | 0 | 1 | 0 | 0 | 0 | 0 | 0 | 0 |
> | 0 | 1 | 1 | 0 | 1 | 1 | 1 | 1 |
> | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
> | 1 | 0 | 1 | 0 | 0 | 0 | 0 | 0 |
> | 1 | 1 | 0 | 1 | 0 | 0 | 1 | 1 |
> | 1 | 1 | 1 | 1 | 0 | 1 | 1 | 1 |
>
> The last two columns agree in all eight rows, so one AND gate and its
> wiring come out of the design for free.

> [!success]- Answer 7
> De Morgan says a bar over an OR becomes an AND of the barred terms: $\overline{\overline{A} + \overline{B}} = \overline{\overline{A}} \cdot \overline{\overline{B}} = A \cdot B$.
>
> | A | B | $\overline{A} + \overline{B}$ | negated | $AB$ |
> | --- | --- | --- | --- | --- |
> | 0 | 0 | 1 | 0 | 0 |
> | 0 | 1 | 1 | 0 | 0 |
> | 1 | 0 | 1 | 0 | 0 |
> | 1 | 1 | 0 | 1 | 1 |
>
> In plain words: "it is not the case that A is missing or B is missing"
> means "both A and B are present". Three gates — two inverters and a NOR
> — become one AND gate.

> [!success]- Answer 8
> **Write it as the words dictate:** $M = E\overline{F} + EV$.
>
> **Simplify by factoring:** $M = E(\overline{F} + V)$.
>
> | E | F | V | $E\overline{F}$ | $EV$ | original | factored |
> | --- | --- | --- | --- | --- | --- | --- |
> | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
> | 0 | 0 | 1 | 0 | 0 | 0 | 0 |
> | 0 | 1 | 0 | 0 | 0 | 0 | 0 |
> | 0 | 1 | 1 | 0 | 0 | 0 | 0 |
> | 1 | 0 | 0 | 1 | 0 | 1 | 1 |
> | 1 | 0 | 1 | 1 | 1 | 1 | 1 |
> | 1 | 1 | 0 | 0 | 0 | 0 | 0 |
> | 1 | 1 | 1 | 0 | 1 | 1 | 1 |
>
> **Gate count:** the original needs an inverter, two AND gates, and an
> OR gate — four. The factored form needs an inverter, an OR gate, and
> one AND gate — three.
>
> **The part that matters more than the gate count:** read the simplified
> form back. "The system must be enabled, and either there is no fault or
> someone is holding the override." That is a clearer statement of the
> requirement than the one you started with — and it exposes a design
> question the original hid, namely whether an override really should be
> able to run a motor that has reported a fault. Take that one to
> [[When Good Enough Is Not Safe]] before you wire it.

Build the reduced version rather than the first one you drew, in
[[Build the Logic Machine]].

%%curriculum-start%%
## Curriculum connection

![[A5.3]]

![[B3.4]]
%%curriculum-end%%
