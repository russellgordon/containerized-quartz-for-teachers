---
title: Series and Parallel Circuits
publish: true
created: __CREATED__
tags:
  - concepts
  - unit-5
---
Two ways to connect components, with opposite consequences.

## Series: one path

$$R_{total} = R_1 + R_2 + \dots$$

- The same current passes through everything.
- The voltages across the components add to the supply voltage.
- Break the loop anywhere and everything stops — which is why old
  fairy lights all went out together.

## Parallel: several paths

$$\frac{1}{R_{total}} = \frac{1}{R_1} + \frac{1}{R_2} + \dots$$

- Every branch has the SAME voltage across it.
- The currents in the branches add to the total from the supply.
- Total resistance is always LESS than the smallest branch, because you
  have added another route.

House wiring is parallel: every socket gets the full 120 V, and switching
off a lamp leaves the fridge running.

> [!example] Why the kettle dims the lights
> Adding a high-current appliance raises the total current through the
> supply wiring, and the small voltage drop along that wiring leaves
> slightly less for everything else. The lights recover a moment later —
> that flicker is Ohm's law happening in your walls.

%%curriculum-start%%
## Curriculum connection

![[F2.3]]

![[F3.6]]
%%curriculum-end%%
