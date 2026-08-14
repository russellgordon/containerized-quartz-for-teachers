---
title: Making a Thematic Map
draft: false
created: __CREATED__
tags:
  - mapping
  - unit-1
---
A thematic map shows one variable across space. Not the place — the
variable. That restriction is what makes it powerful and what makes it so
easy to mislead with, because you are choosing what a reader sees and,
silently, what they never find out.

## Three kinds, and when each is honest

**Choropleth** shades whole areas by value. It is right for a **rate** —
density, percentage, median age — and wrong for a **count**. Shade by
total population and you have mostly mapped the size of the polygons.

**Proportional symbol** scales a circle at a point to the value. Counts
belong here. Scale by *area*, not radius, or a value twice as large looks
four times as large.

**Dot** places one dot per fixed quantity, so the pattern emerges from
dot density. It shows distribution best, and it invites the reader to
think the dots sit where things actually are. They do not; they are
scattered inside a boundary.

## The trap: class breaks

The method you use to sort values into classes changes the picture without
changing a single number. **Equal interval** cuts the range into equal
bands — clean, and useless when one outlier stretches the range.
**Quantiles** put an equal count in each class, which always looks
balanced, including when the data are not. **Natural breaks** finds gaps
in the data: usually the most faithful, and the hardest to explain.

> [!warning]- The same data, two stories (click to expand)
> Take five communities with unemployment of 4, 5, 6, 7 and 19 per cent.
> Three equal-interval classes put four of them in the lowest band and one
> alone at the top: a map about one place in trouble. Three quantile
> classes split them roughly two, two and one: a map about a region
> sliding downhill. Nobody lied. Somebody chose.
>
> Which is why the method belongs in the legend, not just in your head.

## The furniture, and why each piece is load-bearing

Five things, every time. **Title** — the variable, the area, the year.
**Legend** — the classes, their values, and the classification method.
**Scale** — a bar, so it survives resizing. **North arrow**, unless the
projection makes north vary across the sheet, in which case say so.
**Source** — dataset, publisher and year, on the face of the map, where a
reader who screenshots it will still see them.

Leave any of the five off and a reader has to take your word for it. The
point of a map is that they should not have to.

Get numbers from [[Working With Census Data]], check where they came from
with [[Judging a Source]], and build your third version in
[[A Map of Your Own]].

%%curriculum-start%%
## Curriculum connection

![[A1.4]]

![[A1.6]]
%%curriculum-end%%
