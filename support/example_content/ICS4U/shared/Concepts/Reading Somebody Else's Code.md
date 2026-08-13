---
title: Reading Somebody Else's Code
draft: false
created: __CREATED__
tags:
  - concepts
---
On the first day of this course you were handed a working program
nobody in the room had written, and asked what it did. Nobody could
say — not immediately, not from staring. The groups that got there
first did not read faster. They *ran* it, changed one thing, ran it
again, and let the program tell them.

That is the skill. Most of the code you will ever work on already
exists, was written by somebody else, and is not going to explain
itself. Grade 11 asked you to write a program. Grade 12 asks you to
walk into one already in progress and be useful.

## Read like an investigator, not a reader

Reading code top to bottom like prose is the slowest possible method.
Try this order instead:

1. **Run it.** What does it actually do? Give it ordinary input, then
   strange input.
2. **Find the entry point.** Where does execution begin? In Python,
   look for the last few unindented lines, or a
   `if __name__ == "__main__":` block.
3. **Name the nouns.** What classes and data structures exist? Those
   are the program's model of the problem — see
   [[Objects and Classes]].
4. **Follow one path.** Pick a single feature and trace it end to end.
   Ignore everything else on purpose.
5. **Change something small** and predict the effect before you run
   it. A wrong prediction just taught you the most.

| Question | Where the answer usually lives |
| --- | --- |
| What is this program *for*? | The README, the file names, the output |
| What does it operate on? | Class definitions and data structures |
| Where does it start? | The bottom of the main file |
| What breaks it? | Try bad input; see [[Testing and Regression]] |
| Why is this weird line here? | The version history — see [[Version Control]] |

That last row is the one students underuse. When a line makes no
sense, the commit that introduced it often explains itself in one
sentence.

## Read charitably

You will find code you would not have written. Before you rewrite it,
assume the author had a reason you have not discovered yet — a
constraint, a bug they were working around, a client who insisted. Ask
what would break if you removed it. Sometimes the answer is "nothing",
and you have improved the program; sometimes the answer arrives at
2 a.m. three weeks later.

> [!tip] The "leave a note" rule
> When you finally work out what a confusing chunk does, write it
> down — a comment, a line in the README, an entry in your
> [[Code Journal]]. You are the only person who will ever have that
> understanding for free. Everyone after you pays for it again.

## Why this is the whole course, really

[[The Software Project]] is a team build, which means you will spend
half your time reading code your teammates wrote this morning.
[[The Maintenance Sprint]] hands you a program deliberately written
by somebody else, with its own habits and its own bugs. And the finale is
called [[The Handover]] for a reason: software that only its author can
understand has not really helped anybody, however well it runs today.

Practise the mechanics with [[Reading a Traceback in Someone Else's Code]],
and try it live in [[The Inherited Program]].

%%curriculum-start%%
## Curriculum connection

![[A4.1]]

![[A4.3]]

![[A2.3]]
%%curriculum-end%%
