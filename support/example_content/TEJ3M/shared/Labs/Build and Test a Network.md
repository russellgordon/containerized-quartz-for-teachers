---
title: Build and Test a Network
draft: false
created: __CREATED__
tags:
  - labs
enableToc: true
---
You will make the cable, prove the cable, and only then trust the cable —
and then you will build a small network on top of it and find out
experimentally which machines can reach which, and why.

The prediction in this lab is not about volts. It is about reachability:
given two addresses and a subnet mask, you will state before testing
whether one machine can reach the other, and the network will confirm or
demolish your reasoning. That is the same discipline as Unit 1, applied
to a different kind of number.

> [!danger] Safety notes
> **Safety glasses before the first cut.** Trimmed copper conductors are
> short, stiff, and they leave the cutters fast. **Crimping dies close
> hard** — fingers and thumbs out of the jaws, and cable in fully before
> you squeeze. **Treat any unknown wall port as energised.** A network
> port can carry Power over Ethernet, which puts around $48\ \text{V}$
> on the pairs; that is not a shock hazard through insulation, but it
> will destroy shop-made cables and equipment that is not expecting it.
> **Do not plug anything you built into the school's network** until
> your teacher has checked it and said yes. **Cable off the floor** —
> runs across walkways are trip hazards and the wire always loses.

## What you need

- [ ] Cat 5e or Cat 6 cable off the spool, cut generously
- [ ] 8P8C modular plugs, several — you will ruin some, everyone does
- [ ] Crimping tool, cable stripper, flush cutters, cable tester
- [ ] Two or more computers with network interfaces, and a small switch
- [ ] Safety glasses and your journal

## Predict before you build

1. **Write out the T568B pin order** from pin 1 to pin 8, before you
   look at the poster: white-orange, orange, white-green, blue,
   white-blue, green, white-brown, brown. Then check the poster and mark
   anything you got wrong.
2. **Predict what the tester will show** for a cable where two adjacent
   conductors have been swapped. Which lamps light in order, which do
   not, and what would that fault do to a working link?
3. **Predict reachability before you configure anything.** Given
   `192.168.10.10` with mask `255.255.255.0` on one machine and
   `192.168.10.20` with the same mask on the other: same network, or
   different? Now the same question for `192.168.10.10` and
   `192.168.11.20`. Commit in writing to whether each pair can reach the
   other, and to what the failure will look like if it cannot.

## The work — the cable

4. Strip about $25\ \text{mm}$ of jacket without nicking the
   conductors. A nicked conductor passes the tester today and breaks in
   six months.
5. Untwist the pairs as little as possible — no more than about
   $13\ \text{mm}$ at the end. The twist is not decoration; it is what
   cancels interference, and undoing it is undoing the cable.
6. Arrange in T568B order, trim square so all eight ends are even, and
   push into the plug until every conductor is visible at the front and
   the jacket is inside the strain relief.
7. Crimp fully, in one firm motion. Repeat at the other end, same
   standard on both ends for a straight-through cable.
8. **Test it.** Every pair, in order, both directions. A cable that has
   not been tested is a hypothesis. Record the tester's result before
   you use the cable for anything.

## The work — the network

9. Connect two machines through your switch with your own cables.
10. Assign static addresses matching your first prediction, then verify
    what the machine actually holds with `ipconfig` or `ip addr`. What
    the operating system reports beats what you thought you typed.
11. Test with `ping`, and record whether replies come back and how long
    they take.
12. Look at `arp -a` on each machine. An entry for the other machine
    means the two spoke at the hardware-address level; no entry means
    they never got that far.
13. Now change one machine to the second address from your prediction.
    Test again. Record exactly how the failure presents — the wording of
    the error matters, and it is different from a cable fault.
14. Share a folder from one machine and open it from the other. A
    network you cannot use for anything has not been proven yet.

## Results

| Test | Predicted | Observed |
| --- | --- | --- |
| Cable 1 tester result, pairs 1–8 | all pass | |
| Cable 2 tester result, pairs 1–8 | all pass | |
| Same-subnet ping, replies received | | |
| Same-subnet round-trip time (ms) | | |
| ARP entry present, same subnet | | |
| Different-subnet ping result | | |
| ARP entry present, different subnet | | |
| File share reachable | | |

## Predicted against measured

Where a ping failed, say precisely *why* it failed, in terms of the mask.
With a `255.255.255.0` mask the first three numbers of the address are
the network and the last is the machine, so `192.168.10.x` and
`192.168.11.x` are two different networks and neither machine will even
try the wire — it will hand the packet to a gateway, and on your bench
there is no gateway to hand it to. That is why the ARP table stays empty:
the machine never asked who the other one was.

If a machine shows an address beginning `169.254`, it did not get one
from a server and assigned itself a link-local address. That is not a
cable fault, and chasing it as one costs technicians hours every week.

## The question that matters

Your two cables both passed the tester. Does that prove they are good?
A basic tester checks continuity and pin order — it does not test the
cable at speed, and it cannot see a nicked conductor, an untwisted run,
or a cable pulled over its bend radius. Name three faults your tester
would happily pass, and say how each one would present to a user weeks
later. Then write the sentence you would put on a service ticket to
describe a cable that "tests fine but drops out".

%%curriculum-start%%
## Curriculum connection

![[B4.1]]

![[B4.3]]

![[B4.4]]
%%curriculum-end%%
