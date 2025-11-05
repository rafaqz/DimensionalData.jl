
```@meta
Description = "Complete API reference for DimensionalData.jl - arrays, stacks, dimensions, selectors, and utility functions documentation"
```

# API Reference

## Arrays

```@docs
DimensionalData.AbstractBasicDimArray
AbstractDimArray
DimArray
```

Shorthand `AbstractDimArray` constructors:

```@docs
Base.fill
Base.rand
Base.zeros
Base.ones
```

Functions for getting information from objects:

```@docs
dims
refdims
metadata
name
otherdims
dimnum
hasdim
```

## Multi-array datasets

```@docs
AbstractDimStack
DimStack
maplayers
```

## DimTree 

These objects and methods are still experimental and
subject to breaking changes _without_ breaking versions.

```@docs
AbstractDimTree
DimTree
prune
```

## Dimension generators

```@docs
DimIndices
DimSelectors
DimPoints
DimensionalData.DimSlices
```

## Tables.jl/TableTraits.jl interface

```@docs
DimensionalData.AbstractDimTable
DimTable
```

## Group by methods

For transforming DimensionalData objects:

```@docs
groupby
combine
DimensionalData.DimGroupByArray
Bins
ranges
intervals
CyclicBins
seasons
months
hours
```

## Utility methods

For transforming DimensionalData objects:

```@docs
set
rebuild
modify
@d
broadcast_dims
broadcast_dims!
mergedims
unmergedims
reorder
```

## Global lookup strictness settings

Control how strict DimensionalData when comparing [`Lookup`](@ref)s
before doing broadcasts, matrix multipications, or indexing with 
possibly unordered `AbstractVector{Int}`.

In some cases (especially `DimVector` and small `DimArray`) checking 
lookup values match may be too costly compared to the operations.
You can turn check the current setting and turn them on or off with these
methods.

```@docs
DimensionalData.strict_broadcast
DimensionalData.strict_broadcast!
DimensionalData.strict_matmul
DimensionalData.strict_matmul!
DimensionalData.strict_order
DimensionalData.strict_order!
```

## Base methods

```@docs
Base.cat
Base.copy!
Base.eachslice
Base.skipmissing
```

Most base methods work as expected, using `Dimension` wherever a `dims`
keyword is used. They are not all specifically documented here.

## Name

```@docs
DimensionalData.AbstractName
DimensionalData.Name
DimensionalData.NoName
```

## Internal interface

```@docs
DimensionalData.DimArrayInterface
DimensionalData.DimStackInterface
DimensionalData.rebuild_from_arrays
DimensionalData.rebuildsliced
DimensionalData.show_main
DimensionalData.show_after
DimensionalData.refdims_title
```
