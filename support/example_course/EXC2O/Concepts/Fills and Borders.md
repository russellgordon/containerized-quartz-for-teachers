---
draftSection1: true
draftSection2: false
createdSection1: 2024-09-19T07:00:00.000-0400
createdSection2: 2024-12-04T07:00:00.000-0400
tags: 
---

A lot can be done with fills and borders using the `turtle` in **Swift Playgrounds**.

Each shape has a fill and border. The width of the border of a shape can be adjusted.

## Defaults

The defaults are:

- fill is *clear*
- border is blue
	- width of border is 3 pixels

For example:

```swift
// Draw a standard poster grid
// NOTE: Width and height refer to the size of the first quadrant (top-right)
turtle.drawAxes(withScale: true, by: 100, width: 400, height: 600, color: .black)

// Defaults example – shape will have a clear (transparent) fill and blue border
turtle.drawRectangle(at: Point(x: 0, y: 0), width: 300, height: 200)
```

This produces:

![[Screenshot 2024-12-04 at 9.59.06 AM.png]]

## Adjusting fill

Let's adjust the fill. 

Here is how to do that – take note of how the color well is produced by typing `#colorLiteral(`:

<div style="padding:56.25% 0 0 0;position:relative;">
	<iframe src="https://player.vimeo.com/video/1036012402?h=1752a5af7c&amp;badge=0&amp;autopause=0&amp;player_id=0&amp;app_id=58479&portrait=0&byline=0&title=0" frameborder="0" allow="autoplay; fullscreen; picture-in-picture; clipboard-write" style="position:absolute;top:0;left:0;width:100%;height:100%;" title="Opening the Teamspace">
	</iframe>
	</div>
<script src="https://player.vimeo.com/api/player.js"></script>

The new code is:

```swift
// Adjust the fill
// NOTE: The #colorLiteral code will be converted into a "color well"
// when copy-pasted into a Playground
turtle.fillColor = #colorLiteral(red: 0.3997545242, green: 0.6133489013, blue: 0.2060141265, alpha: 1.0)
turtle.drawRectangle(at: Point(x: -300, y: 0), width: 200, height: 100)
```

The visual result is:

![[Screenshot 2024-12-04 at 10.11.02 AM.png]]

## Adjusting the border color

Here is the new code:

```swift
// Adjust the border color
turtle.penColor = #colorLiteral(red: 0.8894588351, green: 0.1420151591, blue: 0.0, alpha: 1.0)
turtle.drawRectangle(at: Point(x: -300, y: -300), width: 200, height: 200)
```

Here is the result:

![[Pasted image 20241204100955.png]]

## Adjusting the border width

Here is the new code:

```swift
// Adjust the border width
turtle.lineWidth = 20
turtle.drawRectangle(at: Point(x: 100, y: -200), width: 300, height: 100)
```

Here is the result:

![[Pasted image 20241204101302.png]]

## Sequence

The border and fill settings apply to all shapes drawn *after* a given change to the fill or border – the *sequence*, or order you supply instructions, does matter:

![[Screenshot 2024-12-04 at 10.16.29 AM.png]]

## Conclusion

Here is all of the code shared above in one code block – use this as a reference while you work on reproducing gig posters, or producing your own gig poster, later in this module:

```swift
// Draw a standard poster grid
// NOTE: Width and height refer to the size of the first quadrant (top-right)
turtle.drawAxes(withScale: true, by: 100, width: 400, height: 600, color: .black)

// Defaults example – shape will have a clear (transparent) fill and blue border
turtle.drawRectangle(at: Point(x: 0, y: 0), width: 300, height: 200)

// Adjust the fill
turtle.fillColor = #colorLiteral(red: 0.3997545242, green: 0.6133489013, blue: 0.2060141265, alpha: 1.0)
turtle.drawRectangle(at: Point(x: -300, y: 0), width: 200, height: 100)

// Adjust the border color
turtle.penColor = #colorLiteral(red: 0.8894588351, green: 0.1420151591, blue: 0.0, alpha: 1.0)
turtle.drawRectangle(at: Point(x: -300, y: -300), width: 200, height: 200)

// Adjust the border width
turtle.lineWidth = 20
turtle.drawRectangle(at: Point(x: 100, y: -200), width: 300, height: 100)

// Draws a circle with a red border and green fill
turtle.drawEllipse(at: Point(x: 200, y: -400), width: 150, height: 150)

// Change the fill to yellow and the
// border color to purple
// NOTE: Has no impact on drawing, since
// shapes were drawn BEFORE fill and border color
// where changed.
turtle.penColor = .purple
turtle.fillColor = .yellow
```
