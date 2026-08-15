---
title: Anti-Static Habits
publish: true
created: __CREATED__
tags:
  - tutorials
---
Walk across a dry carpeted floor and touch a door handle: the snap you
feel is thousands of volts. You do not notice a discharge at all until
it is somewhere around two thousand, which means every discharge below
that threshold happens without your knowledge — and the input
structures inside a MOSFET or a modern logic chip can be damaged well
below a hundred. That gap is the entire problem. Electrostatic
discharge is the only hazard in this lab you cannot see, hear, or
feel, and the only defence against a hazard you cannot detect is a
habit you perform whether or not it seems necessary.

If you built machines in the Grade 10 shop, you know the three habits
already. Grade 11 adds a reason to take them more seriously: you are
now handling bare parts rather than modules, and a bare MOSFET or a
logic IC out of its tube is far more exposed than a stick of memory in
a slot.

## The three habits

1. **Strap on before the parts come out.** The wrist strap goes
   against skin, and its cord clips to the bench's grounding point.
   It keeps you and the work at the same potential — no difference, no
   discharge. Strap first, then tools; off when you leave the bench,
   hung with the tools at reset.[^1]
2. **The bag rule.** Sensitive components live in their metallised
   shielding bags until the moment they are placed, and go straight
   back when removed. The bench is not a resting place for a bare
   chip, and a fleece sleeve is a generator. Note the difference
   between bag types while you are at it: the silvery shielding bags
   protect what is inside them from external fields, and the pink
   dissipative bags merely avoid generating charge themselves.
3. **Touch the ground point first.** No strap on — just passing a
   part across, or reaching in for ten seconds? Touch the grounded
   bench point or bare chassis metal first, every single time. Make
   it as automatic as reaching for a seatbelt.

Everything is worse in winter, when the heating dries the air out.
Humid air leaks charge away continuously; dry air lets you accumulate
it until something conductive comes within arcing distance. If the
room feels dry and your sleeve crackles, that is the day the habits
matter most.

## Handling, once the part is out

Hold components by their edges and their package body. Never touch
pins, leads, or gold contacts — partly because of charge, and partly
because skin oils on a contact cause connection faults that look
exactly like a dead component and waste an hour of anyone's time.

Set parts down on the anti-static mat, not on paper, not on a
notebook, and not on the plastic tray from the parts cupboard.

## What a spark actually costs

The obvious cost is a dead component and a real dent in a real shop
budget. The far worse cost is **latent damage**: a part that is
wounded rather than killed, works perfectly today, and fails
intermittently three weeks from now inside a finished build, with no
mark on it anywhere and nothing in your notes to point at.

No troubleshooting method finds that fault efficiently, because the
symptom is "sometimes". You will spend hours on it, and the hours will
be spent on a mistake made in a moment that felt like nothing. That is
the whole argument for a habit you perform even when it seems
unnecessary — you cannot know which of the thousand times it was the
one that counted.

[^1]: There is a resistor inside a wrist strap's cord, typically about
    one megohm. It is there for you, not for the electronics: it lets
    static drain away harmlessly while limiting the current that could
    flow through you if you touched something energised while
    strapped to ground. A strap with a damaged cord or a shorted
    resistor is not a safer strap — it is a broken one, so report it
    rather than using it.
