---
title: VSEPR Shapes
draft: false
created: __CREATED__
enableToc: true
tags:
  - reference
  - structure
---
The lookup sheet for [[Molecular Shapes]]. Count the electron domains
around the central atom, count how many of them are lone pairs, and read
the row.

## Counting domains

One **electron domain** is one region of electron density around the
central atom.

| Feature on the central atom | Domains it contributes |
| --- | --- |
| A single bond | 1 |
| A double bond | 1 |
| A triple bond | 1 |
| A lone pair | 1 |

Multiple bonds count once because the extra pairs occupy the same region
of space and point the same way. This is the rule people forget, and it
is the reason carbon dioxide is linear.

Procedure: draw the Lewis structure, count the domains on the central
atom, count how many are lone pairs, read the table, and then **delete
the lone pairs from the picture** — the molecular shape is the
arrangement of the atoms alone.

## The table

$\text{A}$ is the central atom, $\text{X}$ a bonded atom, $\text{E}$ a
lone pair.

| Domains | Lone pairs | Type | Electron-domain geometry | Molecular shape | Ideal angles | Example |
| --- | --- | --- | --- | --- | --- | --- |
| 2 | 0 | $\ce{AX2}$ | linear | linear | 180° | $\ce{CO2}$ |
| 3 | 0 | $\ce{AX3}$ | trigonal planar | trigonal planar | 120° | $\ce{SO3}$ |
| 3 | 1 | $\ce{AX2E}$ | trigonal planar | bent | slightly under 120° | $\ce{SO2}$ |
| 4 | 0 | $\ce{AX4}$ | tetrahedral | tetrahedral | 109.5° | $\ce{CH4}$, $\ce{NH4+}$ |
| 4 | 1 | $\ce{AX3E}$ | tetrahedral | trigonal pyramidal | about 107° | $\ce{NH3}$ |
| 4 | 2 | $\ce{AX2E2}$ | tetrahedral | bent | about 104.5° | $\ce{H2O}$ |
| 5 | 0 | $\ce{AX5}$ | trigonal bipyramidal | trigonal bipyramidal | 90° and 120° | $\ce{PCl5}$ |
| 5 | 1 | $\ce{AX4E}$ | trigonal bipyramidal | seesaw | under 90° and 120° | $\ce{SF4}$ |
| 5 | 2 | $\ce{AX3E2}$ | trigonal bipyramidal | T-shaped | under 90° | $\ce{ClF3}$ |
| 5 | 3 | $\ce{AX2E3}$ | trigonal bipyramidal | linear | 180° | $\ce{XeF2}$ |
| 6 | 0 | $\ce{AX6}$ | octahedral | octahedral | 90° | $\ce{SF6}$ |
| 6 | 1 | $\ce{AX5E}$ | octahedral | square pyramidal | under 90° | $\ce{BrF5}$ |
| 6 | 2 | $\ce{AX4E2}$ | octahedral | square planar | 90° | $\ce{XeF4}$ |

A molecule of only two atoms is **linear** whatever else is true, so
$\ce{O2}$, $\ce{N2}$, and $\ce{HCl}$ need no row.

## Why the angles shrink

A lone pair is held by one nucleus only, so it spreads out more than a
bonding pair held between two. It therefore takes more room and pushes
harder:

$$\text{lone--lone} > \text{lone--bonding} > \text{bonding--bonding}$$

Read down the four-domain block of the table and you can watch it
happen: 109.5°, then about 107° with one lone pair, then about 104.5°
with two. Each lone pair squeezes the remaining bonds a little closer
together.

A double or triple bond is slightly fatter than a single bond for the
same reason, so it squeezes its neighbours too — which is why
formaldehyde's H–C–H angle is a little under 120° rather than exactly
120°.

> [!note] Why lone pairs go equatorial in a trigonal bipyramid
> A trigonal bipyramid has two kinds of position: three **equatorial**
> around the middle and two **axial** at top and bottom. They are not
> equivalent, and lone pairs always take the equatorial positions.
>
> An equatorial position has two close neighbours at 90°; an axial
> position has three. Since a lone pair repels most strongly, it goes
> where it has the fewest close neighbours to shove. That single fact
> generates the seesaw, the T-shape, and the linear arrangement in the
> table above — otherwise those three rows would have to be memorised.

## Reading polarity off this table

A molecule is non-polar when every bond dipole cancels, and the table
tells you when the geometry allows it. The symmetric arrangements are:

| Type | Shape | Non-polar if all outer atoms are identical |
| --- | --- | --- |
| $\ce{AX2}$ | linear | yes |
| $\ce{AX3}$ | trigonal planar | yes |
| $\ce{AX4}$ | tetrahedral | yes |
| $\ce{AX5}$ | trigonal bipyramidal | yes |
| $\ce{AX6}$ | octahedral | yes |
| $\ce{AX2E3}$ | linear | yes |
| $\ce{AX4E2}$ | square planar | yes |

Every other row in the main table is polar when the bonds are polar.
Note the last two entries: those two shapes have lone pairs and are
*still* symmetric, because the lone pairs themselves sit opposite each
other. Replace even one outer atom with a different element in any row
and the cancellation is destroyed. The full argument is in
[[Polarity]].

## What this sheet cannot tell you

VSEPR predicts geometry. It does not predict bond length, bond strength,
colour, magnetism, or reactivity, and it does not explain why the bonds
exist. It also fails on $\ce{O2}$, whose Lewis structure suggests all
electrons are paired when the molecule is measurably paramagnetic.

Use it for what it is: a fast, accurate way of getting from a count to a
shape. Practise the count in
[[Shapes and Polarity Practice]].
