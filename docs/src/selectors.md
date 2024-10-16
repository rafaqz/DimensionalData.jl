# Selectors

In addition to choosing dimensions by name, we can also select values within them.

First, we can create a `DimArray` with lookup values as well as dimension names:

````@example selectors
using DimensionalData
````

````@ansi selectors
A = rand(X(1.0:0.2:2.0), Y([:a, :b, :c]))
````

Then we can use the [`Selector`](@ref) to select values from the array:

::: tabs

== At

The [`At(x)`](@ref) selector gets the index or indices exactly matching the passed in value(s). 

````@ansi selectors
A[X=At(1.2), Y=At(:c)]
````

Or within a tolerance:

````@ansi selectors
A[X=At(0.99:0.201:1.5; atol=0.05)]
````

[`At`](@ref) can also take vectors and ranges:

````@ansi selectors
A[X=At(1.2:0.2:1.5), Y=At([:a, :c])]
````

== Near

The [`Near(x)`](@ref) selector gets the closest index to the passed in value(s), indexing with an `Int`.

````@ansi selectors
A[X=Near(1.245)]
````

`Near` can also take vectors and ranges, which indexes with a `Vector{Int}`

````@ansi selectors
A[X=Near(1.1:0.25:1.5)]
````

== Contains

The [`Contains(x)`](@ref) selector gets indices where the value x falls within an interval in the lookup. 

First, set the `X` axis to be `Intervals`:

````@ansi selectors
using DimensionalData.Lookups
A_intervals = set(A, X => Intervals(Start()))
intervalbounds(A_intervals, X)
````

With a single value, it is like indexing with `Int`

````@ansi selectors
A_intervals[X=Contains(1.245)]
````

`Contains` can also take vectors and ranges, which is like indexing with `Vector{Int}`

````@ansi selectors
A_intervals[X=Contains(1.1:0.25:1.5)]
````

== ..

The `..` or `IntervalSets.Interval` selector selects a range of values:
`..` is like indexing with a `UnitRange`:

````@ansi selectors
A[X=1.2 .. 1.6]
````

````@ansi selectors
using IntervalSets
A[X=OpenInterval(1.2 .. 1.6)]
````

````@ansi selectors
A[X=Interval{:close,:open}(1.2 .. 1.6)]
````

== Touches

The [`Touches`](@ref) selector is like `..`, but for `Intervals`, it will include intervals touched by the selected interval, not inside it.

This usually means including zero, one, or two cells more than `..`
`Touches` is like indexing with a `UnitRange`

````@ansi selectors
A_intervals[X=Touches(1.1, 1.5)]
A_intervals[X=1.1 .. 1.5]
````

== Where

The [`Where(f)`](@ref) selector filters the array axis by a function of the dimension index values. 
`Where` is like indexing with a `Vector{Bool}`:

````@ansi selectors
A[X=Where(>=(1.5)), Y=Where(x -> x in (:a, :c))]
````

== Not

The [`Not(x)`](@ref) selector gets all indices _not_ selected by `x`, which can be another selector.
`Not` is like indexing with a `Vector{Bool}`.

````@ansi selectors
A[X=Not(Near(1.3)), Y=Not(Where(in((:a, :c))))]
````

:::

## Lookups

Selectors find indices in the `Lookup` of each dimension.
Lookups wrap other `AbstractArray` (often `AbstractRange`) but add additional traits to facilitate fast lookups or specifying point or interval behaviour. These are usually detected automatically.


````@example selectors
using DimensionalData.Lookups
````
::: tabs

== Sampled lookups

The [`Sampled(x)`](@ref) lookup holds values sampled along an axis.
They may be `Ordered`/`Unordered`, `Intervals`/`Points`, and `Regular`/`Irregular`.

Most of these properties are usually detected automatically,
but here we create a `Sampled` lookup manually:

````@ansi selectors
l = Sampled(10.0:10.0:100.0; order=ForwardOrdered(), span=Regular(10.0), sampling=Intervals(Start()))
````

To specify `Irregular` `Intervals`, we should include the outer bounds of the lookup, as we can't determine them from the vector.

````@ansi selectors
l = Sampled([13, 8, 5, 3, 2, 1]; order=ForwardOrdered(), span=Irregular(1, 21), sampling=Intervals(Start()))
````

== Categorical lookup

The [`Categorical(x)`](@ref) lookup is a categorical lookup that holds categories,
and may be ordered.

Create a [`Categorical`](@ref) lookup manually

````@ansi selectors
l = Categorical(["mon", "tue", "weds", "thur", "fri", "sat", "sun"]; order=Unordered())
````

== Cyclic lookups

The [`Cyclic(x)`](@ref) lookup is an `AbstractSampled` lookup for cyclical values.

Create a [`Cyclic`](@ref) lookup that cycles over 12 months.

````@ansi selectors
using Dates
l = Cyclic(DateTime(2000):Month(1):DateTime(2000, 12); cycle=Month(12), sampling=Intervals(Start()))
````

There is a shorthand to make a `DimArray` from a `Dimension` with a function of the lookup values. Here we convert the values to the month names:

````@ansi selectors
A = DimArray(monthabbr, X(l))
````

Now we can select any date and get the month:

````@ansi selectors
A[At(DateTime(2005, 4))]
A[At(DateTime(3047, 9))]
````

== NoLookup

The [`NoLookup(x)`](@ref) lookup has no lookup values provided, so `Selector`s will not work.
When you create a `DimArray` without a lookup array, `NoLookup` will be used.
It is also not shown in REPL printing.

Here we create a [`NoLookup`](@ref):

````@ansi selectors
l = NoLookup()
typeof(l)
````

Or even fill in the axis:
````@ansi selectors
l = NoLookup(Base.OneTo(10))
typeof(l)
````

:::

## Lookup autodetection

When we define an array, extra properties are detected:

````@ansi selectors
A = DimArray(rand(7, 5), (X(10:10:70), Y([:a, :b, :c, :d, :e])))
````

This array has a `Sampled` lookup with `ForwardOrdered` `Regular`
`Points` for `X`, and a `Categorical` `ForwardOrdered` for `Y`.

Most lookup types and properties are detected automatically like this
from the arrays and ranges used.

- Arrays and ranges of `String`, `Symbol`, and `Char` are set to `Categorical` lookup.
    - `order` is detected as `Unordered`, `ForwardOrdered`, or `ReverseOrdered`
- Arrays and ranges of `Number`, `DateTime`, and other things are set to `Sampled` lookups.
    - `order` is detected as `Unordered`, `ForwardOrdered`, or `ReverseOrdered`.
    - `sampling` is set to `Points()` unless the values are `IntervalSets.Interval`,
        then `Intervals(Center())` is used.
    - `span` is detected as `Regular(step(range))` for `AbstractRange` and
        `Irregular(nothing, nothing)` for other `AbstractArray`, where `nothing,
        nothing` are the unknown outer bounds of the lookup. They are not needed
        for `Points` as the outer values are the outer bounds. But they can be
        specified manually for `Intervals`
    - Empty dimensions or dimension types are assigned `NoLookup()` ranges that
        can't be used with selectors as they hold no values.

## `DimSelector`

We can also index with arrays of selectors [`DimSelectors`](@ref).
These are like `CartesianIndices` or [`DimIndices`](@ref), but holding
the `Selectors` `At`, `Near`, or `Contains`.

````@ansi selectors
A = rand(X(1.0:0.2:2.0), Y(10:2:20))
````

We can define another array with partly matching indices

````@ansi selectors
B = rand(X(1.0:0.04:2.0), Y(20:-1:10))
````

And we can simply select values from `B` with selectors from `A`:

````@ansi selectors
B[DimSelectors(A)]
````

If the lookups aren't aligned, we can use `Near` instead of `At`,
which is like doing a nearest neighbor interpolation:

````@ansi selectors
C = rand(X(1.0:0.007:2.0), Y(10.0:0.9:30))
C[DimSelectors(A; selectors=Near)]
````
