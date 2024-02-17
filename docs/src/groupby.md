# groupby

## Basics: DateTime operations we can use for grouping

````@example groupby
using DimensionalData
using Dates
using Statistics
const DD = DimensionalData
````

First lets look at the kind of functions that can be used to group `DateTime`.
Other types will follow the same principles, but are usually simpler.

Create a demo `DateTime` range

````@ansi groupby
tempo = range(DateTime(2000), step=Hour(1), length=365*24*2)
````

Now lets see how some common functions work.

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

We can creat our own anonymous function that return tuples

````@example groupby
yearday(x) = year(x), dayofyear(x)
yearhour(x) = year(x), hour(x)
````

And you can probably guess what they do:

````@ansi groupby
yearday.(tempo)
````

All of these functions can be used in `groupby` on `DateTime` objects.

# Practical example: grouping by season

## groupby operations

Here we use the same time functions from above

````@ansi groupby
ds = rand(X(1:0.01:2), Ti(tempo))
````

## select by month, days, years and seasons

How do we select month 1 or 2, and even a group of them, i.e. [1,3,5]? Same for days, years and seasons.

````@ansi groupby
mean.(groupby(ds, Ti=>Bins(month, 1:2))) 
````

````@ansi groupby
mean.(groupby(ds, Ti=>Bins(month, [1, 3, 5]))) 
````

````@ansi groupby
mean.(groupby(ds, Ti => season(; start=December))) 
````

````@ansi groupby
mean.(groupby(ds, Ti => Bins(dayofyear, intervals(1:8:370))))
````

````@ansi groupby
mean.(groupby(ds, Ti => Bins(yearday, [[1,2,3], [4,5,6]], labels=x -> join(string.(x), ','))))
````

````@ansi groupby
mean.(groupby(ds, Ti => week))
````

````@ansi groupby
mean.(groupby(ds, Ti => hours(12; start=6, labels=x -> 6 in x ? :night : :day)))
````

````@ansi groupby
mean.(groupby(ds, Ti => dims(ds, Ti)))
````

We need a new function that can return DJF (Dec-Jan-Feb), MAM (Mar-Apr-May)... etc.

THIS IS HARD. We need a succinct way to select around the end-start of the year. 

is combining month from different years

````@ansi groupby
mean.(groupby(ds, Ti=>month)) 
````

Use three-month bins. The 13 is the open side of the last interval.

````@ansi groupby
mean.(groupby(ds, Ti=>Bins(yearmonth, intervals(1:3:12))))
````

````@ansi groupby
mean.(groupby(ds, Ti=>Bins(month, 4))) # is combining month from different years
````

````@ansi groupby
mean.(groupby(ds, Ti=>year))
````

````@ansi groupby
mean.(groupby(ds, Ti=>yearmonth))
````

````@ansi groupby
mean.(groupby(ds, Ti=>hour))
````

````@ansi groupby
mean.(groupby(ds, Ti=>Dates.hour12))
````

How do could we incorporate resample? Let's say if we have hour resolution I want to resample every 3,6,12.. hours?

````@ansi groupby
mean.(groupby(ds, Ti=>Bins(yearhour, intervals(1:3:24)))) # it will combine the same day from different year.
````

````@ansi groupby
mean.(groupby(ds, Ti=>dayofyear)) # it will combine the same day from different year.
````

````@ansi groupby
mean.(groupby(ds, Ti=>yearmonthday)) # this does the a daily mean aggregation.
````

````@ansi groupby
mean.(groupby(ds, Ti=>yearmonth)) # this does a monthly mean aggregation
````

````@ansi groupby
mean.(groupby(ds, Ti=>yearday)) # this does a daily mean aggregation
````

````@ansi groupby
mean.(groupby(ds, Ti=>Bins(yearhour, 12))) # this does a daily mean aggregation
````

Similar to the hourly resample, how do we do it for more than 1 day, let's say 8daily?

````@ansi groupby
mean.(groupby(ds, Ti=>Bins(dayofyear, map(x -> x:x+7, 1:8:370))))
````

## Group by Dims. 
This should include the rasters input sampling.

````@ansi groupby
mean.(groupby(ds, dims(ds, Ti)))
````

## Apply custom function (i.e. normalization) to grouped output.
