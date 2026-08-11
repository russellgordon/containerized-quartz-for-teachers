---
title: Storage and Drives
draft: false
created: __CREATED__
tags:
  - concepts
enableToc: true
---
The heaviest small thing in [[Take It Apart]] was probably a hard
drive — a sealed metal brick that, opened carefully, turns out to be a
mirror-finish record player. The lightest was a flash drive with no
moving parts at all. Both do the same job by opposite means.

## Two ways to remember

A hard drive stores bits as tiny magnetic spots on spinning platters,
read by an arm that skims a hair's width above the surface. A
solid-state drive (SSD) stores bits as electric charge trapped in
microscopic cells — nothing moves, which is why it is faster, quieter,
and shrugs off the bump that would scar a platter. The trade has
always been the same: spinning drives give more space per dollar;
flash gives speed and toughness.

## What "saving" physically means

When you save a file, the machine copies it from
[[The CPU and Memory|RAM]] — which forgets everything at power-off —
onto one of these durable surfaces: magnet flips or trapped charge.
That is all saving is. Deleting is stranger: the drive usually just
crosses the file out of its index and leaves the bits in place until
something overwrites them, which is why undelete tools work — and why
wiping a drive properly matters before a machine leaves your hands.
You felt the cost of all this in [[Install an Operating System]],
where most of the waiting was writing.

## Capacity, honestly

Storage is measured in bytes: about a thousand to the kilobyte, a
thousand of those to the megabyte, then gigabytes, then terabytes.
Buy a "1 TB" drive, though, and the operating system may report about
931 GB. Nothing is missing — the maker counted in powers of ten and
the OS counted in powers of two.[^1] [[Reading a Spec Sheet]] covers
the other numbers on a drive's label, and [[Spec Sheet Practice]]
puts real ones in front of you.

[^1]: Drive makers define $1\ \text{TB} = 10^{12}$ bytes. Operating
    systems often count in units of $2^{40}$ bytes, and
    $10^{12} / 2^{40} \approx 0.909$ — so the same drive honestly
    reports about 931 "gigabytes". Both are counting the same bits.

%%curriculum-start%%
## Curriculum connection

![[A1.2]]
%%curriculum-end%%
