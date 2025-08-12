---
draftSection1: false
draftSection2: false
createdSection1: 2024-09-06T07:00:00.000-0400
createdSection2: 2024-09-09T07:00:00.000-0400
tags:
  - C1.1
---
## Gameplay

We broke into pairs and played [Rock-Paper-Scissors](https://wrpsa.com/the-official-rules-of-rock-paper-scissors/) with everyone in our class.

The winner of each initial match paired with another winner to play a match in the second round. Losers of a match from the first round then cheered for the person who won their first-round match. 

So in the second round, 8 people are active, with the rest cheering someone on by repeating their name.

In the third round, 4 people are active, with everyone else cheering.

This continues until there is one final winner – the ultimate Rock-Paper-Scissors champion.

## Discussion

The efficiency with which an ultimate Rock-Paper-Scissors champion is found is the same as that for the worst-case scenario of the [binary search algorithm](https://yongdanielliang.github.io/animation/web/BinarySearchNew.html).

Worst case, using binary search with a sorted list of 16 numbers, the target number [can be found](https://yongdanielliang.github.io/animation/web/BinarySearchNew.html) with just 4 comparisons.

## Extension

Although using the following terminology goes beyond expectations in this course, binary search is $O(log_2 n)$ – that is read out loud as "big O log base 2" – a worst-case [logarithmic](https://www.mathsisfun.com/algebra/logarithms.html) efficiency.

In the best case, binary search is $\Omega(1)$ – read out loud as "big omega 1". That is to say: if the target number is  in the middle of a sorted list of numbers, it will be found after just one comparison.

## Conclusion

An *algorithm* is nothing more than a series of steps taken to accomplish a goal.

Also, that Ultimate Rock-Paper-Scissors is a pretty fun way to learn the names of some of the people in our class. 🙂