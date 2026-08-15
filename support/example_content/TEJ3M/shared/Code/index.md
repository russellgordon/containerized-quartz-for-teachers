---
title: Code
publish: true
created: __CREATED__
tags:
  - code
---
Everything in this folder runs on a microcontroller, in MicroPython, and
every program here exists to make something physical happen. That is the
difference between this and a programming course: a bug does not produce
a stack trace, it produces a motor that will not turn or an LED that
flickers when you touch the bench.

These six pages are one continuous thread, and they end at
[[The Embedded Device]] — the Unit 3 task, where a sensor you chose
drives an actuator you sized, under code you wrote. That is not an
invention of this course: the curriculum asks specifically for
[[B5.3|a program that controls or responds to an external device]]. Read
the pages in order. Each one assumes the habits of the one before it.

| Page | What it adds |
| --- | --- |
| [[Your First Embedded Program]] | Getting code onto the board and a pin to obey |
| [[Input, Output, and Timing]] | Buttons, debouncing, and timing that does not block |
| [[Reading Sensors]] | The analog world, converted and calibrated |
| [[Driving Outputs Safely]] | PWM, transistors, and loads bigger than a pin |
| [[Structuring Embedded Code]] | Programs another person can read and change |
| [[Debugging Hardware and Software Together]] | Finding which half is lying to you |

> [!warning] Pin numbers on these pages are examples
> Boards differ, and a pin number that is a plain output on one board is
> a bus line, a boot-mode pin, or nothing at all on another. Every
> example here names its pins in a single line at the top so there is
> exactly one place to change. Confirm every one against your own board's
> pinout before you power anything — [[Reading a Datasheet]] is how.

Two working habits carry over from the bench and matter more here than
in any software course you will take.

**Predict, then run.** Write down what the program will do, in your
[[Tech Journal]], before you load it. The gap between prediction and
behaviour is the entire lesson; loading first and reading the result
teaches you almost nothing.

**Check the circuit before the code.** A program that "does not work" is
a hardware fault about half the time. Meter first, then blame the
software — the discipline is in
[[Debugging Hardware and Software Together]].
