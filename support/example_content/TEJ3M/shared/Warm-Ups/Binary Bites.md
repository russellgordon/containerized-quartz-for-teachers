---
title: Binary Bites
draft: false
created: __CREATED__
tags:
  - warm-ups
---
Three small conversions go up instead of last year's two, because a
third base has joined the room: hexadecimal. One decimal to binary,
one binary to hex, one hex to decimal. Everyone works all three, then
two volunteers defend their *method* out loud — not the answer, the
route. Fluency is the goal and speed never is. By the end of the
semester a byte should read like a word, and `0x3F` should stop
looking like a typo.

## How to run it

1. Post all three. Quiet work — paper, whiteboard, fingers if that is
   what it takes.
2. When most pens stop, collect answers without judging them yet.
3. Two defences aloud. The defender narrates every step; the class's
   job is to catch the step that got skipped.
4. If two methods agree by different routes, board them both. There
   is more than one honest way through, and seeing that is the point.

## Why hex earns its place

Hex is not a third thing to memorise — it is binary, written shorter.
Four bits is exactly one hex digit, always, with no carrying between
them. That is the whole trick, and it is why every register, colour
code, memory address, and error code you meet this semester is
written in hex rather than in sixteen ones and zeros.

| Binary nibble | Hex | Decimal |
| --- | --- | --- |
| `0000` | `0` | 0 |
| `1001` | `9` | 9 |
| `1010` | `A` | 10 |
| `1101` | `D` | 13 |
| `1111` | `F` | 15 |

Split any byte down the middle, convert each half on its own, and
write the two digits side by side. No arithmetic crosses the seam.

> [!example]- A worked round
> **Decimal to binary: 214.** Biggest power that fits is 128,
> leaving 86; then 64, leaving 22; then 16, leaving 6; then 4,
> leaving 2; then 2, leaving 0. Bits at 128, 64, 16, 4, and 2 give
> `11010110`. **Binary to hex:** split it — `1101` and `0110` — and
> convert each nibble on its own: `D` and `6`, so `0xD6`. **Hex to
> decimal: 0x2F.** That is $2 \times 16 + 15 = 47$. Check every
> answer by converting it back the way it came; a conversion you
> cannot reverse is a conversion you do not own yet.

## One variation

Hand over the marker. A student sets tomorrow's three numbers and
must bring worked answers for all of them. Choosing numbers that are
interesting but fair — one that crosses a nibble boundary awkwardly,
one that is a round hex value in disguise — teaches more than solving
ten of somebody else's.

> [!tip] Say the base out loud
> "Forty-seven" and "four seven" are different claims, and `0x10`,
> `10`, and `0b10` are three different numbers wearing the same
> costume. Prefix hex with `0x` and binary with `0b` in everything
> you write this semester, the way [[Binary and Hexadecimal]] does —
> it costs two characters and it prevents an entire genus of bug.
