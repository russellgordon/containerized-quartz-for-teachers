---
title: Reading a Datasheet
draft: false
created: __CREATED__
tags:
  - tutorials
enableToc: true
---
Last year you read spec sheets, which are written to help someone
choose between two products in a shop. A datasheet is a different
document with a different reader in mind: it is the manufacturer's
formal statement of what a part will and will not do, written for the
person designing it into something. It is longer, it is drier, and it
is the only place the number you actually need is going to be.

You are not expected to read one end to end. Nobody does. You are
expected to be able to find four things in one quickly, and to notice
when the document declines to tell you something.

## What a datasheet is and is not

It is a promise with conditions attached. Every figure in it is true
*at the stated supply voltage, at the stated temperature, with the
stated test circuit* — and outside those conditions the manufacturer
has promised nothing at all. That is not weaselling; it is the only
honest way to characterise a physical part. It does mean that quoting
a number without its conditions is quoting half a fact, which is the
same rule your [[Tech Journal]] applies to your own measurements.

Get it from the manufacturer, by exact part number, and check the
revision date. A retailer's product page and a forum's memory of a
datasheet are not the datasheet.

## The sections, and the question each answers

| Section | The question it answers |
| --- | --- |
| Description and features | What is this part for, in one paragraph? |
| Pin configuration and package | Which pin is which, and where is pin 1? |
| Absolute maximum ratings | What must never happen to this part? |
| Recommended operating conditions | Where am I supposed to run it? |
| Electrical characteristics | What will it actually do there, with min, typ, and max? |
| Timing | How fast, and with what setup and hold requirements? |
| Thermal information | How much power can it dissipate before it cooks? |
| Application information | The manufacturer's own worked examples |

Two habits pay off immediately. First, find pin 1 before anything
else — a notch, a dot, or a bevel on the package — because every other
pin number in the document counts from it, and a chip installed
rotated is a chip that gets hot and stays broken. Second, read the
conditions column beside any figure you write down. It is narrow, it
is in small type, and it is where the truth lives.

> [!warning] Absolute maximums are a fence, not a target
> The absolute maximum ratings table is the most misread page in any
> datasheet. It does not say "this part runs at 30 mA". It says
> "beyond 30 mA, this manufacturer no longer guarantees the part
> survives" — and exceeding it even briefly can cause damage that
> shows up weeks later as an intermittent fault with no visible
> cause. Designs are built against the *recommended operating
> conditions*, with margin. Deliberately running well below a limit
> is called derating, and it is what separates something that works
> from something that keeps working.

## Min, typ, and max

Three columns, three quite different meanings, and mixing them up
produces designs that pass on your bench and fail on somebody else's.

- **Typ** is what a representative part did on a good day. It is
  useful for predicting behaviour and useless as a guarantee. No part
  is required to be typical.
- **Min** and **max** are the guaranteed bounds. Design so that your
  circuit works anywhere between them, because the part you are handed
  is somewhere in there and you do not get to choose where.
- Where only a typ figure is given, the manufacturer is telling you
  they are not prepared to bound that parameter. Treat that as
  information, and leave more margin.

## Working an example properly

You want an indicator LED on a 5.0 V rail. Its datasheet gives a
typical forward voltage of 2.0 V at 20 mA and an absolute maximum
continuous forward current of 30 mA. You choose to run it at 15 mA —
comfortably visible, and half the absolute maximum.

The resistor gets whatever voltage the LED does not take, so

$$R = \frac{V_{\text{supply}} - V_F}{I_F} = \frac{5.0\ \text{V} - 2.0\ \text{V}}{0.015\ \text{A}} = 200\ \Omega$$

Nobody stocks 200 Ω in the drawer, so you take the next standard value
upward — 220 Ω, which errs toward less current rather than more — and
recompute what you will actually get:

$$I = \frac{3.0\ \text{V}}{220\ \Omega} \approx 13.6\ \text{mA}$$

Then the step that gets skipped: check the resistor as well as the
LED. Its power dissipation is

$$P = I^2 R = (0.0136\ \text{A})^2 \times 220\ \Omega \approx 0.041\ \text{W}$$

which is about 41 mW. A common quarter-watt resistor has roughly six
times that in hand, so it will run cool. Had the answer come out at
0.2 W you would still be "within rating" and the part would be too hot
to touch — see [[Power and Heat]] for why that matters more than the
rating alone suggests.

That whole sequence is the professional pattern: pick a target well
below the maximum, compute, take a real value, recompute what you will
actually get, then check every part in the loop for heat.

## When the datasheet does not say

Sometimes the figure you want is genuinely absent. The honest
responses, in order of preference:

1. Look for an application note from the same manufacturer. It often
   contains the worked case the datasheet omitted.
2. Look at the typical characteristic curves at the back — the answer
   is frequently in a graph rather than a table.
3. Measure it yourself, and write down the conditions, and treat the
   result as true only for the part in your hand.
4. Design so that it does not matter. A circuit whose correctness
   depends on an unspecified parameter is a circuit with a hidden
   assumption in it.

What you may not do is assume. [[Components and Their Markings]] gets
you as far as identifying the part; from there the datasheet is the
primary source, and "I thought it was about two volts" is not a
number anybody can build on.

%%curriculum-start%%
## Curriculum connection

![[A3.1]]

![[A1.2]]
%%curriculum-end%%
