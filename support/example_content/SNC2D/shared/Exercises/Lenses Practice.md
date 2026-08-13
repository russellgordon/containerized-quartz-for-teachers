---
title: Lenses Practice
draft: false
created: __CREATED__
tags:
  - optics
  - exercises
---
Every question here uses a **converging** lens and this sign
convention, which you should state at the top of your page before you
start:

$$\frac{1}{f} = \frac{1}{d_o} + \frac{1}{d_i} \qquad M = \frac{h_i}{h_o} = -\frac{d_i}{d_o}$$

Distances are positive on the side where the light really goes. So
$d_o$ is positive for a real object, $f$ is positive for a converging
lens, and $d_i$ is **positive** for a real image on the far side of the
lens and **negative** for a virtual image on the same side as the
object. A **negative** magnification means an inverted image.

**1.** A 4.0 cm tall object stands 30.0 cm from a converging lens of
focal length 10.0 cm. Find the image distance, the magnification, and
the image height, and describe the image completely.

> [!success]- Answer 1
> $\begin{aligned} \frac{1}{d_i} &= \frac{1}{f} - \frac{1}{d_o} = \frac{1}{10.0} - \frac{1}{30.0} = \frac{3}{30.0} - \frac{1}{30.0} = \frac{2}{30.0} \\ d_i &= 15.0\ \text{cm} \end{aligned}$
>
> $$M = -\frac{d_i}{d_o} = -\frac{15.0}{30.0} = -0.500$$
>
> $$h_i = M h_o = (-0.500)(4.0\ \text{cm}) = -2.0\ \text{cm}$$
>
> **Description:** the image is 15.0 cm from the lens on the far side,
> **real** (because $d_i$ is positive, so the rays genuinely cross and
> you can catch it on a screen), **inverted** (because $M$ is
> negative), and **2.0 cm tall**, which is half the size of the object.
>
> The object was beyond $2F$ — that is, beyond 20.0 cm — and the image
> landed between $F$ and $2F$. Getting a smaller, inverted, real image
> is what that region always does, and checking your arithmetic against
> the qualitative rule catches sign errors before you hand them in.

**2.** The same 4.0 cm object, now 20.0 cm from a lens of focal length
15.0 cm.

> [!success]- Answer 2
> $\begin{aligned} \frac{1}{d_i} &= \frac{1}{15.0} - \frac{1}{20.0} = \frac{4}{60.0} - \frac{3}{60.0} = \frac{1}{60.0} \\ d_i &= 60.0\ \text{cm} \end{aligned}$
>
> $$M = -\frac{60.0}{20.0} = -3.00 \qquad h_i = (-3.00)(4.0\ \text{cm}) = -12\ \text{cm}$$
>
> **Real, inverted, enlarged**, 12 cm tall, 60.0 cm from the lens on
> the far side.
>
> Here the object sits between $F$ (15.0 cm) and $2F$ (30.0 cm), and
> that region always gives a real, inverted, **enlarged** image beyond
> $2F$. This is a projector: a small slide close to the lens throwing a
> large picture a long way off. Notice how sensitive it is — moving the
> object 5 cm changed the image distance by tens of centimetres, which
> is why focusing a projector feels so touchy.

**3.** The same 4.0 cm object, 5.0 cm from a lens of focal length
10.0 cm.

> [!success]- Answer 3
> $\begin{aligned} \frac{1}{d_i} &= \frac{1}{10.0} - \frac{1}{5.0} = \frac{1}{10.0} - \frac{2}{10.0} = -\frac{1}{10.0} \\ d_i &= -10.0\ \text{cm} \end{aligned}$
>
> $$M = -\frac{(-10.0)}{5.0} = +2.0 \qquad h_i = (+2.0)(4.0\ \text{cm}) = 8.0\ \text{cm}$$
>
> **Virtual, upright, enlarged**, 8.0 cm tall, 10.0 cm from the lens on
> the **same side as the object**.
>
> The negative image distance is not an error to be tidied away — it is
> the equation telling you the image is on the object's side, where no
> light actually arrives. You cannot put a screen there and catch it;
> you look **through** the lens to see it. This is a magnifying glass,
> and the object being inside the focal point is the whole condition
> for it working.
>
> Two habits worth taking from this question: carry the negative sign
> through the magnification instead of dropping it, and read the sign
> of your answer as physics rather than as arithmetic.

**4.** Name the three principal rays used to locate an image from a
converging lens, and say why these three in particular.

> [!success]- Answer 4
> 1. A ray from the top of the object travelling **parallel to the
>    principal axis**, which refracts through the **focal point on the
>    far side**.
> 2. A ray straight **through the centre of the lens**, which carries
>    on undeviated.
> 3. A ray **through the focal point on the near side**, which emerges
>    **parallel to the principal axis**.
>
> Why these three: each one has an outgoing direction you know without
> doing any calculation. Every other ray from that point would need
> Snell's law applied twice. Two of these are enough to locate the
> image; the third is the check, and if all three do not meet at one
> point, something in your drawing is wrong.
>
> Rays 1 and 3 are mirror images of each other in their logic, which is
> worth noticing — parallel in gives focus out, focus in gives parallel
> out. Conventions for drawing them, including which lines are dashed:
> [[Drawing Scientific Diagrams]].

**5.** Complete the table of image characteristics for a converging
lens.

| Object position | Type | Orientation | Size | Image position |
| --- | --- | --- | --- | --- |
| Beyond $2F$ | | | | |
| At $2F$ | | | | |
| Between $F$ and $2F$ | | | | |
| At $F$ | | | | |
| Inside $F$ | | | | |

> [!success]- Answer 5
> | Object position | Type | Orientation | Size | Image position |
> | --- | --- | --- | --- | --- |
> | Beyond $2F$ | Real | Inverted | Smaller | Between $F$ and $2F$ |
> | At $2F$ | Real | Inverted | Same size | At $2F$ on the far side |
> | Between $F$ and $2F$ | Real | Inverted | Larger | Beyond $2F$ |
> | At $F$ | No image | — | — | Rays emerge parallel and never meet |
> | Inside $F$ | Virtual | Upright | Larger | Same side as the object |
>
> Three things are worth memorising as patterns rather than rows.
> Every **real** image from a converging lens is **inverted**, without
> exception. The only **upright** image is the **virtual** one, and it
> only happens inside $F$. And the object and image trade places as you
> move across $2F$ — the arrangement is reversible, so the object and
> image positions in row 1 are exactly those of row 3 swapped over.

**6.** You need a **real** image exactly twice the height of the
object, using a lens of focal length 10.0 cm. Where should the object
go, and where will the image be?

> [!success]- Answer 6
> A real image is inverted, so the magnification required is
> $M = -2.00$, not $+2.00$.
>
> $$M = -\frac{d_i}{d_o} = -2.00 \quad \Rightarrow \quad d_i = 2.00 d_o$$
>
> Substitute into the lens equation:
>
> $\begin{aligned} \frac{1}{f} &= \frac{1}{d_o} + \frac{1}{2.00 d_o} = \frac{2}{2.00 d_o} + \frac{1}{2.00 d_o} = \frac{3}{2.00 d_o} \\ d_o &= \frac{3f}{2} = \frac{3(10.0)}{2} = 15.0\ \text{cm} \end{aligned}$
>
> So the object goes **15.0 cm** from the lens, and
> $d_i = 2.00(15.0) = 30.0\ \text{cm}$.
>
> Check it back through the original equation:
> $\frac{1}{15.0} + \frac{1}{30.0} = \frac{2}{30.0} + \frac{1}{30.0} = \frac{3}{30.0} = \frac{1}{10.0}$. Correct.
>
> Note also that 15.0 cm lies between $F$ and $2F$, exactly as row 3 of
> the table promises for an enlarged real image. The algebra and the
> qualitative rule agree, which is how you know you have not made a
> sign error.

**7.** A group covers the top half of their lens with card and the
image on the screen does not become half an image. One student says the
experiment is broken. What actually happens, and why?

> [!success]- Answer 7
> The **whole image is still there**. It simply becomes **dimmer**.
>
> The reason is in how an image is formed. Every point on the object
> sends light to the **entire surface** of the lens, and the lens
> brings all of that light back together at one image point. Blocking
> half the lens removes half the rays reaching every image point, so
> every point loses brightness — and no point loses existence.
>
> The three principal rays are a **drawing technique**, not a claim
> about which rays matter. Cover the path of the parallel ray and the
> image is unaffected, because thousands of other rays from that same
> object point are still getting through and still converging in the
> same place.
>
> This is worth understanding rather than memorising, because it
> explains a real trade-off. Narrowing the opening in a camera makes
> the picture dimmer, and it also makes a larger range of distances
> look acceptably sharp at once — which is the next question.

**8.** On the optical bench, your group finds that the image looks
sharp anywhere from 24.1 cm to 25.7 cm, and you cannot agree on the
best position. How should you report the image distance, and what does
the range tell you?

> [!success]- Answer 8
> Report the **midpoint with the range**: about 24.9 cm, with the
> sharp-looking region spanning roughly $\pm 0.8$ cm.
>
> The 1.6 cm spread is not a failure and it is not something to hide by
> picking a number. It **is your uncertainty**, measured directly, and
> it is more honest than any figure your ruler could give you — because
> the limit here was never the ruler, it was the judgement of "sharp".
>
> Two things follow, and both belong in the conclusion:
>
> 1. **Compare your disagreement with your prediction against this
>    range.** If your ray diagram predicted 25.0 cm, the prediction sits
>    comfortably inside the range and your data supports it. If it
>    predicted 21 cm, it does not, and you have something real to
>    explain.
> 2. **You cannot report more precision than the range allows.** A
>    calculated answer of 24.87 cm is arithmetic, not measurement.
>
> Notice too that the range itself is data about the lens. A short
> focal length lens with a wide opening gives a narrow sharp region; a
> narrower opening widens it — which is exactly the effect question 7
> ended on. The thing your group found annoying is the thing a
> photographer spends their career using on purpose.

Reference: [[Lenses and Images]]. Your own measurements:
[[Finding the Focal Length]]. You will need all of this for
[[The Optics Design]].

%%curriculum-start%%
## Curriculum connection

![[E2.5]]

![[E3.5]]
%%curriculum-end%%
