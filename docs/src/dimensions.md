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

## Use in a `DimArray`

We can use dimensions without a `LookupArray` to simply label the axis.
A `DimArray` with labelled dimensions can be constructed by:

```@ansi dimensions
using DimensionalData

A1 = zeros(X(5), Y(10))
```

And we can access a value with:

```@ansi dimensions
A1[Y(1), X(2)]
```

As shown above, `Dimension`s can be used to construct arrays in `rand`, `zeros`,
`ones` and `fill`, with either a range for a lookup index or a number for the
dimension length.

For completely arbitrary names, we can use the `Dim{:name}` dims 
by using `Symbol`s, and indexing with keywords:

```@ansi dimensions
A2 = DimArray(rand(5, 5), (:a, :b))
```

and get a value:

```@ansi dimensions
A2[a=3, b=1:3]
```

Keywords also work with our first example:

```@ansi dimensions
A1[X=3]
```

The length of each dimension index has to match the size of the corresponding
array axis. 


## Dimensional Indexing

When used in indexing, dimension wrappers free us from knowing the 
order of our objects axes, or from even keeping it consistent. 

We can index in whatever order we want to. These are the same:

```@ansi dimensions
A1[X(2), Y(1)]
A1[Y(1), X(2)]
```

We can Index with a single dimsions, and the remaining will be filled with colons: 

```@ansi dimensions
A1[Y(1:2:5)]
```

We can use Tuples of dimensions like `CartesianIndex`, but they don't have to
be in order or for consecutive axes.

```@ansi dimensions
A3 = rand(X(10), Y(7), Z(5))
# TODO not merged yet A3[(X(3), Z(5))]
```

We can index with `Vector` of `Tuple{Vararg(Dimension}}` like vectors of
`CartesianIndex`

```@ansi dimensions
# TODO not merged yet A3[[(X(3), Z(5)), (X(7), Z(x)), (X(8), Z(2))]]
nothing # hide
```

`DimIndices` can be used like `CartesianIndices` but again, without the 
constraint of consecutive dimensions or known order.

```@ansi dimensions
# TODO not merged yet A3[DimIndices(dims(A3, (X, Z))), Y(3)]
nothing # hide
```

All of this indexing can be combined arbitrarily.

This will regurn values for `:e` at 6, `:a` at 3, all of `:d` an `:b`, and a vector of `:c` 
and `:f`. Unlike base, we know that `:c` and `:f` are now related and merge the `:c` and `:f`
dimensions into a lookup of tuples:

```@ansi dimensions
A4 = DimArray(rand(10, 9, 8, 7, 6, 5), (:a, :b, :c, :d, :e, :f))

# TODO not merged yet A4[e=6, DimIndices(dims(A4, (:d, :b))), a=3, collect(DimIndices(dims(A4, (:c, :f))))] 
nothing # hide
```

The `Dimension` indexing layer sits on top of regular indexing and _can not_ be combined 
with it! Regular indexing specifies order, so doesn't mix well with our dimensions.

Mixing them will throw an error:

```@example dimensions
A1[X(3), 4]
# ERROR: ArgumentError: invalid index: X{Int64}(3) of type X{Int64}
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

```@example dimensions
using BenchmarkTools
```

```@ansi dimensions
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
