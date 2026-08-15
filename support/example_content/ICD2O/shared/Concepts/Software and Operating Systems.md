---
title: Software and Operating Systems
publish: true
created: __CREATED__
tags:
  - concepts
enableToc: false
---
By the time you finished [[Setting Up Python]], you had already met
the two layers this page names: the app you installed, and the
operating system you installed it *into*. Every device works this way
— a stack, with your apps on top and one very busy program
underneath.

## Apps do one job

An app — short for application — is software with a purpose you can
say in a sentence. Browse the web. Edit photos. Play music. Run
Python. Apps are the layer you choose: each one is on your device
because somebody decided to put it there, and each can be removed
without the device caring.

## The operating system does everything else

The OS — Windows, macOS, iOS, Android, Linux — is the program that
runs the machine itself. It decides which app gets the CPU next,
parcels out memory, draws the windows, reads the keyboard, and
guards the files. Apps never touch the hardware from
[[Hardware Inside the Box]] directly — they ask the OS, and the OS
does the touching. That is also why the "same" app on your phone and
your laptop is really two apps: each was written to ask a different
OS.

## Updates are maintenance, not nagging

All software ships with mistakes in it — all of it, always, which is
why [[Debugging Is the Job]] is a discussion and not a joke. Updates
are how mistakes get fixed after shipping, and some of those
mistakes are security holes that [[Staying Secure Online]] would
rather you not leave open.

> [!tip] The unglamorous truth about updates
> An update notification is a repair crew offering to fix your house
> for free. Scheduling it for a convenient hour is sensible —
> overnight is fine. Postponing it forever mostly protects the bugs.

%%curriculum-start%%
## Curriculum connection

![[B1.3]]
%%curriculum-end%%
