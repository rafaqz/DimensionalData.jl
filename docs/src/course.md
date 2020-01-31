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
timespan = Time(DateTime(2001):Month(1):DateTime(2001,12))
xspan = X(10:10:100)

```
Here both `X` and `Time` are already created (and exported) dimensions from within the `DimensionalData` module. We use them now to make a `DimensionalArray`:
```@example main
A = DimensionalArray(rand(12,10), (timespan, xspan))
```

These dimensions (here `X, Time`) can then be used to index the array by name, without having to worry about the order of the dimensions.
For example, simple index-based access of `A` at let's say every 2 points of the `Time` dimension and every 3rd point of the `X` dimension happens like so:
```@example main
A[Time(1:2:end), X(1:3:end)]
```

!!! info "Indexing"
    All indexing on `DimensionalArray`s works with `getindex` (the above example), `setindex!` as well as `view`. In addition, indexing like this always preserves the nature of the data, i.e. the result is still a `DimensionalArray`.

## Selecting by value
The above example is useful because one does not have to care about the ordering of the dimensions.
But much more useful is to be able to select a dimension by value.
For example, we would like to get all values of `A` where the `X` dimension is between two values.
This is done with the so-called selectors, all of which are listed in the [Selectors](@ref) page.
For simplicity, here we showcase the [`Between`](@ref) selector but many others exist, like [`At`](@ref) or [`Near`](@ref).
```@example main
A[X <| Between(12, 35), Time <| Between(Date(2001,5), Date(2001, 7))]
```
Notice that the selectors have to be applied to a dimension (here we use the notation `x <| f`, which literally translates to `f(x)`).

## Selecting by position
Selection, including all selector functions, also works by position (when the target dimension is not specified).
I.e. if `X, Y` are the two dimensions of `A` (in order), then `A[At([1, 2]), At([4, 5])]` , `A[X <| At([1, 2]), Y <| At([4, 5])]` and `A[Y <| At([4, 5]), X <| At([1, 2])]` are all equivalent.
When selecting by position applying the selector to a target dimension is not necessary, as is evident by the expression `A[At([1, 2]), At([4, 5])]`.

When PR#48 is done, this section will be updated.

## Specifying `dim` by dimension name
In many Julia functions, like e.g. `size, sum` etc., one can specify the dimension (as an integer) along which to perform the operation.
It is possible to do this for `DimensionalArray` by specifying the dimension by its name (its Type actually), for example
```@example main
sum(A, dims = X)
```
(both dimensions of `A` need to be kept, as the standard Julia functions also keep the extra dimensions, but make them singular). All methods that have been extended to support this are listed in the [Methods with dim keyword](@ref) section.


## Referenced dimensions
Here @rafaqz needs to write, because I really don't know refdims... :)

## Grid functionality
Here @rafaqz needs to write, because I really don't know grids... :)
