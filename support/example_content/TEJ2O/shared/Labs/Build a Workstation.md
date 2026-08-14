---
title: Build a Workstation
publish: true
created: __CREATED__
tags:
  - labs
enableToc: true
---
Today runs [[Take It Apart]] in reverse — from a bin of parts (or
your own teardown notes) to a machine that powers on and passes POST,
the power-on self-test that is the build's moment of truth. And not
just working: built to a standard a technician would sign, which is
what [[The Build Sheet]] asks you to prove.

> [!danger] Safety notes
> **The machine stays unplugged until the final check** — assembly
> happens dead, and first power-on waits for your teacher's
> once-over. **The power supply stays sealed**, cabled from the
> outside only. **ESD discipline throughout** — strap on, each part
> in its bag until seated ([[Anti-Static Habits]]). **Mind the case
> edges**, and keep loose sleeves and cords away from the work.

## What you need

- [ ] Case, mainboard, CPU, cooler, memory, storage, power supply
- [ ] Your teardown photos and notes from [[Take It Apart]]
- [ ] Screwdriver set, anti-static strap and mat
- [ ] The screws you bagged and labelled — this is their moment

## The work

1. **Seat the CPU first, outside the case.** Match the alignment
   marks and let it drop in — a CPU seats with zero force, so any
   resistance means wrong orientation, not push harder.
2. **Mount the cooler** with a small central dot of thermal paste —
   paste fills microscopic gaps; too much insulates instead.
3. **Click in the memory** until both latches close on their own —
   half-seated memory is the top reason a build stays dark.
4. **Stand the mainboard on its standoffs** — one under every screw
   hole, none anywhere else. A stray standoff is a short circuit
   waiting for power.
5. **Cable power and drives**, checking each connector's shape first.
   Keyed connectors fit one way; force is a sign, not a solution.
6. **Wire the front-panel header** — power switch, lights — with a
   teardown photo beside you. The fiddliest step, and the usual
   reason a machine "will not turn on".
7. **Route cables the way a technician would** — clear of fans,
   along the edges, traceable by the next person. [[Cable Habits]]
   is the standard to hit.
8. **Check the build against its future operating system** — enough
   memory and storage? [[Reading a Spec Sheet]] tells you what
   [[Install an Operating System]] will demand next lab.
9. **Teacher check, then power on.** One beep or a splash screen is
   POST passing — the machine took attendance of its own parts, and
   everyone answered.

## What can go wrong

- **Nothing at all happens.** Work the power chain: wall, supply
  switch, front-panel header. It is almost always step 6.
- **Fans spin, screen stays black.** POST is failing — reseat the
  memory first, then listen: beep codes are the board naming the
  part that did not answer.
- **A rattle or grind at power-up.** Power off now — a loose screw
  or cable has found a fan blade. Routing is not cosmetic.

## Level up

Swap builds with another bench and inspect each other's work like an
incoming technician: would you sign it? Trade one concrete
improvement each, and log the inspection in your [[Tech Journal]].

%%curriculum-start%%
## Curriculum connection

![[B1.1]]

![[B1.2]]
%%curriculum-end%%
