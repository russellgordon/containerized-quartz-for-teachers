---
title: Food Webs and Trophic Levels
createdSection1: 2026-10-01T07:00:00.000-0400
draftSection1: false
createdSection2: 2026-10-02T07:00:00.000-0400
draftSection2: false
enableToc: true
tags:
  - biology
---
## The idea

A **food chain** is a single path: grass → grasshopper → frog → hawk. Reality is
messier, because most organisms eat several things and are eaten by several
others. Draw all of those arrows at once and you have a **food web**.

```mermaid
graph BT
    G["Grass"] --> GH["Grasshopper"]
    G --> MO["Mouse"]
    GH --> FR["Frog"]
    GH --> SP["Spider"]
    MO --> HA["Hawk"]
    FR --> SN["Snake"]
    SP --> FR
    SN --> HA
    HA --> DE["Decomposers"]
    SN --> DE
    FR --> DE
```

Arrows point **in the direction the energy travels** — from the eaten to the
eater. Students get this backwards constantly; the arrow is not "eats".

## Reading a web

Two questions to ask of any food web:

1. **What happens if one species disappears?** Trace every arrow leading out of
   it. Everything downstream is affected.
2. **Which species has the most arrows?** Removing that one causes the most
   disruption. Ecologists call it a **keystone species**.

> [!example] Sea otters and kelp
> Otters eat sea urchins. Urchins eat kelp. Remove the otters and the urchin
> population explodes, the kelp forest is grazed to bare rock, and every species
> that lived in the kelp goes with it. The otter never touched the kelp.

Practise this in [[Reading a Food Web]].

## Curriculum connection

![[B2.2]]

![[B2.5]]
