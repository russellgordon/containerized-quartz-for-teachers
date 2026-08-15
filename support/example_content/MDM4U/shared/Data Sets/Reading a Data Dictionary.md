---
title: Reading a Data Dictionary
publish: true
created: __CREATED__
tags:
  - data-sets
enableToc: true
---
A group downloaded a real table, opened it, and reported that the
average grade of respondents was $23.4$. There is no Grade 23. What
had happened is that the file used $99$ to mean "did not answer", the
spreadsheet cheerfully averaged the 99s along with everything else,
and nobody had read the documentation. Five seconds of reading would
have prevented an hour of confident nonsense. This page is about those
five seconds.

## What a data dictionary is

A **data dictionary** — sometimes called a codebook, metadata file, or
user guide — is the document that explains what each column of a data
set actually contains. Good publishers ship one with every download.
It tells you the name of each variable, what it measures, in what
units, what values are legal, and what the collector did about
missing answers.

Without it you are guessing, and the guesses fail silently. A column
called `INC` might be individual income or household income, before or
after tax, in dollars or thousands of dollars, for last year or an
average of five. All four ambiguities change your conclusion and none
of them are visible in the numbers.

## An example, invented for the purpose

Nothing below is a real file. It is written the way a real one is
written, so you can practise reading the format.

| Column | Meaning | Type of data | Values and units | Missing |
| --- | --- | --- | --- | --- |
| `resp_id` | Anonymous respondent number | Nominal categorical | 1 to 84 | never blank |
| `grade` | Grade of study | Ordinal categorical | 9, 10, 11, 12 | `99` = not stated |
| `mode` | Usual way of getting to school | Nominal categorical | 1 walk, 2 bicycle, 3 bus, 4 car, 5 other | `9` = not stated |
| `commute_min` | One-way travel time | Continuous numerical | minutes, nearest minute | blank cell |
| `dist_km` | Home-to-school distance | Continuous numerical | kilometres, 1 decimal | `-1` = unknown |

Read down the "Type" column first, because it decides what you are
allowed to do. `resp_id` and `mode` are stored as numbers and are not
numbers: the mean of `mode` is meaningless, and the fact that a
spreadsheet will compute it anyway is the whole hazard. `grade` is
ordinal — the order is real, the spacing is not necessarily — so a
median is defensible and a mean is arguable. Only `commute_min` and
`dist_km` are genuinely quantitative, and only they belong in a
standard deviation, a scatter plot, or a regression.

Then read the "Missing" column, because it decides what you must
remove. Three different conventions appear in one small table — `99`,
`9`, blank, and `-1` — and that is realistic. Every one of them will
be silently averaged if you let it.

## Codes, missing values, and units

Three habits handle almost everything.

**Decode before you analyse.** Replace `1, 2, 3, 4, 5` with `walk,
bicycle, bus, car, other` in a working copy. Charts become readable
and the temptation to average a category disappears.

**Convert missing codes to genuinely empty cells** before any
calculation, and count how many you removed. That count is a finding.
If 40 of 84 respondents did not state their distance, you no longer
have a distance study; you have a study of people willing to state a
distance, which is the non-response bias that [[Bias]] warned you
about.

**Check the units against reality.** A `dist_km` value of $340$ is a
typing error or a different unit. A commute of $0$ minutes is either a
child who lives on site or a form that treated blank as zero. One
minute spent skimming the maximum and minimum of every numerical
column catches most disasters, and it is step one of
[[Cleaning Messy Data]].

## Questions the documentation should answer

- [ ] Who collected this, when, and for what purpose?
- [ ] What population was sampled, and by what method?
- [ ] How many were approached, and how many responded?
- [ ] What exactly did each question ask? (The wording, not the
      summary — [[Bias]] explains why wording is data collection.)
- [ ] Are these individual records or already-aggregated totals?
- [ ] What do the missing-value codes mean?
- [ ] Have the values been rounded, suppressed, or adjusted for
      privacy?

That last one surprises people. Statistical agencies routinely
suppress or round small cell counts so individuals cannot be
identified — so a column of totals may not add exactly to its own
sum, and the agency is being careful rather than sloppy.

If a data set arrives with no documentation at all, you have a
decision to make and you should make it early. Sometimes the columns
are self-evident and the source is reputable. Often they are not, and
the right move is to go back to [[Where to Find Real Data]] and find a
version that comes documented. An analysis you cannot explain the
inputs of is not an analysis you can defend in
[[The Culminating Investigation]].

%%curriculum-start%%
## Curriculum connection

![[C1.3]]

![[C2.5]]

![[E1.3]]
%%curriculum-end%%
