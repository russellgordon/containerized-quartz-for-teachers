---
title: Bench Power Supply Habits
publish: true
created: __CREATED__
tags:
  - tutorials
enableToc: true
---
A bench supply is not a wall socket with a knob. It is a test
instrument, and like every test instrument it tells you things — if you
have set it up so that it can. Used well, it is the cheapest fault
protection your board will ever have and a live readout of your power
budget. Used badly, it is a device for pouring amps into a wiring
error until something browns.

## Two modes, and the mode is a measurement

Every bench supply has two operating modes and moves between them
automatically.

- **Constant voltage.** The supply holds the voltage you set and
  delivers whatever current the circuit asks for, up to the limit.
- **Constant current.** The circuit has asked for more than the limit,
  so the supply holds the current at the limit and lets the voltage
  fall to whatever that requires.

Which mode the front panel says it is in is not a status message. It
is data about your circuit. A board you expected to draw 80 mA sitting
in constant current at your 150 mA limit, with the voltage collapsed to
2 V, is telling you there is a short — before anything gets hot enough
to smell. A board that flicks into constant current only when the motor
starts is telling you your inrush is larger than your budget.

Get in the habit of glancing at the mode indicator the way you glance
at a meter's range. It costs nothing and it has caught more student
faults than any other single thing in this room.

## The power-up ritual

Run this every time, in this order. It takes about twenty seconds once
it is a habit, and skipping it is how boards die.

- [ ] Output **off**. Nothing is connected yet.
- [ ] Set the voltage you actually want, with no load, and read it
      back on the display
- [ ] Set the current limit to a little above what the circuit should
      draw — you calculated that number when you designed the thing,
      so use it
- [ ] Connect the leads to the board, checking polarity twice; on a
      supply with separate terminals, confirm you are on the output
      you set and not the neighbouring channel
- [ ] Set the over-voltage protection, if the supply has it, a
      sensible margin above your rail
- [ ] Output **on**, then look at the mode indicator and the current
      reading before you look at anything else
- [ ] Confirm the voltage *at the board*, with a meter, not on the
      supply's display

Setting the current limit is the step people fudge. On most bench
supplies the honest way is: output off, short the output leads
together, turn the output on — the supply goes straight into constant
current — and adjust the current knob until the display reads the limit
you want. Then output off, remove the short, set your voltage. Shorting
the output of a current-limited bench supply is a normal operation it
is designed for, not a stunt, but confirm yours behaves that way before
you do it the first time. Supplies with a numeric entry or a "set"
preview make this easier and you should use it if you have it.

> [!important] The limit protects your board, not you
> At the voltages we use, the current limit is not a personal safety
> device — the supply cannot deliver a dangerous shock at 12 V through
> dry skin regardless of its setting. What the limit does is catch the
> wiring error before it turns a two-dollar part into an afternoon.
> Personal safety at this bench comes from
> [[Safety in the Lab]] and from never working on anything
> mains-referenced.

## Sense leads, and where the rail actually is

Your supply regulates at *its* terminals. Every millivolt lost in the
leads, the connector, and the breadboard rails is lost after the point
where the supply is looking, which is why a board can be at 4.1 V while
the front panel insists on 5.00 V. At 500 mA through 2 Ω of lead and
contact resistance, that is a full volt gone.

Two fixes, and they are not equivalent.

**Shorter and fatter leads.** Always worth doing, costs nothing, and
fixes most of it.

**Remote sense.** Better supplies have a second pair of terminals that
measure the voltage at the load and adjust the output to compensate.
Connect them at the point that matters — the board's input, not the
far end of a wire — and the supply will hold *that* point at your set
voltage.

> [!warning] A sense lead that falls off is worse than no sense lead
> If a remote-sense connection opens while the output is on, the
> supply sees a very low voltage at the load and pushes its output up
> trying to correct it. Some supplies detect this; not all do.
> Connect sense leads before turning the output on, check them, and
> disconnect them last.

## Series and parallel

Two supplies, two very different levels of caution.

**Series raises voltage.** Connect the positive of one to the negative
of the next and the total across your circuit is the sum. Three
things must be true: both outputs have to be genuinely isolated from
earth, each supply has to be rated for the current, and — the one that
matters — **you have now created a voltage that neither front panel is
displaying**. Two supplies at 30 V in series put 60 V across your
circuit, which is above the threshold where we stop treating this as
low-voltage work. Ask before you do it, every time.

**Parallel raises current, and mostly does not work.** Two constant
voltage sources connected in parallel do not share. The one set very
slightly higher supplies all the current until it hits its limit and
drops into constant current; the other one contributes nothing until
then. If your supply has a designed parallel or tracking mode, use it
as the manual describes. Otherwise, get a bigger supply.

## What current limiting does not protect against

Three things, all of which have surprised somebody.

- **The supply's own output capacitance.** There is a capacitor across
  the output terminals, and its stored energy is delivered in the
  first instant of a short regardless of what the current limit is set
  to. The limit governs the steady state, not the spike.
- **Current going the wrong way.** A motor that is being turned by
  something else is a generator, and most bench supplies cannot absorb
  current. The rail rises instead, sometimes far enough to damage
  everything on it. If your design can back-drive a motor — and any
  design in [[Close the Loop]] can — plan for where that energy goes.
- **Inrush.** A large bulk capacitor on your board looks like a short
  for the first few milliseconds. The supply will do exactly what you
  told it and current-limit, so the rail comes up slowly or not at
  all, and a microcontroller that expects a clean rise may not start.
  That is a design problem, not a supply problem, and
  [[Power Supplies and Regulation]] is where it gets solved.

## Reading the supply's own meters

Use them for trend and mode; do not quote them.

A bench supply's built-in displays are indicative. They are measuring
at the terminals, they are usually two or three digits, and their
accuracy specification is far looser than the handheld meter sitting
beside them. For anything going into your documentation, measure at the
load with a meter, and write down which instrument you used — the same
rule [[Writing About Technology]] applies to every number.

What the supply's current reading *is* excellent for is your power
budget in real time. Write down the idle current, the working current,
and the peak, with the condition each was measured under. Those three
numbers are the beginning of the power section of
[[The Specification]], and they are the numbers your capstone's battery
or supply choice will be defended with.

> [!tip] Turn the output off, not the voltage down
> Winding the voltage to zero and back up again ramps your circuit
> through every intermediate voltage, including the region where a
> microcontroller is powered enough to be confused but not enough to
> run. Use the output button. It exists for exactly this reason, and
> it makes your power-up repeatable — which matters the day you are
> trying to reproduce a fault that only happens at start-up.

%%curriculum-start%%
## Curriculum connection

![[D1.1]]

![[D1.2]]
%%curriculum-end%%
