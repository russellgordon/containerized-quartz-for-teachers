---
title: Getting Unstuck
draft: false
created: __CREATED__
enableToc: true
tags:
  - skills
---
Being stuck is normal and is not a sign of anything. Being stuck for
forty minutes without changing what you are doing is the part worth
fixing.

There is one change from Grade 11 worth naming at the top. Last year,
most stuck was *procedural* — you knew the chemistry and could not find
the route through the arithmetic. This year a good deal of it is
**structural**: you are applying a model that does not fit the question,
and no amount of care with the algebra will rescue that. Sorting one
from the other in the first two minutes is the whole trick.

## Four kinds of stuck, and they want different things

Work down the list. Stop at the first one that is true.

1. **You cannot say what quantity is wanted, in what units.** Read the
   question aloud, underline the quantity and its unit, and write both
   at the top of the page before anything else. A surprising share of
   stuck is misreading, and your ear catches what your eye skipped.
2. **You know the quantity but not which model gets you there.** This is
   the new one. Ask what *kind* of question it is: how far (equilibrium),
   how fast (kinetics), how much energy (thermochemistry), which way
   (redox or Le Châtelier), what shape (VSEPR). The units of the answer
   usually tell you — kJ/mol is a thermochemistry question, mol/L at
   equilibrium is not.
3. **You have the model and cannot set up the arithmetic.** Write the
   balanced equation, then the table or expression the model uses — an
   ICE table, a $K$ expression, a $q = mc\Delta T$, a pair of
   half-reactions. Half the problems in this course solve themselves at
   the moment the structure is on paper, because the route becomes
   visible.
4. **The set-up is right and the numbers will not come out.** Then it is
   arithmetic, and it is usually a logarithm, an exponent, or a
   calculator key. Go straight to
   [[Working with Logarithms in Chemistry#Where people actually go wrong]]
   and check your answer against that table before assuming the
   chemistry is at fault.

Being honest about which number you are on saves more time than anything
else on this page. If you cannot get past step 2, no amount of staring
will close the gap, because what is missing is an idea rather than a
step. That is the moment to ask, not an hour later.

## Units are still a debugging tool

The habit that carried you through Grade 11 has not stopped working.
Write every quantity with its unit, write the unit you are trying to end
up with, and check that the operation you are about to perform produces
it.

- Joules divided by moles gives joules per mole. Correct.
- Grams times joules per gram per degree gives joules per degree — which
  is not an energy, so you have forgotten to multiply by $\Delta T$.
- Moles per litre times litres gives moles. Correct.

Two Grade 12 additions to the same habit:

- **Logarithms eat units.** You cannot take the logarithm of "0.0025
  mol/L" as such; what goes into a logarithm is a pure number, which is
  part of why the equilibrium constants in your booklet are printed
  without units. So if you find yourself carrying mol/L through a pH
  calculation, stop — the unit lives outside the logarithm, not inside
  it.
- **Check the exponent separately from the digits.** The commonest
  wrong answer in Unit 4 is right to two significant figures and out by
  a factor of a thousand. Work out roughly what power of ten the answer
  should be *before* you press anything.

## Is this number a plausible size?

Before you accept an answer, ask whether it could be true. You do not
need to know the right answer to know that an answer is absurd, and
noticing takes five seconds.

| An answer of | Is telling you |
| --- | --- |
| A pH of 23, or a pH of $-400$ | An exponent or a sign has gone missing |
| A negative equilibrium constant | An arithmetic slip — $K$ is a ratio of concentrations and cannot be negative |
| An equilibrium concentration larger than what you started with | Your $x$ has the wrong sign, or you added when you should have subtracted |
| A cell potential of 40 V from two half-cells | You added two reduction potentials instead of subtracting |
| An enthalpy of combustion of 12 J/mol | A kilo went missing somewhere |
| A rate constant that changed when you changed the concentration | It is not a rate constant. Something in the setup is wrong |

That last row is the Grade 12 flavour of this check: the implausible
thing is not the size of the number but the fact that a quantity which
is supposed to be constant did not stay constant. Watch for those.

## Things to try before asking, in order of how often they work

1. **Say the question out loud.**
2. **Write down what you know, with units**, and what you want, with its
   unit.
3. **Write the balanced equation** and mark which quantity you were
   given and which you want.
4. **Do the simpler version.** Assume a 1:1 stoichiometry. Assume 1.00
   mol/L. Assume the change is negligible and see whether the answer
   even makes sense, then decide whether the assumption was allowed.
   Working the simple case first tells you what the awkward case
   changed.
5. **Find the sentence where your understanding stops.** Not the page —
   the sentence. That sentence is your question.

## Then ask well

"I don't get it" gets you a re-explanation of something you may already
understand. Any of these gets you a real answer in one exchange:

| Instead of | Say |
| --- | --- |
| "I don't get equilibrium" | "I can build the ICE table, but I don't know when I'm allowed to drop the $x$ in the denominator" |
| "The lab didn't work" | "We got $\Delta H$ of 54 kJ/mol against about 57 in the booklet, and I can't tell whether that's heat loss or something else" |
| "I'm lost on titrations" | "I follow it to the equivalence point, then I lose which species is left in solution" |
| "My answer's wrong" | "I get pH 2.87 and the key says 2.87 for a different concentration, so I think I've used the wrong row" |
| "I don't understand cells" | "I can write both half-reactions, but I can't tell which one gets reversed" |

Each of those tells me where to start. The first column tells me
nothing, so my first three questions have to be diagnostic — and that is
three minutes you did not need to spend.

> [!note] Twenty minutes, then ask
> That is the rule I would like you to use on homework. Twenty minutes
> of genuine attempts, **with the attempts written down**, and then stop
> and bring them to me. The written attempts are not evidence against
> you; they are the most useful thing you can hand me, because a wrong
> attempt shows exactly which idea is bent.
>
> And bring the attempt even when you think it is embarrassing. The
> version of a mistake that is written down takes thirty seconds to
> diagnose. The version that has been rubbed out takes ten minutes to
> reconstruct.

Where to ask: [[Getting Help]] has the routes and [[Help Sessions]] has
the times. If the problem is that your result disagrees with everyone
else's, that is a different and more interesting situation — see
[[Mistakes Are Data]].
