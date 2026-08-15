---
title: Driving Outputs Safely
publish: true
created: __CREATED__
tags:
  - code
enableToc: true
---
The board in [[Drive a Motor]] that stopped responding halfway through
the period had not crashed. Its output pin had been asked to supply a
motor's current, and it did so once. This page is half software and half
electronics, because the boundary between them is exactly where boards
die.

## Know what a pin can actually deliver

A GPIO pin is a small switch, not a power supply. A typical
microcontroller pin is rated to source or sink a few tens of
milliamperes, and the chip as a whole has a further limit on the total
across all pins at once. Those two numbers are in the datasheet and
nowhere else — the value differs between families and sometimes between
pins on the same chip.

Set that against what real loads want:

| Load | Rough current | Verdict |
| --- | --- | --- |
| LED with a series resistor | 5 – 20 mA | Direct from a pin, fine |
| Piezo buzzer | Tens of mA | Usually fine, check the part |
| Small DC motor | Hundreds of mA running, more at stall | Needs a driver |
| Relay coil | Tens to hundreds of mA | Needs a driver, and a diode |
| Servo | Hundreds of mA, spikes higher | Own supply; only the signal comes from the pin |
| Solenoid, pump, lamp | Amperes | Needs a driver, a diode, and a real supply |

Everything below the LED line is a wiring exercise. Everything above it
needs three things between the pin and the load, and the correct number
of them is three, not two.

> [!danger] The three rules, and why each one exists
> **A transistor or driver carries the current, not the pin.** The pin
> switches the transistor's gate or base; the transistor switches the
> load. A logic-level MOSFET or a purpose-made driver chip does this
> job; a bipolar transistor needs a base resistor sized from its current
> gain.
>
> **A flyback diode goes across every inductive load** — motors, relay
> coils, solenoids. A coil opposes a change in its current, so switching
> it off produces a reverse spike that can be many times the supply
> voltage and will punch straight through a transistor. Fit the diode so
> it does *not* conduct in normal operation and does conduct that spike
> into a harmless loop.
>
> **The load gets its own supply, with a shared ground.** A motor
> starting drags its rail down hard. If that rail also feeds the
> microcontroller, the chip browns out mid-instruction and does not fail
> politely. Separate positive supplies, one common ground — without the
> shared ground the two halves have no agreed zero and the signal means
> nothing.

Safe wiring practice is not an add-on to this course; it is the standard
the trade works to, and the reasoning behind it is
[[Health and Safety in the Shop]].

## Controlling brightness and speed with PWM

Most pins cannot produce an arbitrary voltage. They switch fully on or
fully off, very quickly, and vary the fraction of each cycle spent on.
For a load that cannot follow the switching — an LED and your eye, a
motor and its own inertia — the effect is that of a steady voltage of
duty times supply.

```python
from machine import Pin, PWM
import time

DRIVE_PIN = 15         # drives the transistor gate; check your board's pinout
PWM_HZ = 1000
FULL_SCALE = 65535

drive = PWM(Pin(DRIVE_PIN))
drive.freq(PWM_HZ)


def set_power(percent):
    if percent < 0:
        percent = 0
    if percent > 100:
        percent = 100
    drive.duty_u16(int(percent * FULL_SCALE / 100))


set_power(0)           # start with the load off, always
```

Two habits are built into that snippet. The function **clamps its input**,
so a calculation that produces 140 % somewhere upstream cannot become a
hardware surprise. And it is called with 0 immediately, so the load is
definitely off before anything else runs.

That second habit matters more than it looks. Pins are not necessarily
outputs at reset, and a floating gate can leave a MOSFET partly on. A
pull-down resistor on the gate holds it off while the board boots, and
the code sets a known state as its first act. Between them, the load
cannot twitch during a reset — which is the sort of thing that is merely
annoying with an LED and dangerous with anything that moves.

Choosing the frequency is a real decision. Too low and you see an LED
flicker or hear a motor whine in the audible range; a few hundred hertz
to a few kilohertz suits most small motors, and above about 20 kHz the
whine leaves human hearing entirely at some cost in switching losses.

## Servos are different

A servo does not take a duty cycle as a speed. It expects a pulse roughly
every 20 ms, and the *width* of that pulse commands a position — around
1 ms at one end of travel, 2 ms at the other, and 1.5 ms at centre. The
servo then drives itself there and holds, resisting you if you push.

```python
SERVO_PIN = 16
SERVO_HZ = 50
PERIOD_MS = 20

servo = PWM(Pin(SERVO_PIN))
servo.freq(SERVO_HZ)


def set_pulse_ms(width_ms):
    duty = int(width_ms / PERIOD_MS * FULL_SCALE)
    servo.duty_u16(duty)


set_pulse_ms(1.5)      # centre
time.sleep_ms(500)
set_pulse_ms(1.0)      # one end of travel
```

Check the arithmetic once so the numbers stop being magic. At 50 Hz the
period is 20 ms, so a 1.5 ms pulse is
$\frac{1.5}{20} = 0.075$ of the cycle, and
$0.075 \times 65535 \approx 4915$. A 1.0 ms pulse comes out at about 3277
and a 2.0 ms pulse at about 6554.

Two cautions. The exact end-of-travel pulse widths vary between servos,
so find yours by careful experiment and stop before it strains against
its own stop — a servo held against its limit draws heavy current and
cooks. And a servo takes its power from the supply, not from your board:
only the signal wire goes to the pin, and the grounds are tied together.

## Make it yours

1. Ramp a load from 0 to 100 % over two seconds and back down, using the
   non-blocking timing pattern from [[Input, Output, and Timing]] rather
   than a chain of sleeps.
2. Measure the average voltage at the load with a meter at 25 %, 50 %
   and 75 % duty, and compare each with duty times supply. Then look at
   the same pin on a scope and explain to a partner why the two
   instruments disagree.
3. Add a limit to your motor code so that it refuses to jump from 0 to
   full power in one step. Say in a comment what damage the limit
   prevents.
4. Sketch the complete circuit — pin, gate resistor, transistor, load,
   flyback diode, both supplies, shared ground — as a proper schematic
   before you build it. [[Reading Schematics]] sets the standard, and
   this drawing goes in your submission for [[The Embedded Device]].

Something will still not work. [[Debugging Hardware and Software Together]]
is about finding out which half is lying.

%%curriculum-start%%
## Curriculum connection

![[A3.2]]

![[B3.1]]

![[B5.3]]

![[D1.1]]
%%curriculum-end%%
