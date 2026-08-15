---
title: Security Is a Trade-Off
publish: true
created: __CREATED__
tags:
  - discussions
enableToc: true
---
"Is it secure?" is not a question with an answer. It is a question with
a *missing clause*: secure against whom, protecting what, for how long,
and at what cost to the person legitimately trying to use the thing.
Fill in those blanks and the argument becomes tractable. Leave them
blank and you get security theatre — measures that look protective,
cost real money and real convenience, and stop nobody who was actually
trying.

## Nothing is secure; things are secure against something

A lock on a door is not "secure". It raises the cost of entry above
what a particular class of intruder is willing to pay. That is all any
security control ever does, including the good ones.

Which means the first document is never a control list. It is a
**threat model**: who might attack this, what do they want, what can
they reach, and what would it cost them. Five lines, written before any
decision, and it changes every decision after it.

> [!question]- A worked threat model, in five lines
> **The system.** A greenhouse controller on the school network: a
> microcontroller reading temperature and humidity, switching a fan
> and a heater, reporting readings to a small server in the lab.
>
> **What is worth protecting.** Not the temperature readings — those
> are boring. The *ability to switch the heater* is worth protecting,
> because it can damage plants and, if it fails on, become a fire
> risk. So the asset is control, not data.
>
> **Who might reach it.** Anybody on the school network, which is
> everybody in the building. Anybody who can physically touch the box
> in an unlocked greenhouse. Nobody on the open internet, because it
> is not exposed — and that single fact removes most of the attack
> surface at no cost, which is the cheapest security decision
> available to anyone.
>
> **What would it cost them.** Reaching the network: nothing, they
> are already on it. Touching the board: a walk. Guessing the default
> password the firmware shipped with: about four seconds.
>
> **What follows.** Change the default credential and make that
> impossible to skip; require authentication for the control endpoint
> but not for the readings; log every switching command with a
> timestamp; put a hardware thermal cut-out on the heater that no
> amount of network access can override. Notice the last one is not
> a security control at all. It is
> [[When Good Enough Is Not Safe|a safety design]] that happens to
> bound the worst thing an attacker can achieve, and it is more
> valuable than everything above it.

## The cost is always paid by somebody

Every control has a price, and the price is usually charged to the
legitimate user. A password policy nobody can satisfy produces sticky
notes. A two-step login on a shop-floor terminal that six people share
produces one person logged in all day. A device that locks itself after
three wrong attempts produces a denial-of-service you built yourself.

The rule that follows is uncomfortable and true: **a control people
route around has made the system less secure, not more.** The bypass
becomes the real interface, and now it is undocumented. Usability is
not the opposite of security; unusable security is a failure mode of
security.

Availability belongs in the same conversation. A lock that bricks a
medical device is not a stronger lock. A firmware update that refuses
to install without a server that no longer exists has turned a security
feature into a shutdown switch.

## Honest limits

Three statements that are true and that vendors rarely volunteer.

- **If the attacker holds the hardware, you cannot win outright.** Debug
  ports, flash readout, glitching, and simply watching how long an
  operation takes are all real. What you can do is raise cost and
  reduce reward — encrypt what matters, store as little as possible,
  and make one compromised device not compromise the others.
- **Obscurity is not a control.** Hiding how something works buys time
  against a casual attacker and nothing against a determined one, and
  it makes the design harder for your own side to review. A design
  that only survives because nobody has looked has not been tested.
- **Old code does not stay secure by sitting still.** The code is
  unchanged; what is known about it is not. This is the argument that
  ties straight into [[Who Owns the Firmware]] and end-of-support.

> [!warning] Theatre has a smell
> A password field with no rules behind it. A "military-grade
> encryption" claim with no statement of what is encrypted, or when,
> or against whom. A privacy setting that changes what you see and not
> what is collected. A certificate warning users are trained to click
> through. Each one costs somebody something and protects nothing —
> and each one is easier to ship than the boring control that would
> have worked.

## Questions worth arguing about

1. Take one device you own. Write its five-line threat model. Then
   name one control it has that does not match the model, in either
   direction — protection you do not need, or exposure nobody
   addressed.
2. Default passwords on network devices have caused enormous real
   harm. Should shipping one be treated the way shipping an
   uninsulated mains lead would be? What would that regime cost, and
   who would pay it?
3. Your capstone reports readings over the lab network. Argue for
   *not* adding authentication. Make the strongest honest case you
   can — then say what would change your mind.
4. Security updates require the ability to replace running code, which
   is the same ability an attacker wants. Design the update path.
   Where did you put the trust, and who holds it in five years?
5. Where does responsibility sit when a device is compromised because
   the owner never changed a setting the manufacturer chose badly?
   Split the blame with actual percentages and defend them.

Bring the same standard here that [[Tech Headlines]] applies to a
product claim: a security claim without conditions is not a claim. And
bring the standard from [[Our Classroom Norms]] — the strongest
position in this discussion is usually held by the person willing to
name the cost of their own proposal.

%%curriculum-start%%
## Curriculum connection

![[D2.1]]

![[D2.3]]

![[B4.2]]
%%curriculum-end%%
