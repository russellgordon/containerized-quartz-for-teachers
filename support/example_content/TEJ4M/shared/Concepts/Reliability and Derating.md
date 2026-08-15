---
title: Reliability and Derating
publish: true
created: __CREATED__
tags:
  - concepts
---
The dead board on the bench in [[The Failure Autopsy]] did not fail
because somebody wired it wrong. It worked for months. Then a resistor
that had been quietly running at 90% of its rating spent one warm
afternoon at 100% of it, and the device that depended on it stopped
being a device. Nobody made a mistake you could point at in a
schematic. That is exactly the kind of failure this year is about.

## Rated is not the same as safe

A component's rating is the manufacturer's statement of where it stops
being guaranteed — at a stated temperature, in still air, with the
lead lengths and copper area their test assumed. It is a fence, not a
target. Design at the fence and everything that varies in the real
world — ambient heat, supply tolerance, an enclosure with no
ventilation, the part itself being at the edge of its own tolerance —
pushes you over it.

**Derating** is the deliberate practice of using a component well
below its rating so that ordinary variation cannot reach the limit. A
common starting point in student work:

| Component | Common derating | Why |
| --- | --- | --- |
| Resistors | Use at 50% of rated power or less | Rating assumes 25 °C in still air |
| Capacitors (electrolytic) | Use well under the rated voltage | Life falls sharply near the limit |
| Semiconductors | Keep junction temperature far below maximum | Life and failure rate track temperature |
| Connectors and wire | Below rated current | Contact resistance turns current into heat |

Those are engineering habits, not magic numbers: the real figure for a
real part comes from its own datasheet and its derating curve, which
is why [[Reading a Datasheet Like an Engineer]] is a Grade 12 tutorial
rather than a Grade 11 one.

## Doing the arithmetic

A 220 Ω resistor carrying 30 mA dissipates

$$P = I^2R = (0.030\ \text{A})^2 \times 220\ \Omega \approx 0.198\ \text{W}$$

which is 79% of a quarter-watt part. It will work on the bench and it
will run hot in a box in July. The design answer is not "it's within
spec" — it is a half-watt part, or less current, or both.

- [ ] Compute the dissipation of every resistor that carries real
      current, not just the ones you suspect.
- [ ] Compare against the rating, then halve it and compare again.
- [ ] Write the margin into your build log — a number you can defend
      at a design review beats a shrug.

> [!warning] Heat is the quiet killer
> Most electronic failures that look sudden were slow. Electrolytic
> capacitors dry out faster when hot; semiconductor life falls as
> junction temperature rises; solder joints crack under repeated
> thermal cycling. If part of your circuit is warm enough to notice
> with a fingertip, that is data — find out why before you box it up.

## What this buys you

Reliability is not a feature you add at the end; it is the accumulated
result of margins you chose early. When
[[The Engineering Design Project]] asks you to defend a component
choice, "it is rated for it" is a Grade 11 answer. The Grade 12 answer names the worst case you
designed for, the margin you left, and the measurement that confirmed
it — the habit [[Power and Regulation Practice]] drills and
[[Writing a Specification]] makes contractual.

%%curriculum-start%%
## Curriculum connection

![[A3.1]]

![[A3.3]]

![[A3.5]]
%%curriculum-end%%
