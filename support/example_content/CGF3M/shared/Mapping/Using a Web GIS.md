---
title: Using a Web GIS
draft: false
created: __CREATED__
tags:
  - mapping
  - unit-1
---
A geographic information system is a stack of layers that share a
coordinate system, so that anything can be compared with anything else in
the same place. The skill is not clicking; it is deciding which layers
belong in the stack and what their overlap would prove.

## The question comes first

Write the question in one sentence before you open anything: *which
buildings in this settlement lie below the modelled flood level?* That
sentence tells you the layers — building footprints, flood extent, and a
base map — and it tells you what the answer looks like. Open the software
first and you will produce a handsome map of nothing in particular.

| Layer type | Holds | Good for |
| --- | --- | --- |
| Point | One location each | Wells, gauges, earthquake epicentres, ignitions |
| Line | Connected locations | Rivers, faults, roads, evacuation routes |
| Polygon | Enclosed areas | Watersheds, flood extent, soil units, wards |
| Raster | A grid of valued cells | Elevation, imagery, slope, land cover, burn severity |

Elevation rasters earn their place in this course. A digital elevation
model can be processed into slope, aspect and flow direction, and from
flow direction into watershed boundaries — the same delineation you do by
hand in [[Reading a Topographic Map]], done consistently over a whole
region.

## Where to work

[Ontario GeoHub](https://geohub.lio.gov.on.ca/) publishes provincial
foundation layers — hydrography, elevation, imagery, transport —
downloadable and viewable in a browser. [geo.ca](https://geo.ca/) is the
federal geospatial platform across all provinces. Both were free and
account-free when checked in August 2026. Your conservation authority
almost certainly publishes its regulated-area and flood-plain mapping in
a viewer of its own; that is the most locally accurate hazard layer you
will find.

## Three rules that keep a stack honest

**Match the coordinate system**, or layers will sit metres to kilometres
from where they belong, silently. **Check scale suitability**: data
digitised for 1:250 000 has no business being read at 1:2 000, and it
will happily let you zoom in anyway. **Read the metadata** for the date,
the producer, and the accuracy statement — a layer without metadata is a
picture, not evidence.

> [!tip] Overlay proves association, not cause
> Two layers coinciding is a place to start an explanation, never the
> end of one. If landslides coincide with steep slopes *and* with a
> particular soil *and* with clearing, you have three candidates and a
> reason to go and look.

Turn a stack into a finished map in [[A Map of Your Own]].

%%curriculum-start%%
## Curriculum connection

![[A1.1]]

![[A1.4]]

![[B2.2]]
%%curriculum-end%%
