---
title: Gates on the Bench
draft: false
created: __CREATED__
tags:
  - labs
enableToc: true
---
Four integrated circuits are on your bench with their part numbers taped
over. Each one contains the same gate repeated four times, and each is a
different gate. Nobody is going to tell you which is which. You will find
out the way it was found out in the first place: apply every combination
of inputs, measure what comes out, and write the table.

The Grade 10 version of this asked whether the LED lit. This version asks
for the output *in volts*, because "high" and "low" are not properties of
the universe — they are voltage ranges a manufacturer promises, and the
promise is printed in a datasheet.

> [!danger] Safety notes
> **Static first.** These are CMOS parts, and a discharge far too small
> for you to feel can damage one so that it works today and fails next
> month. Strap on and grounded before a chip leaves its tube — the full
> routine is in [[Anti-Static Habits]], and the $1\ \text{M}\Omega$
> resistor built into the strap cord is what makes wearing it safe.
> **Check orientation twice before power.** On these 14-pin packages
> pin 14 is $V_{CC}$ and pin 7 is ground; a supply connected backwards
> destroys the chip in under a second and it gets hot enough to burn
> you first. Notch to the left, pin 1 bottom-left. **Supply at
> $5\ \text{V}$, current limit low.** The 74HC family runs from $2$ to
> $6\ \text{V}$; nothing above that, ever. **Power off before you
> rewire.** **No floating inputs** — an unconnected CMOS input is not
> "off", it drifts, oscillates, and heats the chip.

## What you need

- [ ] Four 14-pin logic ICs, part numbers masked, from the 74HC family
- [ ] Breadboard, jumper wires, $5\ \text{V}$ bench supply
- [ ] Four $100\ \text{nF}$ ceramic capacitors, one per chip
- [ ] Two switches with $10\ \text{k}\Omega$ pull-down resistors
- [ ] One LED and one $1\ \text{k}\Omega$ resistor for the output
- [ ] Multimeter, anti-static strap, and your journal

## Predict before you measure

1. **Predict the input voltages your switch circuit will actually
   produce.** With a $10\ \text{k}\Omega$ pull-down to ground and the
   switch connecting to $5\ \text{V}$, an open switch should read very
   near $0\ \text{V}$ and a closed one very near $5\ \text{V}$. Measure
   both before any chip is involved. If they are not what you predicted,
   fix that before going further — every result after this depends on it.
2. **Predict the thresholds.** For 74HC parts running at $5\ \text{V}$,
   an input is guaranteed to be read as high above about
   $3.15\ \text{V}$ and as low below about $1.35\ \text{V}$. Between
   those two figures the manufacturer promises nothing. Write both
   numbers at the top of your results page.
3. **Predict the output current.** With a $1\ \text{k}\Omega$ resistor
   and an LED dropping about $2\ \text{V}$, a high output drives roughly
   $3\ \text{V} / 1000\ \Omega = 3\ \text{mA}$ — well inside what these
   outputs are rated to supply. Check that claim in the datasheet once
   the chip is identified.

## The work

4. Fit a $100\ \text{nF}$ capacitor directly across each chip's
   $V_{CC}$ and ground pins, as close to the package as the breadboard
   allows. It is not optional and it is not decoration; without it,
   gates switching produce supply spikes that make neighbouring gates
   misbehave.
5. Tie **every unused input** on the package to ground or to
   $5\ \text{V}$. Leave nothing floating, including the three gates you
   are not using.
6. Wire your two switches to the two inputs of one gate, and the output
   to the LED and resistor.
7. Step through all four input combinations. For each one, **measure the
   output with the meter** and record the voltage, then say whether that
   voltage is a guaranteed high, a guaranteed low, or in the forbidden
   middle.
8. Repeat for all four chips. Then, and only then, remove the tape, look
   up each part number in its datasheet, and check your table against
   the manufacturer's.

## Results

Fill one of these for each chip.

| Input A | Input B | Output (V) | Logic level | Notes |
| --- | --- | --- | --- | --- |
| 0 V | 0 V | | | |
| 0 V | 5 V | | | |
| 5 V | 0 V | | | |
| 5 V | 5 V | | | |

| Chip | Your deduced function | Actual part number | Match? |
| --- | --- | --- | --- |
| A | | | |
| B | | | |
| C | | | |
| D | | | |

## Predicted against measured

Your output highs will not be exactly $5\ \text{V}$ and your lows will
not be exactly $0\ \text{V}$. That is expected: an output transistor has
resistance, so it drops a little voltage while it supplies current to
your LED. Record how far off each one was, then find the datasheet's
$V_{OH}$ and $V_{OL}$ figures and check whether your chip is inside
specification. A part that is out of specification is either damaged or
being loaded harder than it is rated for — and both of those are
findings worth writing down.

If any output sat in the forbidden middle, something is wrong at the
input: a floating pin, a missing pull-down, or a switch that is not
making contact. Track it down. A logic circuit with an ambiguous level in
it does not have a bug, it has a coin flip.

## The question that matters

One of your four chips can, all by itself, be wired to imitate any of the
other three. Work out which one, and prove it at the bench by building an
inverter out of it. Then answer the harder version: why would a
manufacturer bother making the other three at all, if one of them is
enough?

%%curriculum-start%%
## Curriculum connection

![[A5.3]]

![[B1.2]]

![[B3.2]]
%%curriculum-end%%
