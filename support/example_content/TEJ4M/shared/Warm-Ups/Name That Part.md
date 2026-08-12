---
title: Name That Part
draft: false
created: __CREATED__
tags:
  - warm-ups
enableToc: true
---
One component goes up on the projector, and this year it is usually
too small to hold. Last year four things earned the point: the name,
the job, the value read off the part, and one place it lives. All four
still count. The fifth is the Grade 12 one, and it is the only one
that takes real work — **what you would have to find in its datasheet
before you were willing to design it in**.

That last answer is never "nothing". Every part has at least one
number that decides whether it belongs in your circuit, and finding it
is the difference between choosing a part and grabbing one.

## How to run it

1. Reveal the part — a photograph at high magnification, or the real
   thing under the bench camera. One quiet minute, no calling out.
   Everyone writes name, job, value or part number, one place it
   lives, and the one datasheet figure they would want.
2. Cold-call the five answers in that order. The datasheet answer
   comes last because it is the one worth arguing about.
3. The class judges each claim: read, inferred, or guessed. Say which
   one you did. "Inferred from the package" is an honest and useful
   answer; "guessed" is fine as long as it is labelled.
4. If the part is in the room, put it under the camera and read the
   marking aloud, then check it against a meter or the reel label.

## Reading a surface-mount part

Through-hole parts wear stripes. Surface-mount parts wear a code, a
package, or nothing at all, and each of those is a different reading
problem.

| Marking | How to read it | Example |
| --- | --- | --- |
| Three digits | Two significant figures, then a count of zeros | `103` is 10 kΩ |
| Four digits | Three significant figures, then a count of zeros | `1002` is 10.0 kΩ |
| `R` in the middle | The `R` stands in for the decimal point | `4R7` is 4.7 Ω |
| Two digits plus a letter | EIA-96: the digits index a three-figure value, the letter is the multiplier | `01C` is 100 × 100, so 10 kΩ |
| Nothing at all | Very common on ceramic capacitors — the value is on the reel, not the part | Measure it or trust the label |

The package itself carries information before you read a single
character. Imperial chip sizes are named for their dimensions in
hundredths of an inch: an 0805 is about 0.08 in by 0.05 in, an 0603 is
0.06 in by 0.03 in, an 0402 is 0.04 in by 0.02 in. Smaller packages
shed heat less well and are harder to rework, so package size is a
maintenance decision as much as a space one.[^1]

> [!example]- A worked round
> On screen: a black rectangle roughly 2 mm long with `1002` printed
> on it in white, on a board beside a microcontroller. Name: a
> surface-mount chip resistor, 0805 by the look of it against the
> neighbouring 0.1 in header. Job: it sets a current, or divides a
> voltage — here it sits between an analog input pin and ground, so
> almost certainly the lower leg of a divider. Value: four-digit code,
> 100 followed by two zeros, so 10.0 kΩ, and the fourth digit means a
> tighter tolerance part than a three-digit code would suggest.
> Where it lives: any place a signal has to be scaled down to fit an
> ADC's input range. The datasheet figure I would want: its tolerance
> and its temperature coefficient, because a divider's accuracy is
> the accuracy of the *ratio*, and a drifting ratio is a reading that
> moves when the room warms up.

## Decoding a part number

Semiconductors and integrated circuits are named, not valued, and the
name has two parts. The base number identifies the device. Everything
after it — letters, digits, a slash, a trailing tape-and-reel code —
is the manufacturer's ordering code, and it usually encodes the
package, the temperature grade, the lead finish, and how the part was
shipped.

You do not guess those suffixes. Every datasheet has an **ordering
information** table, normally near the back, that decodes its own part
numbers exactly. Two parts with the same base number and different
suffixes can have different pinouts, different thermal performance,
and different guaranteed operating temperature ranges. Ordering the
wrong suffix is the most expensive kind of small mistake, because the
part arrives, fits, works on the bench, and fails in the enclosure.

Many parts also carry a date or lot code, often four digits for year
and week. That is not the value and never has been — it is traceability,
and it is how a manufacturer recalls a bad batch.

## The package is a thermal decision

Two parts with the same silicon inside and different packages have
different power ratings, because a package is mostly a heat path. The
figure the datasheet gives for this is a thermal resistance from the
junction to the surrounding air, and it always comes with a condition
attached: measured on a particular test board, with a particular area
of copper, in still air.

This is why "same chip, smaller package" is never a free swap, and it
is exactly the reasoning [[Reliability and Derating]] applies to every
part that carries real current. When you meet the derating curve in
[[Reading a Datasheet Like an Engineer]], the package is the reason
the curve slopes.

## One variation

Run it as a specification. Give the requirement — "a resistor that
sets 12 mA through an indicator on a 5 V rail, in an enclosure that
reaches 60 °C, with 1 % accuracy" — and ask for the value, the
tolerance class, the power rating, the package, and one sentence of
justification for each. Producing a part number from a requirement is
what [[Component Selection and Tolerances]] asks of you all semester,
and this is the five-minute rehearsal.

> [!tip] "It is rated for it" is a Grade 11 answer
> Push every answer one notch further than last year. Not just what
> the part does, but what it does at the top of its temperature range,
> at the edge of its tolerance, after a year in a warm box. If your
> answer would survive somebody asking "and how do you know?" three
> times in a row, it is a Grade 12 answer.

[^1]: Watch for the trap that catches people who have only ever used
    one system: chip packages have both imperial and metric size
    codes, and the numbers collide. Imperial 0603 and metric 1608 are
    the same physical part — 1.6 mm by 0.8 mm. A bare "0402" in a
    supplier's listing means nothing at all until you know which
    system is being used, so check the millimetre dimensions rather
    than trusting the four digits.
