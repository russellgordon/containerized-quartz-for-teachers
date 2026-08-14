---
title: Microcontroller Code Practice
draft: false
created: __CREATED__
tags:
  - exercises
---
These follow [[Inside a Microcontroller]], [[Digital and Analog Signals]]
and the programs you wrote in [[Blink, Read, React]]. Predict every
answer in writing before you check it, and predict it before you run it
on hardware — a program that does the wrong thing on a board can cost you
a component, and a prediction costs nothing.

Pin numbers below are written as they would be for a generic board.
Always confirm against your own board's pinout.

## Predict the output

1. What does this print, and how many lines appear?

   ```python
   for i in range(5):
       print(i)
   ```

2. A blink loop turns an LED on for 200 ms and off for 300 ms, forever.
   What is the period of the flash, its frequency, and the duty cycle?
3. A PWM output is set up with `pwm.freq(1000)` and
   `pwm.duty_u16(16384)`. What duty cycle is that, and what average
   voltage does a motor on a 3.3 V rail experience?
4. An `ADC` object returns 32768 from `read_u16()` on a board with a
   3.3 V reference. What voltage is at the pin? If the underlying
   converter is 12-bit, how many genuinely distinct readings are
   possible?
5. A button connects a pin to ground and the pin is configured with
   `Pin.IN, Pin.PULL_UP`. What does `button.value()` return when the
   button is pressed, and when it is not?

## Fix the program

6. This is meant to count button presses. It reports dozens per press.
   Explain why, and describe the fix.

   ```python
   count = 0
   while True:
       if button.value() == 0:
           count = count + 1
           print(count)
   ```

7. A classmate wants a one-second pause and writes `time.sleep(1000)`.
   What actually happens, and what did they mean to write?
8. **Find the error.** A program drives a small DC motor by wiring it
   between a GPIO pin and ground and calling `motor.value(1)`. The code
   runs without any error message. What is wrong, and what should the
   circuit look like instead?

## Answers

> [!success]- Answer 1
> It prints 0, 1, 2, 3, 4 — one number per line, **five lines**, and
> never a 5. `range(5)` produces five values starting at zero and
> stopping *before* five.
>
> This is the most famous off-by-one in programming and it costs real
> hardware time: a loop meant to step a motor five positions that steps
> it four, or an array of eight LEDs indexed 1 to 8 that crashes on the
> last one. Count the values, not the endpoint.

> [!success]- Answer 2
> **Period:** $200\ \text{ms} + 300\ \text{ms} = 500\ \text{ms}$, which is 0.5 s.
>
> **Frequency:** $f = \frac{1}{0.5\ \text{s}} = 2\ \text{Hz}$ — two full flashes per second.
>
> **Duty cycle:** the fraction of each period spent on, $\frac{200}{500} = 0.40$, so 40 %.
>
> Worth noting that "on for 200 ms" only describes the LED accurately
> because nothing else is happening in that loop. The moment the program
> also reads a sensor, the timing drifts — which is exactly the problem
> [[Structuring Embedded Code]] solves with non-blocking timing.

> [!success]- Answer 3
> `duty_u16` takes a value from 0 to 65535, so $\frac{16384}{65535} \approx 0.250$ — a **25 % duty cycle**.
>
> A motor cannot respond fast enough to follow a 1000 Hz square wave, so
> it experiences the average: $0.25 \times 3.3\ \text{V} \approx 0.825\ \text{V}$.
>
> An oscilloscope on that pin shows no such thing — it shows the full
> square wave swinging between 0 V and 3.3 V, one thousand times a
> second. The meter shows the average and hides the mechanism; the scope
> shows the mechanism. Both are true, and only one of them tells you the
> switching frequency.

> [!success]- Answer 4
> $V = \frac{32768}{65535} \times 3.3\ \text{V} \approx 1.65\ \text{V}$ — almost exactly half the reference, which is what half of the 16-bit range should give.
>
> A 12-bit converter produces $2^{12} = 4096$ distinct readings. The
> `read_u16()` call rescales them into a 0 – 65535 range for
> portability, but rescaling invents no information: you still have 4096
> real values, spaced about 16 apart in the reported range. Printing six
> decimal places of voltage claims a precision the hardware does not
> have.

> [!success]- Answer 5
> Pressed returns **0**; not pressed returns **1**.
>
> The pull-up resistor holds the pin at the supply voltage — a logic 1 —
> whenever nothing else is driving it. Pressing the button connects the
> pin to ground, pulling it to 0. This is called active-low, and it is
> the standard arrangement because a switch to ground needs only one
> wire to the button and no extra components.
>
> The practical consequence is that `if button.value():` reads as "if the
> button is *not* pressed", which is a bug that tests fine on the bench
> because the LED still changes when you press it.

> [!success]- Answer 6
> **Why it counts dozens.** The loop runs thousands of times per second,
> and a human press lasts a fair fraction of a second. Every pass through
> the loop while your finger is down sees a 0 and adds one. On top of
> that, the mechanical contacts *bounce* — they make and break several
> times within a few milliseconds of closing — so even an impossibly
> brief press produces multiple transitions.
>
> **The fix has two parts.** Count the *transition*, not the state:
> remember the previous reading and only act when it changes from 1 to 0.
> Then debounce: after a transition, ignore further changes for a short
> settling window, typically around 20 ms, using `time.ticks_ms()` and
> `time.ticks_diff()` rather than a blocking sleep. Worked code is in
> [[Input, Output, and Timing]].
>
> A brief `time.sleep_ms(200)` inside the `if` appears to fix it and does
> not: it makes the program deaf for a fifth of a second, which will drop
> a genuine second press and will stall everything else the program
> should be doing.

> [!success]- Answer 7
> `time.sleep()` takes **seconds**, so `time.sleep(1000)` pauses for a
> thousand seconds — nearly seventeen minutes. The board is not frozen
> and not broken; it is doing exactly as told, which is the most
> expensive kind of bug because there is nothing to see.
>
> They meant either `time.sleep(1)` or `time.sleep_ms(1000)`. Both give
> one second. In embedded code, prefer the millisecond form throughout
> and the unit is stated in the function name where you cannot misread
> it.

> [!success]- Answer 8
> **What is wrong:** nothing in the software, and everything in the
> circuit. A GPIO pin is rated to source or sink a few tens of
> milliamperes; a small DC motor draws hundreds of milliamperes running
> and considerably more at the instant it starts or if it stalls. The pin
> is being asked for many times what it can deliver. On top of that, a
> motor is inductive, so switching it off generates a reverse voltage
> spike well above the supply.
>
> The program runs "without any error message" because there is nothing
> in software that could detect this. The chip has no way to report that
> the world outside it is unreasonable.
>
> **What the circuit should be:** the pin drives the gate or base of a
> transistor through an appropriate resistor; the transistor switches the
> motor's current; a flyback diode sits across the motor to absorb the
> switch-off spike; and the motor runs from its own supply, with the two
> grounds tied together. All four, every time. The full treatment is in
> [[Driving Outputs Safely]].

When these are automatic, write the real thing in
[[Structuring Embedded Code]] and take it to [[The Embedded Device]].

%%curriculum-start%%
## Curriculum connection

![[B5.1]]

![[B5.2]]

![[B5.3]]
%%curriculum-end%%
