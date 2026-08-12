---
title: Bus and Protocol Practice
draft: false
created: __CREATED__
tags:
  - exercises
---
These follow [[Communication Buses]] and prepare the bench work in
[[Talk on a Bus]]. Bus problems are rarely mysterious once you put
numbers on them: how many bits, at what rate, through how much
capacitance, with how many devices sharing the wire. Do the arithmetic
before you reach for the logic analyzer, and the capture will confirm
what you already expected.

## Throughput and timing

1. A link runs at 115200 baud, 8 data bits, no parity, one stop bit.
   Calculate the number of bytes per second it carries, and the time to
   send a 200-byte packet.
2. The same link is reconfigured to 9600 baud. Calculate the time to
   send a 32-byte sensor reading, and say what happens if the two ends
   disagree about the baud rate.
3. An SPI bus runs at 8 MHz. Calculate the theoretical throughput in
   bytes per second and the time for a 32-byte transfer, ignoring
   overhead. Why is the real figure lower?
4. An I²C read of six data bytes from a register takes, in bit-times:
   a start, an address byte with its acknowledgement (9 bits), a
   register byte with its acknowledgement (9), a repeated start, another
   address byte with acknowledgement (9), six data bytes each with an
   acknowledgement, and a stop. Calculate the total bit-times and the
   time taken at 100 kHz and at 400 kHz. If the sensor is read ten times
   a second, what fraction of the time is the bus busy?

## Wiring, addressing, and choosing

5. An I²C bus at 3.3 V has about 100 pF of total capacitance. Taking the
   10% – 90% rise time as $t_r \approx 2.2RC$, calculate the rise time
   with 4.7 kΩ pull-ups. The specification allows 1000 ns in standard
   mode (100 kHz) and 300 ns in fast mode (400 kHz) — does this bus meet
   either?
6. Calculate the largest pull-up resistor that meets the 300 ns fast-mode
   limit with that same 100 pF, choose a standard value, and calculate
   the current each device must sink when it pulls the line low. The
   specification requires devices to sink 3 mA — is your choice legal?
7. Two identical temperature sensors with a fixed I²C address must be
   read by one microcontroller. Explain why this fails, give three
   different fixes, and state how many usable 7-bit addresses the bus
   has in total.
8. Choose a bus for each of these, and justify the choice in one
   sentence: (a) six small sensors scattered around a chassis, none of
   them fast; (b) a display refreshed 30 times a second with a
   kilobyte per frame; (c) a link from your board to a laptop three
   metres away.
9. **Find the error.** A group writes: "The sensor worked on the
   breadboard. We moved it to the chassis on 40 cm leads and set the bus
   to 400 kHz for speed. Now it returns zeros, so the driver code must
   be wrong." Identify the likely fault, and give the order of tests you
   would run.

## Answers

> [!success]- Answer 1
> In 8N1 framing each byte costs 10 bit-times: one start bit, eight data bits, one stop bit.
>
> $\frac{115200\ \text{bit/s}}{10\ \text{bit/byte}} = 11\,520\ \text{bytes/s}$
>
> $t = \frac{200\ \text{bytes} \times 10\ \text{bit/byte}}{115200\ \text{bit/s}} \approx 0.01736\ \text{s} \approx 17.4\ \text{ms}$
>
> The 20% overhead is the price of asynchronous framing: with no clock line, the receiver needs the start and stop bits to find each byte.

> [!success]- Answer 2
> $\frac{9600}{10} = 960\ \text{bytes/s}$, so $t = \frac{32 \times 10}{9600} \approx 0.0333\ \text{s} \approx 33.3\ \text{ms}$ — twelve times as long as the same data at 115200 baud.
>
> **If the ends disagree:** you do not get an error, you get plausible garbage. The receiver samples at the wrong instants and reconstructs bytes that are real bytes, just not the ones that were sent. This is why a baud mismatch is so often mistaken for a broken sensor — and why the first thing to check on a silent or babbling UART is that both ends agree on the rate, the framing, and the ground connection.

> [!success]- Answer 3
> SPI has no start or stop bits, so a byte costs exactly 8 clock cycles.
>
> $\frac{8 \times 10^6\ \text{bit/s}}{8\ \text{bit/byte}} = 1 \times 10^6\ \text{bytes/s} = 1\ \text{MB/s}$
>
> $t = \frac{32\ \text{bytes} \times 8\ \text{bit/byte}}{8 \times 10^6\ \text{bit/s}} = 32 \times 10^{-6}\ \text{s} = 32\ \mu\text{s}$
>
> **Why the real figure is lower:** the chip select has to be asserted and released, most devices need a command or register byte before the data, the software has to prepare the buffer, and gaps appear between transfers while your program does something else. The bus rate is a ceiling, not a delivery.

> [!success]- Answer 4
> Add the bit-times: $1 + 9 + 9 + 1 + 9 + (6 \times 9) + 1 = 84$ bit-times.
>
> At 100 kHz: $\frac{84}{100\,000} = 8.4 \times 10^{-4}\ \text{s} = 840\ \mu\text{s}$.
>
> At 400 kHz: $\frac{84}{400\,000} = 2.1 \times 10^{-4}\ \text{s} = 210\ \mu\text{s}$.
>
> Ten reads per second at 400 kHz occupies $10 \times 210\ \mu\text{s} = 2.1\ \text{ms}$ out of every second, or **0.21%** of the time.
>
> The point of that last figure: the bus is almost entirely idle, so "we need 400 kHz for speed" is very often a claim with no requirement behind it. At 100 kHz the same job takes 0.84% of the time — still nothing — and 100 kHz tolerates longer wires and weaker pull-ups. Choose the slowest rate that meets the requirement.
>
> Note also that this ignores clock stretching and any conversion time the sensor needs, both of which are real and both of which make the true figure longer.

> [!success]- Answer 5
> $t_r \approx 2.2RC = 2.2 \times 4700\ \Omega \times 100 \times 10^{-12}\ \text{F} \approx 1.03 \times 10^{-6}\ \text{s} = 1034\ \text{ns}$
>
> **Standard mode (1000 ns):** marginally over — it fails, by about 3%. In practice a bus like this often works and is sitting right on the limit, which is exactly the kind of design that stops working when somebody adds a device or lengthens a wire.
>
> **Fast mode (300 ns):** fails badly, by more than a factor of three.
>
> This is why 4.7 kΩ is a starting point rather than an answer. The right value depends on your bus capacitance, which depends on your wiring and how many devices are on it.

> [!success]- Answer 6
> Rearranging $t_r \approx 2.2RC$ for $R$:
>
> $R_{\text{max}} = \frac{t_r}{2.2C} = \frac{300 \times 10^{-9}\ \text{s}}{2.2 \times 100 \times 10^{-12}\ \text{F}} \approx 1364\ \Omega$
>
> Choose **1.2 kΩ**, the nearest standard value below that. Check the rise time: $2.2 \times 1200 \times 100\ \text{pF} = 264\ \text{ns}$ — inside 300 ns.
>
> **Sink current** when a device pulls the line to nearly zero:
>
> $I = \frac{3.3\ \text{V}}{1200\ \Omega} = 2.75\ \text{mA}$
>
> The specification requires devices to be able to sink 3 mA, so 2.75 mA is **legal**, with about 8% of margin. A 1 kΩ pull-up would demand 3.3 mA and exceed it.
>
> Both ends of this calculation matter, and they pull in opposite directions: smaller resistors give faster edges and more current; larger ones give less current and slower edges. That is the whole design.

> [!success]- Answer 7
> **Why it fails:** I²C selects a device by address. Two devices answering to the same address both respond to the same read, driving the data line at the same time. The result is not a neat error — it is corrupted data, or one device winning by accident, and it may look intermittent.
>
> **Fix 1 — use the address pin.** Most such parts have one or more address pins; strapping one high and one low gives two different addresses. Free, if the part offers it.
>
> **Fix 2 — use a second I²C bus.** Many microcontrollers have two peripherals. Costs two pins.
>
> **Fix 3 — use an I²C multiplexer**, a chip that switches the master between several sub-buses. Costs a part, board space, and a little complexity in the driver.
>
> A fourth, sometimes the cheapest: choose a different sensor for one of the two positions.
>
> **Usable addresses:** 7 bits gives $2^7 = 128$ combinations, of which 16 are reserved by the specification, leaving **112** usable.

> [!success]- Answer 8
> **(a) Six slow sensors around a chassis — I²C.** Two wires reach all six, each answers to its own address, and none of them needs speed; the wiring saving is the entire argument. Size the pull-ups for the real bus length, as in question 6.
>
> **(b) A display, 30 frames a second at 1 kB per frame — SPI.** That is 30 kB/s of sustained data, which SPI handles trivially and I²C would struggle with; the dedicated chip select is a small price for a single fast device.
>
> **(c) A link to a laptop three metres away — UART.** Point to point, no clock to distribute over that distance, and a standard the laptop already speaks through a serial adapter. Neither SPI nor I²C is meant to travel three metres.

> [!success]- Answer 9
> **The likely fault is wiring, not code** — and the report contains the evidence. Nothing about the driver changed; two physical things did.
>
> Forty centimetres of lead adds capacitance to the bus, which lengthens the rise time on both lines. At the same time the bus rate was raised to 400 kHz, which *shortens* the time available for those edges from 1000 ns to 300 ns. The two changes attack the same margin from both sides, and the arithmetic in questions 5 and 6 says a 4.7 kΩ pull-up was already marginal at 100 pF before the leads were added.
>
> "Returns zeros" is itself a clue: it is what you get when the data line never gets high in time, so every bit reads low.
>
> **The order of tests:**
>
> 1. Put the bus back to 100 kHz. If it works, the fault is timing, and you have proved it in thirty seconds.
> 2. Scan the bus. A device that no longer appears in the scan is not a driver problem at all.
> 3. Put a logic analyzer or a scope on the clock and data lines and *look at the edges*. Slow, rounded rising edges are the signature — [[Using a Logic Analyzer]].
> 4. Fit smaller pull-ups sized for the new capacitance and retest at 400 kHz.
> 5. Shorten the leads, or accept 100 kHz — and ask whether 400 kHz was ever required. From answer 4, ten reads a second occupies a fifth of a percent of the bus either way.
> 6. Only now look at the driver code, and record in your log which of these actually fixed it.
>
> Changing two things at once is what made this expensive. Change one, test, record — the discipline in [[Testing Without a Debugger]].

Bring the pull-up calculation to [[Talk on a Bus]] and capture the rising
edge on a scope with two different resistor values. The difference
between 4.7 kΩ and 1.2 kΩ on a real bus is visible in one screenshot, and
it is worth more in your [[Tech Journal]] than a page of description.
