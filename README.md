# DimensionalData

[![](https://img.shields.io/badge/docs-stable-blue.svg)](https://rafaqz.github.io/DimensionalData.jl/stable)
[![](https://img.shields.io/badge/docs-dev-blue.svg)](https://rafaqz.github.io/DimensionalData.jl/dev)
[![Build Status](https://travis-ci.org/rafaqz/DimensionalData.jl.svg?branch=master)](https://travis-ci.org/rafaqz/DimensionalData.jl)
[![Codecov](https://codecov.io/gh/rafaqz/DimensionalData.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/rafaqz/DimensionalData.jl)
[![Aqua.jl Quality Assurance](https://img.shields.io/badge/Aqua.jl-%F0%9F%8C%A2-aqua.svg)](https://github.com/JuliaTesting/Aqua.jl)


DimensionalData.jl provides tools and abstractions for working with datasets
that have named dimensions. It's a pluggable, generalised version of
[AxisArrays.jl](https://github.com/JuliaArrays/AxisArrays.jl) with a cleaner
syntax, and additional functionality found in NamedDims.jl. It has similar
goals to pythons [xarray](http://xarray.pydata.org/en/stable/), and is primarily
written for use with spatial data in [GeoData.jl](https://github.com/rafaqz/GeoData.jl).


## Dimensions

Dimensions are just wrapper types. They store the dimension index
and define details about the grid and other metadata, and are also used
to index into the array, wrapping a value or a `Selector`.
`X`, `Y`, `Z` and `Ti` are the exported defaults.

A generalised `Dim` type is available to use arbitrary symbols to name dimensions.
Custom dimensions can be defined using the `@dim` macro.

We can use dim wrappers for indexing, so that the dimension order in the underlying array
does not need to be known:

```julia
julia> using DimensionalData

julia> A = DimArray(rand(40, 50), (X, Y));

julia> A[Y(1), X(1:10)]
DimArray with dimensions:
 X: 1:10 (NoIndex)
and referenced dimensions:
 Y: 1 (NoIndex)
and data: 10-element Array{Float64,1}
[0.515774, 0.575247, 0.429075, 0.234041, 0.4484, 0.302562, 0.911098, 0.541537, 0.267234, 0.370663]
```

And this has no runtime cost:

```julia
julia> using BenchmarkTools

julia> @btime A[X(1), Y(2)]
  25.068 ns (1 allocation: 16 bytes)
0.7302366320496405

julia> @btime parent(A)[1, 2]
  34.061 ns (1 allocation: 16 bytes)
0.7302366320496405
```

Dims can be used for indexing and views without knowing dimension order:

```julia
A[X(10)]
view(A, Y(30:40), X(1:20))
```

And for indicating dimensions to reduce or permute in julia
`Base` and `Statistics` functions that have dims arguments:

```julia
using Statistics

A = DimArray(rand(10, 10, 100), (X, Y, Ti));
mean(A, dims=Ti)
permutedims(A, [Ti, Y, X])
```

You can also use arbitrary symbol to create `Dim{X}` dimensions:


```julia
julia> A = DimArray(rand(10, 20, 30), (:a, :b, :c));

julia> A[a=2:5, c=9]

DimArray with dimensions:
 Dim{:a}: 2:5 (NoIndex)
 Dim{:b}: Base.OneTo(20) (NoIndex)
and referenced dimensions:
 Dim{:c}: 9 (NoIndex)
and data: 4×20 Array{Float64,2}
 0.868237   0.528297   0.32389   …  0.89322   0.6776    0.604891
 0.635544   0.0526766  0.965727     0.50829   0.661853  0.410173
 0.732377   0.990363   0.728461     0.610426  0.283663  0.00224321
 0.0849853  0.554705   0.594263     0.217618  0.198165  0.661853
```

Other methods also work:

```julia
julia> bounds(A, (:b, :c))

((1, 20), (1, 30))

julia> mean(A, dim=Dim{:b})

julia> mean(A, dims=Dim{:b})
DimArray with dimensions:
 Dim{:a}: Base.OneTo(10) (NoIndex)
 Dim{:b}: 1 (NoIndex)
 Dim{:c}: Base.OneTo(30) (NoIndex)
and data: 10×1×30 Array{Float64,3}
[:, :, 1]
 0.543099
 0.542407
 0.540647
 0.513554
 0.601689
 0.601558
 0.46997
 0.524254
 0.601844
 0.520966
[and 29 more slices...]
```


## Selectors

Selectors find indices in the dimension based on values `At`, `Near`, or
`Between` the index value(s). They can be used in `getindex`, `setindex!` and
`view` to select indices matching the passed in value(s)

- `At(x)`: get indices exactly matching the passed in value(s)
- `Near(x)`: get the closest indices to the passed in value(s)
- `Where(f::Function)`: filter the array axis by a function of dimension
  index values.
- `Between(a, b)`: get all indices between two values (inclusive)
- `Contains(x)`: get indices where the value x falls in the interval.
  Only used for `Sampled` `Intervals`, for `Points` us `At`.

We can use selectors with dim wrappers:

```julia
A[X(Between(1, 10)), Y(At(25.7))]
```

Without dim wrappers selectors must be in the right order:

```julia
using Unitful

julia> A = DimArray(rand(10, 20), (X((1:10:100)u"m"), Ti((1:5:100)u"s")))

julia> A[Between(10.5u"m", 50.5u"m"), Near(23u"s")]
DimArray with dimensions:
 X: (11:10:41) m (Sampled: Ordered Regular Points)
and referenced dimensions:
 Time (type Ti): 21 s (Sampled: Ordered Regular Points)
and data: 4-element Array{Float64,1}
[0.819172, 0.418113, 0.461722, 0.379877]
```

For values other than `Int`/`AbstractArray`/`Colon` (which are set aside for
regular indexing) the `At` selector is assumed, and can be dropped completely:

```julia
julia> A = DimArray(rand(3, 3), (X(Val((:a, :b, :c))), Y([25.6, 25.7, 25.8])))
DimArray with dimensions:
 X: Val{(:a, :b, :c)}()
 Y: Float64[25.6, 25.7, 25.8]
and data: 3×3 Array{Float64,2}
 0.280308  0.92255    0.023938
 0.129487  0.0993857  0.618391
 0.246378  0.276186   0.0425624

julia> A[:b, 25.8]
0.61839141062599
```

Using all `Val` indexes (only recommended for small arrays)
you can index with named dimensions `At` arbitrary values with no
runtime cost:


```julia
using BenchmarkTools

julia> A = DimArray(rand(3, 3), (cat=Val((:a, :b, :c)),
                                 val=Val((5.0, 6.0, 7.0))))
DimArray with dimensions:
 Dim{:cat}: Val{(:a, :b, :c)}() (Categorical: Unordered)
 Dim{:val}: Val{(5.0, 6.0, 7.0)}() (Categorical: Unordered)
and data: 3×3 Array{Float64,2}
 0.993357  0.765515  0.914423
 0.405196  0.98223   0.330779
 0.365312  0.388873  0.88732

julia> @btime A[:a, 7.0]
  26.333 ns (1 allocation: 16 bytes)
0.32927504968939925

julia> @btime A[cat=:a, val=7.0]
  31.920 ns (2 allocations: 48 bytes)
0.7476441117572306
```

It's also easy to write your own custom `Selector` if your need a different behaviour.

_Example usage:_

```julia
using Dates, DimensionalData
timespan = DateTime(2001,1):Month(1):DateTime(2001,12)
A = DimArray(rand(12,10), (Ti(timespan), X(10:10:100)))

julia> A[X(Near(35)), Ti(At(DateTime(2001,5)))]
0.658404535807791

julia> A[Near(DateTime(2001, 5, 4)), Between(20, 50)]
DimArray with dimensions:
 X: 20:10:50
and referenced dimensions:
 Time (type Ti): 2001-05-01T00:00:00
and data: 4-element Array{Float64,1}
[0.456175, 0.737336, 0.658405, 0.520152]
```

Dim types or objects can be used instead of a dimension number in many
Base and Statistics methods:

## Methods where dims can be used containing indices or Selectors

`getindex`, `setindex!` `view`

## Methods where dims can be used

- `size`, `axes`, `firstindex`, `lastindex`
- `cat`
- `reverse`
- `dropdims`
- `reduce`, `mapreduce`
- `sum`, `prod`, `maximum`, `minimum`,
- `mean`, `median`, `extrema`, `std`, `var`, `cor`, `cov`
- `permutedims`, `adjoint`, `transpose`, `Transpose`
- `mapslices`, `eachslice`
- `fill`

_Example usage:_

```julia
A = DimArray(rand(20,10), (X, Y))
size(A, Y)
using Statistics
mean(A, dims=X)
std(A; dims=Y())
```

## Warnings

Indexing with unordered or reverse order arrays has undefined behaviour.
It will trash the dimension index, break `searchsorted` and nothing will make
sense any more. So do it at you own risk. However, indexing with sorted vectors
of Int can be useful. So it's allowed. But it will still do strange things
to your interval sizes if the dimension span is `Irregular`.


## Alternate Packages

There are a lot of similar Julia packages in this space. AxisArrays.jl, NamedDims.jl, NamedArrays.jl are registered alternative that each cover some of the functionality provided by DimensionalData.jl. DimensionalData.jl should be able to replicate any of their functionality, although with slightly more verbose syntax and less polish in some cases. If there is anything it doesn't do that these packages can do, put in an issue with the feature request.

[AxisRanges.jl](https://github.com/mcabbott/AxisRanges.jl) and [AbstractIndices.jl](https://github.com/Tokazama/AbstractIndices.jl) are some other interesting developments. For more detail on why there are so many similar options and where things are headed, read this [thread](https://github.com/JuliaCollections/AxisArraysFuture/issues/1).
