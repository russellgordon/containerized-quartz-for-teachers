---
title: The Wrong Container
draft: false
created: __CREATED__
tags:
  - explorations
enableToc: true
---
The breakfast programme in the cafeteria keeps a tally. Every morning,
whoever is on the door writes down who came, and at the end of the
month somebody has to say how many mornings each person came. It is
currently done on paper, and the paper is a mess.

You have lists. Lists are the container you know. Build it with lists.

Here is where every group ends up within about ten minutes:

```python
names = []
visits = []


def record_visit(person):
    for position in range(len(names)):
        if names[position] == person:
            visits[position] = visits[position] + 1
            return
    names.append(person)
    visits.append(1)


def report():
    for position in range(len(names)):
        print(f"{names[position]}: {visits[position]}")


record_visit("Priya")
record_visit("Devon")
record_visit("Priya")
record_visit("Sam")
record_visit("Priya")

report()
```

It works. Run it and you get Priya 3, Devon 1, Sam 1. Nothing is wrong
with this program yet.

## The task

Four jobs, and the fourth one is the day.

**Job one — make it work.** Type it, or write your own version, and
tally the sample morning you are handed. Everyone gets the right
answer. Take thirty seconds to enjoy that.

**Job two — make it bigger.** Tally a month: 40 names, 20 mornings.
Count how many comparisons `record_visit` performs on the last morning
of the month. Not roughly — count them, on paper, for one call.

**Job three — the withdrawal.** One family withdraws from the
programme. Remove that person from the tally. Do it the obvious way:

```python
names = ["Priya", "Devon", "Sam"]
visits = [3, 1, 7]

names.remove("Devon")

for position in range(len(names)):
    print(f"{names[position]}: {visits[position]}")
```

Run it. Sam came seven mornings. Read what the program now says about
Sam.

**Job four — write the sentence.** On the board, in your own notation,
finish this sentence: *"What I actually want to write is …"*. Invent
whatever punctuation you like. You are not allowed to use the word
"list", and you are not allowed to say "index".

## What went wrong is not a bug

Nothing in job three was mistyped. `remove` did exactly what it says.
The two lists are joined only by a convention that lives in the
programmer's head — position 2 in `names` means the same person as
position 2 in `visits` — and there is nothing in the program that
enforces it. One ordinary, correct operation on one list broke that
convention silently, printed a confident wrong answer, and would have
gone into a report.

> [!note]- Facilitation notes
> **Let them build it with lists, properly.** Do not shortcut to the
> answer. The parallel-list version must work, and must be theirs, or
> the failure in job three lands as a gotcha rather than as evidence.
>
> **Timing in a 70-minute period.** Fifteen minutes on jobs one and
> two, ten on job three (springing the withdrawal only once everyone's
> tally is correct), ten on the board sentence in job four, and the
> rest on comparing the room's invented notations to each other.
>
> **Make job two physical.** Have one pair count comparisons out loud
> while another pair times them with a phone. Forty names is enough to
> be annoying and not enough to be abstract. Write the count on the
> board and leave it there; it is the seed of [[The Race]] in Unit 3.
>
> **The sentence to wait for.** Something close to "I just want to say
> `visits['Priya']`". Somebody almost always writes the square brackets
> with a name inside before they know that is legal Python. Circle it.
> Put their name on it. Next class, [[Dictionaries]] is that student's
> notation, spelled the way Python spells it.
>
> **Do not name it today.** The word "dictionary" should not be said by
> you. If a student who already knows says it, thank them, write the
> word in the corner, and carry on collecting notations — the room has
> not earned it yet, and earning it is what makes it stick.
>
> **If you want the second twist**, ask for one more thing at the very
> end: "now also record, for each person, which mornings they came".
> The parallel-list crowd needs a third list; and a list of lists; and
> the whole room feels the ceiling at once.

## What tends to surface

The first surface is that "it works" was a statement about the size of
the data. The program was correct for three people and one morning, and
its correctness had nothing to do with the deletion that came later.

The second is about who is holding the program together. Two parallel
lists work only while every operation on one is mirrored on the other,
and the person doing the mirroring is you, from memory, at 11pm. A
container that keeps the pairing itself is not a convenience. It is a
way of removing a class of mistakes from your life entirely.

The third surface is speed, and it usually arrives as a complaint from
whoever did job two honestly. Looking somebody up by scanning every
name is fine for forty and ridiculous for forty thousand. Hold on to
that complaint; the room will need it again.

## Where this goes next

The notation your room invented is named next class in
[[Dictionaries]], and you will read and change a working one in
[[Using a Dictionary]]. Two more containers with strict rules about
order arrive in [[Stacks and Queues]], and the habit of choosing rather
than defaulting is [[Choosing a Data Structure]].

Then you argue for your choice in writing, in [[The Structure Study]] —
the same problem, three containers, and a defence.

> [!note] The answer is not on this page
> No fixed version of the tally is printed here, and the word your room
> is circling is not written down either. Both belong to the class that
> comes after you have needed them. Bring your board notation to the
> next class; comparing it to Python's is the whole first ten minutes.

%%curriculum-start%%
## Curriculum connection

![[C1.1]]

![[A1.5]]
%%curriculum-end%%
