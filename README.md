# DimensionalData

[![](https://img.shields.io/badge/docs-stable-blue.svg)](https://rafaqz.github.io/DimensionalData.jl/stable)
[![](https://img.shields.io/badge/docs-dev-blue.svg)](https://rafaqz.github.io/DimensionalData.jl/dev)
![CI](https://github.com/rafaqz/DimensionalData.jl/workflows/CI/badge.svg)
[![Codecov](https://codecov.io/gh/rafaqz/DimensionalData.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/rafaqz/DimensionalData.jl)
[![Aqua.jl Quality Assurance](https://img.shields.io/badge/Aqua.jl-%F0%9F%8C%A2-aqua.svg)](https://github.com/JuliaTesting/Aqua.jl)

DimensionalData.jl provides tools and abstractions for working with datasets
that have named dimensions, and optionally a lookup index. It provides no-cost
abstractions for named indexing, and fast index lookups.

DimensionalData is a pluggable, generalised version of
[AxisArrays.jl](https://github.com/JuliaArrays/AxisArrays.jl) with a cleaner
syntax, and additional functionality found in NamedDims.jl. It has similar goals
to pythons [xarray](http://xarray.pydata.org/en/stable/), and is primarily
written for use with spatial data in [Rasters.jl](https://github.com/rafaqz/Rasters.jl).

The basic syntax is:

```julia
julia> using DimensionalData

julia> A = rand(X(1:40), Y(50))
40×50 DimArray{Float64,2} with dimensions:
  X Sampled 1:40 ForwardOrdered Regular Points,
  Y
 0.30092   0.227971  0.128361  …  0.389487  0.0555927  0.871982
 0.159059  0.394427  0.809897     0.226557  0.741705   0.0789759
 ⋮                             ⋱
 0.425069  0.632975  0.908398     0.965678  0.5779     0.842689
 0.567717  0.803798  0.799519     0.577853  0.498151   0.277229

julia> A[Y=1, X=1:10]
10-element DimArray{Float64,1} with dimensions:
  X Sampled 1:10 ForwardOrdered Regular Points
and reference dimensions: Y
 0.112816
 0.770233
 0.760037
 ⋮
 0.953163
 0.626103
 0.38987
```

[See the docs for more details](https://rafaqz.github.io/DimensionalData.jl/stable)

Some properties of DimensionalData.jl objects:
- broadcasting and most Base methods maintain and sync dimension context.
- comprehensive plot recipes for Plots.jl.
- a Tables.jl interface with `DimTable`
- multi-layered `DimStack`s that can be indexed together, 
    and have base methods applied to all layers.
- the Adapt.jl interface for use on GPUs, even as GPU kernel arguments.
- traits for handling a wide range of spatial data types accurately.

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
- `fill`, `ones`, `zeros`, `falses`, `trues`, `rand`

## **Note**: recent changes have greatly reduced the exported API

Previously exported methods can me brought into global scope by `using`
the sub-modules they have been moved to - `LookupArrays` and `Dimensions`:

```julia
using DimensionalData
using DimensionalData.LookupArrays, DimensionalData.Dimensions
```

## Alternate Packages

There are a lot of similar Julia packages in this space. AxisArrays.jl, NamedDims.jl, NamedArrays.jl are registered alternative that each cover some of the functionality provided by DimensionalData.jl. DimensionalData.jl should be able to replicate most of their syntax and functionality.

[AxisKeys.jl](https://github.com/mcabbott/AxisKeys.jl) and [AbstractIndices.jl](https://github.com/Tokazama/AbstractIndices.jl) are some other interesting developments. For more detail on why there are so many similar options and where things are headed, read this [thread](https://github.com/JuliaCollections/AxisArraysFuture/issues/1).

The main functionality is explained here, but the full list of features is
listed at the [API](@ref) page.
