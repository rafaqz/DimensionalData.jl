# Selectors and LookupArrays

http://localhost:5173/DimensionalData.jl/reference#lookuparrays

DimensionalData.jl [`Dimension`](@ref)s in an `AbstractDimArray` or 
`AbstactDimStack` usually hold [`LookupArrays`](@ref). 

These are `AbstractArray` with added features to facilitate fast and
accurate lookups of their values, using a [`Selector`](@ref)

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
behviour.

Some common `LookupArray` that are:

| LookupArray               | Description                                                                                                  |
| :----------------------   | :----------------------------------------------------------------------------------------------------------- |
| [`Sampled(x)`](@ref)      | values sampled along an axis - may be `Ordered`/`Unordered`, `Intervals`/`Points`, and `Regular`/`Irregular` |
| [`Categorical(x)`](@ref)  | a categorical lookup that holds categories, and may be ordered                                               |
| [`Cyclic(x)`](@ref)       | an `AbstractSampled` lookup for cyclical values.                                                             |
| [`NoLookup(x)`](@ref)     | no lookup values provided, so `Selector`s will not work. Not show in repl printing.                          |

