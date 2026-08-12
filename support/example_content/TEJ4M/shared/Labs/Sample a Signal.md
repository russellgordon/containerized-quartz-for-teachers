---
title: Sample a Signal
draft: false
created: __CREATED__
tags:
  - labs
enableToc: true
---
A converter does not measure a signal. It measures the signal at
instants, and then your program pretends the gaps were not there. Most
of the time the pretence is harmless. Today you find the conditions
under which it is a lie, and you produce the lie deliberately: a fast
signal that comes back as a slow one, steady and convincing and
completely fictional.

Then you fix it the only way it can be fixed — in hardware, before the
converter, because no amount of code can recover something that was
never sampled.

> [!danger] Safety notes
> **Nothing over the supply rail reaches an analogue input.** Check the
> maximum input voltage in your board's datasheet before you connect
> anything, and if your source can exceed it, build a divider and
> verify the divided output with a meter first. **Set the bench
> supply's current limit before connecting**, as always. **Scope
> ground clip to circuit ground only**, and share a single ground
> between the signal source, the board, and the scope — two grounds at
> different potentials are exactly how a signal gets an offset nobody
> can explain. **Rewire with power off.** This bench is low-voltage
> throughout, which makes it a good place to practise habits that
> matter more elsewhere.

## What you need

- [ ] Microcontroller board with an analogue input, and its datasheet
      open at the converter section
- [ ] A signal source: a function generator, or a second board making
      a square wave through an RC network
- [ ] Resistors: $1.5\ \text{k}\Omega$, plus a pair for a divider
- [ ] A $1\ \mu\text{F}$ capacitor for the anti-alias filter
- [ ] Oscilloscope, multimeter, breadboard, jumper wires
- [ ] Somewhere to plot results — squared paper or a spreadsheet

## Predict before you build

1. **Predict the size of one count.** A converter spreads its counts
   across its reference voltage. For a 12-bit converter on a
   $3.3\ \text{V}$ reference, one count is
   $3.3 / 4096 = 0.806\ \text{mV}$. Work out the same figure for
   10-bit — $3.3 / 1024 = 3.22\ \text{mV}$ — and decide, before you
   measure anything, which resolution your own project needs.
2. **Predict the sampling rate you need.** A sampled system can only
   represent frequencies below half its sampling rate. Write down the
   fastest thing your signal does, double it, and then double it again
   for comfort: that last number is a design decision, and you should
   be able to defend the factor you chose.
3. **Predict the alias.** When a signal at $f$ is sampled at $f_s$ and
   $f$ is above half of $f_s$, what comes back is the difference:
   $f_{alias} = |f - n f_s|$ for whichever whole number $n$ brings the
   result below $f_s / 2$. Predict what a $90\ \text{Hz}$ sine sampled
   at $100\ \text{Hz}$ will look like — $|90 - 100| = 10\ \text{Hz}$ —
   and predict $110\ \text{Hz}$ at the same rate before you try it.
4. **Predict the filter you would need.** For a first-order RC filter,
   $f_c = 1 / (2 \pi R C)$. With $R = 1.5\ \text{k}\Omega$ and
   $C = 1\ \mu\text{F}$ that is about $106\ \text{Hz}$. Say what that
   filter does to a $500\ \text{Hz}$ intruder, and be honest: a
   first-order filter rolls off gently, so "removed" is the wrong word.
5. **Predict your own loop's timing.** Write down how long you think
   one pass of your sampling loop takes, in microseconds, before you
   measure it.

## The work

6. Sample at a known rate and record the raw counts. Keep the loop
   deliberately plain to begin with — the point is to see its faults:

```python
from machine import ADC, Pin
import time

SENSOR_PIN = 26              # your board's pinout is the only authority
SAMPLE_INTERVAL_US = 10000   # 10 ms between samples, so 100 Hz
SAMPLE_COUNT = 200

sensor = ADC(Pin(SENSOR_PIN))
marker = Pin(15, Pin.OUT)    # toggled once per sample, for the scope

readings = []
for sample_number in range(SAMPLE_COUNT):
    marker.toggle()
    readings.append(sensor.read_u16())
    time.sleep_us(SAMPLE_INTERVAL_US)

for reading in readings:
    print(reading)
```

7. **Calibrate first.** Feed the input from a divider with a known,
   measured DC voltage. Record the counts at three different voltages
   and compute volts per count from your own data. Compare with your
   prediction in step 1.
8. **Measure your real sampling rate.** Put the scope on the marker pin
   and measure the interval between toggles. It will not be exactly
   $10\ \text{ms}$, and the difference is the time your loop spends
   doing everything else.
9. **Sweep the signal upward.** Start the source at $5\ \text{Hz}$ and
   step it up past $50\ \text{Hz}$, sampling and plotting at each step.
   Record the frequency your samples appear to show against the
   frequency the generator says.
10. **Cross Nyquist deliberately.** At $90\ \text{Hz}$, then
    $100\ \text{Hz}$, then $110\ \text{Hz}$, plot what your samples
    reconstruct. Keep the scope trace beside the plot: the scope shows
    the truth, your samples show the story.
11. **Fit the anti-alias filter** between the source and the input and
    repeat the three frequencies above. Record what changed and what
    did not.
12. **Make the loop worse on purpose.** Add a print statement inside
    the sampling loop, measure the marker interval again, and record
    both the new average and the worst case.

## Results

| Measurement | Predicted | Measured |
| --- | --- | --- |
| Volts per count, from the reference | 0.000806 | |
| Volts per count, from calibration | | |
| Sampling interval, plain loop (ms) | 10.00 | |
| Worst-case interval, plain loop (ms) | | |
| Apparent frequency of a 90 Hz signal (Hz) | 10 | |
| Apparent frequency of a 100 Hz signal (Hz) | | |
| Apparent frequency of a 110 Hz signal (Hz) | 10 | |
| Amplitude of the 90 Hz alias, filter fitted | | |
| Filter cutoff frequency (Hz) | 106 | |
| Sampling interval with a print in the loop (ms) | | |

## Predicted against measured

Two rows deserve most of your attention.

The calibration row tells you whether your converter's reference is what
you assumed. Many boards use their own supply as the reference, which
means the reference moves when the supply does — and a reading in counts
is meaningless until you know what it is counted against. If your
measured volts-per-count differs from the calculated figure by a percent
or two, that is your supply, not your arithmetic.

The timing rows tell you what your sampling rate really was, and every
alias frequency you measured depends on that number rather than on the
one in your code. Recompute your predicted aliases using the *measured*
interval and see how much of the gap disappears.

For the alias amplitudes with the filter fitted: a first-order filter at
$106\ \text{Hz}$ attenuates a $90\ \text{Hz}$ signal barely at all. If
you expected it to vanish, your model of a filter is a brick wall and
the real one is a slope. Say so in your journal — it is a genuine
finding and it changes how you would design the next one.

## The question that matters

Your samples showed a slow, steady, believable signal that the
oscilloscope proved was not there. Explain to somebody who has not taken
this course how that can happen, using nothing but the idea of taking
snapshots. Then explain why turning the sampling rate up is only half a
fix, and what the other half is.

Then the design-margin questions:

- Your device has to report a temperature that never changes faster
  than once a second. What sampling rate and what anti-alias filter
  would you specify, and what margin did you leave?
- The board is in a cabinet next to a motor drive that switches at
  several kilohertz. What does that do to your input, and what would
  you change in hardware?
- Somebody adds a feature to your firmware and the loop gets slower.
  How would your design make that visible instead of silently wrong?

%%curriculum-start%%
## Curriculum connection

![[A5.5]]

![[A5.6]]

![[B5.2]]
%%curriculum-end%%
