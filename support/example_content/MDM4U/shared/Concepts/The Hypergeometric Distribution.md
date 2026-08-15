---
title: The Hypergeometric Distribution
publish: true
created: __CREATED__
tags:
  - concepts
enableToc: true
---
Same deck, same question, one word changed. Draw three cards *with*
replacement and ask for exactly one face card — binomial, and your
group had it in a line. Draw three cards *without* replacement and the
line broke, because after the first card the deck is not the deck any
more. The two answers turned out to be $0.410$ and $0.424$. Close
enough to feel like rounding, different enough to matter, and the
reason for the difference is the entire content of this page.

## Sampling without replacement

A **hypergeometric** random variable counts successes in a sample
drawn without replacement from a finite population. Every draw shrinks
the pool and changes the odds for the next one, so the trials are
dependent — precisely the condition [[The Binomial Distribution]]
requires and this situation refuses.

You already own the tool for it. Because the draws happen all at once
as far as the mathematics is concerned, this is a counting problem:
count the samples you want, divide by the samples there are, exactly
as [[Combinations]] taught.

## The formula as three choices

Let the population have $n$ members of which $a$ are successes, and
take a sample of size $r$. Then

$$P(X = x) = \frac{\binom{a}{x}\binom{n-a}{r-x}}{\binom{n}{r}}$$

Three choices, read left to right: choose which $x$ successes are in
your sample, choose which $r - x$ failures fill the rest of it, and
divide by every sample of size $r$ you might have drawn.

A committee of $4$ from $7$ women and $5$ men, exactly $2$ women:

$$P(X = 2) = \frac{\binom{7}{2}\binom{5}{2}}{\binom{12}{4}} = \frac{21 \times 10}{495} = \frac{14}{33} \approx 0.424$$

The mean has a shortcut too, and it says what you would hope:

$$\mu = r \cdot \frac{a}{n}$$

For that committee, $4 \times \frac{7}{12} = \frac{7}{3} \approx 2.33$
women on average — the sample size times the population's success
rate, which is what "representative" means in one equation.

## Binomial or hypergeometric?

| | Binomial | Hypergeometric |
| --- | --- | --- |
| Sampling | With replacement | Without replacement |
| Trials | Independent | Dependent |
| $P(\text{success})$ | Constant $p$ | Changes every draw |
| Built from | Powers of $p$ | Combinations |
| Typical wording | "each trial", "repeated", "returned" | "committee", "hand", "sample from a batch" |

The distributions converge when the population is large relative to
the sample. Drawing 3 cards from 52 changes the odds noticeably;
drawing 3 people from 40 000 changes them so little that pollsters
treat their surveys as binomial without apology. A common rule of
thumb is that a sample under about $5\%$ of the population makes the
difference negligible — a rule you should test yourself rather than
inherit.

Two honest cautions. First, the hypergeometric histogram is narrower
than the matching binomial one: sampling without replacement is
*more* informative, because you cannot waste a draw re-asking the same
person. Second, everything here assumes every member of the population
is equally likely to be drawn, and real sampling rarely obliges — the
gap between that assumption and reality is what
[[Sampling Techniques]] and [[Bias]] spend Unit 3 on.

Quality control, card hands, and committee questions are the classic
homes for this distribution, and they are all in
[[Distributions Practice]]. If your own investigation samples from a
finite list — a class, a team, a batch — this is your model, not the
binomial.

%%curriculum-start%%
## Curriculum connection

![[B1.5]]

![[B1.6]]

![[B1.7]]
%%curriculum-end%%
