---
title: Hardware Inside the Box
publish: true
created: __CREATED__
tags:
  - concepts
enableToc: true
---
When the case came off in [[Inside the Box]], the mystery mostly
evaporated. A computer is a small number of parts, each with one job,
connected so they can hand work to each other. Every device you own —
laptop, phone, console, the watch on your wrist — is these same parts
at different sizes.

## The CPU

The central processing unit is the follower of instructions — the
part that actually computes. It does nothing but fetch the next tiny
step and carry it out, billions of times per second, with exactly the
no-judgement literalness you met in [[The Sandwich Robot]]. Fast is
its only talent.

## Memory and storage

These two get confused because both "hold things", but the jobs
differ. Memory — RAM — is the desk: whatever you are working on right
now sits there, reachable instantly, and it is swept clean the moment
the power goes off. Storage — the SSD or hard drive — is the
backpack: slower to dig through, but everything in it survives the
trip home. When your laptop "runs out of space", that is storage;
when it chokes on twenty open tabs, that is memory.

## Input and output

Input devices carry information in: keyboard, mouse, trackpad,
microphone, camera, and the touchscreen under your thumb all day.
Output devices carry results out: screen, speakers, printer, the
little motor that vibrates against your wrist. Some hardware works in
both directions — a touchscreen displays and listens at once.

## How the parts work together

```mermaid
flowchart LR
    A[Input] --> B[CPU]
    B <--> C[Memory]
    B <--> D[Storage]
    B --> E[Output]
```

Every program you write this term travels this loop: input comes in,
the CPU works on it using memory, results go out — and anything worth
keeping gets written to storage. [[Connected Devices]] shows what
happens when these parts shrink, multiply, and start talking to each
other.

%%curriculum-start%%
## Curriculum connection

![[B1.1]]
%%curriculum-end%%
