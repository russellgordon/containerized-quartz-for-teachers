---
title: Using a Multimeter
draft: false
created: __CREATED__
tags:
  - tutorials
enableToc: true
---
The multimeter is the instrument you will touch every day this
semester, and it is the one students most often break in the first
month. Not by dropping it — by setting it to measure one thing and
then using it to measure another. This page is the procedure that
prevents that, and it is worth learning as a fixed ritual rather than
as advice.

> [!danger] Set the dial and check the jacks before the probes touch anything
> In that order, every single time, out loud if it helps. A meter set
> to measure current has almost no resistance between its probes —
> it is, deliberately, nearly a piece of wire. Put that across a
> power supply and you have created a short circuit through your
> instrument. Best case, the meter's fuse dies and the period is
> over. Worse cases exist and involve heat.

## Where the leads go

The black lead lives in **COM** and effectively never moves. The red
lead moves, and moving it is half of what "setting up the meter"
means.

| What you want | Red lead | Dial | How the meter joins the circuit |
| --- | --- | --- | --- |
| Voltage | The V/Ω jack | V, DC unless told otherwise | **In parallel** — probes across the two points |
| Small current | The mA jack | mA | **In series** — circuit broken, meter inserted |
| Large current | The dedicated high-current jack | A | In series, and briefly |
| Resistance | The V/Ω jack | Ω | Across the part, power off |
| Continuity | The V/Ω jack | The beeper symbol | Across the connection, power off |

Read that table's right-hand column again, because it contains the
single most important idea about this instrument: **voltage is
measured across things, current is measured through them.** A
voltmeter is a bystander. An ammeter has to become part of the
circuit.

## Measuring voltage

Probes go on either side of whatever you want the voltage across —
across a resistor, across an LED, from a node to ground. Nothing is
disconnected and nothing is rewired. Red on the point you expect to be
more positive; if the display shows a negative number, the reading is
still correct and your probes are simply the other way round, which is
information rather than an error.

Take the habit of naming the two points out loud before you place the
probes: "across R2", "from the junction to ground". Half of all
confusing readings are a probe on a point nobody chose.

## Measuring current

This is the one that requires actual surgery. Current has to flow
*through* the meter, which means the circuit has to be opened and the
meter inserted into the gap. On a breadboard that usually means
pulling one end of a jumper and putting the two probes into the hole
it left and the hole it came from.

The order that keeps everything alive:

- [ ] Power off at the supply
- [ ] Decide where the break goes, and open the circuit there
- [ ] Move the red lead to the current jack, set the dial to current
- [ ] Start on the highest range if the meter is not autoranging
- [ ] Power on, read, power off
- [ ] Move the red lead back to the V/Ω jack **before you walk away**

That last box is not decoration. A meter left with its leads in the
current jack is a trap for the next person, and the next person is
usually you at the start of the following period.

## Resistance and continuity

Both of these live in a world where the circuit is **off**. A meter
measuring resistance is supplying its own small test current, and any
voltage already present in the circuit will corrupt the reading or
damage the instrument.

There is a second trap that catches everyone once. Measuring a
resistor while it is still soldered into a board measures that
resistor *in parallel with every other path between the same two
points*, so the number comes out lower than the part's real value.
Lift one leg of the component, or measure it out of circuit, and the
reading becomes trustworthy.

Continuity is the same measurement with a beeper: it sounds when
resistance is below a low threshold, which makes it perfect for
checking a solder joint, a jumper, or a length of wire with your eyes
on the board instead of on the display.

## What the meter changes just by being there

Every instrument disturbs what it measures, and a Grade 11 technician
knows in which direction.

- On voltage ranges, a typical digital meter presents a very high
  resistance — around ten megohms — so it draws a tiny current of its
  own. High-impedance circuits can still be pulled off their true
  value by it.
- On current ranges, the meter is not a perfect wire. The small
  voltage it drops is called **burden voltage**, and it means the
  circuit you are measuring is running on slightly less voltage than
  it had before you inserted the instrument. In a low-voltage circuit
  that can be enough to change the number you came to measure.
- `OL`, or a lone `1` at the left of the display, means over-range —
  the quantity is bigger than the selected range, not broken. Go up a
  range.
- If a current range suddenly reads zero on a circuit you know is
  running, suspect the meter's fuse before you suspect the circuit.
  Something taught the fuse a lesson recently.

> [!warning] What we do not measure in this room
> Meters and their leads carry a measurement category rating that
> describes the electrical environment they are safe in. Ours are
> rated for bench work on low-voltage, current-limited supplies, and
> that is the only thing we use them for. Nobody in this course
> measures a mains circuit, an outlet, or the inside of a
> mains-powered supply — not with these meters and not with me
> standing next to you. If a job seems to require it, the answer is
> that the job is not ours; see [[Safety in the Lab]].

Everything above turns into practice at the bench in
[[Measure a Circuit]], and every number it produces belongs in your
[[Tech Journal]] with its unit and its conditions attached.
