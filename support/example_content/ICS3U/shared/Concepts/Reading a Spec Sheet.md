---
title: Reading a Spec Sheet
publish: true
created: __CREATED__
tags:
  - concepts
enableToc: true
---
"Which laptop should I buy?" is never really a question about laptops.
It is a question about what somebody does all day, translated into
numbers by a person who knows how the translation works. That person
is about to be you.

## The numbers, and who they matter to

| Line on the spec sheet | Reads as | Matters most to |
| --- | --- | --- |
| Processor: 6 cores, 3.5 GHz | How much arithmetic per second, and how many things at once | Video editing, simulations, compiling |
| Memory: 16 GB | How much can be open at once | Many browser tabs, big data files, virtual machines |
| Storage: 512 GB SSD | How much is kept, and how fast it loads | Everyone; the SSD is the upgrade people feel |
| Graphics: dedicated, 8 GB | Drawing and wide parallel arithmetic | Games, 3-D, machine learning |
| Display: 14", 1920 × 1080 | How much fits on screen, how sharp | Anyone reading code all day |
| Battery: 60 Wh | How long away from a wall | Students, anyone commuting |
| Ports: 2 × USB-C, HDMI | What can be plugged in without an adapter | Anyone with existing gear |

Notice what is missing: nowhere does the sheet say "good" or "fast
enough". Those words only exist relative to a person.

## Peripherals are specifications too

The parts outside the case have numbers that mean something, and a
requirement usually lands on one of them:

- **Monitor** — size and resolution decide how much code is visible
  without scrolling; refresh rate matters for games and almost nothing
  else.
- **Printer** — pages per minute, and whether it is laser (cheap per
  page, sharp text) or inkjet (cheap to buy, better photographs).
- **Scanner** — dots per inch; 300 is a document, 1200 is a
  photograph, more is usually storage spent on nothing.
- **Keyboard and mouse** — the parts touched most, judged by comfort
  over eight hours rather than by any number at all.
- **Speakers or headphones** — where "good enough" arrives early and
  cheaply.
- **USB flash drive** — capacity, and the version (USB 3 moves a large
  folder in a minute, USB 2 in ten). See [[Backing Up Your Work]].

## Working from the person backwards

The method is always the same, and it is the same one
[[Interviewing Your Client]] teaches for software:

1. Ask what they will do with it, in their words. "Photo editing" and
   "photos" are different answers.
2. Find the one thing that will hurt first. For most people it is
   memory; for a photographer it is storage; for a gamer it is
   graphics.
3. Spend there. Meet the rest.
4. Say the trade-off out loud: what you gave up, and who would have
   noticed.

> [!example]- Two people, one budget
> A student writing essays and running Python: 16 GB of memory, a
> 512 GB SSD, integrated graphics, and the best screen and keyboard the
> budget allows — they will look at that screen for four years. A
> student editing video: same money, but shifted to a faster processor,
> dedicated graphics, and a 1 TB drive, on a heavier machine with worse
> battery life. Same total, opposite machines, both correct.

The vocabulary matters here as much as the judgement. Saying "16 GB of
RAM" when you mean storage does not merely sound wrong — it sends
somebody to buy the wrong machine.

%%curriculum-start%%
## Curriculum connection

![[C1.2]]

![[C1.3]]
%%curriculum-end%%
