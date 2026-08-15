---
title: Reading a Datasheet Like an Engineer
publish: true
created: __CREATED__
tags:
  - tutorials
enableToc: true
---
You already know what a datasheet is: the manufacturer's formal
statement of what a part will and will not do, valid only under the
conditions printed beside every figure. You can find pin 1, you know
that absolute maximum ratings are a fence rather than a target, and you
know the difference between a typical figure and a guaranteed one. Keep
all of that; none of it changes.

What changes this year is that you are no longer looking things up.
You are **choosing parts against a specification and defending the
choice**, and that work happens in the parts of the document a Grade 11
reader skips: the graphs at the back, the thermal table nobody reads,
the fine print under the conditions column, and a second document
called the errata sheet that most people do not know exists.

## The curves are where the design lives

A table gives you a number at one operating point. A curve gives you
the number everywhere else, and "everywhere else" is where your device
will actually spend its life.

| Curve | What it tells you | The mistake it prevents |
| --- | --- | --- |
| Power derating against ambient temperature | The rating is flat to a stated temperature, then slopes toward zero | Using the front-page power rating in a warm enclosure |
| Safe operating area | The combinations of voltage and current a transistor survives, and for how long | Assuming a part rated for both figures separately can do them together |
| On-resistance against temperature and gate voltage | A MOSFET driven at 3.3 V is a different part from one driven at 10 V | Designing with the headline on-resistance you cannot actually reach |
| Capacitance against DC bias | Many ceramic capacitors lose a large fraction of their value under the voltage they are rated for | A filter or bulk capacitor that is quietly a third of what the label says |
| Gain against frequency | An amplifier's usable gain falls as frequency rises | Expecting the DC gain figure at your signal's frequency |
| Dropout against load current | A regulator needs more headroom as it works harder | A rail that regulates at idle and collapses under load |

The capacitor one deserves a sentence of its own, because it catches
more people than the rest combined. High-value ceramic capacitors in
the common class II dielectrics — the ones with codes like X7R and X5R
— are voltage-dependent by nature. Put a capacitor rated 16 V on a 12 V
rail and you may retain well under half its nominal capacitance.
Nothing is faulty and nothing is being hidden; the derating curve says
so plainly, four pages in. The stable dielectrics do not do this, and
they are only available at much smaller values, which is exactly the
trade-off [[Component Selection and Tolerances]] is about.

## Thermal numbers, and the fine print under them

The thermal section usually gives a **junction-to-ambient thermal
resistance**, in degrees Celsius per watt. It is used like this:

$$T_J = T_A + P \times \theta_{JA}$$

Work a real case. A linear regulator takes 12 V in and produces 5.0 V
out at 200 mA. A linear regulator burns the difference, so

$$P = (V_{\text{in}} - V_{\text{out}}) \times I = (12\ \text{V} - 5\ \text{V}) \times 0.200\ \text{A} = 1.4\ \text{W}$$

Suppose its datasheet gives 60 °C/W for the package you have chosen —
that figure is an example, and yours must come from your own part's
table. Then the junction runs

$$\Delta T = P \times \theta_{JA} = 1.4\ \text{W} \times 60\ \text{°C/W} = 84\ \text{°C}$$

above ambient. On a 25 °C bench the junction sits near 109 °C, which is
under a typical 125 °C maximum and looks like a pass. Now put it in a
sealed box that reaches 45 °C inside and the junction is at 129 °C.
The design that passed on the bench fails in the product, and nothing
changed except the room.

> [!warning] That thermal resistance was measured on somebody else's board
> A junction-to-ambient figure is only meaningful with the test
> conditions attached, and they are always there in the fine print: a
> specified test board, a specified area of copper, still air. Solder
> the same part onto a small board with a thin trace and the real
> figure is worse — sometimes much worse. Treat the datasheet number
> as a best case, design with margin, and then *measure* the case
> temperature of the real assembly. That measurement belongs in your
> [[Tech Journal]] with the ambient and the run time beside it.

The honest engineering responses to the case above are all design
changes: drop the input voltage so there is less to burn, use a
switching regulator, add copper or a heatsink, or reduce the load. "It
is within the rating" is not on the list, for the reasons
[[Reliability and Derating]] sets out.

## Absolute maximums combine

The subtlest trap in the whole document. Every figure in the absolute
maximum table is individually true, and staying under each one
separately does not mean you are safe.

- A package has a **total power dissipation** limit that no individual
  pin rating mentions. Eight outputs each within their per-pin current
  limit can exceed it together.
- Many parts specify a **maximum current through the ground pin** or
  the supply pin, which caps the sum of everything the part is driving.
- Input voltages are frequently specified relative to the supply — an
  input that is legal at 5 V while the part is powered can destroy it
  when the supply is off and the input is still live. That is a real
  and common failure in systems where one board powers up before
  another.
- Storage temperature, soldering temperature, and ESD ratings are
  absolute maximums too, and the last one is why boards live in bags.

## The documents beside the datasheet

A datasheet is not the whole story, and knowing what else exists is
most of what separates a Grade 12 reader from a Grade 11 one.

- **Application notes.** The manufacturer's own worked designs, often
  containing the case the datasheet omitted and the layout advice that
  decides whether your version works.
- **Reference designs and evaluation board documentation.** A complete,
  tested schematic for a system built around the part, including the
  component values somebody already argued about.
- **The errata sheet.** For microcontrollers especially, a separate
  document listing the ways this silicon revision does *not* match its
  own datasheet, with workarounds. It is not embarrassing; it is
  normal, and it is essential. An afternoon spent chasing a peripheral
  that "should work" is frequently an afternoon somebody else already
  documented.
- **The revision history**, at the very back. Parameters change between
  datasheet revisions. If your design was built against an older
  revision, this page tells you whether it still holds.

## Reading for what is absent

Get in the habit of noticing silence.

- A parameter given only as *typical*, with no minimum or maximum, is
  the manufacturer declining to bound it. That is information. Leave
  more margin.
- A note saying a figure is *guaranteed by design* or *characterised,
  not production tested* means no part was individually measured
  against it.
- A missing timing figure in a bus interface means somebody has to go
  and measure it, and that somebody is you — with a scope, and with
  the conditions written down.
- A part number that appears in a distributor's catalogue but whose
  datasheet is marked as not recommended for new designs is a part
  that will be unavailable exactly when you need a second one.

> [!important] Design so it does not matter
> When the figure you want genuinely is not there, the strongest
> response is not to guess and not even to measure — it is to change
> the design so the answer stops mattering. A circuit whose
> correctness depends on an unspecified parameter has a hidden
> assumption in it, and hidden assumptions are what
> [[When Good Enough Is Not Safe]] is entirely about.

## Comparing two parts honestly

Half of [[Component Selection and Tolerances]] is comparison, and
comparisons go wrong in a predictable way: two datasheets quoting the
same-sounding parameter under different conditions.

Before you put two parts side by side, line up the conditions. Same
supply voltage, same temperature, same load, same measurement
definition. Then compare guaranteed limits with guaranteed limits and
typicals with typicals — never one against the other. If one vendor
publishes only a typical figure where the other publishes a maximum,
the honest comparison says so rather than quietly treating them as
equivalent.

Then record the comparison. Two candidate parts, the parameter that
decided it, the conditions, and one sentence on what the winner cost
you — that is a design decision in the form
[[Writing Documentation Somebody Can Build From]] expects, and it is
the thing somebody will ask you about at
[[The Engineering Review]].

%%curriculum-start%%
## Curriculum connection

![[A3.1]]

![[B2.1]]
%%curriculum-end%%
