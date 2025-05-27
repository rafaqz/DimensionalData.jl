
# Selectors {#Selectors}

In addition to choosing dimensions by name, we can also select values within them.

First, we can create a `DimArray` with lookup values as well as dimension names:

```julia
using DimensionalData
```


```julia
julia> A = rand(X(1.0:0.2:2.0), Y([:a, :b, :c]))
```

```ansi
[90m┌ [39m[38;5;209m6[39m×[38;5;32m3[39m DimArray{Float64, 2}[90m ┐[39m
[90m├──────────────────────────┴───────────────────────────────── dims ┐[39m
  [38;5;209m↓ [39m[38;5;209mX[39m Sampled{Float64} [38;5;209m1.0:0.2:2.0[39m [38;5;244mForwardOrdered[39m [38;5;244mRegular[39m [38;5;244mPoints[39m,
  [38;5;32m→ [39m[38;5;32mY[39m Categorical{Symbol} [38;5;32m[:a, …, :c][39m [38;5;244mForwardOrdered[39m
[90m└──────────────────────────────────────────────────────────────────┘[39m
 [38;5;209m↓[39m [38;5;32m→[39m   [38;5;32m:a[39m        [38;5;32m:b[39m        [38;5;32m:c[39m
 [38;5;209m1.0[39m  0.127082  0.973847  0.0943594
 [38;5;209m1.2[39m  0.677743  0.406072  0.698462
 [38;5;209m1.4[39m  0.822783  0.874735  0.698995
 [38;5;209m1.6[39m  0.381692  0.751977  0.983399
 [38;5;209m1.8[39m  0.992013  0.806006  0.319013
 [38;5;209m2.0[39m  0.359758  0.376108  0.157175
```


Then we can use the [`Selector`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.Selector) to select values from the array:

::: tabs

== At

The [`At(x)`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.At) selector gets the index or indices exactly matching the passed in value(s). 

```julia
julia> A[X=At(1.2), Y=At(:c)]
```

```ansi
0.6984622051778979
```


Or within a tolerance:

```julia
julia> A[X=At(0.99:0.201:1.5; atol=0.05)]
```

```ansi
[90m┌ [39m[38;5;209m3[39m×[38;5;32m3[39m DimArray{Float64, 2}[90m ┐[39m
[90m├──────────────────────────┴───────────────────────────────────── dims ┐[39m
  [38;5;209m↓ [39m[38;5;209mX[39m Sampled{Float64} [38;5;209m[1.0, …, 1.4][39m [38;5;244mForwardOrdered[39m [38;5;244mIrregular[39m [38;5;244mPoints[39m,
  [38;5;32m→ [39m[38;5;32mY[39m Categorical{Symbol} [38;5;32m[:a, …, :c][39m [38;5;244mForwardOrdered[39m
[90m└──────────────────────────────────────────────────────────────────────┘[39m
 [38;5;209m↓[39m [38;5;32m→[39m   [38;5;32m:a[39m        [38;5;32m:b[39m        [38;5;32m:c[39m
 [38;5;209m1.0[39m  0.127082  0.973847  0.0943594
 [38;5;209m1.2[39m  0.677743  0.406072  0.698462
 [38;5;209m1.4[39m  0.822783  0.874735  0.698995
```


[`At`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.At) can also take vectors and ranges:

```julia
julia> A[X=At(1.2:0.2:1.5), Y=At([:a, :c])]
```

```ansi
[90m┌ [39m[38;5;209m2[39m×[38;5;32m2[39m DimArray{Float64, 2}[90m ┐[39m
[90m├──────────────────────────┴────────────────────────────────── dims ┐[39m
  [38;5;209m↓ [39m[38;5;209mX[39m Sampled{Float64} [38;5;209m[1.2, 1.4][39m [38;5;244mForwardOrdered[39m [38;5;244mIrregular[39m [38;5;244mPoints[39m,
  [38;5;32m→ [39m[38;5;32mY[39m Categorical{Symbol} [38;5;32m[:a, :c][39m [38;5;244mForwardOrdered[39m
[90m└───────────────────────────────────────────────────────────────────┘[39m
 [38;5;209m↓[39m [38;5;32m→[39m   [38;5;32m:a[39m        [38;5;32m:c[39m
 [38;5;209m1.2[39m  0.677743  0.698462
 [38;5;209m1.4[39m  0.822783  0.698995
```


== Near

The [`Near(x)`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.Near) selector gets the closest index to the passed in value(s), indexing with an `Int`.

```julia
julia> A[X=Near(1.245)]
```

```ansi
[90m┌ [39m[38;5;209m3-element [39mDimArray{Float64, 1}[90m ┐[39m
[90m├────────────────────────────────┴─────────────── dims ┐[39m
  [38;5;209m↓ [39m[38;5;209mY[39m Categorical{Symbol} [38;5;209m[:a, …, :c][39m [38;5;244mForwardOrdered[39m
[90m└──────────────────────────────────────────────────────┘[39m
 [38;5;209m:a[39m  0.677743
 [38;5;209m:b[39m  0.406072
 [38;5;209m:c[39m  0.698462
```


`Near` can also take vectors and ranges, which indexes with a `Vector{Int}`

```julia
julia> A[X=Near(1.1:0.25:1.5)]
```

```ansi
[90m┌ [39m[38;5;209m2[39m×[38;5;32m3[39m DimArray{Float64, 2}[90m ┐[39m
[90m├──────────────────────────┴────────────────────────────────── dims ┐[39m
  [38;5;209m↓ [39m[38;5;209mX[39m Sampled{Float64} [38;5;209m[1.2, 1.4][39m [38;5;244mForwardOrdered[39m [38;5;244mIrregular[39m [38;5;244mPoints[39m,
  [38;5;32m→ [39m[38;5;32mY[39m Categorical{Symbol} [38;5;32m[:a, …, :c][39m [38;5;244mForwardOrdered[39m
[90m└───────────────────────────────────────────────────────────────────┘[39m
 [38;5;209m↓[39m [38;5;32m→[39m   [38;5;32m:a[39m        [38;5;32m:b[39m        [38;5;32m:c[39m
 [38;5;209m1.2[39m  0.677743  0.406072  0.698462
 [38;5;209m1.4[39m  0.822783  0.874735  0.698995
```


== Contains

The [`Contains(x)`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.Contains) selector gets indices where the value x falls within an interval in the lookup. 

First, set the `X` axis to be `Intervals`:

```julia
julia> using DimensionalData.Lookups

julia> A_intervals = set(A, X => Intervals(Start()))
```

```ansi
[90m┌ [39m[38;5;209m6[39m×[38;5;32m3[39m DimArray{Float64, 2}[90m ┐[39m
[90m├──────────────────────────┴─────────────────────────────────────────── dims ┐[39m
  [38;5;209m↓ [39m[38;5;209mX[39m Sampled{Float64} [38;5;209m1.0:0.2:2.0[39m [38;5;244mForwardOrdered[39m [38;5;244mRegular[39m [38;5;244mIntervals{Start}[39m,
  [38;5;32m→ [39m[38;5;32mY[39m Categorical{Symbol} [38;5;32m[:a, …, :c][39m [38;5;244mForwardOrdered[39m
[90m└────────────────────────────────────────────────────────────────────────────┘[39m
 [38;5;209m↓[39m [38;5;32m→[39m   [38;5;32m:a[39m        [38;5;32m:b[39m        [38;5;32m:c[39m
 [38;5;209m1.0[39m  0.127082  0.973847  0.0943594
 [38;5;209m1.2[39m  0.677743  0.406072  0.698462
 [38;5;209m1.4[39m  0.822783  0.874735  0.698995
 [38;5;209m1.6[39m  0.381692  0.751977  0.983399
 [38;5;209m1.8[39m  0.992013  0.806006  0.319013
 [38;5;209m2.0[39m  0.359758  0.376108  0.157175
```

```julia
julia> intervalbounds(A_intervals, X)
```

```ansi
6-element Vector{Tuple{Float64, Float64}}:
 (1.0, 1.2)
 (1.2, 1.4)
 (1.4, 1.6)
 (1.6, 1.8)
 (1.8, 2.0)
 (2.0, 2.2)
```


With a single value, it is like indexing with `Int`

```julia
julia> A_intervals[X=Contains(1.245)]
```

```ansi
[90m┌ [39m[38;5;209m3-element [39mDimArray{Float64, 1}[90m ┐[39m
[90m├────────────────────────────────┴─────────────── dims ┐[39m
  [38;5;209m↓ [39m[38;5;209mY[39m Categorical{Symbol} [38;5;209m[:a, …, :c][39m [38;5;244mForwardOrdered[39m
[90m└──────────────────────────────────────────────────────┘[39m
 [38;5;209m:a[39m  0.677743
 [38;5;209m:b[39m  0.406072
 [38;5;209m:c[39m  0.698462
```


`Contains` can also take vectors and ranges, which is like indexing with `Vector{Int}`

```julia
julia> A_intervals[X=Contains(1.1:0.25:1.5)]
```

```ansi
[90m┌ [39m[38;5;209m2[39m×[38;5;32m3[39m DimArray{Float64, 2}[90m ┐[39m
[90m├──────────────────────────┴──────────────────────────────────────────── dims ┐[39m
  [38;5;209m↓ [39m[38;5;209mX[39m Sampled{Float64} [38;5;209m[1.0, 1.2][39m [38;5;244mForwardOrdered[39m [38;5;244mIrregular[39m [38;5;244mIntervals{Start}[39m,
  [38;5;32m→ [39m[38;5;32mY[39m Categorical{Symbol} [38;5;32m[:a, …, :c][39m [38;5;244mForwardOrdered[39m
[90m└─────────────────────────────────────────────────────────────────────────────┘[39m
 [38;5;209m↓[39m [38;5;32m→[39m   [38;5;32m:a[39m        [38;5;32m:b[39m        [38;5;32m:c[39m
 [38;5;209m1.0[39m  0.127082  0.973847  0.0943594
 [38;5;209m1.2[39m  0.677743  0.406072  0.698462
```


== ..

The `..` or `IntervalSets.Interval` selector selects a range of values: `..` is like indexing with a `UnitRange`:

```julia
julia> A[X=1.2 .. 1.6]
```

```ansi
[90m┌ [39m[38;5;209m3[39m×[38;5;32m3[39m DimArray{Float64, 2}[90m ┐[39m
[90m├──────────────────────────┴───────────────────────────────── dims ┐[39m
  [38;5;209m↓ [39m[38;5;209mX[39m Sampled{Float64} [38;5;209m1.2:0.2:1.6[39m [38;5;244mForwardOrdered[39m [38;5;244mRegular[39m [38;5;244mPoints[39m,
  [38;5;32m→ [39m[38;5;32mY[39m Categorical{Symbol} [38;5;32m[:a, …, :c][39m [38;5;244mForwardOrdered[39m
[90m└──────────────────────────────────────────────────────────────────┘[39m
 [38;5;209m↓[39m [38;5;32m→[39m   [38;5;32m:a[39m        [38;5;32m:b[39m        [38;5;32m:c[39m
 [38;5;209m1.2[39m  0.677743  0.406072  0.698462
 [38;5;209m1.4[39m  0.822783  0.874735  0.698995
 [38;5;209m1.6[39m  0.381692  0.751977  0.983399
```


```julia
julia> using IntervalSets

julia> A[X=OpenInterval(1.2 .. 1.6)]
```

```ansi
[90m┌ [39m[38;5;209m1[39m×[38;5;32m3[39m DimArray{Float64, 2}[90m ┐[39m
[90m├──────────────────────────┴───────────────────────────────── dims ┐[39m
  [38;5;209m↓ [39m[38;5;209mX[39m Sampled{Float64} [38;5;209m1.4:0.2:1.4[39m [38;5;244mForwardOrdered[39m [38;5;244mRegular[39m [38;5;244mPoints[39m,
  [38;5;32m→ [39m[38;5;32mY[39m Categorical{Symbol} [38;5;32m[:a, …, :c][39m [38;5;244mForwardOrdered[39m
[90m└──────────────────────────────────────────────────────────────────┘[39m
 [38;5;209m↓[39m [38;5;32m→[39m   [38;5;32m:a[39m        [38;5;32m:b[39m        [38;5;32m:c[39m
 [38;5;209m1.4[39m  0.822783  0.874735  0.698995
```


```julia
julia> A[X=Interval{:close,:open}(1.2 .. 1.6)]
```

```ansi
[90m┌ [39m[38;5;209m2[39m×[38;5;32m3[39m DimArray{Float64, 2}[90m ┐[39m
[90m├──────────────────────────┴───────────────────────────────── dims ┐[39m
  [38;5;209m↓ [39m[38;5;209mX[39m Sampled{Float64} [38;5;209m1.2:0.2:1.4[39m [38;5;244mForwardOrdered[39m [38;5;244mRegular[39m [38;5;244mPoints[39m,
  [38;5;32m→ [39m[38;5;32mY[39m Categorical{Symbol} [38;5;32m[:a, …, :c][39m [38;5;244mForwardOrdered[39m
[90m└──────────────────────────────────────────────────────────────────┘[39m
 [38;5;209m↓[39m [38;5;32m→[39m   [38;5;32m:a[39m        [38;5;32m:b[39m        [38;5;32m:c[39m
 [38;5;209m1.2[39m  0.677743  0.406072  0.698462
 [38;5;209m1.4[39m  0.822783  0.874735  0.698995
```


== Touches

The [`Touches`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.Touches) selector is like `..`, but for `Intervals`, it will include intervals touched by the selected interval, not inside it.

This usually means including zero, one, or two cells more than `..` `Touches` is like indexing with a `UnitRange`

```julia
julia> A_intervals[X=Touches(1.1, 1.5)]
```

```ansi
[90m┌ [39m[38;5;209m3[39m×[38;5;32m3[39m DimArray{Float64, 2}[90m ┐[39m
[90m├──────────────────────────┴─────────────────────────────────────────── dims ┐[39m
  [38;5;209m↓ [39m[38;5;209mX[39m Sampled{Float64} [38;5;209m1.0:0.2:1.4[39m [38;5;244mForwardOrdered[39m [38;5;244mRegular[39m [38;5;244mIntervals{Start}[39m,
  [38;5;32m→ [39m[38;5;32mY[39m Categorical{Symbol} [38;5;32m[:a, …, :c][39m [38;5;244mForwardOrdered[39m
[90m└────────────────────────────────────────────────────────────────────────────┘[39m
 [38;5;209m↓[39m [38;5;32m→[39m   [38;5;32m:a[39m        [38;5;32m:b[39m        [38;5;32m:c[39m
 [38;5;209m1.0[39m  0.127082  0.973847  0.0943594
 [38;5;209m1.2[39m  0.677743  0.406072  0.698462
 [38;5;209m1.4[39m  0.822783  0.874735  0.698995
```

```julia
julia> A_intervals[X=1.1 .. 1.5]
```

```ansi
[90m┌ [39m[38;5;209m1[39m×[38;5;32m3[39m DimArray{Float64, 2}[90m ┐[39m
[90m├──────────────────────────┴─────────────────────────────────────────── dims ┐[39m
  [38;5;209m↓ [39m[38;5;209mX[39m Sampled{Float64} [38;5;209m1.2:0.2:1.2[39m [38;5;244mForwardOrdered[39m [38;5;244mRegular[39m [38;5;244mIntervals{Start}[39m,
  [38;5;32m→ [39m[38;5;32mY[39m Categorical{Symbol} [38;5;32m[:a, …, :c][39m [38;5;244mForwardOrdered[39m
[90m└────────────────────────────────────────────────────────────────────────────┘[39m
 [38;5;209m↓[39m [38;5;32m→[39m   [38;5;32m:a[39m        [38;5;32m:b[39m        [38;5;32m:c[39m
 [38;5;209m1.2[39m  0.677743  0.406072  0.698462
```


== Where

The [`Where(f)`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.Where) selector filters the array axis by a function of the dimension index values.  `Where` is like indexing with a `Vector{Bool}`:

```julia
julia> A[X=Where(>=(1.5)), Y=Where(x -> x in (:a, :c))]
```

```ansi
[90m┌ [39m[38;5;209m3[39m×[38;5;32m2[39m DimArray{Float64, 2}[90m ┐[39m
[90m├──────────────────────────┴───────────────────────────────────── dims ┐[39m
  [38;5;209m↓ [39m[38;5;209mX[39m Sampled{Float64} [38;5;209m[1.6, …, 2.0][39m [38;5;244mForwardOrdered[39m [38;5;244mIrregular[39m [38;5;244mPoints[39m,
  [38;5;32m→ [39m[38;5;32mY[39m Categorical{Symbol} [38;5;32m[:a, :c][39m [38;5;244mForwardOrdered[39m
[90m└──────────────────────────────────────────────────────────────────────┘[39m
 [38;5;209m↓[39m [38;5;32m→[39m   [38;5;32m:a[39m        [38;5;32m:c[39m
 [38;5;209m1.6[39m  0.381692  0.983399
 [38;5;209m1.8[39m  0.992013  0.319013
 [38;5;209m2.0[39m  0.359758  0.157175
```


== Not

The `Not(x)` selector gets all indices _not_ selected by `x`, which can be another selector. `Not` is like indexing with a `Vector{Bool}`.

```julia
julia> A[X=Not(Near(1.3)), Y=Not(Where(in((:a, :c))))]
```

```ansi
[90m┌ [39m[38;5;209m5[39m×[38;5;32m1[39m DimArray{Float64, 2}[90m ┐[39m
[90m├──────────────────────────┴───────────────────────────────────── dims ┐[39m
  [38;5;209m↓ [39m[38;5;209mX[39m Sampled{Float64} [38;5;209m[1.0, …, 2.0][39m [38;5;244mForwardOrdered[39m [38;5;244mIrregular[39m [38;5;244mPoints[39m,
  [38;5;32m→ [39m[38;5;32mY[39m Categorical{Symbol} [38;5;32m[:b][39m [38;5;244mForwardOrdered[39m
[90m└──────────────────────────────────────────────────────────────────────┘[39m
 [38;5;209m↓[39m [38;5;32m→[39m   [38;5;32m:b[39m
 [38;5;209m1.0[39m  0.973847
 [38;5;209m1.2[39m  0.406072
 [38;5;209m1.6[39m  0.751977
 [38;5;209m1.8[39m  0.806006
 [38;5;209m2.0[39m  0.376108
```


:::

## Lookups {#Lookups}

Selectors find indices in the `Lookup` of each dimension. Lookups wrap other `AbstractArray` (often `AbstractRange`) but add additional traits to facilitate fast lookups or specifying point or interval behaviour. These are usually detected automatically.

```julia
using DimensionalData.Lookups
```


::: tabs

== Sampled lookups

The [`Sampled(x)`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.Sampled) lookup holds values sampled along an axis. They may be `Ordered`/`Unordered`, `Intervals`/`Points`, and `Regular`/`Irregular`.

Most of these properties are usually detected automatically, but here we create a `Sampled` lookup manually:

```julia
julia> l = Sampled(10.0:10.0:100.0; order=ForwardOrdered(), span=Regular(10.0), sampling=Intervals(Start()))
```

```ansi
Sampled{Float64} [38;5;244mForwardOrdered[39m [38;5;244mRegular[39m [38;5;244mIntervals{Start}[39m
[90mwrapping: [39m10.0:10.0:100.0
```


To specify `Irregular` `Intervals`, we should include the outer bounds of the lookup, as we can&#39;t determine them from the vector.

```julia
julia> l = Sampled([13, 8, 5, 3, 2, 1]; order=ForwardOrdered(), span=Irregular(1, 21), sampling=Intervals(Start()))
```

```ansi
Sampled{Int64} [38;5;244mForwardOrdered[39m [38;5;244mIrregular[39m [38;5;244mIntervals{Start}[39m
[90mwrapping: [39m6-element Vector{Int64}:
 13
  8
  5
  3
  2
  1
```


== Categorical lookup

The [`Categorical(x)`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.Categorical) lookup is a categorical lookup that holds categories, and may be ordered.

Create a [`Categorical`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.Categorical) lookup manually

```julia
julia> l = Categorical(["mon", "tue", "weds", "thur", "fri", "sat", "sun"]; order=Unordered())
```

```ansi
Categorical{String} [38;5;244mUnordered[39m
[90mwrapping: [39m7-element Vector{String}:
 "mon"
 "tue"
 "weds"
 "thur"
 "fri"
 "sat"
 "sun"
```


== Cyclic lookups

The [`Cyclic(x)`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.Cyclic) lookup is an `AbstractSampled` lookup for cyclical values.

Create a [`Cyclic`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.Cyclic) lookup that cycles over 12 months.

```julia
julia> using Dates

julia> l = Cyclic(DateTime(2000):Month(1):DateTime(2000, 12); cycle=Month(12), sampling=Intervals(Start()))
```

```ansi
Cyclic{DateTime} [38;5;244mAutoOrder[39m [38;5;244mAutoSpan[39m [38;5;244mIntervals{Start}[39m
[90mwrapping: [39mDateTime("2000-01-01T00:00:00"):Month(1):DateTime("2000-12-01T00:00:00")
```


There is a shorthand to make a `DimArray` from a `Dimension` with a function of the lookup values. Here we convert the values to the month names:

```julia
julia> A = DimArray(monthabbr, X(l))
```

```ansi
[90m┌ [39m[38;5;209m12-element [39mDimArray{String, 1}[38;5;37m monthabbr(X)[39m[90m ┐[39m
[90m├─────────────────────────────────────────────┴────────────────────────── dims ┐[39m
  [38;5;209m↓ [39m[38;5;209mX[39m Cyclic{DateTime} [38;5;209mDateTime("2000-01-01T00:00:00"):Month(1):DateTime("2000-12-01T00:00:00")[39m [38;5;244mForwardOrdered[39m [38;5;244mRegular[39m [38;5;244mIntervals{Start}[39m
[90m└──────────────────────────────────────────────────────────────────────────────┘[39m
 [38;5;209m2000-01-01T00:00:00[39m  "Jan"
 [38;5;209m2000-02-01T00:00:00[39m  "Feb"
 [38;5;209m2000-03-01T00:00:00[39m  "Mar"
 [38;5;209m2000-04-01T00:00:00[39m  "Apr"
 [38;5;209m2000-05-01T00:00:00[39m  "May"
 ⋮
 [38;5;209m2000-08-01T00:00:00[39m  "Aug"
 [38;5;209m2000-09-01T00:00:00[39m  "Sep"
 [38;5;209m2000-10-01T00:00:00[39m  "Oct"
 [38;5;209m2000-11-01T00:00:00[39m  "Nov"
 [38;5;209m2000-12-01T00:00:00[39m  "Dec"
```


Now we can select any date and get the month:

```julia
julia> A[At(DateTime(2005, 4))]
```

```ansi
"Apr"
```

```julia
julia> A[At(DateTime(3047, 9))]
```

```ansi
"Sep"
```


== NoLookup

The [`NoLookup(x)`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.NoLookup) lookup has no lookup values provided, so `Selector`s will not work. When you create a `DimArray` without a lookup array, `NoLookup` will be used. It is also not shown in REPL printing.

Here we create a [`NoLookup`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.NoLookup):

```julia
julia> l = NoLookup()
```

```ansi
NoLookup
```

```julia
julia> typeof(l)
```

```ansi
NoLookup{AutoValues}
```


Or even fill in the axis:

```julia
julia> l = NoLookup(Base.OneTo(10))
```

```ansi
NoLookup
```

```julia
julia> typeof(l)
```

```ansi
NoLookup{Base.OneTo{Int64}}
```


:::

## Lookup autodetection {#Lookup-autodetection}

When we define an array, extra properties are detected:

```julia
julia> A = DimArray(rand(7, 5), (X(10:10:70), Y([:a, :b, :c, :d, :e])))
```

```ansi
[90m┌ [39m[38;5;209m7[39m×[38;5;32m5[39m DimArray{Float64, 2}[90m ┐[39m
[90m├──────────────────────────┴──────────────────────────── dims ┐[39m
  [38;5;209m↓ [39m[38;5;209mX[39m Sampled{Int64} [38;5;209m10:10:70[39m [38;5;244mForwardOrdered[39m [38;5;244mRegular[39m [38;5;244mPoints[39m,
  [38;5;32m→ [39m[38;5;32mY[39m Categorical{Symbol} [38;5;32m[:a, …, :e][39m [38;5;244mForwardOrdered[39m
[90m└─────────────────────────────────────────────────────────────┘[39m
  [38;5;209m↓[39m [38;5;32m→[39m   [38;5;32m:a[39m        [38;5;32m:b[39m        [38;5;32m:c[39m        [38;5;32m:d[39m          [38;5;32m:e[39m
 [38;5;209m10[39m    0.444305  0.969079  0.101231  0.642658    0.522816
 [38;5;209m20[39m    0.184738  0.764895  0.339858  0.679337    0.227694
 [38;5;209m30[39m    0.772277  0.86273   0.973357  0.735544    0.389375
 [38;5;209m40[39m    0.711133  0.748041  0.925367  0.976465    0.0898635
 [38;5;209m50[39m    0.883222  0.621603  0.41767   0.48849     0.511313
 [38;5;209m60[39m    0.802776  0.768488  0.594101  0.956886    0.165145
 [38;5;209m70[39m    0.156538  0.869012  0.530389  0.00114293  0.87255
```


This array has a `Sampled` lookup with `ForwardOrdered` `Regular` `Points` for `X`, and a `Categorical` `ForwardOrdered` for `Y`.

Most lookup types and properties are detected automatically like this from the arrays and ranges used.
- Arrays and ranges of `String`, `Symbol`, and `Char` are set to `Categorical` lookup.
  - `order` is detected as `Unordered`, `ForwardOrdered`, or `ReverseOrdered`
    
  
- Arrays and ranges of `Number`, `DateTime`, and other things are set to `Sampled` lookups.
  - `order` is detected as `Unordered`, `ForwardOrdered`, or `ReverseOrdered`.
    
  - `sampling` is set to `Points()` unless the values are `IntervalSets.Interval`,   then `Intervals(Center())` is used.
    
  - `span` is detected as `Regular(step(range))` for `AbstractRange` and   `Irregular(nothing, nothing)` for other `AbstractArray`, where `nothing,   nothing` are the unknown outer bounds of the lookup. They are not needed   for `Points` as the outer values are the outer bounds. But they can be   specified manually for `Intervals`
    
  - Empty dimensions or dimension types are assigned `NoLookup()` ranges that   can&#39;t be used with selectors as they hold no values.
    
  

## `DimSelector` {#DimSelector}

We can also index with arrays of selectors [`DimSelectors`](/api/reference#DimensionalData.DimSelectors). These are like `CartesianIndices` or [`DimIndices`](/api/reference#DimensionalData.DimIndices), but holding the `Selectors` `At`, `Near`, or `Contains`.

```julia
julia> A = rand(X(1.0:0.2:2.0), Y(10:2:20))
```

```ansi
[90m┌ [39m[38;5;209m6[39m×[38;5;32m6[39m DimArray{Float64, 2}[90m ┐[39m
[90m├──────────────────────────┴───────────────────────────────── dims ┐[39m
  [38;5;209m↓ [39m[38;5;209mX[39m Sampled{Float64} [38;5;209m1.0:0.2:2.0[39m [38;5;244mForwardOrdered[39m [38;5;244mRegular[39m [38;5;244mPoints[39m,
  [38;5;32m→ [39m[38;5;32mY[39m Sampled{Int64} [38;5;32m10:2:20[39m [38;5;244mForwardOrdered[39m [38;5;244mRegular[39m [38;5;244mPoints[39m
[90m└──────────────────────────────────────────────────────────────────┘[39m
 [38;5;209m↓[39m [38;5;32m→[39m  [38;5;32m10[39m          [38;5;32m12[39m         [38;5;32m14[39m         [38;5;32m16[39m         [38;5;32m18[39m         [38;5;32m20[39m
 [38;5;209m1.0[39m   0.0928922   0.973622   0.229418   0.679453   0.21921    0.357367
 [38;5;209m1.2[39m   0.441181    0.942925   0.228248   0.442111   0.506221   0.246886
 [38;5;209m1.4[39m   0.621662    0.314906   0.749731   0.882656   0.680987   0.771237
 [38;5;209m1.6[39m   0.72217     0.196478   0.201129   0.683795   0.396585   0.0429074
 [38;5;209m1.8[39m   0.896257    0.791844   0.97293    0.12668    0.687921   0.870348
 [38;5;209m2.0[39m   0.301659    0.758149   0.883323   0.575595   0.647225   0.825204
```


We can define another array with partly matching indices

```julia
julia> B = rand(X(1.0:0.04:2.0), Y(20:-1:10))
```

```ansi
[90m┌ [39m[38;5;209m26[39m×[38;5;32m11[39m DimArray{Float64, 2}[90m ┐[39m
[90m├────────────────────────────┴──────────────────────────────── dims ┐[39m
  [38;5;209m↓ [39m[38;5;209mX[39m Sampled{Float64} [38;5;209m1.0:0.04:2.0[39m [38;5;244mForwardOrdered[39m [38;5;244mRegular[39m [38;5;244mPoints[39m,
  [38;5;32m→ [39m[38;5;32mY[39m Sampled{Int64} [38;5;32m20:-1:10[39m [38;5;244mReverseOrdered[39m [38;5;244mRegular[39m [38;5;244mPoints[39m
[90m└───────────────────────────────────────────────────────────────────┘[39m
 [38;5;209m↓[39m [38;5;32m→[39m   [38;5;32m20[39m          [38;5;32m19[39m         [38;5;32m18[39m         …  [38;5;32m12[39m         [38;5;32m11[39m         [38;5;32m10[39m
 [38;5;209m1.0[39m    0.11787     0.371583   0.400001      0.92906    0.337296   0.760043
 [38;5;209m1.04[39m   0.0905873   0.564657   0.986155      0.668806   0.466288   0.215999
 [38;5;209m1.08[39m   0.495624    0.952489   0.397388      0.208304   0.515929   0.467332
 [38;5;209m1.12[39m   0.263531    0.10454    0.074921      0.158368   0.624812   0.3926
 ⋮                                       ⋱              ⋮
 [38;5;209m1.88[39m   0.896624    0.630782   0.298791      0.212246   0.320737   0.216905
 [38;5;209m1.92[39m   0.823123    0.898833   0.542826      0.213848   0.312277   0.931705
 [38;5;209m1.96[39m   0.631878    0.429465   0.109509  …   0.737151   0.5053     0.997569
 [38;5;209m2.0[39m    0.29205     0.244582   0.499362      0.801242   0.328169   0.822161
```


And we can simply select values from `B` with selectors from `A`:

```julia
julia> B[DimSelectors(A)]
```

```ansi
[90m┌ [39m[38;5;209m6[39m×[38;5;32m6[39m DimArray{Float64, 2}[90m ┐[39m
[90m├──────────────────────────┴───────────────────────────────────── dims ┐[39m
  [38;5;209m↓ [39m[38;5;209mX[39m Sampled{Float64} [38;5;209m[1.0, …, 2.0][39m [38;5;244mForwardOrdered[39m [38;5;244mIrregular[39m [38;5;244mPoints[39m,
  [38;5;32m→ [39m[38;5;32mY[39m Sampled{Int64} [38;5;32m[10, …, 20][39m [38;5;244mReverseOrdered[39m [38;5;244mIrregular[39m [38;5;244mPoints[39m
[90m└──────────────────────────────────────────────────────────────────────┘[39m
 [38;5;209m↓[39m [38;5;32m→[39m  [38;5;32m10[39m          [38;5;32m12[39m         [38;5;32m14[39m         [38;5;32m16[39m         [38;5;32m18[39m         [38;5;32m20[39m
 [38;5;209m1.0[39m   0.760043    0.92906    0.122323   0.475301   0.400001   0.11787
 [38;5;209m1.2[39m   0.651104    0.797969   0.244449   0.35128    0.586663   0.422318
 [38;5;209m1.4[39m   0.0534248   0.760577   0.845805   0.326566   0.117547   0.44818
 [38;5;209m1.6[39m   0.860352    0.525557   0.169812   0.713043   0.536294   0.753597
 [38;5;209m1.8[39m   0.460775    0.952744   0.460204   0.41747    0.187648   0.574678
 [38;5;209m2.0[39m   0.822161    0.801242   0.107466   0.246027   0.499362   0.29205
```


If the lookups aren&#39;t aligned, we can use `Near` instead of `At`, which is like doing a nearest neighbor interpolation:

```julia
julia> C = rand(X(1.0:0.007:2.0), Y(10.0:0.9:30))
```

```ansi
[90m┌ [39m[38;5;209m143[39m×[38;5;32m23[39m DimArray{Float64, 2}[90m ┐[39m
[90m├─────────────────────────────┴────────────────────────────────── dims ┐[39m
  [38;5;209m↓ [39m[38;5;209mX[39m Sampled{Float64} [38;5;209m1.0:0.007:1.994[39m [38;5;244mForwardOrdered[39m [38;5;244mRegular[39m [38;5;244mPoints[39m,
  [38;5;32m→ [39m[38;5;32mY[39m Sampled{Float64} [38;5;32m10.0:0.9:29.8[39m [38;5;244mForwardOrdered[39m [38;5;244mRegular[39m [38;5;244mPoints[39m
[90m└──────────────────────────────────────────────────────────────────────┘[39m
 [38;5;209m↓[39m [38;5;32m→[39m    [38;5;32m10.0[39m       [38;5;32m10.9[39m        …  [38;5;32m28.0[39m       [38;5;32m28.9[39m        [38;5;32m29.8[39m
 [38;5;209m1.0[39m     0.399781   0.148229       0.449093   0.560553    0.565202
 [38;5;209m1.007[39m   0.717006   0.615703       0.925484   0.0485471   0.794437
 [38;5;209m1.014[39m   0.661197   0.360751       0.739562   0.366935    0.923642
 [38;5;209m1.021[39m   0.887979   0.0284535      0.352175   0.127118    0.639886
 ⋮                             ⋱
 [38;5;209m1.973[39m   0.725774   0.525431   …   0.520799   0.961561    0.0889688
 [38;5;209m1.98[39m    0.707629   0.640577       0.945549   0.67027     0.934843
 [38;5;209m1.987[39m   0.271952   0.948532       0.27236    0.782344    0.93513
 [38;5;209m1.994[39m   0.294534   0.680648       0.53422    0.906871    0.503183
```

```julia
julia> C[DimSelectors(A; selectors=Near)]
```

```ansi
[90m┌ [39m[38;5;209m6[39m×[38;5;32m6[39m DimArray{Float64, 2}[90m ┐[39m
[90m├──────────────────────────┴─────────────────────────────────────── dims ┐[39m
  [38;5;209m↓ [39m[38;5;209mX[39m Sampled{Float64} [38;5;209m[1.0, …, 1.994][39m [38;5;244mForwardOrdered[39m [38;5;244mIrregular[39m [38;5;244mPoints[39m,
  [38;5;32m→ [39m[38;5;32mY[39m Sampled{Float64} [38;5;32m[10.0, …, 19.9][39m [38;5;244mForwardOrdered[39m [38;5;244mIrregular[39m [38;5;244mPoints[39m
[90m└────────────────────────────────────────────────────────────────────────┘[39m
 [38;5;209m↓[39m [38;5;32m→[39m    [38;5;32m10.0[39m       [38;5;32m11.8[39m        [38;5;32m13.6[39m       [38;5;32m16.3[39m       [38;5;32m18.1[39m        [38;5;32m19.9[39m
 [38;5;209m1.0[39m     0.399781   0.0646533   0.611333   0.198465   0.0887762   0.302922
 [38;5;209m1.203[39m   0.594314   0.50095     0.315896   0.878116   0.728728    0.928246
 [38;5;209m1.399[39m   0.819291   0.235618    0.535219   0.112537   0.390661    0.170889
 [38;5;209m1.602[39m   0.482064   0.629542    0.893616   0.58833    0.182349    0.680387
 [38;5;209m1.798[39m   0.690159   0.219552    0.580422   0.167206   0.640598    0.966742
 [38;5;209m1.994[39m   0.294534   0.910144    0.490752   0.374164   0.395148    0.265639
```

