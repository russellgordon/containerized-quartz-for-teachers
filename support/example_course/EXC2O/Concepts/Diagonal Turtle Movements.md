---
draftSection1: false
draftSection2: false
createdSection1: 2024-09-19T07:00:00.000-0400
createdSection2: 2024-10-09T07:00:00.000-0400
tags: 
---

Say that you want to draw a triangle like this:

![[Pasted image 20240919071631.png|300]]

You could do this by moving the turtle forward and turning.

Drawing the horizontal and vertical edges would be easy.

Drawing the diagonal is harder. How long should the edge be? By how many degrees would the turtle have to turn?

If you have studied trigonometry, you know this can be relatively easily figured out.

However, using sine, cosine, or tangent ratios is just a *bit* too much work to do every time we want to draw a diagonal.

So... the turtle drawing framework has a shortcut. It is the diagonal command:

![[Pasted image 20240919072002.png]]

Here is how it works – watch the animation closely:

<div style="padding:56.25% 0 0 0;position:relative;">
	<iframe src="https://player.vimeo.com/video/1010934331?h=30d563dd9a&amp;badge=0&amp;autopause=0&amp;player_id=0&amp;app_id=58479&portrait=0&byline=0&title=0" frameborder="0" allow="autoplay; fullscreen; picture-in-picture; clipboard-write" style="position:absolute;top:0;left:0;width:100%;height:100%;" title="Opening the Teamspace">
	</iframe>
	</div>
<script src="https://player.vimeo.com/api/player.js"></script>

In more detail, here is an explanation:

![[Screenshot 2024-09-19 at 7.31.39 AM.png]]

To summarize, with a few more examples:

|direction|argument|result|
|-|-|-|
|right|dx: 100|goes 100 units to the right, relative to current position|
|left|dx: -100|goes 100 units to the left, relative to current position|
|up|dy: 100|goes 100 units upwards, relative to current position|
|down|dy: -100|goes 100 units downwards, relative to current position|
