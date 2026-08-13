---
title: Variables and Data Types
draft: false
created: __CREATED__
tags:
  - concepts
enableToc: true
---
The chair program in [[Your First Python Program]] had the number 12 in
it three times. When Mr. Diaz asked for wider rows, two of the three
got changed, and the printed total quietly disagreed with the room. The
fix is older than Python: give the value a name, put the value in one
place, and let the rest of the program ask for it by name.

```python
chairs_per_row = 14
rows = 8
audience_chairs = rows * chairs_per_row
```

A variable is a name bound to a value. Change the value at the top and
every line that uses the name changes with it — including the lines you
have not written yet.

## Assignment is not equality

`=` does not mean "is equal to". It means *put this value in this
name*, right to left. So this is not nonsense:

```python
total = 0
total = total + 45
```

Read it as: work out `total + 45` using the value `total` has right
now, then store the answer back in `total`. That pattern — the
accumulator — is the engine of half the programs in [[Repetition]]. The
test for equality is `==`, and mixing up the two is a rite of passage;
see [[Boolean Logic]].

## The four types you need first

Every value in Python has a type, and the type decides what the value
can do.

| Type | Looks like | Use it for | Watch out |
| --- | --- | --- | --- |
| `int` | `78`, `0`, `-4` | counting things: marks, days, chairs | `int` division with `/` gives a `float` |
| `float` | `67.4`, `1.0` | measuring things: kilograms, averages | `0.1 + 0.2` is not exactly `0.3` |
| `str` | `"Priya"`, `"14"` | text: names, titles, anything typed | `"14"` is text, not a number |
| `bool` | `True`, `False` | answers to yes/no questions | capital letter, no quotes |

```python
mark = 78
average = 67.4
name = "Priya"
is_overdue = True
```

Nothing declares those types. Python works out the type from the value,
and `type(mark)` will tell you `<class 'int'>` if you ever want to
check. That convenience has a cost, which the next section is about.

## Everything from input() is text

`input()` always hands back a `str`, even when the person typed digits.
This is the single most common surprise in Unit 1:

```python
answer = input("Minutes practised: ")
minutes = int(answer)
```

Without that second line, `answer + 10` fails and Python says exactly
what is wrong:

```
TypeError: can only concatenate str (not "int") to str
```

`int()` and `float()` do the conversion. They also refuse loudly when
the text is not a number — `int("seven")` raises
`ValueError: invalid literal for int() with base 10: 'seven'`, which is
Python being helpful, not hostile. [[Input and Output]] shows how to
catch that instead of crashing, and [[Name That Error]] is five minutes
a day spent making messages like that one readable at a glance.

## Where the value actually lives

The name is not the value. When Python runs `mark = 78`, it stores the
number in RAM and keeps `mark` as a label pointing at it; when it later
computes `mark * 2`, that arithmetic happens in the CPU. Nothing about
this is metaphorical — it is why a program forgets everything the
moment it closes, which is the problem [[Files and Persistence]] exists
to solve.

Underneath, RAM holds nothing but binary, so every type above is a
convention for reading a pattern of bits. `78` is stored as `1001110`.
Text is stored the same way through a character set: Unicode gives
every character a number, and `ord("P")` will show you that the letter
P is number 80. The type is how Python knows which convention to use —
which is why `"14"` and `14` can look identical on screen and behave
nothing alike.

Two conventions your future self will thank you for: names that say
what they hold (`chairs_per_row`, not `c`), and `SCREAMING_SNAKE_CASE`
for values that are never meant to change, like `FILE_NAME`. Practise
all of it in [[Variables and Types Practice]].

%%curriculum-start%%
## Curriculum connection

![[A1.1]]

![[A1.2]]

![[A1.3]]

![[C1.4]]
%%curriculum-end%%
