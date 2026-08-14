---
title: The Other Three Ratios
draft: false
created: __CREATED__
tags:
  - concepts
enableToc: true
---
Sine, cosine, and tangent each have a reciprocal, and the reciprocals
have names. They add no new information — every one of them is a
fraction you could already write — but they make certain expressions
short enough to work with, which is the entire reason they exist.

## The definitions

For an angle in a right triangle, with the usual opposite, adjacent, and
hypotenuse:

$$\csc\theta = \frac{\text{hyp}}{\text{opp}} = \frac{1}{\sin\theta}
\qquad
\sec\theta = \frac{\text{hyp}}{\text{adj}} = \frac{1}{\cos\theta}
\qquad
\cot\theta = \frac{\text{adj}}{\text{opp}} = \frac{1}{\tan\theta}$$

The pairing is deliberately awkward: **cosecant goes with sine** and
**secant goes with cosine**, not the way the first letters suggest.
Everybody gets this wrong once. The way to remember it is the third
letter — co**s**ecant pairs with **s**ine, **sec**ant pairs with
**c**osine.

Since they are reciprocals, each is undefined wherever its partner is
zero. $\csc\theta$ has no value at $0^\circ$ or $180^\circ$, because
$\sin\theta = 0$ there and nothing divides by zero.

## The identities worth knowing

An **identity** is an equation true for every value of the variable, as
opposed to an equation you solve for particular values. Three of them
carry most of the work:

$$\sin^2 x + \cos^2 x = 1 \qquad\qquad \tan x = \frac{\sin x}{\cos x}
\qquad\qquad \cot x = \frac{\cos x}{\sin x}$$

The first is the Pythagorean theorem in disguise: on the unit circle a
point is $(\cos x, \sin x)$ and its distance from the origin is 1.

## Proving one

The method is fixed, and following it is most of the marks:

1. Work with **one side only** — the messier one — and transform it
   until it becomes the other. Never move terms across the equals sign;
   you are not solving, you are showing two expressions are the same
   thing written differently.
2. Convert everything to sines and cosines. It is dull and it nearly
   always works.
3. Look for the Pythagorean identity, in either direction.
4. Simplify the fraction.

$$\text{Prove } \frac{\cos x}{\sin x}\cdot \tan x = 1$$

Left side, in sines and cosines:

$$\frac{\cos x}{\sin x}\cdot\frac{\sin x}{\cos x} = 1$$

which is the right side. Done — and the layout matters: each line
follows from the one above, and a reader can check every step without
asking you what you did.

> [!tip] What makes a proof fail
> Working on both sides at once and meeting in the middle looks
> convincing and proves nothing, because you assumed the thing you were
> proving. If you get stuck, start from the other side instead — it is
> allowed, and it is often much easier.

## Where the reciprocals earn their keep

Rarely in this course, and constantly in calculus: derivatives and
integrals of trigonometric functions come out in terms of $\sec$ and
$\csc$, and an expression written with them is short where the same
thing written with fractions is unreadable. For now, the value is
recognising them when they appear in [[Special Angles]] work and in
anything you read ahead into.

%%curriculum-start%%
## Curriculum connection

![[D1.4]]

![[D1.5]]
%%curriculum-end%%
