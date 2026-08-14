---
title: Specification Practice
draft: false
created: __CREATED__
tags:
  - exercises
---
These follow [[Writing a Specification]], [[System Block Diagrams]], and
[[Component Selection and Tolerances]] — the paperwork that decides
whether the build is possible before anybody opens the parts drawer.
Answer in the form the question asks for: a rewritten sentence, a
numbered budget, or a worst case with its arithmetic shown.

## Writing statements that can be checked

1. Rewrite each of these so that two people running the same test would
   reach the same verdict. Add a number where a number is missing, and
   say what you assumed.
   - "The alarm should respond quickly."
   - "The device must have good battery life."
   - "The enclosure should be robust."
2. Classify each statement as a **requirement**, a **constraint**, an
   **acceptance test**, or **none of these**, and justify the awkward
   ones.
   - "The controller shall hold the plate within ± 0.5 °C of setpoint."
   - "The board must run from the school's 12 V bench supplies."
   - "Use an op-amp with a gain of 165."
   - "Heat the plate to 40 °C, allow ten minutes to settle, and record
     the temperature every 30 s for five minutes; all readings within
     ± 0.5 °C."
3. A requirement reads: "The fan shall start when the plate gets hot."
   Write the acceptance test you would run, including the equipment, the
   procedure, the number of trials, and the pass criterion.

## Budgets, tolerances, and worst cases

4. A battery-powered logger draws 25 mA (microcontroller), 3 mA
   (sensor), and 120 mA from its radio for 200 ms once every 60 s.
   Calculate the average current and the run time from a 2000 mA·h cell.
   Does it meet a requirement of 48 hours?
5. The customer now wants a reading transmitted every 10 s instead of
   every 60 s. Recalculate, and say whether the 48-hour requirement
   still holds — first on the full 2000 mA·h, then assuming only 80% of
   the cell's capacity is usable in the cold.
6. The same logger's supply must handle every load being on at once.
   Calculate the peak current and say whether a supply rated for 150 mA
   is acceptable.
7. A divider of two nominally equal 10 kΩ resistors, each ± 1%, is fed
   from a 5 V supply specified as ± 5%. Calculate the highest and lowest
   possible output voltage. A comparator elsewhere in the design
   switches at 2.60 V — what does your answer mean for production?
8. **Find the error.** A group's specification for a temperature
   controller reads, in full: "Requirement 1: the device shall use a
   10-bit ADC and a thermistor. Requirement 2: the device shall be
   accurate. Requirement 3: the device shall be tested by the teacher."
   List everything wrong with it, and rewrite the three lines properly.

## Answers

> [!success]- Answer 1
> Each rewrite needs a measurable quantity, a condition, and a limit.
>
> **"Respond quickly"** → "The alarm shall sound within 500 ms of the door contact opening, at any supply voltage within the specified range." *Assumption: 500 ms is fast enough for a person to hear before the door has fully opened; the source of that number should be named.*
>
> **"Good battery life"** → "The device shall operate for at least 48 hours from a fully charged 2000 mA·h cell at 20 °C, transmitting once per minute." *Assumption: the duty cycle, which changes the answer entirely — see question 5.*
>
> **"Robust enclosure"** → "The enclosure shall survive a 1 m drop onto a hard floor on each face without loss of function." *Assumption: a drop test is what "robust" means here; if the real worry is dust or water, the requirement should name an ingress rating instead.*
>
> Notice that writing the requirement forced you to decide what you meant. That is not a side effect — it is the entire purpose.

> [!success]- Answer 2
> **"Within ± 0.5 °C of setpoint"** — a **requirement**. It says what the device must do, and it has a number, so it can pass or fail.
>
> **"Must run from the school's 12 V bench supplies"** — a **constraint**. It is a limit imposed from outside, not a behaviour of the device, and it will shape the regulator choice in [[Power Supplies and Regulation]].
>
> **"Use an op-amp with a gain of 165"** — **none of these**, and the most dangerous line on the list. It is a *solution* wearing a requirement's clothes. The genuine requirement is something like "the device shall resolve 0.1 °C over the range 0 – 80 °C"; the gain of 165 is one way to meet it, and writing it as a requirement forbids every other way before anybody has thought about it.
>
> **The ten-minute settling procedure** — an **acceptance test**. It names the equipment, the procedure, and the criterion, so two people get one verdict.

> [!success]- Answer 3
> A usable acceptance test for "the fan shall start when the plate gets hot" — noting first that the requirement itself must be fixed, because "hot" is not a number. Assume the requirement is: **the fan shall start within 5 s of the plate temperature exceeding 28 °C.**
>
> **Equipment:** a calibrated reference thermometer, a stopwatch, and the hot plate.
>
> **Procedure:** with the device idle and the plate below 24 °C, raise the plate temperature at no more than 2 °C per minute. Record the reference thermometer reading at the moment the fan starts, and the elapsed time from the reference crossing 28 °C.
>
> **Trials:** five, from cold each time.
>
> **Pass criterion:** the fan starts in every trial, in each case within 5 s of the reference crossing 28 °C, and at a temperature between 27.5 °C and 28.5 °C.
>
> The reference thermometer is the part students leave out. Testing the device against its own sensor proves only that the code matches itself.

> [!success]- Answer 4
> Average the radio over the whole period first, because it is only on for a fraction of it.
>
> $I_{\text{radio}} = 120\ \text{mA} \times \frac{0.2\ \text{s}}{60\ \text{s}} = 0.4\ \text{mA}$
>
> $I_{\text{average}} = 25 + 3 + 0.4 = 28.4\ \text{mA}$
>
> $t = \frac{2000\ \text{mA} \cdot \text{h}}{28.4\ \text{mA}} \approx 70.4\ \text{h}$
>
> **Yes** — about 70 hours against a requirement of 48, a margin of roughly 47%. Say the margin out loud in the specification; it is the number that tells the next person how much room there is to add a feature.

> [!success]- Answer 5
> The radio is now on for 200 ms every 10 s, six times as often.
>
> $I_{\text{radio}} = 120\ \text{mA} \times \frac{0.2\ \text{s}}{10\ \text{s}} = 2.4\ \text{mA}$
>
> $I_{\text{average}} = 25 + 3 + 2.4 = 30.4\ \text{mA}$, so $t = \frac{2000}{30.4} \approx 65.8\ \text{h}$.
>
> Still comfortably past 48 hours — and the useful observation is *why*. The radio was never the problem; the microcontroller's 25 mA dwarfs it. Six times as many transmissions cost only about 7% of the run time (70.4 h down to 65.8 h), so if this device needs to last longer, the work to do is putting the microcontroller to sleep, not transmitting less.
>
> With only 80% of the capacity usable, $t = \frac{0.8 \times 2000}{30.4} \approx 52.6\ \text{h}$ — still a pass, but the margin has fallen from 37% to about 10%. That is the number to report, because it is the one that describes the device in February.

> [!success]- Answer 6
> Peak means everything at once, including the load that only appears occasionally.
>
> $I_{\text{peak}} = 25 + 3 + 120 + 20 = 168\ \text{mA}$
>
> A 150 mA supply is **not acceptable**. It will work for the 59.8 seconds of every minute when the radio is idle and sag exactly when the radio transmits — producing a fault that appears only during transmission, which is the hardest kind to diagnose.
>
> Size supplies from the peak, with margin, and remember that some loads have an inrush current higher than their running current. A supply chosen from the average is a supply chosen from the wrong number.

> [!success]- Answer 7
> Work the extremes rather than the nominal. The output is highest when the upper resistor is at its lowest and the lower resistor at its highest, on a high supply:
>
> $V_{\text{max}} = 5.25\ \text{V} \times \frac{10.1\ \text{k}\Omega}{9.9\ \text{k}\Omega + 10.1\ \text{k}\Omega} = 5.25 \times 0.505 \approx 2.651\ \text{V}$
>
> $V_{\text{min}} = 4.75\ \text{V} \times \frac{9.9\ \text{k}\Omega}{10.1\ \text{k}\Omega + 9.9\ \text{k}\Omega} = 4.75 \times 0.495 \approx 2.351\ \text{V}$
>
> So the real output is somewhere in **2.351 V to 2.651 V**, against a nominal 2.500 V — about ± 6%.
>
> **What it means for production:** a comparator switching at 2.60 V sits *inside* that band. Some boards will switch and some will not, and every one of them is built correctly. This is the classic tolerance-stack failure: it passes on the bench, where you have one set of parts, and fails on a fraction of the class's builds.
>
> Fixes, in order of cost: make the measurement ratiometric so that the supply cancels out; use 0.1% resistors and a proper reference; or move the threshold well outside the worst-case band and document why it sits there.

> [!success]- Answer 8
> **What is wrong:**
>
> "Requirement 1" is not a requirement at all — it names a solution (10-bit ADC, thermistor) and so forbids every alternative before anyone has established what the device must actually do. Those are design decisions, and they belong in the design section with the reasoning that produced them.
>
> "Requirement 2" is untestable. "Accurate" has no number, no condition, and no procedure, so it can neither pass nor fail. A requirement that cannot fail is not a requirement.
>
> "Requirement 3" is not a requirement either; it is a vague statement about assessment. An acceptance test names the procedure and the criterion, not the person.
>
> The whole document is also missing constraints, interfaces, and a source for each requirement.
>
> **A rewrite:**
>
> **R1.** The device shall measure temperature over the range 0 °C to 80 °C. *(Source: the customer's process.)*
>
> **R2.** The device shall report temperature with an error no greater than ± 0.5 °C over that range, when compared with a calibrated reference. *(Source: the customer's tolerance.)*
>
> **R3.** The device shall run from the school's 12 V bench supply and draw no more than 300 mA. *(Constraint: available equipment.)*
>
> **A1 (acceptance test for R1 and R2):** in a stirred water bath, compare the device against a calibrated reference at 0, 20, 40, 60, and 80 °C; five readings at each point, all within ± 0.5 °C of the reference.
>
> Now the 10-bit converter can be *justified* rather than assumed — and the arithmetic in [[Sampling and Resolution Practice]] will tell you whether it is good enough.

Take a real requirement from your own [[The Specification]] draft and run
question 3's treatment on it. If you cannot write the acceptance test,
the requirement is not finished — and finding that out now is the whole
reason this set exists.

%%curriculum-start%%
## Curriculum connection

![[B2.2]]

![[A3.1]]

![[D3.3]]
%%curriculum-end%%
