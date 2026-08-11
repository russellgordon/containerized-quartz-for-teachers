---
title: Subprograms and Modules
draft: false
created: __CREATED__
tags:
  - concepts
enableToc: false
---
Somewhere in building [[The Chatbot]], the program got long enough to
sprawl — greeting logic tangled with reply logic tangled with the
goodbye. The fix was to name the chunks. A subprogram — Python calls
them functions — is a block of code with a name, written once and
called from wherever it is needed.

## Name a chunk, reuse it everywhere

```python
def greet(name):
    print("Hello,", name, "— good to see you!")

greet("Avery")
greet("Sam")
```

`def` defines the function, the indented block is what it does, and
writing `greet("Avery")` runs it. Change the greeting once and every
call gets the improvement — the professional laziness that
[[Computational Thinking]] called pattern recognition, finally given
its own syntax.

## Standing on other people's functions

You do not have to write every function yourself. A module[^1] is a
collection someone else wrote, and `import` brings it in:

```python
import random

roll = random.randint(1, 6)
print("You rolled a", roll)
```

Two lines of borrowed brilliance powered all of [[The Dice Roller]].
Python ships with modules for randomness, math, dates, and far more —
which is how one student's project gets to use the same tools as a
studio.

## Building blocks others can reuse

Eventually the direction flips: functions *you* write become parts
other people assemble. That standard changes how you write — a good
function does one nameable job, and its name tells the truth. It is
also why [[Writing Good Comments]] matters more in shared code than
in private code. [[Subprograms Practice]] builds the habit, and the
payoff lands in [[The Remix Project]], when you inherit someone
else's blocks and discover what reusable really means.

[^1]: You will hear "module" and "library" used almost
    interchangeably — both mean collections of ready-made code. The
    word library is apt: you are borrowing, and everyone borrows.

%%curriculum-start%%
## Curriculum connection

![[C3.3]]

![[C3.4]]
%%curriculum-end%%
