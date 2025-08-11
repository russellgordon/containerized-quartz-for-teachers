---
draftSection1: false
draftSection2: false
createdSection1: 2024-11-12T07:00:00.000-0400
createdSection2: 2024-12-03T07:00:00.000-0400
notes: Need to print enough copies of the planning sheet for partners to analyse the poster. See "Blur - Planning Sheet.pdf".
tags:
  - A1.1
  - A1.2
  - C1.1
  - C1.5
  - C2.4
  - C2.6
  - C2.7
---
A "gig" is an occasion where a band or singer performs for an audience.

If you are a solo vocalist, or a member of a band, and you have a gig – you naturally want people to *attend* that performance.

![[Screen Shot 2022-12-08 at 1.16.14 PM.png]]

A gig poster is used to draw the attention of people passing by in a heavily populated area in the hopes that they will choose to attend the performance.

![[Screen Shot 2022-12-08 at 1.16.50 PM.png]]

As such, designs for a gig poster should draw the eye.

![[Screen Shot 2022-12-08 at 1.17.21 PM.png]]

[Mike Joyce](https://www.swissted.com/pages/about-us) is a graphic designer who has [created original gig posters](https://www.swissted.com/?page=1) for well known performances made by bands and artists in the past.

![[Screen Shot 2022-12-08 at 1.18.33 PM.png]]

For the next couple of weeks, by reproducing some of Mike Joyce's posters, and then creating your own original gig poster, you will revisit and reinforce your understanding of these key programming concepts:

- sequence (order of statements)
- iteration (loops)
- abstraction (use of functions)

You will also learn about a *new* concept:

- selection (choosing a block of code to be run based upon a condition)

## Making a Plan

You have used  loops in the past to render repeated elements of a drawing:

![[Screen Shot 2022-12-08 at 1.22.08 PM.png|300]]

Consider the following gig poster:

![[blur - no grid copy.png|510]]

What repeated elements do you see in this poster?

It might be helpful to view this poster against a grid:

![[blur - with grid copy.png|510]]

We can reproduce this poster by applying the concepts of *sequence* and *iteration*.

With your partner, mark up the planning sheet you have been provided with, and:

1. number elements of the drawing to indicate what order they might be drawn in (sequence)
2. identify where a loop might be used (iteration)
	- consider the position of each repeated element
	- look for a numerical pattern in the positioning of each element

> [!TIP]
> When text is drawn, imagine a rectangular box around the text. To position text you specify the co-ordinates of the *lower-left corner*.

After some thought, you may have come up with something like this:

![[IMG_1BC805D98ECE-1.jpeg]]

Let's look at how to implement this now.

## Implementation

### Add the axes 

First, add the axes and the scale.

The first quadrant of every gig poster will be 400 pixels wide by 600 pixels high:

![[Screen Shot 2022-12-08 at 3.38.12 PM.png]]

> [!TIP]
> 
> To create the color well (allowing for colors to be selected from a flyout menu) begin typing `#colorLiteral(`.
> 
> As you type the opening bracket, `(`, the code will turn into a color well.

### Generate PDF output

You may see that the grid does not completely fit within the height of your computer's screen.

That is OK – you can also check what your program produces by generating a PDF file of the output.

Add this code to the end of your program:

```swift
// Generate a PDF
turtle.renderDrawingToPDF()
```

Here is how you can find the PDF after running your program:

![[Generating PDF Output.mp4]]

> [!TIP]
> Once you have found the PDF file, keep it open. When you re-run your code in Playgrounds, and then return to the PDF file, it's contents will be updated.

### Draw the background

Next, draw the background.

The `drawAxes` command, by default, anchors rectangles from their lower left hand corner.

So, to draw the background – identified in our plan as 800 pixels wide by 1200 pixels high – add the following code to the end of your program, anchoring the rectangle at $(-400,-600)$:

![[Screen Shot 2022-12-08 at 4.13.22 PM.png]]

Three problems surface:

1. The axes are no longer visible.
2. The shade of blue is incorrecct.
3. The PDF output does not match the output seen in Playgrounds.

Let's fix these three small problems now.

#### 1. Show the axes

The axes are not visible because the *sequence* of the code is currently incorrect.

The axes are drawn, and *then* the background.

So, the blue rectangle of the background covers up the axes.

Instead, we should draw the rectangle for the background, then draw the axes.

Make good use of keyboard shortcuts as you change the sequence of the code:

![[Fixing the Sequence to Show Axes.mp4]]

Now the axes are visible.

#### 2. Adjust the color

Using the color well and eyedropper tool, we can sample the correct color from the example given in this tutorial.

Arrange your Playgrounds window and this web page side by side, then sample the color like this:

![[Using the Eyedropper Tool to Obtain a Color.mp4]]

Now the shade of blue is correct.

#### 3. Ensure PDF output matches Playgrounds output

At this point, if we arrange the PDF (at left) next to the output from our code in Playgrounds (at right) the output does not match:

![[Screen Shot 2022-12-09 at 5.48.41 AM.png]]

To fix this, again we must consider the *sequence* of our code.

As a general rule, ensure that the command:

```swift
// Generate a PDF
turtle.renderDrawingToPDF()
```

... is the final command in the playground's code.

Right above that command, draw the axes:

![[Screen Shot 2022-12-09 at 5.51.27 AM.png]]

And above that, have all the code that draws the poster.

It can be helpful to separate these sections with clear comments, shown here using `UPPERCASE` letters:

![[Screen Shot 2022-12-09 at 5.53.17 AM.png|"Note the use of comments with UPPERCASE letters to separate sections of code."]]

### Draw the band name repeatedly

According to the plan, the second step is to draw the name of the band, **blur**, repeatedly:

![[IMG_1BC805D98ECE-1.jpeg]]

Recall that the *lower-left corner* of the the text is the anchor point.

In the plan, we see that anchor points range between -600 and 60. Note the annotations in red:

![[IMG_C664455E35CB-1.jpeg]]

As well, we observed in our plan that within a vertical range of 100 pixels, it looks like the word **blur** is repeated five times. Note the lower left part of the plan, where a blue ☆ has been added:

![[IMG_EDE918FC294B-1.jpeg]]

If the word **blur** is repeated 5 times within a height of 100 pixels, that means the change in position must be 20 pixels.

So the pattern of $y$ values would start as:

$$-600, -580, -560, -540, -520\text{...}$$

...and end all the way up at the top of the repeated text with:

$$\text{...}-40, -20, 0, 20, 40, 60$$

We can express all of that with the following code added to our program after drawing the background color:

![[Screen Shot 2022-12-09 at 6.16.48 AM.png|500]]

How to type that in is shown in the animation below. Some things to keep in mind:

1. use the `tab` key to move between placeholders
2. it's not necessary to add a `⮐` or new line after each argument for the `drawText` command, but it can help to improve the readability of your code
3. the black text used for the title is transparent, with an opacity of about 10%
4. the `kerning` parameter accepts positive or negative values as an argument; negative values draw letters closer together and positive values push letters in the text further apart from one another

![[Adding a Loop Using Stride.mp4]]

We have made good progress!

### Draw the band name 

According to the plan, the third step is to draw the name of the band, **blur**, once, in opaque black text:

![[IMG_1BC805D98ECE-1.jpeg]]

This is straightforward.

Add the code shown here:

```swift
// Draw the primary title
turtle.drawText(message: "blur",
                at: Point(x: -375, y: 0),
                color: .black,
                size: 440,
                kerning: -15.0)
```

... just after the loop that draws the name of the band repeatedly:

![[Screen Shot 2022-12-09 at 6.46.43 AM.png]]

### Draw the subtitle text

The fourth and final step is to draw all of the smaller text at the top the poster:

![[IMG_1BC805D98ECE-1.jpeg]]

When you make a poster like this, a bit of trial and error is needed to get the exact values for the horizontal and vertical positions of the smaller text.

A good approach is to think of the smaller text as a grid. Analyse the poster more closely:

![[IMG_2BA71B77C1FA-1.jpeg]]

Use some constants (declared using the `let` keyword) to store values for the $x$ positions of each column of smaller text, and to store values for $y$ positions of each row of text:

![[Screen Shot 2022-12-09 at 7.03.03 AM.jpg|550]]

This makes it fast to adjust the positions of all text within a column or row, when you use those constants to position each piece of text:

![[Screen Shot 2022-12-09 at 7.02.15 AM.jpg|650]]

Add the code shown above to your program. It's totally OK to copy and paste a block of code and adjust the values for each additional piece of text!

> [!NOTE]
> A `kerning` value of `0.1` is used to ever so slightly push the letters of each piece of smaller text away from one another.

All done! 🎉 

To take your final look, comment out the line of code that draws the axes using the `Command /` (command and forward slash) keyboard shortcut:

![[Comment out a Block of Code.mp4]]

It's best to see your final product by looking at the PDF version:

![[Viewing the Finished Product.mp4]]

## Exercise: Sweating the details

Look *very* closely at the bottom of the poster.

Try zooming in on the bottom of the PDF file you've generated.

Do you notice anything that is not quite right?

Think in terms of overlapping shapes. 

How could you fix the minor issue that you've spotted? 😎



