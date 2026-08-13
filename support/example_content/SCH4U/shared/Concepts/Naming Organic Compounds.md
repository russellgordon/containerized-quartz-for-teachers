---
title: Naming Organic Compounds
draft: false
created: __CREATED__
enableToc: true
tags:
  - concepts
  - organic
---
[[Isomers]] left you with a problem rather than a fact. Nine different
substances share the formula $\text{C}_7\text{H}_{16}$, and if you
cannot tell somebody which one you mean, you cannot order it, publish
it, or repeat what you did with it. In class you tried describing a
structure out loud to a partner who could not see it, and watched them
build the wrong thing.

Names in organic chemistry are not labels handed down by tradition. They
are **instructions for rebuilding the molecule**, and the rules exist so
that two chemists starting from the same name always draw the same
structure.

## The system has one job

The International Union of Pure and Applied Chemistry maintains the
naming rules, and every part of a systematic name is doing work:

$$\underbrace{\text{2-methyl}}_{\text{substituent}}\underbrace{\text{but}}_{\text{root}}\underbrace{\text{an}}_{\text{bonds}}\underbrace{\text{-2-ol}}_{\text{group and position}}$$

- **Root** — how many carbons in the main chain.
- **Suffix for the bonds** — `an` for all single, `en` for a double,
  `yn` for a triple. A **saturated** hydrocarbon has only single bonds
  and carries as much hydrogen as it can; an **unsaturated** one has at
  least one multiple bond and carries less.
- **Suffix for the functional group** — what class of compound it is.
- **Prefixes with numbers** — everything else hanging off the chain, and
  exactly where.

The roots are the part to memorise, and there are only ten:

| Carbons | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Root | meth | eth | prop | but | pent | hex | hept | oct | non | dec |

## Five steps, in this order

The order matters. Doing step 3 before step 2 produces a name that is
wrong in a way that looks right.

- [ ] **1. Find the principal functional group.** Not the biggest group
      — the highest priority one. That group decides the suffix and it
      decides which chain counts as the main chain.
- [ ] **2. Find the longest continuous carbon chain that contains it.**
      Longest, and continuous, and containing the principal group. The
      chain does not have to be drawn in a straight line, and it very
      often is not — go around corners.
- [ ] **3. Number the chain from the end that gives the principal group
      the lowest number.** If there is no principal group, number to
      give the lowest set of numbers to the substituents.
- [ ] **4. Name every substituent and give it the number of the carbon
      it is attached to.** Use `di`, `tri`, `tetra` for repeats, and a
      number for each one even when they repeat.
- [ ] **5. Assemble it: substituents in alphabetical order, then root,
      then suffix.** Alphabetise by the substituent name itself —
      `di` and `tri` do not count for alphabetical order, so
      *ethyl* comes before *dimethyl*.

The priority order for step 1, highest first, is the one thing here you
cannot derive:

$$\text{carboxylic acid} > \text{ester} > \text{amide} > \text{aldehyde} > \text{ketone} > \text{alcohol} > \text{amine}$$

Multiple bonds sit below all of those and become part of the root
suffix rather than competing for it. A molecule containing both an
$-\text{OH}$ and a $\text{C=O}$ acid group is named as an **acid** with
a `hydroxy` prefix, never as an alcohol. The full list of groups, with
both their suffix and their prefix forms, is on
[[Functional Groups at a Glance]].

## Punctuation carries meaning

This is where marks are lost, and the rules are short enough to learn
once.

- A **hyphen** goes between a number and a letter: `2-methyl`.
- A **comma** goes between two numbers: `2,3-dimethyl`.
- Nothing at all goes between a prefix and the root:
  `2,3-dimethylpentane` is one word.
- The locant for a functional group goes **immediately before its
  suffix** in current practice — `propan-2-ol`. You will also see
  `2-propanol`, an older style still used in North American textbooks
  and on many bottles. Both are understood; be consistent within a
  piece of work.
- A number is omitted only when it cannot be ambiguous. There is one
  propanal and only one, so it is not `propan-1-al`.

> [!warning] The longest chain is rarely the one you drew
> The most common naming error in this course is taking the chain that
> runs left to right across the page because that is how the structure
> was printed. Turn the corner. A structure drawn as a five-carbon row
> with a two-carbon branch may well contain a six-carbon chain running
> diagonally, and if it does, the six-carbon chain is the name.
>
> Check by counting the carbons in your chosen chain and then counting
> the carbons in the whole molecule. If the leftover count does not
> match the branches you have named, you have picked the wrong chain.

## Where the old names survive

Systematic naming did not abolish the common names, and pretending
otherwise will leave you unable to read a label.

| Common name | Systematic name |
| --- | --- |
| acetic acid | ethanoic acid |
| acetone | propanone |
| formaldehyde | methanal |
| isopropyl alcohol | propan-2-ol |
| toluene | methylbenzene |

Benzene itself keeps its name entirely — nobody attempts a systematic
one — and when a benzene ring hangs off something else as a substituent
it is called a **phenyl** group. Positions around the ring are numbered
$1,2$, $1,3$, and $1,4$, though the older *ortho*, *meta*, and *para*
are still in constant use.

Use the common name when you are talking, the systematic name when you
are writing something that has to be unambiguous, and expect a data
booklet to use whichever it feels like. Drill the whole procedure in
[[Organic Naming Practice]] — naming is a skill that only becomes
automatic by repetition, and it needs to be automatic before
[[Organic Reactions]], where you will be naming products you have
never seen.

%%curriculum-start%%
## Curriculum connection

![[B2.2]]

![[B2.1]]
%%curriculum-end%%
