---
title: Writing Good Comments
publish: true
created: __CREATED__
tags:
  - tutorials
---
A comment is a message to a future reader — usually you, three weeks
from now, having forgotten everything. The one rule: comments explain
**why**, not *what*. The code already says what it does; a comment
that repeats it is noise. The *reason* lives nowhere else.

## Before and after

Noise — the comment restates the line below it:

```python
# check if length is less than 8
if len(password) < 8:
    print("Too short")
```

Signal — the comment records the decision the code cannot express:

```python
# Short passwords fall to guessing attacks fastest, so we
# reject under 8 characters before checking anything else.
if len(password) < 8:
    print("Too short")
```

Same program — but only the second one lets a reader *disagree* with
you, which is what [[The Password Checker]] reviews will ask of it.

## Docstrings for subprograms

Every [[Subprograms and Modules|subprogram]] you write gets a
docstring — one sentence, in quotes, first line inside it, saying what
it does and returns:

```python
def average(scores):
    """Return the mean of a list of quiz scores."""
```

Tools display docstrings automatically, so this one sentence is the
subprogram's public face — write it for a stranger reusing your code.

## Crediting help — in the code itself

[[Our Classroom Norms]] says help is fine WHEN NAMED, and the comment
is where the naming happens:

```python
# Loop structure adapted from an AI assistant's example;
# I rewrote the condition and tested the edge cases myself.
```

Classmate's idea, forum answer, AI suggestion — same pattern: name
the source, then say which part of the thinking is yours. That is
exactly how professionals document borrowed code — and it turns "did
you write this?" into a question your comment already answered.

%%curriculum-start%%
## Curriculum connection

![[C2.7]]

![[C3.5]]
%%curriculum-end%%
