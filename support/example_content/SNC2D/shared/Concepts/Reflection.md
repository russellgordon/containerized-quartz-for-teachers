---
title: Reflection
publish: true
created: __CREATED__
enableToc: true
tags:
  - concepts
  - optics
---
In [[The Law of Reflection]] you did not look up the law. You measured angles,
plotted one against the other, and the graph came out as a straight line
through the origin with a slope of one. That is a nicer way to meet a law than
being told it, and it is worth remembering that the law is a *summary of
measurements* rather than a rule light has been issued.

## The law, and the line you measure from

The **normal** is an imaginary line drawn perpendicular to the surface at the
exact point where the ray strikes it. Every angle in optics is measured from
the normal, and almost every wrong answer in this unit comes from measuring
from the surface instead.

With that fixed, the law has two parts and you need both:

1. The angle of reflection equals the angle of incidence, $\theta_i = \theta_r$, with both measured from the normal.
2. The incident ray, the reflected ray, and the normal all lie in the same plane.

The second part is what stops light from glancing off sideways, and it is the
reason a ray diagram drawn flat on paper is a complete description.

> [!warning] Measure from the normal, not from the mirror
> A ray striking a mirror at 20° **to the surface** has an angle of incidence
> of 70°, because the normal is 90° from the surface. Students who measure
> from the surface get answers that are consistently the complement of the
> right one — and, worse, the arithmetic still "works", so nothing looks
> broken. Draw the normal first, as a dashed line, every single time. It costs
> two seconds and it is the difference between a diagram that can be marked
> and one that cannot.

## Why a wall is not a mirror

Here is a question the law seems not to answer: this page reflects light, and
so does a mirror, so why can you read the page from any angle but only see
yourself in the mirror from one?

Both obey the law of reflection exactly. The difference is the surface. A
mirror is smooth on the scale of the wavelength of light, so every point on it
has a normal pointing the same way, and a bundle of parallel rays arrives and
leaves as a bundle of parallel rays. That is **specular** reflection, and it
preserves the arrangement of the rays, which is what an image is made of.

A sheet of paper is rough at that scale. Every tiny facet has its own normal
pointing in its own direction, so parallel rays arrive together and leave in
every direction. Each individual ray still obeys $\theta_i = \theta_r$
perfectly. That is **diffuse** reflection, and it destroys the arrangement
while scattering the light everywhere — which is exactly why you can read from
any seat in the room.

Nothing extra is needed to explain the difference. Same law, different
normals.

## Curved mirrors and the images they make

A curved mirror is a piece of a sphere, and the law still applies point by
point — it is only the normals that change direction across the surface. Two
points on the axis matter: the **centre of curvature** $C$, the centre of the
sphere the mirror was cut from, and the **focal point** $F$, halfway between
$C$ and the mirror.

A **concave** mirror curves inward and converges parallel rays through $F$. A
**convex** mirror curves outward and spreads them, so they only appear to come
from a focal point behind the surface.

| Mirror and object position | Image type | Orientation | Size | Where |
| --- | --- | --- | --- | --- |
| Plane mirror | Virtual | Upright | Same | As far behind as the object is in front |
| Concave, object beyond $C$ | Real | Inverted | Smaller | Between $F$ and $C$ |
| Concave, object at $C$ | Real | Inverted | Same | At $C$ |
| Concave, object between $C$ and $F$ | Real | Inverted | Larger | Beyond $C$ |
| Concave, object at $F$ | No image | — | — | Reflected rays leave parallel |
| Concave, object inside $F$ | Virtual | Upright | Larger | Behind the mirror |
| Convex, any position | Virtual | Upright | Smaller | Behind the mirror, between $F$ and the surface |

A **real** image is formed where reflected light actually converges, so it can
be caught on a screen held at that point. A **virtual** image is where the
rays only *appear* to have come from; no screen will show it, and it is always
on the far side of the mirror from the light.

The same information comes out of the mirror equation, $\frac{1}{f} = \frac{1}{d_o} + \frac{1}{d_i}$, with magnification $M = \frac{h_i}{h_o} = -\frac{d_i}{d_o}$.

The **sign convention used here** — state it in your answers, because more
than one convention exists — is that distances are measured from the mirror
and are positive on the side the light is on. So $d_o$ is positive for a real
object; $d_i$ is positive for a real image in front of the mirror and negative
for a virtual image behind it; $f$ is positive for a concave mirror and
negative for a convex one. A negative $M$ means an inverted image, and
$|M| > 1$ means an enlarged one. If your arithmetic returns a negative
$d_i$, the equation is not failing — it is telling you the image is virtual.

One more thing about the plane mirror, said properly. Your reflection is often
described as left–right reversed, which is not quite what happens. Nothing is
swapped left for right; the image is reversed **front to back**, along the
direction perpendicular to the mirror. Raise your right hand and the hand in
the mirror on the same side as yours goes up. It looks like a left hand
because you imagine turning yourself around to face the way the image faces,
and it is that imagined turn, not the mirror, that swaps the sides.

## Choosing a mirror for a job

Every application is a choice about what kind of image you need, and the table
above is the whole design manual.

A **plane** mirror is for seeing something without changing it — a periscope
folds a line of sight around an obstacle using two of them.

A **concave** mirror is for gathering and enlarging. Put a lamp at the focal
point of one and the reflected rays leave parallel, which is a headlight or a
torch. Run it the other way and parallel light from a distant star converges
to a point, which is a reflecting telescope; a mirror is used rather than a
lens partly because it can be made very large and supported from behind, and
partly because it brings all colours to the same focus. A shaving or dental
mirror works with the object *inside* the focal point, giving the enlarged
upright virtual image on the bottom row but one of the table.

A **convex** mirror is for seeing as much as possible at once. Because it
spreads rays, it takes in a wide field of view and shrinks it — which is what
you want at a blind corner in a car park or on the side of a vehicle. The
warning etched on those mirrors follows directly from the physics: the image
is reduced, your brain reads a smaller image as a more distant one, and so
objects really are closer than they appear.

Lenses do the same jobs by bending light rather than bouncing it, and
instruments often combine the two — a camera lens focuses onto a sensor, a
microscope stacks two converging lenses, and binoculars use prisms to fold a
long path into a short body. That story continues in [[Refraction]] and then
[[Lenses and Images]]. Practise the diagrams and the equation in
[[Reflection Practice]].

%%curriculum-start%%
## Curriculum connection

![[E3.3]]

![[E3.6]]
%%curriculum-end%%
