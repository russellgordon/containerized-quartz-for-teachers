---
title: Electronics Calculations Practice
publish: true
created: __CREATED__
tags:
  - exercises
---
These questions follow [[Electronics Fundamentals]] and the circuits
you built in [[Breadboard a Circuit]]. One law, $V = IR$, worked
every direction — and units carried everywhere, always.

## Questions

1. A current of $0.02\ \text{A}$ flows through a $250\ \Omega$
   resistor. What voltage appears across it?
2. A $9\ \text{V}$ battery drives a $450\ \Omega$ resistor. How much
   current flows? Give the answer in milliamperes too.
3. A component drops $5\ \text{V}$ while passing $0.01\ \text{A}$.
   What is its resistance?
4. Three resistors sit in series: $220\ \Omega$, $330\ \Omega$, and
   $100\ \Omega$. What is the total resistance?
5. A $9\ \text{V}$ supply pushes current through $220\ \Omega$ and
   $330\ \Omega$ in series. Find the current in the circuit.
6. **Explain why** an LED on a breadboard always gets a resistor as a
   neighbour. What happens without one?
7. **Find the error.** Asked for the current in question 2, a
   classmate computes $I = V \times R = 9 \times 450 = 4050\ \text{A}$
   and writes it down without blinking. Find both mistakes.

## Answers

> [!success]- Answer 1
> $V = IR = 0.02\ \text{A} \times 250\ \Omega = 5\ \text{V}$.

> [!success]- Answer 2
> Rearrange to $I = V / R = 9\ \text{V} / 450\ \Omega = 0.02\ \text{A}$
> — that is $20\ \text{mA}$, a healthy LED-sized current.

> [!success]- Answer 3
> $R = V / I = 5\ \text{V} / 0.01\ \text{A} = 500\ \Omega$.

> [!success]- Answer 4
> Series resistances simply add:
> $220\ \Omega + 330\ \Omega + 100\ \Omega = 650\ \Omega$.

> [!success]- Answer 5
> Add first, then apply the law: $R = 220 + 330 = 550\ \Omega$, so
> $I = 9\ \text{V} / 550\ \Omega \approx 0.016\ \text{A}$ — about
> $16\ \text{mA}$.

> [!success]- Answer 6
> An LED has almost no resistance of its own, and $I = V/R$ with a
> tiny $R$ means an enormous current — enough to burn out the LED
> in a flash. The series resistor holds the current to a safe
> $20\ \text{mA}$ or so — not decoration, but the LED's bodyguard.

> [!success]- Answer 7
> First, the algebra: solving $V = IR$ for current gives $I = V/R$
> — division, not multiplication. Second, no sanity check: a
> $4050\ \text{A}$ answer is welding territory, not a breadboard.
> Correct: $0.02\ \text{A}$, or $20\ \text{mA}$ — always ask
> whether the number could be real.

%%curriculum-start%%
## Curriculum connection

![[B2.5]]

![[B2.1]]
%%curriculum-end%%
