# Crash course
This is brief a tutorial for DimensionalData.jl.
All main functionality is explained here, but the full list of features is listed at the [API](@ref) page.

## Dimensions and DimensionalArrays
The core type of DimensionalData.jl is [`DimensionalArray`](@ref), which bundles a standard array with dimensions.
The dimensions are in the form of an `AbstractDimension`, and types that inherit from it, such as `Time`, `X`, `Y`, `Z`, the generic `Dim{:x}` or others that you define manually using the [`@dim`](@ref) macro.
A `DimensionalArray` is constructed by passing the data and the dimensions like so
```@example main
using Dates: DateTime, Month, Date
using DimensionalData
timespan = Ti(DateTime(2001):Month(1):DateTime(2001,12))
xspan = X(10:10:100)
```
Here both `X` and `Time` are already created dimensions from within the `DimensionalData` module. The currently exported predefined dimensions are `X, Y, Z, Ti`, with `Ti` an alias of `DimensionalData.Time` (to avoid the conflict with `Dates.Time`).

We pass a `Tuple` of the dimensions to make a `DimensionalArray`:
```@example main
A = DimensionalArray(rand(12,10), (timespan, xspan))
```

## Selecting by name and index
These dimensions (here `X, Ti`) can then be used to index the array by name, without having to worry about the order of the dimensions.

The simplest case is probably to select a dimension by index, e.g. at let's say every 2nd point of the `Ti` dimension and every 3rd point of the `X` dimension. This is done with the simple `Ti(range)` syntax like so:
```@example main
A[Ti(1:2:end), X(1:3:end)]
```

Of course, when specifying only one dimension, all other elements of the other dimensions are assumed to be included:
```@example main
A[X(1:3:end)]
```

!!! info "Indexing"
    All indexing on `DimensionalArray`s works with `getindex` (the above example), `setindex!` as well as `view`. In addition, indexing like this always preserves the nature of the data, i.e. the result is still a `DimensionalArray`.

## Selecting by name and value
The above example is useful because one does not have to care about the ordering of the dimensions.
But arguably more useful is to be able to select a dimension by its values.
For example, we would like to get all values of `A` where the `X` dimension is between two values.

Selecting by value in `DimensionalData` is **always** done with the **selectors**, all of which are listed in the [Selectors](@ref) page.
This avoids the ambiguity of what happens when the actual values of the dimension are also integers (like the case here for the dimension `X`).

For simplicity, here we showcase the [`Between`](@ref) selector but  others also exist, like [`At`](@ref) or [`Near`](@ref).
```@example main
A[X(Between(12, 35)), Ti(Between(Date(2001,5), Date(2001, 7)))]
```
Notice that the selectors have to be applied to a dimension (alternative syntax is `selector <| Dim`, which literally translates to `Dim(selector)`).

## Selecting by position
So far, the selection protocols we have mentioned work by specifying the _name_ of the dimension, without much care of what is the ordering.

However "normal" selection, as in standard Julia functions, also works by specifying dimensions by position. This functionality also covers the selector functions!

Continuing from the above realization of `A`, we showcase this by comparing the statements without and with names:
```@example main
A[Between(12, 35), :] == A[X(Between(12, 35))]
A[1:5, :] == A[X(1:5)]
A[:, 1:5] == A[Ti(1:5)]
```
etc. Of course in this approach it is necessary to specify _all_ dimensions by position, one cannot leave some unspecified.

In addition, to attempt supporting as much as base Julia functionality as possible, single index access like in standard `Array`. For example
```@example main
A[1:5]
```
selects the first 5 entries of the underlying numerical data. In the case that `A` has only one dimension, this kind of indexing retains the dimension.

## Specifying `dims` by dimension name
In many Julia functions, like e.g. `size, sum` etc., one can specify the dimension (as an integer) along which to perform the operation.
It is possible to do this for `DimensionalArray` by specifying the dimension by its name (its Type actually), for example
```@example main
sum(A, dims = X)
```
(both dimensions of `A` need to be kept, as the standard Julia functions also keep the extra dimensions, but make them singular). All methods that have been extended to support this are listed in the [Methods with dims keyword](@ref) section.


## Referenced dimensions
Coming soon.

## Grid functionality
Coming soon.
