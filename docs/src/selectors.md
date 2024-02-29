# Selectors

As well as choosing dimensions by name, we can also select values in them.

First, we can create `DimArray` with lookup values as well as
dimension names:

````@example selectors
using DimensionalData
````

````@ansi selectors
A = rand(X(1.0:0.2:2.0), Y([:a, :b, :c]))
````

Then we can use [`Selector`](@ref) to select values from the array:

::: tabs

== At

[`At(x)`](@ref) gets the index or indices exactly matching the passed in value/s. 

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

[`Near(x)`](@ref) gets the closest index to the passed in value(s),
indexing with an `Int`.

````@ansi selectors
A[X=Near(1.245)]
````

`Near` can also take vectors and ranges, which indexes with a `Vector{Int}`

````@ansi selectors
A[X=Near(1.1:0.25:1.5)]
````

== Contains

[`Contains(x)`](@ref) get indices where the value x falls within an interval in the lookup. 

First set the `X` axis to be `Intervals`:

````@ansi selectors
using DimensionalData.LookupArrays
A_intervals = set(A, X => Intervals(Start()))
intervalbounds(A_intervals, X)
````

With a single value it is like indexing with `Int`

````@ansi selectors
A_intervals[X=Contains(1.245)]
````

`Contains` can also take vectors and ranges, which is lick indexing with `Vector{Int}`

````@ansi selectors
A_intervals[X=Contains(1.1:0.25:1.5)]
````

== ..

`..` or `IntervalSets.Interval` selects a range of values:
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

[`Touches`](@ref) is like `..`, but for `Intervals` it will include
intervals touched by the selected interval, not inside it.

This usually means including zero, one or two cells more than `..`
`Touches` is like indexing with a `UnitRange`

````@ansi selectors
A_intervals[X=Touches(1.1, 1.5)]
A_intervals[X=1.1 .. 1.5]
````

== Where

[`Where(f)`](@ref) filter the array axis by a function of the dimension index values. 
`Where` is like indexing with a `Vector{Bool}`:

````@ansi selectors
A[X=Where(>=(1.5)), Y=Where(x -> x in (:a, :c))]
````

== Not

`Not(x)` get all indices _not_ selected by `x`, which can be another selector.
`Not` is like indexing with a `Vector{Bool}`.

````@ansi selectors
A[X=Not(Near(1.3)), Y=Not(Where(in((:a, :c))))]
````

:::

## Lookups

Selectors find indices in the `LookupArray` of each dimension.
LookupArrays wrap other `AbstractArray` (often `AbstractRange`) but add
aditional traits to facilitate fast lookups or specifing point or interval
behviour. These are usually detected automatically.


````@example selectors
using DimensionalData.LookupArrays
````
::: tabs

== Sampled lookups

[`Sampled(x)`](@ref) lookups hold values sampled along an axis.
They may be `Ordered`/`Unordered`, `Intervals`/`Points`, and `Regular`/`Irregular`.

Most of these properties are usually detected autoatically,
but here we create a [`Sampled`](@ref) lookup manually:

````@ansi selectors
l = Sampled(10.0:10.0:100.0; order=ForwardOrdered(), span=Regular(10.0), sampling=Intervals(Start()))
````

TO specify `Irregular` `Intervals` we should include the outer bounds of the
lookup, as we cant determine them from the vector.

````@ansi selectors
l = Sampled([13, 8, 5, 3, 2, 1]; order=ForwardOrdered(), span=Irregular(1, 21), sampling=Intervals(Start()))
````

== Categorical lookup

[`Categorical(x)`](@ref) a categorical lookup that holds categories,
and may be ordered.

Create a [`Categorical`](@ref) lookup manually

````@ansi selectors
l = Categorical(["mon", "tue", "weds", "thur", "fri", "sat", "sun"]; order=Unordered())
````

== Cyclic lookups

[`Cyclic(x)`](@ref) an `AbstractSampled` lookup for cyclical values.

Create a [`Cyclic`](@ref) lookup that cycles over 12 months.

````@ansi selectors
using Dates
l = Cyclic(DateTime(2000):Month(1):DateTime(2000, 12); cycle=Month(12), sampling=Intervals(Start()))
````

There is a shorthand to make a `DimArray` frome a `Dimension` with a function
of the lookup values. Here we convert the values to the month names:

````@ansi selectors
A = DimArray(monthabbr, X(l))
````

Now we can select any date and get the month:

````@ansi selectors
A[At(DateTime(2005, 4))]
A[At(DateTime(3047, 9))]
````

== NoLookup

[`NoLookup(x)`](@ref) no lookup values provided, so `Selector`s will not work.
Whe you create a `DimArray` without a lookup array, `NoLookup` will be used.
It is also not show in repl printing.

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

- Arrays and ranges of `String`, `Symbol` and `Char` are set to `Categorical` lookup.
    - `order` is detected as `Unordered`, `ForwardOrdered` or `ReverseOrdered`
- Arrays and ranges of `Number`, `DateTime` and other things are set to `Sampled` lookups.
    - `order` is detected as `Unordered`, `ForwardOrdered` or `ReverseOrdered`.
    - `sampling` is set to `Points()` unless the values are `IntervalSets.Interval`,
        then `Intervals(Center())` is used.
    - `span` is detected as `Regular(step(range))` for `AbstractRange` and
        `Irregular(nothing, nothing)` for other `AbstractArray`, where `nothing,
        nothing` are the unknown outer bounds of the lookup. They are not needed
        for `Points` as the outer values are the outer bounds. But they can be
        specified manually for `Intervals`
    - Emtpy dimensions or dimension types are assigned `NoLookup()` ranges that
        can't be used with selectors as they hold no values.

## `DimSelector`

We can also index with arrays of selectors [`DimSelectors`](@ref).
These are like `CartesianIndices` or [`DimIndices`](@ref) but holding
`Selectors` `At`, `Near` or `Contains`.

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

If the lookups aren't aligned we can use `Near` instead of `At`,
which like doing a nearest neighor interpolation:

````@ansi selectors
C = rand(X(1.0:0.007:2.0), Y(10.0:0.9:30))
C[DimSelectors(A; selectors=Near)]
````

