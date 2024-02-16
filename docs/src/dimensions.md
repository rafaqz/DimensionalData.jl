# Dimensions

Dimensions are "wrapper types" that can be used to wrap any 
object to associate it with a named dimension.

The abstract supertype is [`Dimension`](@ref), and the types
that inherit from it aare `Ti`, `X`, `Y`, `Z`, the generic `Dim{:x}`, 
or others that you define manually using the [`@dim`](@ref) macro.

DimensionalData.jl uses `Dimensions` pretty much everywhere: 

- `Dimension` are returned from `dims` to specify the names of the dimensions of an object
- they wrap [`LookupArrays`](@ref) to associate the lookups with those names
- to index into these objects, they can wrap indices like `Int` or a `Selector` 

This symmetry means we can just ignore how data is organised, and
just label and access it by name, letting DD work out the details for us.

Dimensions are defined in the [`Dimensions`](@ref) submodule, some 
Dimension-specific methods can be brought into scope with:

```julia
using DimensionalData.Dimensions
```

## Examples

## Use in AbstractDimArray

We can use dimensions without a `LookupArray` - to simply label the axis.
A `DimArray` with labelled dimensions can be constructed by:

````@ansi dimensions
using DimensionalData

A1 = zeros(X(5), Y(5:10))
````

And we can acces a value with:

````@ansi dimensions
A1[Y(1), X(2)]
````

As shown above, `Dimension`s can be used to construct arrays in `rand`, `zeros`,
`ones` and `fill`, with either a range for a lookup index or a number for the
dimension length.

We can also use the `Dim{:name}` dims by using `Symbol`s, and indexing with keywords:

````@ansi dimensions
A2 = DimArray(rand(5, 5), (:a, :b))
````

and get a value:

````@ansi dimensions
A2[a=3, b=5]
````

Keywords also work with our first example:

````@ansi dimensions
A1[X=3]
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
exported dimensions are `X, Y, Z, Ti` (`Ti` is shortening of `Time` to avoid
the existing `Time` object and the very common `T` type).

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

Indexing with `Dimension`s has no runtime cost:

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

this is the same as accessing the parent array directly:

````@ansi dimensions
@benchmark parent($A2)[1, 2]
````


## `dims` keywords

In many Julia functions like, `size` or `sum`, you can specify the dimension
along which to perform the operation as an `Int`. It is also possible to do this
using [`Dimension`](@ref) types with `AbstractDimArray`:

````@ansi dimensions
A3 = rand(X(3), Y(4), Ti(5))
sum(A3; dims=Ti)
````

This also works in methods from `Statistics`:

````@example dimensions
using Statistics
````

````@ansi dimensions
mean(A3; dims=Ti)
````

::: info Dims keywords

Methods where dims, dim types, or `Symbol`s can be used to indicate the array dimension:

- `size`, `axes`, `firstindex`, `lastindex`
- `cat`, `reverse`, `dropdims`
- `reduce`, `mapreduce`
- `sum`, `prod`, `maximum`, `minimum`
- `mean`, `median`, `extrema`, `std`, `var`, `cor`, `cov`
- `permutedims`, `adjoint`, `transpose`, `Transpose`
- `mapslices`, `eachslice`

:::


## DimIndices
## Vectors of Dimensions

## How to name dimensions?
## How to name an array?
## Adding metadata
