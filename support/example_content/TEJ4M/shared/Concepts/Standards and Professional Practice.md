---
title: Standards and Professional Practice
draft: false
created: __CREATED__
tags:
  - concepts
enableToc: true
---
Every bench in this room runs on agreements somebody else wrote down. The
mains plug fits the socket, the USB cable fits the port, the 3.3 V logic
on one board understands the 3.3 V logic on another, and the resistor
marked 10 kΩ is 10 kΩ within a band the whole industry recognises. None
of that is luck. It is standards, and by Grade 12 you are expected to
work inside them deliberately rather than benefit from them accidentally.

## What a standard actually buys

A standard is a published agreement that lets parts, people, and
companies who have never met produce things that work together. It buys
four things worth naming at a design review: **interoperability**, so
somebody else's sensor works with your board; **safety**, because the
agreement encodes what has already gone wrong for other people;
**a shared vocabulary**, so that "class 2 insulated" or "IP-rated" means
the same to both parties in an argument; and **evidence**, because a
certification mark is a third party's statement, not a vendor's promise.

They also cost something. Standards move slowly, they can entrench the
incumbent's way of doing things, and complying with one takes time you
would rather spend building. Both halves belong in your report.

## The ones that touch this shop

| Kind | What it governs | Where you meet it here |
| --- | --- | --- |
| Workplace hazardous materials rules (WHMIS) | Labelling, safety data sheets, and training for hazardous products | Solder, flux, etchant, cleaning solvents |
| The provincial electrical safety code | How electrical work is done and inspected in Ontario | Anything connected to mains; why bench supplies are used instead |
| Certification marks on equipment | Independent testing of electrical equipment | The mark on a power supply you are allowed to plug in |
| Component and interface standards | Dimensions, tolerances, timing, voltage levels | Preferred resistor series, USB, serial ports, network cabling |
| Environmental rules on electronics | Restricted hazardous substances, and end-of-life handling | Lead-free solder; how a dead board leaves this building |
| Documentation conventions | Symbols, drawing practice, revision control | [[Read the Schematic]] and every drawing you submit |

Two of those rows deserve a sentence each, because they are the ones
students most often treat as background noise.

Hazardous-material rules are not about paperwork; they are about the fact
that flux fumes, etchant, and older solder are genuinely hazardous, and
that the person who has to know is you, before you use them. Labels and
safety data sheets exist so that knowledge does not depend on who
happened to be in the room.

Environmental rules follow the same logic on a longer timescale. Modern
electronics are made under restrictions on hazardous substances precisely
because the older ones ended up in soil and water, and Ontario runs
programs to divert electronics from landfill for exactly that reason. The
practical obligation on you is small and non-negotiable: dead boards,
batteries, and lamps leave this shop through the collection channel, not
the bin. That is the applied half of
[[C1.1|assessing the environmental effects of this technology]] — the
assessment is worth nothing if the board still goes in the garbage.

## Accountability: your name is on it

In Ontario, engineering practice is a licensed profession and the title
of Professional Engineer is protected in law; technicians and
technologists have their own certification bodies and designations. What
that means for your work now is not the letters after anybody's name — it
is the standard of accountability those systems exist to enforce, and the
habits are learnable at seventeen:

- **Sign your work.** Name, date, and revision on every drawing, program
  header, and report, as in [[Structuring a Larger Program]].
- **Say what you tested, and how.** A claim without a procedure behind it
  is an opinion.
- **State your assumptions and your margins**, so a reviewer can check
  the reasoning rather than only the result.
- **Report the problem you found**, including the one you caused. Late
  discovery is expensive; concealed discovery is a career.
- **Work inside your competence and ask when you are outside it.** "I do
  not know yet, here is how I will find out" is a professional sentence,
  not a confession — the same instinct as [[Getting Unstuck]].
- **Keep somebody else's interests in view.** The person who will
  maintain this, the person who will use it, and the person standing
  beside it when it fails.

## Staying current, because the ground moves

The technology you will use in five years does not all exist yet, and
none of it will wait for you. That is not a threat — it is the reason
this trade stays interesting, and it is written into the curriculum as
[[D3.2|the need for lifelong learning]] alongside
[[D3.4|the work habits the industry actually screens for]]: reliability,
initiative, teamwork, organisation, and the ability to advocate for
yourself. Employers assess those in the first month, whatever your marks
said.

Build the habit now. Follow a standards body or two, read the
manufacturer's application notes rather than only the datasheet, keep
[[Tech Journal]] entries that record why you chose things and not just
what you chose, and treat every certification and course you complete as
an entry in the portfolio you are already assembling. Bring the questions
this raises — about pathways, apprenticeship, college, and university —
to [[Where This Takes You]], and let the evidence you have collected all
year speak for itself in [[Final Reflection]] and
[[The Engineering Review]].

The specification you write, the margin you leave, and the documentation
you hand over are the professional part of this course.
[[Specification Practice]] is where the discipline gets rehearsed; the
rest of your working life is where it gets used.

%%curriculum-start%%
## Curriculum connection

![[C1.1]]

![[D1.1]]

![[D3.2]]

![[D3.4]]
%%curriculum-end%%
