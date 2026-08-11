---
title: Networks and Connectivity
draft: false
created: __CREATED__
tags:
  - concepts
enableToc: false
---
When the class became a network in [[Build a Network]], you were the
hardware: sticky notes as packets, students as routers, and one
long-suffering message trying to cross the room. The real internet is
that game at planetary scale, played billions of times a second.

## Messages travel as packets

A message is not sent whole. It is chopped into packets — small,
numbered pieces, each stamped with its destination address — that
travel separately and may not even take the same route. The receiving
device reassembles them in order, asks again for any that went
missing, and hands the finished message upward. You never see the
seams.

## The journey

Your phone speaks wifi to the router in the wall, or cellular to a
tower down the street. Either way the packets reach your internet
provider, then hop between routers — each one reading the address and
passing the packet along, exactly like the students in the middle of
the room — until they arrive at a server: a computer whose whole job
is to answer requests. The reply makes the same trip in reverse, and
a round trip across an ocean takes well under a second.

> [!question]- Self-check: trace a text to a friend across town
> Before expanding this, list every stop you can name. Roughly: your
> phone → wifi router or cell tower → your provider's network →
> several routers → the messaging company's server → your friend's
> provider → their phone. Two phones ten metres apart often still
> route through a server in another country.

## Always on: the trade

Constant connectivity is genuinely wonderful — video calls with a
grandparent, maps that reroute around traffic,
[[Finding Answers Online]] the moment you are stuck. The costs are
real too: every connected hour generates data about you, attention
drifts wherever notifications pull it, and communities without
coverage or affordable service are locked out of things the connected
take for granted. The point is not to disconnect — it is to know what
the connection costs and to decide on purpose.

%%curriculum-start%%
## Curriculum connection

![[B4.2]]
%%curriculum-end%%
