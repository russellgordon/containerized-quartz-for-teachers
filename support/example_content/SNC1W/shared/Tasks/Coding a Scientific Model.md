---
created: __CREATED__
createdSection1: 2026-09-08T08:00:00.000-0400
draftSection1: false
createdSection2: 2026-09-08T08:00:00.000-0400
draftSection2: false
enableToc: true
tags:
  - skills
  - assessment
---
> [!abstract] At a glance
> **Curriculum:** [[A1.4]] · **Language:** Python (or another, if you ask first)

## The task

Write a program that models a scientific relationship you have studied, and use
it to answer a question you could not easily answer by hand.

## Starting point

```python
# Model the energy remaining at each trophic level.

def energy_at_levels(starting_energy, transfer_rate, levels):
    # Return the energy available at each trophic level.
    remaining = starting_energy
    results = []
    for level in range(levels):
        results.append(remaining)
        remaining = remaining * transfer_rate
    return results


amounts = energy_at_levels(10000, 0.10, 5)
for index in range(len(amounts)):
    print("Level", index + 1, ":", round(amounts[index], 2), "kJ")
```

## Choose one

| Model | The question it answers |
| --- | --- |
| Energy pyramid | How many trophic levels can an ecosystem support? |
| Ohm's law calculator | What resistance is needed for a given current? |
| Radioactive decay | How much remains after $n$ half-lives? |
| Orbital periods | How does period change with distance? |
| Population growth | What happens when a limit is introduced? |

## Requirements

- [ ] At least one **loop** and one **function**
- [ ] Inputs the user can change without editing the code
- [ ] Output that is readable — labels and units, not bare numbers
- [ ] Comments explaining the **science**, not the syntax
- [ ] A run with at least three different inputs, results recorded

## The written part

1. What relationship does your model represent? Give the equation.
2. What did you learn by changing the inputs that you would not have seen
   otherwise?
3. Where does your model stop being realistic? Every model has a limit — find
   yours and state it.

> [!tip] Do not confuse a calculator with a model
> Computing one answer is arithmetic. A model lets you ask "what if?" repeatedly
> and see a *pattern* in the answers. Aim for the second.
