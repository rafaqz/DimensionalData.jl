# Selectors

Indexing by value in `DimensionalData` is done with [Selectors](@ref).
IntervalSets.jl is now used for selecting ranges of values (formerly `Between`).

| Selector                | Description                                                           |
| :---------------------- | :-------------------------------------------------------------------- |
| [`At(x)`](@ref)         | get the index exactly matching the passed in value(s)                 |
| [`Near(x)`](@ref)       | get the closest index to the passed in value(s)                       |
| [`Contains(x)`](@ref)   | get indices where the value x falls within an interval                |
| [`Where(f)`](@ref)      | filter the array axis by a function of the dimension index values.    |
| [`Not(x)`]              | get all indices _not_ selected by `x`, which can be another selector. |
| [`a..b`]                | get all indices between two values, inclusively.                      |
| [`OpenInterval(a, b)`]  | get all indices between `a` and `b`, exclusively.                     |
| [`Interval{A,B}(a, b)`] | get all indices between `a` and `b`, as `:closed` or `:open`.         |


Selectors find indices in the `LookupArray`, for each dimension. 

## lookup
## At
## Between, ..
## Where
## Near
## Touches
## Contains
## All
## IntervalSets
## DimSelectors