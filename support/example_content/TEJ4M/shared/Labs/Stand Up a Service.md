---
title: Stand Up a Service
publish: true
created: __CREATED__
tags:
  - labs
enableToc: true
---
A network that carries nothing proves nothing. Today your bench
configures a machine to serve something real, gives it users with
different privileges, and proves both by trying to break in from the
next bench.

> [!danger] Safety and authorisation
> Nothing here is electrically dangerous and everything here is
> professionally dangerous. You scan, probe, and attempt access ONLY on
> the bench and addresses assigned to you, and only what the steps
> below ask for. Anything else breaks [[Our Classroom Norms]] and, off
> school equipment, breaks the law. The instinct to "just try it on the
> school server" is exactly the instinct this lab exists to discipline.

## What you need

- [ ] Two machines on your bench network, one to serve and one to test
- [ ] A drive or partition on the server machine that may be formatted
- [ ] Your network drawing from [[Design and Test a Network]], updated
      as you go

## Part A — Prepare the machine

1. **Partition and format** the storage deliberately: one volume for the
   system, one for the served data. Record the filesystem and why you
   chose it.
2. **Set a static address or a DHCP reservation** for the server, and
   say in your notes which you chose and why — the argument is in
   [[Addressing at Scale]].
3. **Create accounts**: one administrator, two ordinary users, and one
   service account. Nobody works day to day as an administrator.
4. **Assign folder privileges**: one folder readable by both users and
   writable by one; one folder readable by neither. Write the intended
   matrix down BEFORE you set anything.

## Part B — Run services

Choose at least **three**, and configure each so it starts on boot:

| Service | What it does | Prove it by |
| --- | --- | --- |
| **HTTP** | Serves a page | Fetching it from the other machine by address and by name |
| **FTP or SFTP** | File transfer | Uploading as one user and being refused as the other |
| **Remote desktop or SSH** | Remote administration | Connecting, then confirming the account restrictions hold |
| **DHCP** | Hands out addresses | Watching a client receive a lease, and reading the lease table |
| **SMTP relay (lab only)** | Mail submission | Sending one message inside the bench network |

## Part C — Test it like an attacker who is allowed to

1. From the second machine, verify the permission matrix **row by row**:
   every allowed action succeeds, every forbidden one fails.
2. Record the exact error message for each refusal. Those messages are
   what a user will read you over the phone one day.
3. Check what is listening: which ports are open, and can you justify
   every one? Close anything you cannot.
4. Try one deliberately weak credential on your own server, confirm it
   gets in, then fix it — and note how long the fix took compared with
   how long the mistake took.

## Record in your service documentation

The account list with privileges, the permission matrix as intended and
as tested, every service with its port and start-up setting, the open
ports you justified, and the address plan. That set is what
[[The Deployment]] hands over, and what
[[Writing Documentation Somebody Can Build From]] describes.

%%curriculum-start%%
## Curriculum connection

![[B4.3]]

![[B4.4]]

![[A4.4]]

![[B4.2]]
%%curriculum-end%%
