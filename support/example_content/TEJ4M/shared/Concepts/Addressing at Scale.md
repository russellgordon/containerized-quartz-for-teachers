---
title: Addressing at Scale
publish: true
created: __CREATED__
tags:
  - concepts
enableToc: true
---
[[Network Design]] got machines talking on one segment. This page is
about what happens when there are more machines than addresses, which is
the situation the whole internet has been in for thirty years.

## Classful addressing, and why you still meet it

The original scheme divided IPv4 addresses into classes by their leading
bits:

| Class | First octet | Default mask | Networks / hosts each |
| --- | --- | --- | --- |
| A | 1–126 | 255.0.0.0 | Few networks, ~16.7 million hosts |
| B | 128–191 | 255.255.0.0 | ~16,000 networks, ~65,000 hosts |
| C | 192–223 | 255.255.255.0 | ~2 million networks, 254 hosts |

Classful allocation was abandoned in the 1990s for **CIDR**, where the
mask is stated explicitly (192.168.1.0/24) and can fall anywhere. But
the classes survive in defaults, in documentation, and in the vocabulary
of every network engineer you will work with — which is why it is worth
knowing that "a Class C" means a /24 to most people in the room.

## Public and private

Three ranges are reserved for private use and are never routed on the
public internet:

- 10.0.0.0/8
- 172.16.0.0/12
- 192.168.0.0/16

Every home and school network in the country uses one of them, which is
why your bench address and a bench address in another province can be
identical and never collide.

## NAT and PAT: many machines, one address

**Network address translation** rewrites the private source address of
outgoing packets to the router's public address, and reverses it on the
way back. **Port address translation** — what almost every home router
actually does — distinguishes the conversations by port number as well,
so hundreds of machines share one public address.

| | What it gives you | What it costs |
| --- | --- | --- |
| NAT / PAT | Many machines behind one public address; incidental protection, since unsolicited inbound traffic has nowhere to go | Inbound services need explicit port forwarding; some protocols need help; troubleshooting is harder because addresses are not what they seem |

The incidental protection is worth naming precisely: NAT is **not** a
firewall, and treating it as one is a recurring mistake — see
[[Security by Design]].

## Static and dynamic assignment

**DHCP** hands out addresses, masks, gateways, and DNS servers on a
lease. It is right for laptops, phones, and anything that comes and
goes.

**Static addressing** — set on the device, or reserved by MAC address in
DHCP — is right for anything other machines need to find: servers,
printers, switches, access points, and the controller in
[[The Control System]]. The reservation approach is usually better than
a hand-set address, because the addressing stays documented in one place
rather than in somebody's memory.

> [!question] The design question worth arguing
> Your deployment has 40 workstations, 3 servers, 12 printers, 6 access
> points, and a guest wireless network that may see 200 devices a day.
> Which of those get DHCP, which get reservations, which get static
> addresses, and where do you draw the subnet boundaries? Defend it in
> [[Network Design Practice]], then build it in [[The Deployment]].

%%curriculum-start%%
## Curriculum connection

![[A4.4]]

![[A4.2]]
%%curriculum-end%%
