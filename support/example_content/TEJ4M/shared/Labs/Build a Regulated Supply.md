---
title: Build a Regulated Supply
draft: false
created: __CREATED__
tags:
  - labs
enableToc: true
---
Every project this semester needs a rail that holds still. Today you
build one from an AC adapter, a bridge rectifier, a reservoir capacitor,
and a linear regulator — and you calculate, before anything is
connected, exactly how much heat the regulator will have to get rid of.
That number is the whole lab. Almost every regulated supply that fails
in service fails because somebody skipped it.

The mains stays inside the sealed adapter, where it belongs. Everything
you touch is low-voltage AC and DC, and you still treat it with respect,
because a reversed electrolytic capacitor does not care how low the
voltage was.

> [!danger] Safety notes
> **The AC adapter stays sealed and intact.** Inspect the cord for
> damage before you plug it in; a cracked moulding means it goes back
> to the teacher, not onto your bench. **Electrolytic capacitor
> polarity, checked twice before power** — the marked stripe is the
> negative lead. Reversed, an electrolytic heats internally and can
> vent violently: glasses on, and have your neighbour confirm the
> polarity before you energise. **The capacitor's voltage rating must
> exceed the *peak* input, not the RMS figure** printed on the
> adapter, with margin on top of that. **Discharge before you rewire**:
> a $1\ \text{k}\Omega$ resistor across the reservoir capacitor for a
> few seconds, then confirm with the meter. **Rewire only with the
> adapter unplugged.** **The regulator tab is not automatically
> ground** — on many parts it is connected to a pin, and on some it is
> the output. Read the datasheet before you bolt anything to a shared
> heatsink, and insulate if in doubt. **The regulator and the load
> resistor will reach temperatures that burn**: read them with the
> infrared thermometer, not a fingertip. **Scope ground clip goes to
> circuit ground and nowhere else** — that clip is connected to the
> building's earth through the scope, so putting it on any other node
> creates a short through the instrument.

## What you need

- [ ] A $12\ \text{V}$ AC adapter, sealed, low current rating
- [ ] Bridge rectifier module or four rectifier diodes
- [ ] $1000\ \mu\text{F}$ reservoir capacitor, rated at least
      $35\ \text{V}$
- [ ] A fixed $5\ \text{V}$ linear regulator in a TO-220 package, plus
      its datasheet and a bolt-on heatsink
- [ ] Small ceramic capacitors for the regulator's input and output, as
      that regulator's datasheet specifies
- [ ] Load resistor: $22\ \Omega$, rated $5\ \text{W}$
- [ ] Multimeter, oscilloscope, infrared thermometer, a
      $1\ \text{k}\Omega$ bleed resistor, safety glasses

## Predict before you build

1. **Peak, not RMS.** A $12\ \text{V}$ AC adapter delivers
   $12\ \text{V}$ RMS, and the capacitor charges towards the peak:
   $V_{peak} = 12\ \text{V} \times \sqrt{2} \approx 17.0\ \text{V}$.
   Two diodes conduct in series in a bridge on each half cycle, so
   subtract about $1.4\ \text{V}$: roughly $15.6\ \text{V}$ DC at the
   top of the ripple. Now re-read the capacitor rating you were about
   to use.
2. **Predict the ripple.** Between peaks the load empties the capacitor
   at a rate set by $I = C \, \Delta V / \Delta t$. A full-wave
   rectifier on a $60\ \text{Hz}$ supply recharges twice per cycle, so
   $\Delta t \approx 1/120\ \text{s} = 8.33\ \text{ms}$, and with a
   $22\ \Omega$ load drawing $5/22 = 0.227\ \text{A}$ the ripple is
   $\Delta V = I \Delta t / C$, which is
   $0.227 \times 0.00833 / 0.001 \approx 1.89\ \text{V}$.
3. **Check the regulator still has headroom.** The trough of the ripple
   sits at about $15.6 - 1.9 = 13.7\ \text{V}$, comfortably above the
   $5\ \text{V}$ output plus the dropout voltage your datasheet quotes.
   Write down both numbers.
4. **Predict the dissipation — the number this lab exists for.** A
   linear regulator throws away the difference between its input and
   its output as heat, at the full load current. Using the average
   input of about $14.7\ \text{V}$, the regulator dissipates
   $P = (V_{in} - V_{out}) I_{out}$, which is
   $(14.7 - 5) \times 0.227 \approx 2.20\ \text{W}$.
5. **Turn watts into degrees.** Find the junction-to-ambient thermal
   resistance in your regulator's datasheet — for a bare TO-220 in
   still air it is often around $60\ ^\circ\text{C/W}$, but your part's
   datasheet is the only authority. At that figure,
   $2.20\ \text{W} \times 60\ ^\circ\text{C/W}$ is a rise of about
   $132\ ^\circ\text{C}$ above ambient, which is past the maximum
   junction temperature of most such parts before the room is even
   warm. Predict, in writing, what will actually happen when you power
   it without a heatsink.
6. **Size the heatsink.** To hold the junction $60\ ^\circ\text{C}$
   above a $40\ ^\circ\text{C}$ room at $2.20\ \text{W}$ you need
   $60 / 2.20 \approx 27\ ^\circ\text{C/W}$ or better, all the way from
   junction to air. Compare that with the heatsink on your bench.

## The work

7. Build with the adapter unplugged: adapter to bridge, bridge output
   to the reservoir capacitor (polarity checked twice), capacitor to
   the regulator input, the datasheet's ceramic capacitors close to the
   regulator's pins, load across the output.
8. Power up with **no heatsink and no load** first. Measure the DC
   input voltage and the output voltage.
9. Add the load. Measure the output again, then the input, then the
   current through the load.
10. **Scope the input, AC coupled**, across the reservoir capacitor.
    Measure the ripple peak-to-peak and its frequency. The frequency
    tells you whether your bridge is doing full-wave rectification.
11. **Scope the output, AC coupled**, at maximum vertical sensitivity.
    A good regulator rejects most of that ripple, so expect a few
    millivolts rather than volts. Record what you actually see.
12. Read the regulator's case temperature every $30\ \text{s}$ for two
    minutes with the infrared thermometer. Stop and power down if it
    reaches the temperature its datasheet calls a limit, or if the
    output starts collapsing and recovering — that is thermal shutdown,
    and it is the part saving itself from you.
13. Power down, discharge, fit the heatsink, and repeat step 12.

## Results

| Measurement | Predicted | Measured |
| --- | --- | --- |
| Peak DC at the capacitor, no load (V) | 17.0 less diode drops | |
| DC input under load (V) | ≈ 14.7 average | |
| Ripple at the input, peak-to-peak (V) | 1.89 | |
| Ripple frequency (Hz) | 120 | |
| Output voltage, no load (V) | 5.00 | |
| Output voltage, full load (V) | 5.00 | |
| Load current (A) | 0.227 | |
| Ripple at the output, peak-to-peak (mV) | | |
| Regulator dissipation (W) | 2.20 | |
| Case temperature at 2 min, no heatsink (°C) | | |
| Case temperature at 2 min, with heatsink (°C) | | |

Load regulation is worth computing from two of those rows:
$(V_{no\ load} - V_{full\ load}) / V_{full\ load} \times 100\%$. A good
linear regulator gives a fraction of one percent.

## Predicted against measured

Your measured input will usually sit *below* the predicted peak, and
there are three honest reasons: an adapter labelled $12\ \text{V}$ is
specified at its rated load and reads higher unloaded, the transformer
inside it has real winding resistance that sags under current, and the
diode drops are not exactly $0.7\ \text{V}$ each — they rise with
current, and the datasheet's forward-voltage curve will show you by how
much.

If your ripple came out larger than predicted, check the capacitance you
actually have: electrolytic tolerances are wide, often $-20\%$ or worse,
and they get worse with age. If it came out much smaller, check your
load current — a resistor that measured $24\ \Omega$ instead of
$22\ \Omega$ changes everything downstream.

The row that should bother you most is the temperature one. Compare what
you predicted from the thermal resistance against what you measured, and
remember that the case is cooler than the junction inside it.

## The question that matters

You just built a supply that converts about $2.2\ \text{W}$ into heat in
order to deliver about $1.1\ \text{W}$ to a load. Explain to somebody
where that energy goes and why a linear regulator has no choice about
it. Then answer: what happens to both numbers if you feed the same
regulator from a $9\ \text{V}$ adapter instead, and what do you lose?

Then the design-margin question. Name one change for each of these, with
the number that justifies it:

- It has to work in a sealed enclosure on a $35\ ^\circ\text{C}$ day.
- Somebody will eventually connect the input backwards.
- It has to run for a year without anybody opening the box.

The habits behind those answers are in [[Reliability and Derating]], and
the arithmetic gets drilled in [[Power and Regulation Practice]].

%%curriculum-start%%
## Curriculum connection

![[A3.3]]

![[B3.2]]

![[D1.2]]
%%curriculum-end%%
