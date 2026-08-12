---
title: The Tide Problem
draft: false
created: __CREATED__
tags:
  - tasks
enableToc: true
---
> [!abstract] At a glance
> Pairs · launched with the sinusoid recipe, due on the modelling day ·
> one model, four letters explained, one prediction defended

## What you are making

Twice a day, the ocean breathes. You will receive a genuine tide table
— heights and times for one Canadian station over several days — and
your job is to catch that breathing in an equation:

$$h(t) = a\sin(k(t - d)) + c$$

You finish with the **fitted model**, a paragraph for each letter
explaining what it means *in water* — half the tidal range, the length
of a tidal cycle, when high tide arrives, the average sea level — and
one **defended prediction**: the water height at a time your data
never recorded, plus the answer to the harbour question that comes
with your station: *between which hours is there enough depth to
cross?*

## Milestones

- [ ] Data plotted by hand; period, amplitude, and axis estimated from
      the picture before any formula appears
- [ ] The four letters assembled into a first-draft equation, using the
      recipe from [[Sinusoidal Functions]]
- [ ] Model plotted against the data in [[Using Desmos]] and adjusted
      until the disagreement is small and stated
- [ ] Each letter translated into a sentence about water
- [ ] Prediction and harbour answer written and defended

## How it is assessed

Per [[How Marks Work]], the reasoning is the product: a model that
misses slightly, with the miss measured and explained, outranks a
perfect curve with silent letters. On the due date your pair defends
the prediction out loud. The [[Math Journal]] entry on where your
model disagreed with the data completes the evidence.

## Success criteria

| Quality | What it looks like in your work |
| --- | --- |
| Picture first | Amplitude, period, and axis read from the plot |
| Letters that speak | Every parameter tied to something wet |
| A measured miss | Model-versus-data disagreement stated in metres |
| A brave prediction | An unmeasured time, with reasoning shown |
| A useful answer | The harbour question answered in clock hours |

> [!success]- If the wave will not fit
> Check the period before anything else — tides run on roughly a
> 12.4-hour cycle, so a period of exactly 12 will drift out of phase
> across your data window. A cosine form may also fit more naturally
> than sine: same wave, different starting point.

%%curriculum-start%%
## Curriculum connection

![[D2.8]]

![[D3.3]]

![[D3.5]]
%%curriculum-end%%
