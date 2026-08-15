---
title: Remote Sensing and Imagery
draft: false
created: __CREATED__
tags:
  - mapping
  - unit-2
---
Remote sensing is measurement without contact. A sensor records energy
reflected or emitted by a surface, and because different materials
reflect different wavelengths in different proportions, the record can be
turned into a statement about what is down there — vegetation health,
water temperature, burn severity, snow extent, or ground that has moved.

## Four resolutions, and the trade between them

| Resolution | Question it answers | Why it is limited |
| --- | --- | --- |
| Spatial | How small a thing can be seen | Finer detail means a smaller area covered |
| Temporal | How often the same place is revisited | More frequent usually means coarser |
| Spectral | How many wavelength bands are recorded | More bands means more data to handle |
| Radiometric | How finely brightness is graded | Sensor and downlink capacity |

You cannot maximise all four, so the sensor you want depends on the
question. Watching a fire evolve daily needs temporal resolution;
identifying which individual houses burned needs spatial.

## Bands you cannot see are the useful ones

Healthy vegetation reflects strongly in the near infrared and weakly in
visible red, so the difference between those two bands is a good index of
green biomass. Short-wave infrared distinguishes wet from dry and burned
from unburned, which is why a burn scar that is nearly invisible in a
natural-colour image is unmistakable in a short-wave infrared composite.
Thermal bands measure emitted heat and pick out urban heat islands and
active fire fronts. Radar supplies its own energy, so it sees through
cloud and at night — which is why flood extent is so often mapped from
radar rather than from an optical image.

## Where to get imagery, free

[NASA Worldview](https://worldview.earthdata.nasa.gov/) browses and
animates hundreds of daily global products and is the fastest way to see
a smoke plume or a flood on a chosen date. The
[Copernicus Browser](https://browser.dataspace.copernicus.eu/) serves
Sentinel-2 optical imagery at 10 m in some bands with a revisit of a few
days, and offers ready-made fire and moisture visualisations. Both were
free in August 2026; Copernicus asks for a free account.

> [!example] The before-and-after that proves something
> Pick the event date. Find the cleanest cloud-free image before it and
> the first after. Use the same area, same bands, same stretch. Then
> state what changed and what you cannot tell — a plume seen from orbit
> shows extent, not concentration at ground level, and a dark burn scar
> shows area, not severity.

Feed the result into [[Mapping a Hazard]] and check the ground truth
against [[Hazard and Disaster Records]].

%%curriculum-start%%
## Curriculum connection

![[E2.1]]

![[A1.4]]
%%curriculum-end%%
