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

## hour

````@ansi groupby
hour.(tempo)
````

These do similar things with other time periods

## dayofweek

````@ansi groupby
dayofweek.(tempo)
````

## month

````@ansi groupby
month.(tempo)
````

## dayofyear

````@ansi groupby
dayofyear.(tempo)
````

## Tuple grouping

Some functions return a tuple - we can also use tuples for grouping.
They are sorted by the left to right values.

## yearmonth

````@ansi groupby
yearmonth.(tempo)
````

We can create our own anonymous function that return tuples

````@example groupby
yearday(x) = year(x), dayofyear(x)
yearhour(x) = year(x), hour(x)
````

And you can probably guess what they do:

````@ansi groupby
yearday.(tempo)
````

All of these functions can be used in `groupby` on `DateTime` objects.


# Grouping and reducing

Now lets define an array

````@ansi groupby
A = rand(X(1:0.01:2), Ti(tempo))
````

Simple groupbys using the functions from above

````@ansi groupby
group = groupby(A, Ti=>month)
````

We take the mean of each group by broadcasting over the group

````@ansi groupby
mean.(group)
````

Here are some more examples

````@ansi groupby
sum.(groupby(A, Ti=>dayofyear)) # it will combine the same day from different year.
````

````@ansi groupby
maximum.(groupby(A, Ti=>yearmonthday)) # this does the a daily mean aggregation.
````

````@ansi groupby
minimum.(groupby(A, Ti=>yearmonth)) # this does a monthly mean aggregation
````

````@ansi groupby
median.(groupby(A, Ti=>Dates.hour12))
````

We can also use the function we defined above

````@ansi groupby
mean.(groupby(A, Ti=>yearday)) # this does a daily mean aggregation
````

# Binning

Sometimes we want to further aggregate our groups after running a function,
or just bin the raw data directly. We can use the [`Bins`](@ref) wrapper to 
do this.

When our function returns an `Int`, we can just use a range of values we want to keep:

````@ansi groupby
mean.(groupby(A, Ti=>Bins(month, 1:2))) 
````

````@ansi groupby
mean.(groupby(A, Ti=>Bins(month, [1, 3, 5]))) 
````

Or an array of arrays

````@ansi groupby
mean.(groupby(A, Ti => Bins(yearday, [[1,2,3], [4,5,6]], labels=x -> join(string.(x), ','))))
````

The `ranges` function is a helper for creating these bin groupings

````@ansi groupby
ranges(1:8:370)
````

````@ansi groupby
mean.(groupby(A, Ti => Bins(dayofyear, ranges(1:8:370))))
````

````@ansi groupby
mean.(groupby(A, Ti => season(; start=December))) 
````

````@ansi groupby
mean.(groupby(A, Ti => hours(12; start=6, labels=x -> 6 in x ? :night : :day)))
````

## select by month, days, years and seasons

How do we select month 1 or 2, and even a group of them, i.e. [1,3,5]? Same for days, years and seasons.

Use three-month bins. The 13 is the open side of the last interval.

````@ansi groupby
mean.(groupby(A, Ti=>Bins(yearmonth, intervals(1:3:12))))
````

````@ansi groupby
mean.(groupby(A, Ti=>Bins(month, 4))) # is combining month from different years
````

# Select by [`Dimension`](@ref)

````@ansi groupby
A
B = 
A[:, 1:3:100]
C = mean.(groupby(A, B))
@assert size(A) == size(B)
````

How do could we incorporate resample? Let's say if we have hour resolution I want to resample every 3,6,12.. hours?

````@ansi groupby
mean.(groupby(A, Ti=>Bins(yearhour, intervals(1:3:24)))) # it will combine the same day from different year.
````

````@ansi groupby
mean.(groupby(A, Ti=>Bins(yearhour, 12))) # this does a daily mean aggregation
````

Similar to the hourly resample, how do we do it for more than 1 day, let's say 8daily?

````@ansi groupby
mean.(groupby(A, Ti=>Bins(dayofyear, map(x -> x:x+7, 1:8:370))))
````

## Group by Dims. 
This should include the rasters input sampling.

````@ansi groupby
mean.(groupby(A, dims(A, Ti)))
````

## Apply custom function (i.e. normalization) to grouped output.
