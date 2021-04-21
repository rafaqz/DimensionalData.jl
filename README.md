# DimensionalData

[![](https://img.shields.io/badge/docs-stable-blue.svg)](https://rafaqz.github.io/DimensionalData.jl/stable)
[![](https://img.shields.io/badge/docs-dev-blue.svg)](https://rafaqz.github.io/DimensionalData.jl/dev)
![CI](https://github.com/rafaqz/DimensionalData.jl/workflows/CI/badge.svg)
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

julia> A = rand(X(40), Y(50));

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
julia> A = rand(40, 50), (X, Y));

julia> @btime $A[X(1), Y(2)]
  2.092 ns (0 allocations: 0 bytes)
0.27317596504655417

julia> @btime parent($A)[1, 2]
  2.092 ns (0 allocations: 0 bytes)
0.27317596504655417
```

Dims can be used for indexing and views without knowing dimension order:

```julia


```

And for indicating dimensions to reduce or permute in julia
`Base` and `Statistics` functions that have dims arguments:

```julia
julia> using Statistics

julia> A = DimArray(rand(3, 4, 5), (X, Y, Ti));

julia> mean(A, dims=Ti)
DimArray with dimensions:
 X (type X): Base.OneTo(3) (NoIndex)
 Y (type Y): Base.OneTo(4) (NoIndex)
 Time (type Ti): 1 (NoIndex)
and data: 3×4×1 Array{Float64,3}
[:, :, 1]
 0.495295  0.650432  0.787521  0.502066
 0.576573  0.568132  0.770812  0.504983
 0.39432   0.5919    0.498638  0.337065
[and 0 more slices...]

julia> permutedims(A, [Ti, Y, X])
DimArray with dimensions:
 Time (type Ti): Base.OneTo(5) (NoIndex)
 Y (type Y): Base.OneTo(4) (NoIndex)
 X (type X): Base.OneTo(3) (NoIndex)
and data: 5×4×3 Array{Float64,3}
[:, :, 1]
 0.401374  0.469474  0.999326  0.265688
 0.439387  0.57274   0.493883  0.88678
 0.425845  0.617372  0.998552  0.650999
 0.852777  0.954702  0.928367  0.0045136
 0.357095  0.637873  0.517476  0.702351
[and 2 more slices...]
```

You can also use symbols to create `Dim{X}` dimensions:

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
julia> A = DimArray(rand(3, 3), (X(Val((:a, :b, :c))), Y([25.6, 25.7, 25.8])));

julia> A[:b, 25.8]
0.61839141062599
```

### Compile-time selectors

Using all `Val` indexes (only recommended for small arrays)
you can index with named dimensions `At` arbitrary values with no
runtime cost:

```julia
julia> A = DimArray(rand(3, 3), (cat=Val((:a, :b, :c)),
                                 val=Val((5.0, 6.0, 7.0))));

julia> @btime $A[:a, 7.0]
  2.094 ns (0 allocations: 0 bytes)
0.25620608873275397

julia> @btime $A[cat=:a, val=7.0]
  2.091 ns (0 allocations: 0 bytes)
0.25620608873275397
```


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

## Warnings

Indexing with unordered or reverse order arrays has undefined behaviour.
It will trash the dimension index, break `searchsorted` and nothing will make
sense any more. So do it at you own risk. However, indexing with sorted vectors
of Int can be useful. So it's allowed. But it will still do strange things
to your interval sizes if the dimension span is `Irregular`.


## Alternate Packages

There are a lot of similar Julia packages in this space. AxisArrays.jl, NamedDims.jl, NamedArrays.jl are registered alternative that each cover some of the functionality provided by DimensionalData.jl. DimensionalData.jl should be able to replicate most of their syntax and functionality.

[AxisKeys.jl](https://github.com/mcabbott/AxisKeys.jl) and [AbstractIndices.jl](https://github.com/Tokazama/AbstractIndices.jl) are some other interesting developments. For more detail on why there are so many similar options and where things are headed, read this [thread](https://github.com/JuliaCollections/AxisArraysFuture/issues/1).
