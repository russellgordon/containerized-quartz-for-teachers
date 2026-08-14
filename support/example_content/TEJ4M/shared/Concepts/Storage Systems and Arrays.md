---
title: Storage Systems and Arrays
draft: false
created: __CREATED__
tags:
  - concepts
enableToc: true
---
Choosing storage is a Grade 12 problem because there is no best answer,
only a defensible one: capacity, speed, endurance, and what happens
when a drive dies, weighed against what the system is for.

## The devices, and what each is actually for

| Device | Strength | Weakness | Where it belongs |
| --- | --- | --- | --- |
| **Mechanical hard drive** | Cost per terabyte, and predictable wear | Seek latency; vibration and shock | Bulk storage, archives, surveillance |
| **SATA solid state** | No seek time; quiet and cool | Costlier per terabyte; finite write endurance | General workstations |
| **NVMe solid state** | Sits directly on PCI Express lanes — several gigabytes per second | Thermal throttling; costs more again | Boot volumes, video editing, databases |
| **Flash drives and cards** | Portable, cheap, universally readable | Poor endurance and no warning before failure | Transfer, never storage |
| **Optical** | Write-once media that cannot be silently altered | Slow, small, and drives are disappearing | Archival where immutability matters |
| **Network and cloud storage** | Shared, off-site, someone else's backup problem | Depends on the link; recurring cost; someone else's outage | Shared work, off-site copies |

## Arrays: several drives behaving as one

An array trades capacity for redundancy or speed, and the trade is the
whole point.

| Level | How it works | Buys you | Costs you |
| --- | --- | --- | --- |
| **RAID 0** | Data striped across drives | Speed and full capacity | Any drive fails, everything is gone — *more* risk, not less |
| **RAID 1** | Mirrored copies | Survives one drive failing; simple to rebuild | Half the capacity |
| **RAID 5** | Striped with distributed parity | Survives one failure, good capacity | Slow, risky rebuilds on large drives |
| **RAID 6** | Two parity blocks | Survives two failures | More overhead, slower writes |
| **RAID 10** | Mirrored pairs, striped | Speed and resilience | Half the capacity, more drives |

> [!warning] The sentence to memorise
> **RAID is not a backup.** It protects against a drive failing. It does
> nothing about deletion, ransomware, fire, theft, or a controller that
> writes corruption to every member at once. The backup rule from
> [[Standards and Professional Practice]] still applies on top of it.

## Reading the specification that matters

Beyond capacity, three numbers decide whether a drive suits the job:
sustained transfer rate — which is far below the burst figure on the
box; IOPS, which is what a database or a busy server actually feels; and
endurance in terabytes written, which is how you predict when a solid
state drive in a logging application will wear out.

## Where the advances went next

Storage did not improve in isolation. Cheap, small, low-power flash is
the reason a phone can hold a camera roll, a car can log a hundred
sensors, and a microcontroller can carry a filesystem. The same is true
of the other side of the machine: as processors gained cores and dropped
in power, the technologies that became possible were not faster desktops
but hand-held devices, wearables, drones, and the embedded controllers
in this room. Each advance in the core parts opened a category of
product that could not have existed the year before — which is the
argument you will have to make in writing in [[The Deployment]].

%%curriculum-start%%
## Curriculum connection

![[A1.2]]

![[A1.3]]
%%curriculum-end%%
