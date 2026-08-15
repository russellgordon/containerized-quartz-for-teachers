---
title: Getting Started with Python
created: __CREATED__
publish: true
enableToc: true
tags:
  - skills
---
You need very little Python for [[Coding a Scientific Model]] — variables,
loops, functions, and printing.

## Variables and arithmetic

```python
voltage = 12.0
resistance = 4.0
current = voltage / resistance
print("Current:", current, "A")
```

## Loops

```python
# Half-life decay: how much remains after each half-life?
amount = 100.0
for half_life in range(1, 6):
    amount = amount / 2
    print("After", half_life, "half-lives:", round(amount, 2), "g")
```

## Functions

```python
def kinetic_energy(mass, speed):
    return 0.5 * mass * speed ** 2

print(kinetic_energy(1200, 25), "J")
```

## Getting input

```python
distance = float(input("Distance in AU: "))
kilometres = distance * 1.5e8
print(distance, "AU is", kilometres, "km")
```

> [!tip] Errors are information, not failure
> `NameError` means you used a name Python has not seen — usually a typo.
> `TypeError` means you mixed text and numbers, often because `input()` returns
> text and you forgot `float()`. Read the last line of the message first.

%%curriculum-start%%
## Curriculum connection

![[A1.4]]
%%curriculum-end%%
