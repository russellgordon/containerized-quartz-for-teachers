---
draftSection1: false
draftSection2: false
createdSection1: 2024-09-26T07:00:00.000-0400
createdSection2: 2024-10-25T07:00:00.000-0400
tags:
  - C3.3
notes: The idea is to have students try out the code and then realize they can add a line of code that moves the turtle back to the origin by multiplying it's current x and y position by -1. Then we can share a playground with them that has a function that moves the turtle back to the origin, using a function (or develop that in class with them). See the Scratch Page for the link to the playground in question, and the code for the function.
---

## Arithmetic Operators

Here is the complete list of arithmetic operators that can be used in an expression:

![[Pasted image 20221216085929.png|400]]

Note that the usual order of operations (e.g.: [BEDMAS](https://www.mathnasium.ca/2023-03-order-of-operations-and-bedmas-explained)) will be respected, including when brackets are used in expressions.

What this means is that we can perform arithmetic, or simple math, within expressions when drawing with the turtle.

To try this out, please create a new playground named *Adjusting Scale*.

Then try adding the following the following code to it:

```swift
let scale = 100.0
for i in 1...4 {
    turtle.forward(distance: 2.0 * scale)
    turtle.left(angleInDegrees: 90)
}
```

What happens to the drawing when you change the value assigned to `scale`?

## The Wandering Turtle

Please create a new playground titled *Going Home Again*.

Then copy and paste this code into the playground:

```swift
// FUNCTIONS

// Teach the computer to put the turtle in a random position
func moveToRandomPosition() {
    // Select a horizontal position at random
    let x = Double.random(in: -400...400)
    
    // Select a vertical position at random
    let y = Double.random(in: -300...300)
    
    // Move to the random position, leaving a trail behind
    turtle.penDown()
    turtle.lineWidth = 10
    turtle.diagonal(dx: x, dy: y)
    turtle.lineWidth = 3
    turtle.drawSelf()
    turtle.penColor = .red
    
}

// START OF ACTUAL PROGRAM

// Draw axes
turtle.drawAxes(withScale: true, by: 50, width: 800, height: 800, color: .black)

// Move to a random position
moveToRandomPosition()

// Get the current position of the turtle
let x = turtle.currentPosition().x
let y = turtle.currentPosition().y

// Print the current position of the turtle
turtle.drawText(message: "x \(x.description)",
                at: Point(x: -300, y: -200))
turtle.drawText(message: "y \(y.description)",
                at: Point(x: -300, y: -225))

// Move the turtle home again
// (Can you do this in one line of code?)
// Add your code immediately below this line...


// Where am I?
turtle.drawSelf()
```

## Experiment

Run the program several times. What do you notice?

![[Screenshot 2024-09-21 at 6.22.15 PM.png]]

## Consider

1. Write a single line of code, in the position indicated by the comments in the code, that moves the turtle home again.
2. In your notebook, use point-form English to describe the steps you might take to *always* move the turtle back to the correct location.
