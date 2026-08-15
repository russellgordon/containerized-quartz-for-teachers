---
title: Operational Amplifiers
publish: true
created: __CREATED__
tags:
  - concepts
enableToc: true
---
The thermocouple in [[Amplify a Sensor]] produces tens of microvolts per
degree. Wired straight to a 10-bit converter on a 3.3 V reference, one
step of the converter is about 3.2 mV — so the entire useful range of the
sensor disappears inside a single count. The sensor is not too weak. The
signal chain is missing a stage, and that stage is an operational
amplifier.

## Two rules explain nearly every op-amp circuit

An op-amp is a differential amplifier with enormous open-loop gain. On
its own that gain is useless — anything at the input slams the output to
a rail. Wrapped in negative feedback it becomes precise, and two rules
follow that let you analyse the standard circuits on sight:

1. **The inputs draw essentially no current.** Input bias currents are
   tiny compared with anything in your divider network.
2. **The output does whatever it must so that the two inputs are at the
   same voltage** — provided the feedback is negative and the output is
   not asking for more than the supply can give.

Every circuit below is those two rules plus Ohm's law.

## Non-inverting: gain without loading the source

Feed the signal to the + input and the divider to the − input:

$$G = 1 + \frac{R_f}{R_g}$$

With $R_f = 100\ \text{k}\Omega$ and $R_g = 10\ \text{k}\Omega$ the gain
is $1 + 10 = 11$, so a 0.2 V input produces 2.2 V out. The source sees
only the op-amp's input, which draws almost nothing — that is the reason
to choose this configuration for a sensor whose output would sag if you
loaded it.

Now design rather than analyse. The thermocouple front end must turn a
0 – 20 mV span into the converter's 0 – 3.3 V span, so

$$G_{\text{required}} = \frac{3.3\ \text{V}}{0.020\ \text{V}} = 165$$

Take $R_g = 1\ \text{k}\Omega$; then
$R_f = (165 - 1) \times 1\ \text{k}\Omega = 164\ \text{k}\Omega$, which
you cannot buy in the 5% series. Fit 160 kΩ, giving $G = 161$ and a
full-scale output of
$0.020\ \text{V} \times 161 = 3.22\ \text{V}$ — inside the range, with a
sliver of headroom, and the gain error corrected in software by
calibration rather than by pretending. Record the real gain in your
[[Tech Journal]]; the number you calibrate against must be the one you
built.

## Inverting: gain with a sign, and a virtual earth

Feed the signal through $R_{\text{in}}$ to the − input and ground the +
input:

$$G = -\frac{R_f}{R_{\text{in}}}$$

With $R_f = 220\ \text{k}\Omega$ and $R_{\text{in}} = 22\ \text{k}\Omega$
the gain is $-10$, so 0.15 V in gives $-1.5$ V out. The − input sits at a
**virtual earth** — held at ground potential by the feedback, without
being connected to ground — which is why the source now sees a load of
exactly $R_{\text{in}}$.

> [!warning] Minus 1.5 volts, on a single supply, is zero
> Run that circuit from a single 0 – 5 V supply and it cannot produce
> $-1.5$ V. There is no negative rail for the output to reach toward, so
> the output pins itself just above ground and your beautiful gain
> calculation describes nothing. The measurement looks like a dead
> sensor.
>
> An op-amp's output can only swing between its own supply rails, and
> most parts cannot even reach them: a common single-supply device may be
> specified to get within a volt or so of each rail, so on a 5 V supply
> the honest output range might be about 1.5 V to 3.5 V. **Rail-to-rail**
> output parts are the category that swings much closer — check the
> output voltage swing line of the datasheet, at the load you will
> actually drive, before you design around it.
>
> If you genuinely need to amplify a signal that goes negative, you need
> either a split supply or a deliberately biased mid-rail reference, so
> that "zero" in your circuit sits in the middle of the range instead of
> at the bottom of it.

## Bandwidth is not free

The gain you take, you take from a fixed budget. For a typical
voltage-feedback op-amp the product of closed-loop gain and bandwidth is
roughly constant, so a part with a 1 MHz gain–bandwidth product gives

$$f_{-3\text{dB}} = \frac{1\ \text{MHz}}{161} \approx 6.2\ \text{kHz}$$

at the gain of 161 above — ample for temperature, hopeless for audio.
Design the gain, then check that the remaining bandwidth still covers the
signal you care about. Two stages of gain 13 each get you a similar total
gain with far more bandwidth, which is one honest reason to cascade.

Op-amps also add their own errors: input offset voltage is amplified
along with your signal (an offset of 2 mV at a gain of 161 becomes
0.32 V of error at the output), and the finite slew rate limits how fast
a large output can move regardless of bandwidth. None of this is a reason
to be frightened of the part. It is the reason your amplifier stage gets
measured against a known input on a scope, not admired.

Work the gain arithmetic in [[Transistor and Op-Amp Practice]], build and
verify a stage in [[Amplify a Sensor]] with the techniques from
[[Using an Oscilloscope Properly]], and remember that the stage after
this one — the filter and the converter of
[[Filters and Noise]] and [[Sampling and Resolution]] — will faithfully
digitise every bit of noise you just amplified by 161.

%%curriculum-start%%
## Curriculum connection

![[A3.3]]

![[B3.2]]

![[B3.4]]
%%curriculum-end%%
