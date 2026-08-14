---
title: Working with Logarithms in Chemistry
draft: false
created: __CREATED__
enableToc: true
tags:
  - skills
  - equilibrium
---
There is no page like this in the Grade 11 course, because Grade 11 did
not need one. Unit 4 does. From the moment acid–base equilibrium starts,
concentration stops being reported as a concentration and starts being
reported as a logarithm, and a great deal of the trouble people have
with that unit turns out to be arithmetic wearing a chemistry costume.

Half an hour here saves you a fortnight of small, confusing errors.

## Why chemistry reaches for a logarithm at all

Look at the range you are being asked to work in. The hydronium
concentration in the solutions you will meet this semester runs from
around $1 \times 10^{-1}$ mol/L in a fairly strong acid down to around
$1 \times 10^{-14}$ mol/L in a strongly basic one. That is fourteen
powers of ten. No graph axis and no sensible table handles that.

A logarithm answers one question: **what power of ten is this?** And
since all these concentrations are less than one, every one of those
powers is negative, so the definition carries a minus sign to hand you
back a number you can say out loud:

$$\text{pH} = -\log[\ce{H3O+}]$$

A concentration of $1 \times 10^{-3}$ mol/L is ten to the minus three,
so the pH is 3. That is the whole idea. Everything else on this page is
a consequence of it.

The same trick gets used on anything that spans orders of magnitude, and
you will meet all of these:

$$\text{pOH} = -\log[\ce{OH-}] \qquad \text{p}K_a = -\log K_a \qquad \text{p}K_w = -\log K_w$$

## The relationships worth knowing cold

In water at 25 °C, the two ion concentrations are tied together:

$$K_w = [\ce{H3O+}][\ce{OH-}] = 1.0 \times 10^{-14}$$

Take the negative logarithm of both sides — a product becomes a sum —
and you get the relationship you will use constantly:

$$\text{pH} + \text{pOH} = 14.00$$

> [!warning] "14" is a temperature, not a law
> $K_w$ changes with temperature, because the ionisation of water is
> itself an equilibrium and equilibrium constants depend on temperature.
> The value $1.0 \times 10^{-14}$, and therefore the 14.00 above, and
> therefore "neutral means pH 7", all belong to 25 °C.
>
> Warm the water and $K_w$ gets larger, so pure water ends up with a pH
> **below 7 while remaining perfectly neutral** — the hydronium and
> hydroxide concentrations are still equal, they are simply both bigger.
> Neutral means the two are equal. It has never meant seven.

## One unit of pH is a factor of ten

This is the single most useful sentence on the page and the one most
often nodded at without being absorbed.

| pH | $[\ce{H3O+}]$ in mol/L | Compared with pH 5 |
| --- | --- | --- |
| 2 | $1 \times 10^{-2}$ | 1000 times more concentrated |
| 3 | $1 \times 10^{-3}$ | 100 times more concentrated |
| 4 | $1 \times 10^{-4}$ | 10 times more concentrated |
| 5 | $1 \times 10^{-5}$ | — |

So a lake that drops from pH 5.4 to pH 4.4 has not changed by "one".
Its hydronium concentration has gone up **tenfold**. And a difference
that looks trivial is often not: since $10^{0.3} \approx 2$, a change of
0.3 in pH is a doubling. Two solutions differing by 0.3 pH units differ
by a factor of two in concentration, which is a large chemical
difference dressed as a small number.

Train yourself to translate before you argue. Whenever somebody says a
pH difference is small, ask what the ratio of concentrations is.

## Significant figures for a logarithm

Here is the rule that catches everybody, including people who are
otherwise careful about digits.

**In a logarithm, the digits before the decimal point are not
significant.** They record the power of ten — where the number sits —
and that came from the exponent, not from your measurement. All the
information from your measured digits ends up **after** the decimal
point.

$$\text{pH} = -\log(3.4 \times 10^{-3}) = 2.47$$

The measurement had two significant figures. The "2" in that answer came
from $10^{-3}$; the ".47" is where the "3.4" went. So the pH is written
to **two decimal places**, and quoting it as 2.4685 would be claiming
five figures of precision from a two-figure measurement.

Stated as a working rule, in both directions:

| Going this way | The rule |
| --- | --- |
| Concentration → pH | Decimal places in the pH = significant figures in the concentration |
| pH → concentration | Significant figures in the concentration = decimal places in the pH |

Two consequences worth sitting with:

- A pH of **2.47 carries two significant figures, not three.** Counting
  the digits the way you would for any other number gives the wrong
  answer here, and only here.
- A pH written as plain **"3"**, with no decimal places, tells you the
  order of magnitude and nothing else. It is not a three-figure result;
  it is barely a one-figure one. If your meter reads to two decimals,
  write two decimals.

> [!tip] What your instrument is entitled to claim
> A benchtop pH meter typically resolves 0.01 pH units, and only after
> it has been calibrated against standard buffers that day. Universal
> indicator paper against a printed colour chart is worth perhaps half a
> pH unit on a good day and a whole one on a normal one.
>
> Writing "pH = 4.50" from a strip of paper is not a rounding
> preference. It is a claim about equipment you did not use.

## Going backwards, from pH to concentration

Half the questions in Unit 4 run the other way. Undo the definition:

$$[\ce{H3O+}] = 10^{-\text{pH}}$$

On your calculator the $10^x$ function is almost always the second
function of the `log` key, which makes sense once you see that they undo
each other. Find it in the first week. Two checks that take five seconds
and will save you an hour:

- `log` of 100 must give exactly 2. If it gives 4.605, you have `ln`,
  which is the natural logarithm and is 2.303 times too large for this
  purpose.
- $10^x$ of 2 must give exactly 100. If it gives 7.389, you have $e^x$.

> [!example]- Three worked conversions, in full
> **A strong acid.** Hydrochloric acid at 0.025 mol/L ionises
> completely, so $[\ce{H3O+}] = 0.025$ mol/L.
>
> $$\text{pH} = -\log(2.5 \times 10^{-2}) = 1.60$$
>
> Two significant figures in, two decimal places out.
>
> **Through pOH.** A solution has $[\ce{OH-}] = 2.5 \times 10^{-4}$
> mol/L. Then $\text{pOH} = -\log(2.5 \times 10^{-4}) = 3.60$, and
> since the pair must add to 14.00 at 25 °C, $\text{pH} = 10.40$. You
> could also have divided into $K_w$ first and taken the logarithm at
> the end; both routes are correct and the second one gives you more
> chances to lose an exponent.
>
> **Backwards.** A meter reads 4.75. Then
> $[\ce{H3O+}] = 10^{-4.75} = 1.8 \times 10^{-5}$ mol/L —
> two decimal places in the pH, so two significant figures out, and
> writing $1.7783 \times 10^{-5}$ would be inventing three of them.

> [!example]- A weak acid, where the logarithm is the easy part
> Ethanoic acid at 0.10 mol/L. Take $K_a$ from your data booklet — for
> this one it is about $1.8 \times 10^{-5}$ at 25 °C.
>
> $$\ce{CH3COOH(aq) + H2O(l) <=> CH3COO-(aq) + H3O+(aq)}$$
>
> With $x$ for the hydronium concentration at equilibrium,
>
> $$K_a = \frac{x^2}{0.10 - x} \approx \frac{x^2}{0.10}$$
>
> $$\begin{aligned} x^2 &= (1.8 \times 10^{-5})(0.10) = 1.8 \times 10^{-6} \\ x &= 1.3 \times 10^{-3}\ \text{mol/L} \\ \text{pH} &= -\log(1.34 \times 10^{-3}) = 2.87 \end{aligned}$$
>
> Two things to notice, and the second is the one that gets marked.
>
> The approximation dropped the $x$ in the denominator. That is a
> **model choice**, and it comes with a stated boundary: it is
> acceptable when $x$ is less than about 5% of the starting
> concentration. Here $x$ is about 1.3% of 0.10 mol/L, so it holds. In a
> more dilute solution of the same acid it would not, and you would have
> to solve the quadratic. Say which you did.
>
> And carry the unrounded $1.34 \times 10^{-3}$ into the logarithm
> rather than the rounded $1.3 \times 10^{-3}$. Rounding early and then
> taking a logarithm is how a correct method produces a pH that is off
> in the second decimal place — the place that carries all your
> significant figures.

## pKa, and why the p is worth having

$K_a$ values in a data booklet span an enormous range and are printed in
scientific notation, which makes them awkward to compare at a glance.
Taking the negative logarithm fixes that:

$$\text{p}K_a = -\log K_a \qquad K_a = 10^{-\text{p}K_a}$$

For ethanoic acid, $K_a = 1.8 \times 10^{-5}$ gives
$\text{p}K_a = 4.74$.

Two things follow, and both are worth memorising because they are the
opposite of what the notation suggests:

- **A smaller $\text{p}K_a$ means a stronger acid.** The minus sign
  flips the ranking. An acid with $\text{p}K_a$ 3.75 is stronger than
  one with $\text{p}K_a$ 4.74.
- **A difference of 1 in $\text{p}K_a$ is a factor of 10 in $K_a$.**
  Exactly as with pH, and for exactly the same reason.

You will use this constantly in [[Buffers and Titration Curves]], where
choosing a buffer means choosing an acid whose $\text{p}K_a$ sits near
the pH you want to hold.

## Where people actually go wrong

| The mistake | What it looks like | The fix |
| --- | --- | --- |
| `ln` instead of `log` | Every answer is 2.303 times too big | Check that `log` of 100 gives 2 |
| $e^x$ instead of $10^x$ | Going backwards gives nonsense | Check that $10^x$ of 2 gives 100 |
| The minus sign | Negative pH values everywhere | pH is positive for every ordinary solution |
| Counting digits normally | pH 2.47 reported as three significant figures | Only the decimals count |
| Rounding before the logarithm | Correct method, wrong second decimal | Round at the end, once |
| Averaging pH values | Two solutions averaged to the pH between them | Average the concentrations, then take the logarithm |

That last row deserves its own sentence, because it looks so
reasonable. Mix equal volumes of a pH 2.00 and a pH 4.00 strong acid and
the result is **not** pH 3.00. It is 2.30, because the more concentrated
solution dominates completely — $1.0 \times 10^{-2}$ swamps
$1.0 \times 10^{-4}$, and the logarithm of the mixture is nowhere near
halfway. A logarithmic scale is not an ordinary axis and it does not
average.

> [!important] Dilution behaves differently for strong and weak acids
> Dilute a **strong** acid tenfold and its pH rises by exactly 1, since
> the concentration fell by exactly a factor of ten.
>
> Dilute a **weak** acid tenfold and its pH rises by only about 0.5.
> Look at the weak-acid working above: $x$ goes as the square root of
> the concentration, and the square root of ten is about 3.2, not 10.
> Diluting shifts the ionisation equilibrium, so a larger *fraction* of
> the acid ionises and partly compensates.
>
> Dilute a **buffer** and the pH barely moves at all, which is the
> entire point of a buffer.
>
> Three different behaviours from one operation. If you can say why each
> one happens, you understand both the logarithm and the equilibrium.

## Practice

Work these with a calculator and the rules above, then open the answers.

1. A solution has $[\ce{H3O+}] = 4.7 \times 10^{-9}$ mol/L.
   What is its pH?
2. A calibrated meter reads 12.15. Find $[\ce{H3O+}]$ and
   $[\ce{OH-}]$ at 25 °C.
3. Equal volumes of two strong acid solutions, pH 2.00 and pH 4.00, are
   mixed. Find the pH of the mixture.
4. A weak acid has $K_a = 6.3 \times 10^{-5}$. Find its
   $\text{p}K_a$, and say whether it is stronger or weaker than an acid
   with $\text{p}K_a = 3.75$.

> [!success]- Answers
> **1.** $-\log(4.7 \times 10^{-9}) = 8.33$. Two significant figures in
> the concentration, so two decimal places in the pH.
>
> **2.** $[\ce{H3O+}] = 10^{-12.15} = 7.1 \times 10^{-13}$
> mol/L. Then either divide into $K_w$, or use
> $\text{pOH} = 14.00 - 12.15 = 1.85$, giving
> $[\ce{OH-}] = 10^{-1.85} = 1.4 \times 10^{-2}$ mol/L. Two decimal
> places in, two significant figures out, both times.
>
> **3.** Convert first: $1.00 \times 10^{-2}$ mol/L and
> $1.00 \times 10^{-4}$ mol/L. Equal volumes halve each, so the mixture
> is $(1.00 \times 10^{-2} + 1.00 \times 10^{-4}) / 2 = 5.05 \times 10^{-3}$
> mol/L, and $\text{pH} = 2.30$. Not 3.00 — the stronger solution wins
> by two orders of magnitude and the weaker one barely registers.
>
> **4.** $\text{p}K_a = -\log(6.3 \times 10^{-5}) = 4.20$. That is
> **weaker** than the acid with $\text{p}K_a = 3.75$, because a smaller
> $\text{p}K_a$ means a larger $K_a$. The gap of 0.45 corresponds to a
> factor of about 2.8 in $K_a$.

Next, the chemistry these tools are for: [[Acids and Bases]] and
[[Buffers and Titration Curves]]. For the digits in everything that is
not a logarithm, [[Significant Figures and Units]]. For practice
questions with chemistry attached rather than arithmetic alone,
[[Acids and Bases Practice]].

%%curriculum-start%%
## Curriculum connection

![[A1.13]]
%%curriculum-end%%
