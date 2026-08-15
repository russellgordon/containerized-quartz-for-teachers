---
title: Your First Embedded Program
publish: true
created: __CREATED__
tags:
  - code
enableToc: true
---
The board on your bench has no screen to print to and no operating
system to complain to. Plug it in and it runs whatever program is stored
on it, immediately, and keeps running it until the power goes. Your first
program's job is to prove that chain works end to end: your editor, the
cable, the board's flash, the pin, the resistor, the LED.

## Where the code lives

MicroPython gives you two ways in, and you will use both constantly.

The **REPL** is a live prompt on the board itself, reached over the USB
cable. Type one line, press enter, and the board does it now. It is the
fastest instrument you own for answering "does this pin actually do
anything" — faster than editing a file, faster than reasoning.

A **file called `main.py`** stored on the board runs automatically at
power-up. That is what turns your experiment into a device. Once
`main.py` exists, the board no longer needs a computer attached; it needs
power. This is the moment the thing on your bench stops being a demo.

> [!tip] Keep an escape route
> A `main.py` containing an infinite loop with no pause in it can make
> the board hard to interrupt. Get in the habit of a short sleep inside
> every loop and of knowing your board's interrupt key combination before
> you need it — usually <kbd>Ctrl</kbd> + <kbd>C</kbd> at the REPL.

## Making a pin obey

```python
from machine import Pin
import time

LED_PIN = 2        # pin 2 on this board; check your board's pinout
ON_MS = 500
OFF_MS = 500

led = Pin(LED_PIN, Pin.OUT)

while True:
    led.value(1)
    time.sleep_ms(ON_MS)
    led.value(0)
    time.sleep_ms(OFF_MS)
```

Read it before you run it, line by line.

`from machine import Pin` brings in the hardware module. `machine` is the
part of MicroPython that does not exist on a desktop — it is the board.

`LED_PIN = 2` is a **constant**: a name for a value that is fixed for
this program. Writing pin numbers and timings as named constants at the
top, in capitals, is not decoration. It means the one thing that changes
when you move to a different board changes in exactly one place, and it
means the loop below reads as intent instead of as magic numbers.

`Pin(LED_PIN, Pin.OUT)` configures the pin as an output and hands back an
object representing it. Until this line runs, the pin is not an output
and writing to it does nothing useful.

`led.value(1)` drives the pin to the supply voltage; `led.value(0)` drives
it to ground. `led.on()` and `led.off()` do the same thing and read
better in code about lamps; use whichever makes the sentence clearer.

`time.sleep_ms(500)` pauses for 500 milliseconds. Note the unit is in the
name — `time.sleep()` takes *seconds*, and `time.sleep(500)` will freeze
your board for over eight minutes while looking exactly like a crash.

`while True:` runs forever, which on a microcontroller is the normal
shape of a program rather than a mistake. There is nothing to return to.

## The circuit underneath it

Software will happily drive a pin into an LED with no resistor, and the
LED will light, and it will be drawing far more current than it or the
pin is rated for. The code is not what protects the hardware — the
resistor is.

For a red LED with a forward drop of about 2.0 V on a 3.3 V pin, aiming
for 10 mA:

$$R = \frac{3.3\ \text{V} - 2.0\ \text{V}}{0.010\ \text{A}} = 130\ \Omega$$

The nearest standard value at or above that is 150 Ω, which gives
$\frac{1.3\ \text{V}}{150\ \Omega} \approx 8.7\ \text{mA}$ — comfortably
inside what a pin can source and plenty bright. The arithmetic is
[[Ohm's Law]]; the reason it is not optional is [[Power and Heat]].

## Make it yours

1. Change the two timing constants so the LED is on for a fifth of the
   time it is off. Predict the visual effect in writing first, then run
   it.
2. Add a second LED on another pin, with its own resistor, and alternate
   them. What single change makes them flash together instead?
3. Compute the resistor for the LED colour you were actually handed,
   using the forward drop from its datasheet rather than the 2.0 V above.
   Record both the calculation and the measured current in your
   [[Tech Journal]].
4. Save your program as `main.py`, unplug the board from the computer,
   and power it from something else. If it runs, you have built a device.

Everything so far is output only — the board talking, never listening.
[[Input, Output, and Timing]] gives it ears.

%%curriculum-start%%
## Curriculum connection

![[A3.5]]

![[B5.1]]

![[B5.2]]
%%curriculum-end%%
