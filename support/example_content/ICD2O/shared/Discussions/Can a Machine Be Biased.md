---
title: Can a Machine Be Biased
publish: true
created: __CREATED__
tags:
  - discussions
---
A computer has no opinions, no upbringing, and no feelings about
anyone. So it should be the fairest judge imaginable — and yet
researchers keep documenting the opposite: face-recognition systems
that misidentify darker-skinned faces far more often than lighter
ones, voice assistants that understand some accents easily and others
barely at all. Nobody wrote a line of code that says "work worse for
these people." The bias got in anyway, through three doors: the
**data** the system learned from, the **design** choices about what to
build and test, and the **deployment** — where the system gets used,
and on whom.

Questions worth arguing about:

1. A face-recognition system fails most often on the faces least like
   the ones in its training photos. Nobody *meant* it. Does "nobody
   meant it" matter to the person misidentified — and should it matter
   to the people who shipped it?
2. When a voice assistant understands one accent better than another,
   somebody's speech was treated as the default. Who decided whose
   voice was "normal" — and how would the builders even notice, if
   everyone on the team spoke the default?
3. Suppose a biased system still makes fewer mistakes, on average,
   than the humans it replaces. Use it or not? Does your answer change
   depending on which group pays for the mistakes it still makes?
4. What does "fixing it" actually involve — more diverse data, more
   diverse builders, testing on people unlike yourself, rules with
   teeth? Which of those can a Grade 10 programmer already practise?
5. A tool that a blind or deaf user simply cannot operate — is that
   bias, or oversight? Is there a difference, from the outside?

The practical edge: [[Bias and Accessibility in Technology]] digs
into how these failures work and what accessible design does about
them. And when you design anything in this course, the habit starts
now — before asking "does it work?", ask "*who* does it work for, and
who did I never test?" Per [[Our Classroom Norms]], we argue this one
with ideas, never at people — the point is to build better, not to
find villains.

%%curriculum-start%%
## Curriculum connection

![[A2.4]]

![[A2.5]]
%%curriculum-end%%
