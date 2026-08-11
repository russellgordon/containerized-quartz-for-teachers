---
title: The Vertex Form
draft: false
created: __CREATED__
tags:
  - concepts
enableToc: true
---
You met this idea at the boards with [[Maximum Enclosure]] — the moment
your group asked "where exactly is the top of this curve?". The vertex
form answers that question by making the parabola's turning point visible
in the equation itself:

$$
y = a(x - h)^2 + k
$$

The vertex sits at $(h, k)$, in plain sight. The $a$ is the same $a$ as
ever — direction and width — and everything else about the graph hangs
off those three numbers.

## Reading a graph straight from the equation

| Equation | Vertex | Opens | Compared with $y = x^2$ |
| --- | --- | --- | --- |
| $y = (x-3)^2 + 2$ | $(3, 2)$ | up | slid right 3, up 2 |
| $y = -(x+1)^2 + 4$ | $(-1, 4)$ | down | flipped, slid left 1, up 4 |
| $y = 2x^2 - 5$ | $(0, -5)$ | up | narrowed, slid down 5 |

Watch the sign trap: $(x - h)$ means the graph slides in the *positive*
direction when $h$ is positive — $(x+1)$ is $h = -1$. Test it with one
point before trusting it; that is [[Checking Your Own Work]] in one
second flat.

## Completing the square

Standard form $y = ax^2 + bx + c$ hides the vertex; completing the
square is the algebra that un-hides it. The move: build the perfect
square that *almost* matches, then repair the difference.

$$
y = x^2 + 6x + 2 = (x^2 + 6x + 9) + 2 - 9 = (x+3)^2 - 7
$$

Nothing changed — we added 9 and took it away in the same breath — but
now the vertex $(-3, -7)$ is visible. Why 9? Half of 6, squared. The
[[The Border Problem|border problem]] is where that "half, then square"
pattern first showed itself at the boards.

> [!success]- Quick self-check (click to expand)
> $y = x^2 - 8x + 3$. Half of $-8$ is $-4$; squared is 16.
> $y = (x^2 - 8x + 16) + 3 - 16 = (x-4)^2 - 13$ — vertex $(4, -13)$.
> Verify: at $x = 4$, the original gives $16 - 32 + 3 = -13$. ✓

Which form to use when? Vertex form for the turning point and the story
("maximum height", "minimum cost"); standard form for the
$y$-intercept; factored form for the
[[Zeros and the Quadratic Formula|zeros]]. Fluent movement between them
— not loyalty to one — is the skill [[Quadratic Graphing Practice]]
builds, and [[The Perfect Arc]] is where it earns its keep.

%%curriculum-start%%
## Curriculum connection

![[A2.3]]

![[A2.4]]
%%curriculum-end%%
