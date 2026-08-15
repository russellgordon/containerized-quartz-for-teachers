---
title: Debugging Step by Step
publish: true
created: __CREATED__
tags:
  - tutorials
---
[[Debugging Is the Job|Debugging is the job]] — here is the method.
It has five steps, and the discipline is doing them *in order* instead
of changing things at random and hoping.

1. **Read the message. All of it.** Bottom line first — that is the
   diagnosis. Do not groan and re-run; the answer is on the screen.
2. **Find the line.** The traceback names the file and line number.
   Go there and read what the line *actually* says, not what you
   meant it to say.
3. **Form ONE hypothesis.** A sentence: "I think it crashes because
   ___." If you cannot finish the sentence, gather more information —
   [[Getting Unstuck]] shows how — before touching anything.
4. **Test it.** What would be true if your hypothesis were right?
   Check *that*, cheaply — print the suspect value, try the failing
   input by hand.
5. **Change ONE thing.** Then run again. One change per run, always —
   change three things and you no longer know which one mattered, even
   if it works.

## A worked example

The program:

```python
temperature = input("Temperature today: ")
if temperature > 30:
    print("Heat warning!")
```

The crash:

```
Traceback (most recent call last):
  File "weather.py", line 2, in <module>
    if temperature > 30:
TypeError: '>' not supported between instances of 'str' and 'int'
```

**Read:** something cannot be compared — a `str` and an `int`.
**Line:** 2, the comparison. **Hypothesis:** "I think `input()` gave
me text, so `temperature` is the *text* `"25"`, not the number 25 —
[[Data in Programs|type matters]]." **Test:** add
`print(type(temperature))` — it prints `<class 'str'>`. Confirmed.
**One change:** `temperature = int(input("Temperature today: "))`.
Run. Fixed — and you know *why*, which is the part that transfers.

This is the same hunt [[Spot the Bug]] warms up every week, and steps
3 to 5 are just the scientific method wearing a lanyard. When the
message alone is not enough, [[Finding Answers Online]] is step six.

%%curriculum-start%%
## Curriculum connection

![[C2.6]]
%%curriculum-end%%
