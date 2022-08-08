
# API

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

## Dimension indices generators

```@docs
DimIndices
DimKeys
DimPoints
```

## Tables.jl/TableTraits.jl interface

```@docs
DimensionalData.AbstractDimTable
DimTable
DimensionalData.DimColumn
```

## Common methods

Common functions for obtaining information from objects:

```@docs
dims
refdims
metadata
name
```

Utility methods for transforming DimensionalData objects:

```@docs
set
rebuild
modify
broadcast_dims
broadcast_dims!
reorder
Base.cat
Base.map
Base.copy!
```

Most base methods work as expected, using `Dimension` wherever a `dims`
keyword is used. They are not allspecifically documented here.


Shorthand constructors:

```@docs
Base.fill
Base.rand
Base.zeros
Base.ones
```

# Dimensions

Handling of Dimensions is kept in a sub-module `Dimensions`.

```@docs
Dimensions.Dimensions
```

Dimensions have a type-heirarchy that organises plotting and
dimension matching.

```@docs
Dimensions.Dimension
Dimensions.DependentDim
Dimensions.IndependentDim
Dimensions.XDim
Dimensions.YDim
Dimensions.ZDim
Dimensions.TimeDim
X
Y
Z
Ti
Dim
Coord
Dimensions.AnonDim
@dim
```

### Exported methopds

```@docs
hasdim
dimnum
```


### Non-exported methods

```@docs
Dimensions.lookup
Dimensions.label
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
DimensionalData.otherdims
DimensionalData.commondims
DimensionalData.sortdims
DimensionalData.basetypeof
DimensionalData.setdims
DimensionalData.dimsmatch
DimensionalData.dimstride
DimensionalData.refdims_title
DimensionalData.rebuild_from_arrays
```

# LookupArrays

```@docs
LookupArrays.LookupArrays
```

## Selectors

```@docs
LookupArrays.Selector
LookupArrays.IntSelector
LookupArrays.ArraySelector
At
Near
Between
Contains
Where
All
```

Lookup properties:

```@docs
bounds
LookupArrays.val
```

```@docs
LookupArrays.LookupArray
LookupArrays.Aligned
LookupArrays.AbstractSampled
LookupArrays.Sampled
LookupArrays.AbstractCategorical
LookupArrays.Categorical
LookupArrays.Unaligned
LookupArrays.Transformed
LookupArrays.NoLookup
LookupArrays.AutoLookup
LookupArrays.AutoIndex
```

## Metadata

```@docs
LookupArrays.AbstractMetadata
LookupArrays.Metadata
LookupArrays.NoMetadata
```

## LookupArray traits

```@docs
LookupArrays.LookupArrayTrait
```

### Order

```@docs
LookupArrays.Order
LookupArrays.Ordered
LookupArrays.ForwardOrdered
LookupArrays.ReverseOrdered
LookupArrays.Unordered
LookupArrays.AutoOrder
```

### Span

```@docs
LookupArrays.Span
LookupArrays.Regular
LookupArrays.Irregular
LookupArrays.Explicit
LookupArrays.AutoSpan
```

### Sampling

```@docs
LookupArrays.Sampling
LookupArrays.Points
LookupArrays.Intervals
```

### Loci

```@docs
LookupArrays.Locus
LookupArrays.Center
LookupArrays.Start
LookupArrays.End
LookupArrays.AutoLocus
```

## LookupArrays methods

```@docs
hasselection
LookupArrays.shiftlocus
LookupArrays.sampling
LookupArrays.span
LookupArrays.order
LookupArrays.index
LookupArrays.locus
LookupArrays.units
```

## Name

```@docs
DimensionalData.AbstractName
DimensionalData.Name
DimensionalData.NoName
```
