---
title: Predict the Circuit
publish: true
created: __CREATED__
tags:
  - warm-ups
enableToc: true
---
A schematic goes up, same as always. In Grade 11 the question was how
much current flows and what voltage sits across each part, and you
committed to those numbers before anybody touched a supply. Those
questions are still fair game, and you should be able to answer them
without slowing down.

The Grade 12 question is different in kind. It is not *how much* — it
is **what does this do over time, and what does it do when the world
is not ideal**. Predict the shape on the screen. Predict what the rail
does when the load switches on. Predict what happens as the enclosure
warms up. Then we measure, and the disagreement is the lesson.

## How to run it

1. Show the schematic with every value marked, plus one condition that
   is not ideal — a supply with lead resistance, a load that switches,
   an ambient temperature. Two quiet minutes; predictions in writing.
2. Everyone commits to a *behaviour*: a sketch of the waveform with
   both axes labelled, or a rail voltage before and after the load
   turns on, with numbers.
3. Collect predictions before any discussion. The spread is the hook.
4. Measure — scope for anything that changes, meter for anything that
   does not. Compare, then chase the disagreement until somebody can
   name the component that caused it.

## What a prediction has to contain now

Three things, and an answer missing any one of them is not yet a
prediction.

- **The quantity, with its unit.** Unchanged from last year, and still
  the thing most often skipped.
- **The condition it is true under.** Supply setting, load state,
  temperature, whether the motor is running. A number without its
  condition cannot be checked, so it also cannot be wrong.
- **The margin.** How far is this from a limit? "About 14 mA, and the
  part is good for 30 mA, so I am at less than half" is a prediction
  with engineering in it.

The workhorse relationship for anything with a capacitor in it is the
time constant, which is what turns a schematic into a shape:

$$\tau = RC \qquad \text{one } \tau \text{ reaches about } 63\% \text{ of the way; five } \tau \text{ is settled}$$

> [!example]- A worked round — same circuit, two answers
> On screen: a square-wave source, a 10 kΩ resistor in series, a
> 100 nF capacitor to ground, and the scope probe on the capacitor.
> First, the time constant is $\tau = RC$, which here comes to 1 ms.
>
> Drive it at 100 Hz and each half-cycle lasts 5 ms, which is five
> time constants — the capacitor has time to arrive. You should
> predict a square wave with visibly rounded corners that still
> reaches both rails. Drive the *same circuit* at 5 kHz and each
> half-cycle lasts 100 µs, a tenth of a time constant. The capacitor
> barely moves before the drive reverses, so you should predict a
> small, roughly triangular ripple sitting near the middle of the
> supply — amplitude down by more than a factor of ten.
>
> Nothing on the schematic changed. The circuit did not become a
> different circuit; you asked it a different question. That is what
> [[Filters and Noise]] is about, and it is why a prediction that
> does not name a frequency is only half a prediction.

## Predicting a supply that is not ideal

The other half of this routine has no waveform in it at all. A rail is
only 5 V until something draws current through the resistance of the
wire, the connector, and the supply's own output.

Take a bench supply set to 5.00 V feeding a board through leads and a
connector that together measure about 2 Ω. With the board idling at
20 mA, the drop is 40 mV and nobody notices. Switch on a load that
draws 500 mA and the drop becomes

$$V_{\text{drop}} = I R = 0.500\ \text{A} \times 2\ \Omega = 1.0\ \text{V}$$

so the board now sees 4.0 V, and a microcontroller that needs a
minimum supply voltage resets. The supply's front panel still says
5.00 V, because that is where it is regulating — at *its* terminals,
not at your circuit. This is the single most common "it works until
the motor starts" fault in this course, and predicting it before you
build is worth more than diagnosing it afterwards. The habits that
prevent it live in [[Bench Power Supply Habits]] and
[[Power Supplies and Regulation]].

## One variation

Reverse it into design, the way [[The Specification]] will. Name a
requirement — "the rail must stay above 4.6 V with a 500 mA load
stepping on and off at 10 Hz" — and have everyone produce one design
change that would meet it, plus the measurement that would prove it.
Thicker leads, remote sensing, a local bulk capacitor, a separate
supply for the motor: four different answers, all defensible, and the
argument about which is best is the whole point.

> [!tip] A prediction you cannot be wrong about is not a prediction
> "It should be fine" survives every measurement, which is exactly
> what makes it worthless. Say the number, say the condition, say the
> margin — then, when the scope disagrees, you will know which of the
> three was wrong. That is also the standard your
> [[Tech Journal]] applies to every bench day.
