---
title: Compound Angles
draft: false
created: __CREATED__
tags:
  - concepts
---
At the boards, the question was innocent: is
$\sin(a + b) = \sin a + \sin b$? Every group found a counter-example
within minutes — $a = b = \frac{\pi}{2}$ gives $\sin\pi = 0$ on the
left and $2$ on the right. Sine refuses to distribute. But the wreck
raised the better question: if not that, then *what*? The compound
angle formulas are the answer.

## The formulas and why you believe them

$$\sin(a \pm b) = \sin a \cos b \pm \cos a \sin b$$
$$\cos(a \pm b) = \cos a \cos b \mp \sin a \sin b$$

Note cosine's contrary streak: the sign in the middle flips. You
followed the development in class — distances on the unit circle,
nothing beyond Grade 10 tools — and you are not expected to reproduce
that derivation, but you are expected to *distrust and verify*: test
a formula numerically with angles you know before you lean on it.
That habit also catches the equivalences hiding in plain sight —
expand $\cos\!\left(\frac{\pi}{2} - x\right)$ and out falls $\sin x$,
which is why the graphs of sine and cosine are the same wave, shifted.

## Exact values you could not reach before

The special angles gave you exact values at multiples of
$\frac{\pi}{6}$ and $\frac{\pi}{4}$. Compound angles fill gaps
between them: any angle you can write as a sum or difference of two
special angles now has an exact value.

> [!example]- Worked: the exact value of $\cos\frac{\pi}{12}$
> $\frac{\pi}{12} = \frac{\pi}{3} - \frac{\pi}{4}$, so
> $$\cos\frac{\pi}{12} = \cos\frac{\pi}{3}\cos\frac{\pi}{4} + \sin\frac{\pi}{3}\sin\frac{\pi}{4} = \frac{1}{2}\cdot\frac{\sqrt{2}}{2} + \frac{\sqrt{3}}{2}\cdot\frac{\sqrt{2}}{2} = \frac{\sqrt{2}+\sqrt{6}}{4}$$
> Sanity check, the habit from [[Showing Your Thinking]]:
> $\frac{\pi}{12}$ is a small angle, so its cosine should be near 1 —
> and $\frac{\sqrt{2}+\sqrt{6}}{4} \approx 0.966$. It holds.

Set $a = b$ in the sum formulas and the **double angle formulas**
fall out for free — $\sin 2a = 2\sin a\cos a$ — a two-line derivation
worth doing yourself before [[Trigonometric Identities]] asks you to
wield it. [[Identities and Equations Practice]] starts with exact
values and builds from there.

%%curriculum-start%%
## Curriculum connection

![[B3.1]]

![[B3.2]]
%%curriculum-end%%
