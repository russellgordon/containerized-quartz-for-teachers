---
title: The Prediction Contest
publish: true
created: __CREATED__
tags:
  - labs
enableToc: true
---
Two resistors, two arrangements, one supply — and no meter switched on
until every bench has committed, in pen, to a total current and to what
each resistor is doing. Then we power up, and the circuit settles it.

This is [[Predict the Circuit]] played for the whole period, and it is
scored: closest prediction takes the round, but a bench that is wrong and
can explain *why* takes the argument. Being wrong for a stated reason is
how measurement improves a model. Being right by luck teaches nobody
anything.

> [!danger] Safety notes
> **Bench supply set to $9.00\ \text{V}$, current limit at about
> $100\ \text{mA}$** — set the limit before the first connection.
> **Rewire only with the supply off.** In the parallel round the total
> current is more than four times the series round, and moving one wire
> live is how a meter still set to a low current range gets destroyed.
> **The meter goes in series for current, in parallel for voltage** —
> and the red lead comes out of the current jack the moment you are done
> with it. **Check power ratings before energising**: at $9\ \text{V}$
> a $1.0\ \text{k}\Omega$ resistor dissipates
> $P = V^2 / R = 81 / 1000 = 0.081\ \text{W}$, which a quarter-watt part
> handles. Do that calculation every time, not just when we ask.

## What you need

- [ ] Bench supply, set and verified at $9.00\ \text{V}$
- [ ] One $1.0\ \text{k}\Omega$ and one $2.2\ \text{k}\Omega$ resistor,
      both quarter-watt, both measured before use
- [ ] Breadboard, jumper wires, multimeter, safety glasses
- [ ] Your journal, open, with the prediction table already drawn

## Round one — in series

1. **Draw it first.** Supply, $1.0\ \text{k}\Omega$,
   $2.2\ \text{k}\Omega$, back to supply. One loop.
2. **Predict, using measured resistor values.** The current is the same
   everywhere in a single loop, so the two resistors behave as their sum:
   $R = 3.2\ \text{k}\Omega$ and
   $I = 9.00\ \text{V} / 3200\ \Omega = 2.81\ \text{mA}$. The voltage
   across each is that current times its own resistance:
   $2.81\ \text{V}$ and $6.19\ \text{V}$.
3. **Predict the check, too.** Those two drops should add to the supply
   voltage. Write down what you expect them to sum to before you find
   out.
4. Build it, power it, and measure: total current, then each voltage.

## Round two — in parallel

5. **Power off. Rewire** so both resistors sit directly across the
   supply, each in its own branch.
6. **Predict.** Each branch sees the full $9.00\ \text{V}$, so
   $I_1 = 9.00 / 1000 = 9.00\ \text{mA}$ and
   $I_2 = 9.00 / 2200 = 4.09\ \text{mA}$, and the supply must deliver
   both, so $13.09\ \text{mA}$ in total. Equivalently the pair behaves
   as $687.5\ \Omega$.
7. **Predict which branch gets more current, and say why in words** — a
   sentence, not a formula. If you cannot say it in words, you do not
   understand it yet.
8. Build it, power it, and measure each branch current and the total.

## Results

| Round | Quantity | Predicted | Measured | Difference (%) |
| --- | --- | --- | --- | --- |
| Series | Total current (mA) | 2.81 | | |
| Series | $V$ across $1.0\ \text{k}\Omega$ (V) | 2.81 | | |
| Series | $V$ across $2.2\ \text{k}\Omega$ (V) | 6.19 | | |
| Series | Sum of the two drops (V) | 9.00 | | |
| Parallel | Current in $1.0\ \text{k}\Omega$ (mA) | 9.00 | | |
| Parallel | Current in $2.2\ \text{k}\Omega$ (mA) | 4.09 | | |
| Parallel | Total supply current (mA) | 13.09 | | |

The predicted column is filled in here so nobody loses the period to
arithmetic. Do the arithmetic anyway, from *your* measured resistor
values, and write your own numbers beside these. Where yours differ from
the table, yours are the better prediction — and you should be able to
say by how much and why.

## Predicted against measured

Two of the rows above are not really predictions at all; they are laws
being tested. The series drops summing to the supply voltage, and the
branch currents summing to the total, are Kirchhoff's two laws, and if
your measurements break them the fault is in your bench, not in physics.
Chase it: a loose lead, a meter left in the wrong range, or a branch that
is not connected where you think it is.

For every row, name the cause of the gap. Tolerance, supply accuracy,
burden voltage, and contact resistance are all on the table again — see
[[Measure a Circuit]] for what each one does to your numbers.

## The question that matters

In the parallel round, the pair of resistors together drew more current
than either one alone, and behaved like a resistance *smaller* than
either of them. Explain that to somebody who finds it obviously wrong.
Then answer the follow-up: if you added a third resistor in parallel,
what happens to the total current, and what happens to the supply's
current limit?

%%curriculum-start%%
## Curriculum connection

![[A3.3]]

![[B3.2]]

![[B3.3]]
%%curriculum-end%%
