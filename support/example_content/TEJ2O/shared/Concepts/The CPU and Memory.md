---
title: The CPU and Memory
publish: true
created: __CREATED__
tags:
  - concepts
enableToc: true
---
Under the biggest heatsink in [[Take It Apart]] sat the smallest star
of the show — a chip about the size of a cracker that does essentially
one simple thing, billions of times a second.

## Fetch, execute, repeat

The CPU is not clever. It fetches one instruction from memory, carries
it out — add these, compare those, copy this over there — and fetches
the next. That loop is the fetch–execute cycle, and it is the whole
trick. Clock speed, quoted in gigahertz, is how many times the loop
runs per second, in billions. The magic is volume, not wit.

## Workbench and shelf

RAM is the workbench: everything the CPU is working on right now sits
there, close at hand. [[Storage and Drives|Storage]] is the shelf at
the back of the shop — far bigger, much slower, and the only place
anything survives the lights going out.

|              | RAM — the workbench | Storage — the shelf           |
| ------------ | ------------------- | ----------------------------- |
| Holds        | work in progress    | everything the machine keeps  |
| Speed        | nanoseconds         | microseconds to milliseconds  |
| Power off    | wiped blank         | keeps it all                  |
| Typical size | 8–32 GB             | 500 GB and up                 |

The two error messages are different complaints: "out of memory" is a
crowded workbench; "disk full" is a full shelf. Adding one never fixes
the other.

## Saying it precisely

A spec sheet states these parts in exact terms — cores, clock speed in
GHz, RAM capacity in GB and its own speed in MHz. Precise terminology
is what lets two technicians agree on what a machine can do without
opening it. [[Reading a Spec Sheet]] shows how to read those lines
without flinching, and in [[Build a Workstation]] you match them so
the parts you choose actually work together.

%%curriculum-start%%
## Curriculum connection

![[A1.2]]

![[A1.3]]
%%curriculum-end%%
