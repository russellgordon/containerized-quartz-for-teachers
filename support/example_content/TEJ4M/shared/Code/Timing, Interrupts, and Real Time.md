---
title: Timing, Interrupts, and Real Time
draft: false
created: __CREATED__
tags:
  - code
enableToc: true
---
The control loop in [[Close the Loop]] held its setpoint beautifully
until somebody pressed the button, and the button did nothing for most of
a second. The program was asleep. Every `sleep` in your code is a promise
that nothing else matters for that long, and in a device with a sensor, a
button, and an actuator, that promise is nearly always a lie.

## Never sleep when you could check the clock

Blocking code does one thing at a time. Non-blocking code checks the
clock, does whatever is due, and comes straight back around, so every
part of the device gets a look several hundred times a second.

```python
import time

BLINK_MS = 500
SAMPLE_MS = 100

next_blink = time.ticks_ms()
next_sample = time.ticks_ms()

while True:
    now = time.ticks_ms()

    if time.ticks_diff(now, next_blink) >= 0:
        next_blink = time.ticks_add(next_blink, BLINK_MS)
        led.toggle()

    if time.ticks_diff(now, next_sample) >= 0:
        next_sample = time.ticks_add(next_sample, SAMPLE_MS)
        handle_sample(sensor.read_celsius())
```

Three points of technique in that loop, all of which get marked.

`time.ticks_ms()` returns a counter that **wraps around** at a value that
depends on the port. Subtracting two raw tick values is a bug that
appears once and then hides for weeks; `ticks_diff` and `ticks_add`
handle the wrap correctly, and are the only arithmetic you should ever do
on ticks.

The next deadline is computed from the previous *deadline*, not from
`now`. Add the period to `now` and every pass drifts by however long the
work took, so a "one second" blink slowly becomes 1.05 seconds. Add it to
the deadline and the schedule stays anchored.

And the loop never sleeps for longer than the shortest thing it must
notice. A short `time.sleep_ms(1)` at the bottom is fine and can save
power; a `sleep(0.5)` in the middle is the bug you started with.

## Interrupts: the hardware taps you on the shoulder

Polling is fine for anything you can afford to check every few
milliseconds. Some events cannot wait — a pulse from an encoder, a limit
switch, a signal from another chip — and for those the hardware can
interrupt whatever the processor is doing and run a small function of
yours immediately.

```python
from machine import Pin
import micropython

micropython.alloc_emergency_exception_buf(100)   # do this once, at startup

pulse_count = 0


def on_encoder_edge(pin):
    """Interrupt handler. Keep it tiny; do the thinking in the loop."""
    global pulse_count
    pulse_count = pulse_count + 1


encoder = Pin(14, Pin.IN, Pin.PULL_UP)
encoder.irq(trigger=Pin.IRQ_FALLING, handler=on_encoder_edge)
```

> [!danger] What is genuinely unsafe inside an interrupt handler
> An interrupt handler runs in the middle of your main program, between
> two instructions it cannot see. The restrictions below are not style
> advice — breaking them produces failures that appear once an hour and
> cannot be reproduced on demand.
>
> **Do not allocate memory.** No new lists, dictionaries, strings, or
> floats created inside the handler, and no `print`. If the garbage
> collector is running when the interrupt fires, an allocation raises an
> exception you cannot catch in any useful place. Increment integers that
> already exist; set flags that already exist.
>
> **Keep it short.** Microseconds, not milliseconds. While your handler
> runs, other interrupts may be blocked, including the ones that keep
> time.
>
> **Set a flag; do the work in the loop.** The handler's job is to record
> that something happened. Interpreting it, filtering it, printing it,
> and acting on it all belong in the main loop where exceptions are
> catchable and allocation is safe.
>
> **Call `micropython.alloc_emergency_exception_buf(100)` once at
> startup** so that if a handler does raise, you get a readable traceback
> instead of silence.
>
> If a handler really must do something complicated, hand it off with
> `micropython.schedule(function, argument)`, which asks the runtime to
> run your function as soon as it is safe to do so — soon, but not inside
> the interrupt.

Shared variables need care in the other direction too. A counter the
handler increments can change *while the main loop is reading it*, so
read-and-clear must be indivisible:

```python
import machine


def take_pulse_count():
    """Read and clear the shared counter without racing the handler."""
    global pulse_count
    interrupt_state = machine.disable_irq()
    count = pulse_count
    pulse_count = 0
    machine.enable_irq(interrupt_state)
    return count
```

Interrupts stay off for two lines and no longer. Turn them off for a
millisecond and you will lose the events you built the handler for.

Now use it. With a 20-slot encoder wheel, 240 pulses counted over 2
seconds is 120 pulses per second, so

$$\frac{120\ \text{pulses/s}}{20\ \text{pulses/rev}} = 6\ \text{rev/s} = 360\ \text{rpm}$$

which is the measurement that closes the loop in
[[Feedback and Control Systems]]. Count in the handler; divide in the
loop.

## Let the hardware keep time for you

The best real-time code is the code you do not run. Peripherals keep
their own time, exactly, with no help from your loop.

**PWM** is the clearest case: set a frequency and a duty and the hardware
produces the waveform forever while your program does something else.

```python
from machine import Pin, PWM

fan = PWM(Pin(15))
fan.freq(1000)            # 1 kHz: period of 1 ms
fan.duty_u16(19661)       # about 30 percent of 65535
```

A duty of 30% asked of a 16-bit setting is $0.30 \times 65535 = 19660.5$,
so you round — and on an 8-bit interface, where 30% is
$0.30 \times 255 = 76.5$, rounding to 76 gives an actual
$76/255 \approx 29.8\%$. Small, but it is the difference between a
calculated number and a claimed one, and it is the digital-to-analog
argument from [[Sampling and Resolution]] arriving in your code.

Choose the frequency deliberately. A motor driven at a few hundred hertz
whines audibly; well above the audible range it does not, at the cost of
more switching loss in the driver. Say which you chose and why.

Hardware **timers** can also call a function at a fixed rate without your
loop's cooperation, but the timer API differs between boards more than
almost anything else in MicroPython — check your port's documentation,
and treat a timer callback with exactly the same suspicion as an
interrupt handler, because that is what it is.

## Real time means predictable, not fast

A system is real-time when it meets its deadlines, every time. That is a
statement about the worst case, not the average, so measure the worst
case:

```python
worst_loop_ms = 0

while True:
    started = time.ticks_ms()
    run_one_pass()
    elapsed = time.ticks_diff(time.ticks_ms(), started)
    if elapsed > worst_loop_ms:
        worst_loop_ms = elapsed
        print("new worst pass:", worst_loop_ms, "ms")
```

A loop that must run every 100 ms and whose worst pass takes 90 ms has
almost no margin left, and the first thing that grows — a slower sensor,
a log write, the garbage collector — pushes it over. Find the long pass
and shorten it: reading eight samples when four would do, writing to the
filesystem inside the loop, and string formatting for a `print` are the
usual three.

Put the worst-case number in your report next to the loop period. "The
loop is scheduled every 100 ms and the worst observed pass was 12 ms" is
an engineering claim with evidence behind it, and it is exactly the kind
of statement [[Testing Without a Debugger]] teaches you to produce and
[[The Control System]] expects you to defend.

%%curriculum-start%%
## Curriculum connection

![[A5.6]]

![[B5.2]]

![[B5.4]]
%%curriculum-end%%
