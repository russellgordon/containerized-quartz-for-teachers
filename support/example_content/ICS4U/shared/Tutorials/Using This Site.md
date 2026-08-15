---
title: Using This Site
publish: true
created: __CREATED__
tags:
  - tutorials
---
This site is the course's memory, and if you were here last year you
already know the basics: land on today, search with
<kbd>⌘</kbd> + <kbd>K</kbd> or <kbd>Ctrl</kbd> + <kbd>K</kbd>, hover
a link to preview it, predict before you unfold a worked answer. All
of that still works. This page is the next layer — the habits that
only start paying off when you are using a site like this the way you
will use a project's documentation at work.

## Read the backlinks as a dependency map

At the bottom of every page, *Backlinks* lists every page that links
**to** this one. Last year that was a convenience. This year it is a
technique.

Open [[Recursion]] and its backlinks name every warm-up, exercise,
program, and task that leans on the idea. That is exactly the
question you ask before changing anything in a shared codebase: *what
else depends on this?* A site that answers it in one glance is a good
place to practise asking it, and nobody maintains that list by hand.

## Link to the paragraph, not the page

A link can point at a heading inside a page, not just at the page
itself — add a `#` and the heading's exact wording to the end of the
link, as [[What This Site Can Do]] demonstrates. In your own notes,
in a task write-up, or in a message to a teammate, that is the
difference between "read this page" and "read this bit".

Precision is the same courtesy in a link as it is in a bug report.
Sending somebody a whole document when you meant one section is a
small tax that adds up across a team.

## Write once, transclude everywhere

One page can appear inside another, live, with `![[Page name]]`. Edit
the source and every page showing it updates. That is how the class
landing page always displays current information without anybody
maintaining three copies.

The idea is worth more than the syntax. It is the documentation
version of what [[Writing Code Others Can Read]] argues about
constants: **one authoritative place, referenced from everywhere
else**. Duplicated information goes stale exactly as fast as
duplicated code goes wrong, and for the same reason — somebody
updates one copy.

## Where things live

The folder map is on [[How This Site Is Organised]]. The full feature
tour, with the source shown for every example, is
[[What This Site Can Do]] — worth a proper read this year, because
the writing conventions on this site are the ones your own handover
documentation will be judged against.

> [!tip] Use the site the way you will use a README
> When you are stuck in the project, resist the urge to ask first.
> Search the site, follow one link, check the backlinks. The habit
> you are building is not "find the answer on this website" — it is
> "assume the answer was written down and go and find it", which is
> the single most useful reflex you can take into a codebase you did
> not write.
