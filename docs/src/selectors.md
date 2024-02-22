# Selectors and LookupArrays

As well as choosing dimensions by name, we can also select values in them.

First, we can create `DimArray` with lookup values as well as
dimension names:

````@example selectors
using DimensionalData
````

````@ansi selectors
A = rand(X(1.0:0.2:2.0), Y([:a, :b, :c]))
````

Then we can use [`Selector`](@ref) to selctect
values from the array based on its lookup values:

These are single value selectors:

````@ansi selectors
A[X=Near(1.3), Y=At(:c)]
````

But they can select vectors of indices if given vectors of values:

````@ansi selectors
# Broken
# A[X=Near(1.12:0.09:1.3), Y=At([:a, :b])]
````

These selectors only select multiple indices: `..`, `Where` and `Not`

````@ansi selectors
A[X=1.2 .. 1.7, Y=Where(x -> x in (:a, :c))]
A[X=Not(At(1.2)), Y=Where(x -> x in (:a, :c))]
````

The full set is details in this table.

| Selector                | Description                                                                  | Indexing style    |
| :---------------------- | :--------------------------------------------------------------------------- |------------------ |
| [`At(x)`](@ref)         | get the index exactly matching the passed in value(s)                        | `Int/Vector{Int}` |
| [`Near(x)`](@ref)       | get the closest index to the passed in value(s)                              | `Int/Vector{Int}` |
| [`Contains(x)`](@ref)   | get indices where the value x falls within an interval in the lookup         | `Int/Vector{Int}` |
| [`Where(f)`](@ref)      | filter the array axis by a function of the dimension index values.           | `Vector{Bool}`    |
| `Not(x)`                | get all indices _not_ selected by `x`, which can be another selector.        | `Vector{Bool}`    |
| `a .. b`                | get all indices between two values, inclusively.                             | `UnitRange`       |
| `OpenInterval(a, b)`    | get all indices between `a` and `b`, exclusively.                            | `UnitRange`       |
| `Interval{A,B}(a, b)`   | get all indices between `a` and `b`, as `:closed` or `:open`.                | `UnitRange`       |
| [`Touches(a, b)`](@ref) | like `..` but includes all cells touched by the interval, not just inside it | `UnitRange`       |

Note: `At`, `Near` and `Contains` can wrap either single values or an
`AbstractArray` of values, to select one index with an `Int` or multiple 
indices with a `Vector{Int}`.


Selectors find indices in the `LookupArray`, for each dimension. 
LookupArrays wrap other `AbstractArray` (often `AbstractRange`) but add
aditional traits to facilitate fast lookups or specifing point or interval
behviour. These are usually detected automatically.

Some common `LookupArray` that are:

| LookupArray              | Description                                                                                                  |
| :----------------------  | :----------------------------------------------------------------------------------------------------------- |
| [`Sampled(x)`](@ref)     | values sampled along an axis - may be `Ordered`/`Unordered`, `Intervals`/`Points`, and `Regular`/`Irregular` |
| [`Categorical(x)`](@ref) | a categorical lookup that holds categories, and may be ordered                                               |
| [`Cyclic(x)`](@ref)      | an `AbstractSampled` lookup for cyclical values.                                                             |
| [`NoLookup(x)`](@ref)    | no lookup values provided, so `Selector`s will not work. Not show in repl printing.                          |



````@example lookuparrays
using DimensionalData.LookupArrays
````

## Lookup autodetection

When we define an array, extra properties are detected:

````@ansi lookuparrays
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

## Specifying properties

We can also override properties by adding keywords to a `Dimension` constructor:

````@ansi lookuparrays
using DimensionalData.LookupArrays
rand(X(10:20:100; sampling=Intervals(Start())), Y([:a, :b, :c, :d, :e]; order=Unordered()))
````

And they will be passed to the detected `LookupArray` typed - here `Sampled` and
`Categorical`. Anything we skip will be detected automatically.

Finally, we can fully lookup properties. You may want to do this in a
package to avoid the type instability and other costs of the automatic checks.
Any skippied fields will still be auto-detected. Here we skip `span` in
`Sampled` as there is no cost to detecting it from a `range`. You can see
`AutoSpan` in the show output after we construct it - this will be replaced 
when the `DimArray` is constructed.

````@ansi
using DimensionalData.LookupArrays
x = X(Sampled(10:20:100; order=ForwardOrdered(), sampling=Intervals(Start()), metadata=NoMetadata()))
y = Y(Categorical([1, 2, 3]; order=ForwardOrdered(), metadata=NoMetadata()))
rand(x, y)
````

Some other lookup types are never detected, and we have to specify them
manually.

## `Cyclic` lookups

Create a `Cyclic` lookup that cycles over 12 months.

````@ansi lookuparrays
lookup = Cyclic(DateTime(2000):Month(1):DateTime(2000, 12); cycle=Month(12), sampling=Intervals(Start()))
````

Make a `DimArray` where ther values are the month names:

````@ansi lookuparrays
A = DimArray(monthabbr, X(lookup))
````

Now we can select any date and get the month:

```@ansi lookups
A[At(DateTime(2005, 4))]
A[At(DateTime(3047, 9))]
```


## `DimSelector`

We can also index with arrays of selectors [`DimSelectors`](@ref). 
These are like `CartesianIndices` or [`DimIndices`](@ref) but holding 
`Selectors` `At`, `Near` or `Contains`.

````@ansi dimselectors
A = rand(X(1.0:0.2:2.0), Y(10:2:20))
````

We can define another array with partly matching indices

````@ansi dimselectors
B = rand(X(1.0:0.04:2.0), Y(20:-1:10))
````

And we can simply select values from `B` with selectors from `A`:

````@ansi dimselectors
B[DimSelectors(A)]
````

If the lookups aren't aligned we can use `Near` instead of `At`,
which like doing a nearest neighor interpolation:

````@ansi dimselectors
C = rand(X(1.0:0.007:2.0), Y(10.0:0.9:30))
C[DimSelectors(A; selectors=Near)]
````
