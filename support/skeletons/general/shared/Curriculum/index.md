---
title: Curriculum
draft: false
enableToc: true
---
This folder is where the Ministry's expectations for __COURSE_CODE__ live —
one page per expectation, so a lesson or task can link to exactly the
expectations it addresses.

**It is empty apart from one example.** Ready-made curriculum pages ship
with a handful of course codes; for the rest, this is the shape to fill in.

## How to add them

1. Open the Ministry's curriculum document for __COURSE_CODE__ and find the
   expectations for this course.
2. Make one page per expectation, named for its code — `A1.1.md`, `A1.2.md`,
   and so on. [[A1.1|The example page]] shows the shape: the verbatim
   wording, ending in a ` ^text` block anchor.
3. On a lesson or task page, transclude the ones it addresses:

```markdown
%%curriculum-start%%
## Curriculum connection

![[A1.1]]
%%curriculum-end%%
```

The markers matter: they let the whole block be removed cleanly if you ever
decide the site should not carry expectations.

> [!warning] Copy the wording exactly
> An expectation paraphrased is an expectation misquoted. Copy the
> Ministry's words as they are published, and put your own explanation on a
> concept page instead.
