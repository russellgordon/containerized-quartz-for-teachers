---
title: Network Design
publish: true
created: __CREATED__
tags:
  - concepts
enableToc: true
---
Grade 11 asked you to make two machines see each other. In
[[Design and Test a Network]] the brief is different: here is a shop with
sixty workstations, a dozen lab devices that must not reach the internet,
five servers, a printer everybody needs, and a link to the rest of the
school. Design the network. There is no single right answer, which is
exactly why the design has to be written down and defended.

## Requirements come before topology

A network diagram drawn before the requirements are known is decoration.
Start where [[Writing a Specification]] starts.

- [ ] **Who and what** connects — count the hosts, and count them again
      for three years from now.
- [ ] **What must reach what** — and, more revealing, what must *not*.
- [ ] **What traffic** — a nightly 40 GB backup is a different network
      from four hundred web pages an hour.
- [ ] **What must keep working** when one link, one switch, or the
      internet connection fails.
- [ ] **Who administers it**, and how they get told something broke.
- [ ] **What it must cost**, including the cable runs nobody budgets for.

Only then do you draw boxes. Wired for anything fixed and heavy; wireless
for anything that moves, understanding that a shared radio channel is
shared capacity, not extra capacity. Separate the lab devices from the
office machines because the requirements say so, not because separation
sounds professional.

## Addressing is arithmetic, and it has to balance

Subnetting is binary arithmetic in a dotted-decimal disguise. Borrowing
bits from the host part creates subnets and shrinks each one: a prefix
with $h$ host bits holds $2^h - 2$ usable addresses, because the all-zeros
address names the network and the all-ones address is the broadcast.

Take 192.168.20.0/24 and lay the shop out inside it:

| Group | Need | Prefix | Network | Usable range | Usable |
| --- | --- | --- | --- | --- | --- |
| Workstations | 60 | /26 | 192.168.20.0 | .1 – .62 | 62 |
| Lab devices | 12 | /28 | 192.168.20.64 | .65 – .78 | 14 |
| Servers | 5 | /29 | 192.168.20.80 | .81 – .86 | 6 |
| Router link | 2 | /30 | 192.168.20.88 | .89 – .90 | 2 |

Allocate the largest block first, always, and let each subsequent block
start where the last one ended — 192.168.20.92 is still free here, and
that is your room to grow. Give each subnet the smallest prefix that
holds its hosts with headroom, because the growth you refuse to plan for
is the renumbering you will do at midnight.

The addresses above are private, from the ranges reserved for internal
use, which is why they can be reused in every building in the country.
Traffic to the outside gets translated at the boundary — one public
address serving many internal hosts, with the router keeping track of
which conversation belongs to whom. Static assignment for anything that
must be found (servers, printers, switches, the router); leases from a
[[A4.4|dynamic addressing service]] for everything else, with the static
addresses excluded from the lease pool so the two schemes cannot collide.

## Layers are a troubleshooting tool, not a quiz

The seven-layer reference model is worth memorising for one practical
reason: it tells you where to look, and in what order. Each layer trusts
the one beneath it, so a fault at a low layer produces symptoms at every
layer above.

| Layer | What lives there | Where you meet it in this shop |
| --- | --- | --- |
| 7 Application | The service itself | A web page, a file transfer, mail |
| 6 Presentation | Encoding, encryption | Certificates, character sets |
| 5 Session | Conversations between hosts | Logins, remote desktop sessions |
| 4 Transport | End-to-end delivery, ports | TCP retransmits, a blocked port |
| 3 Network | Addresses and routing | IP addresses, masks, the router |
| 2 Data link | Frames on one segment | MAC addresses, the switch, VLANs |
| 1 Physical | Copper, fibre, radio | The cable you crimped, link lights |

Work from the bottom when something is broken. Link light, then address
and mask, then gateway, then a ping by address, then a ping by name, then
the application. Stop at the first failure, because everything above it
will also fail and tell you nothing new — the same halving discipline as
[[Testing Without a Debugger]], with better instruments.

Routing sits at layer 3 and gets two easily confused names. A **routed
protocol** is the one your data travels in, carrying source and
destination addresses. A **routing protocol** is how routers tell each
other which networks they can reach, so that the tables build themselves
instead of being typed in by hand. A small shop network may need no
routing protocol at all — a static default route out and one route back
is honest engineering when the topology is a straight line.

## Services, and the machines that provide them

A network that carries no services is a lit-up cable tray. The build in
[[Design and Test a Network]] is expected to stand up real ones — address
leasing, name resolution, file sharing, a web or print service, remote
administration — and to document, for each, which machine provides it,
which hosts may use it, and how you proved it works. Virtualization means
one physical server can host several of them, which is efficient right up
to the moment that machine fails and takes six services with it. Say what
happens then.

Then prove the design against the requirements you wrote at the top, in
writing: this subnet holds these hosts with this much growth, this
service is reachable from here and not from there, this failure produces
this behaviour. [[Network Design Practice]] drills the address arithmetic
and the throughput sums until they are quick, and
[[Security by Design]] takes the same network and asks the questions this
page deliberately left out.

%%curriculum-start%%
## Curriculum connection

![[A4.1]]

![[A4.2]]

![[A4.3]]

![[B4.1]]
%%curriculum-end%%
