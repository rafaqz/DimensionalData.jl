# AbstracDimArray

`DimArray`s are wrappers for other kinds of `AbstractArray` that 
add named dimension lookups. 


Here we define a `Matrix` of `Float64`, and give it `X` and `Y` dimensions

```@ansi dimarray
using DimensionalData
A = zeros(5, 10)
da = DimArray(A, (X, Y))
```

We can access a value with the same dimension wrappers:

```@ansi dimensions
A1[Y(1), X(2)]
```

There are shortcuts for creating `DimArray`:

::::tabs

== zeros

```@ansi dimensions
zeros(X(5), Y(10))
```

== ones

```@ansi dimensions
ones(X(5), Y(10))
```

== rand

```@ansi dimensions
rand(X(5), Y(10))
```

== fill 

```@ansi dimensions
fill(7, X(5), Y(10))
```

::::

For arbitrary names, we can use the `Dim{:name}` dims 
by using `Symbol`s, and indexing with keywords:

```@ansi dimensions
A2 = DimArray(rand(5, 5), (:a, :b))
```

and get a value, here another smaller `DimArray`:

```@ansi dimensions
A2[a=3, b=1:3]
```

## Dimensional Indexing

When used for indexing, dimension wrappers free us from knowing the 
order of our objects axes. These are the same:

```@ansi dimensions
A1[X(2), Y(1)] == A1[Y(1), X(2)]
```

We also can use Tuples of dimensions like `CartesianIndex`, 
but they don't have to be in order of consecutive axes.

```@ansi dimensions
A3 = rand(X(10), Y(7), Z(5))
A3[(X(3), Z(5))]
```

We can index with `Vector` of `Tuple{Vararg(Dimension}}` like vectors of
`CartesianIndex`. This will merge the dimensions in the tuples:

```@ansi dimensions
A3[[(X(3), Z(5)), (X(7), Z(4)), (X(8), Z(2))]]
```

`DimIndices` can be used like `CartesianIndices` but again, without the 
constraint of consecutive dimensions or known order.

```@ansi dimensions
A3[DimIndices(dims(A3, (X, Z))), Y(3)]
```

The `Dimension` indexing layer sits on top of regular indexing and _can not_ be combined 
with it! Regular indexing specifies order, so doesn't mix well with our dimensions.

Mixing them will throw an error:

```julia
julia> A1[X(3), 4]
ERROR: ArgumentError: invalid index: X{Int64}(3) of type X{Int64}
...
```

::: info Indexing

Indexing `AbstractDimArray`s works with `getindex`, `setindex!` and
`view`. The result is still an `AbstracDimArray`, unless using all single
`Int` or `Selector`s that resolve to `Int` inside `Dimension`.

:::


## Indexing Performance

Indexing with `Dimension`s has no runtime cost:

```@ansi dimensions
A2 = ones(X(3), Y(3))
```

Lets benchmark it

```@ansi dimensions
using BenchmarkTools
@benchmark $A2[X(1), Y(2)]
```

the same as accessing the parent array directly:

```@ansi dimensions
@benchmark parent($A2)[1, 2]
```


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

This can be especially useful when you are working with multiple objects.
Here we take the mean of A3 over all dimensions _not in_ A2, using `otherdims`.

In this case, thats the `Z` dimension. But we don't need to know it the Z 
dimension, some other dimensions, or even if it has extra dimensions at all!

This will work either way, leaveing us with the same dims as A1:

````@ansi dimensions
d = otherdims(A3, dims(A1))
dropdims(mean(A3; dims=d); dims=d)
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
