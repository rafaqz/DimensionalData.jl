# Dimensions

````@example dimensions
using DimensionalData
````

The core type of DimensionalData.jl is the [`Dimension`](@ref) and the types
that inherit from it, such as `Ti`, `X`, `Y`, `Z`, the generic `Dim{:x}`, or
others that you define manually using the [`@dim`](@ref) macro.

`Dimension`s are primarily used in [`DimArray`](@ref), other
[`AbstractDimArray`](@ref).

## DimArray
We can use dimensions without a value index - these simply label the axis.
A `DimArray` with labelled dimensions is constructed by:

````@ansi dimensions
A = rand(X(5), Y(5))
````

get a value

````@ansi dimensions
A[Y(1), X(2)]
````

As shown above, `Dimension`s can be used to construct arrays in `rand`, `ones`,
`zeros` and `fill` with either a range for a lookup index or a number for the
dimension length.

Or we can use the `Dim{X}` dims by using `Symbol`s, and indexing with keywords:

````@ansi dimensions
A = DimArray(rand(5, 5), (:a, :b))
````

get value

````@ansi dimensions
A[a=3, b=5]
````

## What is a dimension?

````@example dimensions
using DimensionalData
using Dates
t = DateTime(2001):Month(1):DateTime(2001,12)
x = 10:10:100
nothing # hide
````

````@ansi dimensions
A = rand(X(x), Ti(t));
````

Here both `X` and `Ti` are dimensions from `DimensionalData`. The currently
exported dimensions are `X, Y, Z, Ti` (`Ti` is shortening of `Time`).

The length of each dimension index has to match the size of the corresponding
array axis. 

This can also be done with `Symbol`, using `Dim{X}`:

````@ansi dimensions
A2 = DimArray(rand(12, 10), (time=t, distance=x))
````

## Dimensional Indexing
Dimensions can be used to index the array by name, without having to worry
about the order of the dimensions.

The simplest case is to select a dimension by index. Let's say every 2nd point
of the `Ti` dimension and every 3rd point of the `X` dimension. This is done
with the simple `Ti(range)` syntax like so:

````@ansi dimensions
A[X(1:3:11), Ti(1:2:11)]
````

When specifying only one dimension, all elements of the other dimensions are assumed to be included:

````@ansi dimensions
A[X(1:3:10)]
````

::: info Indexing

Indexing `AbstractDimArray`s works with `getindex`, `setindex!` and
`view`. The result is still an `AbstracDimArray`, unless using all single
`Int` or `Selector`s that resolve to `Int`.

:::

### Indexing Performance

Indexing with `Dimension` has no runtime cost:

````@ansi dimensions
A2 = ones(X(3), Y(3))
````

time ?

````@example dimensions
using BenchmarkTools
````

````@ansi dimensions
@benchmark $A2[X(1), Y(2)]
````

and

````@ansi dimensions
@btime parent($A2)[1, 2]
````

In many Julia functions like `size` or `sum`, you can specify the dimension
along which to perform the operation as an `Int`. It is also possible to do this
using [`Dimension`](@ref) types with `AbstractDimArray`:

````@ansi dimensions
A3 = rand(X(3), Y(4), Ti(5));
sum(A3; dims=Ti)
````

This also works in methods from `Statistics`:

````@example dimensions
using Statistics
````

````@ansi dimensions
mean(A3; dims=Ti)
````

::: info

Methods where dims, dim types, or `Symbol`s can be used to indicate the array dimension:

- `size`, `axes`, `firstindex`, `lastindex`
- `cat`, `reverse`, `dropdims`
- `reduce`, `mapreduce`
- `sum`, `prod`, `maximum`, `minimum`
- `mean`, `median`, `extrema`, `std`, `var`, `cor`, `cov`
- `permutedims`, `adjoint`, `transpose`, `Transpose`
- `mapslices`, `eachslice`

:::


## Dimensions
## DimIndices
## Vectors of Dimensions

## How to name dimensions?
## How to name an array?
## Adding metadata