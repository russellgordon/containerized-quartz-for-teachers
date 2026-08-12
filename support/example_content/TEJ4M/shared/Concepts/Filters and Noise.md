---
title: Filters and Noise
draft: false
created: __CREATED__
tags:
  - concepts
enableToc: true
---
The temperature reading in [[Sample a Signal]] jumped by a degree and a
half between consecutive samples while the sensor sat untouched on the
bench. Nothing physical changed that fast. What you were watching was
==noise== — everything in the measurement that did not come from the
quantity you are measuring — and the moment a signal has been amplified
by 161 in [[Operational Amplifiers]], the noise has been amplified by 161
too.

## Know which noise you have before you filter it

Filtering blind is a waste of an afternoon. Put the signal on a scope,
as [[Read the Waveform]] trains you to, and identify it.

| What you see | Likely source | What actually fixes it |
| --- | --- | --- |
| A clean sine riding on the signal, at mains frequency | Coupling from mains wiring | Shielding, twisted pairs, a low cutoff, or averaging |
| Fast spikes timed with a motor or relay switching | Switching transients through shared supply or ground | Flyback diodes, decoupling, separate supply rails, star grounding |
| A steady buzz at tens or hundreds of kHz | A switching regulator | A linear regulator for the analog stage, or a filter |
| Fuzz with no pattern at all | Thermal and device noise, plus converter noise | Averaging, a slower measurement, a better front end |
| A step that appears when you touch the bench | A floating input or a bad ground | Fix the wiring; no filter will save this |

That last row matters more than the rest of the table. A filter is a
correction, not an excuse, and half the "noise" in student projects is a
wiring fault wearing a disguise.

## The RC low-pass, and its cutoff

One resistor into one capacitor to ground is the filter you will build
most often. Its ==cutoff frequency== — the frequency at which the output
has fallen to about 70% of the input, which is $-3$ dB — is

$$f_c = \frac{1}{2\pi RC}$$

Design it the other way round. To put the cutoff at 200 Hz using a
100 nF capacitor:

$$R = \frac{1}{2\pi f_c C} = \frac{1}{2\pi \times 200\ \text{Hz} \times 100\ \text{nF}} \approx 7958\ \Omega$$

so fit 8.2 kΩ, which lands the real cutoff at
$1/(2\pi \times 8200 \times 100\ \text{nF}) \approx 194\ \text{Hz}$.
Close enough — and you now know the actual number rather than the wished
one.

Be honest about how gently a single RC rolls off. It is one pole: the
response falls at about 20 dB per decade, so a frequency three times the
cutoff is attenuated only about 10 dB (to roughly a third), and you need
ten times the cutoff for 20 dB (a tenth). Worse, a signal *below* the
cutoff barely moves at all — 60 Hz mains hum through that 194 Hz filter
comes out at about 96% of its original size. If mains hum is your
problem, a filter with a 200 Hz cutoff is decoration. Either drop the
cutoff below the hum, and accept a slower response, or go and find why
the hum is coupling in.

## Choosing a cutoff you can defend

The cutoff is a trade between noise and speed, and both ends have a
number attached.

- **The fastest real change you must follow** sets the floor. A cutoff
  well below it removes the signal along with the noise.
- **The noise you are trying to remove** sets the ceiling.
- **The sampling rate of your converter** sets a hard requirement: an
  anti-alias filter must sit *before* the converter and cut off well
  below half the sampling rate, because once a frequency has been
  aliased no amount of software can tell it apart from a real one.
  [[Sampling and Resolution]] is where that bill comes due.

A related trade is where you do the work. An analog RC costs two parts
and no processor time. Averaging in software — sum sixteen samples and
divide — reduces random noise by $\sqrt{16} = 4$, costs no parts, and
takes sixteen sample times. Both are low-pass filters; only one of them
can stop an out-of-band frequency reaching the converter.

## Layout beats filtering

Some of the most effective noise work has no filter in it at all.

- **One ground reference, arranged deliberately.** Return currents from a
  motor must not share copper with a sensor's return. Bring the noisy
  and quiet returns to a single point rather than daisy-chaining them.
- **A decoupling capacitor at every supply pin**, physically close to the
  pin — typically 100 nF ceramic, plus a bulk capacitor for the board.
  This is not superstition; it supplies the fast current the chip demands
  before the supply wiring can react.
- **Short, twisted, or shielded runs for small signals**, and never
  routed parallel to a motor lead.
- **Amplify early.** A microvolt signal carried across a bench and then
  amplified has picked up interference the amplifier then multiplies. Put
  the gain stage at the sensor.

Do these first, then filter what is left. Prove the improvement with the
scope, and record the before-and-after traces in your [[Tech Journal]] —
a claim about noise with no waveform behind it is worth nothing at a
design review. [[Sampling and Resolution Practice]] carries the RC and
averaging arithmetic; [[Using an Oscilloscope Properly]] is how you see
what you are actually doing.

%%curriculum-start%%
## Curriculum connection

![[A3.3]]

![[B3.2]]

![[B3.4]]
%%curriculum-end%%
