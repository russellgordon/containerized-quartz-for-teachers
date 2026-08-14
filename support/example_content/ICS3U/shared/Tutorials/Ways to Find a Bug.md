---
title: Ways to Find a Bug
draft: false
created: __CREATED__
tags:
  - tutorials
enableToc: true
---
Guessing is a debugging method. It is simply the worst one, and it is
the one everybody reaches for first. Here are five that work, roughly
in the order you should try them.

## 1. Read the message

Free, immediate, and skipped constantly. The error names the file, the
line, the kind of failure, and often the value that caused it.
[[Reading an Error Message]] takes this apart properly. Only when the
message is genuinely unhelpful — or when there is no message, because
the program runs and is simply wrong — do you need the rest of this
page.

## 2. Print what you believe

Put a `print()` immediately before the line that misbehaves, showing
the values you *think* are there:

```python
print(f"before the loop: total={total}, count={len(readings)}")
```

You are not printing to see the output. You are printing to find the
first place where the machine disagrees with you. That place is the
bug, or its neighbour. Delete these lines when you are done — a program
littered with debug prints is one somebody will mistake for output.

## 3. Cut the program in half

If the fault is somewhere in sixty lines, do not read sixty lines. Put
a print in the middle. Is the state right there? Then the fault is in
the second half; if not, the first. Repeat. Six halvings find the line
in a program of sixty, and the method does not care how clever the code
is.

## 4. Step through it with the debugger

When you need to watch values change rather than sample them, use the
debugger: set a breakpoint, run, and step line by line while it shows
you every variable. [[Using the Debugger]] is the how-to. This is the
right tool for a loop that goes wrong on the fourth pass, where
printing gives you four screens of output to squint at.

## 5. Make the failing case smaller

Take the input that breaks it and cut it down: forty lines of data
become four, then one. A bug that survives on one line of input is
nearly always obvious. A bug that disappears when you shrink the input
has just told you something real — the size, or a specific row, is the
trigger.

## When none of it works

| Symptom | Try this |
| --- | --- |
| It worked ten minutes ago | Compare with your last backup or archive |
| It works for you, not for them | Different file, different folder, different Python |
| It fails only sometimes | Something outside the program: input, a file, the clock |
| You have stared at it for twenty minutes | Explain it out loud to somebody, line by line |

That last one has a name — rubber-duck debugging — and it is not a
joke. Saying "this line reads the file, this line splits it, this line
adds it to the…" is how most bugs are found, because saying it forces
you to check what you assumed. [[Getting Unstuck]] is the fuller
version of what to do when the twenty minutes are up.

%%curriculum-start%%
## Curriculum connection

![[B4.5]]

![[A4.1]]

![[A4.4]]
%%curriculum-end%%
