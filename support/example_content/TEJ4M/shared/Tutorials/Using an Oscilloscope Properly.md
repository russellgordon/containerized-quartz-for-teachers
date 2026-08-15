---
title: Using an Oscilloscope Properly
publish: true
created: __CREATED__
tags:
  - tutorials
enableToc: true
---
You can already drive a scope. Volts per division, time per division,
edge trigger, ×10 probe, ground clip on circuit ground — if any of
that is fuzzy, go and re-run a couple of rounds of
[[Read the Waveform]] before you read on, because this page starts
where that knowledge ends.

The Grade 12 problem with an oscilloscope is not getting a trace. It
is that a scope will happily draw you a confident, stable, entirely
wrong picture, and nothing on the screen will tell you. This page is
about the handful of settings and physical facts that decide whether
what you are looking at is the signal or the instrument.

## Bandwidth is a promise about attenuation, not a wall

A scope's bandwidth is the frequency at which a sine wave is displayed
at about 70 % of its true amplitude — the −3 dB point. Nothing dramatic
happens there. Below it, error grows quietly; above it, the scope keeps
drawing, just smaller and slower than reality.

Two consequences you must carry.

**Amplitude at the top of the range is understated.** Measure a signal
near your scope's rated bandwidth and the number on screen is low by a
margin that grows as you approach it. If it matters, use a faster
instrument or state the limitation.

**Edges are the real casualty.** A square wave is not a frequency; it
is a fundamental plus a long tail of harmonics, and the harmonics are
what make the corners square. A scope with just enough bandwidth for
the fundamental will show you a rounded, slow-looking edge that the
circuit does not have. The usual working rule is to want several times
the fundamental frequency in bandwidth before you trust the shape of a
digital edge.

The instrument's own rise time follows from its bandwidth:

$$t_{\text{scope}} \approx \frac{0.35}{\text{bandwidth}}$$

and what you measure is roughly the signal and the scope combined:

$$t_{\text{measured}} \approx \sqrt{t_{\text{signal}}^2 + t_{\text{scope}}^2}$$

On a 100 MHz scope, $t_{\text{scope}}$ is about 3.5 ns. A measured
12 ns edge is really about 11.5 ns — a correction you can ignore. A
measured 5 ns edge is mostly instrument, and the honest write-up says
"faster than this scope can resolve" rather than inventing a figure.

## A digital scope samples, and sampling can lie

Everything on the screen was reconstructed from samples. Three numbers
interact, and scopes trade them against one another without telling
you.

| Setting | What it limits | The failure it produces |
| --- | --- | --- |
| Sample rate | How finely time is resolved | Aliasing — a fast signal drawn as a slow one that does not exist |
| Memory depth | How long a capture can be at a given sample rate | A long capture silently drops the sample rate |
| Bandwidth | What amplitude and edges survive the front end | Understated amplitude, softened edges |

Aliasing is the dangerous one because the result looks perfectly
plausible. A rock-steady, low-frequency wave that has no business
existing in your circuit is the classic signature. The test costs five
seconds: change the timebase. A real signal keeps its frequency as you
sweep the timebase; an alias moves. The theory behind why is in
[[Sampling and Resolution]], and it is exactly the same theory that
governs your microcontroller's analog inputs.

Watch also for the scope's own interpolation. Between samples, the
instrument draws a smooth curve because a smooth curve is usually
right. With only two or three samples per cycle, that curve is a guess
with a nice haircut.

## Acquisition modes change what "the trace" means

Four modes, four different questions. Choosing the wrong one is how
people spend an afternoon looking for a glitch they told the scope to
throw away.

- **Sample** — plain acquisition. Fine by default, and it can miss a
  narrow event between samples.
- **Peak detect** — records the minimum and maximum within each
  interval, so a very narrow spike cannot fall between samples. This
  is the mode for hunting glitches, and it makes noise look worse
  because it is showing you the extremes honestly.
- **Average** — combines many repetitions to suppress random noise.
  It requires a repeating signal and a rock-solid trigger, and it will
  erase any event that happens once. Never hunt an intermittent fault
  in averaging mode.
- **High resolution** — combines adjacent samples to gain vertical
  resolution at the cost of bandwidth. Useful for small, slow signals;
  wrong for fast edges.

## Triggering beyond the edge

Edge triggering answers "show me every time the signal crosses this
level going up". Most Grade 12 faults need a better question.

- **Single-shot.** Arm the scope once and capture the one event. This
  is how you catch a start-up transient, a fault that occurs on power
  up, or a spike that happened while you were looking away. Combine
  it with the pre-trigger buffer and you can see what led up to the
  event as well as the event itself.
- **Pulse width.** Trigger only on a pulse narrower or wider than a
  stated time. This is how you find the runt pulse that is upsetting
  a state machine without wading through millions of good ones.
- **Holdoff.** After a trigger, ignore further triggers for a set
  time. It is what stabilises a repeating burst that would otherwise
  trigger on a different pulse within the burst each sweep.

## The probe is half the measurement

A probe is not a wire. Treat it like one and you will get results that
are wrong in ways that look plausible.

- **Use ×10 almost always.** It divides the signal by ten and — more
  importantly — loads your circuit far less. A typical ×10 probe
  presents on the order of ten picofarads to the node; a ×1 setting is
  usually several times that and has much lower bandwidth. Tell the
  scope which setting you used, or every voltage it reports is out by
  a factor of ten.
- **Compensate the probe to the scope it is plugged into.** Every
  bench scope has a terminal putting out a square wave for exactly
  this. Clip on, adjust the trimmer until the corners are square —
  neither rounded nor overshooting. An uncompensated probe distorts
  every edge you look at for the rest of the day.
- **Kill the ground lead for fast work.** The standard alligator lead
  is 10 to 15 cm of inductance sitting in series with your
  measurement, and it manufactures ringing on fast edges that the
  circuit does not have. If the ringing changes when you change the
  ground connection, the ringing was yours. For fast edges, use the
  short ground spring that came with the probe.
- **Know which input you are on.** Some scopes offer a 50 Ω input as
  well as the usual 1 MΩ. The 50 Ω setting is for high-frequency work
  with matched cabling and has a low voltage limit — connecting a
  power rail to it is an expensive mistake.

## Measuring between two points that are neither of them ground

This is the Grade 12 measurement, and it is where people get hurt.

> [!danger] Never defeat the earth pin to "float the scope"
> The probe's ground clip is joined, through the instrument and its
> power cord, to the building's earth. That is why clipping it to a
> non-ground node shorts that node to earth. The internet's favourite
> fix — an adapter that removes the earth pin from the scope's plug —
> does not float the signal. It floats the entire metal chassis of the
> instrument to whatever potential you clipped to, including every
> exposed connector shell you are about to touch. It is one of the few
> things in this room that can genuinely kill somebody. We do not do
> it, ever, and we do not put a scope on a mains-referenced circuit at
> all.

The legitimate ways to measure across two floating points, in order of
preference:

1. **A differential probe.** Purpose-built, isolated from earth by
   design, with a stated common-mode range and a stated maximum
   voltage. If the lab has one, this is the answer.
2. **Two channels and the maths.** Put channel 1 on the high point,
   channel 2 on the low point, both grounds on circuit ground, and
   display A − B. This works and it is what you will usually do here.
   Its limits are real: both probes must be on the same attenuation
   and reasonably matched, both points must be within the scope's
   input range measured against ground, and the subtraction only
   removes as much common-mode signal as the two channels match each
   other. It provides no isolation whatsoever.
3. **Move the circuit.** Often the cleanest answer is to rearrange
   your build so the thing you want to measure is referenced to
   ground — for example, putting a current-sense resistor in the
   ground leg rather than the high side.

## A rail-ripple measurement done properly

The most common Grade 12 scope task, and the one most often botched.
You want to know how clean a supply rail is under load.

- [ ] Probe at the point that matters — the capacitor terminals or the
      chip's supply pin — not at the far end of a long lead
- [ ] Ground spring, not the alligator lead
- [ ] AC coupling, so the DC level goes away and you can turn up the
      vertical gain to see millivolts
- [ ] Bandwidth limit on (many scopes offer a 20 MHz limit) unless you
      are specifically hunting fast switching spikes — otherwise you
      are mostly measuring noise pickup
- [ ] The load actually running, in the state you care about
- [ ] Both scale settings, the coupling, and the load condition written
      down beside the number

Without that last box the measurement is not reportable. "40 mV of
ripple" means nothing; "40 mV peak-to-peak at the regulator output,
AC coupled, 20 MHz limit on, at 350 mA load" is a measurement somebody
can reproduce or dispute, which is the standard
[[Writing About Technology]] holds you to everywhere.

> [!tip] Automatic measurements are fine — after you can read the grid
> Every modern scope will compute frequency, rise time, and amplitude
> for you, and you should use it. But an automatic measurement of a
> badly triggered, aliased, or clipped signal is a confident wrong
> answer with three decimal places on it, and only the person who can
> count divisions will notice. Read the grid first. Then let the
> instrument do the arithmetic.

%%curriculum-start%%
## Curriculum connection

![[B3.2]]

![[B2.3]]
%%curriculum-end%%
