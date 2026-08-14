---
title: Keeping Data Safe
draft: false
created: __CREATED__
tags:
  - concepts
enableToc: true
---
Nobody in this room will lose their work to a dramatic attack. They
will lose it to a laptop left on a bus, a folder synced over itself, or
a download that was not what it claimed to be. Protection is a routine,
not an event.

## What is actually out there

**Malware** is the umbrella word for software written to work against
the person running it, and the varieties differ in how they arrive:

- A **virus** attaches itself to a file you already trust and travels
  when that file does.
- A **worm** needs no host and no help — it spreads across a network on
  its own.
- A **trojan** looks like something you wanted. It is the free copy of
  the expensive thing.
- **Ransomware** encrypts your files and sells the key back to you.
- **Spyware** watches quietly: keystrokes, passwords, screens.
- **Phishing** is not software at all. It is a message engineered to
  make you hand over a password yourself, and it is how most real
  breaches start.

The last one matters most, and it is the one no program can fully
prevent. A system is compromised through the person far more often than
through the machine.

## A protection plan that a person will actually follow

| Layer | The routine | What it stops |
| --- | --- | --- |
| Updates | Apply operating-system and browser updates promptly | The already-known hole, which is most of them |
| Accounts | Long, unique passwords in a password manager; two-factor on anything that matters | One leaked password becoming ten broken accounts |
| Scanning | Leave the built-in protection on; scan anything from a stranger | Known malware from downloads and drives |
| Least privilege | Work in a normal account, not an administrator one | A bad click changing the whole system |
| Backups | Three copies, two kinds of media, one somewhere else | Ransomware, theft, fire, and your own mistakes |
| Judgement | Verify unexpected messages by another channel | Phishing, which is the actual front door |

The backup line is the one that turns a catastrophe into an
inconvenience, and it is the only defence that works against an attack
nobody has seen before. [[Backing Up Your Work]] is the practical
version.

> [!warning] Being helpful is the attack surface
> A message that creates urgency — an account closing, a coach needing
> the roster *right now* — is doing that on purpose, because hurry
> defeats judgement. Slow down and check by a different channel: phone
> the person, or type the address yourself rather than following the
> link. Ten seconds of scepticism outperforms every product you can
> buy.

## Your programs are part of somebody's system

When you write software that other people run, their safety is partly
your responsibility. Do not ask for data you do not need. Do not store
a password in a plain text file next to the program. Assume that any
input can be hostile and check it before you use it — the habit
[[The Bad Input Hunt]] built for correctness is the same habit that
keeps a program from being turned against its user.

%%curriculum-start%%
## Curriculum connection

![[C2.2]]
%%curriculum-end%%
