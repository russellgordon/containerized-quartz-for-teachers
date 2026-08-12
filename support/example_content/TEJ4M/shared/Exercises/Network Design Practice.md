---
title: Network Design Practice
draft: false
created: __CREATED__
tags:
  - exercises
---
These follow [[Network Design]] and [[Security by Design]], and they are
the arithmetic behind [[Design and Test a Network]]. Address work is
binary arithmetic wearing dotted decimal: when an answer is not obvious,
write the octet out in bits and it becomes obvious. Every design question
here has more than one defensible answer and several indefensible ones —
the reasoning is what gets marked.

## Address arithmetic

1. A shop must be laid out inside 192.168.20.0/24: 60 workstations, 12
   lab devices, 5 servers, and a two-host router link. Allocate a subnet
   to each, largest first. For every subnet give the prefix, the network
   address, the usable host range, and the number of usable addresses.
   State the first address still free at the end.
2. A workstation reports 172.16.35.200 with mask 255.255.248.0. Give the
   prefix in CIDR notation, the network address, the broadcast address,
   the usable host range, and the number of usable hosts.
3. How many /26 subnets fit inside 10.20.0.0/22, and how many usable
   hosts does each hold? Give the first three network addresses and the
   last one.
4. A machine has 192.168.4.130/25. Give its network address, broadcast
   address, usable range, and host count. Can it reach 192.168.4.100/25
   without a router?

## Capacity, services, and design

5. A nightly backup moves 40 GB across a 1 Gbit/s link. Calculate the
   transfer time at 100% utilisation and at a more realistic 60%. How
   long would the same job take on a 100 Mbit/s link?
6. A /24 network is served by one address-leasing scope. Twenty
   addresses are reserved for servers, printers, and network equipment
   and excluded from the pool. How many leases remain? What will a
   workstation report if the pool is exhausted, and where is the fault?
7. The 12 lab devices in question 1 must reach the servers but must not
   reach the internet. Describe how you would achieve this, and name one
   way a determined student could defeat your first answer.
8. Put these faults at the layer they belong to, and give the order in
   which you would test for them: a crimped cable with one pair
   reversed; a workstation with no default gateway; a service listening
   on the wrong port; two devices assigned the same address; a switch
   port disabled.
9. **Find the error.** A group submits: "We put all 77 devices on one
   192.168.1.0/24 network with DHCP. Everything can reach everything,
   the backup runs at night, and we tested it by opening a web page. The
   network is secure and meets the requirements." List everything wrong,
   and say which requirement each failure violates.

## Answers

> [!success]- Answer 1
> Allocate largest first so the blocks pack without gaps. A prefix with $h$ host bits holds $2^h - 2$ usable addresses.
>
> **Workstations, 60 needed** — six host bits give $2^6 - 2 = 62$, so **/26**. Network 192.168.20.0, usable 192.168.20.1 – 192.168.20.62, broadcast 192.168.20.63.
>
> **Lab devices, 12 needed** — four host bits give $2^4 - 2 = 14$, so **/28**. Network 192.168.20.64, usable 192.168.20.65 – 192.168.20.78, broadcast 192.168.20.79.
>
> **Servers, 5 needed** — three host bits give $2^3 - 2 = 6$, so **/29**. Network 192.168.20.80, usable 192.168.20.81 – 192.168.20.86, broadcast 192.168.20.87.
>
> **Router link, 2 needed** — two host bits give $2^2 - 2 = 2$, so **/30**. Network 192.168.20.88, usable 192.168.20.89 – 192.168.20.90, broadcast 192.168.20.91.
>
> **First free address: 192.168.20.92**, and everything from there to 192.168.20.255 is available for growth.
>
> Two things to defend at a review. The workstation subnet has only two spare addresses out of 62, which is uncomfortably tight for a room that grows — a /25 would give 126 and still leave half the range free. And a five-server group in a /29 with one spare address will need renumbering the day a sixth server arrives.

> [!success]- Answer 2
> 255.255.248.0 in binary is `11111111.11111111.11111000.00000000` — 8 + 8 + 5 = 21 ones, so **/21**.
>
> Eleven host bits remain, and the third octet moves in blocks of $2^{(8-5)} = 8$: 0, 8, 16, 24, 32, 40 …
>
> 35 falls in the block starting at 32 and ending at 39.
>
> **Network address:** 172.16.32.0
>
> **Broadcast address:** 172.16.39.255
>
> **Usable range:** 172.16.32.1 – 172.16.39.254
>
> **Usable hosts:** $2^{11} - 2 = 2048 - 2 = 2046$
>
> Check it the fast way: the block size is 8, and $35 \div 8 = 4$ remainder 3, so the block starts at $4 \times 8 = 32$ and the next one starts at 40, making the broadcast 39.255.

> [!success]- Answer 3
> Going from /22 to /26 borrows $26 - 22 = 4$ bits, so there are $2^4 = 16$ subnets.
>
> Each /26 has six host bits: $2^6 - 2 = 62$ usable hosts.
>
> The block size is 64 in the last octet, and the /22 spans 10.20.0.0 through 10.20.3.255:
>
> **First three:** 10.20.0.0/26, 10.20.0.64/26, 10.20.0.128/26
>
> **Last:** 10.20.3.192/26
>
> Sanity check the total: $16 \times 64 = 1024$ addresses, which is exactly the $2^{10}$ addresses a /22 contains.

> [!success]- Answer 4
> /25 splits the last octet in half: block size 128, so the subnets are .0 – .127 and .128 – .255.
>
> 130 falls in the second block.
>
> **Network address:** 192.168.4.128
>
> **Broadcast address:** 192.168.4.255
>
> **Usable range:** 192.168.4.129 – 192.168.4.254
>
> **Host count:** $2^7 - 2 = 126$
>
> **Can it reach 192.168.4.100/25 directly?** **No.** Applying the same mask, .100 is on network 192.168.4.0, a different network. The two addresses look neighbourly in dotted decimal and are not neighbours at all — which is precisely why you apply the mask instead of trusting the numbers. The traffic must go through a router, and if either machine has no gateway configured it will simply fail, looking exactly like a cable fault from the user's chair.

> [!success]- Answer 5
> Convert to a common unit first: links are rated in bits per second, files are measured in bytes, and one byte is eight bits.
>
> $40\ \text{GB} \times 8 = 320\ \text{Gbit}$
>
> At 1 Gbit/s and 100% utilisation: $t = \frac{320\ \text{Gbit}}{1\ \text{Gbit/s}} = 320\ \text{s} \approx 5.3\ \text{minutes}$.
>
> At 60%: $t = \frac{320}{0.6} \approx 533\ \text{s} \approx 8.9\ \text{minutes}$.
>
> On a 100 Mbit/s link at 100%: $t = \frac{320\,000\ \text{Mbit}}{100\ \text{Mbit/s}} = 3200\ \text{s} \approx 53\ \text{minutes}$ — and at 60%, nearly an hour and a half.
>
> The design consequence: on gigabit the backup is a non-event that can run any time; on fast Ethernet it occupies a large part of the night and will collide with anything else scheduled then. That is a requirement question — "what traffic, and when" — not a cabling preference.

> [!success]- Answer 6
> A /24 holds 256 addresses, of which the network address and the broadcast address are spoken for, leaving 254 usable. Excluding 20 reservations:
>
> $254 - 20 = 234$ leases available.
>
> **If the pool is exhausted**, a workstation that asks for a lease gets no reply and falls back to a self-assigned link-local address in 169.254.x.x. It can then talk only to other machines that have done the same thing, and to nothing else.
>
> **Where the fault is:** upstream, not on that machine. Either the pool is genuinely full, the leasing service is down or unreachable, or the machine has no working link to it. Configuring a static address makes the symptom vanish and leaves the fault in place — and creates a second fault later when the pool hands that address to somebody else.

> [!success]- Answer 7
> **How to achieve it:** the lab devices are already on their own subnet (192.168.20.64/28 from question 1), which is the necessary first step — you cannot filter what is not separated. Then:
>
> - Give the lab subnet **no default route** to the internet, or a route that is filtered at the router.
> - Write firewall rules on the router permitting traffic from 192.168.20.64/28 to the server subnet 192.168.20.80/29 on the specific ports the services need, and denying everything else outbound.
> - Do not include the lab devices in any address translation to the outside.
> - Default to deny, permit by exception, and log the denials so you can see what is being attempted.
>
> **How a determined student defeats it:** by not using your network at all — a phone's hotspot, or a laptop with a second interface bridging the two. They could also set a static address inside the workstation subnet, if nothing stops a device from choosing its own address, which is why port-level controls on the switch matter as much as router rules.
>
> That is not a reason to skip the controls; it is the honest limit from [[Security by Design]]. Write it in the handover document, because a control whose limits are stated can be managed and one that is claimed to be perfect cannot.

> [!success]- Answer 8
> **The layers:**
>
> - Crimped cable with a reversed pair — **layer 1, physical**.
> - Switch port disabled — **layer 1 / 2**, depending on how it was disabled; it presents as no link.
> - Two devices with the same address — **layer 3, network** (though it surfaces as conflicting entries in the neighbour tables at layer 2).
> - Workstation with no default gateway — **layer 3, network**.
> - Service listening on the wrong port — **layer 4 upward**; the transport is fine, nothing is answering where you knocked.
>
> **The order to test:** bottom up, stopping at the first failure, because everything above a broken layer fails too and tells you nothing new.
>
> 1. Link lights and a cable tester — catches the cable and the disabled port.
> 2. Address, mask, and gateway on the workstation — catches the missing gateway and shows a duplicate-address warning if there is one.
> 3. Ping the gateway — proves the local segment.
> 4. Ping something beyond it by address — proves routing.
> 5. Ping by name — proves name resolution.
> 6. Connect to the service on its port — catches the wrong-port fault last, which is where it belongs.

> [!success]- Answer 9
> **What is wrong:**
>
> **Capacity.** A /24 gives 254 usable addresses, so 77 devices fit — but "fits today" is not a design. There is no growth plan and no allowance for the reservations every real network needs.
>
> **No segmentation.** The requirements said the lab devices must not reach the internet, and on one flat network they reach everything. Segmentation is the precondition for any access control at all — this violates the isolation requirement outright.
>
> **"Everything can reach everything" is stated as a success.** It is the finding, not the feature: every device is exposed to every other device's faults, malware, and broadcast traffic.
>
> **"We tested it by opening a web page."** That is the *last* test in the chain, so it exercises everything at once and identifies nothing. It also tests none of the requirements: not the backup window, not the isolation, not the failure behaviour, not the services individually.
>
> **The backup is unmeasured.** "Runs at night" is not a measurement. On a 100 Mbit/s link the arithmetic in answer 5 says nearly an hour; on gigabit, five minutes. Which is it, and does it finish before the building wakes up?
>
> **"The network is secure" is a claim with no threat model.** Secure against whom, doing what? [[Security by Design]] asks for the one page that answers this, and there is no evidence of it here.
>
> **No documentation of failure behaviour.** What happens when the leasing service dies, or the single switch fails, or the internet link drops?
>
> **What a passing submission looks like instead:** the subnet plan from question 1 with growth stated; the isolation implemented and *tested by attempting the forbidden traffic and showing it denied*; each service tested individually with the command and its output recorded; the backup timed with real numbers; a threat model page; and a handover document naming who maintains it and how often.

Take the subnet plan to [[Design and Test a Network]] and build it, then
prove each claim with a command whose output you paste into your
[[Tech Journal]]. A design defended with captured output is an
engineering document; the same design defended from memory is a story.
