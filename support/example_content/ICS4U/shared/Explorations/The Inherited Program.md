---
title: The Inherited Program
draft: false
created: __CREATED__
tags:
  - explorations
enableToc: true
---
The music room lends out instruments. Somebody built a program to track
the loans and print overdue notices, and that somebody has left the
school. The program still runs every Monday morning. Nobody currently
in the building can tell you how it works.

This morning it is yours.

```python
class Loan:

    def __init__(self, item, borrower, days_out):
        self.item = item
        self.borrower = borrower
        self.days_out = days_out

    def is_overdue(self):
        return self.days_out > 14

    def fee(self):
        if not self.is_overdue():
            return 0.00
        return 0.25 * (self.days_out - 14)


def print_notices(loans):
    for loan in loans:
        if loan.is_overdue():
            print(f"{loan.item} out to {loan.borrower}: "
                  f"{loan.days_out} days, ${loan.fee():.2f} owing")


loans = [
    Loan("Trumpet", "R. Okafor", 9),
    Loan("Cello", "M. Tremblay", 21),
    Loan("Music stand", "J. Ng", 15),
]

print_notices(loans)
```

Some of that syntax you have never been taught. That is deliberate, and
it is not a trick. Most of the code you will ever be handed contains
something you have not been taught yet.

## The task

Three jobs, in this order, and no skipping ahead.

**Job one — say what it does.** In your group, in three sentences, in
your own words, with no jargon you cannot define. Write it on the card
you are given. Do not write down what you think the code *should* do;
write down what it does.

**Job two — predict, then run.** Before you run anything, write your
predicted output on the back of the card. Then run it and compare. A
wrong prediction is worth more to you right now than a right one,
because it tells you exactly which line you had misread.

**Job three — the change request.** The music teacher emails at 8:40am:

> We are shortening the grace period. It is ten days now, not fourteen.
> Can it be right for period one?

Make the change. Then hand your file to another group and have them
check it with a loan of exactly 11 days out, and a loan of exactly 14
days out.

## The count

Hands up, honestly:

1. How many places did you have to edit?
2. How many groups changed one of them and not the other? What did
   their program print for the loan at 11 days?
3. Who noticed that the two places must always agree, and who found out
   from the other group's test?

The group that changed one `14` and not the other did not make a
careless mistake. They made the mistake this program is designed to
produce, because the rule that matters — *the grace period* — is
written down twice as a bare number and named nowhere.

> [!note]- Facilitation notes
> **Hand it out working, not broken.** The whole force of the day comes
> from a correct program becoming incorrect through an ordinary,
> reasonable change requested by a reasonable person.
>
> **Do not teach classes today.** Students will ask what `self` means
> and what `__init__` does. Answer only what is needed to get moving:
> "it is a way of keeping the three facts about one loan together, and
> we will name it properly next class." Resist the whole lesson. The
> ache is the point; it is discharged on Day 2 in
> [[Objects and Classes]].
>
> **Timing in a 70-minute period.** Ten minutes on job one, in silence
> at first, then in groups. Ten on job two. Ten on the change request,
> sprung when the room has just started to relax. Ten on the
> cross-check and the count. Twenty on the discussion below and on
> building the room's reading protocol on the board.
>
> **Plant a second file.** Give one group a version with a `main()`
> function at the bottom and the loan list read from a small text file.
> When groups compare notes, that group will report a different
> starting point, which is exactly how real code varies.
>
> **The sentence to wait for.** Some version of "we should just run it
> and see". Put it on the board with the student's name on it. That
> sentence is the whole course. Every reading strategy the room invents
> after that goes underneath it.
>
> **Collect the cards.** Keep the three-sentence descriptions. In Unit
> 4, when they hand their own project to somebody else, give the cards
> back. The distance between "what it does" and "what its author meant"
> is the argument of [[The Handover]], made with their own handwriting.

## What tends to surface

The room usually starts by reading top to bottom, like prose, and gets
about eight lines in before losing the thread. The groups that finish
first are almost never the fastest readers. They are the ones who ran
it, changed one line, ran it again, and let the program answer their
question instead of arguing about it.

The second discovery is about blame. When two groups disagree about
what the program does, the instinct is to decide who read it wrong. The
better question is what the program did to make two careful readers
disagree — because your own project will do the same thing to somebody
in eight weeks.

The third is the one worth writing on the wall: a rule that lives in
the code as a bare number, repeated, has no name and no single home.
Nobody who inherits it can change it safely. This is not a style
preference. It is why the 11-day loan got the wrong notice.

## Where this goes next

The strategies your room invented today are collected and sharpened in
[[Reading Somebody Else's Code]]. The syntax that made this program
opaque gets its name next class in [[Objects and Classes]], and you
will write your own in [[Your First Class]] before you design one in
[[The Model]].

The larger version of today, with a program big enough to hurt, is
[[The Maintenance Sprint]]. The argument about whose job any of this is
belongs to [[Who Maintains This]].

> [!note] The answer is not on this page
> The three sentences are not printed here, and neither is the safe
> version of the change. Your room writes both — one on cards, one on
> the board — and the version that survives another group's test at 11
> days is the one that goes in the file. If you want the fix that makes
> the next change safe, notice that you already said it out loud during
> the count.

%%curriculum-start%%
## Curriculum connection

![[A2.3]]

![[A4.1]]
%%curriculum-end%%
