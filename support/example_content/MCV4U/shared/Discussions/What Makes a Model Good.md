---
title: What Makes a Model Good
publish: true
created: __CREATED__
tags:
  - discussions
---
At the boards, someone fits a curve through every point of a braking
car's position data — six radar readings, a degree-five polynomial
that misses nothing — and announces "perfect fit". Is it a good
model? Differentiate it. The velocity that falls out of the perfect
fit wiggles: it claims the car *sped up* twice in the middle of
braking, something no driver did and no brake can do. Meanwhile the
group beside them has a plain constant-deceleration model that
misses every single point by a little — and its velocity says the
one thing that must be true: steadily down, through zero, then stop.
Between "passes through the points" and "tells the truth about the
motion" runs the gap this conversation is about, and calculus makes
the gap visible in a way nothing before it could: differentiation
*amplifies* wiggles. A model can hide its lies in its values and
still confess them in its rates.

Questions worth arguing about:

1. What exactly has the perfect-fitter shown, and what have they not?
   Is hitting every data point evidence of *anything*?
2. The plain model's parameters mean something: one is the speed the
   car was doing when the brakes bit, the other is how hard they
   bit. Why does a model whose knobs have *names* deserve more trust
   than one whose knobs do nothing but fit?
3. Every model has an expiry: the braking model dies the moment the
   car stops — trust it past that and it predicts the car reversing
   into the distance. Whose job is it to say where a model stops
   being true — the equation's, or the person wielding it?
4. When is simple-but-slightly-wrong the *better* choice than
   complicated-but-close? Would you rather the court weighing a
   speeding ticket trusted the first kind or the second?
5. "All models are wrong, but some are useful." Prosecute or defend
   this claim — and decide what "useful" has to mean for it to
   survive.

This stops being talk at [[The Speed Camera]] and [[Smooth Landing]],
where your group must choose a model, defend every parameter, and
say out loud where it stops deserving belief — with its derivatives
called as witnesses. The habit of asking what a graph's shape
*claims* starts small, every morning, in [[Graph Talks]].
