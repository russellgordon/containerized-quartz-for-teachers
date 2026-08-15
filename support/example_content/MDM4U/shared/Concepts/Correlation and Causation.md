---
title: Correlation and Causation
publish: true
created: __CREATED__
tags:
  - concepts
enableToc: true
---
In [[The Spurious Correlation Hunt]] your group went looking for two
completely unrelated things that move together, and it was far too
easy. Somebody found a pairing with $r$ above $0.9$ and presented it
with a straight face and a plausible-sounding mechanism, and for about
twenty seconds the room believed it. That is the whole lesson. A high
correlation is not evidence of a mechanism. It is an invitation to go
find one — or to find out there isn't one.

## Five ways two variables can move together

| Type | What is happening | Example |
| --- | --- | --- |
| Cause and effect | $x$ genuinely produces a change in $y$ | A tree's age and its diameter |
| Common cause | A third variable drives both | Ice cream sales and forest fires — both driven by summer |
| Reverse cause and effect | $y$ is actually causing $x$ | Police numbers and reported crime, if crime prompts hiring |
| Accidental | Coincidence, often over a short window | The consumer price index and the number of known planets |
| Presumed | Plausible, untested, believed anyway | "Students who eat breakfast get better marks" |

The three the Ministry names by name are cause-and-effect,
common-cause, and accidental; the other two are the ones that most
often survive into a finished report unchallenged. **Presumed** is the
dangerous one, because it feels like reasoning. A story that explains
the correlation is not evidence for the correlation — you can invent a
story for any pair of variables in about ten seconds, and in the
spurious hunt you did.

## Confounding, in one picture

A **confounding variable** is one that influences both of your
variables and was never in your data. Ice cream and drownings; summer
sits behind both. Coffee drinking and lung disease; smoking used to
sit behind both, and generations of studies had to be redone.

The reason confounders are hard is not that they are subtle. It is
that they are *absent*. Nothing in a scatter plot, a correlation
coefficient, or a regression output can warn you about a column you
never collected. Only knowledge of the subject can, which is why the
background research in [[The Culminating Investigation]] is not
throat-clearing before the mathematics — it is part of the
mathematics.

> [!question]- Self-check: a district reports that schools with more
> library books have higher graduation rates. Which of the five is
> most likely? (click to expand)
> Almost certainly **common cause**. Schools with larger budgets and
> wealthier catchments buy more books *and* have higher graduation
> rates for a dozen reasons that have nothing to do with the books.
> Funding is the confounder. Notice how tempting cause-and-effect is
> here — the presumed story ("reading improves outcomes") is
> plausible and possibly even true, but this data cannot tell you,
> because nothing in it isolates the books from the money. A useful
> next question: among schools with *similar* funding, does the
> pattern survive?

## What would settle it

Only one design lets you claim causation with confidence: a controlled
experiment with **random assignment**. Randomly assigning subjects to
treatment and control spreads the confounders — the known ones and the
ones nobody has thought of — evenly across both groups, so a
difference in outcomes has nowhere else to come from.

Observational data cannot do that, but it is not useless. Evidence
accumulates from consistency across studies, a dose-response pattern,
correct time order, and a mechanism that survives testing. That is how
the smoking case was actually made, over decades, without ever
randomly assigning anyone to smoke.

## Reading a claim in the news

When a headline asserts that one thing causes another, four questions
usually settle it:

Was there random assignment, or is this observational? What is the
sample, and who is missing from it — the question [[Bias]] taught you
to ask first? Is the effect large enough to matter, or merely large
enough to publish? And what would the same data look like if the
claimed cause were false?

Then look at the graph, because the graph is where the persuasion
happens: an axis that does not start at zero, a window of years chosen
to flatter, a trend line drawn through a cloud with no trend. That is
the trade being practised in [[Graph Talks]], and the whole of
[[The Statistical Claim Report]] is one careful run through these
questions on a claim you choose yourself.

Nothing here forbids you from believing a cause exists. It asks you to
say which kind of relationship you are claiming, and on what evidence
— and to write the limitation down in your own report before someone
else writes it for you. Practise the whole judgement in
[[Regression and Inference Practice]].

%%curriculum-start%%
## Curriculum connection

![[D2.2]]

![[D2.5]]

![[D3.1]]

![[D3.2]]
%%curriculum-end%%
