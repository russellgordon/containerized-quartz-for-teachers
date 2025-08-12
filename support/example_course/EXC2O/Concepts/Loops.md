---
draftSection1: false
draftSection2: false
createdSection1: 2024-09-18T07:00:00.000-0400
createdSection2: 2024-10-17T07:00:00.000-0400
tags:
  - C2.4
---
## Introduction

If we wanted someone to walk 5 steps, it's easier to say just that – "walk 5 steps" – rather than:

- walk 1 step
- walk 1 step
- walk 1 step
- walk 1 step
- walk 1 step

In the same way, we can use a *loop* to have a computer repeat an instruction – or a block of multiple instructions – more than once. When a loop repeats, we could also say that it *iterates*. A loop is also considered a form of abstraction.

## Creating a loop

To make a loop in Swift Playgrounds, just begin typing the keyword `for`, and then press the **Return** key to use autocomplete:

![[Pasted image 20240918071834.png]]

You will then have a template for a loop that you can fill in:

![[Pasted image 20240918071959.png]]

First, fill in the *number*.

That describes how many times you want the block of code to run.

Let's choose 5:

![[Pasted image 20240918072026.png]]

Next, copy the code shown here below into the body of the loop:

```swift
turtle.penDown()
turtle.forward(distance: 50)
turtle.penUp()
turtle.forward(distance: 50)
```

... replacing the placeholder:

![[Pasted image 20240918072041.png]]

... with the code:

![[Pasted image 20240918072059.png]]

The opening `{` marks the start of the code block that will be repeated.

The closing `}` marks the end of the code block that will be repeated.

You can step through your code to see exactly how the loop repeats the block of instructions:

<div style="padding:56.25% 0 0 0;position:relative;">
	<iframe src="https://player.vimeo.com/video/1010565533?h=b9ab9ef479&amp;badge=0&amp;autopause=0&amp;player_id=0&amp;app_id=58479&portrait=0&byline=0&title=0" frameborder="0" allow="autoplay; fullscreen; picture-in-picture; clipboard-write" style="position:absolute;top:0;left:0;width:100%;height:100%;" title="Opening the Teamspace">
	</iframe>
	</div>
<script src="https://player.vimeo.com/api/player.js"></script>

> [!NOTE]
> 
> Watch the video a second time. Notice how Playgrounds tells you how often a line of code has been run within a loop – 1x for once, 2x for twice, and so on.