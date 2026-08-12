---
title: Using an Oscilloscope
draft: false
created: __CREATED__
tags:
  - tutorials
enableToc: true
---
A multimeter answers "how much?" An oscilloscope answers "how much,
and when?" It draws voltage against time, which is the only way to see
the things that make circuits interesting and circuits fail: a pulse
that is too narrow, a supply rail with ripple on it, a button that
bounces six times before it settles, a signal that looks perfect until
the motor starts.

One thing to know before you touch it: a scope measures **voltage with
respect to ground**, over time. It does not measure current, and it
does not measure between two arbitrary floating points. Everything it
shows you is "this node, compared to ground".

## The three controls that matter

Everything else on the front panel is convenience. These three decide
whether you see anything at all.

| Control | What it sets | How you know it is wrong |
| --- | --- | --- |
| Volts per division | The vertical scale | The trace is a flat line, or it runs off the top and bottom |
| Time per division | The horizontal scale | You see a solid band, or one motionless slope |
| Trigger | When each sweep starts | The waveform slides sideways and will not sit still |

The trigger is the one that confuses people, and it is worth one clear
sentence: the scope needs to be told which event to line each sweep up
with, so that a repeating signal is drawn on top of itself in the same
place every time. Edge triggering wants a level and a direction —
"start when the voltage crosses 1.5 V going up". Set the level
somewhere the signal actually passes through, and the picture stops
sliding.

Coupling is worth a sentence too. **DC coupling** shows the signal as
it really is, offset and all. **AC coupling** removes the steady part
so you can turn up the vertical gain and look at a small ripple riding
on top of a large rail — the standard way to find out whether a supply
is as clean as it claims.

## The probe is part of the instrument

A scope probe is not a wire, and treating it like one produces
measurements that are wrong in ways that look plausible.

- Most probes have a switch marked ×1 and ×10. In the ×10 position
  the probe divides the signal by ten and loads your circuit much
  less, which is what you want almost always. The scope has to be
  told which setting you used, or every voltage it reports will be
  out by a factor of ten.
- Probes need **compensating** to the scope they are plugged into.
  Every bench scope has a small terminal putting out a square wave for
  exactly this purpose. Clip the probe to it and adjust the trimmer on
  the probe body until the square wave's corners are square — not
  rounded, not overshooting. An uncompensated probe distorts every
  edge you look at afterwards.
- The ground lead is short for a reason. A long ground lead adds
  inductance and puts ringing on fast edges that the circuit does not
  actually have.

> [!danger] Where the ground clip may go, and where it may not
> On a normal bench scope, the probe's ground clip is connected —
> through the instrument and its power cord — to the building's
> earth. Clipping it to any point in a circuit that is not at ground
> potential creates a short from that point to earth, through your
> probe. On our current-limited bench supplies that is an
> embarrassing bang and a lost afternoon. On anything mains-referenced
> it is genuinely dangerous, which is one of several reasons nobody in
> this course puts a scope on a mains-powered circuit. The clip goes
> to circuit ground. Only to circuit ground. Ask first if you cannot
> find one.

## Reading a number off the screen

The screen is a grid, and the grid is the measurement. Count divisions
and multiply by the setting.

Suppose one complete cycle of a square wave spans five divisions with
the timebase set to 0.5 ms per division. The period is
$T = 5 \times 0.5\ \text{ms} = 2.5\ \text{ms}$, and frequency is the
reciprocal of period:

$$f = \frac{1}{T} = \frac{1}{2.5 \times 10^{-3}\ \text{s}} = 400\ \text{Hz}$$

Amplitude works the same way vertically: three divisions at 2 V per
division is a 6 V peak-to-peak signal, and if you were using a ×10
probe, check that the scope knew it.

Modern scopes will compute all of this for you with a measurement
menu, and you should use it — after you have counted the divisions
yourself at least a dozen times. An automatic measurement of a badly
triggered signal is a confident wrong answer, and only the person who
can read the grid will notice.

## When the screen is blank

Work through it in this order, because it goes from most likely to
least.

1. Is the channel switched on, and is the probe in that channel?
2. Is the vertical scale so sensitive that the trace is off-screen,
   or so coarse that a 3 V signal is a flat line? Try autoset, then
   fix what autoset chose badly.
3. Is the trigger level set somewhere the signal never reaches?
4. Is the ground clip actually connected to circuit ground?
5. Is the circuit powered, and is the node you clipped to the node
   you meant?

That list is the same discipline as [[Getting Unstuck]], applied to an
instrument instead of a circuit: change one thing, then look. Every
waveform you settle on belongs in your [[Tech Journal]] as a sketch
with both scale settings written beside it — a trace with no
volts-per-division and no time-per-division is a drawing, not a
measurement.
