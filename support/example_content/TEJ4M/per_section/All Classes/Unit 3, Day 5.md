---
title: Unit 3, Day 5
publish: true
created: __CREATED_CLASS_41__
transcludeTitleSize: h2
enableToc: false
excludeBacklinks: true
tags:
  - unit-3
---
## Agenda

1. Warm-up: [[Name That Part]] — the motor driver round: three
   packages, one heatsink, one flyback diode
2. Bench: drive a motor from the loop you built last class. Predict
   the stall current from the winding resistance, then measure the
   running current and account for the difference
3. Protection in order, checked by a second pair of eyes before power:
   separate supply, common ground, flyback diode, current limit
4. The program has outgrown a single file:
   [[Structuring a Larger Program]] — one place for pin numbers, named
   constants, and functions with jobs you can say out loud
5. Log the driver's measured temperature under load and compare it
   against what [[Reliability and Derating]] would accept

## Things to do before our next class

- [ ] Refactor your control code so no pin number appears twice.
- [ ] Journal: the protection component you would refuse to omit, and
      what happens without it.
