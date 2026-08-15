---
title: State Machines in Code
publish: true
created: __CREATED__
tags:
  - code
enableToc: true
---
[[State Machines]] left you with a diagram and a transition table on
paper. This page turns them into MicroPython that still matches the paper
in week three, when a fifth state has arrived and two people are editing
the file.

The rule that makes it work: the table is **data**, not control flow.
Written as data, the code and the diagram can be compared line by line by
somebody who did not write either.

## States and events, named once

```python
# states.py
# Bench exhaust controller state machine.
# R. Okafor, revision 4.

IDLE = "idle"
RUNNING = "running"
PURGING = "purging"
MANUAL = "manual"
FAULT = "fault"

EVENT_WARM = "warm"             # temperature rose above WARM_C
EVENT_COOL = "cool"             # temperature fell below COOL_C
EVENT_BUTTON = "button"         # debounced press
EVENT_TIMEOUT = "timeout"       # the current state's timer expired
EVENT_IMPLAUSIBLE = "implausible"   # sensor reading cannot be real
EVENT_RESET = "reset"           # button held down deliberately
```

Strings are used here because they print readably in a log, which matters
enormously when you are debugging with no debugger. On a board where
memory is tight, integers cost less; the structure below does not care
which you choose.

## The transition table, as data

```python
TRANSITIONS = {
    (IDLE,    EVENT_WARM):         RUNNING,
    (IDLE,    EVENT_BUTTON):       MANUAL,
    (IDLE,    EVENT_IMPLAUSIBLE):  FAULT,

    (RUNNING, EVENT_COOL):         PURGING,
    (RUNNING, EVENT_BUTTON):       MANUAL,
    (RUNNING, EVENT_IMPLAUSIBLE):  FAULT,

    (PURGING, EVENT_TIMEOUT):      IDLE,
    (PURGING, EVENT_IMPLAUSIBLE):  FAULT,

    (MANUAL,  EVENT_BUTTON):       IDLE,

    (FAULT,   EVENT_RESET):        IDLE,
}
```

Every key is a (state, event) pair and every value is the state you end
up in. A pair that is absent means "ignore this event in this state", and
that must be a decision you took rather than a line you forgot — which is
precisely why you filled in the paper table first.

Reading it back against the diagram takes about a minute, and it is the
cheapest review in this course. Note the deliberate absences: no button
during a purge, and no way out of `FAULT` except an explicit reset.

## Entry actions keep the outputs honest

The states decide *what the device is*. Entry actions decide *what the
outputs do* when it becomes that.

```python
import fan
import config


def on_enter_idle():
    fan.off()


def on_enter_running():
    fan.set_percent(60)


def on_enter_purging():
    fan.set_percent(40)


def on_enter_manual():
    fan.set_percent(100)


def on_enter_fault():
    fan.off()                      # the safe output for this device


ON_ENTER = {
    IDLE: on_enter_idle,
    RUNNING: on_enter_running,
    PURGING: on_enter_purging,
    MANUAL: on_enter_manual,
    FAULT: on_enter_fault,
}

STATE_TIMEOUT_MS = {
    PURGING: config.PURGE_MS,      # states not listed here never time out
}
```

Setting the outputs only on entry — never scattered through the loop —
means there is exactly one place in the program that can turn the fan on,
and one that can turn it off. When the fan does something unexpected, the
list of suspects is five functions long.

## The engine, which never changes

```python
import time

state = IDLE
state_entered_ms = time.ticks_ms()


def enter(new_state, now):
    """Move to new_state, run its entry action, restart its timer."""
    global state, state_entered_ms
    state = new_state
    state_entered_ms = now
    action = ON_ENTER.get(new_state)
    if action is not None:
        action()
    print(now, "state ->", new_state)     # the trace that saves you later


def handle(event, now):
    """Apply one event to the machine. Unknown pairs are ignored."""
    destination = TRANSITIONS.get((state, event))
    if destination is not None:
        enter(destination, now)


def timed_out(now):
    limit = STATE_TIMEOUT_MS.get(state)
    if limit is None:
        return False
    return time.ticks_diff(now, state_entered_ms) >= limit
```

`time.ticks_diff` rather than plain subtraction, because the millisecond
counter wraps around and `ticks_diff` handles the wrap correctly — see
[[Timing, Interrupts, and Real Time]].

## Generating events once per pass

```python
import sensor
import button

previous_warm = False


def collect_events(now):
    """Return the list of events that have occurred since the last pass."""
    global previous_warm
    events = []

    celsius = sensor.read_celsius()
    if not sensor.is_plausible(celsius):
        events.append(EVENT_IMPLAUSIBLE)
    else:
        if celsius > config.WARM_C and not previous_warm:
            events.append(EVENT_WARM)
            previous_warm = True
        elif celsius < config.COOL_C and previous_warm:
            events.append(EVENT_COOL)
            previous_warm = False

    if button.pressed(now):
        events.append(EVENT_BUTTON)

    if button.held_for(now, 2000):        # deliberate, not accidental
        events.append(EVENT_RESET)

    if timed_out(now):
        events.append(EVENT_TIMEOUT)

    return events


def main():
    enter(IDLE, time.ticks_ms())
    next_pass = time.ticks_ms()

    while True:
        now = time.ticks_ms()
        if time.ticks_diff(now, next_pass) >= 0:
            next_pass = time.ticks_add(next_pass, config.LOOP_MS)
            for event in collect_events(now):
                handle(event, now)


try:
    main()
finally:
    fan.off()          # whatever happens, the hardware ends up safe
```

Two details worth arguing about at a review. Events are **edges**, not
levels: `EVENT_WARM` fires once when the temperature crosses upward, not
on every pass while it is hot, and the two thresholds differ so that
noise cannot rattle the machine — hysteresis, straight out of
[[Open and Closed Loop Control]]. And the `finally` block guarantees the
fan stops however the program ends, including an exception three levels
down or a keyboard interrupt at the REPL.

## Walking every cell

The reason to write the table as data is that you can now test the logic
with no hardware attached at all. Import the module on a laptop, replace
the sensor and fan modules with fakes, and drive the machine by hand:

```python
def walk(sequence):
    """Apply a list of events and print the state after each one."""
    now = 0
    enter(IDLE, now)
    for event in sequence:
        now = now + 100
        handle(event, now)
        print(event, "->", state)


walk([EVENT_WARM, EVENT_COOL, EVENT_TIMEOUT, EVENT_BUTTON, EVENT_BUTTON])
```

Run every row of your paper table through that function and you have
evidence, not confidence. Add the sequence a marker will certainly
try — press the button during a purge, trip the fault while running, hold
reset — and record the output in your build log. That is what
[[Testing Without a Debugger]] means by a repeatable test, and it is the
proof [[The Control System]] asks you to bring to the design review.

%%curriculum-start%%
## Curriculum connection

![[A5.2]]

![[B5.2]]

![[B5.3]]
%%curriculum-end%%
