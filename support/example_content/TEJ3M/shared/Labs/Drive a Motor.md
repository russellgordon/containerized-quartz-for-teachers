---
title: Drive a Motor
publish: true
created: __CREATED__
tags:
  - labs
enableToc: true
---
Everything you have driven so far has been an LED, and an LED is polite:
it takes a few milliamps, it never changes its mind, and it stores no
energy. A motor is none of those things. It draws far more current than a
pin can supply, it draws several times *that* at the instant it starts or
stalls, and when you switch it off the collapsing magnetic field in its
winding tries to keep the current flowing by producing whatever voltage
it takes.

That last sentence is why this lab has a diode in it, and why a circuit
without one destroys its switching transistor — sometimes on the first
switch-off, sometimes on the thousandth.

> [!danger] Safety notes
> **The motor gets its own supply.** Never a motor on a microcontroller
> pin, and never a motor on the same rail as the logic — starting
> current will drag the rail down and reset the board mid-operation.
> Tie the two grounds together and only the grounds. **A flyback diode
> goes across the motor terminals, cathode to the positive side.**
> Backwards, it is a short circuit across your supply. Rate it for at
> least the motor's supply voltage and its stall current. **Clamp or
> bolt the motor down before it turns** — an unsecured motor with
> anything on its shaft walks off a bench and takes wires with it.
> **Hair tied back, sleeves and leads clear of the shaft**, glasses on.
> **Stall the motor only in short bursts** of a second or two: at stall
> all of that current becomes heat in the winding, and a stalled motor
> cooks itself in well under a minute. **Do not spin the motor by hand
> while it is connected** — turned by hand it is a generator, and it
> will push current back into your circuit. Everything in
> [[Safety in the Lab]] still applies on top of this.

## What you need

- [ ] Small brushed DC motor, and a bench supply separate from the board
- [ ] Logic-level N-channel MOSFET, plus a $220\ \Omega$ gate resistor
      and a $10\ \text{k}\Omega$ gate-to-ground pull-down
- [ ] A flyback diode — a 1N4001 or a 1N5819 Schottky suits a small
      motor at these voltages; check both its voltage and current
      ratings against your motor
- [ ] Microcontroller board, breadboard, jumper wires
- [ ] Multimeter, clamp or bracket for the motor, safety glasses

## Predict before you build

1. **Measure the motor's winding resistance** with the ohmmeter, motor
   disconnected. Turn the shaft a little between readings and take
   several — the brushes make contact differently at different angles,
   so record the range, not one number.
2. **Predict the stall current.** A spinning motor generates a voltage
   that opposes the supply, which is why running current is modest. At
   stall it generates nothing, so the only thing limiting current is the
   winding resistance itself: $I = V / R$. If you measured
   $5.0\ \Omega$ and your supply is $6\ \text{V}$, predict
   $6 / 5.0 = 1.2\ \text{A}$. Write it down before you go near the
   bench supply.
3. **Predict the running current**, from the motor's specification if
   you have one, or as a fraction of stall if you do not — and say what
   fraction you guessed and why.
4. **Check your switch against the prediction.** Find the MOSFET's
   continuous drain current rating and its on-resistance in the
   datasheet. Its dissipation while conducting is $P = I^2 R_{DS(on)}$;
   work that out at your predicted stall current and decide whether it
   needs a heatsink. Do this *before* you build, not after it gets hot.

## The work

5. Build with everything unpowered. Motor positive to the motor supply
   positive; motor negative to the MOSFET drain; MOSFET source to
   ground; gate to the board's pin through the $220\ \Omega$ resistor,
   with the $10\ \text{k}\Omega$ pull-down from gate to ground so the
   motor stays off while the board boots.
6. Fit the flyback diode across the motor terminals, **cathode — the
   banded end — to the positive side**. Have somebody else check it
   before power. This is the single component that most often goes in
   backwards and it fails loudly.
7. Tie the motor supply's ground to the board's ground. Nothing else
   crosses between them.
8. Power the motor supply *only*, with no gate drive, and confirm the
   motor does not turn. If it does, your pull-down is missing.
9. Power the board, drive the gate high, and measure the running current
   with the meter in series on the motor supply line.
10. **Stall test, briefly.** Hold the shaft with a tool — not fingers —
    for no more than two seconds and read the current. Release, and let
    the motor cool.
11. Add speed control and see what changes:

```python
from machine import Pin, PWM

MOTOR_PIN = 16          # your board's pinout is the only authority

motor = PWM(Pin(MOTOR_PIN))
motor.freq(1000)
motor.duty_u16(32768)   # roughly half of full scale
```

12. Sweep the duty cycle from low to high and find the value at which
    the motor first turns reliably from rest. Record it.

## Results

| Measurement | Predicted | Measured |
| --- | --- | --- |
| Winding resistance, range (Ω) | | |
| Stall current (A) | | |
| Running current, no load (A) | | |
| Ratio of stall to running | | |
| Supply voltage under running load (V) | | |
| Supply voltage at the instant of stall (V) | | |
| Lowest duty cycle that starts the motor | | |

## Predicted against measured

Your measured stall current will usually come out somewhat *below*
$V/R$, and the reason is in the last two rows of your table: under a
one-amp load the supply's own output sags, and the leads, the meter, and
the MOSFET each drop a little voltage too. So the motor never actually
sees the full supply voltage at stall. Add up those drops and see whether
they account for the gap.

If your measured stall current is far below prediction, check whether the
supply's current limit tripped — that is not the motor's answer, it is
the supply's.

Note the duty cycle needed to start from rest against the duty cycle that
keeps it turning once moving. They are not the same number, and the
difference is a real property of motors that anybody writing motor
control code has to design around.

## The question that matters

Take the flyback diode out — with the power off — and predict, in
writing, what will happen at the moment of switch-off and why. Then
reason through what that voltage does to the MOSFET, and decide whether
you actually want to try it. (Your teacher may demonstrate it once, on a
transistor already destined for the bin, with a scope on the drain. It is
worth seeing exactly once.)

Then the design question: your circuit can turn the motor one way. What
would have to change to make it turn both ways, and why can that not be
done by swapping a single wire in software?

%%curriculum-start%%
## Curriculum connection

![[A3.2]]

![[B5.3]]

![[D1.1]]
%%curriculum-end%%
