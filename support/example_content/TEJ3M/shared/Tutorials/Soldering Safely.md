---
title: Soldering Safely
draft: false
created: __CREATED__
tags:
  - tutorials
enableToc: true
---
Soldering is the first thing in this course that can hurt you without
any electricity being involved. The tip runs at a few hundred degrees
and looks exactly the same hot or cold; the fumes coming off the joint
are not smoke; and the offcut you clip from a component lead leaves at
a surprising speed in an unpredictable direction. All of that is
manageable, and the management is entirely habit.

It is also the first thing in this course where the difference between
a good result and a bad one is invisible from a metre away and
catastrophic six months later. A joint that merely looks connected is
a fault waiting for vibration.

> [!danger] Four rules that do not bend
> The iron lives **in its stand** whenever it is not in your hand —
> not on the mat, not "just for a second". **Eye protection on**
> before any lead is clipped and while you solder. **The fumes go
> somewhere else**: extractor on, intake close to the joint, or work
> at a ventilated station. And **never solder a board that is
> powered or plugged in**; disconnect it, and discharge any large
> capacitor before you touch the board.

## Before the iron goes on

- [ ] Hair tied back, sleeves secured, nothing dangling from your neck
- [ ] Eye protection on
- [ ] Fume extraction running, with its intake within a hand's width
      of where you will be working
- [ ] Iron in its stand, cord routed so it cannot be dragged
- [ ] Tip clean and tinned — a wiping sponge damp, not soaking, or
      brass wool in its holder
- [ ] Board held in a vice or a clamp, because a joint you are also
      holding steady with your other hand is a joint you will move
- [ ] Bench clear of anything you would mind melting, and clear of
      anything to drink

## Making the joint

The single most common beginner error is melting solder on the iron
and carrying it to the joint. That produces a blob sitting on top of a
cold pad, connected to nothing. The metal has to be heated by the
*joint*, not delivered to it.

1. Touch the tip so it contacts the pad and the component lead at the
   same time. Give it a second or two.
2. Feed the solder into the joint on the far side from the tip — into
   the gap between lead and pad, not onto the iron.
3. Watch for the moment the solder flows and pulls itself into a
   smooth cone around the lead. That is wetting, and it is the whole
   event.
4. Take the solder away first, then the iron.
5. Do not move the joint while it cools. It takes about a second, and
   a joint disturbed while freezing is a joint that will fail.

Then clip the lead — pointing the offcut down and away, with your eye
protection on and preferably a finger over the end so it does not
launch across the room.

## Reading a finished joint

| Joint | What it looks like | What it means |
| --- | --- | --- |
| Good | Smooth concave fillet, wetting both the pad and the lead all the way round | Metal has actually alloyed with metal |
| Cold | Dull, grainy, ball-shaped, sitting on the pad rather than joined to it | Not enough heat, or the joint moved while cooling |
| Starved | A thin ring, gaps visible, lead not fully surrounded | Not enough solder, or poor wetting |
| Drowned | A fat blob hiding the lead entirely, possibly touching its neighbour | Too much solder; check for a bridge with the continuity beeper |

Fix a cold or starved joint by reheating it with a little fresh solder
— the flux inside the fresh solder is what makes it flow properly the
second time. Remove excess with desoldering braid and a touch of flux,
or with a solder sucker. Then verify with the continuity setting
described in [[Using a Multimeter]], because your eyes are not a test
instrument.

## Leaded and lead-free

Two families of solder exist in most shops, and they behave
differently enough that you should always know which one is in your
hand.

| | Tin-lead (Sn63/Pb37) | Lead-free (tin-silver-copper) |
| --- | --- | --- |
| Melting | Around 183 °C, and it melts all at once | Around 217–220 °C |
| Tip temperature | Lower | Higher, and the joint takes a little longer |
| Wetting | Flows readily | Flows less readily; technique matters more |
| Finished joint | Bright and shiny | Duller and slightly grainy — this is normal, not a cold joint |
| Why it exists | Long-established, easy to work | Required for most products sold, on health and environmental grounds |

> [!important] What the fumes actually are
> The visible smoke coming off a joint is vaporised **flux**, not
> lead — lead does not evaporate at soldering temperatures. That is
> not a reason to relax about it. Rosin flux fumes are a respiratory
> sensitiser: repeated exposure can produce asthma in people who
> previously had none, and once sensitised you stay sensitised. This
> is why extraction is a rule rather than a nicety.
>
> The lead risk is a *contact* risk instead. If you have handled
> leaded solder, wash your hands before you eat, and never eat at the
> bench. Both rules, together, cost nothing.

## When something goes wrong

- **A burn.** Cool it under cool running water for at least ten
  minutes — longer is better — and do not use ice, butter, or
  anything else. Then tell me, however minor it looks. Every incident
  gets reported, the way [[Safety in the Lab]] promises, because a
  report is information and never trouble.
- **Solder spits toward your face.** This is what the eye protection
  was for. Tell me immediately regardless of whether you think
  anything landed.
- **Something smells wrong or a component gets hot.** Iron in the
  stand, power off, hands away, then come and get me — in that order.
- **The tip stops picking up solder.** It has oxidised. Clean it and
  re-tin it; a dry, blackened tip transfers almost no heat, and
  turning the temperature up to compensate makes it worse.

Every joint you make in [[Solder a Board]] gets inspected and tested,
not admired. A build is not finished when it works once; it is
finished when somebody could reasonably expect it to keep working,
which is the argument running through
[[When Good Enough Is Not Safe]].

%%curriculum-start%%
## Curriculum connection

![[D1.1]]

![[D1.2]]
%%curriculum-end%%
