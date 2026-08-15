---
title: Code
publish: true
created: __CREATED__
tags:
  - code
---
Everything in this folder runs on a microcontroller, in MicroPython, and
every program exists to make something physical happen. Grade 11 got a
pin to obey you. This year the question is whether the firmware survives
contact with other people: can somebody else read it, change it safely,
and find out what it was doing when it failed at 2 a.m.?

These six pages are one continuous thread and they all feed
[[The Engineering Design Project]], where the code you write is a
deliverable in its own right — reviewed, defended, and handed over with
documentation. The curriculum asks for
[[B5.3|a program that interacts with a real-world device]], built with a
design process; a program nobody but you can maintain meets the letter of
that and fails the spirit.

| Page | What it adds |
| --- | --- |
| [[Structuring a Larger Program]] | Files, modules, and code that survives a partner |
| [[State Machines in Code]] | The transition table, in MicroPython |
| [[Talking to a Peripheral]] | Buses, registers, and raw bytes turned into numbers |
| [[Timing, Interrupts, and Real Time]] | Doing several things at once, on time |
| [[Defensive Embedded Code]] | Behaving sensibly when the world misbehaves |
| [[Testing Without a Debugger]] | Evidence, on hardware, with no step button |

Read them in order. Each assumes the habits of the one before it, and
each assumes the electrical design is already settled — the order of work
in [[System Block Diagrams]] has not changed just because the interesting
part is now software.

> [!warning] Pin numbers on these pages are examples
> Boards differ, and a pin that is a plain output on one board is a bus
> line, a boot-mode pin, or nothing at all on another. Every example here
> names its pins in one block at the top so there is exactly one place to
> change. Confirm every one against your own board's pinout before you
> power anything — [[Reading a Datasheet Like an Engineer]] is how.

Three habits carry the whole thread.

**Predict, then run.** Write down what the program will do before you
load it, in your [[Tech Journal]]. The gap between prediction and
behaviour is the entire lesson.

**Check the circuit before the code.** A program that "does not work" is
a hardware fault about half the time, and the meter answers faster than
the debugger you do not have.

**Commit early and often.** Firmware that only exists on one laptop is
firmware you can lose in an afternoon — [[Version Control for Firmware]]
is not optional at this level, and a revision history is the only
evidence of what was demonstrated when.
