---
title: Sampling Techniques
publish: true
created: __CREATED__
tags:
  - concepts
enableToc: true
---
Unit 3 opened with a question that sounded like a formality: *how tall
is the average student in this school?* In [[The Sampling Frame]] your
group measured the eight people nearest you and produced a number.
Every group produced a number. The numbers disagreed by more than the
height of a Grade 9 student, and one group's sample had somehow
contained the entire senior basketball team. Nobody had cheated.
Everyone had sampled badly, in a different direction.

## Population and sample

The **population** is every individual you want to describe. The
**sample** is the subset you actually observe. Everything in Unit 4
depends on a leap between them, so it is worth being blunt about why
we take that leap at all: censuses are expensive, slow, and sometimes
physically impossible. A manufacturer testing whether matches light
cannot test every match — there would be no matches left.

A good sample is not a small population. It is one whose members were
selected by a process that gave the population a fair chance of being
represented, and it is big enough that ordinary variation does not
swamp the signal. Both halves of that sentence matter, and the first
half matters more. A badly chosen sample of 10 000 is worse than a
well-chosen sample of 400, because size makes a biased estimate
*more confidently* wrong.

## Five techniques, and what each one costs

| Technique | How it works | Watch for |
| --- | --- | --- |
| Simple random | Every member equally likely; draw names from the full list | Needs a complete, current list of the population |
| Systematic | Order the list, pick a random start, take every $k$th | Fails if the list has a hidden cycle matching $k$ |
| Stratified | Split into groups (grade, region), sample each in proportion | You must know the group sizes in advance |
| Convenience | Ask whoever is nearby | Almost always unrepresentative; cheap and tempting |
| Voluntary response | Let people opt in | Attracts the strongly opinionated; the calm stay home |

The first three are **random** methods and can support an honest
inference. The last two are not, and no amount of later arithmetic
repairs them. This is the practical meaning of the curriculum's
[[C2.2|sampling expectation]]: the technique is a claim about who
could have been in your data, and you are answerable for that claim.

Stratified sampling deserves a second look, because it is the one that
most often improves a student investigation. If you are surveying a
school with 300 students per grade in Grades 9 and 10 but only 180 in
Grade 12, a simple random sample of 60 will *probably* land roughly
proportional — but "probably roughly" is doing a lot of work. Stratify
and it lands proportional every time.

## Principles of good primary collection

When you gather your own data rather than downloading someone else's,
three principles carry most of the weight.

**Randomization** decides who or what ends up in each group, so that
the differences you find are not differences you accidentally
arranged. **Replication** means enough observations that a single odd
result cannot drive your conclusion. **Control** means holding
everything else fixed, or at least recording it, so the variable you
changed is the one your results are about.

Then there are the mundane things that quietly ruin data: a question
that leads, a scale that was never calibrated, a form that will not
accept a legitimate answer, a survey posted at a time of day only some
people are online. Write down your collection procedure before you
collect anything, and one honest question after every design decision:
**who is missing from this sample?** Anyone your method could never
reach does not appear in your data, does not appear in your graphs,
and does not appear in your conclusion — but they are still in the
population you are claiming to describe.

The systematic ways that gap opens up are the subject of the next
page, [[Bias]], and dissecting a real example is the work of
[[The Survey Autopsy]]. When you are ready to design your own
collection, [[Choosing a Data Set]] walks through the decision from
the other end.

%%curriculum-start%%
## Curriculum connection

![[C2.1]]

![[C2.2]]

![[C2.5]]
%%curriculum-end%%
