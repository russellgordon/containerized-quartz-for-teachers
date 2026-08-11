---
title: Debugging Basics
draft: false
created: __CREATED__
tags:
  - code
---
You already know how to debug — you learned it at the bench. A
machine that will not boot gets diagnosed the same way as a
program that will not run: read the symptom, change one thing,
test, and never trust a guess you have not written down. This
page moves the diagnosis mindset you drill in
[[Troubleshooting Practice]] into code.

## Read the error like a technician

```python
parts = ["fan", "heatsink", "thermal paste"]
print("Installing:", parts[3])
```

Run it. Python answers with a *traceback*: the file, the line
number, and `IndexError: list index out of range`. Read it from
the bottom up — the last line names the fault, the lines above say
where. Three items live at positions 0, 1, and 2; there is no
position 3. The error message is not scolding you; it is the beep
code.

## One change at a time

Swapping three components at once tells you nothing when the
machine finally boots — which one was the fix? Code is identical.
When a program misbehaves:

1. Change exactly one thing.
2. Run it again.
3. Keep or revert the change based on what you saw — then repeat.

Two changes at once and a working program is a *mystery*, not a
repair.

## Print the values

```python
volts = input("Supply voltage? ")
print("DEBUG: volts is", volts, "- type:", type(volts))
threshold = 11.5
print("DEBUG: comparing", float(volts), "against", threshold)
```

A multimeter tells you what the circuit is *actually* doing, not
what the schematic promises. `print` is the code multimeter: drop
one in, look at the real value, and half of all bugs confess on
the spot — usually because a value is not what you assumed it
was. Delete the debug lines once the program behaves: a clean
bench, a clean file.

## Make it yours

1. Take any program from [[Decisions and Loops]] and break it on
   purpose — one character. Trade with a neighbour and diagnose
   each other's fault using only the traceback.
2. Log your next three real bugs: symptom, one-change steps, fix.
   That log is [[Tech Journal]] material, verbatim.

%%curriculum-start%%
## Curriculum connection

![[B5.4]]
%%curriculum-end%%
