# DimensionalData

[![](https://img.shields.io/badge/docs-stable-blue.svg)](https://rafaqz.github.io/DimensionalData.jl/stable)
[![](https://img.shields.io/badge/docs-dev-blue.svg)](https://rafaqz.github.io/DimensionalData.jl/dev)
![CI](https://github.com/rafaqz/DimensionalData.jl/workflows/CI/badge.svg)
[![Codecov](https://codecov.io/gh/rafaqz/DimensionalData.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/rafaqz/DimensionalData.jl)
[![Aqua.jl Quality Assurance](https://img.shields.io/badge/Aqua.jl-%F0%9F%8C%A2-aqua.svg)](https://github.com/JuliaTesting/Aqua.jl)

DimensionalData.jl provides tools and abstractions for working with datasets
that have named dimensions, and optionally a lookup index. It's a pluggable, 
generalised version of [AxisArrays.jl](https://github.com/JuliaArrays/AxisArrays.jl) 
with a cleaner syntax, and additional functionality found in NamedDims.jl. It has 
similar goals to pythons [xarray](http://xarray.pydata.org/en/stable/), and is primarily
written for use with spatial data in [GeoData.jl](https://github.com/rafaqz/GeoData.jl).

Broadcasting and most Base methods maintain and sync dimension context.

DimensionalData.jl also implements:
- comprehensive plot recipes for Plots.jl.
- a Tables.jl interface with `DimTable`
- multi-layered `DimStack`s that can be indexed together, 
    and have base methods applied to all layers.
- the Adapt.jl interface for use on GPUs, even as GPU kernel arguments.
- traits for handling a wide range of spatial data types accurately.

## Dimensions

Dimensions are wrapper types. They hold the lookup index, details about the 
grid, and other metadata. They are also used to index into the array. 
`X`, `Y`, `Z` and `Ti` are the exported defaults. A generalised `Dim` type is available 
to use arbitrary symbols to name dimensions. Custom dimension types can also be defined 
using the `@dim` macro.

Dimensions can be used to construct arrays in `rand`, `ones`, `zeros` and `fill` with 
either a range for a lookup index or a number for the dimension length:

```julia
julia> using DimensionalData

julia> A = rand(X(1:40), Y(50))
40×50 DimArray{Float64,2} with dimensions:
  X: 1:40 (Sampled - Ordered Regular Points)
  Y
 0.929006   0.116946  0.750017  …  0.172604  0.678835   0.495294
 0.0550038  0.100739  0.427026     0.778067  0.309657   0.831754
 ⋮                              ⋱
 0.647768   0.965682  0.049315     0.220338  0.0326206  0.36705
 0.851769   0.164914  0.555637     0.771508  0.964596   0.30265
```

We can also use dim wrappers for indexing, so that the dimension order in the underlying array
does not need to be known:

```julia
julia> A[Y(1), X(1:10)]
10-element DimArray{Float64,1} with dimensions:
  X: 1:10 (Sampled - Ordered Regular Points)
and reference dimensions: Y(1) 
 0.929006
 0.0550038
 0.641773
 ⋮
 0.846251
 0.506362
 0.0492866
```

And this has no runtime cost:

```julia
julia> A = ones(X(3), Y(3))
3×3 DimArray{Float64,2} with dimensions: X, Y
 1.0  1.0  1.0
 1.0  1.0  1.0
 1.0  1.0  1.0

julia> @btime $A[X(1), Y(2)]
  1.077 ns (0 allocations: 0 bytes)
1.0

julia> @btime parent($A)[1, 2]
  1.078 ns (0 allocations: 0 bytes)
1.0
```

Dims can be used in `X=val` form:

```julia
julia> A = rand(X(40), Y(50))
40×50 DimArray{Float64,2} with dimensions: X, Y
 0.377696  0.105445  0.543156  …  0.844973  0.163758  0.849367
 ⋮                             ⋱
 0.431454  0.108927  0.137541     0.531587  0.592512  0.598927

julia> A[Y=3]
40-element DimArray{Float64,1} with dimensions: X
and reference dimensions: Y(3)
 0.543156
 ⋮
 0.137541
```

For views:
```julia
julia> view(A, Y(), X(1:5))
5×50 DimArray{Float64,2} with dimensions: X, Y
 0.377696  0.105445  0.543156  …  0.844973  0.163758  0.849367
 ⋮                             ⋱
 0.875279  0.133032  0.925045     0.156768  0.736917  0.444683
```

And for specifying dimension number in all `Base` and `Statistics` 
functions that have a `dims` argument:

```julia
julia> using Statistics

julia> A = rand(X(3), Y(4), Ti(5));

julia> mean(A; dims=Ti)
3×4×1 DimArray{Float64,3} with dimensions: X, Y, Ti (Time)
[:, :, 1]
 0.168058  0.52353   0.563065  0.347025
 0.472786  0.395884  0.307846  0.518926
 0.365028  0.381367  0.423553  0.369339
```

You can also use symbols to create `Dim{X}` dimensions.
We can't use the `rand` method directly with Symbols,
so insteadd use the regular `DimArray` constructor:

```julia
julia> A = DimArray(rand(10, 20, 30), (:a, :b, :c));

julia> A[a=2:5, c=9]

4×20 DimArray{Float64,2} with dimensions: Dim{:a}, Dim{:b}
and reference dimensions: Dim{:c}(9)
 0.134354  0.581673  0.422615  …  0.410222   0.687915  0.753441
 0.573664  0.547341  0.835962     0.0353398  0.794341  0.490831
 0.166643  0.133217  0.879084     0.695685   0.956644  0.698638
 0.325034  0.147461  0.149673     0.560843   0.889962  0.75733
```

## Selectors

Selectors find indices in the lookup index, for each dimension: 

- `At(x)`: get the index exactly matching the passed in value(s)
- `Near(x)`: get the closest index to the passed in value(s)
- `Where(f::Function)`: filter the array axis by a function of the 
    dimension index values.
- `Between(a, b)`: get all indices between two values, excluding the high value.
- `Contains(x)`: get indices where the value x falls within the interval, exluding 
    the upper value. Only used for `Sampled` `Intervals`, for `Points`, use `At`.
    
(`Between` and `Contains` exlude the upper boundary so that adjacent selections
never contain the same index)

Selectors can be used in `getindex`, `setindex!` and
`view` to select indices matching the passed in value(s)

We can use selectors inside dim wrappers:

```julia
julia> using Dates

julia> timespan = DateTime(2001,1):Month(1):DateTime(2001,12)
DateTime("2001-01-01T00:00:00"):Month(1):DateTime("2001-12-01T00:00:00")

julia> A = DimArray(rand(12,10), (Ti(timespan), X(10:10:100)))
12×10 DimArray{Float64,2} with dimensions:
  Ti (Time): DateTime("2001-01-01T00:00:00"):Month(1):DateTime("2001-12-01T00:00:00") (Sampled - Ordered Regular Points)
  X: 10:10:100 (Sampled - Ordered Regular Points)
 0.14106   0.476176  0.311356  0.454908  …  0.464364  0.973193  0.535004
 ⋮                                       ⋱
 0.522759  0.390414  0.797637  0.686718     0.901123  0.704603  0.0740788

julia> @btime A[X(Near(35)), Ti(At(DateTime(2001,5)))]
0.3133109280208961
```

Without dim wrappers selectors must be in the right order:

```julia
using Unitful

julia> A = rand(X((1:10:100)u"m"), Ti((1:5:100)u"s"));

julia> A[Between(10.5u"m", 50.5u"m"), Near(23u"s")]
4-element DimArray{Float64,1} with dimensions:
  X: (11:10:41) m (Sampled - Ordered Regular Points)
and reference dimensions:
  Ti(21 s) (Time): 21 s (Sampled - Ordered Regular Points)
 0.584028
 ⋮
 0.716715
```

## Methods where dims can be used containing indices or Selectors

`getindex`, `setindex!` `view`

## Methods where dims, dim types, or `Symbol`s can be used to indicate the array dimension:

- `size`, `axes`, `firstindex`, `lastindex`
- `cat`, `reverse`, `dropdims`
- `reduce`, `mapreduce`
- `sum`, `prod`, `maximum`, `minimum`,
- `mean`, `median`, `extrema`, `std`, `var`, `cor`, `cov`
- `permutedims`, `adjoint`, `transpose`, `Transpose`
- `mapslices`, `eachslice`

## Methods where dims can be used to construct `DimArray`s:
- `fill`, `ones`, `zeros`, `rand`

## Warnings

Indexing with unordered or reverse order arrays has undefined behaviour.
It will trash the dimension index, break `searchsorted` and nothing will make
sense any more. So do it at you own risk. However, indexing with sorted vectors
of Int can be useful. So it's allowed. But it will still do strange things
to your interval sizes if the dimension span is `Irregular`.


## Alternate Packages

There are a lot of similar Julia packages in this space. AxisArrays.jl, NamedDims.jl, NamedArrays.jl are registered alternative that each cover some of the functionality provided by DimensionalData.jl. DimensionalData.jl should be able to replicate most of their syntax and functionality.

[AxisKeys.jl](https://github.com/mcabbott/AxisKeys.jl) and [AbstractIndices.jl](https://github.com/Tokazama/AbstractIndices.jl) are some other interesting developments. For more detail on why there are so many similar options and where things are headed, read this [thread](https://github.com/JuliaCollections/AxisArraysFuture/issues/1).
