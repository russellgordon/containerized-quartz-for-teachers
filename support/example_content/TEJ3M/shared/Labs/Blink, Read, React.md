---
title: Blink, Read, React
publish: true
created: __CREATED__
tags:
  - labs
enableToc: true
---
Three stages, over two bench days: make a pin turn something on, make a
pin notice something happening, and then put the two together into a
reaction-time game that measures a human being in milliseconds.

The circuit is smaller than anything you built in Unit 1. What is new is
that a program is now part of it, which means a fault can live in two
places at once, and "have you tried it again?" stops being a diagnostic
technique.

> [!danger] Safety notes
> **A microcontroller pin is not a power supply.** Its datasheet gives a
> maximum current per pin *and* a maximum total for the whole device,
> and the second is usually much smaller than the first times the number
> of pins. Read both before you connect anything, and design well under
> them. **Every LED gets its series resistor**, sized before it is
> connected. **Wire with the board unpowered** — unplug the USB cable,
> not just the code. **Never connect a pin directly to the supply rail
> or to ground while it is set as an output**: the pin will try to win
> and it will lose. **Anti-static habits apply to boards too**; the
> routine in [[Anti-Static Habits]] does not stop being true because
> the part has a USB socket on it.

## What you need

- [ ] Microcontroller board running MicroPython, plus its data cable
- [ ] Breadboard, jumper wires, one LED, one $180\ \Omega$ resistor
- [ ] One momentary pushbutton
- [ ] Multimeter, and the board's pinout open in front of you
- [ ] Your journal, and a stopwatch or phone timer

## Predict before you connect

1. **Size the resistor from the board's own rail voltage.** Most
   microcontroller pins swing to about $3.3\ \text{V}$, not
   $5\ \text{V}$ — check yours. With a red LED holding around
   $2.0\ \text{V}$, the resistor sees roughly $1.3\ \text{V}$. For about
   $7\ \text{mA}$ of current, the resistor needs to be
   $R = 1.3 / 0.007 \approx 186\ \Omega$, so $180\ \Omega$ is the
   nearest standard part, giving $1.3 / 180 \approx 7.2\ \text{mA}$.
   Write that prediction down.
2. **Check it against the datasheet's pin limit** and state the margin.
   If the pin is rated well above $7\ \text{mA}$ you are fine; if it is
   not, raise the resistor value. Do not discover this later.
3. **Predict the blink period from the code**, in milliseconds, by
   adding up the delays. Then predict how far off the real timing will
   be, and why.

## The work — stage one, output

4. Build the LED branch with the board unplugged: pin, resistor, LED
   long leg toward the pin, short leg to ground.
5. Plug in, and run this. The pin numbers are the only thing here that
   is not universal — replace them with the ones your board actually
   uses, from its pinout.

```python
from machine import Pin
import time

# These two numbers are specific to YOUR board. The pinout diagram in
# its documentation is the only authority; nothing here is a standard.
LED_PIN = 15
BUTTON_PIN = 14

led = Pin(LED_PIN, Pin.OUT)

while True:
    led.value(1)
    time.sleep_ms(500)
    led.value(0)
    time.sleep_ms(500)
```

6. **Measure the pin current** by breaking the LED branch and putting
   the meter in series. Compare with your prediction from step 1.
7. **Measure the blink period** by timing twenty full cycles with a
   stopwatch and dividing by twenty. Timing one cycle measures your
   thumb; timing twenty measures the board.

## The work — stage two, input

8. Add the button between your input pin and ground, and enable the
   board's internal pull-up so the pin reads high when nothing is
   pressed:

```python
button = Pin(BUTTON_PIN, Pin.IN, Pin.PULL_UP)
```

9. Print `button.value()` in a loop and confirm it reads 1 when open and
   0 when pressed. If it does not, the pull-up is not on, or the button
   is not wired to the pin you think it is.

## The work — stage three, react

10. Combine the two: light the LED after a random delay, then time how
    long the player takes to press.

```python
import random

def reaction_round():
    led.value(0)
    time.sleep_ms(random.randint(1000, 4000))
    led.value(1)
    start = time.ticks_ms()
    while button.value() == 1:
        pass
    elapsed = time.ticks_diff(time.ticks_ms(), start)
    led.value(0)
    return elapsed

print("Reaction time:", reaction_round(), "ms")
```

11. Run ten rounds on one player and record every result. One trial is
    an anecdote; ten is data.

## Results

| Measurement | Predicted | Measured | Difference |
| --- | --- | --- | --- |
| LED current (mA) | 7.2 | | |
| Voltage across the LED (V) | 2.0 | | |
| Voltage across the resistor (V) | 1.3 | | |
| Blink period, twenty cycles ÷ 20 (ms) | 1000 | | |
| Fastest of ten reaction rounds (ms) | | | |
| Slowest of ten reaction rounds (ms) | | | |

## Predicted against measured

Your blink period will come out a little longer than the delays you
added, and the reason is worth understanding: `sleep_ms` guarantees *at
least* that long, and every other line of the loop takes time too. The
gap is small here and enormous in a program that does real work between
delays — which is exactly why a blinking LED is a terrible clock, and why
[[Input, Output, and Timing]] introduces a better approach.

Your LED current will likely sit slightly under prediction if the LED's
forward drop is above $2.0\ \text{V}$. Measure the voltage across the LED
and across the resistor separately: the two should add up to the pin's
output voltage, and if they do not, your pin is not swinging as high as
you assumed under load.

## The question that matters

Your reaction times vary from round to round. Some of that variation is
the player. How much of it is the *measurement*? Work out every source of
delay between the LED lighting and `ticks_ms` being read — the loop, the
button's contact bounce, the pull-up's rise time — and estimate whether
the equipment could be adding milliseconds of its own. Then design a test
that would tell you.

%%curriculum-start%%
## Curriculum connection

![[B5.2]]

![[B5.3]]
%%curriculum-end%%
