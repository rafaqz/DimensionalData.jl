# Group By

DimensionalData.jl provides a `groupby` function for dimensional
grouping. This guide will cover:

- simple grouping with a function
- grouping with `Bins`
- grouping with another existing `AbstractDimArry` or `Dimension`


## Grouping functions

Lets look at the kind of functions that can be used to group `DateTime`.
Other types will follow the same principles, but are usually simpler.

First load some packages:

````@example groupby
using DimensionalData
using Dates
using Statistics
const DD = DimensionalData
nothing # hide
````

Now create a demo `DateTime` range

````@ansi groupby
tempo = range(DateTime(2000), step=Hour(1), length=365*24*2)
````

Lets see how some common functions work.

The `hour` function will transform values to hour of the day - the integers `0:23`

:::tabs

== hour

````@ansi groupby
hour.(tempo)
````

== day

````@ansi groupby
day.(tempo)
````

== month

````@ansi groupby
month.(tempo)
````

== dayofweek

````@ansi groupby
dayofweek.(tempo)
````

== dayofyear

````@ansi groupby
dayofyear.(tempo)
````

:::


Tuple groupings

::: tabs

== yearmonth

````@ansi groupby
yearmonth.(tempo)
````

== yearmonthday

````@ansi groupby
yearmonthday.(tempo)
````

== custom

We can create our own function that return tuples

````@example groupby
yearday(x) = (year(x), dayofyear(x))
nothing # hide
````

You can probably guess what it does:

````@ansi groupby
yearday.(tempo)
````

:::


## Grouping and reducing

Lets define an array with a time dimension of the times used above:

````@ansi groupby
A = rand(X(1:0.01:2), Ti(tempo))
````

::: tabs

== basic

Group by month, using the `month` function:

````@ansi groupby
groups = groupby(A, Ti=>month)
````

We can take the mean of each group by broadcasting over them:

````@ansi groupby
mean.(groups)
````

== sum dayofyear

````@ansi groupby
sum.(groupby(A, Ti=>dayofyear))
````

== maximum yearmonthday

````@ansi groupby
maximum.(groupby(A, Ti=>yearmonthday))
````
== minimum yearmonth

````@ansi groupby
minimum.(groupby(A, Ti=>yearmonth))
````

== median hour

````@ansi groupby
median.(groupby(A, Ti=>hour))
````

== mean yearday

We can also use the function we defined above

````@ansi groupby
mean.(groupby(A, Ti=>yearday))
````

:::

## Binning

Sometimes we want to further aggregate our groups after running a function,
or just bin the raw data directly. We can use the [`Bins`](@ref) wrapper to
do this.

::: tabs

== evenly spaced

For quick analysis, we can break our groups into `N` bins.

````@ansi groupby
groupby(A, Ti=>Bins(month, 4))
````

Doing this requires slightly padding the bin edges, so the lookup
of the output is less than ideal.

== specific values as bins

When our function returns an `Int`, we can use a range of values we want to keep:

  ````@ansi groupby
mean.(groupby(A, Ti=>Bins(month, 1:2)))
````

== selected month bins

````@ansi groupby
mean.(groupby(A, Ti=>Bins(month, [1, 3, 5])))
````

== bin groups

We can also specify an `AbstractArray` of grouping `AbstractArray`:
Her we group by month, and bin the summer and winter months:

````@ansi groupby
groupby(A, Ti => Bins(month, [[12, 1, 2], [6, 7, 8]]; labels=x -> string.(x)))
````

== range bins

First, lets see what [`ranges`](@ref) does:

````@ansi groupby
ranges(1:8:370)
````

We can use this vector of ranges to group into blocks, here 8 days :

````@ansi groupby
groupby(A, Ti => Bins(dayofyear, ranges(1:8:370)))
````

Note: this only works where our function `dayofyear` returns
values exactly `in` the ranges. `7.5` would not be included!

== intervals bins

Intervals is like ranges, but for taking all values in
an interval, not just discrete `Integer`s.

`intervals` returns closed-open `IntervalSets.Interval`:

````@ansi groupby
intervals(1:0.3:2)
````

We can use this to bin the `Float64` values on the `X` axis:

````@ansi groupby
groups = groupby(A, X => Bins(intervals(1:0.3:2)))
````

The lookup values of our final array are now `IntervalSets.Interval`:

````@ansi groupby
mean.(groups)
````

== seasons

There is a helper function for grouping by three-month seasons and getting
nice keys for them: `seasons`. Note you have to call it, not just pass it!

````@ansi groupby
groupby(A, Ti => seasons())
````

We could also start our seasons in January:

````@ansi groupby
groupby(A, Ti => seasons(; start=January))
````

== months

We can also use `months` to group into arbitrary
group sizes, starting wherever we like:

````@ansi groupby
groupby(A, Ti => months(2; start=6))
````

== hours

`hours` works a lot like `months`. Here we group into day
and night - two 12 hour blocks starting at 6am:

````@ansi groupby
groupby(A, Ti => hours(12; start=6, labels=x -> 6 in x ? :night : :day))
````

:::

## Select by Dimension
- [`Dimension`](@ref)

We can also select by `Dimension`s and any objects with `dims` methods.

::: tabs

== groupby dims

Trivially, grouping by an objects own dimension is similar to `eachslice`:

````@ansi groupby
groupby(A, dims(A, Ti))
````

== groupby AbstractDimArray

But we can also group by other objects dimensions:

````@ansi groupby
B = A[:, 1:3:100]
C = mean.(groupby(A, B))
@assert size(C) == size(B)
````

:::

_TODO: Apply custom function (i.e. normalization) to grouped output._
