---
title: Number Systems Practice
draft: false
created: __CREATED__
tags:
  - exercises
---
These questions follow [[Binary and Number Systems]] and the counting
you did at the bench in [[Binary Bites]]. Fingers allowed. Encouraged.

## Questions

1. Convert $1010_2$ to decimal.
2. Convert $110011_2$ to decimal.
3. Convert $45_{10}$ to binary.
4. Convert $178_{10}$ to binary.
5. **Explain why** the largest number one byte can hold is 255.
6. A memory listing shows the hex value $\mathrm{4F}_{16}$. Write it
   in binary, then in decimal.
7. **Find the error.** A classmate converts $25_{10}$ by dividing by
   two and collecting remainders, and reports $10011_2$. Check it,
   find what went wrong, and give the correct answer.
8. **Challenge.** In ASCII, the letter A is 65. Write 65 in binary,
   then decode the mystery byte $1000011_2$ back to its letter.

## Answers

> [!success]- Answer 1
> Places from the left are worth 8, 4, 2, 1, so
> $8 + 0 + 2 + 0 = 10_{10}$ — a number that spells its own answer.

> [!success]- Answer 2
> Places worth 32, 16, 8, 4, 2, 1, with ones at 32, 16, 2, and 1:
> $32 + 16 + 2 + 1 = 51_{10}$.

> [!success]- Answer 3
> Greedy method: $45 - 32 = 13$, $13 - 8 = 5$, $5 - 4 = 1$,
> $1 - 1 = 0$. Bits at 32, 8, 4, 1 give $101101_2$. Verify forward:
> $32 + 8 + 4 + 1 = 45$. ✓

> [!success]- Answer 4
> $178 - 128 = 50$, $50 - 32 = 18$, $18 - 16 = 2$, $2 - 2 = 0$. Bits
> at 128, 32, 16, 2: $10110010_2$. Check: $128 + 32 + 16 + 2 = 178$. ✓

> [!success]- Answer 5
> All eight bits on gives $128 + 64 + 32 + 16 + 8 + 4 + 2 + 1 = 255$.
> A byte offers exactly 256 *patterns*, but one is spent on zero —
> so the ceiling is 255, and hardware does not negotiate.

> [!success]- Answer 6
> Each hex digit is four bits: 4 is $0100$ and F is $1111$, so
> $01001111_2$. In decimal: $64 + 8 + 4 + 2 + 1 = 79_{10}$.

> [!success]- Answer 7
> $10011_2 = 16 + 2 + 1 = 19$, not 25 — the remainders were read
> top-down, and they must be read *bottom-up*, last remainder
> first. Reversed: $11001_2$, and $16 + 8 + 1 = 25$. ✓

> [!success]- Answer 8
> Greedy on 65: $65 - 64 = 1$, so $1000001_2$. The mystery byte is
> $64 + 2 + 1 = 67$ — two past A, the letter C. Same bits either way;
> only context decides whether they mean a number or a letter.

%%curriculum-start%%
## Curriculum connection

![[A3.1]]

![[A3.2]]
%%curriculum-end%%
