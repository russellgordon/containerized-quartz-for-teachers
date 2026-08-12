---
title: Communication Buses
draft: false
created: __CREATED__
tags:
  - concepts
enableToc: true
---
The sensor in [[Talk on a Bus]] answered on one bench and stayed silent
on the next, with identical code on both. The silent bench had wired the
two signal lines and forgotten that this particular bus does not drive
them high — it needs resistors to do that. A bus is not just wires; it is
an agreement, and every party to it has to keep the same one.

## Buses inside the machine, and buses to the outside

Open a computer and the word *bus* already has a meaning: the parallel
paths inside the machine that move addresses, data, and control signals
between the processor, memory, and chipset. An **address bus** carries
where, a **data bus** carries what, and the control lines carry when and
which direction. Their width and clock rate are a large part of what
makes one machine faster than another, and the memory bus is usually the
bottleneck nobody looks at.

The buses on this page are the other kind: the serial links that carry
data between a controller and the peripherals around it, in the same
family of ideas as the port standards on the back of a computer — USB,
RS-232, and their relatives — where a published standard says exactly
what the voltages, timing, and framing must be so that equipment from
different makers can work together. That is what a standard is *for*.

## The three you will meet at the bench

**UART — asynchronous serial.** Two wires, one each way, and no clock
line at all. Both ends must be configured for the same bit rate, and each
byte is wrapped in a start bit and a stop bit so the receiver can find
it. At the common 115200 baud with 8 data bits, no parity, and one stop
bit, each byte costs 10 bit-times:

$$\frac{115200\ \text{bit/s}}{10\ \text{bit/byte}} = 11\,520\ \text{bytes/s}$$

Point to point, simple, and unforgiving about baud rate: get it wrong and
you receive plausible-looking garbage rather than an error.

**SPI — synchronous, fast, one master.** Four wires: clock, master-out,
master-in, and a **chip select** per device. The master supplies the
clock, so there is no baud rate to agree — the clock *is* the agreement —
and data moves in both directions at once. It is the fastest of the
three by a wide margin: at an 8 MHz clock, 8 bits per byte and no framing
overhead gives a megabyte per second, so a 32-byte transfer takes about
32 µs. The cost is pins. Each additional device needs its own chip select
line, so three devices need six wires where two would have done.

**I²C — two wires, addressed, shared.** Clock and data, both **open
drain**: every device can pull a line low, nobody drives it high, and
**pull-up resistors** return the line high when everyone lets go. That is
the wiring the silent bench forgot. Because the bus is shared, each
device answers to an address — seven bits, giving 128 combinations of
which 16 are reserved, leaving 112 usable — and every byte is
acknowledged by the receiver pulling data low for a ninth bit. A device
that needs time can even hold the clock line low to stall the master,
which is called clock stretching.

The pull-ups are a design decision, not a formality. They must be strong
enough to pull the line high through the bus capacitance within the time
the specification allows, and weak enough that the devices can still pull
it down within their rated sink current. Bigger resistors mean slower
edges; smaller resistors mean more current. [[Bus and Protocol Practice]]
works that sizing out with numbers.

## Choosing a bus, and paying for the choice

| | UART | SPI | I²C |
| --- | --- | --- | --- |
| Wires | 2 (plus ground) | 3 shared + 1 select each | 2 (plus ground) |
| Clock | None — agreed baud rate | Supplied by the master | Supplied by the master |
| Addressing | None; point to point | By chip select line | 7-bit address in the frame |
| Speed | Modest | Highest of the three | Modest, defined bus modes |
| Multiple devices | One per port | Yes, one select line each | Yes, on the same two wires |
| Classic failure | Mismatched baud rate | Forgotten or shared chip select | Missing pull-ups, address collision |

Choose by what the design actually needs. Many sensors that must share
two wires, none of them fast? I²C. One display or memory that has to move
data quickly? SPI. A link to another board or a computer, with cheap
wiring and no clock to distribute? UART. Then write the choice and its
reason into your specification, because the pin budget it implies is one
of the constraints everything else has to live with.

Two things bite when you leave the breadboard. Long wires add
capacitance, which slows the edges on any bus and shows up first on I²C —
the bus that depends on a resistor to charge that capacitance. And every
one of these standards specifies logic levels: a 5 V device and a 3.3 V
device on the same bus need level translation, not optimism. When you
build the cable yourself, build it deliberately and test it before you
trust it — [[B1.3|constructing and testing connection media]] is a
Grade 12 expectation precisely because a bad cable produces symptoms that
look exactly like bad code.

When it does not work, stop guessing and look. A logic analyzer shows you
the actual edges, the actual address, and the actual acknowledgement —
[[Using a Logic Analyzer]] is the tutorial, and
[[Talking to a Peripheral#Reading a register]] is the firmware side of
the same conversation. [[Which One Doesn't Belong]] is a good five-minute
drill on telling the three apart from a wiring diagram alone.

%%curriculum-start%%
## Curriculum connection

![[A1.1]]

![[A2.4]]

![[B1.3]]
%%curriculum-end%%
