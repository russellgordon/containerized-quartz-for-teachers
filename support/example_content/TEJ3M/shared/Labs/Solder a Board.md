---
title: Solder a Board
draft: false
created: __CREATED__
tags:
  - labs
enableToc: true
---
A breadboard is a rehearsal. Today the circuit stops being temporary: you
will make joints on scrap until they are consistently good, then build a
small indicator circuit on stripboard that will still work after it has
been in a bag with your keys.

Soldering is the first genuinely dangerous skill in this course. The iron
sits somewhere between 315 and 370 °C depending on the
solder — hot enough that a touch is a burn before your reflexes arrive,
and hot enough that nothing about it is forgiving. Read
[[Soldering Safely]] in full before your iron is plugged in, not after.

> [!danger] Safety notes
> **Fume extraction on, or the bench fan drawing fumes away from your
> face.** Rosin flux fumes are a respiratory sensitiser: people develop
> asthma from years of breathing them, and the damage is cumulative and
> permanent. You do not get to skip this because it is one period.
> **The iron lives in its stand. Every time.** Not on the mat, not on
> the board, not balanced on a wire. **Never pass an iron to anybody** —
> set it in the stand and let them pick it up. **Assume every iron is
> hot**, including one that has been off for a minute. **Safety glasses
> on before you clip a single lead**: trimmed leads leave at speed and
> they leave sideways. Point the clipped end down and cup it as you cut.
> **Leaded solder means washing your hands** before you eat, and no food
> or drink at a soldering bench regardless. **Unplug at the end of the
> period** and leave the iron in its stand to cool where the next person
> can see it. Nothing here overrides [[Safety in the Lab]] — it adds to
> it.

## What you need

- [ ] Temperature-controlled iron in a stand, damp sponge or brass wool
- [ ] Fume extraction or a bench fan pulling away from your face
- [ ] Solder, scrap protoboard for practice, and one piece of stripboard
- [ ] One LED, one $220\ \Omega$ resistor, two-pin header, hookup wire
- [ ] Flush cutters, safety glasses, multimeter, and your journal

## Predict before you build

1. **Size the resistor and justify it in writing.** The board runs from
   a $5\ \text{V}$ supply. A red LED holds roughly $2\ \text{V}$ across
   itself, so the resistor drops the remaining $3\ \text{V}$. For a
   comfortable $15\ \text{mA}$,
   $R = 3\ \text{V} / 0.015\ \text{A} = 200\ \Omega$, and
   $220\ \Omega$ is the nearest standard part — which gives
   $3 / 220 = 13.6\ \text{mA}$. That is the current you are predicting.
2. **Predict the supply current the finished board will draw**, and
   write it down. On this board it is the LED current and nothing else,
   so the two numbers are the same. Say so explicitly; on the next board
   they will not be.
3. **Predict the resistor's dissipation** as a check:
   $P = I^2 R = (0.0136)^2 \times 220 \approx 0.041\ \text{W}$. A
   quarter-watt part is not remotely troubled. Note that number — you
   will compare it to how warm the part actually feels.

## The work

4. **Tin the tip** and wipe it. A bright, wetted tip transfers heat; a
   dull, oxidised one does not, and every bad joint in this room today
   will start with a tip somebody did not clean.
5. **Heat the joint, not the solder.** Tip against both the pad and the
   lead for about a second, then feed solder into the *joint* so the
   heat of the metal melts it. Solder melted on the tip and dabbed on is
   the classic cold joint.
6. **Feed, then withdraw in order**: solder away first, iron away
   second. Roughly one to two seconds of heat for a small joint.
7. **Inspect every joint.** A good one is shiny, and concave where it
   flows up onto the lead — like a tiny volcano. A bad one is dull, or
   balled up on the lead without wetting the pad. Reflow the bad ones
   with a touch of fresh solder; do not just add more.
8. **Practise ten joints on scrap** and have them checked before you
   touch the real board.
9. **Build the board**: resistor, LED (long leg to positive), header.
   Clip leads with glasses on.
10. **Test before power.** Continuity across each joint, and a
    resistance check from the supply pins that is roughly the resistor
    value plus the LED's reverse behaviour, not a short. Only then
    connect $5\ \text{V}$ and measure the current in series.

## Results

| Joint or measurement | Predicted | Observed | Action taken |
| --- | --- | --- | --- |
| Practice joints passing inspection (of 10) | | | |
| Resistor value, measured (Ω) | | | |
| Supply current, calculated (mA) | 13.6 | | |
| Supply current, measured (mA) | | | |
| Resistor dissipation, calculated (W) | 0.041 | | |
| Joints reflowed after inspection | | | |

## Predicted against measured

If your measured current is meaningfully below the prediction, the usual
causes are a red LED whose forward drop is nearer $2.1\ \text{V}$ than
$2.0\ \text{V}$, a resistor sitting at the high end of its tolerance
band, or a supply that is not quite at $5\ \text{V}$ under load. Measure
the voltage actually across the LED and actually across the resistor,
and see whether the two together account for the difference. They almost
always do.

If your measured current is far *above* prediction, stop and check
whether the resistor is really in the circuit. On stripboard the classic
fault is an uncut track shorting straight past it.

## The question that matters

Pick your worst joint — the one you reflowed — and explain what was
physically wrong with it. Not "it looked bad": what had the solder failed
to do, and what would that failure have done to the circuit six months
from now, in a device somebody depended on? Then photograph your best and
worst joints side by side for [[Documenting Your Build]].

%%curriculum-start%%
## Curriculum connection

![[B3.1]]

![[D1.1]]
%%curriculum-end%%
