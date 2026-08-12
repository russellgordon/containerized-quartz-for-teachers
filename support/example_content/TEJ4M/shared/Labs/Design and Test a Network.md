---
title: Design and Test a Network
draft: false
created: __CREATED__
tags:
  - labs
enableToc: true
---
Anybody can plug machines into a switch until they can ping each other.
A design is different: it starts with a written requirement, it commits
to an address plan before a single cable is made, and it ends with tests
somebody else could run to check that the requirement was met.

Today you do it in that order. The requirement comes first, and if your
network passes every test you wrote but nobody can say what it was for,
it is not finished.

> [!danger] Safety notes
> **Our lab network stays isolated.** Nothing you build today touches
> the school's network, and no cable of yours goes into a wall port
> without your teacher physically present. That is not a classroom
> preference — running scanning or capture tools against equipment you
> do not have written permission to test is an offence, and the isolated
> bench is what makes today's work lawful as well as safe. **Scanning
> and capture tools run on our own subnet only.** **Crimpers, snips,
> and stripped conductors cut**: glasses on, cut ends into the bin, and
> never pull a cable towards yourself while trimming. **Some switch
> ports supply power over the cable** — a homemade cable with a short
> in the wrong pair can damage the port that energises it, so test
> every cable in the tester before it goes into equipment. **Static
> discipline** applies to any card or board you handle: strap on, board
> by the edges.

## What you need

- [ ] A small managed or unmanaged switch, and two or more machines or
      single-board computers
- [ ] Cable, plugs, a crimper, and a cable tester
- [ ] A machine that can act as a server for one service
- [ ] Whatever your bench uses for address configuration and
      diagnostics — a terminal, a browser, and the standard reachability
      and path tools
- [ ] Your written requirement, brought from last class

## Predict before you build

1. **Write the requirement as a testable list.** Not "a network for the
   robotics club" but: how many devices now, how many in two years,
   which of them need a fixed address, which service must be reachable
   from where, and how quickly the network must recover from a
   restarted switch.
2. **Plan the addresses on paper.** Take a private range and divide it
   deliberately. A $/26$ mask leaves six host bits, so each subnet
   holds $2^6 = 64$ addresses, of which $64 - 2 = 62$ are usable — one
   address identifies the subnet itself and one is the broadcast
   address. Splitting $192.168.10.0/24$ into $/26$ subnets gives four
   blocks: $.0$ to $.63$, $.64$ to $.127$, $.128$ to $.191$, and
   $.192$ to $.255$. Write down which block does what, which addresses
   are reserved for fixed devices, and which are left for automatic
   assignment.
3. **Predict growth.** State how many free addresses your plan leaves
   in each block, and say what happens on the day somebody plugs in
   more devices than that.
4. **Predict the measurements.** Before you touch anything, write down
   what you expect for: link speed on a cable you made, round-trip time
   between two machines on the same switch, round-trip time to a
   machine on another subnet, and throughput of a large file transfer
   as a fraction of the link speed.
5. **Predict the failures you will inject.** For each of these, say
   what symptom you expect *before* you cause it: one cable with a
   swapped pair; a machine with the wrong subnet mask; two machines
   given the same address.

## The work

6. **Make and test the cables.** Follow one wiring standard for both
   ends and stay with it — a building is wired to one standard and your
   patch cables must match it. Every finished cable goes into the
   tester before it goes into equipment, and a cable that fails gets
   re-terminated, not "tried anyway".
7. **Build to the plan.** Configure addresses exactly as written on
   paper, including the deliberate gaps. If you change the plan, change
   the paper first — that habit is the difference between a network you
   documented and a network you remembered.
8. **Verify reachability** in a fixed order: a machine to itself, to
   its own gateway, to another machine in the same subnet, to a machine
   in another subnet, and finally to the service. Record where the
   first failure is, because that location names the layer to
   investigate.
9. **Measure, do not assume.** Link speed as negotiated, round-trip
   times as an average over many attempts, and throughput on a transfer
   large enough to last several seconds.
10. **Stand up the service** your requirement named, and test it from a
    machine that has no business knowing anything about how it was
    configured.
11. **Inject the three failures from step 5, one at a time**, and
    record the symptom each produces and how long it took you to find
    it using the tools rather than your memory of what you broke.
12. **Restart the switch** and time how long the network takes to be
    fully usable again. Compare that against the recovery requirement
    you wrote.
13. **Hand it over.** Give your written plan and test list to another
    bench and have them run every test without asking you a question.
    Their failures are your findings.

## Results

| Measurement | Predicted | Measured |
| --- | --- | --- |
| Usable addresses per subnet | 62 | |
| Free addresses left after build | | |
| Cable tester result, each cable made | pass | |
| Negotiated link speed (Mbit/s) | | |
| Round-trip, same subnet (ms) | | |
| Round-trip, across subnets (ms) | | |
| Throughput, large transfer (Mbit/s) | | |
| Throughput as a fraction of link speed | | |
| Service reachable from the far subnet | yes | |
| Symptom of a swapped pair | | |
| Symptom of a wrong subnet mask | | |
| Symptom of a duplicate address | | |
| Time to full recovery after switch restart (s) | | |

## Predicted against measured

Your measured throughput will come in below the negotiated link speed,
and that is not a fault. Every frame carries headers, the transport
protocol acknowledges what it receives, and the machines at each end
have to actually read and write the data — so some of the link's
capacity is spent on making the transfer reliable rather than on the
file. Compute the percentage you lost and see whether it is stable
across repeat runs; a figure that wanders points at one of the machines,
not at the network.

Cross-subnet round trips should be measurably longer than same-subnet
ones, because a router has to look at each packet and decide. If yours
are not, check that traffic is really crossing the router and not
finding a shortcut you did not plan.

For each injected failure, compare the symptom you predicted with the
symptom you got. The duplicate address is the one that surprises people:
it often does not fail cleanly at all, and instead produces intermittent
behaviour that looks like a bad cable. Write down how you would tell
those two apart next time, from evidence.

## The question that matters

Your address plan left deliberate gaps and reserved ranges that nothing
uses today. Justify them to somebody who wants those addresses now.
Then answer the harder half: what would you have to change if the
requirement doubled the number of devices, and how much of your work
would survive?

Then the design-margin questions:

- Somebody plugs both ends of one cable into the same switch. Predict
  what happens, then say what feature of a managed switch prevents it
  and why an unmanaged one cannot.
- The switch lives in a closed cabinet that reaches
  $40\ ^\circ\text{C}$. Find the equipment's stated operating range and
  say what margin you have left.
- A year from now somebody has to add a device to this network and you
  are not here. Which single document would they need, and does it
  exist yet? That is the standard set by
  [[Writing Documentation Somebody Can Build From]].

%%curriculum-start%%
## Curriculum connection

![[A4.3]]

![[B4.1]]

![[B4.5]]
%%curriculum-end%%
