---
title: Reading a Spec Sheet
publish: true
created: __CREATED__
tags:
  - tutorials
---
Every part in this lab arrives with a spec sheet, and every spec
sheet is written twice: once by engineers, in precise terms, and
once by marketing, in large friendly numbers. A technician reads
past the second to reach the first. This page is the decoder ring —
[[Spec Sheet Practice]] drills it, and [[The Build Sheet]] is where
you will use it with a budget on the line.

## Three questions every spec answers

- **Capacity — how much fits?** Gigabytes of storage, gigabytes of
  memory. Watch the units doing quiet work: a "500 GB" drive shows
  up smaller once formatted because GB and GiB measure "giga" two
  different ways. Nobody lied; two definitions shook hands badly.
- **Speed — how fast does it move?** GHz for processor clocks, MHz
  for memory, MB/s for drives, Mb/s for
  [[Networking Basics|network gear]] — and note the small b: bits,
  not bytes, an eightfold difference the box is happy to blur. A
  speed number means nothing alone; 3200 only matters next to the
  2666 beside it on the shelf, at that price difference.
- **Compatibility — does it fit?** Socket, connector, form factor,
  voltage. This is the question marketing never answers and the one
  that wastes the most money: the fastest memory ever made is
  worthless in [[The CPU and Memory|a board]] with the wrong slots.

## Marketing numbers vs useful numbers

"Up to" is the tell. "Up to 6 Gb/s" describes the connector's
ceiling on its best day, not the part's real, sustained rate. The
antidote is precise terminology — device name, capacity, speed,
bandwidth, connector type, in units you can actually compare — and a
technician's reflex: when two numbers disagree, the boring one is
true.

## Manuals first

The authoritative version of every claim is the manufacturer's own
manual and spec page — not the retailer's blurb, not a forum's
memory of it. Finding that document for an exact model number is a
core technician's move; [[Finding Answers Online]] shows the
searching half of it.

%%curriculum-start%%
## Curriculum connection

![[A1.2]]

![[B4.3]]
%%curriculum-end%%
