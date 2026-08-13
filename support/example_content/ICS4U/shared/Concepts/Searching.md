---
title: Searching
draft: false
created: __CREATED__
tags:
  - concepts
enableToc: true
---
In [[The Race]] two groups wrote a card-number lookup for the
community centre. On the ten test cards, both were instant. On the
real file of a hundred thousand numbers, one still felt instant and
the other made you wait — every time, at the desk, with somebody
standing there.

Same answer, same language, same laptop. The difference was the method,
and this is the first time in the course that choosing a method is
worth marks.

## Linear search: start at the front

```python
def linear_search(values, target):
    """Return the index of target in values, or -1 if it is absent.

    Precondition: none. Any list at all will do.
    """
    for index in range(len(values)):
        if values[index] == target:
            return index
    return -1
```

Look at every item until you find it or run out. To *find* something
it may look at one item or all of them; to prove something is
**absent** it must look at every single one. With $n$ items the worst
case is $n$ comparisons — $O(n)$, growing in step with the data.

Returning `-1` rather than `None` or crashing is a deliberate
convention; the docstring records it. What matters is that every
caller knows what "not found" looks like.

## Binary search: halve it, every time

```python
def binary_search(values, target):
    """Return the index of target in values, or -1 if it is absent.

    Precondition: values is sorted in ascending order. On an unsorted
    list this function returns wrong answers instead of crashing.
    """
    low = 0
    high = len(values) - 1
    while low <= high:
        middle = (low + high) // 2
        if values[middle] == target:
            return middle
        elif values[middle] < target:
            low = middle + 1
        else:
            high = middle - 1
    return -1
```

`low` and `high` mark the region still worth searching. Each pass
looks at the middle of that region and throws away half of what is
left: too small, search the right; too big, search the left. Integer
division keeps `middle` a whole index — one of the few places
[[A1.1|the integer division expectation]] shows up doing real work.

Because the region halves each time, the question is not "how many
items" but "how many times can $n$ be halved" — $\log_2 n$. That is
$O(\log n)$, and it is why the numbers are almost hard to believe:

| Cards | Linear, worst case | Binary, worst case |
| --- | --- | --- |
| 1 000 | 1 000 | 9 |
| 10 000 | 10 000 | 13 |
| 100 000 | 100 000 | 16 |
| 1 000 000 | 1 000 000 | 19 |

Those counts are measured in [[Searching and Timing It]], and they are
exact — comparison counts are arithmetic, not measurement, so they are
the same on your machine as on ours.

Two details worth stealing:

- `low <= high`, not `low < high`. With the strict version, a region
  of one item is never examined and the search misses items at the
  edges. This is the classic binary search bug.
- `middle + 1` and `middle - 1`, not `middle`. The middle has already
  been compared; leaving it in the region is how you write a loop that
  never ends.

## The precondition is the whole point

Binary search works **only on sorted data**, and when that promise is
broken it does not crash. It returns `-1` for cards that are sitting
right there in the list.

> [!danger] Fast and wrong is a worse failure than slow and right
> On a shuffled list of 1 000 cards, binary search failed to find 991
> of them in our run — every one of them present. No exception, no
> warning. A real person is told they are not a member. When you
> replace a slow-and-correct search with a fast one, the *condition*
> you have introduced is part of the change, and a reviewer is right
> to ask how you know the data qualifies. That conversation is
> [[Read the Diff]], and it is not a formality.

A precondition is a claim about the starting state, and a
postcondition is a claim about the ending state. Writing both in the
docstring is what [[C2.1|the pre- and postcondition expectation]] asks
for, and it is the cheapest bug prevention in this course.

## Choosing, and the cost of qualifying

Sorting a list costs about $O(n \log n)$ — more than a single linear
search. So:

- **Searching once, unsorted data?** Linear search. Sorting first is
  more expensive than the search you avoided.
- **Searching many times?** Sort once, then binary search for ever
  after. The sort pays for itself within a few lookups.
- **Data arriving constantly and lookups by name?** Neither: use a
  dictionary, as [[Choosing a Data Structure]] argues, and get average
  $O(1)$ without keeping anything in order.

That is what "defending an algorithm" means at this level — not
knowing that binary search is faster, but saying under which
conditions, at what cost, and how you know the conditions hold.

Read the measurements in [[Searching and Timing It]], the vocabulary
in [[Efficiency and Big-O]], and drill both algorithms in
[[Searching Practice]].

%%curriculum-start%%
## Curriculum connection

![[A3.2]]

![[C2.1]]

![[C2.2]]
%%curriculum-end%%
