# DimensionalData

[![](https://img.shields.io/badge/docs-stable-blue.svg)](https://rafaqz.github.io/DimensionalData.jl/stable)
[![](https://img.shields.io/badge/docs-dev-blue.svg)](https://rafaqz.github.io/DimensionalData.jl/dev)
[![CI](https://github.com/rafaqz/DimensionalData.jl/actions/workflows/ci.yml/badge.svg)](https://github.com/rafaqz/DimensionalData.jl/actions/workflows/ci.yml)
[![Codecov](https://codecov.io/gh/rafaqz/DimensionalData.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/rafaqz/DimensionalData.jl/tree/main)
[![Aqua.jl Quality Assurance](https://img.shields.io/badge/Aqua.jl-%F0%9F%8C%A2-aqua.svg)](https://github.com/JuliaTesting/Aqua.jl)

> [!TIP]
> Visit the latest documentation at https://rafaqz.github.io/DimensionalData.jl/dev/
>
> Visit the stable documentation at https://rafaqz.github.io/DimensionalData.jl/stable/
>

DimensionalData.jl provides tools and abstractions for working with datasets
that have named dimensions, and optionally a lookup index. It provides no-cost
abstractions for named indexing, and fast index lookups.

DimensionalData is a pluggable, generalised version of
[AxisArrays.jl](https://github.com/JuliaArrays/AxisArrays.jl) with a cleaner
syntax, and additional functionality found in NamedDims.jl. It has similar goals
to pythons [xarray](http://xarray.pydata.org/en/stable/), and is primarily
written for use with spatial data in [Rasters.jl](https://github.com/rafaqz/Rasters.jl).

> [!IMPORTANT]
> INSTALLATION

```shell
julia>]
pkg> add DimensionalData
```

Start using the package:

```julia
using DimensionalData
```

The basic syntax is:

```julia
A = DimArray(rand(50, 31), (X(), Y(10.0:40.0)));
```

Or just use `rand` directly, which also works for `zeros`, `ones` and `fill`:

```julia
A = rand(X(10), Y(10.0:20.0))
```
```julia
╭───────────────────────────╮
│ 10×11 DimArray{Float64,2} │
├───────────────────────────┴──────────────────────────────── dims ┐
  ↓ X,
  → Y Sampled{Float64} 10.0:1.0:20.0 ForwardOrdered Regular Points
└──────────────────────────────────────────────────────────────────┘
 10.0       11.0       12.0        13.0       14.0         …  16.0       17.0       18.0        19.0       20.0
  0.71086    0.689255   0.672889    0.766345   0.00277696      0.773863   0.252199   0.279538    0.808931   0.783528
  0.934464   0.815631   0.815715    0.890573   0.158584        0.304733   0.936321   0.499803    0.839926   0.979722
  ⋮                                                        ⋱                                                ⋮
  0.935495   0.460879   0.0218015   0.703387   0.756411    …   0.431141   0.619897   0.0536918   0.506488   0.170494
  0.800226   0.208188   0.512795    0.421171   0.492668        0.238562   0.4694     0.320596    0.934364   0.147563
```

> [!NOTE]
> Subsetting by index is easy:

```julia
A[Y=1:10, X=1]
```
```julia
╭────────────────────────────────╮
│ 10-element DimArray{Float64,1} │
├────────────────────────────────┴─────────────────────────── dims ┐
  ↓ Y Sampled{Float64} 10.0:1.0:19.0 ForwardOrdered Regular Points
└──────────────────────────────────────────────────────────────────┘
 10.0  0.130198
 11.0  0.693343
 12.0  0.400656
  ⋮    
 17.0  0.877581
 18.0  0.866406
 19.0  0.605331
```

We can also subset by lookup, using a `Selector`, lets try `At`: 

```julia
A[Y(At(25))]
```
```julia
╭────────────────────────────────╮
│ 50-element DimArray{Float64,1} │
├────────────────────────── dims ┤
  ↓ X
└────────────────────────────────┘
  1  0.5318
  2  0.212491
  3  0.99119
  4  0.373549
  5  0.0987397
  ⋮  
 46  0.503611
 47  0.225421
 48  0.293564
 49  0.976395
 50  0.622586
```

There is also `Near` (for inexact/nearest selection), `Contains` (for `Intervals` containing values), 
`Between` or `..` for range selection, and `Where` for queries, among others.

Plotting with Makie.jl is as easy as:

```julia
using GLMakie, DimensionalData
boxplot(rand(X('a':'d'), Y(2:5:20)))
```

And the plot will have the right ticks and labels.

[See the docs for more details](https://rafaqz.github.io/DimensionalData.jl/)

> [!NOTE]
> Recent changes have greatly reduced the exported API.

Previously exported methods can me brought into global scope by `using`
the sub-modules they have been moved to - `LookupArrays` and `Dimensions`:

```julia
using DimensionalData
using DimensionalData.LookupArrays, DimensionalData.Dimensions
```

> [!IMPORTANT]
> Alternate Packages

There are a lot of similar Julia packages in this space. AxisArrays.jl, NamedDims.jl, NamedArrays.jl are registered alternative that each cover some of the functionality provided by DimensionalData.jl. DimensionalData.jl should be able to replicate most of their syntax and functionality.

[AxisKeys.jl](https://github.com/mcabbott/AxisKeys.jl) and [AbstractIndices.jl](https://github.com/Tokazama/AbstractIndices.jl) are some other interesting developments. For more detail on why there are so many similar options and where things are headed, read this [thread](https://github.com/JuliaCollections/AxisArraysFuture/issues/1).

The main functionality is explained here, but the full list of features is
listed at the [API](https://rafaqz.github.io/DimensionalData.jl/reference) page.