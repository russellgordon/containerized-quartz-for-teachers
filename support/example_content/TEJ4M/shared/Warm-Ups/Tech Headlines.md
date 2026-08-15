---
title: Tech Headlines
publish: true
created: __CREATED__
tags:
  - warm-ups
enableToc: true
---
One current technology story, one minute of telling, and columns on the
board. Same routine as the last two years, with one more column — and
the new column is the one that turns a discussion into engineering.

Last year the standard was that the middle column had to contain a
number with a unit, or an honest admission that no number was
published. Keep that. This year we add: **what measurement would prove
this wrong?** A claim that cannot fail a test is not a specification,
whatever it is printed next to.

## The four columns

| Claimed | Specified | Falsified by | Who benefits |
| --- | --- | --- | --- |
| What the headline says, in its own words | The number, its unit, and the conditions it was measured under | The measurement that would settle it, and who could run it | Who is better off if you believe it before it is proven |

## How to run it

1. One student from the rotating roster brings the story and tells it
   in about a minute. No screen — if it cannot be told, it was not
   understood.
2. The class fills columns one and four quickly. Then the slow work:
   columns two and three, which are where the argument lives.
3. Where column two is empty, say so out loud. "No conditions were
   published" is a finding, not a failure.
4. Close with a single sentence naming the test. If nobody in the room
   can describe a test that would settle it, that is the most
   interesting possible result and worth sitting with.

## Specification or advertising

By now you have read enough datasheets to know what a real
specification looks like: a value, a unit, a min or typ or max label,
and a conditions column in small type. Hold technology claims to the
same standard and most of them fall over immediately.

Four questions do nearly all the work.

- **Under what conditions?** Every honest figure has them. A range
  measured at 20 °C, a speed at a stated workload, a battery life at a
  stated brightness. "Up to" is the phrase that means the conditions
  were chosen to flatter.
- **Typical or guaranteed?** A typical figure describes a good sample
  on a good day. A guaranteed minimum is a promise somebody can be
  held to. Marketing quotes the first and lets you assume the second —
  the exact trap [[Reading a Datasheet Like an Engineer]] trains you
  out of.
- **Compared against what?** "Twice as efficient" is meaningless
  without the baseline, and the baseline is frequently the vendor's own
  previous product, chosen because it was weak.
- **Measured by whom?** A manufacturer's own bench, an independent
  laboratory, or a certification body testing to a published standard
  are three very different levels of evidence, and the third one is
  the reason [[Standards and Professional Practice]] exists.

> [!example]- A worked round
> The claim: a new microcontroller family is announced with "ten times
> lower power than the previous generation".
>
> **Claimed:** ten times lower power. **Specified:** almost certainly
> a sleep-mode current, in microamps, at one supply voltage and one
> temperature, with most peripherals disabled. Ten times lower *than
> what* is the question — usually than the same vendor's older part,
> in the same mode. **Falsified by:** running a realistic duty cycle
> on both parts on the same bench, measuring average current over a
> full wake-sleep-wake period at the same supply voltage, and
> comparing the energy per useful operation rather than the current in
> the deepest sleep state. **Who benefits:** the vendor, and every
> designer who now has a headline number to quote to their manager.
>
> Notice the claim may well be *true*. Ten times lower sleep current
> is a real engineering achievement. It also may not change your
> battery life at all, if your device spends most of its energy awake.
> Both of those things are true at once, and holding them together is
> the whole skill.

## One variation

Bring two write-ups of the same announcement from different outlets
and fill the columns twice. Watching the *specified* column sit
perfectly still while the *claimed* column swings from "breakthrough"
to "incremental" is the entire lesson, delivered without anybody having
to argue for it.

> [!question] Who benefits is a question, not a verdict
> Sometimes the honest answer is "everyone" — real improvements do get
> announced, and cynicism is not analysis. The habit is asking every
> single time, so that the once it matters, it has already been asked.
> That same standard runs through [[Writing About Technology]], and
> you will be on the receiving end of it at
> [[The Engineering Review]], where somebody will ask what conditions
> *your* number was measured under.[^1]

[^1]: The battery genre remains the reigning champion of this
    exercise, because two different achievements get measured in two
    different units and reported as if they were one. A cell that
    accepts charge quickly is a claim about power, in watts. A cell
    that holds a lot of charge is a claim about energy, in watt-hours.
    A headline that praises the first while implying the second has
    not lied, exactly, and knowing the difference costs you nothing
    but pays every time.
