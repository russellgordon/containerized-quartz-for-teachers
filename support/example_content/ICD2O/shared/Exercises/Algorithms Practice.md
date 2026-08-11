---
title: Algorithms Practice
draft: false
created: __CREATED__
tags:
  - exercises
---
These questions follow [[Algorithms in Everyday Life]] — and the
literal-minded robot from [[The Sandwich Robot]] is watching.

## Questions

1. Write instructions for making toast that would survive the most
   literal reading possible. Aim for six to eight numbered steps.
2. Match each description to a term — *algorithm*, *variable*,
   *loop*, *condition*: (a) a named box holding a value, (b) a
   precise list of steps, (c) a test that picks a path, (d) a repeat.
3. **Predict the output.** Trace the spoken algorithm "start at 1;
   while it is 20 or less, double it; say the number" — then as code:
   ```python
   number = 1
   while number <= 20:
       number = number * 2
   print(number)
   ```
4. **Find the bug** in this hot-chocolate algorithm: (1) drink,
   (2) stir, (3) add cocoa to the mug, (4) pour in hot milk. Give an
   order that works, and name what *kind* of error this is.
5. A program finds locker 23 by checking locker 1, then 2, then 3,
   and so on. The lockers are numbered in order. Describe a better
   algorithm, and say roughly how much work it saves.
6. **Challenge.** Write a plain-language algorithm for finding the
   biggest of three numbers — precise enough to need no judgement.

## Answers

> [!success]- Answer 1
> Answers vary. The test: could a robot with no common sense follow
> it? "Put bread in the toaster" fails if the bag is still sealed —
> compare your steps with a partner's and hunt for hidden judgement.

> [!success]- Answer 2
> (a) variable, (b) algorithm, (c) condition, (d) loop. Using the
> right names is half of explaining any program clearly.

> [!success]- Answer 3
> 1, 2, 4, 8, 16, 32 — the check `32 <= 20` fails, so `32` prints.
> It sails *past* 20: the test happens before each double, not after.

> [!success]- Answer 4
> One working order: 3, 4, 2, 1. The steps are fine — the *sequence*
> is broken: right instructions, wrong order, no crash, wrong result.

> [!success]- Answer 5
> The lockers are sorted, so go straight to 23 — or leap in halves
> like [[Twenty Questions]]: 22 checks avoided out of 23. Ordered
> data is a gift; good algorithms accept it.

> [!success]- Answer 6
> One version: call the first number the *leader*. Compare the second
> to the leader; if it is bigger, it becomes the leader. Repeat with
> the third. Announce the leader. No taste, no judgement — just steps.

%%curriculum-start%%
## Curriculum connection

![[C1.2]]

![[C1.1]]
%%curriculum-end%%
