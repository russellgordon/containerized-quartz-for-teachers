---
title: Firmware and System Optimisation
draft: false
created: __CREATED__
tags:
  - concepts
enableToc: true
---
Between the power button and the operating system sits software that
belongs to the board rather than to the drive. Knowing what it does, and
what can safely be tuned afterwards, separates a technician from someone
who reinstalls things and hopes.

## What the firmware does

The **BIOS** — a **UEFI** implementation on anything modern — is the
first code the processor runs. Its jobs, in order:

1. **Power-on self test**: check the processor, memory, and essential
   devices, and report failures by beep code or board LED *before* a
   display is possible.
2. **Hardware recognition**: enumerate and initialise devices.
3. **Resource allocation**: assign the address ranges and interrupts
   that devices need to coexist.
4. **Port and device settings**: enable or disable interfaces, set
   storage modes, control virtualisation support.
5. **Energy management**: power states, fan curves, and wake behaviour.
6. **Boot device selection**, then hand over to the bootloader.

After hand-over the operating system reaches hardware through its own
drivers, not through the firmware. That division is why a capability can
be missing in software because it is switched off in firmware, and no
amount of reinstalling will bring it back.

## Optimisation, in the order worth doing it

| Step | What it addresses | The honest caveat |
| --- | --- | --- |
| **Firmware update** | Compatibility, stability, published security fixes | Can brick a board if interrupted — mains power or a UPS, always |
| **Driver updates** | Devices that misbehave or underperform | Newer is not automatically better; note the version you replaced |
| **Storage housekeeping** | A drive over about 90% full slows and misbehaves | Free space first; it is the cheapest fix in computing |
| **Defragmentation** | Mechanical drives only | On solid state it is useless and consumes write endurance — leave TRIM to run itself |
| **Virtual memory sizing** | Systems that page heavily | A swap file is not a substitute for memory; sizing it larger hides the symptom |
| **Startup and service pruning** | Boot time and idle load | Disabling services you cannot name is how support calls are created |
| **Thermal work** — dust, paste, fan curves | Sustained performance under load | Measure temperatures before and after, or you have not shown anything |

## Measure, change one thing, measure again

Optimisation without measurement is superstition. Take a baseline —
boot time, a benchmark, temperatures under load, free space — change
**one** thing, and measure again. Record both numbers in your
[[Tech Journal]]. That discipline is the same one
[[Testing Without a Debugger]] applies to firmware, and it is what makes
a claim of improvement defensible in [[The Deployment]].

> [!tip] Before any firmware update
> Record the current version, read the release notes to the end, confirm
> the machine cannot lose power, and know how the board recovers from a
> failed flash. Some have a dual-BIOS or a USB recovery mode; some do
> not, and on those the answer to a failed flash is a new board.

%%curriculum-start%%
## Curriculum connection

![[A2.2]]

![[A2.3]]
%%curriculum-end%%
