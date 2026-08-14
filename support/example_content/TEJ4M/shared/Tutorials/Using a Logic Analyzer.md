---
title: Using a Logic Analyzer
draft: false
created: __CREATED__
tags:
  - tutorials
enableToc: true
---
An oscilloscope is deep and narrow: one or two channels, every detail
of the shape. A logic analyzer is the opposite — eight, sixteen, or
more channels, one bit deep. It does not know what a voltage looks
like. For each channel at each moment it records a single fact: was
this line above or below the threshold?

That sounds like a downgrade until the first time you watch a chip
select, a clock, and a data line at once and see, immediately, that
the data changes while the clock is still high. No scope with two
channels was going to tell you that.

## Which instrument answers which question

| The question you have | The instrument that answers it |
| --- | --- |
| Is this level legal for the logic downstream? | Oscilloscope |
| How fast is this edge, and is it ringing? | Oscilloscope |
| How much ripple is on the rail? | Oscilloscope |
| Which line changed first, and by how long? | Logic analyzer |
| What byte did the master actually send? | Logic analyzer |
| Does the fault happen once every ten thousand transactions? | Logic analyzer |
| The decode is garbage and the wiring looks right | Oscilloscope, immediately |

Reaching for the wrong one of those is the most common way to lose an
afternoon in this course.

## The three settings that decide everything

**Threshold.** The analyzer compares every channel against one voltage
you choose. Set it for the logic family you are actually probing —
3.3 V parts, 5 V parts, and 1.8 V parts all need different thresholds,
and a threshold left over from the last person's session produces a
capture that is entirely one level, or decoded nonsense that looks
real. Check this first, every single time.

**Sample rate.** The analyzer samples on its own clock, so an edge is
located only to within one sample interval. The working rule is to
sample at least four times faster than the fastest signal you care
about, and ten times faster if you want to trust the timing between
edges. Sampling a 1 MHz clock at 2 MHz will show you *a* clock; it
will not show you where its edges are.

**Ground.** The analyzer needs a ground connection to the target
before any of its readings mean anything, and one ground lead is often
not enough when many channels are switching. Connect every ground the
pod provides.

## Timing mode and state mode

Two fundamentally different ways of capturing, and knowing which you
are in explains most confusing captures.

- **Timing mode** samples on the analyzer's own internal clock. It
  answers questions about *time*: how long between these two edges,
  how wide is this pulse. Resolution is set by your sample rate.
- **State mode** samples on a clock supplied by the circuit — the
  bus clock, typically — so each sample is one bus cycle. Time
  disappears and sequence takes over: you see exactly what the bus
  saw, in order, with no jitter and no oversampling. It answers
  questions about *data*.

Most protocol work you do here will be timing mode at a generous
sample rate, which gets you both approximately. Reach for state mode
when the question is "what sequence of values appeared" rather than
"when".

## Triggering, and the pre-trigger buffer

The trigger is not there to start the capture. It is there to decide
which part of a very long stream you keep.

Analyzers trigger on an edge, on a **pattern** across several channels
at once, on a pulse of a given width, or — the useful one — on a
**protocol event**: this specific I²C address, this byte value, this
chip select going active.

The feature that changes how you work is the **pre-trigger buffer**.
The analyzer is always recording; when the trigger fires it keeps what
came before as well as what came after. So you can trigger on the
failure and then look backwards at what led to it. That is a
diagnostic superpower a scope in single-shot mode also has, and almost
nobody uses either.

## Protocol decode

The analyzer will turn edges back into bytes, but only if you tell it
exactly what it is looking at. Get any of these wrong and the decode
is confident garbage.

| Protocol | What you must tell it |
| --- | --- |
| UART | Baud rate, data bits, parity, stop bits, idle level, bit order |
| I²C | Which channel is SDA and which is SCL, and whether addresses are shown as 7-bit or as the 8-bit byte on the wire |
| SPI | Clock polarity and phase, chip-select polarity, word size, and whether the most significant bit goes first |

Have the firmware's own intent in front of you while you read the
decode. Here is a small MicroPython program worth running before you
debug anything on an I²C bus, because it answers "is the device
there at all" without any analyzer involved:

```python
from machine import I2C, Pin
import time

# These pin numbers are an example only — check your own board's
# pinout diagram, because the numbering differs between boards.
i2c = I2C(0, scl=Pin(9), sda=Pin(8), freq=100_000)

found = i2c.scan()
print("Devices responding:", len(found))
for address in found:
    print("  7-bit address:", hex(address))

time.sleep(1)
```

If that prints nothing, the analyzer will confirm why in about ten
seconds — and the answer is usually one of the four below.

## The classic finds

- **No clock at all.** On I²C, both lines idle high because of pull-up
  resistors. Forget the pull-ups and both lines sit low or float, and
  nothing ever starts. This is the single most common I²C fault and
  the analyzer shows it instantly.
- **The address is off by one bit.** An I²C device's 7-bit address is
  shifted left by one on the wire, with the read/write bit in the
  bottom position. A datasheet quoting the 8-bit form and firmware
  expecting the 7-bit form disagree by a factor of two, and the
  symptom is a device that never acknowledges. The scan program above
  prints the 7-bit form.
- **The SPI mode is wrong.** Clock polarity and phase decide which
  clock edge the data is sampled on. Get it wrong and you receive
  shifted or garbage data from a device that is working perfectly.
- **Chip select never goes active.** The peripheral was never being
  addressed at all; everything else on the capture was irrelevant.
  Always capture the select line, even when you are sure.

The details of all four live in [[Communication Buses]], and
[[Talk on a Bus]] is where you meet them with hardware.

## When to put the scope back on it

If the decode is nonsense and the protocol settings are right and the
wiring is right, stop. You now have an *analog* problem, and an
analyzer cannot see analog problems by construction. A line that only
reaches 2.1 V on a 3.3 V bus, an edge slowed to a crawl by too much
pull-up resistance and too much capacitance, or ringing that crosses
the threshold twice on one edge will all produce a clean-looking
capture full of wrong bits.

Put a scope probe on the clock line, look at the actual shape, and the
answer usually arrives within a minute. That handoff — analyzer for
sequence, scope for shape — is the whole working relationship between
the two instruments, and it is the same one-variable-at-a-time
discipline as [[Getting Unstuck]].

> [!tip] Capture the working case first
> Before you debug a broken transaction, capture a working one and
> save it. A known-good reference makes the difference obvious instead
> of requiring you to remember what correct looks like — and it goes
> straight into your [[Tech Journal]] as evidence with the sample
> rate, threshold, and protocol settings written beside it.

%%curriculum-start%%
## Curriculum connection

![[A5.1]]

![[B2.3]]
%%curriculum-end%%
