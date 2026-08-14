---
title: Software and Operating Systems
publish: true
created: __CREATED__
tags:
  - concepts
enableToc: true
---
For most of [[Install an Operating System]] you watched a progress
bar and wondered what could possibly take so long. The answer: the
machine was being given the one program that lets it run all the
others.

## The layer beneath the apps

Bare hardware does nothing useful. The operating system — Windows,
macOS, Linux — is the program that manages everything the others
share: which program gets the CPU next, where files live on the
drive, what appears on screen, who is allowed to log in. Applications
never touch the hardware directly; they ask the OS, and the OS
decides. That is why the same application can crash without taking
the whole machine down — the landlord survives a bad tenant.

## Operating system versus application

An application does a job you chose: write an essay, edit a photo,
play a game. The OS does the jobs nobody chooses but everyone needs.
Drivers sit between the two — small pieces of software that teach the
OS to speak one specific device's dialect, which is why new hardware
sometimes does nothing until its driver is installed. When software
misbehaves, deciding which layer is at fault is half the diagnosis,
a skill [[Troubleshooting Practice]] works directly.

## Installing, updating, licensing

A fresh install is not finished when the desktop appears. The
machine is ready for a user when you can check every box:

- [ ] Updates applied — the fixes found since the installer was made
- [ ] Drivers installed for any hardware the OS did not recognize
- [ ] The applications this machine actually needs, and no more
- [ ] A licence you genuinely hold for every piece of paid software
- [ ] A backup arrangement, tested once

On licensing, plainly: buying software buys permission to use it, not
ownership of it. Open-source licences grant that permission to
everyone; commercial licences sell it per machine or per person; and
a copied licence key is not a purchase. Help systems and vendor
documentation are part of the product too — [[Finding Answers Online]]
shows how to use them before guessing.

%%curriculum-start%%
## Curriculum connection

![[B4.1]]

![[B4.2]]
%%curriculum-end%%
