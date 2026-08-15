---
title: Networking Practice
publish: true
created: __CREATED__
tags:
  - exercises
---
These follow [[Networks and Protocols]] and the two machines that
refused to see each other in [[Build and Test a Network]]. Address
arithmetic is binary arithmetic wearing dotted decimal, so write the
octets out in bits whenever an answer is not obvious — the conversions
are drilled in [[Number Systems Practice]].

## Addressing

1. A workstation has address 192.168.1.10 and mask 255.255.255.0.
   Give the network address, the broadcast address, the range of usable
   host addresses, and how many hosts the network can hold.
2. Write these masks in CIDR shorthand: 255.255.255.0, 255.255.0.0, and
   255.255.255.240.
3. Can 192.168.1.10 and 192.168.2.15, both with a /24 mask, communicate
   directly? Show the reasoning, and say what has to happen if they are
   to exchange traffic at all.
4. A workstation has address 10.0.0.37 with mask 255.255.255.240. Give
   its network address, broadcast address, usable host range, and host
   count.
5. A machine reports an address of 169.254.13.7 that nobody assigned it.
   What has happened, and where is the fault?

## Performance, hardware, and diagnosis

6. A 50 MB file is copied across a link that is measuring 40 Mbit/s of
   throughput. How long should the transfer take? If it takes 40
   seconds, what throughput are you actually getting?
7. Explain the difference between a MAC address and an IP address, and
   why a network needs both.
8. A workstation can ping its own gateway and can ping 8.8.8.8, but
   cannot open any website by name. Name the single most likely fault
   and the one command you would run next.
9. **Find the error.** Asked to prove a newly built network works, a
   classmate opens a browser, finds it fails to load a page, and
   concludes the cable they crimped is bad. List everything wrong with
   that reasoning and give the order they should have worked in.

## Answers

> [!success]- Answer 1
> Mask 255.255.255.0 covers the first three octets, so the network part
> is 192.168.1 and the last octet identifies the host.
>
> **Network address:** 192.168.1.0 — all host bits zero.
>
> **Broadcast address:** 192.168.1.255 — all host bits one.
>
> **Usable hosts:** 192.168.1.1 through 192.168.1.254.
>
> **Count:** eight host bits give $2^8 = 256$ addresses, minus the network address and the broadcast address, so **254 usable hosts**. The "minus two" is not a convention you memorise — those two addresses are genuinely spoken for.

> [!success]- Answer 2
> CIDR notation counts the number of one-bits in the mask.
>
> 255.255.255.0 is `11111111.11111111.11111111.00000000` —
> twenty-four ones, so **/24**.
>
> 255.255.0.0 is sixteen ones, so **/16**.
>
> 255.255.255.240 is `11111111.11111111.11111111.11110000` —
> twenty-four plus four, so **/28**.
>
> The last one is the reason to write masks in binary. In dotted decimal
> 240 tells you nothing; in binary it is obviously four bits of network
> and four bits of host.

> [!success]- Answer 3
> **No.** Apply the mask to both and compare the network parts.
>
> 192.168.1.10 with /24 is on network 192.168.**1**.0.
>
> 192.168.2.15 with /24 is on network 192.168.**2**.0.
>
> Different networks, so no direct conversation. Each machine, finding
> the destination is not local, hands the packet to its **default
> gateway**, and a router moves it between the two networks. If either
> machine has no gateway configured, it will simply fail — which looks
> identical to a cable fault from the user's chair and is not one.

> [!success]- Answer 4
> Mask 255.255.255.240 is /28, so the last octet splits four bits of
> network and four bits of host. Four host bits give a block size of
> $2^4 = 16$, meaning subnets start at 0, 16, 32, 48 and so on.
>
> 37 falls in the block that starts at 32 and ends at 47.
>
> **Network address:** 10.0.0.32.
>
> **Broadcast address:** 10.0.0.47.
>
> **Usable hosts:** 10.0.0.33 through 10.0.0.46.
>
> **Count:** $2^4 - 2 = 14$ usable hosts.
>
> Check the arithmetic the fast way: the block size is 16, and $37 \div 16 = 2$ with a remainder, so the block starts at $2 \times 16 = 32$ and the broadcast is one below the next block, $48 - 1 = 47$.

> [!success]- Answer 5
> An address in 169.254.x.x is self-assigned. The machine asked for a
> lease from a DHCP server, got no reply, and fell back to picking a
> link-local address so that it can at least talk to other machines doing
> the same thing.
>
> **Where the fault is:** upstream, not on this machine. Either the DHCP
> server is down or unreachable, the machine has no working link to it,
> or the address pool is exhausted. Configuring a static address makes
> the symptom disappear and leaves the fault in place — worth knowing
> before you reach for that fix.

> [!success]- Answer 6
> Convert to a common unit first. Links are rated in bits per second,
> files are measured in bytes, and one byte is eight bits.
>
> $50\ \text{MB} \times 8 = 400\ \text{Mbit}$, so $t = \frac{400\ \text{Mbit}}{40\ \text{Mbit/s}} = 10\ \text{s}$.
>
> If the transfer takes 40 seconds, the real throughput is $\frac{400\ \text{Mbit}}{40\ \text{s}} = 10\ \text{Mbit/s}$ — a quarter of what was claimed. That gap is a measurement, not a complaint, and it is where a duplex mismatch, a failing cable retransmitting, or a saturated link would show up.

> [!success]- Answer 7
> A **MAC address** is 48 bits, written as twelve hex digits, fixed in
> the hardware, and unique to that interface. It identifies *what* a
> device is, and it is only meaningful on the local segment — routers do
> not carry MAC addresses across networks.
>
> An **IP address** is assigned rather than built in, and it encodes
> *where* the device is: the mask splits it into a network part and a
> host part, and routing works entirely on the network part.
>
> Both are needed because they answer different questions. Routing across
> the world needs an address that says where to go; delivering the frame
> to one specific card on the final wire needs an address that says which
> card. A machine keeps a table matching the two for its neighbours,
> which is what `arp` displays and what shows two devices fighting over
> one IP address.

> [!success]- Answer 8
> **Most likely fault:** name resolution. DNS.
>
> The evidence is decisive. Reaching the gateway proves the local
> configuration and cabling work. Reaching 8.8.8.8 by address proves
> routing out of the network works. The only step left between that and
> loading a page by name is turning the name into an address.
>
> **Next command:** `ipconfig /all` (or the equivalent) to see which DNS
> server the machine has been given, followed by an attempt to reach that
> server. A machine with a DNS server address that is wrong, or one it
> cannot reach, produces exactly this symptom.

> [!success]- Answer 9
> **What is wrong with the reasoning:**
>
> A browser failing is the *last* test in the chain, not the first. It
> depends on the cable, the interface, the address, the mask, the
> gateway, routing, DNS, and the remote server — so its failure implicates
> everything at once and identifies nothing.
>
> The conclusion also skips every cheaper test. A cable tester takes ten
> seconds. A link light takes none.
>
> And it ignores the evidence already on the machine: if `ipconfig` shows
> a 169.254 address, the cable is almost certainly fine and the DHCP
> server is the problem.
>
> **The order they should have worked in:**
>
> 1. Link lights and a cable tester on the crimped cable.
> 2. `ipconfig` — is there an address, mask, and gateway?
> 3. Ping the loopback, 127.0.0.1 — is the stack alive?
> 4. Ping the gateway — is the local network working?
> 5. Ping something beyond it by address — is routing working?
> 6. Ping something beyond it by name — is DNS working?
> 7. *Now* open a browser.
>
> Stop at the first step that fails, because every step after it will
> fail too and tell you nothing new. Halving the problem is the same
> discipline as [[Debugging Hardware and Software Together]] — the
> network just gives you better instruments.

Wire it, address it, and prove it in [[Build and Test a Network]].

%%curriculum-start%%
## Curriculum connection

![[A4.1]]

![[A4.2]]

![[B4.2]]
%%curriculum-end%%
