---
title: Mistakes Are Data
draft: false
created: __CREATED__
tags:
  - discussions
---
Professional programmers spend most of their working hours not typing
brilliant new code but reading, testing, and repairing code that does
not do what anyone intended. Debugging is not the embarrassing
interruption to the job — it *is* the job. Which reframes the red text
on your screen entirely. It is not the computer scolding you; it is
the computer holding up its end of a conversation:

```
Traceback (most recent call last):
  File "/home/student/hours.py", line 2, in <module>
    count = int(answer)
ValueError: invalid literal for int() with base 10: 'abc'
```

A file, a line, a value, and a reason. Nobody in your life will ever
tell you what you did wrong that precisely, that quickly, or that
willingly. The skill this course cares about is half technical and
half emotional: staying curious for thirty seconds past the moment
frustration wants you to shut the laptop.

Questions worth arguing about:

1. Why does an error message *feel* like an insult when it is
   literally the most helpful thing on the screen? What changes if you
   read it as a note from a teammate who watched the crash happen?
2. If professionals spend most of the day debugging, what does "good
   at programming" actually mean? Rank these honestly: typing speed,
   memorised syntax, patience, curiosity, method.
3. Describe the exact moment frustration peaks — the run-it-again
   moment, the delete-everything urge. What do you do there now? What
   could you do instead, on purpose?
4. Which is worth more: a program that worked first try, or a bug you
   hunted down yourself? Which one will you still remember next year?
5. Hunting a planted bug in [[Spot the Bug]] is fun. The identical
   hunt in your own program feels awful. The bug is the same, so what
   changed? Is the difference in the code, or in what you think the
   bug says about you?
6. What would a room look like where nobody hid a broken build? What
   would we have to agree to, and what would we have to stop doing?

The evidence lives in your [[Code Journal]], which asks for the bug
and not just the victory — a pasted traceback from the day it happened
is the best artifact that journal collects. The method is
[[Reading an Error Message]], the survival kit is [[Getting Unstuck]],
and the discipline behind both is [[Testing and Debugging]]. A room
that treats errors as information debugs faster, and enjoys it more,
than a room that treats them as verdicts.
