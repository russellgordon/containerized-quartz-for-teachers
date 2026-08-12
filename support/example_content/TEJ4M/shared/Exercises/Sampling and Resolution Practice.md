---
title: Sampling and Resolution Practice
draft: false
created: __CREATED__
tags:
  - exercises
---
These follow [[Sampling and Resolution]] and [[Filters and Noise]], and
they decide whether the capture you take in [[Sample a Signal]] means
anything. Two separate promises are being tested here — how finely you
can tell values apart, and how often you look — and mixing them up is the
fastest way to a confident wrong answer.

## Resolution

1. A 10-bit converter uses a 3.3 V reference. Calculate the size of one
   least significant bit and the maximum quantization error.
2. Repeat for a 12-bit converter on the same reference. How many bits
   are needed for one count to be worth 1 mV or less?
3. A sensor produces 10 mV per degree Celsius and feeds the 10-bit
   converter of question 1 directly. Calculate the temperature
   resolution in degrees per count. A requirement asks for 0.1 °C —
   calculate the minimum gain that meets it, choose a gain of 4, and
   state both the new resolution and the temperature range you can still
   measure.
4. Averaging 16 samples is proposed instead of amplifying. By what
   factor does it reduce random noise, roughly how many extra bits is
   that worth, what does it cost, and what does it *not* fix?

## Sampling, aliasing, and storage

5. A signal contains components up to 400 Hz. State the minimum
   theoretical sampling rate, and say why sampling at exactly that rate
   is a bad idea in practice.
6. A board samples at 1000 Hz. Calculate the frequency you would see
   from an input at 1300 Hz, at 900 Hz, and at 2400 Hz.
7. Design the anti-alias filter for the 1000 Hz sampling rate above.
   Choose a cutoff, take $C = 100\ \text{nF}$, calculate $R$, fit a
   standard value, and state the cutoff you actually built.
8. A capture stores 16-bit samples at 5 kHz for 2 s. Calculate the
   memory required, and give two ways to fit it into 8 kB of free
   memory, with the cost of each.
9. One converter capable of 100 000 samples per second is shared
   round-robin between four channels. Calculate the rate per channel and
   the highest signal frequency that can honestly be measured.
10. **Find the error.** A group's report says: "Our readings were noisy
    and some of them were at frequencies the sensor cannot produce, so we
    averaged 32 samples in software. The noise went away and the data is
    now clean." What is right, what is wrong, and what should they have
    done?

## Answers

> [!success]- Answer 1
> $\text{LSB} = \frac{V_{\text{ref}}}{2^n} = \frac{3.3\ \text{V}}{2^{10}} = \frac{3.3\ \text{V}}{1024} \approx 3.223\ \text{mV}$
>
> Everything inside one step reads as the same number, so the maximum quantization error is half a step: $\pm 1.61\ \text{mV}$.
>
> Say "resolution", not "accuracy". This is the smallest change the converter can distinguish, and it says nothing about whether the reading is correct.

> [!success]- Answer 2
> $\text{LSB} = \frac{3.3\ \text{V}}{4096} \approx 0.806\ \text{mV}$, so the maximum quantization error is about $\pm 0.40\ \text{mV}$. Two extra bits gives four times as many steps.
>
> For 1 mV or better you need $2^n \geq \frac{3.3\ \text{V}}{0.001\ \text{V}} = 3300$ steps. Eleven bits gives 2048 steps, or 1.61 mV per count — not enough. Twelve bits gives 4096 steps, or 0.806 mV per count. **Twelve bits.**

> [!success]- Answer 3
> $\frac{3.223\ \text{mV per count}}{10\ \text{mV}/^\circ\text{C}} \approx 0.322\ ^\circ\text{C per count}$ — more than three times coarser than the requirement, so the requirement fails before a line of code is written.
>
> **Minimum gain:** $\frac{0.322}{0.1} \approx 3.22$, so any gain above about 3.3 meets it.
>
> **With a gain of 4:** resolution becomes $\frac{0.322}{4} \approx 0.081\ ^\circ\text{C per count}$ — a pass.
>
> **The cost:** the amplifier's output must still fit in 3.3 V, so the sensor input range shrinks to $\frac{3.3\ \text{V}}{4} = 0.825\ \text{V}$, which at 10 mV/°C is a span of **82.5 °C**. If the requirement had asked for 0 – 100 °C *and* 0.1 °C resolution, a gain of 4 cannot deliver both and the honest answer is a 12-bit converter.
>
> That trade — resolution against range — is worth stating explicitly in your specification, because it is the reason converters get chosen rather than inherited.

> [!success]- Answer 4
> Averaging $N$ samples reduces *random, uncorrelated* noise by $\sqrt{N}$, so 16 samples gives $\sqrt{16} = 4$ times less noise. Since each bit is a factor of 2, a factor of 4 is worth about **2 extra bits** of effective resolution.
>
> **What it costs:** 16 sample times per reading, so the measurement is 16 times slower — which lowers the rate at which you can follow a changing signal, and may collide with your control loop's period.
>
> **What it does not fix:** anything systematic. A constant offset averages to exactly that offset; a reference voltage that is 2% high stays 2% high; and an aliased frequency is a perfectly good signal as far as the average is concerned. Averaging also needs a little noise present to work at all — with a signal that never crosses a code boundary, all 16 samples are identical and you have averaged nothing.

> [!success]- Answer 5
> The Nyquist criterion requires sampling at **more than twice** the highest frequency present, so above **800 Hz**.
>
> Sampling at exactly 800 Hz is a bad idea for two reasons. Mathematically, samples can land at the same point on every cycle — at the zero crossings, for instance — and record a flat line where a full-amplitude signal exists. Practically, no filter cuts off instantly, so real content just above 400 Hz would still arrive and alias.
>
> Real designs sample several times higher — commonly 4 to 10 times the highest frequency of interest — precisely to leave room for a real filter to roll off.

> [!success]- Answer 6
> An aliased frequency appears at $|f - n f_s|$, using whichever multiple of the sampling rate lies nearest.
>
> **1300 Hz:** $|1300 - 1000| = 300\ \text{Hz}$.
>
> **900 Hz:** $|900 - 1000| = 100\ \text{Hz}$. Note that this one is *below* the sampling rate and still aliases — the limit is half the sampling rate, 500 Hz, not the sampling rate itself.
>
> **2400 Hz:** the nearest multiple is $2 \times 1000 = 2000$, giving $|2400 - 2000| = 400\ \text{Hz}$.
>
> All three come back inside the 0 – 500 Hz band, indistinguishable from genuine signals at those frequencies. That is the whole danger: the data looks perfectly reasonable.

> [!success]- Answer 7
> Half the sampling rate is 500 Hz, so the filter must be well down before then. Choosing a cutoff of 200 Hz leaves the filter a factor of 2.5 to work in — modest for a single-pole RC, and worth saying so.
>
> $R = \frac{1}{2\pi f_c C} = \frac{1}{2\pi \times 200\ \text{Hz} \times 100 \times 10^{-9}\ \text{F}} \approx 7958\ \Omega$
>
> Fit **8.2 kΩ**, and the cutoff you actually built is
>
> $f_c = \frac{1}{2\pi \times 8200\ \Omega \times 100\ \text{nF}} \approx 194\ \text{Hz}$
>
> Be honest about how much this buys. One pole falls at about 20 dB per decade, so at 500 Hz — only 2.6 times the cutoff — the attenuation is roughly 9 dB, a factor of about 2.8. Content just above Nyquist is reduced, not removed. If the application cannot tolerate that, the answers are a steeper filter (more poles) or a much higher sampling rate, and both cost something you should name.

> [!success]- Answer 8
> $2\ \text{bytes} \times 5000\ \text{samples/s} \times 2\ \text{s} = 20\,000\ \text{bytes}$, which is about 20 kB — two and a half times the 8 kB available.
>
> **Option 1 — store 8-bit samples.** Halves it to 10 000 bytes. *Cost:* still over 8 kB, and you have thrown away resolution: 8 bits on a 3.3 V reference is $\frac{3.3}{256} \approx 12.9\ \text{mV}$ per count.
>
> **Option 2 — sample for 1 s instead of 2**, or at 2 kHz instead of 5 kHz. Sampling at 2 kHz for 2 s gives $2 \times 2000 \times 2 = 8000$ bytes, which just fits. *Cost:* the Nyquist limit falls to 1 kHz, so this is only legitimate if the signal genuinely has nothing above it — and the anti-alias filter must be redesigned to match.
>
> **Option 3 — stream the data out as it arrives** over a serial link rather than storing it. *Cost:* the link must keep up: 16-bit samples at 5 kHz is 10 000 bytes per second, which at 115200 baud (11 520 bytes/s in 8N1) is possible but leaves almost no margin — see [[Bus and Protocol Practice]].
>
> Decide before the capture. Finding out afterwards that the buffer overflowed means the data you needed is the data you lost.

> [!success]- Answer 9
> $\frac{100\,000\ \text{samples/s}}{4\ \text{channels}} = 25\,000\ \text{samples/s per channel}$.
>
> Nyquist puts the theoretical limit at $\frac{25\,000}{2} = 12\,500\ \text{Hz}$ per channel — and the honest working figure is lower, because a real anti-alias filter needs room to roll off below that. Quoting 12.5 kHz as an achievable bandwidth is exactly the over-claim question 5 warns about.
>
> Note also that the four channels are not sampled at the same instant. If you are comparing two signals in time — phase, or which event happened first — the skew between channels is a real measurement error you must account for.

> [!success]- Answer 10
> **What is right:** averaging is a genuine and useful technique for random noise, and 32 samples would reduce it by $\sqrt{32} \approx 5.7$ times, worth about 2.5 bits.
>
> **What is wrong:** the report contains its own evidence of aliasing — "frequencies the sensor cannot produce" is the signature. Averaging is a low-pass filter applied *after* the converter, and by then the aliased content has already been folded down to a low frequency, where it looks exactly like a real signal. It will survive the average untouched. The data is not clean; it is smooth, which is a different thing and far more dangerous, because it now looks trustworthy.
>
> "The noise went away" is also a claim with no measurement behind it. Compare against what?
>
> **What they should have done:**
>
> 1. Look at the raw signal on a scope before digitising anything, and identify what is actually there — the table in [[Filters and Noise]] is the checklist.
> 2. Fit an anti-alias filter *before* the converter, with a cutoff well below half the sampling rate (question 7's design).
> 3. Check the wiring and grounding, since a substantial share of student "noise" is a floating input or a shared return path.
> 4. Raise the sampling rate if the signal genuinely contains high-frequency content that matters.
> 5. *Then* average, if random noise remains — and report the before-and-after with real numbers.
>
> Aliasing is destroyed information. No amount of processing afterwards recovers it, and the only fix is analog, upstream, and in place before the first sample is taken.

Take question 7's filter to [[Sample a Signal]], capture the same tone
with the filter fitted and removed, and put both traces in your
[[Tech Journal]]. Seeing the alias appear and disappear on demand is the
one demonstration that makes this permanent.
