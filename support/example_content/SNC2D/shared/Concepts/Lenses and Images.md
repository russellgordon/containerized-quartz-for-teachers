---
title: Lenses and Images
publish: true
created: __CREATED__
enableToc: true
tags:
  - concepts
  - optics
---
In [[Finding the Focal Length]] you wrote down a prediction, then moved a lens
until a sharp picture of the window appeared on the card — upside down, and
smaller than the window. Two facts were established in that moment and this
page explains both: a lens can put an image somewhere in mid-air where a
screen can catch it, and that image can be inverted.

## A lens is refraction, twice

There is nothing new in a lens. It is a piece of glass with curved surfaces,
and the light refracts on the way in and again on the way out, following
exactly the rule from [[Refraction]].

What the curve does is give every part of the surface a differently angled
normal. A ray arriving near the edge of a converging lens meets the glass at a
large angle of incidence and is bent a great deal; a ray arriving near the
centre meets it almost head-on and is barely bent at all. The shape is chosen
so that a whole bundle of parallel rays is bent by just the right amount to
arrive at the same point.

A **converging** lens is thicker in the middle than at the edges. Parallel
rays entering it are brought together at the **focal point**, $F$, and the
distance from the lens to that point is the **focal length**, $f$ — the
quantity you measured. A **diverging** lens is thinner in the middle, spreads
parallel rays apart, and they leave as though they had come from a focal point
on the side the light arrived from.

A fatter curve bends light more, so it has a shorter focal length. That is the
whole of what "a stronger lens" means.

## The three rays that locate any image

To find where an image forms, you do not trace all the light. You trace the
three rays whose behaviour you already know, and where they meet is where
every other ray meets too.

For a converging lens, from a single point on the top of the object:

1. A ray travelling **parallel to the axis** is refracted through $F$ on the
   far side.
2. A ray passing through the **optical centre** of the lens carries straight
   on, because at the centre the two surfaces are parallel and the ray emerges
   travelling in its original direction.
3. A ray passing through the **near focal point** emerges **parallel** to the
   axis — rule 1 run backwards.

Two rays are enough to fix the point; the third is your check, and drawing it
costs nothing.

If the three rays **converge** on the far side, they have actually met there:
that is a **real** image, light is genuinely arriving at that spot, and a
screen placed there shows it. That is what happened on your card.

If the rays leave the lens **spreading apart**, they never meet. Extend them
backwards as dashed lines and they appear to come from a point on the same
side as the object: that is a **virtual** image. No screen will show it,
because no light ever goes there — but your eye, which cannot tell where light
has really been, sees it perfectly well. That is a magnifying glass.

## Where the image lands, and what it looks like

Everything depends on one comparison: the object's distance from the lens,
against $f$ and $2f$.

| Object position (converging lens) | Image type | Orientation | Size | Where the image is |
| --- | --- | --- | --- | --- |
| Beyond $2f$ | Real | Inverted | Smaller | Between $F$ and $2F$, far side |
| At $2f$ | Real | Inverted | Same size | At $2F$, far side |
| Between $f$ and $2f$ | Real | Inverted | Larger | Beyond $2F$, far side |
| At $f$ | No image | — | — | Rays emerge parallel and never meet |
| Closer than $f$ | Virtual | Upright | Larger | Same side as the object |
| Any position, diverging lens | Virtual | Upright | Smaller | Same side as the object, within $f$ |

Read the first row against your investigation. The window was many metres
away, far beyond $2f$, so the theory predicts a real, inverted, much smaller
image close to the focal point — which is exactly the small upside-down
window you caught on the card, and it is why moving the card a few centimetres
past the sharp point blurred it so quickly.

The algebra says the same thing. The thin lens equation is $\frac{1}{f} = \frac{1}{d_o} + \frac{1}{d_i}$ and the magnification is $M = \frac{h_i}{h_o} = -\frac{d_i}{d_o}$.

The **sign convention used on this page** — say which one you are using, since
textbooks differ — is that $d_o$ is positive for a real object in front of the
lens; $d_i$ is **positive** when the image forms on the opposite side from the
object, which is where real images are, and **negative** when it forms on the
same side, which is where virtual images are; $f$ is positive for a converging
lens and negative for a diverging one. A negative $M$ therefore means the
image is inverted, and a magnitude greater than one means it is enlarged.

Notice the convention is not identical to the mirror one in [[Reflection]],
and it cannot be — for a mirror the light stays on one side, and for a lens it
goes through. In both cases the rule is the same underneath: a *real* image
distance is positive, and real images form where the light actually goes.

Your eye runs the first row of that table continuously. The cornea does most
of the bending and the lens behind it fine-tunes by changing shape, so a real,
inverted, reduced image lands on the retina; what you experience as "the right
way up" is your brain's interpretation of an upside-down image it has never
seen any other way. A camera does the same job by moving a lens instead of
reshaping one.

## Refraction you can see without a lab

The same properties of light explain a set of things you have been looking at
all your life.

**A rainbow.** Sunlight entering a raindrop refracts on the way in, reflects
from the inside of the back surface, and refracts again on the way out.
Because the index of water is slightly different for each colour, the colours
leave at slightly different angles — red emerging at about 42° from the
direction directly opposite the Sun, violet at about 40°. Every drop does
this, but from where you stand only the drops at the right angle send their
red to your eye, and a different set send their violet, so the colours arrive
from different parts of the sky as an arc. This is also why the bow is always
opposite the Sun, why you need the Sun behind you, and why nobody else sees
quite the same rainbow you do.

**A mirage on a hot road.** Air just above sun-heated asphalt is much hotter,
and therefore less dense, than the air a metre up, and its index of refraction
is slightly lower. Light from the sky heading down at a shallow angle passes
through a continuous gradient rather than one sharp boundary, so it bends
gradually, curving until it is heading back upward into your eye. Trace it
back in a straight line, as your brain insists on doing, and the sky appears
to be lying on the road — which looks like a puddle of water, because the sky
is what a puddle would reflect.

**Shimmering** above a fire or a hot roof is the unsteady version of the same
thing. Parcels of air at different temperatures churn past one another, each
with a slightly different index, so the path from an object to your eye keeps
shifting and the object appears to wobble. Stars twinkle for this reason and
planets mostly do not, because a planet is a small disc rather than a point
and the wobbles across it average out.

**Apparent depth**, the shallow-looking pool from [[Refraction]], belongs on
the same list: light bending away from the normal as it leaves the water, and
a brain that assumes it travelled straight.

In each case the mechanism is one sentence — light changes speed between
media, and we trace it back as though it had not. That is what it means to
explain a phenomenon rather than name it.

Practise ray diagrams and the lens equation in [[Lenses Practice]], then build
something that uses them on purpose in [[The Optics Design]].

%%curriculum-start%%
## Curriculum connection

![[E3.5]]

![[E3.8]]
%%curriculum-end%%
