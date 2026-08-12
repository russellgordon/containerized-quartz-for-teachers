---
title: Input, Output, and Timing
draft: false
created: __CREATED__
tags:
  - code
enableToc: true
---
In [[Blink, Read, React]] the first button most groups wired appeared to
work perfectly and counted eleven presses for one push. Nothing was
broken. The switch was doing exactly what mechanical switches do, and the
program was believing it. This page is about reading the physical world
honestly, and about timing that does not bring everything else to a halt.

## Reading a pin

```python
from machine import Pin
import time

BUTTON_PIN = 4     # pin 4 on this board; check your board's pinout
LED_PIN = 2

button = Pin(BUTTON_PIN, Pin.IN, Pin.PULL_UP)
led = Pin(LED_PIN, Pin.OUT)

while True:
    if button.value() == 0:      # pressed pulls the pin to ground
        led.on()
    else:
        led.off()
    time.sleep_ms(10)
```

The third argument, `Pin.PULL_UP`, switches on a resistor inside the chip
that holds the pin at the supply voltage whenever nothing else is driving
it. Your button's other job is to connect the pin to ground. So the pin
reads 1 at rest and 0 when pressed — **active low**, which is the normal
arrangement because it needs one wire and no external parts.

Leave the pull-up off and the pin floats: undefined, drifting, and
responsive to your hand near the bench. A circuit that behaves
differently when you touch it has a floating input, every time. The
electrical background is in [[Sensors and Actuators]].

Note also that `if button.value():` reads as "if the button is **not**
pressed" here. It is a bug that passes a casual bench test, because the
LED still changes when you press. Write the comparison out — `== 0` —
and say what it means beside it.

## Why one press counts as eleven

Two separate things are happening, and each on its own is enough to
ruin a count.

**The loop is faster than your finger.** A `while True` loop runs
thousands of times a second. A press lasts a fair fraction of a second.
Every pass while your finger is down sees a 0.

**The contacts bounce.** A mechanical switch does not close once; its
contacts make and break several times over a few milliseconds as they
settle. An oscilloscope on the pin shows it plainly, and
[[Using an Oscilloscope]] is worth the setup once so that you have seen
it rather than been told.

The fix has two halves. Act on the *transition* rather than the state,
and ignore further transitions for a settling window afterwards.

```python
DEBOUNCE_MS = 20

count = 0
previous = button.value()
last_change = time.ticks_ms()

while True:
    now = time.ticks_ms()
    current = button.value()

    if current != previous:
        if time.ticks_diff(now, last_change) > DEBOUNCE_MS:
            last_change = now
            previous = current
            if current == 0:            # a 1 to 0 transition is a press
                count = count + 1
                print("Presses:", count)

    time.sleep_ms(1)
```

Follow it through one press. At rest `previous` is 1. Your finger lands,
`current` becomes 0, the change is more than 20 ms after the last
accepted one, so it is accepted: `previous` becomes 0 and the count goes
up. The contacts then bounce back to 1 briefly — a change, but inside the
20 ms window, so it is rejected and `previous` is left alone. When you
release, the transition back to 1 is accepted but does not count, because
only the 1-to-0 edge is a press.

> [!warning] The fix that is not a fix
> Putting `time.sleep_ms(200)` inside the `if` also stops the
> over-counting, and you will see it recommended. It works by making the
> program deaf for a fifth of a second — so it drops genuine fast
> presses, and it stalls every other thing the program should be doing
> meanwhile. Debounce by *remembering the time*, never by stopping.

## Timing without stopping

`time.sleep_ms()` is fine when the program has nothing else to do, and
useless the moment it does. The general pattern is to check the clock
each time round the loop and act when enough has passed.

```python
BLINK_MS = 250

led_state = 0
last_blink = time.ticks_ms()

while True:
    now = time.ticks_ms()

    if time.ticks_diff(now, last_blink) >= BLINK_MS:
        last_blink = now
        led_state = 1 - led_state
        led.value(led_state)

    # the button check from above goes here, and runs every pass
    # rather than only between blinks

    time.sleep_ms(1)
```

Two details in there are load-bearing.

`time.ticks_ms()` returns a counter that wraps around when it reaches the
end of its range, so subtracting two readings directly can produce
nonsense once every few weeks of uptime. `time.ticks_diff(a, b)` handles
the wrap correctly. Use it always, even in a program you expect to run
for five minutes — the version of this bug that only appears after
forty-nine days is not one you want to meet in a graded project.

`last_blink = now` rather than `last_blink = last_blink + BLINK_MS` is a
deliberate choice. The first restarts the interval from the moment you
acted, and drifts slightly. The second keeps a rigid schedule and can
"catch up" with a burst if the loop is ever delayed. For blinking an LED,
take the first; for anything that must keep long-term time, the second is
the right instinct.

## Make it yours

1. Add a second button that resets the count to zero, debounced the same
   way. Predict on paper what happens if both are pressed together.
2. Make the LED blink at one rate normally and a faster one while the
   button is held, without any `sleep` longer than a millisecond
   anywhere in the program.
3. Time a real switch. Put a scope on your button pin, capture one
   press, and measure how long the bouncing actually lasts. Record the
   number in your [[Tech Journal]] and set `DEBOUNCE_MS` from your
   measurement rather than from this page.
4. Count presses and *report* them: print a running count with the time
   since the previous press, so you can tell a double-click from two
   presses.

Next the world stops being on-or-off: [[Reading Sensors]] handles
quantities that come in shades.

%%curriculum-start%%
## Curriculum connection

![[B3.1]]

![[B5.2]]

![[B5.3]]
%%curriculum-end%%
