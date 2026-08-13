---
title: Periodic Trends
draft: false
created: __CREATED__
enableToc: true
tags:
  - concepts
  - matter-and-bonding
---
The graph you drew in [[Sorting the Elements]] — atomic radius against
atomic number — has a shape nobody warned you about. It does not climb
steadily and it does not scatter. It saws: a long fall, a jump back up,
another long fall. That sawtooth is the periodic law showing up in a
measurement, and this page explains what produces it.

The honest version of this topic is not four arrows on a diagram. It is
two causes, four consequences, and a handful of places where the four
consequences are genuinely broken. The breaks are worth more than the
trends, because they are the evidence that the explanation is about
electrons rather than about arrows.

## Two causes do nearly all the work

**Effective nuclear charge** ($Z_\text{eff}$) is the pull the outermost
electron actually feels. It is not the full nuclear charge, because the
electrons in between get in the way.

**Shielding** is that getting-in-the-way. Inner electrons are negative,
they sit between the nucleus and the outer electrons, and they cancel
part of the attraction. A rough and useful approximation:

$$Z_\text{eff} \approx Z - (\text{number of inner electrons})$$

Now run that across a row. Sodium to chlorine, every step adds one
proton *and* one electron — but the added electron goes into the **same
principal shell**, at roughly the same distance out, so it shields the
others hardly at all. The nuclear charge climbs by seven across the row
and the shielding barely moves. $Z_\text{eff}$ rises steeply.

Now run it down a column. Lithium to caesium, each step starts a new
principal shell, further from the nucleus, with a whole additional layer
of inner electrons beneath it. Distance goes up and shielding goes up
together. The outer electron is held much more loosely, even though the
nucleus has far more protons in it.

Every trend below is one of those two paragraphs applied to a different
measurement.

## The four trends

| Trend | Across a period, left to right | Down a group |
| --- | --- | --- |
| Atomic radius | decreases | increases |
| Ionization energy | increases | decreases |
| Electron affinity | more energy released | less energy released |
| Electronegativity | increases | decreases |

Each of those needs its definition stated properly, because three of the
four are routinely used to mean something they do not.

**Atomic radius** is half the distance between the nuclei of two bonded
identical atoms. It shrinks across a period because a rising
$Z_\text{eff}$ pulls the same shell in tighter — you are adding
electrons but the shell contracts faster than they fill it. It grows
down a group because you have started a new shell further out. Note that
the second effect is much larger than the first: caesium is enormously
bigger than lithium, while chlorine is only somewhat smaller than
sodium.

**Ionization energy** is the energy needed to remove the most loosely
held electron from a neutral atom *in the gas phase*. High
$Z_\text{eff}$ and a small radius both make it harder to pull an
electron off, so it climbs across and falls down. This is the trend that
explains why the metals are on the left: a caesium atom gives up an
electron for very little.

**Electron affinity** is the energy change when a gaseous atom gains an
electron. Usually energy is released, so the value is usually negative,
though many textbooks quote it as "energy released" and print it
positive — check which convention your data table is using before you
compare two numbers. Broadly, an atom one electron short of a full shell
releases the most, which is why the halogens sit at the extreme.

**Electronegativity** is the tendency of an atom **in a bond** to pull
the shared electrons towards itself. That phrase is the important part:
unlike the other three, this is not a property you can measure on a lone
atom. It is inferred from bonds, on a comparative scale that Linus
Pauling set up with fluorine at the top, near 4.0. It is the number you
will use in [[Ionic and Covalent Bonding]] to predict what kind of bond
two elements will form.

## The exceptions are the interesting part

Draw the ionization energies of the first twenty elements and the row is
not a clean ramp. There are two dips per period, in the same places
every time, and they are not experimental error.

- **Group 2 to group 13** — beryllium to boron, magnesium to aluminium.
  Ionization energy *falls*. The electron being removed from boron is
  the first one in a p subshell, which is higher in energy than the
  filled s subshell below it and is shielded by it. It is easier to
  remove than the s electron was, despite the extra proton.
- **Group 15 to group 16** — nitrogen to oxygen, phosphorus to sulfur.
  Ionization energy *falls* again. Nitrogen's three p electrons sit one
  to an orbital. Oxygen's fourth has to pair up with one of them, and
  two electrons crowded into the same orbital repel each other, so one
  of them leaves more readily.

Electron affinity has a famous break too. Fluorine ought to be the
champion, and it is not — **chlorine releases more energy on gaining an
electron than fluorine does**. Fluorine's valence shell is so small that
the incoming electron is pushed into a crowded space and the
electron–electron repulsion cancels part of the gain. The same logic
makes oxygen's electron affinity smaller than sulfur's.

Two more places the arrows lie:

- **Groups 2 and 18 do not really have electron affinities.** A
  magnesium or a neon atom has a filled subshell; adding an electron
  requires energy rather than releasing it, and the resulting ion is not
  stable. A trend line drawn straight through those points is drawing
  through data that does not exist.
- **Across the transition metals, atomic radius barely changes.** The
  electrons being added go into an inner d subshell, where they shield
  the outer electrons quite effectively, so $Z_\text{eff}$ creeps
  instead of climbing. Iron, cobalt, and nickel are nearly the same
  size, which is exactly why they alloy so readily.

> [!question] Is a trend with exceptions still a trend?
> Yes — and knowing where it breaks is what separates using a model from
> reciting one. The dips are not noise sitting on top of the pattern;
> they are the *same* explanation, applied one level finer. Subshells
> and orbital pairing were invented to account for measurements like
> these. A student who says "ionization energy increases across a
> period" has learned the rule. A student who can say "except from
> beryllium to boron, because the electron leaving boron is a shielded p
> electron" has learned the reason, and the reason is the part that
> transfers.

## Reading the trends together

The four trends are not independent — they are four views of the same
thing, how tightly an atom holds electrons.

That single idea sorts the whole table. Elements on the **left** hold
their outer electrons weakly: low ionization energy, low
electronegativity, large radius. They lose electrons and become
**cations**, which are always smaller than the atom they came from,
because the outer shell has gone entirely. Elements on the **right**
hold electrons tightly and pull hard on anyone else's: they gain
electrons and become **anions**, which are always larger than the parent
atom, because the added electron increases repulsion within an unchanged
nuclear charge.

Put a left-hand element next to a right-hand element and the electron
goes one way and stays there. Put two right-hand elements together and
neither can win outright. That is the whole of
[[Ionic and Covalent Bonding]] in two sentences, and it is where this
goes next — after you have practised pulling trend data off a printed
table in [[Reading a Data Table]].

%%curriculum-start%%
## Curriculum connection

![[B2.2]]
%%curriculum-end%%
