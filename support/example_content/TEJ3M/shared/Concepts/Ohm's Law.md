---
title: Ohm's Law
draft: false
created: __CREATED__
tags:
  - concepts
---
At the bench your group did something Grade 10 never asked of you: you
put a resistor in a circuit, changed the supply voltage six times, and
wrote down the current each time. Then you graphed it. The points fell
on a line through the origin, and the slope was the same number for
every group with the same resistor — and a different number for groups
with a different one. You measured a law into existence before anybody
named it.

$$V = IR$$

Voltage in volts, current in amperes, resistance in ohms. Rearranged as
you need it: $I = \frac{V}{R}$ when you want current, $R = \frac{V}{I}$
when you want the resistance a component is actually presenting — which
is not always the number printed on it.

## What the equation is really claiming

It claims that for an ohmic component, current is *proportional* to
voltage. That word matters. Double the voltage across a resistor and
you double the current through it; the resistor does not "resist
harder" as you push. Your graph said so before the formula did: a
straight line through the origin is exactly what proportionality looks
like.

| You know | You want | Use |
| --- | --- | --- |
| $V$ and $R$ | current | $I = \frac{V}{R}$ |
| $I$ and $R$ | voltage drop | $V = IR$ |
| $V$ and $I$ | actual resistance | $R = \frac{V}{I}$ |

## Working an example properly

A 220 Ω resistor sits across a 5 V supply. Then

$$I = \frac{5\ \text{V}}{220\ \Omega} \approx 0.0227\ \text{A} = 22.7\ \text{mA}$$

Two habits worth building now, because they are what separate a
technician from someone who plugs numbers in:

- [ ] Carry the units through the calculation, not just onto the
      answer. Volts divided by ohms *is* amperes; if your units do not
      come out right, your working is wrong even when your arithmetic
      is not.
- [ ] Sanity-check against the bench. Twenty-two milliamps through a
      small resistor is ordinary; twenty-two amps would melt something.
      A number you cannot picture is a number you should not trust —
      see [[Predict the Circuit]].

> [!warning] Not everything is ohmic
> An LED is not a resistor, and $V = IR$ will lie to you about it.
> Its current rises steeply once it starts conducting, which is why an
> LED always gets a resistor in series to limit the current — the
> resistor obeys Ohm's law even when the LED does not. Compute the
> resistor from the voltage *left over* after the LED's forward drop,
> not from the supply voltage.

## Where this goes next

Every measurement you take for the rest of this course leans on this
relationship — [[Series and Parallel Circuits]] extends it to whole
networks of components, [[Power and Heat]] turns it into watts and the
reason parts fail, and every [[Reading a Datasheet|datasheet]] you open
assumes you can already do this arithmetic in your head. Drill it in
[[Ohm's Law Practice]] until the rearranging is automatic; the thinking
is what you want spare attention for.

%%curriculum-start%%
## Curriculum connection

![[A3.1]]

![[A3.3]]

![[B3.2]]
%%curriculum-end%%
