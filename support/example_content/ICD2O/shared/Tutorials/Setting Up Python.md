---
title: Setting Up Python
draft: false
created: __CREATED__
tags:
  - tutorials
---
Python is the language this course programs in, and you need a place
to run it — in class and, ideally, at home. Good news: the zero-setup
option takes about thirty seconds.

## In the browser — zero setup

Any online Python interpreter will do: search for one, open it, and
you have a box to type code in and a Run button. Nothing to install,
nothing to configure, works on any machine including a library
computer or a locked-down school laptop. This is what we use in class,
and it is completely enough for this course. If one site is down or
ad-cluttered, pick another — they are interchangeable.

## On your own computer — for the curious

Installing Python locally is optional but worth it if you have your
own machine: it works offline and matches how professionals run code.
Download the installer from the official Python site (python.org),
accept the defaults, and use the included IDLE editor to write and
run programs. If anything goes wrong, [[Finding Answers Online]] is
made for exactly this — and installation problems are the classic
first use of it.

## The first program checklist

Wherever you run it, type this — do not paste it — and run:

```python
name = input("What is your name? ")
print("Hello,", name)
```

- [ ] It asks the question, waits, and greets you by name
- [ ] Change the greeting text, run again — your change shows up
- [ ] Add a second question and a second reply, all by yourself

If it crashes instead: capital letters matter (`print`, not `Print`),
and every opening quote and bracket needs its closing twin. Read the
error before retyping — [[Debugging Step by Step]] shows how — and
know that a crash on your first program is the traditional welcome to
programming. You now have everywhere you need to
[[Data in Programs|start building]].

%%curriculum-start%%
## Curriculum connection

![[C2.1]]
%%curriculum-end%%
