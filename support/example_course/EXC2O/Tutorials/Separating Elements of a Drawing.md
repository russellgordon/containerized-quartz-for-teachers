---
draftSection1: true
draftSection2: false
createdSection1: 2024-09-18T07:00:00.000-0400
createdSection2: 2024-10-25T07:00:00.000-0400
tags:
---

When authoring programs with many visual elements, it can be helpful to separate elements of those drawings by returning the turtle to the origin.

We can do this using a `goToHome` function, using logic similar to what we just came up with in class a moment ago:

```swift
func goToHome() {
    // Save current position
    let currentX = turtle.currentPosition().x
    let currentY = turtle.currentPosition().y
    
    // Return to origin
    turtle.penUp()
    turtle.diagonal(dx: -1 * currentX, dy: -1 * currentY)
    turtle.penDown()
}
```

For example, when authoring this sketch in a prior year, Matthew Zhang used the `goToHome` function to isolate each part of his code:

![[Screen Shot 2022-12-11 at 11.01.09 AM.png]]

> [!TIP]
> 
> This meant that if Matthew needed to change the turtle's movements in an earlier part of his drawing, it would not impact the movements of the turtle in later parts of his drawing.

Matthew *could* have copy-pasted the code inside his function to do this:

![[Screen Shot 2022-12-11 at 11.17.39 AM.png]]

However, that results in multiple lines of essentially identical code.

It is better to *teach* the computer how to return to the origin by *defining* a function:

![[Screen Shot 2022-12-11 at 11.34.24 AM.png|450]]

And then *invoking*, or calling, the function whenever you want to make the computer carry out the behaviours described in the function:

![[Screen Shot 2022-12-11 at 11.21.58 AM.png]]

Note how Matthew's program invoked the `goToHome` function 31 times!

If he had simply copy-pasted the functionality, he would have used 186 lines of code:

$$
\begin{aligned}
&31 \text{ returns to the origin}\times 6 \text{ lines of code}
\\ &= 186 \text{ total lines of code}
\end{aligned}
$$

By instead defining a function, and then invoking it multiple times, Matthew used this many lines of code:

$$
\begin{aligned}
&8 \text{ lines of code to define function} \\
&+ 31 \text{ lines of code to invoke function} \\
&= 39 \text{ total lines of code}
\end{aligned}
$$

Matthew's program was significantly shorter as a result!

This is an example of applying abstraction – using functions.
