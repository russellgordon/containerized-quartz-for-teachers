---
title: The Password Checker
publish: true
created: __CREATED__
tags:
  - programs
---
Two rules, honestly enforced: eight characters and at least one digit.
Nested [[Conditionals|conditionals]] and Boolean operators do the work.
Be clear about what this is: a *toy*. Real password guidance lives in
[[Staying Secure Online]] — and rule one is that you never type a real
password anywhere for practice, including here.

## The program

```python
password = input("Invent a password (never type a real one!): ")

long_enough = len(password) >= 8
has_digit = False

for character in password:
    if character.isdigit():
        has_digit = True

if long_enough and has_digit:
    if password == "password1":
        print("Technically legal. Famously terrible.")
    else:
        print("Passed both checks. Not bad.")
else:
    if not long_enough:
        print("Too short - eight characters minimum.")
    if not has_digit:
        print("No digits - add at least one.")
```

## Read it before you run it

Predict in writing first — then run the program and grade yourself.

- Which single input makes *two* complaint lines print at once?
- `has_digit` starts as `False`. What exactly can flip it to `True` —
  and is there anything that can ever flip it back?
- `password1` passes both checks, yet gets insulted anyway. Which
  lines arrange that, and why must they sit *inside* the first `if`?

## Make it yours

1. **One line.** Raise the minimum to twelve characters — then keep
   the complaint message honest.
2. **A few lines.** Add a third rule — at least one capital letter —
   using `character.isupper()` inside the existing loop.
3. **A real change.** Replace pass/fail with a strength score: one
   point per rule passed, reported as `Strength: 2 out of 3`.

%%curriculum-start%%
## Curriculum connection

![[C3.1]]

![[C2.3]]
%%curriculum-end%%
