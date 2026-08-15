---
title: Talk on a Bus
publish: true
created: __CREATED__
tags:
  - labs
enableToc: true
---
Two wires, several devices, and a set of rules about who is allowed to
pull which line low and when. A serial bus is the most economical idea
in interfacing and the most unforgiving: it works perfectly until you
add one more device or one more centimetre of wire, and then it stops,
and the code has not changed.

Today you build a bus, predict its rise times in microseconds, and then
watch the oscilloscope show you exactly the shape you calculated. By the
end you will be able to look at a rounded edge and name the resistor
that caused it.

> [!danger] Safety notes
> **Check the logic levels before you connect two devices.** A
> $5\ \text{V}$ device on a $3.3\ \text{V}$ bus can drive a pin above
> its absolute maximum and destroy it, and on an open-drain bus the
> pull-up voltage is what matters — read both datasheets and use a
> level translator if they disagree. **Never fit two pull-up sets to
> one bus**: the resistors end up in parallel and the effective value
> is smaller than either, which changes everything you are about to
> measure. **Set the supply's current limit before connecting**, and
> **rewire only with power off.** **Scope ground clip to circuit
> ground only**, and keep the ground lead short — a long ground lead on
> a scope probe adds ringing that is not in your circuit and will send
> you chasing a fault you invented. **Do not probe a powered board
> with loose leads**; clip on with power off.

## What you need

- [ ] Microcontroller board with a serial bus peripheral, and its
      datasheet
- [ ] Two bus devices with different addresses — a sensor and a display
      suit well — and both datasheets
- [ ] Pull-up resistors: a pair each of $10\ \text{k}\Omega$,
      $4.7\ \text{k}\Omega$, and $2.2\ \text{k}\Omega$
- [ ] Breadboard, jumper wires of two lengths, and a longer cable to
      extend the bus
- [ ] Oscilloscope with two channels, logic analyzer, multimeter

## Predict before you build

1. **Predict the idle state.** On an open-drain bus, no device ever
   drives the line high — the pull-up resistors do. Predict what your
   meter will read on each line with the supply on and no traffic, and
   predict what happens to that reading if a pull-up is missing.
2. **Predict the sink current.** When a device pulls the line low it
   must swallow whatever the pull-up delivers:
   $I = V_{DD} / R$. With $3.3\ \text{V}$ and $2.2\ \text{k}\Omega$
   that is $1.5\ \text{mA}$, comfortably inside the $3\ \text{mA}$ that
   the bus specification requires a device to sink. Compute it for all
   three resistor values you have.
3. **Predict the rise time — the number this lab is built around.**
   The line rises as an RC curve, with $R$ the pull-up and $C$ the
   total capacitance of every device, every track, and every
   centimetre of wire. Measured between $30\%$ and $70\%$ of the
   supply, the rise takes
   $t_r = R C \ln(0.7/0.3) \approx 0.847 R C$. For
   $R = 4.7\ \text{k}\Omega$ and a bus capacitance of $100\ \text{pF}$,
   that is $0.847 \times 4700 \times 100 \times 10^{-12} \approx
   0.40\ \mu\text{s}$.
4. **Predict what happens at the specification's limit.** Standard-mode
   buses allow up to $400\ \text{pF}$ of bus capacitance and no more
   than $1\ \mu\text{s}$ of rise time. Work out the rise time for
   $4.7\ \text{k}\Omega$ at $400\ \text{pF}$:
   $0.847 \times 4700 \times 400 \times 10^{-12} \approx
   1.6\ \mu\text{s}$ — over the limit. Then find the pull-up value that
   brings it back under, and check its sink current against step 2.
5. **Predict the collision.** Look up both devices' addresses in their
   datasheets. Predict what will happen if two devices on one bus share
   an address, and how you would detect it from a scan.

## The work

6. Build with the short jumpers and $4.7\ \text{k}\Omega$ pull-ups,
   power off. Both devices' data lines together, both clock lines
   together, one common ground, pull-ups to the correct supply rail.
7. Power up and measure both lines at idle with the meter.
8. **Scan the bus** and record which addresses answer. An address that
   does not appear is a wiring fault, a missing pull-up, or a device
   that needs a moment after power-up — check its datasheet before you
   assume the wiring.
9. Read one value from each device and print it. Do not move on until
   both work.
10. **Scope both lines at once**, clock on one channel and data on the
    other, triggered on the falling edge that starts a transaction.
    Measure the rise time of the clock line between $30\%$ and $70\%$.
11. **Swap the pull-ups** to $10\ \text{k}\Omega$, then
    $2.2\ \text{k}\Omega$, measuring the rise time each time. Three
    values, three rise times, one straight line when you plot them
    against resistance.
12. **Extend the bus.** Replace the short jumpers with the long cable
    and measure the rise time again at each pull-up value. You have
    just added capacitance; the plot will tell you how much.
13. **Find the breaking point.** Raise the bus speed, or lengthen the
    cable, until transactions start failing. Record the rise time at
    the last setting that worked and at the first one that did not.
14. **Decode it properly.** Put the logic analyzer on the same two
    lines and capture one transaction. Record the address, the
    read/write bit, the acknowledgement, and the data bytes — and check
    them against what the datasheet said should happen.

## Results

| Measurement | Predicted | Measured |
| --- | --- | --- |
| Idle voltage on each line (V) | | |
| Sink current, 10 kΩ pull-up (mA) | 0.33 | |
| Sink current, 4.7 kΩ pull-up (mA) | 0.70 | |
| Sink current, 2.2 kΩ pull-up (mA) | 1.50 | |
| Rise time, 10 kΩ, short bus (µs) | | |
| Rise time, 4.7 kΩ, short bus (µs) | 0.40 | |
| Rise time, 2.2 kΩ, short bus (µs) | | |
| Rise time, 4.7 kΩ, long cable (µs) | | |
| Bus capacitance implied by your times (pF) | | |
| Rise time at the last speed that worked (µs) | | |
| Addresses that answered the scan | | |

The bus capacitance row is the interesting one: you cannot measure it
directly, but you can compute it from your own rise time and pull-up
value by rearranging step 3, $C = t_r / (0.847 R)$. Do that for all
three resistors and see whether you get the same capacitance three
times. If you do, your model is sound.

## Predicted against measured

Rise times measured on a scope with a long ground lead read slower and
ring more than the real signal. If your three computed capacitances
disagree wildly, suspect the probe before you suspect the physics —
swap to the spring-tip ground or shorten the lead and repeat one
measurement.

Expect the long cable to add somewhere in the tens of picofarads per
metre. If your implied capacitance jumped by far more than that, look
for a cable with a shield connected at one end, or two conductors
running as a tight pair.

Where a transaction failed, name what failed: a rise time so slow that
the line had not reached a valid high before the clock edge arrived, or
a device that never acknowledged. The logic analyzer capture settles
that argument in seconds, which is exactly what it is for.

## The question that matters

You changed one resistor and a working bus stopped working, without
touching a line of code. Explain that to a programmer, in terms they
would accept, and then explain why the fix is a resistor rather than a
delay in software.

Then the design-margin questions:

- Your capstone will put this bus on a cable a metre long, inside a
  case, beside a switching supply. What pull-up value would you specify
  and what evidence would you bring to the design review?
- A hot enclosure raises every device's leakage current. What does that
  do to a bus held high only by a resistor?
- Somebody adds a fourth device to your bus next year. What in your
  design tells them whether that is safe, and where would you write it
  down so they find it?

That last question is the whole point of
[[Writing Documentation Somebody Can Build From]].

%%curriculum-start%%
## Curriculum connection

![[A2.4]]

![[B1.2]]

![[B1.3]]
%%curriculum-end%%
