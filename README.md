# DimensionalData

[![](https://img.shields.io/badge/docs-stable-blue.svg)](https://rafaqz.github.io/DimensionalData.jl/stable)
[![](https://img.shields.io/badge/docs-dev-blue.svg)](https://rafaqz.github.io/DimensionalData.jl/dev)
[![CI](https://github.com/rafaqz/DimensionalData.jl/actions/workflows/ci.yml/badge.svg)](https://github.com/rafaqz/DimensionalData.jl/actions/workflows/ci.yml)
[![Codecov](https://codecov.io/gh/rafaqz/DimensionalData.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/rafaqz/DimensionalData.jl/tree/main)
[![Aqua.jl Quality Assurance](https://img.shields.io/badge/Aqua.jl-%F0%9F%8C%A2-aqua.svg)](https://github.com/JuliaTesting/Aqua.jl)

DimensionalData.jl provides tools and abstractions for working with datasets
that have named dimensions, and optionally a lookup index. It provides no-cost
abstractions for named indexing, and fast index lookups.

DimensionalData is a pluggable, generalised version of
[AxisArrays.jl](https://github.com/JuliaArrays/AxisArrays.jl) with a cleaner
syntax, and additional functionality found in NamedDims.jl. It has similar goals
to pythons [xarray](http://xarray.pydata.org/en/stable/), and is primarily
written for use with spatial data in [Rasters.jl](https://github.com/rafaqz/Rasters.jl).

[!IMPORTANT]

The basic syntax is:

```julia
julia> using DimensionalData

julia> A = DimArray(rand(50, 31), (X(), Y(10.0:40.0)));
```

Or just use `rand` directly, which also works for `zeros`, `ones` and `fill`:

```julia
julia> A = rand(X(50), Y(10.0:40.0))
50×31 DimArray{Float64,2} with dimensions: 
  X,
  Y Sampled{Float64} 10.0:1.0:40.0 ForwardOrdered Regular Points
 10.0         11.0       12.0       13.0       14.0        15.0       16.0        17.0       …  32.0       33.0        34.0       35.0       36.0        37.0       38.0        39.0       40.0
  0.293347     0.737456   0.986853   0.780584   0.707698    0.804148   0.632667    0.780715      0.767575   0.555214    0.872922   0.808766   0.880933    0.624759   0.803766    0.796118   0.696768
  0.199599     0.290297   0.791926   0.564099   0.0241986   0.239102   0.0169679   0.186455      0.644238   0.467091    0.524335   0.42627    0.982347    0.324083   0.0356058   0.306446   0.117187
  ⋮                                                         ⋮                                ⋱                                     ⋮                                                        ⋮
  0.720404     0.388392   0.635609   0.430277   0.943823    0.661993   0.650442    0.91391   …   0.299713   0.518607    0.411973   0.410308   0.438817    0.580232   0.751231    0.519257   0.598583
  0.00602102   0.270036   0.696129   0.139551   0.924883    0.190963   0.164888    0.13436       0.717962   0.0452556   0.230943   0.848782   0.0362465   0.363868   0.709489    0.644131   0.801824
```

Subsetting by index is easy:

```julia
julia> A[Y=1:10, X=1]
10-element DimArray{Float64,1} with dimensions: 
  Y Sampled{Float64} 10.0:1.0:19.0 ForwardOrdered Regular Points
and reference dimensions: X
 10.0  0.293347
 11.0  0.737456
 12.0  0.986853
 13.0  0.780584
  ⋮    
 17.0  0.780715
 18.0  0.472306
 19.0  0.20442
```

We can also subset by lookup, using a `Selector`, lets try `At`: 

```julia
julia> A[Y(At(25))]
50-element DimArray{Float64,1} with dimensions: X
and reference dimensions:
  Y Sampled{Float64} 25.0:1.0:25.0 ForwardOrdered Regular Points
  1  0.459012
  2  0.829744
  3  0.633234
  4  0.971626
  ⋮
 47  0.454685
 48  0.912836
 49  0.906528
 50  0.36339
```

There is also `Near` (for inexact/nearest selection), `Contains` (for `Intervals` containing values), 
`Between` or `..` for range selection, and `Where` for queries, among others.

Plotting with Makie.jl is as easy as:

```julia
using GLMakie, DimensionalData
boxplot(rand(X('a':'d'), Y(2:5:20)))
```

And the plot will have the right ticks and labels.

[See the docs for more details](https://rafaqz.github.io/DimensionalData.jl/stable)

Some properties of DimensionalData.jl objects:
- broadcasting and most Base methods maintain and sync dimension context.
- comprehensive plot recipes for both Plots.jl and Makie.jl.
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
listed at the [API](https://rafaqz.github.io/DimensionalData.jl/stable/api/) page.
