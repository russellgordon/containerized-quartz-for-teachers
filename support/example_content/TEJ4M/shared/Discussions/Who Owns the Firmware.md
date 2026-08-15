---
title: Who Owns the Firmware
publish: true
created: __CREATED__
tags:
  - discussions
enableToc: true
---
You bought the device. It is on your desk, you paid for it, nobody
disputes that the plastic and the copper are yours. Now open it,
replace a failed part, and tell it to trust the replacement. Or read
the code out of its flash so you can find out why it does the annoying
thing it does. Or install your own firmware on hardware that is
otherwise perfectly good but no longer supported.

At each of those steps something may stop you, and the thing stopping
you is usually not a screw. It is a design decision, made deliberately,
by an engineer with a reason. This year you are becoming that engineer,
which is why this argument belongs here rather than in a law class.

## What you actually bought

In most consumer transactions you buy the physical object outright and
receive a **licence** to the software inside it. The licence is a
permission, granted on conditions, and it can prohibit things that
ownership would normally allow — modifying, reverse-engineering,
redistributing. The distinction feels like a technicality until the
day it decides whether you may fix your own property.

Canadian copyright law has historically protected **technological
protection measures** — the digital locks themselves — so that
breaking a lock could be an offence even where what you did afterwards
was legal. Parliament has since amended the Copyright Act to create
exceptions permitting circumvention for diagnosis, maintenance, and
repair, and for interoperability between products. That is a genuine
change in the balance, and it is worth knowing the shape of it rather
than the slogan on either side.

## The mechanisms, and who each one serves

Every lock in this table is real engineering with a real purpose. Each
one also takes something from the owner. Both halves are true at once,
and pretending otherwise is how this argument goes bad.

| Mechanism | What it protects | What it prevents |
| --- | --- | --- |
| Signed firmware and secure boot | Malware cannot replace the code that runs on the device | You cannot replace it either, including after support ends |
| Locked bootloader | A stolen device cannot be trivially repurposed | Alternative firmware on hardware you own |
| Flash readout protection | Design work and keys stay out of a competitor's hands | Anyone diagnosing a fault from the code, including you |
| Parts pairing and serialisation | Counterfeit or unsafe replacement parts get rejected | Independent repair with a genuine, working part |
| Cloud dependency for core function | Features that genuinely need a server | The device outliving the server |

Notice that the first column is not dishonest. A signed-firmware scheme
really does stop a class of attack that matters, and
[[Security by Design]] explains why. The question this discussion asks
is not whether the mechanisms work. It is who holds the key, for how
long, and what happens to the object when they stop caring.

## The end-of-support problem

A device that is safe and functional today, with no security updates
in three years, is a different device. Nothing physical changed. The
threats did. This is the same reasoning as
[[Reliability and Derating]] applied to software: the failure is slow,
invisible, and entirely predictable from the day the product shipped.

So who is responsible? The manufacturer who stopped shipping updates
and cannot be forced to continue? The owner who kept using it? The
regulator who never required a supported lifetime to be declared on
the box? A designer who publishes the source at end of support has
transferred the ability to maintain the thing. A designer who does not
has ensured the device becomes waste on a schedule they chose.

## Your own capstone is a case study

You will design something. Somebody may one day need to fix it without
you in the room. Three decisions land on you, and none of them has an
obvious right answer:

- Do you publish your schematics, your bill of materials, and your
  source? Under what licence? Some open licences require anyone who
  distributes a modified version to publish their changes too — a
  condition that spreads openness by contract rather than by goodwill.
- Do you leave the programming header fitted and documented, or remove
  it so nobody can read your code off the board?
- Do you write the maintenance section of your documentation for a
  stranger, or for yourself?

## Questions worth arguing about

1. A manufacturer refuses to sell a replacement part to an independent
   repair shop, citing safety. When is that a real safety argument and
   when is it a market one? What evidence would tell them apart?
2. Signed firmware protects users who will never modify anything and
   blocks users who would. Design a scheme that serves both — then
   name what your scheme gives up, because every version of it gives
   something up.
3. If a company stops supporting a device, should it be required to
   publish enough for others to maintain it? Who would enforce that,
   and what would it do to the incentive to build the thing in the
   first place?
4. You wrote the firmware. Your school owns the equipment. The
   student who takes this course next year wants to extend it. Who
   decides, and what should the default be?
5. Repairability and security pull in opposite directions on a device
   an attacker can hold in their hands. Where would you personally set
   that dial for a doorbell camera, and where for an insulin pump?
   Explain what makes the two different.

The bench answer to all of this is in your own documentation. A device
whose schematic, bill of materials, and test procedure are published in
the form [[Writing Documentation Somebody Can Build From]] describes is
repairable by construction, regardless of what anybody's licence says —
and the argument about whether it *should* be secured against you is
one you are now qualified to have.

%%curriculum-start%%
## Curriculum connection

![[D2.2]]

![[C2.2]]

![[D2.1]]
%%curriculum-end%%
