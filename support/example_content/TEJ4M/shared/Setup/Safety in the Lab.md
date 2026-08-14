---
title: Safety in the Lab
draft: false
created: __CREATED__
tags:
  - setup
enableToc: true
---
This course puts real instruments, real heat, and real stored energy in
your hands, and then asks you to design things other people will switch
on. That is the best thing about it, and it stays the best thing only
in a lab where safety is everyone's habit rather than a poster. This
agreement binds everyone in the room, including your teacher.

Grade 10 had three absolutes. Grade 11 had four. This year there are
still four on the bench — and a fifth that is not about the bench at
all.

> [!danger] The four bench absolutes
> **Nothing gets energised** without the go-ahead and a second person
> in the room. **The supply's current limit is set before the leads go
> on**, never after. **Every ground clip goes to circuit ground**, and
> the earth pin on every instrument's plug stays where the
> manufacturer put it. **Anything smoking, sparking, smelling hot, or
> getting hot** — hands off, power off at the bench master switch, tell
> me, in that order.

> [!danger] And the fifth, which follows you home
> **You are now designing the hazard.** A missing flyback diode, an
> absent fuse, a part at 95 % of its rating, a safety function that
> exists only in software — none of those can hurt anybody today, on a
> current-limited bench, with you watching. All of them can hurt
> somebody later. Design review is a safety procedure in this room,
> not a marking scheme.

## What we agree to

- **We start with the walkthrough.** Every lab page opens with its own
  hazards and we read them together before tools move.
- **We do not work on mains.** Nobody in this course opens a
  mains-powered supply, probes a wall circuit, or works inside anything
  plugged into the wall. Our benches run on low-voltage,
  current-limited supplies, and that is deliberate. A damaged cord or a
  cracked plug gets reported and taken out of service, not used
  carefully.
- **Nobody defeats an earth pin, ever.** The adapter that "floats the
  scope" does not float the signal — it floats the whole instrument
  chassis, and every metal shell you are about to touch, to whatever
  potential you clipped to. The legitimate ways to measure between two
  non-ground points are in
  [[Using an Oscilloscope Properly]].
- **Supplies in series get asked about first.** Two supplies stacked
  can put a voltage across your circuit that neither front panel is
  showing, and it can leave the low-voltage regime entirely. Ask.
  [[Bench Power Supply Habits]] explains what else goes wrong.
- **Nobody works alone on anything powered.** A partner within arm's
  reach is part of the equipment, and that applies at lunch and after
  school exactly as it applies in class.
- **ESD is invisible and real.** Strap on, boards bagged until placed,
  ground point touched first. Third year running, and the parts are
  smaller and less forgiving than they were.
- **Heat is not visible.** A regulator doing its job can be far too hot
  to touch and look completely normal. Approach a suspect component
  with the back of a finger held *near* it, never a fingertip placed
  *on* it, and give it time after power off.
- **Tools go back, benches stay clear** enough to see every wire, and
  food and drink live outside the lab entirely.
- **Report every incident** — a burn, a cut, a shock however small, a
  blown fuse, a component that let its smoke out, a near miss.
  Immediately, no matter how minor it feels. Reporting is information,
  never trouble; see [[Getting Help]].

## Energy that is still there after you switch off

Switching a supply off does not empty a circuit, and this year your
circuits store more energy than they used to.

**Capacitors hold charge.** On low-voltage builds a charged
electrolytic is mainly a hazard to your circuit and your tools: short
one with a screwdriver and you get a bang, a pit in the blade, and
usually a destroyed capacitor. Empty it through a resistor, then check
with the meter that the voltage really has come down. Inside a
mains-powered supply the same components hold enough energy to injure
or kill, and can stay charged long after the unit is unplugged. That is
one of several reasons nobody in this course opens one, and why "I was
only going to look" is not a plan.

**Inductors fight being switched off.** A motor, a solenoid, or a relay
coil stores energy in a magnetic field, and interrupting its current
produces a voltage spike far above your supply rail. That spike
destroys the switching device, and it does it quietly enough that the
part often keeps working for weeks. Every inductive load you switch
gets a flyback diode or a snubber, designed in, every time.

**Motors turned by hand are generators.** A motor being back-driven
pushes current into your supply, and most bench supplies cannot absorb
it — so the rail rises instead. Plan for where that energy goes before
you build anything in [[Close the Loop]].

## Know where things are, before you need them

- [ ] The bench master switch for your bench, and the room's main
      cut-off
- [ ] The extinguisher rated for electrical fires, and the rule that
      water never goes on one
- [ ] The first aid kit, the eyewash station, and the nearest sink with
      running water
- [ ] Which exit you would use, from where you actually sit

Take thirty seconds and find all four now. In an incident nobody reads
signage; people go to what they already know.

## Safety is a professional practice, not a school rule

Every working technician follows these habits every day of their
career, and they have professional names. Isolating and locking out a
circuit before servicing it. Verifying that a supply is really dead
before touching it. Reporting near misses so the pattern gets found
before the injury does. Designing with margin under a rating so a hot
day does not become an incident.

None of that exists because somebody enjoys rules. It exists because
industries learned it expensively and wrote down what they learned so
the next generation would not have to. Learning these habits now *is*
learning the profession — and it is the same argument
[[When Good Enough Is Not Safe]] makes about the things you design for
other people to use. This year you are on the designing side of that
argument, which is exactly why
[[Standards and Professional Practice]] is a concept in this course
rather than a footnote.

- [ ] Read this page with a parent or guardian.
- [ ] Bring one question about anything above. We walk the lab and
      finalise our routines together in the first week, and this page
      stays linked from every lab for the rest of the semester.

%%curriculum-start%%
## Curriculum connection

![[D1.1]]

![[D1.2]]
%%curriculum-end%%
