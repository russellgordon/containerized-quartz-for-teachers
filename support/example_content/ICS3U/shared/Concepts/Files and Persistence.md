---
title: Files and Persistence
publish: true
created: __CREATED__
tags:
  - concepts
enableToc: true
---
The recycling tally worked beautifully, and then Ms. Nakamura closed
the window. Everything the program knew was in RAM, and RAM is
borrowed — it goes back the moment the program stops. If a program is
meant to be used more than once, something has to survive the closing
of it. That something is a file.

## Writing something down

```python
with open("weights.txt", "a") as file:
    file.write("6.5\n")
```

Three things to notice. `open` needs a **mode**: `"a"` appends to the
end of the file and creates it if it does not exist, `"r"` reads, and
`"w"` writes — where "writes" means *empties the file first*. Choosing
`"w"` when you meant `"a"` is the fastest way to delete somebody's data
in this course, so read that letter twice.

`with` guarantees the file is closed properly when the indented block
ends, even if something goes wrong inside it. And `write` adds nothing
you did not ask for: without the `\n` your two entries end up on one
line, glued together.

## Reading it back

```python
with open("weights.txt", "r") as file:
    for line in file:
        kilograms = float(line.strip())
        print(f"{kilograms:.1f} kg")
```

```
6.5 kg
3.0 kg
```

A file gives you back exactly what you put in: text, with a newline at
the end of each line. `.strip()` removes that newline, and `float()`
turns the text back into a number — the same conversion `input()`
needed, for the same reason. Everything in [[Working with Text]] about
splitting a line applies here, which is how one line can carry several
fields.

## The file might not be there

The first time anybody runs your program, the file does not exist:

```
FileNotFoundError: [Errno 2] No such file or directory: 'weights.txt'
```

That is not an unlikely edge case — it is guaranteed, once per user.
Handle it deliberately:

```python
try:
    with open("weights.txt", "r") as file:
        lines = file.readlines()
except FileNotFoundError:
    print("No entries yet — this will be the first.")
    lines = []
```

Designing what a program does when the exception happens is real design
work, and the curriculum names it directly in
[[B3.3|the expectation about detecting and handling exceptions]]. A
crash tells the user they broke something. A sentence tells them where
they are.

## Where the file actually is

`open("weights.txt")` looks in the **working directory** — normally the
folder your program was run from, not the folder the code is saved in.
That is why a program that worked in class "loses" its data when the
teacher runs it from her desktop. Two habits fix it: keep each
project's code and data in one folder, and name your files as if
somebody else has to find them in a year.

Organising a shared drive is the same skill, and it is the one your
client will judge you on when you hand the project over. A folder
called `final_FINAL_2` is a message about how much they should trust
what is in it.

## Backups are part of the program

A program that overwrites its only data file is one bug away from
losing everything the user has entered. Professionals assume the loss
will happen and plan for it: keep the original data somewhere the
program never writes, take a copy before any operation that rewrites a
file, and know how you would restore it. For your project that can be
as simple as a dated copy of the data file before each build — the
point is that "back it up" is a step in your process, not a hope.

> [!danger] Storing data about people is a decision, not a default
> The moment a file holds names, marks, attendance, or anything else
> about a person, you have taken on a responsibility you cannot hand
> back. Before you write that line of code, answer three questions in
> writing: what is the smallest amount of information that makes this
> program work, who else can open this file, and when does it get
> deleted?
>
> Very often the honest answer is that you do not need the name at
> all — a count, a total, or a title is enough. That is why the library
> program in [[Reading and Writing Files]] stores book titles and dates
> and nothing about the borrower. Take the same question to
> [[Should It Exist]] before your project stores its first row.

Practise reading and writing in [[Files Practice]], then read a
complete program that remembers things in
[[Reading and Writing Files]]. When a file operation fails, the message
is usually precise about why — [[Reading an Error Message]] shows how
to take one apart.

%%curriculum-start%%
## Curriculum connection

![[B3.3]]

![[C2.1]]

![[C2.3]]
%%curriculum-end%%
