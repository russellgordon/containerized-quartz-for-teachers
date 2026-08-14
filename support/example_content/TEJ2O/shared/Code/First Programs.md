---
title: First Programs
publish: true
created: __CREATED__
tags:
  - code
---
Three ideas start everything: a program can *show* something, *ask*
for something, and *remember* something. In Python those are
`print`, `input`, and variables — and one bench habit ties them
together: predict what a program will do, in writing, before you
run it. The prediction is the learning; the run is just the marking.

## Show, ask, remember

```python
print("Bench check starting.")
technician = input("Who is on this bench? ")
print("Logged in:", technician)
```

Read it line by line before running. `print` puts text on screen.
`input` pauses, shows its message, and waits — whatever gets typed
comes back and is *remembered* under the name `technician`. The
last line prints two things separated by a comma, and Python adds
the space between them.

## Variables are labelled boxes

```python
volts = 12
amps = 2
watts = volts * amps
print("Power drawn:", watts, "W")
```

`volts` and `amps` are names you chose, each holding a number. The
third line does real work: multiply the two values, store the
result under a new name. Change `amps` to `3`, predict the output
in writing, then run it — if your prediction missed, the gap it
leaves is worth more than a right answer would have been.

## One honest trap

```python
reading = input("Voltage reading? ")
doubled = reading * 2
print(doubled)
```

Predict it. Type `12` when asked — and the program prints `1212`,
not `24`. `input` always hands back *text*, and Python doubles
text by repeating it; `int(reading)` turns it into a number first.
Every programmer meets this trap — meeting it on purpose is cheaper.

## Make it yours

1. Write a program that asks for a part name and a quantity, then
   prints a one-line stock label for the parts drawer.
2. Extend the power example: store an electricity price in a
   variable, then compute and show the cost of running that load
   for an hour.

%%curriculum-start%%
## Curriculum connection

![[B5.1]]

![[B5.2]]
%%curriculum-end%%
