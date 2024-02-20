# Selectors and LookupArrays

As well as choosing dimensions by name, we can also select values in them.

First, we can create `DimArray` with lookup values as well as
dimension names:

````@ansi selectors
A = rand(X(1.0:0.1:2.0), Y([:a, :b, :c]))
````

Then we can use [`Selector`](@ref) to selctect
values from the array based on its lookup values:

````@ansi selectors
A[X=Near(1.3), Y=At(:c)]
````

There are a range of selectors available:

| Selector                | Description                                                                  | Indexing style    |
| :---------------------- | :--------------------------------------------------------------------------- |------------------ |
| [`At(x)`](@ref)         | get the index exactly matching the passed in value(s)                        | `Int/Vector{Int}` |
| [`Near(x)`](@ref)       | get the closest index to the passed in value(s)                              | `Int/Vector{Int}` |
| [`Contains(x)`](@ref)   | get indices where the value x falls within an interval in the lookup         | `Int/Vector{Int}` |
| [`Where(f)`](@ref)      | filter the array axis by a function of the dimension index values.           | `Vector{Bool}`    |
| [`Not(x)`]              | get all indices _not_ selected by `x`, which can be another selector.        | `Vector{Bool}`    |
| [`a .. b`]              | get all indices between two values, inclusively.                             | `UnitRange`       |
| [`OpenInterval(a, b)`]  | get all indices between `a` and `b`, exclusively.                            | `UnitRange`       |
| [`Interval{A,B}(a, b)`] | get all indices between `a` and `b`, as `:closed` or `:open`.                | `UnitRange`       |
| [`Touches(a, b)`]       | like `..` but includes all cells touched by the interval, not just inside it | `UnitRange`       |

Note: `At`, `Near` and `Contains` can wrap either single values or an
`AbstractArray` of values, to select one index with an `Int` or multiple 
indices with a `Vector{Int}`.


Selectors find indices in the `LookupArray`, for each dimension. 
LookupArrays wrap other `AbstractArray` (often `AbstractRange`) but add
aditional traits to facilitate fast lookups or specifing point or interval
behviour. These are usually detected automatically.

Some common `LookupArray` that are:

| LookupArray               | Description                                                                                                  |
| :----------------------   | :----------------------------------------------------------------------------------------------------------- |
| [`Sampled(x)`](@ref)      | values sampled along an axis - may be `Ordered`/`Unordered`, `Intervals`/`Points`, and `Regular`/`Irregular` |
| [`Categorical(x)`](@ref)  | a categorical lookup that holds categories, and may be ordered                                               |
| [`Cyclic(x)`](@ref)       | an `AbstractSampled` lookup for cyclical values.                                                             |
| [`NoLookup(x)`](@ref)     | no lookup values provided, so `Selector`s will not work. Not show in repl printing.                          |



````@ansi lookuparrays
using DimensionalData.LookupArrays
````

## `Cyclic` lookups


Create a `Cyclic` lookup that cycles over 12 months.

````@ansi lookuparrays
lookup = Cyclic(DateTime(2000):Month(1):DateTime(2000, 12); cycle=Month(12), sampling=Intervals(Start()))
````

Make a `DimArray` by apply a funcion to the lookup

````@ansi lookuparrays
A = DimArray(month, X(lookup))
````

Now we can select any date and get the month:

```@ansi lookups
A[At(DateTime(2005, 4))]
```


# `DimSelector`

We can also index with arrays of selectors [`DimSelectors`](@ref). 
These are like `CartesianIndices` or [`DimIndices`](@ref) but holding 
`Selectors` `At`, `Near` or `Contains`.

````@ansi dimselectors
A = rand(X(1.0:0.1:2.0), Y(10:2:20))
````

We can define another array with partly matching indices

````@ansi dimselectors
B = rand(X(1.0:0.02:2.0), Y(20:-1:10))
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
