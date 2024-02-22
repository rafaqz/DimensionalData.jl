# Group By

DimensionalData.jl provides a `groupby` function for dimensional
grouping. This guide will cover:

- simple grouping with a function
- grouping with `Bins`
- grouping with another existing `AbstractDimArry` or `Dimension`


# Grouping functions

Lets look at the kind of functions that can be used to group `DateTime`.
Other types will follow the same principles, but are usually simpler.

First load some packages:

````@example groupby
using DimensionalData
using Dates
using Statistics
const DD = DimensionalData
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

::::tabs

== yearmonth

````@ansi groupby
yearmonth.(tempo)
````

== yearmonthday

````@ansi groupby
yearmonthday.(tempo)
````

== custom

We can create our own anonymous function that return tuples

````@example groupby
yearday(x) = year(x), dayofyear(x)
yearhour(x) = year(x), hour(x)
````

And you can probably guess what they do:

````@ansi groupby
yearhour.(tempo)
````

== yearday

````@ansi groupby
yearday.(tempo)
````

:::


# Grouping and reducing

Lets define an array with a time dimension of the times used above:

````@ansi groupby
A = rand(X(1:0.01:2), Ti(tempo))
````

::::tabs

== basic

And group it by month:

````@ansi groupby
groups = groupby(A, Ti=>month)
````

We take the mean of each group by broadcasting over them :

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

We can also use the function we defined above

== mean yearday

````@ansi groupby
mean.(groupby(A, Ti=>yearday))
````

::::

# Binning

Sometimes we want to further aggregate our groups after running a function,
or just bin the raw data directly. We can use the [`Bins`](@ref) wrapper to
do this.

::::tabs

== bins

When our function returns an `Int`, we can use a range of values we want to keep:

````@ansi groupby
mean.(groupby(A, Ti=>Bins(month, 1:2)))
````

== selected month Bins

````@ansi groupby
mean.(groupby(A, Ti=>Bins(month, [1, 3, 5])))
````

== manual bin groups

Groupby by month and take the summer and winter months:

````@ansi groupby
groupby(A, Ti => Bins(month, [[12, 1, 2], [6, 7, 8]] ; labels=x -> string.(x)))
````

== ranges bins

First, lets see what [`ranges`](@ref) does:

````@ansi groupby
ranges(1:8:370)
````

We can use this to group into blocks of 8 days.

````@ansi groupby
groupby(A, Ti => Bins(dayofyear, ranges(1:8:370)))
````

Note: this only works where our function `dayofyear` returns
values exactly `in` the ranges. `7.5` would not be included!

== seasons

There is a helper function for grouping by three-month seasons and getting
nice keys for them: `season`. Note you have to call it, not just pass it!

````@ansi groupby
groupby(A, Ti => season())
````

We could also start our seasons in January:

````@ansi groupby
groupby(A, Ti => season(; start=January))
````

== months

We can also use `months` to group into arbitrary
group sizes, starting wherever we like:

````@ansi groupby
groupby(A, Ti => months(2; start=6))
````

== hours

`hours` works a lot like `months`. Here we groupb into day
and night - two 12 hour blocks starting at 6am:

````@ansi groupby
groupby(A, Ti => hours(12; start=6, labels=x -> 6 in x ? :night : :day))
````

::::


## select by month, days, years

How do we select month 1 or 2, and even a group of them, i.e. [1,3,5]? Same for days, years and seasons.

Use three-month bins. The 13 is the open side of the last interval.

````@ansi groupby
groupby(A, Ti=>Bins(yearmonth, intervals(1:3:12)))
````

````@ansi groupby
groupby(A, Ti=>Bins(month, 4))
````

# Select by [`Dimension`](@ref)

We can also select by `Dimension`s and any objects with `dims` methods:

````@ansi groupby
julia> B = A[:, 1:3:100]
julia> C = mean.(groupby(A, B))
julia> @assert size(A) == size(B)
````

How do could we incorporate resample? Let's say if we have hour resolution I want to resample every 3,6,12.. hours?

# it will combine the same day from different year.

````@ansi groupby
groupby(A, Ti=>Bins(yearhour, intervals(1:3:24)))
````

````@ansi groupby
groupby(A, Ti=>Bins(yearhour, 12))
````

Lets group into 8 day blocks using `ranges`.

````@ansi groupby
groupby(A, Ti=>Bins(dayofyear, ranges(1:8:366)))
````

## Group by Dims.

````@ansi groupby
groupby(A, dims(A, Ti))
````



_TODO: Apply custom function (i.e. normalization) to grouped output._
