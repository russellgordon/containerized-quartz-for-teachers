---
title: Mistakes Are Data
draft: false
created: __CREATED__
enableToc: true
tags:
  - skills
  - discussion
---
A result you did not expect is information. It is only a failure if you
throw it away without finding out which kind of unexpected it was.

Last year that mostly meant sorting careless mistakes from real
limitations of the method. This year there is a third possibility and
then a fourth, and they are the interesting ones: the system may not
have been in the state you assumed it was in, or the **model** you read
your data through may not apply to what you built.

## The question we are arguing about

When is it honest to leave a data point out of your analysis, and when
is leaving it out the same thing as making the data up?

Then the version this course adds. When your result disagrees with a
model, how do you decide whether the measurement is wrong or the model
has run out of road — and what would you have to do to tell?

## Four different things people call a mistake

| Kind | What it looks like | What you do about it |
| --- | --- | --- |
| A blunder | Wrong reagent, wrong scale read, 2.53 written where the balance said 2.35 | Repeat the trial, and record that you did |
| A limitation of the method | Heat escaping from a coffee-cup calorimeter; a thermometer that resolves 0.1 °C on a 2 °C rise; an electrode you could not clean properly | Report it, size it, and say **which direction** it pushed the result |
| The system was not in the state you assumed | You read the concentrations before equilibrium had actually been reached; the cell was already discharging while you measured it | Not an error in the reading. The reading is honest and describes a different system from the one your calculation assumed |
| The model does not apply here | Standard potentials predicted one thing and your non-standard cell did another; the ideal-solution assumption behind your ICE table was not met | The most valuable of the four. Say what the model assumes, and which assumption your set-up broke |

The first two belong where they belonged last year: blunders in your
notes, limitations in the limitations section of
[[Writing a Lab Report]], where they earn marks.

Rows three and four are the new work, and they are worth separating
carefully, because they feel identical from the bench. Row three says
your model was fine and your system was not yet the thing the model
describes. Row four says your system was exactly what you thought and
the model still failed to describe it. The first is fixed by waiting, or
by checking; the second is a finding.

> [!important] The Grade 12 case you will meet in Unit 4
> Sooner or later somebody will calculate an equilibrium constant from
> their own measurements and get a value well below the one in the data
> booklet. The instinct is to call it experimental error and move on.
>
> Work through the four rows instead. Did you misread a burette — a
> blunder. Was your colorimeter reading in a range where it is not
> linear — a limitation. **Had the system actually stopped changing when
> you sampled it** — row three, and by far the commonest answer, because
> a mixture on its way to equilibrium looks exactly like a mixture at
> equilibrium in a single reading. Or was your temperature genuinely
> different from the booklet's, in which case the booklet's number was
> never about your flask and there is no disagreement to explain.
>
> Four candidate accounts, each with a different test attached. Naming
> which one you checked is worth more here than getting the printed
> value.

## The rule about outliers has not changed

You may exclude a measurement **only** for a reason independent of the
fact that you disliked the answer: the sample was contaminated, the
crucible cracked, the burette was refilled mid-titration, the
thermometer was still equilibrating. Write the reason down at the time,
in ink, in the notebook.

"It did not fit the trend" is not a reason. It is the result you were
trying to test.

The Grade 12 addition is quieter and catches more people. Do not exclude
a point because it disagrees with a model either. A point that disagrees
with a model is the only kind of evidence that could ever tell you where
the model stops, and this course marks you on knowing where models stop.

> [!example]- One afternoon, sorted four ways
> A group builds a zinc–copper cell, reads the potential, and gets a
> value noticeably below the one they calculated from
> $E^\circ_{\text{cell}} = E^\circ_{\text{cathode}} - E^\circ_{\text{anode}}$.
> Four accounts, all plausible, and each one testable:
>
> **Blunder.** The leads are reversed, or the meter is on the wrong
> range. Test: swap the leads and look at the sign; check the range.
> Thirty seconds, and it is the first thing to rule out.
>
> **Limitation.** The zinc surface is oxidised, so the electrode is not
> really the metal named in the table. Test: sand it and read again. If
> the reading rises, the limitation was real and you can say which way
> it pushed — down, always down.
>
> **The system was not what you assumed.** The salt bridge is drying
> out, so the circuit is partly open and the cell is not delivering what
> it could. Test: replace it and watch whether the reading recovers.
>
> **The model does not apply.** The tabulated values are for solutions
> at 1 mol/L, at 25 °C, and your solutions are neither. The model was
> never making a claim about this cell. Test: nothing at the bench —
> instead, state the conditions the table assumes, note which ones your
> set-up broke, and predict the *direction* the difference should go.
>
> Notice that the fourth account is the only one where the correct
> response is to write rather than to fiddle. Notice also that two or
> three of these can be true at once, which is why "the answer" is
> rarely a single sentence.

## Two anomalies that were very nearly binned

**A base with no hydroxide in it.** The Arrhenius picture of acids and
bases, which served chemistry well for decades, required a base to
supply $[\text{OH}^-]$. Ammonia has no oxygen and no hydroxide anywhere
in $\text{NH}_3$, and a solution of it is unmistakably basic. For years
this sat in textbooks as an exception to be memorised. Then Brønsted and
Lowry, independently and within months of each other, proposed that an
acid donates a proton and a base accepts one — at which point ammonia
stopped being an exception and became the ordinary case, taking its
proton from the water and leaving the hydroxide behind. You will meet
the resolution in
[[Acids and Bases]]. The point here is that the anomaly was known,
written down, and taught as an oddity for a very long time before
anybody treated it as a fault in the model rather than a quirk of one
compound.

**A molecule that refused to behave like its formula.** Benzene,
$\text{C}_6\text{H}_6$, has far too few hydrogens for six carbons, which
by every rule of the time meant it should react like a highly
unsaturated compound and add things eagerly across its bonds. It does
not. It substitutes instead, and stubbornly. Kekulé's ring structure
accounted for the formula; accounting for the *reactivity* took the idea
that the bonding electrons are not sitting in fixed alternating bonds at
all. The unexpected result there was not a number. It was a reaction
that kept refusing to happen — and refusing to happen is data.

> [!note] What I actually want from you
> Not clean data. I want to be able to reconstruct, from your record,
> exactly what happened, including the run that went badly and what you
> did next. A careful investigation that names its problems and says
> which model it was reading its numbers through is worth more here than
> a tidy one that hides both, and [[How Marks Work]] says so in the
> categories.

Bring one thing that did not go as expected this unit, with the numbers.
We will sort the room's examples into the four kinds above and argue
about the borderline cases, which is where all the interesting ones
live. Related: [[What Counts as Evidence]] and [[Showing Growth]].
