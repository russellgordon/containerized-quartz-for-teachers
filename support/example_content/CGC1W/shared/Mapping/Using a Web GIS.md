---
title: Using a Web GIS
draft: false
created: __CREATED__
tags:
  - mapping
  - unit-2
---
A geographic information system is a stack of layers you can ask questions
of. A paper map answers the questions its maker anticipated; a GIS answers
the ones you think of afterwards, because the data underneath are still
data rather than ink.

## Layers

Each layer is one kind of thing — watersheds, roads, land cover, census
boundaries, mining claims — with its own geometry and its own table of
attributes. The analysis happens in the comparison. A mine site alone is
unremarkable; a mine site, a watershed boundary and a treaty boundary
stacked together is an argument.

The rule that saves you: **one layer, one source, one date.** Layers from
different years stacked without saying so produce a confident conclusion
about a situation that never existed.

## Queries

Three questions cover most of this course. **What is here?** — click a
feature, read its attributes. **Where is everything that matches?** —
select by attribute, such as every parcel zoned agricultural. **What is
near what?** — select by location, such as everything within 500 m of a
shoreline.

The third is where a GIS earns its keep. Distance and adjacency are
tedious by hand and instant here, and most geographic arguments are
secretly about proximity.

## What it cannot do

A GIS will not tell you whether a boundary is disputed, when a layer was
last checked, or whom it was made for. Those questions stay with you —
[[Judging a Source]].

## Getting access, honestly

| Tool | Cost | What you need | Lead time |
| --- | --- | --- | --- |
| ArcGIS Online, via Esri Canada K-12 | Free to Canadian K-12 schools | A teacher requests an account, then requests student accounts separately | Days to weeks — ask early |
| Toporama | Free | Nothing | None |
| Ontario's data catalogue and GeoHub | Free, Open Government Licence – Ontario | Nothing to browse or download | None |
| Google Earth Web | Free | A Google account to save a Project | None |
| QGIS, installed | Free and open source | Installation on lab machines | Ask the school's technicians first |

Esri Canada states that all Canadian K-12 schools have free access to
ArcGIS for classroom use, but it is **request-based, not self-serve** — a
teacher applies first, and student accounts are a second request only a
teacher or guardian can make. Start at
[k12.esri.ca/ontario](https://k12.esri.ca/ontario/) and assume it takes
time.

The no-login options are real work, not consolation prizes:
[Toporama](https://atlas.gc.ca/toporama/en/index.html) for federal
topographic layers, [Ontario's data
catalogue](https://data.ontario.ca/dataset/greenbelt-outer-boundary) for
provincial boundaries such as the Greenbelt, and [Google Earth
Web](https://earth.google.com/web/) for measuring distances and areas in
the browser (all accessed August 2026).

Then make something with it in [[A Map of Your Own]] and
[[The Region Study]].

%%curriculum-start%%
## Curriculum connection

![[A1.4]]

![[A2.4]]
%%curriculum-end%%
