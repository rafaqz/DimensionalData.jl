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

julia> rand(X(10.0:40.0), Y(50))
31×50 DimArray{Float64,2} with dimensions:
  X Sampled 10.0:1.0:40.0 ForwardOrdered Regular Points,
  Y
 0.793097  0.489866  0.462396  …  0.910434  0.850573   0.183605
 0.76277   0.737544  0.290279     0.742267  0.686086   0.530159
 ⋮                             ⋱
 0.281043  0.979182  0.868658     0.642477  0.139536   0.540512
 0.546036  0.83382   0.530098  …  0.351608  0.0385814  0.159299

julia> A[Y=1, X=1:10]
10-element DimArray{Float64,1} with dimensions:
  X Sampled 10.0:1.0:19.0 ForwardOrdered Regular Points
and reference dimensions: Y
 0.245691
 0.902444
 0.777441
 ⋮
 0.744612
 0.440409
 0.631956
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
