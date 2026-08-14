---
title: How Computers Got Faster
draft: false
created: __CREATED__
tags:
  - concepts
enableToc: true
---
The machine you took apart in [[Take It Apart]] would have filled this
room in 1965 and cost more than the school. Nothing magic happened. A
few specific advances happened, one after another, and it is worth
knowing which — because the same forces decide what is on the bench
next year.

## The one that started it

Early computers switched with **vacuum tubes**: glass, hot, the size of
a thumb, and prone to burning out. The **transistor**, and then the
**integrated circuit** — many transistors made together on one piece of
silicon — replaced them with something small, cool, and cheap enough to
use by the million.

That is the whole story of the chip under the heatsink: the same logic
gates you build by hand in [[Gates in Hardware]], made microscopically
and in enormous numbers.

## What actually got better

| Advance | What changed | What you see on a spec sheet |
| --- | --- | --- |
| Smaller fabrication | Features measured in nanometres rather than micrometres, so more transistors fit and each switches with less energy | "5 nm process" |
| Higher clock rates | The fetch–execute cycle runs more times per second | GHz — but see below |
| More cores | Several complete CPUs on one chip, working at once | "8-core" |
| Cache | Small, very fast memory ON the CPU, so it waits on RAM less often | "32 MB L3 cache" |
| Faster buses | Wider, quicker roads between CPU, RAM, and cards | PCIe generations; RAM speeds in MT/s |
| Solid-state storage | No moving parts, so the shelf stopped being the bottleneck | NVMe, and read speeds in GB/s |

**Moore's observation**, made in 1965, was that the number of
transistors on a chip was doubling roughly every two years. It held for
about fifty years, which is why a phone outruns a 1990s supercomputer.

## Why clock speed stopped being the headline

Around 2005 clock rates stalled near 4 GHz, and they have barely moved
since. Pushing a chip faster means more heat than a fan can move, so
manufacturers stopped racing and started adding cores and cache
instead.

> [!warning] The bench consequence
> A 3.5 GHz CPU from this year beats a 3.5 GHz CPU from 2012 by a wide
> margin, so **never compare machines by clock speed alone**. Compare
> generation, cores, cache, and — most of the time — whether the
> storage is solid state, because on an old machine that single swap
> is the upgrade a customer actually feels. That is the argument you
> will make in [[The Refurb Report]].

## What is coming, roughly

Feature sizes are approaching limits set by atoms rather than by
engineering, so the current work is in specialised chips — graphics and
machine-learning accelerators — and in packaging several small chips
together. Whatever arrives, the technician's question does not change:
what does it do, what does it cost, and does the customer need it?

%%curriculum-start%%
## Curriculum connection

![[A1.4]]

![[A1.3]]
%%curriculum-end%%
