---
title: Reading Sensors
publish: true
created: __CREATED__
tags:
  - code
enableToc: true
---
A button gives you one bit. A light sensor gives you a number that
wanders, drifts with the time of day, and never once repeats exactly.
Both are honest reports of the world. The second kind just requires you
to decide what the number *means* before your program can act on it —
which is the difference between reading a sensor and merely printing one.

## Getting a number out of a voltage

```python
from machine import ADC, Pin
import time

SENSOR_PIN = 26         # an ADC-capable pin on this board; check the pinout
REFERENCE_V = 3.3
FULL_SCALE = 65535

sensor = ADC(Pin(SENSOR_PIN))

while True:
    raw = sensor.read_u16()
    volts = raw * REFERENCE_V / FULL_SCALE
    print(raw, round(volts, 3))
    time.sleep_ms(200)
```

Only some pins can do this. An analog-to-digital converter is a specific
piece of hardware inside the chip, wired to a specific set of pins, and
asking any other pin for an analog reading gets you an error or nonsense.
Your board's pinout says which — [[Reading a Datasheet]] is how to find
out.

`read_u16()` reports the reading rescaled into the range 0 to 65535,
whatever the underlying converter's real resolution is. That is a
convenience and also a small lie: if the hardware is 12-bit, you have
4096 genuinely different values spread across a 16-bit range, spaced
about 16 apart. Rescaling invents no precision. The theory is in
[[Digital and Analog Signals]]; the practical rule is to never print more
decimal places than the hardware can justify.

Most sensors are not voltage sources at all — a light-dependent resistor
and a thermistor are *resistances*, and a resistance is not something a
pin can read. Put the sensor in series with a fixed resistor across the
supply and read the point between them. That divider is doing the
conversion, and its arithmetic is in [[Series and Parallel Circuits]].

> [!danger] Never exceed the input range
> A voltage above the chip's supply on an analog pin does not produce a
> larger number. It damages the pin, sometimes immediately and sometimes
> slowly enough that you blame your code for a week. Anything that can
> swing higher than the reference gets divided down first, and gets
> checked with a meter before it gets connected.

## Making the reading trustworthy

Raw readings jitter. Some of that is real — the world genuinely changes
— and some is noise in the converter and on your wiring. Averaging
several samples costs nothing and steadies the number considerably.

```python
def averaged_reading(adc, samples):
    total = 0
    for sample_number in range(samples):
        total = total + adc.read_u16()
        time.sleep_ms(2)
    return total // samples
```

Averaging trades response speed for steadiness, which is the correct
trade for a temperature and the wrong one for a switch. Choose the number
of samples deliberately and write down why.

Then calibrate. A raw number means nothing until you have written down
what it reads under two known conditions — bright room and covered
sensor, ice water and boiling water, potentiometer fully clockwise and
fully anticlockwise. With two known points you can map the raw reading
onto a real quantity:

```python
def scaled(raw, raw_low, raw_high, value_low, value_high):
    span_raw = raw_high - raw_low
    span_value = value_high - value_low
    return value_low + (raw - raw_low) * span_value / span_raw
```

Record the calibration points and the date in your [[Tech Journal]]. A
sensor recalibrates itself when nobody is watching — a new board, a
different supply, a resistor swapped for the nearest value in the drawer,
and last week's numbers are fiction.

## Turning a number into a decision

The naive way to switch something at a threshold produces chattering: as
the reading wobbles across the boundary, the output flips repeatedly. The
fix is **hysteresis** — two thresholds instead of one, with a gap between
them.

```python
DARK_ENOUGH = 20000        # below this, it is dark: turn the lamp on
LIGHT_ENOUGH = 26000       # above this, it is light: turn the lamp off

lamp_on = False

while True:
    raw = averaged_reading(sensor, 8)

    if lamp_on == False and raw < DARK_ENOUGH:
        lamp_on = True
        lamp.on()
    elif lamp_on == True and raw > LIGHT_ENOUGH:
        lamp_on = False
        lamp.off()

    time.sleep_ms(100)
```

Once the lamp is on, it takes a decisively brighter reading to turn it
off again, so a reading hovering at 20 001 cannot make it stutter. Every
thermostat in the world works this way, and the size of the gap is a real
design decision: too small and it chatters, too large and it responds
late.

Notice too that the program remembers its own state in `lamp_on` rather
than asking the hardware. That is deliberate — a program that keeps
track of what it has decided is far easier to reason about than one that
re-derives it every pass, and it is the seed of the structure in
[[Structuring Embedded Code]].

## Make it yours

1. Print raw and volts side by side while you cover and uncover the
   sensor. Record the extremes; those are your calibration points.
2. Compare a single reading against an average of sixteen, printed
   together. How much steadier is the average, and how much slower to
   react?
3. Build the lamp threshold above with your own numbers, then
   deliberately set both thresholds equal and watch it chatter. Seeing
   the failure is the point.
4. Add a second sensor of a different kind — a potentiometer alongside
   the light sensor — and use it to adjust the threshold live, so the
   device can be tuned without editing code.

You now have a board that can sense. [[Driving Outputs Safely]] gives it
something to do about it.

%%curriculum-start%%
## Curriculum connection

![[A3.2]]

![[B5.2]]

![[B5.3]]
%%curriculum-end%%
