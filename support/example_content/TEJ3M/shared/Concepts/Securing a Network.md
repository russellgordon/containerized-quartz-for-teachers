---
title: Securing a Network
draft: false
created: __CREATED__
tags:
  - concepts
enableToc: true
---
Security is not a product you add at the end. It is a set of decisions
made while the network is being built, each one closing a door that
would otherwise stay open because nobody thought about it.

## The layers, outside in

| Layer | What it does | What it does not do |
| --- | --- | --- |
| **Physical security** | Locks the server room, the cabinet, and the spare ports | Nothing about traffic — but an attacker at the console owns the machine |
| **Firewall** | Allows and blocks traffic by address, port, and direction | Inspect encrypted content, or stop what you have allowed |
| **Authentication** | Establishes who a user is — password, key, second factor | Say what they may then do |
| **Authorisation** | Says what that identity may reach | Help if the identity was stolen |
| **Encryption in transit** | Makes intercepted traffic useless — TLS, and WPA2/WPA3 on wireless | Protect data at rest on the drive |
| **Encryption at rest** | Protects data on a stolen drive or backup | Protect an unlocked, logged-in machine |
| **Patching and monitoring** | Closes known holes; notices the unusual | Work at all if nobody reads the alerts |

Every row protects against a different attack. That is why "we have a
firewall" is not an answer to "is it secure" — it is an answer to one
question out of seven.

## Wireless, specifically

An old wireless network may still be running **WEP**, which has been
broken since the early 2000s and can be cracked in minutes. **WPA2**
with a strong passphrase is the working minimum; **WPA3** is better
where every device supports it. A guest network, separated from the
internal one, is the single cheapest improvement most small sites can
make.

## Passwords, honestly

Length beats complexity: a long passphrase resists guessing better than
a short string of symbols nobody can remember and everyone writes down.
Uniqueness beats both — a reused password turns one breach into all of
them. And a password manager is not cheating; it is the only realistic
way for one person to hold forty unique credentials.

Stored passwords are never stored: they are **hashed**, with a salt, so
that a stolen database does not hand over the passwords themselves.
A service that can email you your existing password has told you
something alarming about how it stores them.

> [!important] The rule for this course
> You test security only on the equipment assigned to your bench, and
> only what the task asks for. Scanning, capturing, or accessing
> anything else — including "just to see if it works" — breaks
> [[Our Classroom Norms]] and, off school equipment, breaks the law.
> The skills on this page are exactly as useful to somebody doing harm,
> which is why the profession takes authorisation so seriously.

## What to write down

For any network you build, the security section of the documentation
records: what is allowed through the firewall and why, who has
administrative accounts, how the wireless is protected, what is
encrypted, where the backups live, and when the passwords were last
changed. If that section is missing, the handover in
[[The Client Build]] is not complete.

%%curriculum-start%%
## Curriculum connection

![[A4.4]]

![[D2.3]]
%%curriculum-end%%
