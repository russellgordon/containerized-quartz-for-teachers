---
title: Spot the Hazard
draft: false
created: __CREATED__
tags:
  - warm-ups
enableToc: true
---
A photo of a bench goes up — staged the evening before, never a real
student's workspace — and the question has not changed since Grade 10:
what here could hurt someone, or something? Keep answering it. The
bench has more on it now, and some of what is dangerous about this
year's work is not on a bench at all.

So this routine runs in two modes, and we alternate. Some days a
photograph, and the hazards are physical. Other days a **schematic**,
and the hazards are decisions somebody made at a desk. The second kind
is new, and it is the kind that ships.

## How to run it

1. Show the photo or the drawing. One quiet minute; everyone counts,
   nobody calls out. Counts get written down before any discussion.
2. Poll the counts. The spread between lowest and highest is the hook.
3. Name hazards one at a time. Each gets four answers now, not three:
   what is the harm, who or what gets hurt, what is the fix, and —
   the Grade 12 addition — **what would have caught it earlier**? A
   checklist, a review, a measurement, a test.
4. Close on the sneakiest one nobody caught. There is always one, and
   on schematic days it is usually something that is *absent*.

## The bench sweep

Run this over your own bench before you energise anything. Eight
seconds, once it is a habit.

- [ ] Supply output off, voltage set, and the current limit set to
      something a little above what the circuit should draw — set
      before the leads go on, never after
- [ ] Scope probe ground clips on circuit ground and nowhere else,
      and the earth pin on every instrument's power cord intact
- [ ] Logic analyzer ground connected to the target, and its threshold
      set for the logic family you are actually probing
- [ ] Meter dial and jacks match the measurement, and the leads are
      not still in the current jack from last period
- [ ] Iron in its stand, extraction on, eye protection on faces
- [ ] Large capacitors discharged through a resistor and *verified*
      with a meter, not merely unplugged
- [ ] Anything with a motor or a coil restrained, and nothing energised
      without a second person in the room
- [ ] No drinks anywhere; walkways clear; sleeves and hair secured

## The design sweep

The schematic version of the routine. Every item below is a hazard you
cannot photograph, and every one of them has shipped in real products.

- [ ] An inductive load — relay coil, solenoid, motor — switched by a
      transistor with no path for the collapsing current. Without a
      flyback diode or a snubber, the switch sees a voltage spike far
      above the supply and dies, sometimes weeks later.
- [ ] A battery or a large supply feeding a rail with no fuse, no
      polyfuse, and no current limit anywhere in the design. The bench
      supply protected you; the product will not have one.
- [ ] A connector that will mate the wrong way round, or two connectors
      of the same shape carrying different voltages.
- [ ] A capacitor bank with no bleed resistor, so the board stays
      charged after it is unplugged.
- [ ] A part running at 90 % of its rating on the bench, in a design
      destined for a sealed enclosure — see [[Reliability and Derating]].
- [ ] Motor return current sharing a copper path with a sensor return,
      so the measurement moves whenever the actuator does.
- [ ] Firmware with no watchdog, driving something that must not keep
      running if the controller hangs.
- [ ] A safety function that exists only in software, where the
      previous version of the machine had a physical interlock.
- [ ] Exposed test points at a voltage somebody could touch, with no
      label saying so.

> [!example]- A staged bench worth stealing
> An iron lying on the mat with its cord looped under the board; a
> scope probe ground clip attached to the emitter of a transistor that
> is nowhere near ground; a bench supply with the current limit wound
> fully open and the output already on; a logic analyzer clipped to a
> 1.8 V target with its threshold still set for 5 V logic; a
> power-supply board with one fat electrolytic capacitor, unplugged
> ten seconds ago; safety glasses folded on the shelf; a can of pop
> beside the mat.
>
> Seven hazards. Most classes find four. The two that get missed are
> the probe's ground clip and the capacitor, because both look exactly
> like a safe bench in a photograph and neither does anything until it
> does everything at once. The analyzer threshold hurts nothing and
> nobody — it just wastes your whole afternoon producing decoded
> garbage you will believe.

> [!danger] The ground clip is connected to the building
> On a normal bench scope, the probe's ground clip is joined through
> the instrument and its power cord to the building's earth. Clip it
> to a node that is not at ground potential and you have shorted that
> node to earth through your probe. The fix is never to defeat the
> earth pin on the scope's plug — that puts the whole chassis at
> whatever potential you clipped to, and it is one of the few things
> in this room that can genuinely kill you.
> [[Using an Oscilloscope Properly]] covers how to make the
> measurement you actually wanted.

## One variation

Students stage it. On photo days, building a convincingly hazardous
bench without creating a real hazard while shooting it — a rule of the
exercise, not a technicality — requires knowing every rule you are
pretending to break. On schematic days, draw a circuit with exactly
three design hazards in it and hand it to another bench. Hiding a
missing flyback diode where somebody will not immediately look is a
better test of your understanding than finding one.

> [!tip] Fix beats find, and prevent beats fix
> End every round with the safe version. Then go one further and name
> the routine that would have caught it without anybody being clever:
> the power-up ritual in [[Bench Power Supply Habits]], the checklist
> in [[Safety in the Lab]], the second pair of eyes at a design
> review. Hazards found by a system stay found; hazards found by a
> sharp person on a good day come back.
