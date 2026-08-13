---
title: Getting Unstuck
draft: false
created: __CREATED__
tags:
  - tutorials
---
Stuck is a normal working condition — [[Getting Help]] says so and
professionals live there daily. But there are two kinds of stuck.
**Stuck-and-thinking** is generating hypotheses and testing them; it
looks slow and is actually progress. **Spinning** is re-running
unchanged code hoping the computer changes its mind. It will not.
These five moves convert spinning back into thinking.

1. **Re-read the line out loud.** Not what you meant — what it *says*.
   A startling number of bugs die at this step: the missing colon, the
   `=` that should be `==`, the variable named `scroe`.
2. **Shrink the program.** Comment out everything after the last part
   that definitely worked, run it, then bring lines back one at a
   time. The bug is in the first line whose return breaks it, and now
   it is cornered.
3. **Print the values.** You *believe* `total` is 27. Add
   `print(total)` just before the crash and find out. The gap between
   what you believe and what prints is exactly where bugs live —
   [[Using the Debugger]] turns this into a proper method.
4. **Explain it to the duck.** Rubber-duck debugging is a real
   professional technique with a silly name: explain your program,
   line by line, to a duck or any patient object. Saying "and then
   this adds one to the total — wait" *is* the technique working. The
   bug hides in the step you were about to skip.
5. **Step away.** Ten minutes, water, a walk. The brain keeps working
   without the screen glare, and the bug you could not see at 2:10 is
   often obvious at 2:20. This is a debugging move, not giving up.

## Knowing which stuck you are in

The honest test: *when did you last change something on purpose?* If
the answer is "three runs ago", you are spinning — take one of the
moves above, or climb the ladder in [[Getting Help]]. Twenty minutes
of genuine stuck-and-thinking is time well spent; twenty minutes of
spinning is suffering with extra steps, and nobody is marked on
suffering.

## Stuck on the problem, not the code

A different kind of stuck: the program runs fine and you do not know
what to build next. That one is never solved by staring harder at the
editor. Go back to the person you are building for — one question to
your client, as [[Interviewing Your Client]] describes, dissolves more
design paralysis than an afternoon of thinking about it alone.

The method for error messages specifically is
[[Reading an Error Message]]; the reason none of this should embarrass
you is [[Mistakes Are Data]].
