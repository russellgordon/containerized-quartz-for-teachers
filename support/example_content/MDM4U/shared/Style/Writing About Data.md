---
title: Writing About Data
publish: true
created: __CREATED__
tags:
  - reference
enableToc: true
---
Half this course happens out loud at the whiteboards; the other half
happens when you put a number into a sentence. That sentence is where
statistics is actually done, and where it is most often broken —
because a number carries no memory of where it came from, and a
sentence has to supply what the number forgot.

> [!important] Write so a sceptic could check you
> Write for a classmate who missed today, doubts your conclusion, and
> has time to look up your source — not for a teacher scanning for
> keywords. If your sceptic could ask "how many people was that?" or
> "compared to what?", answer it before they can.

## The vocabulary is the toolkit

Claims come in strengths, and the words signal which one you are
making. Choosing a stronger word than your evidence supports is the
most common error in statistical writing, and it is not a style
problem — it is a false statement.

| You are saying… | Say it like this |
| --- | --- |
| I see a pattern but have not tested it | "I **conjecture** that…" |
| The data fits this idea, and others too | "These data are **consistent with**… but do not rule out…" |
| A difference is too large to shrug off | "A gap this large would be **unlikely** if the two groups were really the same, so…" |
| One thing causes another | Only with a controlled comparison behind it — see [[Correlation and Causation]] |
| I found where the claim breaks | "**Counter-example:** among respondents under 20, the pattern reverses" |

The fourth row is the one that costs marks and, later, costs careers.
"Students who eat breakfast score higher" is a defensible sentence.
"Eating breakfast raises your marks" is a different claim entirely,
and no amount of correlation will buy it.

## The anatomy of an honest statistic

A statistic reported alone is a rumour with a decimal point. A
complete one has five parts, and you can hear all of them in a
sentence like this:

> In a telephone survey of 1,004 Canadian adults conducted by a
> national polling firm, 62% said they walk somewhere every day. The
> margin of error is about ±3 percentage points, 19 times out of 20.

1. **The number** — 62%.
2. **The denominator** — 62% *of 1,004 adults*, not of Canada, and
   not of everyone the firm tried to reach.
3. **The source** — who collected it. A number with no source cannot
   be checked, and a claim that cannot be checked is not evidence.
4. **The method** — telephone, which already tells a careful reader
   something about who is likely to be missing.
5. **The uncertainty** — ±3 points, 19 times out of 20. That last
   phrase is the standard Canadian way of saying 95% confidence, and
   it means the *method* lands within 3 points of the truth in 19 of
   every 20 samples like this one.

> [!warning] Decimal places you did not earn
> With about a thousand respondents, the honest resolution is roughly
> ±3 percentage points. Writing "62.3%" claims a precision three
> hundred times finer than the survey can deliver. Extra digits do
> not make a number look more careful — to anyone who can read a
> margin of error, they make it look less so. Round to what your
> sample can support, and say what that is.

## Describe your sample honestly

Every real dataset has a gap between who you *wanted* to describe and
who you actually reached, and your reader cannot see that gap unless
you point at it. Three sentences usually cover it:

- **Who could have been included.** "The survey went to all 1,200
  students with a school email address" — which quietly excludes
  anyone without one.
- **Who actually answered.** "412 responded." Then the sentence
  people skip: non-responders are almost never a random subset of the
  invited. Students who ignore school email are a *kind* of student.
- **Who you removed, and why.** "Fourteen responses were dropped
  because the grade field was blank." That is not an admission of
  sloppiness; it is the difference between a result and a magic
  trick.

None of this weakens your report. It is the part that makes the rest
of it worth reading, and it is exactly what
[[The Culminating Investigation]] grades under *limitations*. The
sourcing conventions live in [[Citing Your Sources]].

## Sentence stems that unlock a stuck write-up

- Among the people surveyed, … — but the survey could not reach …
- The data are consistent with … ; they cannot distinguish it from …
- The difference is … , which is larger than I would expect from
  sampling variation alone, because …
- A third variable that could produce this pattern is … , and I could
  not rule it out because …
- If I ran this again, I would change … , because …

## The finished-report standard

Before calling written work done, walk [[Showing Your Thinking]]'s
checklist, with this course's additions: the question restated, the
reasoning visible, every number saying what it is a number *of*, and
a conclusion sentence that carries its own uncertainty. "62% of
respondents" is an answer; "62%" is a fragment, and $0.62$ is not
even that.

The same standard applies to your [[Math Journal]], with one
addition: name what *you* did and thought, not just what the group
did. "We decided the sample was biased" hides the learning; "I
noticed the form only went to students in the school band, and argued
we should say so rather than quietly generalize" shows it — and that
is the evidence [[How Marks Work]] actually counts.
