---
title: Getting Unstuck
draft: false
created: __CREATED__
tags:
  - tutorials
---
Stuck is a normal working condition at a bench — [[Getting Help]] says
so, and working technicians live there daily. But there are two kinds
of stuck, and this year you have an instrument that can tell them
apart.

| Spinning | Diagnosing |
| --- | --- |
| Rewiring the same connection again | Measuring the voltage at both ends of it |
| "Maybe the chip is dead" | "Pin 14 reads 4.98 V, pin 7 reads 0.00 V, so it has power" |
| Changing three things and retesting | Changing one thing and retesting |
| Getting the same result faster | Getting a different result on purpose |
| Reading the code again | Toggling the pin and watching it on the meter |

Spinning feels like effort and produces nothing. Diagnosing looks
slower from the outside and is the only thing that ever ends. These
moves turn one into the other.

## Five moves

1. **Check power and ground first, with the meter.** Not "it should
   have power" — measure it. An astonishing proportion of dead
   circuits are dead because a supply rail is not where it is supposed
   to be, a ground is not connected, or a breadboard rail is split in
   the middle in a way nobody noticed. This costs thirty seconds and
   eliminates the most common fault class in existence.
2. **Change one thing.** One wire, one part, one line of code, then
   test. Change three, get a working circuit, and you have learned
   nothing — which one fixed it, and is one of the other two now a
   latent fault? One variable per test is the entire method.
3. **Split the circuit in half.** Find a point midway along the signal
   path and measure there. Is the fault upstream or downstream? Then
   split the half that failed. Four or five measurements will
   localise a fault anywhere in a circuit of any size, which is far
   better than checking components in the order you happen to like
   them.
4. **Compare against a known good.** The bench next to you built the
   same thing. Measure the same node on both and let the difference
   point at the problem. This is legitimate and professional, not
   copying — the norm in [[Our Classroom Norms]] is that help gets
   named, not that help is forbidden.
5. **Write down what you tried, with numbers.** On paper, at the
   bench: what you changed, what the meter read afterwards. Four lines
   in, patterns appear that memory hides, and you stop repeating a
   test you already ran. The list is also exactly what your
   [[Tech Journal]] needs at tools-away.

## Explaining it aloud still works

To a partner, or to an empty chair: "the supply comes in here, the
divider drops it to about 3 V, so the input pin should see high
when — wait." Saying a circuit out loud forces you through the step
you were skipping, and the fault is usually living in precisely that
step. It has always worked and it works better now, because you can
say numbers instead of hopes.

## When to stop and ask

Twenty minutes of real diagnosis is time well spent. Twenty minutes of
spinning is suffering with extra steps. The honest test: **when did
you last change something on purpose, and what did you measure
afterwards?** If the answer is "three attempts ago", escalate up the
ladder in [[Getting Help]].

> [!danger] Some questions are not twenty-minute questions
> Everything above assumes a circuit on a current-limited bench
> supply, being changed with the power off. Anything involving a
> component that got hot, a smell of burning, a large capacitor that
> may still be charged, or any equipment plugged into the wall is
> ask-first, immediately, every time. That is the standing agreement
> in [[Safety in the Lab]] and no amount of diagnostic cleverness
> outranks it.
