---
title: Structuring Embedded Code
publish: true
created: __CREATED__
tags:
  - code
enableToc: true
---
By the end of Unit 3 the working programs in this room are about a
hundred lines long, and the difference between the ones that get finished
and the ones that get abandoned is not cleverness. It is whether a person
who did not write the program — your partner, your teacher, you in three
weeks — can open it and find the thing they need to change.

## Everything that varies goes at the top

```python
# Bench fan controller
# T. Nguyen and J. Okafor, revision 3
# Board: generic MicroPython board. Confirm pins against your own pinout.

from machine import Pin, ADC, PWM
import time

# --- Configuration -------------------------------------------------
SENSOR_PIN = 26            # ADC-capable pin
FAN_PIN = 15               # drives the transistor gate
BUTTON_PIN = 4             # to ground, uses the internal pull-up

REFERENCE_V = 3.3
FULL_SCALE = 65535
PWM_HZ = 1000

WARM_RAW = 28000           # above this, start the fan
COOL_RAW = 24000           # below this, stop it again
SAMPLE_MS = 100
DEBOUNCE_MS = 20
# -------------------------------------------------------------------
```

Two things make this worth the space it takes. Every value that would
change if you moved to a different board, a different sensor, or a
different room is in one block, so changing it is a thirty-second job
instead of a search through a hundred lines. And every one of those
numbers now has a *name*, so the code below reads as a description of
behaviour rather than a list of magic constants.

The header comment is doing real work too. Who wrote it, which revision,
and which board — the same information you would put on a drawing. A
program is a technical document, and the trade's expectation is that a
technical document says who is responsible for it.

## Functions name the steps

A `while True` loop with forty lines inside it cannot be read, only
deciphered. Break the work into functions whose names are the steps, and
the loop becomes an outline of what the device does.

```python
def read_temperature_raw():
    total = 0
    for sample_number in range(8):
        total = total + sensor.read_u16()
    return total // 8


def set_fan(percent):
    if percent < 0:
        percent = 0
    if percent > 100:
        percent = 100
    fan.duty_u16(int(percent * FULL_SCALE / 100))


def button_pressed(now):
    """Return True once per press, debounced. Uses module state."""
    global previous_button, last_button_change
    current = button.value()
    if current != previous_button:
        if time.ticks_diff(now, last_button_change) > DEBOUNCE_MS:
            last_button_change = now
            previous_button = current
            return current == 0
    return False
```

Name a function after what it produces, not how. `read_temperature_raw`
tells the reader both that they get a raw converter value and that it has
not been scaled to degrees — a warning built into the name. Compare
`get_data`, which promises nothing and delivers less.

## A state machine instead of a pile of flags

Devices that do more than one thing accumulate boolean variables —
`fan_on`, `manual_mode`, `is_cooling` — until no one can say which
combinations are legal. Name the states instead, keep exactly one
variable saying which one you are in, and write the transitions out.

```python
STATE_IDLE = "idle"
STATE_RUNNING = "running"
STATE_MANUAL = "manual"

state = STATE_IDLE
last_sample = time.ticks_ms()


def main():
    global state, last_sample

    set_fan(0)                       # known safe state before anything else

    while True:
        now = time.ticks_ms()

        if button_pressed(now):
            if state == STATE_MANUAL:
                state = STATE_IDLE
                set_fan(0)
            else:
                state = STATE_MANUAL
                set_fan(100)

        if time.ticks_diff(now, last_sample) >= SAMPLE_MS:
            last_sample = now
            raw = read_temperature_raw()

            if state == STATE_IDLE and raw > WARM_RAW:
                state = STATE_RUNNING
                set_fan(60)
            elif state == STATE_RUNNING and raw < COOL_RAW:
                state = STATE_IDLE
                set_fan(0)

        time.sleep_ms(1)
```

Read the loop and you can say exactly what the device does, in three
sentences, without holding anything in your head. That is the test. Note
also that the two thresholds are different values — the hysteresis from
[[Reading Sensors]], carried through so the fan cannot stutter on and off
at one temperature.

> [!important] Leave the hardware safe when the program stops
> Software can stop for reasons you did not plan: an interrupt at the
> REPL, an exception three levels down, a reset. If your program stops
> with a motor at full power, the motor stays at full power. Wrap the
> entry point so that shutdown is not optional.
>
> ```python
> try:
>     main()
> finally:
>     set_fan(0)
> ```
>
> Whatever happens inside `main`, the `finally` block runs on the way
> out. This is the software half of the same instinct that puts a
> pull-down resistor on a transistor gate.

## Writing it for the next person

- **Comment the *why*, never the *what*.** `set_fan(60)` needs no comment
  saying it sets the fan to sixty percent. It might badly need one saying
  that below about fifty the fan stalls without starting.
- **One meaning per name.** If `raw` means the temperature reading
  everywhere in the program, it must never briefly mean the light
  reading.
- **Keep the loop free of arithmetic.** Calculations belong in functions
  with names; the loop should read like a description of behaviour.
- **Record the revision.** Bump the number in the header when the
  behaviour changes, and note what changed in your [[Tech Journal]]. When
  a mark depends on which version was demonstrated, this is the only
  evidence that exists.
- **Write down what you tested.** "Fan starts at 28 000 raw, stops at
  24 000, checked with a hair dryer and a stopwatch" is worth more to an
  assessor than any amount of tidy formatting, and
  [[Documenting Your Build]] shows the form it takes.

These are the Essential Skills the industry actually screens for —
writing so someone else can act on it, using documents accurately, and
organising work so it survives contact with other people. They are
assessed here because they are assessed there.

## Make it yours

1. Take a working program of yours from earlier in the unit and move
   every literal number into a named constant block. Count how many you
   find.
2. Add a fourth state to the fan controller — a timed purge that runs the
   fan for thirty seconds and then returns to idle — without adding a
   single boolean flag.
3. Hand your program to another group with no explanation and ask them to
   change the fan speed and the temperature threshold. Time them. Their
   difficulty is your bug list.
4. Write the header comment for [[The Embedded Device]] now, before the
   code exists. If you cannot state in three lines what the device does,
   the design is not finished.

%%curriculum-start%%
## Curriculum connection

![[B5.1]]

![[B5.2]]

![[D3.4]]
%%curriculum-end%%
