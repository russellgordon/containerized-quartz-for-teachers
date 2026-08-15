---
title: Maintenance Utilities
publish: true
created: __CREATED__
tags:
  - tutorials
enableToc: true
---
Every operating system ships with tools for keeping a machine healthy,
and most users never open one. A technician opens them before touching
a screwdriver, because half of what gets diagnosed as "the computer is
dying" is a full disk or a missing file.

## The five that earn their keep

| Utility | What it answers | When you reach for it |
| --- | --- | --- |
| Storage or disk usage | How much space is left, and what is using it | Any complaint that includes the word "slow", first |
| Disk check / repair | Is the file system itself damaged? | After a hard power loss, or when files vanish |
| Defragment (spinning disks) or TRIM (solid state) | Is the drive organised the way it wants to be? | Old machines with mechanical drives; TRIM runs itself and should be left alone |
| File recovery / undelete | Can I get that back? | Immediately after the mistake, and not one write later |
| Backup and restore | Where is the copy, and does it actually restore? | Before every refurb, and once a term on your own work |

## Checking free space, properly

A drive over about 90% full slows down and starts failing in ways that
look like other problems. Check the number, then find out what is
eating it — usually one of four things: system update caches, a
downloads folder nobody empties, virtual machine or game files, or a
backup that has been running to the same drive it is backing up.

## Undelete, and why speed matters

Deleting a file usually removes the *pointer*, not the data. The space
is marked available, and the file survives until something writes over
it. So the recovery rule is simple and non-negotiable:

> [!warning] Stop writing to the drive
> The moment a customer says "I deleted it", stop using that machine.
> Every file saved, every program installed, every reboot on some
> systems reduces the chance of getting it back. Recover to a
> DIFFERENT drive, never to the one you are recovering from.

## Backups are not backups until restored

A backup you have never restored is a hypothesis. Test it the way a
technician does:

1. Restore ONE file to a temporary folder.
2. Open it, and confirm it is the version you expected.
3. Note in the service record when the restore was tested.

The rule worth taking out of this course: **three copies, on two kinds
of media, one of them somewhere else.** A single external drive sitting
beside the machine survives a disk failure but not a theft, a fire, or
a spilled coffee that reaches both.

## Before you hand any machine back

- [ ] Free space checked and reported
- [ ] Disk check run, result recorded
- [ ] Updates applied, or their state noted
- [ ] Backup taken, and one file restored from it as a test
- [ ] Everything above written in the service record, not remembered

Copy that list into your [[Tech Journal]] — it is the pre-flight check
for [[The Refurb Report]] and for any machine you service after this
course.

%%curriculum-start%%
## Curriculum connection

![[B4.4]]

![[B4.2]]

![[D1.1]]
%%curriculum-end%%
