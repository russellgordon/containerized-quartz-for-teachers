---
title: Breadboard a Circuit
draft: false
created: __CREATED__
tags:
  - labs
enableToc: true
---
Your first circuit: a power source, a resistor, an LED, and light you
caused on purpose. The resistor is not decoration — an LED holds its
voltage near $2\ \text{V}$ and draws whatever current it can get
until it destroys itself, and $V = IR$ is how you decide the current
instead. [[Electronics Fundamentals]] carries the ideas, and
[[Predict the Circuit]] has been rehearsing you for this bench.

> [!danger] Safety notes
> **Only the low-voltage bench supply or battery pack provided** —
> nothing on this breadboard ever touches wall power. **A hot
> component means power off first, questions second** — a part too
> hot to touch is a fault announcing itself, per
> [[Safety in the Lab]]. **Clipped leads fly** — safety glasses when
> trimming, and swept ends before they hide in the board.

## What you need

- [ ] Breadboard and jumper wires
- [ ] One LED and one $220\ \Omega$ resistor (check the colour bands)
- [ ] $5\ \text{V}$ bench supply or battery pack
- [ ] Multimeter, safety glasses, journal for a circuit sketch

## The work

1. **Learn the breadboard's geography first.** Each row of five holes
   is one connected strip; the long side rails carry power; the
   centre channel splits the halves. Two legs in one strip are
   already wired together — that fact builds circuits and causes
   half of all faults.
2. **Sketch the circuit**: supply, resistor, LED, back to supply.
   One loop — if you cannot draw it, the board will not find it.
3. **Justify the resistor with $V = IR$.** The supply gives
   $5\ \text{V}$, the LED keeps about $2\ \text{V}$, so the resistor
   drops $3\ \text{V}$ while passing a safe $15\ \text{mA}$:
   $R = 3\ \text{V} / 0.015\ \text{A} = 200\ \Omega$, and
   $220\ \Omega$ is the nearest standard part. That arithmetic is
   why the LED survives.
4. **Build with power disconnected.** Rail to resistor to LED — long
   leg toward positive, flat side toward negative. Polarity matters;
   an LED is a one-way part.
5. **Trace the loop with a finger, then connect power.** Light means
   the loop is complete and the current is the one you chose.
6. **Measure the truth.** Multimeter across the LED, then across the
   resistor — the two voltages should sum to the supply. Prediction
   confirmed by instrument is [[Electronics Calculations Practice]]
   made physical.

## What can go wrong

- **Nothing lights, quietly.** Most often the LED is backwards — no
  harm done; flip it. Next most often, two legs meant to meet are in
  different five-hole strips. Geography again.
- **Bright flash, then nothing, ever.** The resistor was bypassed or
  misread, and the LED took unlimited current. Read colour bands
  twice; the parts bin is not infinite.
- **The meter reads nonsense.** Check the meter's own dial and probe
  sockets — instruments are honest, but only about what you
  actually asked.

## Level up

Add a second LED and decide: in series, or in its own parallel
branch? Predict each arrangement's brightness with $V = IR$ before
powering up — then let the board grade your prediction.

%%curriculum-start%%
## Curriculum connection

![[B2.1]]

![[B2.5]]
%%curriculum-end%%
