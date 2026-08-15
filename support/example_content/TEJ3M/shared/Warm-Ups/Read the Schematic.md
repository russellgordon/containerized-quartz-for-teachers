---
title: Read the Schematic
publish: true
created: __CREATED__
tags:
  - warm-ups
---
This one is new for Grade 11, and it exists because a schematic is the
only document in this course that every other document depends on. A
drawing goes up — five to fifteen components, values marked — and the
task is to *read* it aloud the way you would read a paragraph: rails
first, then ground, then one loop at a time, naming every component
and what it is there to do.

## How to run it

1. Show the schematic. Two quiet minutes this time, not one — reading
   is slower than recognising.
2. One student reads the supply rails and ground aloud. Another names
   every component and its value. A third traces one complete loop
   from the positive rail back to ground, out loud, without skipping.
3. The class asks one question the drawing does not answer. There is
   always at least one, and finding it is the skill.
4. Finish with a prediction: name one node and give the voltage you
   expect there. That is where this routine hands off to
   [[Predict the Circuit]].

## The reading order

Every schematic gets read in the same order, and the order is not
arbitrary — it is the order that makes the rest of the drawing make
sense.

```mermaid
graph LR
    A["Find the rails"] --> B["Find ground"]
    B --> C["Name every part<br/>and its value"]
    C --> D["Trace one loop,<br/>rail to ground"]
    D --> E["Predict a node<br/>voltage"]
```

Rails and ground first, because every other voltage in the drawing is
measured against ground and fed from a rail. Parts and values second,
because a component with no value is a component you cannot compute
with. One loop third — one, not all of them — because tracing a
single complete path is how you find out whether you actually
understand the topology or have only recognised the shapes.

## What the drawing is not telling you

A schematic shows connections, never positions. Two wires that cross
are not joined unless a dot says so; two points labelled `GND` at
opposite corners of the page are the *same node* even though nothing
visibly connects them. Physical layout, wire length, and which side
of the board a part sits on are all absent by design — that is what a
board layout is for. The gap between the schematic and the object on
your bench is where most wiring faults live, which is exactly why
[[Reading Schematics]] and [[Documenting Your Build]] are two
different pages.

> [!tip] Read a drawing of something you already built
> The best round of this routine uses a schematic of a circuit the
> class has already had on the bench. Reading the drawing of a thing
> whose behaviour you remember is how the symbols stop being symbols
> — and it is the cheapest possible rehearsal for the day a drawing
> arrives for something you have never seen.
