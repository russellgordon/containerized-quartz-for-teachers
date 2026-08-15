---
title: True or False
publish: true
created: __CREATED__
tags:
  - number-talks
---
One claim on the board — say, *the chance of two things both
happening is the product of their chances* — and one job: put it on
trial. Is it ever true? Always true? A rule is not a fact because it
is written down; it is a claim about the world, and claims earn their
verdicts in court. The stakes are real: this particular claim feels
so natural that some part of every class believes it without
conditions, quietly, until the trial.

## How we play

1. Vote first — true, false, or "it depends" — before any working.
2. Prosecute and defend: test cases, count outcomes, draw a tree,
   whatever bites.
3. Deliver a verdict with evidence: *always*, *never*, or *exactly
   when*.

> [!example]- The trial of $P(A \cap B) = P(A) \times P(B)$
> - "Draw one card. Let $A$ be 'it is a heart' and $B$ be 'it is a
>   face card'. Then $P(A) = \frac{13}{52} = \frac{1}{4}$ and
>   $P(B) = \frac{12}{52} = \frac{3}{13}$, and their product is
>   $\frac{3}{52}$. Count directly: there are exactly 3 hearts that
>   are face cards, so $\frac{3}{52}$. It works."
> - "Now draw *two* cards without putting the first back. Let $A$ be
>   'the first is an ace' and $B$ be 'the second is an ace'. The
>   product says $\frac{1}{13} \times \frac{1}{13} =
>   \frac{1}{169}$, about 0.0059. Count honestly: after an ace
>   leaves, only 3 aces remain among 51 cards, so the truth is
>   $\frac{4}{52} \times \frac{3}{51} = \frac{1}{221}$, about
>   0.0045. False."
> - Verdict: *exactly when the events are independent* — when
>   knowing that $A$ happened tells you nothing about $B$. The hearts
>   and the face cards never learned about each other; the two aces
>   did. The rule that survives every case is
>   $P(A \cap B) = P(A) \times P(B \mid A)$, and the familiar version
>   is just the special case where $P(B \mid A)$ happens to equal
>   $P(B)$. [[Conditional Probability]] is where that gets said
>   properly.

## One variation

The claim that decides court cases: *$P(A \mid B)$ is the same as
$P(B \mid A)$.* A screening test catches 99% of the people who have a
rare condition, so a positive result means a 99% chance you have it —
right? Put it on trial with 100,000 people, of whom 100 actually have
it. The test flags 99 of those 100. It also flags 1% of the 99,900
who are healthy, which is 999 people. Of the 1,098 flagged in total,
only 99 are ill: about **9%**, not 99%. Both conditional
probabilities exist, both are correct, and they are nothing alike.
Swapping them is the most expensive mistake in this course, and
[[Conditional Probability]] is where the room learns to refuse it.

> [!tip] One witness is not a proof
> A single counter-example kills an "always" — the two aces ended the
> trial above. A single confirming example proves nothing: the hearts
> and face cards testified for the claim and the claim was still
> false as stated. To speak about *all* cases you need a reason, not
> a coincidence — and inventing the test case you were not given is
> [[Checking Your Own Work]] wearing a courtroom robe.
