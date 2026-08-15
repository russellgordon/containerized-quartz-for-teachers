---
title: Conditional Probability
publish: true
created: __CREATED__
tags:
  - concepts
enableToc: true
---
The class went quiet when the numbers landed. A screening test that
catches 99% of a disease and gives a false alarm only 5% of the time —
and if you test positive, the chance you actually have it is about
one in six. Several people asked to see the arithmetic again. The
arithmetic was fine. What had failed was the assumption that a test's
accuracy and a patient's odds are the same number. They are not, and
this page is about the difference.

## Conditioning is re-drawing the sample space

$P(A \mid B)$ — the Ministry writes it in words, "the probability of
$A$ given $B$" — asks: *among only the outcomes where $B$ happened,
what fraction are also $A$?* You are not changing the world. You are
throwing away every row of the table that does not satisfy $B$ and
re-computing inside what is left.

$$P(A \mid B) = \frac{P(A \text{ and } B)}{P(B)}$$

Rearranged, that is the **multiplication rule**, which is usually the
more useful form:

$$P(A \text{ and } B) = P(B) \times P(A \mid B)$$

Two aces drawn without replacement:
$\frac{4}{52} \times \frac{3}{51} = \frac{1}{221}$. The second factor
is a conditional probability, and the whole reason it is $\frac{3}{51}$
and not $\frac{4}{52}$ is that the first draw already happened. A tree
diagram makes this visible — each branch after the first carries
conditional probabilities, and multiplying along a path is the
multiplication rule in action.

## Independent or dependent

Events are **independent** when conditioning changes nothing:
$P(A \mid B) = P(A)$, equivalently $P(A \text{ and } B) = P(A)
\times P(B)$. Otherwise they are **dependent**. Testing this on real
data means building a table and comparing.

| Of 200 students | Part-time job | No job | Total |
| --- | --- | --- | --- |
| Walks to school | 30 | 50 | 80 |
| Does not walk | 45 | 75 | 120 |
| Total | 75 | 125 | 200 |

Here $P(\text{job}) = \frac{75}{200} = 0.375$ and
$P(\text{job} \mid \text{walks}) = \frac{30}{80} = 0.375$. Identical,
so in this sample the two attributes are independent — knowing that
someone walks tells you nothing about their employment. Change a
single cell and that stops being true, which is a good thing to try
before you trust the idea.

One distinction that trips almost everyone: mutually exclusive is not
the same as independent. Mutually exclusive events are maximally
*dependent* — if $A$ happened, $B$ definitely did not. The number talk
[[True or False]] runs that pair deliberately, because saying it once
is never enough.

## The test-accuracy shock, worked

Take 10 000 people. Suppose 1% have the condition, the test catches
99% of them, and it falsely flags 5% of everyone else.

- Of the $100$ who have it, $99$ test positive.
- Of the $9\,900$ who do not, $5\%$ — that is $495$ — test positive.
- Positives in total: $99 + 495 = 594$.

$$P(\text{has it} \mid \text{positive}) = \frac{99}{594} = \frac{1}{6} \approx 16.7\%$$

The false alarms outnumber the true ones five to one, and the reason
is not the test. It is that healthy people vastly outnumber sick ones,
so even a small false-positive *rate* applies to a huge group. When a
conditional probability surprises you, count actual people in an
actual population — the arithmetic that shocked the room is arithmetic
a Grade 12 student can do in a minute.

This same reasoning underwrites [[The Hypergeometric Distribution]],
where every draw changes the pool, and it is the sharpest tool you own
for [[The Statistical Claim Report]]. Practise it until the tree
diagrams come automatically in
[[Conditional Probability Practice]].

%%curriculum-start%%
## Curriculum connection

![[A1.5]]

![[A1.6]]

![[A2.5]]
%%curriculum-end%%
