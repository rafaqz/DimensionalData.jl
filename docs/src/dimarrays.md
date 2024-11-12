# DimArrays

`DimArray`s are wrappers for other kinds of `AbstractArray` that
add named dimension lookups.


Here we define a `Matrix` of `Float64`, and give it `X` and `Y` dimensions

```@ansi dimarray
using DimensionalData
A = rand(5, 10)
da = DimArray(A, (X, Y))
```

We can access a value with the same dimension wrappers:

```@ansi dimarray
da[Y(1), X(2)]
```

There are shortcuts for creating `DimArray`:

::: tabs

== DimArray

```@ansi dimarray
A = rand(5, 10)
DimArray(A, (X, Y))
DimArray(A, (X, Y); name=:DimArray, metadata=Dict())
```

== zeros

```@ansi dimarray
zeros(X(5), Y(10))
zeros(X(5), Y(10); name=:zeros, metadata=Dict())
```

== ones

```@ansi dimarray
ones(X(5), Y(10))
ones(X(5), Y(10); name=:ones, metadata=Dict())
```

== rand

```@ansi dimarray
rand(X(5), Y(10))
rand(X(5), Y(10); name=:rand, metadata=Dict())
```

== fill

```@ansi dimarray
fill(7, X(5), Y(10))
fill(7, X(5), Y(10); name=:fill, metadata=Dict())
```

== generator construction

```@ansi dimarray
[x + y for x in X(1:5), y in Y(1:10)]
DimArray(x + y for x in X(1:5), y in Y(1:10))
DimArray(x + y for x in X(1:5), y in Y(1:10); name=:sum, metadata=Dict())
```

:::

## Constructing DimArray with arbitrary dimension names

For arbitrary names, we can use the `Dim{:name}` dims
by using `Symbol`s, and indexing with keywords:

```@ansi dimarray
da1 = DimArray(rand(5, 5), (:a, :b))
```

and get a value, here another smaller `DimArray`:

```@ansi dimarray
da1[a=3, b=1:3]
```

## Dimensional Indexing

When used for indexing, dimension wrappers free us from knowing the
order of our objects axes. These are the same:

```@ansi dimarray
da[X(2), Y(1)] == da[Y(1), X(2)]
```

We also can use `Tuples` of dimensions, like `CartesianIndex`,
but they don't have to be in order of consecutive axes.

```@ansi dimarray
da2 = rand(X(10), Y(7), Z(5))
da2[(X(3), Z(5))]
```

We can index with `Vector` of `Tuple{Vararg(Dimension}}` like vectors of
`CartesianIndex`. This will merge the dimensions in the tuples:

```@ansi dimarray
inds = [(X(3), Z(5)), (X(7), Z(4)), (X(8), Z(2))]
da2[inds]
```

`DimIndices` can be used like `CartesianIndices` but again, without the
constraint of consecutive dimensions or known order.

```@ansi dimarray
da2[DimIndices(dims(da2, (X, Z))), Y(3)]
```

The `Dimension` indexing layer sits on top of regular indexing and _can not_ be combined
with it! Regular indexing specifies order, so doesn't mix well with our dimensions.

Mixing them will throw an error:

```@ansi dimarray
da1[X(3), 4]
```

## Begin End indexing

```@ansi dimarray
da1[X=Begin+1, Y=End]
```

It also works in ranges, even with basic math:

```@ansi dimarray
da1[X=Begin:Begin+1, Y=Begin+1:End-1]
```

In base julia the keywords `begin` and `end` can be used to
index the first or last element of an array. But this doesn't 
work when named indexing is used. Instead you can use the types
`Begin` and `End`.

::: info Indexing

Indexing `AbstractDimArray`s works with `getindex`, `setindex!` and
`view`. The result is still an `AbstracDimArray`, unless using all single
`Int` or `Selector`s that resolve to `Int` inside `Dimension`.

:::

## `dims` keywords

In many Julia functions like, `size` or `sum`, you can specify the dimension
along which to perform the operation as an `Int`. It is also possible to do this
using [`Dimension`](@ref) types with `AbstractDimArray`:

```@ansi dimarray
da5 = rand(X(3), Y(4), Ti(5))
sum(da5; dims=Ti)
```

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


## Performance

Indexing with `Dimension`s has no runtime cost. Let's benchmark it:

```@ansi dimarray
using BenchmarkTools
da4 = ones(X(3), Y(3))
@benchmark $da4[X(1), Y(2)]
```

the same as accessing the parent array directly:

```@ansi dimarray
@benchmark parent($da4)[1, 2]
```
