---
title: Predict the Circuit
publish: true
created: __CREATED__
tags:
  - warm-ups
---
A schematic goes up — a supply, a switch, a resistor or two, an LED,
sometimes a branch that splits. Last year the question was *what
lights up*. This year the question is **how much current flows, in
milliamps, and what voltage sits across each part** — and you commit
to those numbers on paper before anybody touches the bench supply.
The meter comes on afterwards, and it does not care how confident you
were.

## How to run it

1. Show the schematic with every value marked. One quiet minute.
   Everyone writes a number with a unit, not a range and not a shrug.
2. Collect predictions on the board without comment. The spread is
   the interesting part.
3. Build it, or bring up the bench that already has it built. Meter
   in series for current, in parallel for voltage — the discipline
   from [[Using a Multimeter]] applies even in a five-minute warm-up.
4. Compare. Then the real question: *why* is the measurement not
   exactly your prediction? There is always a reason, and it is
   always a component behaving like itself.

> [!example]- A worked round
> On screen: a 9 V supply, a switch, a 470 Ω resistor, and a red LED
> in series. Predict the current. The LED is not a resistor, so you
> subtract its forward drop first — call it 2.0 V for a red one —
> so the resistor gets the remaining 7.0 V, and
> $I = 7.0 / 470 \approx 0.0149\ \text{A}$, or 14.9 mA.
> The meter says 14.2 mA. Not a failure — a finding. Two honest
> causes: the resistor measured 487 Ω, comfortably inside its ±5 %
> band, and this LED's actual forward drop was 2.1 V rather than the
> 2.0 V you assumed. Put those in and the arithmetic lands on
> 14.2 mA. The model was right; the inputs were rounded.

## Why a number and not a description

"The LED will light" is unfalsifiable — it lights at 2 mA and it
lights at 25 mA, and one of those two will kill it before the end of
the period. A prediction with a number can be wrong, which is the
only property that makes a prediction worth making. It is also the
habit the whole of [[The Prediction Contest]] is built on, and the
reason your [[Tech Journal]] asks for predicted *and* measured on
every bench day.

## One variation

Reverse it into design. Name a requirement — "10 mA through a green
LED on a 5 V rail" — and have everyone produce the resistor value and
then the nearest real value they could pull from the drawer. Reading
a circuit is diagnosis; producing one is engineering, and the second
is what [[The Working Circuit]] will ask of you.

> [!tip] A few percent is a tolerance; ten times is a thinking error
> If your prediction and the meter differ by a few percent, look at
> tolerances, contact resistance, and the supply's actual output. If
> they differ by a factor of ten, stop and look at your working — a
> misplaced decimal, milliamps written as amps, or a component you
> treated as ohmic that never was. See [[Ohm's Law]] for where that
> last one bites.
