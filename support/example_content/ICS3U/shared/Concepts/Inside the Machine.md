---
title: Inside the Machine
publish: true
created: __CREATED__
tags:
  - concepts
enableToc: true
---
Every line you have written so far has run on something. Not a
metaphor, not "the computer" — a board with parts soldered to it, each
doing one job, in a case you could open with a screwdriver. Knowing
which part does what turns a slow program from a mystery into a
question with an answer.

## The parts, and what each one is actually for

| Part | What it does | What it means when it is the bottleneck |
| --- | --- | --- |
| CPU | Fetches an instruction, does it, fetches the next | Your loop is doing too much arithmetic |
| RAM | Holds what is open right now | Your list is bigger than the memory it has |
| Cache | A small, very fast copy of what the CPU just used | The same data, read over and over, is nearly free |
| Storage (SSD or hard drive) | Keeps files when the power is off | Reading a file inside a loop is punishing you |
| Motherboard | Connects everything, sets what fits | You cannot simply add a faster part |
| Power supply | Turns wall power into what the parts need | The machine dies under load, not at rest |
| Video card | Draws things, and does wide parallel arithmetic | Games and machine learning, not your `for` loop |

RAM is where the confusion usually is. It is not storage. Everything in
RAM disappears the moment the power does, which is why
[[Files and Persistence]] exists at all: writing a file is the act of
moving something from the part that forgets to the part that does not.

## What happens when your program runs

The parts split the work in a fixed order, and it is worth being able
to narrate it:

1. Your file is on **storage**, as text.
2. Running it copies what is needed into **RAM**, because the CPU
   cannot reach storage directly at any useful speed.
3. The **CPU** fetches one instruction at a time, decodes it, and does
   it — arithmetic and comparisons in its own circuits, using
   **registers** and **cache** for the values in play right now.
4. `print()` hands bytes to the **operating system**, which hands them
   to the screen.
5. `input()` waits — the CPU has nothing to do until a key arrives,
   which is why a program that feels slow is often just waiting for
   you.

```python
total = 0
for value in readings:      # each pass: fetch, compare, add, jump back
    total = total + value   # CPU and RAM, thousands of times a second
```

That loop is the whole cycle in miniature. Every pass is the CPU
fetching, deciding, and storing, with `readings` sitting in RAM the
entire time.

> [!note]- Why a "3.2 GHz" processor is not 3.2 billion of your lines
> The number counts clock ticks, not Python statements. One statement
> of yours becomes many machine instructions, and one instruction can
> take several ticks — see [[From Source to Running Program]] for the
> journey from your text to those instructions. The number is useful
> for comparing two processors, and useless for predicting your
> program's speed.

## Where to look when something is slow

Ask which part is being asked to do too much. A program that crawls
while the fan is silent is usually waiting on storage or on a person.
A program that crawls with the fan roaring is doing real arithmetic —
and that is a signal to look at your algorithm, not your hardware.
[[Testing and Debugging]] is where that measurement habit lives.

%%curriculum-start%%
## Curriculum connection

![[C1.1]]

![[C1.4]]
%%curriculum-end%%
