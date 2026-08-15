---
title: Sample Data Sets to Practise On
publish: true
created: __CREATED__
tags:
  - data-sets
enableToc: true
---
Sometimes you want to try a technique without betting your
investigation on it — to see what a real standard deviation feels
like, or find out whether a scatter plot of two things you chose says
anything at all. This page is a list of data you can make or gather
yourself, plus an honest description of the kinds of tables the public
catalogues carry. There are no downloadable files here and no numbers
invented for your convenience. Data you collected is data you
understand, and that is worth more in this course than size.

## Data you can generate in one class

| What to collect | Variables | Good for |
| --- | --- | --- |
| Reaction time, ruler-drop or on-screen, 30+ trials each | Time (ms), and hand used | Histograms, mean and standard deviation, roughly normal shape |
| 200 rolls of two number cubes | The sum | Experimental vs theoretical probability, probability histograms |
| 50 shots at a target or a hoop, fixed number of attempts | Successes out of $n$ | [[The Binomial Distribution]] against real trials |
| Draws from a bag of two colours, without replacement | Count of one colour | [[The Hypergeometric Distribution]] |
| Handspan and height for everyone present | Two lengths (cm) | Scatter plot, $r$, regression — and a common-cause discussion |
| Word length in the first 100 words of two different texts | Letters per word, source | Comparing two one-variable distributions with boxplots |
| Time to complete a short puzzle, with and without background noise | Time (s), condition | A controlled comparison, and a lesson in confounders |

The last one is worth doing properly, because it is the only entry
that is an **experiment** rather than an observation. Assign the two
conditions randomly, run enough trials, and hold everything else
fixed — the three principles from [[Sampling Techniques]] in about
fifteen minutes.

## Data you can collect over a week

Small, patient, and genuinely yours.

**A class or school survey.** Commute time, hours of sleep, hours of
paid work, screen time, number of siblings, preferred transport. Two
numerical columns give you a relationship question; a numerical column
plus a categorical one gives you a comparison. Design it with the
cautions from [[Bias]] and pilot it on five people first.

**A repeated measurement.** Bus or train arrival time against the
scheduled time, every school day. The distribution of lateness is
almost never symmetric — buses can be very late and only slightly
early — which makes it an excellent argument against reporting a mean
alone.

**Something you time or count daily.** Minutes to charge a device,
steps walked, temperature at a fixed time, the length of the lunch
queue. Any of these produces a real one-variable data set in ten days,
and the boring ones are often the most instructive.

**A paper-helicopter or paper-airplane experiment.** Vary one design
measurement, record flight time or distance, repeat each setting
several times. This is a regression data set you built on purpose,
and residuals mean something visible.

## Data you can record from what you already watch

Sports statistics are the classic student data set for a reason: the
events are public, the definitions are stable, and you can record them
yourself from broadcasts or from a league's own published results.
Shots and goals per game, minutes played, points per quarter, service
faults — pick two variables that plausibly relate and see whether they
do. Be careful with one temptation: a strong relationship between two
box-score statistics is usually **common cause** (both driven by
minutes played or team quality), which is precisely the discussion
[[Correlation and Causation]] wants you to have.

The same applies to anything else you can count from public life at a
fixed rule: songs on a chart and their lengths, films and their
running times, transit vehicles passing a corner in ten minutes.
Write the counting rule down before you start, or your data will
change definition halfway through.

## Kinds of tables the public catalogues carry

If you would rather practise on secondary data, the catalogues named
in [[Where to Find Real Data]] carry these *kinds* of tables. Search
them by subject; the exact titles change, so go and look rather than
trusting a list.

**Statistics Canada** typically carries population counts broken down
by age, sex, and geography; labour force figures by industry and
month; income and earnings by family type; educational attainment;
health indicators; crime rates by police service; and commuting
patterns collected through the census. Most are aggregate tables —
totals and averages for groups — which suits comparison questions
across provinces or years better than questions about individuals.

**Municipal open data portals** typically carry transit ridership,
road collision records, service requests, building permits, park and
facility inventories, and recreation program registrations. Local
questions are strong investigation questions because you already
understand the context and can sanity-check a surprising number.

**The Ontario Data Catalogue** typically carries provincial-scale
education, health, transport, and environment data published by
ministries, including school- and board-level assessment results.

**Gapminder** typically carries country-level indicators over long
time spans — life expectancy, income per person, child mortality,
fertility, population — which makes it the natural home for a
question about how a global pattern has changed over decades.

Whatever you choose, run it through the six checks in
[[Choosing a Data Set]] before you spend an evening on it, and expect
to spend real time in [[Cleaning Messy Data]] afterwards. Practise
here first; commit [[The Culminating Investigation]] to a data set
only once you have seen one all the way through.

%%curriculum-start%%
## Curriculum connection

![[C2.1]]

![[C2.5]]

![[E1.3]]
%%curriculum-end%%
