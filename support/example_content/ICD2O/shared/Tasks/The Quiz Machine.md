---
title: The Quiz Machine
publish: true
created: __CREATED__
tags:
  - tasks
enableToc: true
---
> [!abstract] At a glance
> Solo, with a play-tester · four working periods mid-course · in-class
> play-testing in the final period · one Python program plus a test log

## What you are making

A quiz program in Python on a topic you genuinely care about — a sport,
a band, a game, a language, your neighbourhood. It asks questions,
reads answers, checks them, keeps score, and gives feedback, and it
must use [[Conditionals]] and at least one [[Loops|loop]].

Checking answers is where the craft lives — exact matching rejects
`"ottawa"` because you typed `"Ottawa"`, so your checker forgives it:

```python
guess = input("What is the capital of Canada? ")
if guess.strip().lower() == "ottawa":
    score = score + 1
```

Then a classmate play-tests it, and every piece of their feedback is
either addressed in the code or logged in an honest known-issues list.

## How to work

1. Choose the topic — the test is that you would happily talk about it
   at lunch. Write your questions and accepted answers on paper first.
2. Build **one** question end to end — ask, read, check, score — and
   get it working before you write ten. [[The Password Checker]] is
   full of checking patterns worth borrowing.
3. Add forgiving matching, so spacing and capitals never cost a point.
   Decide, and comment, what your checker forgives and what it does not.
4. Notice the repetition — question two looks like question one. That
   pattern is your loop. Comment as you go, in the spirit of
   [[Writing Good Comments]]: a stranger should follow your checker.
5. Add the final score and feedback that actually says something —
   "7 out of 10, your goalie knowledge is elite" beats a bare number.
6. Play-test in class: your classmate plays while you stay silent and
   take notes. Address each finding or log it honestly. The working
   periods are class time — [[How Marks Work]] explains why that counts.

## Success criteria

| Quality | What it looks like in your program |
| --- | --- |
| A topic that is yours | The questions could only have been written by you |
| Runs end to end | A player gets from first question to final score |
| Forgiving checking | Spacing and capitals never cost a correct player |
| Working structures | The conditionals decide, the loop repeats real work |
| Readable throughout | Comments let a stranger follow the checking logic |
| Feedback honoured | Every play-test finding is fixed or honestly logged |

## Reflect

Write a [[Dev Journal]] entry after the play-test: what did your
tester find that you could not have found yourself, and why not? Your
tester did you the favour of not knowing what you know.

> [!success]- If your program only half-works (click to expand)
> Ship the half that works, with a known-issues list naming the half
> that does not. A readable program with honest known bugs outscores a
> flashy one nobody can follow — that is the rule in [[How Marks Work]].

%%curriculum-start%%
## Curriculum connection

![[C2.3]]

![[C2.4]]

![[C2.5]]
%%curriculum-end%%
