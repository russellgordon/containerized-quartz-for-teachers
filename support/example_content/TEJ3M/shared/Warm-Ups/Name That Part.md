---
title: Name That Part
publish: true
created: __CREATED__
tags:
  - warm-ups
enableToc: true
---
One component goes up on the projector or comes down the bench in a
dish. Last year three things earned the point: the name, the job, and
one place it lives. This year there is a fourth, and it is the hard
one — *its value, read off the part itself*. Colour bands, a printed
code, a package marking. The bin does not come labelled, and neither
does the board you will be repairing.

## How to run it

1. Reveal the part. One quiet minute, no calling out — everyone
   writes name, job, value, and one place it lives.
2. Cold-call the four answers in that order. The value comes last so
   nobody hides behind it.
3. The class judges each claim: exact, close, or guessed.
4. If the real part is in the room, hold it up and read the marking
   aloud. Then check it on a meter. The meter settles arguments.

## The four-band resistor code

Two digits, a multiplier, a tolerance — read from the end where the
bands are crowded, with the lone tolerance band trailing.

| Colour | Digit | Multiplier |
| --- | --- | --- |
| Black | 0 | ×1 |
| Brown | 1 | ×10 |
| Red | 2 | ×100 |
| Orange | 3 | ×1 000 |
| Yellow | 4 | ×10 000 |
| Green | 5 | ×100 000 |
| Blue | 6 | ×1 000 000 |
| Violet | 7 | — |
| Grey | 8 | — |
| White | 9 | — |

Gold and silver in the last position mean tolerance, ±5 % and ±10 %.
In the multiplier position they mean ×0.1 and ×0.01, which is how you
get resistors under ten ohms. A five-band resistor gives three digits
instead of two, because precision parts need the extra one.

> [!example]- A worked round
> On screen: a small beige cylinder, bands yellow, violet, orange,
> gold. Name: a resistor. Job: it sets the current in a branch, and
> turns the surplus into heat. Value: 4, then 7, then ×1 000 — so
> 47 kΩ, ±5 %, meaning anywhere from about 44.7 kΩ to 49.4 kΩ and
> still in spec. One place it lives: pulling a microcontroller input
> up to the supply rail so a button has something to pull down
> against. Full marks — every claim is a property or a measurement,
> not a vibe.

## Not everything wears stripes

- **Surface-mount resistors** carry a printed code instead. `103`
  means 10 followed by three zeros: 10 kΩ. `4R7` means 4.7 Ω, with
  the R standing in for the decimal point.
- **Ceramic capacitors** use the same trick in picofarads. `104` is
  10 followed by four zeros — 100 000 pF, which everyone in the trade
  says as 100 nF.
- **Semiconductors** are named, not valued. `1N4148`, `BC547`,
  `74HC00` — a part number that means nothing until you look it up.
  That is not a failure of your memory; it is the point of
  [[Reading a Datasheet]].

## One variation

Run it backwards. Give the value and the job — "220 Ω, limits the
current through an indicator LED on a 5 V rail" — and ask for the
band colours and one board it would be found on. Producing the code
from the number is harder than reading it, and it is the direction
you work in when you are pulling parts for a build.

> [!tip] "It resists" is not a job
> Push every answer one notch more specific, exactly as we did last
> year. A capacitor does not "help the circuit" — it stores charge
> and releases it, which is why it can smooth a supply or set a
> timing interval. Precise jobs are the habit
> [[Components and Their Markings]] cashes in later.
