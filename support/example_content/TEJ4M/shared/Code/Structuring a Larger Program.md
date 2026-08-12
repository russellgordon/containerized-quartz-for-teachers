---
title: Structuring a Larger Program
draft: false
created: __CREATED__
tags:
  - code
enableToc: true
---
By Unit 3 the working programs in this room pass three hundred lines, and
the ones that get finished are not the clever ones. They are the ones a
second person can open, find the part they need, change it, and put back
without breaking something at the other end of the file. Structure is
what makes that possible, and at this size it means more than tidy
functions — it means deciding what belongs in which file.

## Split the program into files that name responsibilities

One `main.py` holding everything is fine at fifty lines and unworkable at
three hundred. Split it so that each file has one reason to change.

```python
# config.py
# Bench exhaust controller — pin and tuning constants.
# R. Okafor, revision 4. Board: generic MicroPython board;
# confirm every pin against your own board's pinout.

from micropython import const

# --- Wiring ---------------------------------------------------------
SENSOR_PIN = const(26)          # ADC-capable pin
FAN_PIN = const(15)             # drives the MOSFET gate
BUTTON_PIN = const(4)           # to ground, internal pull-up
FAULT_LED_PIN = const(25)

# --- Electrical -----------------------------------------------------
REFERENCE_V = 3.3
FULL_SCALE = const(65535)
SENSOR_V_PER_C = 0.010          # 10 mV per degree, from the datasheet
AMPLIFIER_GAIN = 161            # measured, not nominal — see build log

# --- Behaviour ------------------------------------------------------
WARM_C = 28.0                   # start the fan above this
COOL_C = 24.0                   # stop it below this (hysteresis)
PURGE_MS = const(30000)
LOOP_MS = const(100)
DEBOUNCE_MS = const(20)
PLAUSIBLE_C = (-10.0, 120.0)    # anything outside this is a fault
```

Every number that would change if you moved rooms, boards, or sensors now
lives in one file, and every one of them has a name, so the code that
uses them reads as a description of behaviour rather than a list of
mystery constants. `const()` is a MicroPython-specific hint that lets the
compiler substitute the value directly — worth using for integers on a
board where memory is genuinely scarce.

## One module owns each piece of hardware

The rest of the program should never touch a pin directly. Give each
device a module that exposes what the device *means*, not how it is
wired.

```python
# sensor.py
from machine import ADC, Pin
import config

_adc = ADC(Pin(config.SENSOR_PIN))


def read_celsius(samples=8):
    """Return the plate temperature in degrees Celsius.

    Averages `samples` readings to cut random noise; averaging N samples
    reduces it by about the square root of N.
    """
    total = 0
    for sample_number in range(samples):
        total = total + _adc.read_u16()
    average_counts = total / samples

    volts = average_counts * config.REFERENCE_V / config.FULL_SCALE
    volts_at_sensor = volts / config.AMPLIFIER_GAIN
    return volts_at_sensor / config.SENSOR_V_PER_C


def is_plausible(celsius):
    """True if a reading could physically be real. See Defensive code."""
    low, high = config.PLAUSIBLE_C
    return low <= celsius <= high
```

```python
# fan.py
from machine import Pin, PWM
import config

_pwm = PWM(Pin(config.FAN_PIN))
_pwm.freq(1000)


def set_percent(percent):
    """Drive the fan at 0–100 percent, clamped."""
    if percent < 0:
        percent = 0
    if percent > 100:
        percent = 100
    _pwm.duty_u16(int(percent * config.FULL_SCALE / 100))


def off():
    set_percent(0)
```

Now `main.py` reads as the device's behaviour and contains no pin numbers
at all. The leading underscore on `_adc` and `_pwm` is a convention that
says "internal to this module" — Python will not stop you reaching in,
but the reader knows they should not.

The payoff arrives when the hardware changes. Move the fan to a different
pin, or swap PWM for a relay, and exactly one file changes. Everything
that depends on "the fan" depends on `set_percent`, which is a promise
about behaviour rather than about wiring — the software version of the
interface contract in [[System Block Diagrams]].

## Functions are contracts, so write them down

```python
def duty_for_error(error_c, gain_percent_per_c=20.0, floor_percent=20.0):
    """Return the fan duty in percent for a temperature error.

    error_c: measured minus target, in degrees Celsius. Positive means
             too hot, so the fan should run harder.
    Returns 0 when the error is negative; otherwise maps proportional
    demand onto the range in which the fan actually spins, which begins
    at floor_percent. Clamped to 100.
    """
    if error_c <= 0:
        return 0.0
    demand = gain_percent_per_c * error_c
    if demand > 100.0:
        demand = 100.0
    return floor_percent + (100.0 - floor_percent) * demand / 100.0
```

Three things make that function reviewable. Its name says what it
produces. Its docstring states what the arguments mean, including units
and sign, which is where most integration bugs live. And its tuning
values are parameters with defaults rather than constants buried inside,
so the same function can be tested with different numbers — which is what
makes [[Testing Without a Debugger]] possible at all.

## Why MicroPython, and when it is the wrong choice

You should be able to answer this at a design review, because it is a
real engineering decision rather than a preference.

| | High-level (MicroPython) | Low-level (C, assembly) |
| --- | --- | --- |
| Development speed | Fast: a REPL, no compile step | Slower: build, flash, repeat |
| Readability | High; a partner can follow it | Depends entirely on the author |
| Memory use | Larger runtime, heap, garbage collection | Small and predictable |
| Timing determinism | Good enough for millisecond work | Required for microsecond work |
| Access to the hardware | Through libraries and modules | Direct register access |
| Best used for | Logic, sequencing, control at human timescales | Tight timing, tiny memory, high volume |

The honest summary: use the highest-level language that meets the timing
and memory requirements, because everything else about it is cheaper.
When a requirement genuinely needs microsecond determinism or a few
kilobytes of total memory, that is when C earns its cost — and even then
the usual answer is to write the one tight piece low and keep the rest
readable.

## Writing it for the next person

- **Comment the *why*, never the *what*.** `set_percent(60)` needs no
  comment saying it sets sixty percent. It may badly need one saying the
  fan stalls below fifty when the filter is dirty.
- **One meaning per name, program-wide.** If `raw` is the temperature
  reading, it must never briefly be the light reading.
- **No arithmetic in the main loop.** Calculations belong in named
  functions; the loop should read like the specification.
- **Header block on every file**: what it is, who owns it, which
  revision, which board. A program is a technical document, and technical
  documents say who is responsible.
- **Revision notes in the log.** Bump the revision when behaviour
  changes, record what changed and why in your [[Tech Journal]], and
  commit it — [[Version Control for Firmware]] is the tool, and the
  commit message is the note your future self will read.

These are the Essential Skills the industry screens for: writing so
somebody can act on it, using documents accurately, and organising work
so it survives other people. They are assessed here because they are
assessed there. Hand your program to another group with no explanation
and ask them to change the fan threshold; time them. Their difficulty is
your bug list, and it is the same test
[[Writing Documentation Somebody Can Build From]] applies to the rest of
the handover package.

%%curriculum-start%%
## Curriculum connection

![[B5.1]]

![[B5.2]]

![[D3.3]]
%%curriculum-end%%
