
# Group By {#Group-By}

DimensionalData.jl provides a `groupby` function for dimensional grouping. This guide covers:
- simple grouping with a function
  
- grouping with `Bins`
  
- grouping with another existing `AbstractDimArray` or `Dimension`
  

## Grouping functions {#Grouping-functions}

Let&#39;s look at the kind of functions that can be used to group `DateTime`. Other types will follow the same principles, but are usually simpler.

First, load some packages:

```julia
using DimensionalData
using Dates
using Statistics
const DD = DimensionalData
```


Now create a demo `DateTime` range

```julia
julia> tempo = range(DateTime(2000), step=Hour(1), length=365*24*2)
```

```ansi
DateTime("2000-01-01T00:00:00"):Hour(1):DateTime("2001-12-30T23:00:00")
```


Let&#39;s see how some common functions work.

The `hour` function will transform values to the hour of the day - the integers `0:23`

:::tabs

== hour

```julia
julia> hour.(tempo)
```

```ansi
17520-element Vector{Int64}:
  0
  1
  2
  3
  4
  5
  6
  7
  8
  9
  ⋮
 15
 16
 17
 18
 19
 20
 21
 22
 23
```


== day

```julia
julia> day.(tempo)
```

```ansi
17520-element Vector{Int64}:
  1
  1
  1
  1
  1
  1
  1
  1
  1
  1
  ⋮
 30
 30
 30
 30
 30
 30
 30
 30
 30
```


== month

```julia
julia> month.(tempo)
```

```ansi
17520-element Vector{Int64}:
  1
  1
  1
  1
  1
  1
  1
  1
  1
  1
  ⋮
 12
 12
 12
 12
 12
 12
 12
 12
 12
```


== dayofweek

```julia
julia> dayofweek.(tempo)
```

```ansi
17520-element Vector{Int64}:
 6
 6
 6
 6
 6
 6
 6
 6
 6
 6
 ⋮
 7
 7
 7
 7
 7
 7
 7
 7
 7
```


== dayofyear

```julia
julia> dayofyear.(tempo)
```

```ansi
17520-element Vector{Int64}:
   1
   1
   1
   1
   1
   1
   1
   1
   1
   1
   ⋮
 364
 364
 364
 364
 364
 364
 364
 364
 364
```


:::

Tuple groupings

::: tabs

== yearmonth

```julia
julia> yearmonth.(tempo)
```

```ansi
17520-element Vector{Tuple{Int64, Int64}}:
 (2000, 1)
 (2000, 1)
 (2000, 1)
 (2000, 1)
 (2000, 1)
 (2000, 1)
 (2000, 1)
 (2000, 1)
 (2000, 1)
 (2000, 1)
 ⋮
 (2001, 12)
 (2001, 12)
 (2001, 12)
 (2001, 12)
 (2001, 12)
 (2001, 12)
 (2001, 12)
 (2001, 12)
 (2001, 12)
```


== yearmonthday

```julia
julia> yearmonthday.(tempo)
```

```ansi
17520-element Vector{Tuple{Int64, Int64, Int64}}:
 (2000, 1, 1)
 (2000, 1, 1)
 (2000, 1, 1)
 (2000, 1, 1)
 (2000, 1, 1)
 (2000, 1, 1)
 (2000, 1, 1)
 (2000, 1, 1)
 (2000, 1, 1)
 (2000, 1, 1)
 ⋮
 (2001, 12, 30)
 (2001, 12, 30)
 (2001, 12, 30)
 (2001, 12, 30)
 (2001, 12, 30)
 (2001, 12, 30)
 (2001, 12, 30)
 (2001, 12, 30)
 (2001, 12, 30)
```


== custom

We can create our own function that returns tuples

```julia
yearday(x) = (year(x), dayofyear(x))
```


You can probably guess what it does:

```julia
julia> yearday.(tempo)
```

```ansi
17520-element Vector{Tuple{Int64, Int64}}:
 (2000, 1)
 (2000, 1)
 (2000, 1)
 (2000, 1)
 (2000, 1)
 (2000, 1)
 (2000, 1)
 (2000, 1)
 (2000, 1)
 (2000, 1)
 ⋮
 (2001, 364)
 (2001, 364)
 (2001, 364)
 (2001, 364)
 (2001, 364)
 (2001, 364)
 (2001, 364)
 (2001, 364)
 (2001, 364)
```


:::

## Grouping and reducing {#Grouping-and-reducing}

Let&#39;s define an array with a time dimension of the times used above:

```julia
julia> A = rand(X(1:0.01:2), Ti(tempo))
```

```ansi
[90m┌ [39m[38;5;209m101[39m×[38;5;32m17520[39m DimArray{Float64, 2}[90m ┐[39m
[90m├────────────────────────────────┴─────────────────────────────────────── dims ┐[39m
  [38;5;209m↓ [39m[38;5;209mX[39m Sampled{Float64} [38;5;209m1.0:0.01:2.0[39m [38;5;244mForwardOrdered[39m [38;5;244mRegular[39m [38;5;244mPoints[39m,
  [38;5;32m→ [39m[38;5;32mTi[39m Sampled{DateTime} [38;5;32mDateTime("2000-01-01T00:00:00"):Hour(1):DateTime("2001-12-30T23:00:00")[39m [38;5;244mForwardOrdered[39m [38;5;244mRegular[39m [38;5;244mPoints[39m
[90m└──────────────────────────────────────────────────────────────────────────────┘[39m
 [38;5;209m↓[39m [38;5;32m→[39m    [38;5;32m2000-01-01T00:00:00[39m   [38;5;32m2000-01-01T01:00:00[39m  …   [38;5;32m2001-12-30T23:00:00[39m
 [38;5;209m1.0[39m   0.89757               0.795755                 0.905858
 [38;5;209m1.01[39m  0.969026              0.785993                 0.477727
 [38;5;209m1.02[39m  0.106472              0.646867                 0.807257
 [38;5;209m1.03[39m  0.283631              0.905428                 0.0958593
 ⋮                                                 ⋱  ⋮
 [38;5;209m1.97[39m  0.830655              0.673995                 0.244589
 [38;5;209m1.98[39m  0.445628              0.54935                  0.00358622
 [38;5;209m1.99[39m  0.571899              0.310328              …  0.355619
 [38;5;209m2.0[39m   0.488519              0.359731                 0.328946
```


::: tabs

== basic

Group by month, using the `month` function:

```julia
julia> groups = groupby(A, Ti=>month)
```

```ansi
[90m┌ [39m[38;5;209m12-element [39mDimGroupByArray{DimArray{Float64,2},1}[90m ┐[39m
[90m├───────────────────────────────────────────────────┴──────── dims ┐[39m
  [38;5;209m↓ [39m[38;5;209mTi[39m Sampled{Int64} [38;5;209m[1, …, 12][39m [38;5;244mForwardOrdered[39m [38;5;244mIrregular[39m [38;5;244mPoints[39m
[90m├──────────────────────────────────────────────────────── metadata ┤[39m
  Dict{Symbol, Any} with 1 entry:
  :groupby => :Ti=>month
[90m├───────────────────────────────────────────────────┴── group dims ┐[39m
  [38;5;32m↓ [39m[38;5;32mX[39m, [38;5;209m→ [39m[38;5;209mTi[39m
[90m└──────────────────────────────────────────────────────────────────┘[39m
  [38;5;209m1[39m  [38;5;32m101[39m×[38;5;209m1488[39m DimArray
  [38;5;209m2[39m  [38;5;32m101[39m×[38;5;209m1368[39m DimArray
  ⋮
 [38;5;209m12[39m  [38;5;32m101[39m×[38;5;209m1464[39m DimArray
```


We can take the mean of each group by broadcasting over them:

```julia
julia> mean.(groups)
```

```ansi
[90m┌ [39m[38;5;209m12-element [39mDimArray{Float64, 1}[90m ┐[39m
[90m├─────────────────────────────────┴────────────────────────── dims ┐[39m
  [38;5;209m↓ [39m[38;5;209mTi[39m Sampled{Int64} [38;5;209m[1, …, 12][39m [38;5;244mForwardOrdered[39m [38;5;244mIrregular[39m [38;5;244mPoints[39m
[90m├──────────────────────────────────────────────────────── metadata ┤[39m
  Dict{Symbol, Any} with 1 entry:
  :groupby => :Ti=>month
[90m└──────────────────────────────────────────────────────────────────┘[39m
  [38;5;209m1[39m  0.49998
  [38;5;209m2[39m  0.499823
  [38;5;209m3[39m  0.499881
  ⋮
 [38;5;209m10[39m  0.499447
 [38;5;209m11[39m  0.500349
 [38;5;209m12[39m  0.499943
```


== sum dayofyear

```julia
julia> sum.(groupby(A, Ti=>dayofyear))
```

```ansi
[90m┌ [39m[38;5;209m366-element [39mDimArray{Float64, 1}[90m ┐[39m
[90m├──────────────────────────────────┴────────────────────────── dims ┐[39m
  [38;5;209m↓ [39m[38;5;209mTi[39m Sampled{Int64} [38;5;209m[1, …, 366][39m [38;5;244mForwardOrdered[39m [38;5;244mIrregular[39m [38;5;244mPoints[39m
[90m├───────────────────────────────────────────────────────── metadata ┤[39m
  Dict{Symbol, Any} with 1 entry:
  :groupby => :Ti=>dayofyear
[90m└───────────────────────────────────────────────────────────────────┘[39m
   [38;5;209m1[39m  2402.82
   [38;5;209m2[39m  2412.16
   [38;5;209m3[39m  2429.79
   ⋮
 [38;5;209m364[39m  2449.36
 [38;5;209m365[39m  1224.82
 [38;5;209m366[39m  1224.13
```


== maximum yearmonthday

```julia
julia> maximum.(groupby(A, Ti=>yearmonthday))
```

```ansi
[90m┌ [39m[38;5;209m730-element [39mDimArray{Float64, 1}[90m ┐[39m
[90m├──────────────────────────────────┴───────────────────────────────────── dims ┐[39m
  [38;5;209m↓ [39m[38;5;209mTi[39m Sampled{Tuple{Int64, Int64, Int64}} [38;5;209m[(2000, 1, 1), …, (2001, 12, 30)][39m [38;5;244mForwardOrdered[39m [38;5;244mIrregular[39m [38;5;244mPoints[39m
[90m├──────────────────────────────────────────────────────────────────── metadata ┤[39m
  Dict{Symbol, Any} with 1 entry:
  :groupby => :Ti=>yearmonthday
[90m└──────────────────────────────────────────────────────────────────────────────┘[39m
 [38;5;209m(2000, 1, 1)[39m    0.999203
 [38;5;209m(2000, 1, 2)[39m    0.999631
 [38;5;209m(2000, 1, 3)[39m    0.999599
 ⋮
 [38;5;209m(2001, 12, 28)[39m  0.999679
 [38;5;209m(2001, 12, 29)[39m  0.999253
 [38;5;209m(2001, 12, 30)[39m  0.999792
```


== minimum yearmonth

```julia
julia> minimum.(groupby(A, Ti=>yearmonth))
```

```ansi
[90m┌ [39m[38;5;209m24-element [39mDimArray{Float64, 1}[90m ┐[39m
[90m├─────────────────────────────────┴────────────────────────────────────── dims ┐[39m
  [38;5;209m↓ [39m[38;5;209mTi[39m Sampled{Tuple{Int64, Int64}} [38;5;209m[(2000, 1), …, (2001, 12)][39m [38;5;244mForwardOrdered[39m [38;5;244mIrregular[39m [38;5;244mPoints[39m
[90m├──────────────────────────────────────────────────────────────────── metadata ┤[39m
  Dict{Symbol, Any} with 1 entry:
  :groupby => :Ti=>yearmonth
[90m└──────────────────────────────────────────────────────────────────────────────┘[39m
 [38;5;209m(2000, 1)[39m   2.9194e-7
 [38;5;209m(2000, 2)[39m   4.5472e-7
 [38;5;209m(2000, 3)[39m   1.70086e-5
 ⋮
 [38;5;209m(2001, 10)[39m  7.92708e-10
 [38;5;209m(2001, 11)[39m  4.27053e-6
 [38;5;209m(2001, 12)[39m  6.1939e-7
```


== median hour

```julia
julia> median.(groupby(A, Ti=>hour))
```

```ansi
[90m┌ [39m[38;5;209m24-element [39mDimArray{Float64, 1}[90m ┐[39m
[90m├─────────────────────────────────┴────────────────────────── dims ┐[39m
  [38;5;209m↓ [39m[38;5;209mTi[39m Sampled{Int64} [38;5;209m[0, …, 23][39m [38;5;244mForwardOrdered[39m [38;5;244mIrregular[39m [38;5;244mPoints[39m
[90m├──────────────────────────────────────────────────────── metadata ┤[39m
  Dict{Symbol, Any} with 1 entry:
  :groupby => :Ti=>hour
[90m└──────────────────────────────────────────────────────────────────┘[39m
  [38;5;209m0[39m  0.498939
  [38;5;209m1[39m  0.499892
  [38;5;209m2[39m  0.502394
  ⋮
 [38;5;209m21[39m  0.500885
 [38;5;209m22[39m  0.497537
 [38;5;209m23[39m  0.499347
```


== mean yearday

We can also use the function we defined above

```julia
julia> mean.(groupby(A, Ti=>yearday))
```

```ansi
[90m┌ [39m[38;5;209m730-element [39mDimArray{Float64, 1}[90m ┐[39m
[90m├──────────────────────────────────┴───────────────────────────────────── dims ┐[39m
  [38;5;209m↓ [39m[38;5;209mTi[39m Sampled{Tuple{Int64, Int64}} [38;5;209m[(2000, 1), …, (2001, 364)][39m [38;5;244mForwardOrdered[39m [38;5;244mIrregular[39m [38;5;244mPoints[39m
[90m├──────────────────────────────────────────────────────────────────── metadata ┤[39m
  Dict{Symbol, Any} with 1 entry:
  :groupby => :Ti=>yearday
[90m└──────────────────────────────────────────────────────────────────────────────┘[39m
 [38;5;209m(2000, 1)[39m    0.494279
 [38;5;209m(2000, 2)[39m    0.498469
 [38;5;209m(2000, 3)[39m    0.503306
 ⋮
 [38;5;209m(2001, 362)[39m  0.506314
 [38;5;209m(2001, 363)[39m  0.495833
 [38;5;209m(2001, 364)[39m  0.506707
```


:::

## Binning {#Binning}

Sometimes we want to further aggregate our groups after running a function, or just bin the raw data directly. We can use the [`Bins`](/api/reference#DimensionalData.Bins) wrapper to do this.

::: tabs

== evenly spaced

For quick analysis, we can break our groups into `N` bins.

```julia
julia> groupby(A, Ti=>Bins(month, 4))
```

```ansi
[90m┌ [39m[38;5;209m4-element [39mDimGroupByArray{DimArray{Float64,2},1}[90m ┐[39m
[90m├──────────────────────────────────────────────────┴───────────────────── dims ┐[39m
  [38;5;209m↓ [39m[38;5;209mTi[39m Sampled{IntervalSets.Interval{:closed, :open, Float64}} [38;5;209m[1.0 .. 3.75275 (closed-open), …, 9.25825 .. 12.011 (closed-open)][39m [38;5;244mForwardOrdered[39m [38;5;244mIrregular[39m [38;5;244mIntervals{Start}[39m
[90m├──────────────────────────────────────────────────────────────────── metadata ┤[39m
  Dict{Symbol, Any} with 1 entry:
  :groupby => :Ti=>Bins(month, 4)…
[90m├──────────────────────────────────────────────────┴─────────────── group dims ┐[39m
  [38;5;32m↓ [39m[38;5;32mX[39m, [38;5;209m→ [39m[38;5;209mTi[39m
[90m└──────────────────────────────────────────────────────────────────────────────┘[39m
 [38;5;209m1.0 .. 3.75275 (closed-open)[39m     [38;5;32m101[39m×[38;5;209m4344[39m DimArray
 ⋮
 [38;5;209m9.25825 .. 12.011 (closed-open)[39m  [38;5;32m101[39m×[38;5;209m4392[39m DimArray
```


Doing this requires slightly padding the bin edges, so the lookup of the output is less than ideal.

== specific values as bins

When our function returns an `Int`, we can use a range of values we want to keep:

```julia
julia> mean.(groupby(A, Ti=>Bins(month, 1:2)))
```

```ansi
[90m┌ [39m[38;5;209m2-element [39mDimArray{Float64, 1}[90m ┐[39m
[90m├────────────────────────────────┴────────────────── dims ┐[39m
  [38;5;209m↓ [39m[38;5;209mTi[39m Sampled{Int64} [38;5;209m1:2[39m [38;5;244mForwardOrdered[39m [38;5;244mRegular[39m [38;5;244mPoints[39m
[90m├─────────────────────────────────────────────── metadata ┤[39m
  Dict{Symbol, Any} with 1 entry:
  :groupby => :Ti=>Bins(month, 1:2)…
[90m└─────────────────────────────────────────────────────────┘[39m
 [38;5;209m1[39m  0.49998
 [38;5;209m2[39m  0.499823
```


== selected month bins

```julia
julia> mean.(groupby(A, Ti=>Bins(month, [1, 3, 5])))
```

```ansi
[90m┌ [39m[38;5;209m3-element [39mDimArray{Float64, 1}[90m ┐[39m
[90m├────────────────────────────────┴────────────────────────── dims ┐[39m
  [38;5;209m↓ [39m[38;5;209mTi[39m Sampled{Int64} [38;5;209m[1, …, 5][39m [38;5;244mForwardOrdered[39m [38;5;244mIrregular[39m [38;5;244mPoints[39m
[90m├─────────────────────────────────────────────────────── metadata ┤[39m
  Dict{Symbol, Any} with 1 entry:
  :groupby => :Ti=>Bins(month, [1, 3, 5])…
[90m└─────────────────────────────────────────────────────────────────┘[39m
 [38;5;209m1[39m  0.49998
 [38;5;209m3[39m  0.499881
 [38;5;209m5[39m  0.501052
```


== bin groups

We can also specify an `AbstractArray` of grouping `AbstractArray`: Here we group by month, and bin the summer and winter months:

```julia
julia> groupby(A, Ti => Bins(month, [[12, 1, 2], [6, 7, 8]]; labels=x -> string.(x)))
```

```ansi
[90m┌ [39m[38;5;209m2-element [39mDimGroupByArray{DimArray{Float64,2},1}[90m ┐[39m
[90m├──────────────────────────────────────────────────┴───────────────────── dims ┐[39m
  [38;5;209m↓ [39m[38;5;209mTi[39m Sampled{Vector{String}} [38;5;209m[["12", "1", "2"], ["6", "7", "8"]][39m [38;5;244mForwardOrdered[39m [38;5;244mIrregular[39m [38;5;244mPoints[39m
[90m├──────────────────────────────────────────────────────────────────── metadata ┤[39m
  Dict{Symbol, Any} with 1 entry:
  :groupby => :Ti=>Bins(month, [[12, 1, 2], [6, 7, 8]])…
[90m├──────────────────────────────────────────────────┴─────────────── group dims ┐[39m
  [38;5;32m↓ [39m[38;5;32mX[39m, [38;5;209m→ [39m[38;5;209mTi[39m
[90m└──────────────────────────────────────────────────────────────────────────────┘[39m
 [38;5;209m["12", "1", "2"][39m  [38;5;32m101[39m×[38;5;209m4320[39m DimArray
 [38;5;209m["6", "7", "8"][39m   [38;5;32m101[39m×[38;5;209m4416[39m DimArray
```


== range bins

First, let&#39;s see what [`ranges`](/api/reference#DimensionalData.ranges) does:

```julia
julia> ranges(1:8:370)
```

```ansi
47-element Vector{UnitRange{Int64}}:
 1:8
 9:16
 17:24
 25:32
 33:40
 41:48
 49:56
 57:64
 65:72
 73:80
 ⋮
 305:312
 313:320
 321:328
 329:336
 337:344
 345:352
 353:360
 361:368
 369:376
```


We can use this vector of ranges to group into blocks, here 8 days :

```julia
julia> groupby(A, Ti => Bins(dayofyear, ranges(1:8:370)))
```

```ansi
[90m┌ [39m[38;5;209m47-element [39mDimGroupByArray{DimArray{Float64,2},1}[90m ┐[39m
[90m├───────────────────────────────────────────────────┴──────────────────── dims ┐[39m
  [38;5;209m↓ [39m[38;5;209mTi[39m Sampled{UnitRange{Int64}} [38;5;209m[1:8, …, 369:376][39m [38;5;244mForwardOrdered[39m [38;5;244mIrregular[39m [38;5;244mPoints[39m
[90m├──────────────────────────────────────────────────────────────────── metadata ┤[39m
  Dict{Symbol, Any} with 1 entry:
  :groupby => :Ti=>Bins(dayofyear, UnitRange{Int64}[1:8, 9:16, 17:24, 25:32, 33…
[90m├───────────────────────────────────────────────────┴────────────── group dims ┐[39m
  [38;5;32m↓ [39m[38;5;32mX[39m, [38;5;209m→ [39m[38;5;209mTi[39m
[90m└──────────────────────────────────────────────────────────────────────────────┘[39m
 [38;5;209m1:8[39m      [38;5;32m101[39m×[38;5;209m384[39m DimArray
 ⋮
 [38;5;209m369:376[39m    [38;5;32m101[39m×[38;5;209m0[39m DimArray
```


Note: this only works where our function `dayofyear` returns values exactly `in` the ranges. `7.5` would not be included!

== intervals bins

Intervals is like ranges, but for taking all values in   an interval, not just discrete `Integer`s.

`intervals` returns closed-open `IntervalSets.Interval`:

```julia
julia> intervals(1:0.3:2)
```

```ansi
4-element Vector{IntervalSets.Interval{:closed, :open, Float64}}:
 1.0 .. 1.3 (closed-open)
 1.3 .. 1.6 (closed-open)
 1.6 .. 1.9 (closed-open)
 1.9 .. 2.2 (closed-open)
```


We can use this to bin the `Float64` values on the `X` axis:

```julia
julia> groups = groupby(A, X => Bins(intervals(1:0.3:2)))
```

```ansi
[90m┌ [39m[38;5;209m4-element [39mDimGroupByArray{DimArray{Float64,2},1}[90m ┐[39m
[90m├──────────────────────────────────────────────────┴───────────────────── dims ┐[39m
  [38;5;209m↓ [39m[38;5;209mX[39m Sampled{IntervalSets.Interval{:closed, :open, Float64}} [38;5;209m[1.0 .. 1.3 (closed-open), …, 1.9 .. 2.2 (closed-open)][39m [38;5;244mForwardOrdered[39m [38;5;244mIrregular[39m [38;5;244mIntervals{Start}[39m
[90m├──────────────────────────────────────────────────────────────────── metadata ┤[39m
  Dict{Symbol, Any} with 1 entry:
  :groupby => :X=>Bins(identity, Interval{:closed, :open, Float64}[1.0 .. 1.3 (…
[90m├──────────────────────────────────────────────────┴─────────────── group dims ┐[39m
  [38;5;209m↓ [39m[38;5;209mX[39m, [38;5;32m→ [39m[38;5;32mTi[39m
[90m└──────────────────────────────────────────────────────────────────────────────┘[39m
 [38;5;209m1.0 .. 1.3 (closed-open)[39m  [38;5;209m30[39m×[38;5;32m17520[39m DimArray
 ⋮
 [38;5;209m1.9 .. 2.2 (closed-open)[39m  [38;5;209m11[39m×[38;5;32m17520[39m DimArray
```


The lookup values of our final array are now `IntervalSets.Interval`:

```julia
julia> mean.(groups)
```

```ansi
[90m┌ [39m[38;5;209m4-element [39mDimArray{Float64, 1}[90m ┐[39m
[90m├────────────────────────────────┴─────────────────────────────────────── dims ┐[39m
  [38;5;209m↓ [39m[38;5;209mX[39m Sampled{IntervalSets.Interval{:closed, :open, Float64}} [38;5;209m[1.0 .. 1.3 (closed-open), …, 1.9 .. 2.2 (closed-open)][39m [38;5;244mForwardOrdered[39m [38;5;244mIrregular[39m [38;5;244mIntervals{Start}[39m
[90m├──────────────────────────────────────────────────────────────────── metadata ┤[39m
  Dict{Symbol, Any} with 1 entry:
  :groupby => :X=>Bins(identity, Interval{:closed, :open, Float64}[1.0 .. 1.3 (…
[90m└──────────────────────────────────────────────────────────────────────────────┘[39m
 [38;5;209m1.0 .. 1.3 (closed-open)[39m  0.499896
 [38;5;209m1.3 .. 1.6 (closed-open)[39m  0.499876
 [38;5;209m1.6 .. 1.9 (closed-open)[39m  0.49991
 [38;5;209m1.9 .. 2.2 (closed-open)[39m  0.500757
```


== seasons

There is a helper function for grouping by three-month seasons and getting nice keys for them: `seasons`. Note you have to call it, not just pass it!

```julia
julia> groupby(A, Ti => seasons())
```

```ansi
[90m┌ [39m[38;5;209m4-element [39mDimGroupByArray{DimArray{Float64,2},1}[90m ┐[39m
[90m├──────────────────────────────────────────────────┴───────────── dims ┐[39m
  [38;5;209m↓ [39m[38;5;209mTi[39m Categorical{Symbol} [38;5;209m[:Dec_Jan_Feb, …, :Sep_Oct_Nov][39m [38;5;244mUnordered[39m
[90m├──────────────────────────────────────────────────────────── metadata ┤[39m
  Dict{Symbol, Any} with 1 entry:
  :groupby => :Ti=>CyclicBins(month; cycle=12, step=3, start=12)…
[90m├──────────────────────────────────────────────────┴─────── group dims ┐[39m
  [38;5;32m↓ [39m[38;5;32mX[39m, [38;5;209m→ [39m[38;5;209mTi[39m
[90m└──────────────────────────────────────────────────────────────────────┘[39m
 [38;5;209m:Dec_Jan_Feb[39m  [38;5;32m101[39m×[38;5;209m4320[39m DimArray
 ⋮
 [38;5;209m:Sep_Oct_Nov[39m  [38;5;32m101[39m×[38;5;209m4368[39m DimArray
```


We could also start our seasons in January:

```julia
julia> groupby(A, Ti => seasons(; start=January))
```

```ansi
[90m┌ [39m[38;5;209m4-element [39mDimGroupByArray{DimArray{Float64,2},1}[90m ┐[39m
[90m├──────────────────────────────────────────────────┴───────────── dims ┐[39m
  [38;5;209m↓ [39m[38;5;209mTi[39m Categorical{Symbol} [38;5;209m[:Jan_Feb_Mar, …, :Oct_Nov_Dec][39m [38;5;244mUnordered[39m
[90m├──────────────────────────────────────────────────────────── metadata ┤[39m
  Dict{Symbol, Any} with 1 entry:
  :groupby => :Ti=>CyclicBins(month; cycle=12, step=3, start=1)…
[90m├──────────────────────────────────────────────────┴─────── group dims ┐[39m
  [38;5;32m↓ [39m[38;5;32mX[39m, [38;5;209m→ [39m[38;5;209mTi[39m
[90m└──────────────────────────────────────────────────────────────────────┘[39m
 [38;5;209m:Jan_Feb_Mar[39m  [38;5;32m101[39m×[38;5;209m4344[39m DimArray
 ⋮
 [38;5;209m:Oct_Nov_Dec[39m  [38;5;32m101[39m×[38;5;209m4392[39m DimArray
```


== months

We can also use `months` to group into arbitrary group sizes, starting wherever we like:

```julia
julia> groupby(A, Ti => months(2; start=6))
```

```ansi
[90m┌ [39m[38;5;209m6-element [39mDimGroupByArray{DimArray{Float64,2},1}[90m ┐[39m
[90m├──────────────────────────────────────────────────┴────────── dims ┐[39m
  [38;5;209m↓ [39m[38;5;209mTi[39m Categorical{Symbol} [38;5;209m[:Jun_Jul, …, :Apr_May][39m [38;5;244mUnordered[39m
[90m├───────────────────────────────────────────────────────── metadata ┤[39m
  Dict{Symbol, Any} with 1 entry:
  :groupby => :Ti=>CyclicBins(month; cycle=12, step=2, start=6)…
[90m├──────────────────────────────────────────────────┴──── group dims ┐[39m
  [38;5;32m↓ [39m[38;5;32mX[39m, [38;5;209m→ [39m[38;5;209mTi[39m
[90m└───────────────────────────────────────────────────────────────────┘[39m
 [38;5;209m:Jun_Jul[39m  [38;5;32m101[39m×[38;5;209m2928[39m DimArray
 ⋮
 [38;5;209m:Apr_May[39m  [38;5;32m101[39m×[38;5;209m2928[39m DimArray
```


== hours

`hours` works a lot like `months`. Here we group into day and night - two 12 hour blocks starting at 6am:

```julia
julia> groupby(A, Ti => hours(12; start=6, labels=x -> 6 in x ? :night : :day))
```

```ansi
[90m┌ [39m[38;5;209m2-element [39mDimGroupByArray{DimArray{Float64,2},1}[90m ┐[39m
[90m├──────────────────────────────────────────────────┴────────── dims ┐[39m
  [38;5;209m↓ [39m[38;5;209mTi[39m Categorical{Symbol} [38;5;209m[:night, :day][39m [38;5;244mReverseOrdered[39m
[90m├───────────────────────────────────────────────────────── metadata ┤[39m
  Dict{Symbol, Any} with 1 entry:
  :groupby => :Ti=>CyclicBins(hour; cycle=24, step=12, start=6)…
[90m├──────────────────────────────────────────────────┴──── group dims ┐[39m
  [38;5;32m↓ [39m[38;5;32mX[39m, [38;5;209m→ [39m[38;5;209mTi[39m
[90m└───────────────────────────────────────────────────────────────────┘[39m
 [38;5;209m:night[39m  [38;5;32m101[39m×[38;5;209m8760[39m DimArray
 [38;5;209m:day[39m    [38;5;32m101[39m×[38;5;209m8030[39m DimArray
```


:::

## Select by Dimension {#Select-by-Dimension}
- [`Dimension`](/api/dimensions#DimensionalData.Dimensions.Dimension)
  

We can also select by `Dimension`s and any objects with `dims` methods.

::: tabs

== groupby dims

Trivially, grouping by an object&#39;s own dimension is similar to `eachslice`:

```julia
julia> groupby(A, dims(A, Ti))
```

```ansi
[90m┌ [39m[38;5;209m17520-element [39mDimGroupByArray{DimArray{Float64,2},1}[90m ┐[39m
[90m├──────────────────────────────────────────────────────┴───────────────── dims ┐[39m
  [38;5;209m↓ [39m[38;5;209mTi[39m Sampled{DateTime} [38;5;209mDateTime("2000-01-01T00:00:00"):Hour(1):DateTime("2001-12-30T23:00:00")[39m [38;5;244mForwardOrdered[39m [38;5;244mRegular[39m [38;5;244mPoints[39m
[90m├──────────────────────────────────────────────────────────────────── metadata ┤[39m
  Dict{Symbol, Any} with 1 entry:
  :groupby => :Ti=>[DateTime("2000-01-01T00:00:00"), DateTime("2000-01-01T01:00…
[90m├──────────────────────────────────────────────────────┴─────────── group dims ┐[39m
  [38;5;32m↓ [39m[38;5;32mX[39m, [38;5;209m→ [39m[38;5;209mTi[39m
[90m└──────────────────────────────────────────────────────────────────────────────┘[39m
 [38;5;209m2000-01-01T00:00:00[39m  [38;5;32m101[39m×[38;5;209m1[39m DimArray
 [38;5;209m2000-01-01T01:00:00[39m  [38;5;32m101[39m×[38;5;209m1[39m DimArray
 ⋮
 [38;5;209m2001-12-30T23:00:00[39m  [38;5;32m101[39m×[38;5;209m1[39m DimArray
```


== groupby AbstractDimArray

But we can also group by other objects&#39; dimensions:

```julia
julia> B = A[:, 1:3:100]
```

```ansi
[90m┌ [39m[38;5;209m101[39m×[38;5;32m34[39m DimArray{Float64, 2}[90m ┐[39m
[90m├─────────────────────────────┴────────────────────────────────────────── dims ┐[39m
  [38;5;209m↓ [39m[38;5;209mX[39m Sampled{Float64} [38;5;209m1.0:0.01:2.0[39m [38;5;244mForwardOrdered[39m [38;5;244mRegular[39m [38;5;244mPoints[39m,
  [38;5;32m→ [39m[38;5;32mTi[39m Sampled{DateTime} [38;5;32mDateTime("2000-01-01T00:00:00"):Hour(3):DateTime("2000-01-05T03:00:00")[39m [38;5;244mForwardOrdered[39m [38;5;244mRegular[39m [38;5;244mPoints[39m
[90m└──────────────────────────────────────────────────────────────────────────────┘[39m
 [38;5;209m↓[39m [38;5;32m→[39m    [38;5;32m2000-01-01T00:00:00[39m   [38;5;32m2000-01-01T03:00:00[39m  …   [38;5;32m2000-01-05T03:00:00[39m
 [38;5;209m1.0[39m   0.89757               0.330905                 0.852021
 [38;5;209m1.01[39m  0.969026              0.473381                 0.0932722
 [38;5;209m1.02[39m  0.106472              0.078867                 0.934708
 [38;5;209m1.03[39m  0.283631              0.0916632                0.40218
 ⋮                                                 ⋱
 [38;5;209m1.97[39m  0.830655              0.480106                 0.45981
 [38;5;209m1.98[39m  0.445628              0.404168                 0.580082
 [38;5;209m1.99[39m  0.571899              0.19512               …  0.189668
 [38;5;209m2.0[39m   0.488519              0.53624                  0.537268
```

```julia
julia> C = mean.(groupby(A, B))
```

```ansi
[90m┌ [39m[38;5;209m101[39m×[38;5;32m34[39m DimArray{Float64, 2}[90m ┐[39m
[90m├─────────────────────────────┴────────────────────────────────────────── dims ┐[39m
  [38;5;209m↓ [39m[38;5;209mX[39m Sampled{Float64} [38;5;209m1.0:0.01:2.0[39m [38;5;244mForwardOrdered[39m [38;5;244mRegular[39m [38;5;244mPoints[39m,
  [38;5;32m→ [39m[38;5;32mTi[39m Sampled{DateTime} [38;5;32mDateTime("2000-01-01T00:00:00"):Hour(3):DateTime("2000-01-05T03:00:00")[39m [38;5;244mForwardOrdered[39m [38;5;244mRegular[39m [38;5;244mPoints[39m
[90m├──────────────────────────────────────────────────────────────────── metadata ┤[39m
  Dict{Symbol, Any} with 1 entry:
  :groupby => (:X=>[1.0, 1.01, 1.02, 1.03, 1.04, 1.05, 1.06, 1.07, 1.08, 1.09  …
[90m└──────────────────────────────────────────────────────────────────────────────┘[39m
 [38;5;209m↓[39m [38;5;32m→[39m    [38;5;32m2000-01-01T00:00:00[39m   [38;5;32m2000-01-01T03:00:00[39m  …   [38;5;32m2000-01-05T03:00:00[39m
 [38;5;209m1.0[39m   0.89757               0.330905                 0.852021
 [38;5;209m1.01[39m  0.969026              0.473381                 0.0932722
 ⋮                                                 ⋱
 [38;5;209m1.99[39m  0.571899              0.19512               …  0.189668
 [38;5;209m2.0[39m   0.488519              0.53624                  0.537268
```

```julia
julia> @assert size(C) == size(B)


```


:::

_TODO: Apply custom function (i.e. normalization) to grouped output._
