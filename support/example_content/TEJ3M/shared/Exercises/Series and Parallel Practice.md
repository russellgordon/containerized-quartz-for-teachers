---
title: Series and Parallel Practice
draft: false
created: __CREATED__
tags:
  - exercises
---
These follow [[Series and Parallel Circuits]] and the head-to-head
predictions from [[The Prediction Contest]]. Two checks apply to every
answer: the voltage drops around a loop must add to the supply, and the
branch currents at a junction must add to the current arriving. Use them
— they cost nothing and catch nearly everything.

## Networks you can add up

1. Three resistors — 330 Ω, 470 Ω, and 220 Ω — are wired in series
   across a 9 V supply. Find the total resistance, the current, and the
   voltage across each resistor. Then check your work.
2. Two 1 kΩ resistors are wired in parallel. What is the equivalent
   resistance?
3. A 470 Ω and a 220 Ω resistor are wired in parallel. What is the
   equivalent resistance?
4. Find the equivalent resistance of 1 kΩ, 2.2 kΩ, and 4.7 kΩ in
   parallel.
5. A 10 kΩ resistor and a 4.7 kΩ resistor form a divider across a 5 V
   supply, with the output taken across the 4.7 kΩ. What is the output
   voltage?

## Networks that need thinking about

6. A 100 Ω resistor is in series with a parallel pair of 220 Ω and
   330 Ω, all across a 12 V supply. Find the total current, the voltage
   across each part of the network, and the current in each branch.
   Verify both of Kirchhoff's laws on your answer.
7. A junction has 12 mA flowing into it and two branches leaving it. One
   branch measures 4.5 mA. What does the other carry, and what would a
   reading of 9 mA on the second branch tell you?
8. **Explain.** Why is the equivalent resistance of a parallel
   combination always smaller than the smallest resistor in it? Answer
   without using the formula.
9. **Find the error.** Asked for question 3, a classmate writes
   $470\ \Omega + 220\ \Omega = 690\ \Omega$ and then, catching
   themselves, "corrects" it to
   $\frac{1}{470} + \frac{1}{220} = 0.00667\ \Omega$. Identify both
   mistakes and give the right answer.

## Answers

> [!success]- Answer 1
> Series resistances add: $330 + 470 + 220 = 1020\ \Omega$.
>
> $I = \frac{9\ \text{V}}{1020\ \Omega} \approx 0.00882\ \text{A} = 8.82\ \text{mA}$, and that same current flows through all three.
>
> The drops: $8.82\ \text{mA} \times 330\ \Omega \approx 2.91\ \text{V}$, $8.82\ \text{mA} \times 470\ \Omega \approx 4.15\ \text{V}$, $8.82\ \text{mA} \times 220\ \Omega \approx 1.94\ \text{V}$.
>
> **The check:** $2.91 + 4.15 + 1.94 = 9.00\ \text{V}$, which is the
> supply. Kirchhoff's voltage law is satisfied, so the arithmetic stands.

> [!success]- Answer 2
> $\frac{1}{R} = \frac{1}{1000} + \frac{1}{1000} = \frac{2}{1000}$, so $R = 500\ \Omega$.
>
> Two equal resistors in parallel always give half the value of one. Worth
> memorising, because it is the fastest sanity check you own.

> [!success]- Answer 3
> For exactly two resistors the product-over-sum form is quickest: $R = \frac{470 \times 220}{470 + 220} = \frac{103400}{690} \approx 149.9\ \Omega$.
>
> Call it 150 Ω. Note that it is smaller than the 220 Ω — as it must be.

> [!success]- Answer 4
> $\frac{1}{R} = \frac{1}{1000} + \frac{1}{2200} + \frac{1}{4700} = 0.0010000 + 0.0004545 + 0.0002128 = 0.0016673$, so $R = \frac{1}{0.0016673} \approx 599.8\ \Omega$ — call it 600 Ω.
>
> The classic mistake is stopping at 0.0016673 and calling that the
> answer. That number is a *reciprocal* of resistance — you are not
> finished until you have inverted it. Sanity check: the answer must be
> less than 1 kΩ, and 600 Ω is.

> [!success]- Answer 5
> $V_{\text{out}} = 5\ \text{V} \times \frac{4700}{10000 + 4700} = 5\ \text{V} \times \frac{4700}{14700} \approx 1.60\ \text{V}$.
>
> Check it against intuition: the 4.7 kΩ is roughly a third of the total
> resistance, so it should take roughly a third of the 5 V. It does.

> [!success]- Answer 6
> **Work inward.** The parallel pair: $\frac{220 \times 330}{220 + 330} = \frac{72600}{550} = 132\ \Omega$ exactly.
>
> **Total:** $100 + 132 = 232\ \Omega$, so $I = \frac{12\ \text{V}}{232\ \Omega} \approx 0.0517\ \text{A} = 51.7\ \text{mA}$.
>
> **Voltages:** across the 100 Ω, $51.7\ \text{mA} \times 100\ \Omega \approx 5.17\ \text{V}$. Across the parallel block, $51.7\ \text{mA} \times 132\ \Omega \approx 6.83\ \text{V}$.
>
> **Branch currents:** the whole 6.83 V sits across both parallel
> resistors, so $\frac{6.83\ \text{V}}{220\ \Omega} \approx 31.0\ \text{mA}$ and $\frac{6.83\ \text{V}}{330\ \Omega} \approx 20.7\ \text{mA}$.
>
> **Both checks:** voltages, $5.17 + 6.83 = 12.00\ \text{V}$, the supply.
> Currents, $31.0 + 20.7 = 51.7\ \text{mA}$, the total. Notice also that
> the smaller resistor took the larger share of the current, which is
> what "less resistance" is supposed to mean.

> [!success]- Answer 7
> Kirchhoff's current law: what arrives leaves. $12 - 4.5 = 7.5\ \text{mA}$ in the second branch.
>
> A reading of 9 mA would mean the branches carry 13.5 mA in total while
> only 12 mA arrives, which is impossible. That is not a discovery about
> electricity — it is a measurement fault. Suspect, in order: a meter on
> the wrong range, a probe in the wrong place, or a third path out of the
> junction you have not noticed.

> [!success]- Answer 8
> Every resistor you add in parallel is another route between the same
> two points. Adding a route cannot make it harder for charge to get
> across; it can only make it easier. Since the original resistor is
> still there, still carrying what it carried before, the total current
> at a given voltage must go up — and more current for the same voltage
> *is* less resistance.
>
> Put in plumbing terms: opening a second pipe between the same two tanks
> never slows the flow. Same pressure, more pipes, more litres per
> second.

> [!success]- Answer 9
> **First mistake:** adding them as if they were in series. Series
> resistances add; parallel ones do not.
>
> **Second mistake:** reaching for the parallel formula and then
> forgetting that it produces a reciprocal — and putting the unit Ω on
> it, which should have been the giveaway. $\frac{1}{470} + \frac{1}{220}$ has units of *per ohm*, not ohms.
>
> **Correct:** invert the sum. $\frac{1}{470} + \frac{1}{220} \approx 0.006673$, and $\frac{1}{0.006673} \approx 149.9\ \Omega$ — about 150 Ω, matching answer 3.

When the arithmetic is dependable, take it to the bench in
[[Measure a Circuit]] and see how close the meter lands, then use it for
real in [[The Working Circuit]].

%%curriculum-start%%
## Curriculum connection

![[A3.3]]

![[B3.3]]
%%curriculum-end%%
