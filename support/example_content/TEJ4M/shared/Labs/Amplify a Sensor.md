---
title: Amplify a Sensor
draft: false
created: __CREATED__
tags:
  - labs
enableToc: true
---
Some sensors shout and some whisper. A temperature sensor that gives you
$10\ \text{mV}$ per degree is whispering: across the whole range you
care about it moves a few hundred millivolts, while your converter is
listening across a range ten times that wide. Most of your resolution is
spent on voltages the sensor will never produce.

Today you build a non-inverting amplifier around an op-amp, choose its
gain from the range you actually need rather than from the largest
number that fits, and then push the gain too far on purpose so you can
see exactly what a rail looks like from the inside.

> [!danger] Safety notes
> **Set the bench supply and its current limit before connecting** —
> $3.3\ \text{V}$ or $5\ \text{V}$ as your op-amp and board require,
> current limit around $100\ \text{mA}$. **Check the op-amp's supply
> pins against its datasheet before power**, every time: pin one is not
> a standard, and a reversed supply destroys the part instantly and
> sometimes loudly. **Rewire only with the supply off.** **Never
> connect the sensor's output straight to a supply rail** while
> hunting for a wiring fault. **Scope ground clip to circuit ground
> only** — the clip is earth-referenced through the instrument.
> **Watch what your amplifier feeds**: an output that swings above your
> microcontroller's supply voltage can damage an analogue input pin, so
> check the maximum gain against the rail before you connect the board.

## What you need

- [ ] An analogue temperature sensor with a stated output slope, and
      its datasheet
- [ ] A single-supply op-amp whose output swings close to both rails,
      and its datasheet
- [ ] Resistors: $10\ \text{k}\Omega$ and $33\ \text{k}\Omega$ for the
      gain network, $1\ \text{k}\Omega$ for the filter, all measured
      before use
- [ ] A $10\ \mu\text{F}$ capacitor for the filter
- [ ] Breadboard, jumper wires, bench supply, multimeter, oscilloscope
- [ ] Microcontroller board for the final reading, and your journal

## Predict before you build

1. **Predict the signal you actually have.** If the sensor gives
   $10\ \text{mV}/^\circ\text{C}$ and you care about $15$ to
   $60\ ^\circ\text{C}$, its output moves from $150\ \text{mV}$ to
   $600\ \text{mV}$ — a swing of $450\ \text{mV}$ inside a
   $3.3\ \text{V}$ window. Write down what fraction of your converter's
   range that is.
2. **Predict the resolution you are throwing away.** A 12-bit converter
   on a $3.3\ \text{V}$ reference resolves
   $3.3 / 4096 = 0.806\ \text{mV}$ per count, so unamplified, one
   degree is about $12$ counts. Compute what that becomes with a gain
   of $4.3$.
3. **Choose the gain from the ceiling, not from ambition.** A
   non-inverting amplifier has gain $G = 1 + R_f / R_g$. With
   $R_f = 33\ \text{k}\Omega$ and $R_g = 10\ \text{k}\Omega$,
   $G = 1 + 3.3 = 4.3$. At $60\ ^\circ\text{C}$ the output is
   $0.600 \times 4.3 = 2.58\ \text{V}$, still below a $3.3\ \text{V}$
   rail with headroom to spare. Compute the temperature at which this
   amplifier runs out of room: $3.3 / (4.3 \times 0.010) \approx
   77\ ^\circ\text{C}$.
4. **Predict the filter.** A first-order RC low-pass has
   $f_c = 1 / (2 \pi R C)$. With $R = 1\ \text{k}\Omega$ and
   $C = 10\ \mu\text{F}$ that is
   $1 / (2\pi \times 1000 \times 0.00001) \approx 15.9\ \text{Hz}$.
   Predict, in writing, what that does to a temperature reading and
   what it would do to a signal you actually wanted to see move fast.
5. **Predict what "too much gain" looks like.** If you swapped $R_f$
   for $330\ \text{k}\Omega$, $G$ becomes $34$ and the sensor reaches
   the rail at about $10\ ^\circ\text{C}$. Draw the shape of the output
   against temperature before you build it.

## The work

6. Wire the sensor per its datasheet and measure its raw output with
   the meter. Warm it gently — a fingertip on the package is enough,
   not a heat gun — and record the output every $10\ \text{s}$ as it
   rises, then as it falls.
7. Build the non-inverting amplifier: sensor output to the
   non-inverting input, $R_g$ from the inverting input to ground, $R_f$
   from the output back to the inverting input. Check the supply pins
   against the datasheet, then power up.
8. Measure the output at room temperature and compute the gain you
   actually got from the two voltages you measured. Compare it against
   the gain your two measured resistor values predict.
9. Repeat the warming run and record both the sensor output and the
   amplifier output at each step, so you have pairs.
10. **Look at the noise.** Put the scope on the amplifier output, AC
    coupled, at high sensitivity. Record the peak-to-peak noise and
    note whether it looks like mains-frequency pickup, switching hash,
    or something random.
11. Fit the RC filter at the output and measure the noise again with
    exactly the same scope settings. Record both numbers.
12. Feed the filtered output to the board's analogue input and read raw
    converter counts. Take ten readings without touching anything and
    record the spread.
13. **Push it over.** Replace $R_f$ with $330\ \text{k}\Omega$, warm
    the sensor, and watch the output flatten. Capture the trace at the
    moment it stops responding and measure the voltage it stopped at.

## Results

| Measurement | Predicted | Measured |
| --- | --- | --- |
| Sensor output at room temperature (mV) | | |
| Sensor swing over the range tested (mV) | | |
| Amplifier gain, from resistor values | 4.3 | |
| Amplifier gain, from measured voltages | | |
| Output at the warmest reading (V) | | |
| Noise before the filter, peak-to-peak (mV) | | |
| Noise after the filter, peak-to-peak (mV) | | |
| Filter cutoff frequency (Hz) | 15.9 | |
| Spread in ten converter readings (counts) | | |
| Output voltage where clipping began (V) | | |

## Predicted against measured

The gain you compute from measured voltages will not match the gain you
compute from resistor values exactly, and both should be close to $4.3$.
Work out which resistor tolerance would account for the difference, and
check it against what you measured — a gain set by a ratio is only as
good as the two parts making the ratio, which is why matched tolerance
matters more here than absolute value.

The clipping voltage in the last row is the honest one. Your op-amp did
not reach the rail, and its datasheet will tell you how close it was
supposed to get, at what load, on what supply. If yours stopped a whole
volt short, you are probably using an op-amp that was never intended for
single-supply work near ground — that is a component-selection finding,
and it belongs in your journal in exactly those words.

Then reconcile the noise rows. If the filter reduced the noise by less
than you expected, ask what frequency the remaining noise is at: the
filter can only remove what is above its cutoff, and a slow drift is not
noise at all — it is your fingertip.

## The question that matters

You increased the gain and every count of your converter now covers a
smaller temperature change. Explain to somebody why that did **not**
make the measurement more accurate, and what it did do. Use the words
resolution, noise, and accuracy, and be precise about which is which.

Then the design-margin questions:

- Your amplifier saturates at about $77\ ^\circ\text{C}$. The device
  ships to somebody whose attic reaches $50\ ^\circ\text{C}$ in August.
  Is that margin enough, and what gain would you choose instead?
- Somebody connects the sensor's output and ground the wrong way round.
  What does your circuit do, and what would you add so that it survives?
- The gain resistors drift with temperature, and the whole circuit is
  in the same hot box as the sensor. Look up their temperature
  coefficient and estimate the error that adds at
  $50\ ^\circ\text{C}$ — then decide whether it matters.

The reasoning behind those choices lives in
[[Component Selection and Tolerances]], and the arithmetic gets drilled
in [[Transistor and Op-Amp Practice]].

%%curriculum-start%%
## Curriculum connection

![[A3.2]]

![[A3.3]]

![[B3.4]]
%%curriculum-end%%
