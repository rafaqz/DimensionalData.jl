
# API

To use the functionality of DimensionalData in your module, dispatch on `AbstractDimArray` and `AbstractDimension`.

## Arrays

```@docs
AbstractDimArray
DimArray
```

## Multi-array datasets

```@docs
AbstractDimStack
DimStack
```

## Dimension indices generator

```@docs
DimIndices
DimKeys
```

## Core types

### Dimensions:

```@docs
DimensionalData.Dimension
DimensionalData.DependentDim
DimensionalData.IndependentDim
DimensionalData.XDim
DimensionalData.YDim
DimensionalData.ZDim
DimensionalData.TimeDim
X
Y
Z
Ti
DimensionalData.ParametricDimension
Dim
Coord
DimensionalData.AnonDim
@dim
```


## Selectors

```@docs
DimensionalData.Selector
At
Near
Between
Contains
Where
```

## Name

```@docs
DimensionalData.AbstractName
DimensionalData.Name
DimensionalData.NoName
```

## Metadata

```@docs
DimensionalData.AbstractMetadata
DimensionalData.Metadata
DimensionalData.NoMetadata
```

## LookupArrays

```@docs
DimensionalData.LookupArray
DimensionalData.Aligned
DimensionalData.AbstractSampled
Sampled
DimensionalData.AbstractCategorical
Categorical
DimensionalData.Unaligned
Transformed
NoLookup
DimensionalData.AutoLookup
DimensionalData.AutoIndex
```

## LookupArray traits

```@docs
DimensionalData.LookupArrayTrait
```

### Order

```@docs
DimensionalData.Order
DimensionalData.Ordered
DimensionalData.ForwardOrdered
DimensionalData.ReverseOrdered
DimensionalData.Unordered
DimensionalData.AutoOrder
```

### Span

```@docs
DimensionalData.Span
DimensionalData.Regular
DimensionalData.Irregular
DimensionalData.Explicit
DimensionalData.AutoSpan
```

### Sampling

```@docs
DimensionalData.Sampling
DimensionalData.Points
DimensionalData.Intervals
```

### Loci

```@docs
DimensionalData.Locus
DimensionalData.Center
DimensionalData.Start
DimensionalData.End
DimensionalData.AutoLocus
```

## Tables.jl interface

```@docs
DimensionalData.AbstractDimTable
DimTable
DimensionalData.DimColumn
```


## Methods

## Getting basic info

These useful functions for obtaining information from your dimensional data:

```@docs
dims
refdims
metadata
name
DimensionalData.units
DimensionalData.label
```

Dimesion and lookup properties:

```@docs
val
lookup
bounds
sampling
locus
span
order
DimensionalData.index
```

Dimension querying

```@docs
hasdim
hasselection
dimnum
otherdims
commondims
```

And some utility methods for transforming DimensionalData objects:

```@docs
set
rebuild
modify
dimwise
dimwise!
reorder
Base.fill
Base.rand
Base.zeros
Base.ones
Base.map
Base.copy!
Base.cat
```

## Non-exported methods for developers

```@docs
DimensionalData.dim2key
DimensionalData.key2dim
DimensionalData.dims2indices
DimensionalData.selectindices
DimensionalData.format
DimensionalData.reducedims
DimensionalData.swapdims
DimensionalData.slicedims
DimensionalData.comparedims
DimensionalData.combinedims
DimensionalData.sortdims
DimensionalData.basetypeof
DimensionalData.setdims
DimensionalData.dimsmatch
DimensionalData.dimstride
DimensionalData.refdims_title
DimensionalData.rebuild_from_arrays
DimensionalData.shiftlocus
```
