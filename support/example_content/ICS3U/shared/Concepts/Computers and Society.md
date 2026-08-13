---
title: Computers and Society
draft: false
created: __CREATED__
tags:
  - concepts
enableToc: true
---
By now you have built something a real person uses. That is the moment
this page becomes possible to write honestly, because every question
below is now a question about your own code rather than about
technology in general.

## Privacy is a design decision

Your program probably stores something. Somebody's name, a mark, a
sign-out time, a phone number "in case". Each of those was a decision,
and defaults are decisions too — nobody has to approve them, which is
exactly what makes them worth examining.

> [!question] Four questions before your program stores anything
> 1. What is the smallest amount of information that still makes this
>    program work?
> 2. Who else can open this file — on this computer, on the shared
>    drive, in a backup?
> 3. Does the person whose information it is know it is being kept, and
>    would they be surprised?
> 4. When does it get deleted, and who does the deleting?

The most common honest answer to the first question is "less than I
was about to collect". A tally does not need names. A reminder list
needs a title and a date. Collecting less is not a compromise; it is
the version of the program that cannot leak what it never held.

## Who cannot use what you built

Software that works for you and fails for somebody else is not
neutral — it has quietly picked a user. Test your own project against
this list, honestly:

- Can it be used without a mouse, by somebody navigating with the
  keyboard?
- Can somebody with low vision read it — is the meaning ever carried by
  colour alone, or by text too small to enlarge?
- Are the messages in plain language? "Invalid input" tells nobody
  anything; "Please type the number of days, like 14" tells them what
  to do next.
- Does it assume a fast connection, a recent device, or a phone number
  the person may not have?
- Does the name field accept apostrophes, hyphens, accents, and names
  that are one word or five? Systems that reject real names are a
  long-standing, entirely avoidable insult.

Accessibility is not a feature added at the end. It is a series of
small decisions, each cheap while you are making it and expensive
afterwards.

## Whose rules are in the code

A program is somebody's judgement written down. When a sign-up form
requires a permanent address, or a scheduling tool assumes everyone is
free after school, the rule was probably never argued for — it just
arrived from whoever wrote it. That is the ordinary kind of bias, and
it is far more common than the dramatic kind.

The same question scales up. The [[D2.1|emerging research areas]] the
course asks you to look into — machine learning, computer vision,
security and cryptography, human–computer interaction — are all places
where somebody's judgement is being encoded and then applied to people
who never met them. A face-recognition system that works less well on
some faces than others is a design decision showing up as a failure
rate. Read the claims made about these systems the way
[[Tech Headlines]] teaches: ask who benefits, who was tested on, and
who is left carrying the error.

## The physical cost of computing

Computing is not weightless. It has three costs that are easy to
overlook because none of them appear on your screen:

- **Manufacturing and e-waste.** Devices are built from mined
  materials, and a replaced laptop does not disappear. Electronics are
  the fastest-growing kind of waste in many places, and much of it is
  handled badly.
- **Electricity.** Every device, server, and search draws power. A room
  of machines left running overnight is a real, measurable choice.
- **Paper.** Printing files and emails that nobody reads is the
  smallest of these and the easiest to stop.

There is a health cost too, and it is not abstract at Grade 11: hours
at a badly set-up desk produce genuine musculoskeletal problems and eye
strain, and a life arranged entirely around a screen costs sleep,
activity, and time with people.

The response is unglamorous and it works: power settings that actually
sleep the machines, lab and school policies about printing, repairing
and reusing a device rather than replacing it, and passing on hardware
that still has years in it. Outside the school there are
[[D1.4|organisations that exist for exactly this]] — municipal
electronics depots, charities that refurbish computers, and cartridge
return programs. Finding out which ones serve your community is a short
piece of research with a concrete outcome.

And computing pays some of this back. Modelling a design in software
instead of building it saves the physical materials; monitoring
networks track water, air, and energy use; routing and scheduling
programs cut kilometres driven. The honest position is neither "tech
will fix it" nor "computers are the problem" — it is that a computer is
a lever, and levers do what the person holding them wants.

Argue the hard cases in [[When Code Hurts]] and [[Should It Exist]],
and take the four questions above into your own project before you hand
it over.

%%curriculum-start%%
## Curriculum connection

![[D1.1]]

![[D1.2]]

![[D1.3]]

![[D2.1]]
%%curriculum-end%%
