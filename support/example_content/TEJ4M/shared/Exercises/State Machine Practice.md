---
title: State Machine Practice
draft: false
created: __CREATED__
tags:
  - exercises
---
These follow [[State Machines]] and feed straight into
[[State Machines in Code]]. Most of the work here is on paper, and that
is the point — a machine you cannot draw and tabulate is a machine you
cannot test, and every hour spent on the table saves an evening at the
bench.

Several questions refer to this bench exhaust fan, whose transition table
you should keep beside you.

| State | Above 28 °C | Below 24 °C | Button | Timer expires | Sensor implausible | Reset held |
| --- | --- | --- | --- | --- | --- | --- |
| Idle | → Running | ignore | → Manual | ignore | → Fault | ignore |
| Running | ignore | → Purging | → Manual | ignore | → Fault | ignore |
| Purging | ignore | ignore | ignore | → Idle | → Fault | ignore |
| Manual | ignore | ignore | → Idle | ignore | ignore | ignore |
| Fault | ignore | ignore | ignore | ignore | ignore | → Idle |

## Reading a machine

1. A program uses five boolean flags: `running`, `manual`, `warming`,
   `fault`, and `door_open`. Calculate how many combinations of those
   flags exist. The device really has six sensible conditions — what is
   the risk represented by the difference, and what does a state machine
   do about it?
2. Starting in `Idle`, apply this sequence to the table above and give
   the state after each event: *above 28 °C, button, button, below
   24 °C, timer expires, sensor implausible, button, reset held*.
3. Suppose the code never generates the "reset held" event. Read the
   table and say exactly what happens the first time the sensor produces
   an implausible reading, and why this is worse than a crash.
4. The `Manual` row ignores the temperature events entirely. Is that a
   bug or a decision? Argue both sides in two sentences, and say what
   you would write in the specification either way.

## Designing one

5. Design a state machine for a garage door with a single button, an
   open limit switch, a closed limit switch, and an obstruction sensor.
   List your states and events, calculate the number of cells in the
   full transition table, and fill in the row for the state `Closing`.
6. A button must be debounced with 20 ms of stability before a press
   counts. Describe this as a state machine with three states, naming
   the events, and say why the timer must be checked rather than slept
   through.
7. Rewrite this fragment as a state machine. Name the states, give the
   transitions, and say which bug the rewrite removes.
   ```python
   if not manual:
       if temperature > 28:
           if not running:
               fan_on()
               running = True
       else:
           if running and temperature < 24:
               fan_off()
               running = False
   else:
       fan_full()
   ```
8. **Find the error.** A group implements the purge state like this, and
   reports that "the button stops working during a purge, but only
   sometimes":
   ```python
   if state == PURGING:
       fan.set_percent(40)
       time.sleep(30)
       state = IDLE
   ```
   Explain the fault precisely, explain the "only sometimes", and give
   the correct implementation.

## Answers

> [!success]- Answer 1
> Five independent booleans give $2^5 = 32$ combinations.
>
> **The risk:** 26 of those 32 combinations are conditions nobody designed, tested, or thought about — `running` and `fault` both true, `manual` and `warming` both true with the door open, and so on. Nothing in the program prevents them; they simply arrive when an unusual sequence of events occurs, which is why the resulting bugs are intermittent and hard to reproduce.
>
> **What a state machine does about it:** it replaces the flags with one variable holding one state from a list you wrote. The illegal combinations stop existing, because there is nowhere for them to be represented. You have gone from 32 possible conditions to 6, all of them intentional, and the difference is exactly the 26 bugs you no longer have to find.

> [!success]- Answer 2
> Walk the table one event at a time, and remember that "ignore" means the state does not change.
>
> 1. **above 28 °C** — Idle → **Running**
> 2. **button** — Running → **Manual**
> 3. **button** — Manual → **Idle**
> 4. **below 24 °C** — Idle: ignore → **Idle**
> 5. **timer expires** — Idle: ignore → **Idle**
> 6. **sensor implausible** — Idle → **Fault**
> 7. **button** — Fault: ignore → **Fault**
> 8. **reset held** — Fault → **Idle**
>
> **Final state: Idle.**
>
> Note events 4, 5, and 7. Two thirds of the interesting behaviour of a state machine is what it *refuses* to do, and none of that is visible in a diagram that only shows the arrows you drew.

> [!success]- Answer 3
> The machine enters `Fault` and stays there permanently. Every row of the `Fault` state ignores every event except "reset held", and if nothing in the program can generate that event, there is no path out. The fan stays off, the device looks dead, and only a power cycle changes anything — and then it will do it again.
>
> **Why this is worse than a crash:** a crash is loud. A traceback appears, a watchdog fires, somebody investigates. A machine sitting in an unreachable state is silent and looks like broken hardware, so the next person spends an afternoon metering a circuit that is fine.
>
> This is a **deadlock**, and the table is exactly the tool that reveals it: a state whose entire row is "ignore" is a state you cannot leave. Check for it deliberately — for every state, name the event that gets you out of it.

> [!success]- Answer 4
> **It is a decision** if it was made on purpose: manual means the operator has taken control, so the automatic thresholds must not override them. That is defensible, and common in real equipment.
>
> **It is a bug** if nobody thought about it, and it is dangerous in one specific respect: `Manual` also ignores the implausible-sensor event, so a fault that occurs while in manual is not detected at all. Automatic protections are usually kept live even when automatic *control* is handed over.
>
> **What to write either way:** a line in the specification saying so — "In manual mode, temperature thresholds are ignored; sensor fault detection remains active and forces the fan off." Then change the table to match. A behaviour that is in the table but not the specification is a behaviour nobody agreed to.

> [!success]- Answer 5
> **States (5):** `Closed`, `Opening`, `Open`, `Closing`, `Stopped`.
>
> **Events (4):** `button`, `open limit reached`, `closed limit reached`, `obstruction detected`.
>
> **Table size:** $5 \text{ states} \times 4 \text{ events} = 20$ cells, every one of which needs an entry even if it is "ignore".
>
> **The `Closing` row:**
>
> | State | button | open limit | closed limit | obstruction |
> | --- | --- | --- | --- | --- |
> | Closing | → Stopped | ignore | → Closed | → Opening |
>
> The obstruction cell is the one that matters and the one students most often leave blank. A door that is closing and meets an obstruction must **reverse**, not merely stop — stopping leaves whatever it hit still trapped. That is a safety requirement, it belongs in the specification with a source, and it is the kind of decision the table forces you to take explicitly.

> [!success]- Answer 6
> **States:** `Released`, `Bouncing`, `Pressed`.
>
> **Events:** the raw input reads low (button down), the raw input reads high (button up), and the 20 ms timer expires.
>
> - `Released` + input low → `Bouncing`, and start the timer.
> - `Bouncing` + input high → `Released` (it was a bounce, not a press).
> - `Bouncing` + timer expires, input still low → `Pressed`, and *this* is where the press is reported once.
> - `Pressed` + input high → `Released`.
>
> **Why the timer is checked, not slept through:** sleeping for 20 ms stops the entire program — the control loop, the other buttons, the safety checks — every single time anybody touches a contact. Record the time the state was entered and compare it against the clock on each pass, as `time.ticks_diff` does in [[Timing, Interrupts, and Real Time]]. The device stays responsive and the debounce still works.

> [!success]- Answer 7
> **States:** `Idle` (fan off, waiting for heat), `Running` (fan on, automatic), `Manual` (fan full, operator control).
>
> **Transitions:**
>
> - `Idle` + temperature above 28 °C → `Running`, entry action: fan on.
> - `Running` + temperature below 24 °C → `Idle`, entry action: fan off.
> - `Idle` or `Running` + button → `Manual`, entry action: fan full.
> - `Manual` + button → `Idle`, entry action: fan off.
>
> **Which bug the rewrite removes:** in the original, `manual` and `running` are independent variables. Enter manual while running and `running` stays `True`; leave manual and the code believes the fan is on when its own entry action may have turned it off — or worse, the fan is left at full power because nothing on the way out of the manual branch turns it down. The three-way `if` also hides the fact that the temperature branch cannot execute at all while `manual` is true, so a fault developing during manual is invisible.
>
> With one state variable and entry actions, there is exactly one place that sets the fan for each condition, and the impossible combination cannot be represented.

> [!success]- Answer 8
> **The fault:** `time.sleep(30)` blocks the entire program for thirty seconds. During that time nothing else runs — no button polling, no sensor reading, no plausibility check, no watchdog feeding. The fan is at 40% and the device is, for practical purposes, unresponsive.
>
> **Why "only sometimes":** the button is only *sometimes* pressed during those thirty seconds. A press during the purge is not queued or remembered — the pin is simply never read, and by the time the loop resumes the button is back up. A press at any other time works normally. To the user this looks intermittent; it is completely deterministic once you know what the code is doing.
>
> There is a second, quieter fault: if the program uses a watchdog with a timeout shorter than 30 s, the board resets in the middle of every purge.
>
> **The correct implementation** records when the state was entered and checks the clock on each pass:
>
> ```python
> PURGE_MS = 30000
>
> # on entering PURGING:
> fan.set_percent(40)
> state_entered_ms = time.ticks_ms()
>
> # once per pass through the main loop:
> if state == PURGING:
>     if time.ticks_diff(time.ticks_ms(), state_entered_ms) >= PURGE_MS:
>         enter(IDLE, time.ticks_ms())
> ```
>
> Now the purge takes thirty seconds and the loop still runs hundreds of times a second underneath it. Note `ticks_diff` rather than plain subtraction, because the millisecond counter wraps.
>
> Counting loop passes instead — 300 passes at a nominal 100 ms — is the other tempting answer, and it is wrong for a reason worth knowing: the loop period is *nominal*. Any pass that takes longer stretches the purge, and the error accumulates invisibly. Ask the clock.

Draw your own device's machine before you write its code, bring the
diagram and the completed table to the design review for
[[The Control System]], and check that every state has a way out. The
table is the deliverable, not a rough draft of one.
