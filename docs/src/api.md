
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
Dimension
DependentDim
IndependentDim
XDim
YDim
ZDim
TimeDim
X
Y
Z
Ti
ParametricDimension
Dim
Coord
AnonDim
@dim
```


## Selectors

```@docs
Selector
At
Near
Between
Contains
Where
```

## Name

```@docs
DimensionalData.AbstractName
Name
NoName
```

## Metadata

```@docs
AbstractMetadata
Metadata
NoMetadata
```

## Lookups

```@docs
Lookup
Aligned
AbstractSampled
Sampled
AbstractCategorical
Categorical
Unaligned
Transformed
NoLookup
AutoLookup
DimensionalData.AutoIndex
```

## Lookup traits

```@docs
DimensionalData.LookupTrait
```

### Order

```@docs
Order
Unordered
Ordered
AutoOrder
DimensionalData.ForwardOrdered
DimensionalData.ReverseOrdered
```

### Span

```@docs
Span
Regular
Irregular
Explicit
AutoSpan
```

### Sampling

```@docs
Sampling
Points
Intervals
```

### Loci

```@docs
Locus
Center
Start
End
AutoLocus
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
units
label
```

Dimesion and lookup properties:

```@docs
val
index
lookup
bounds
sampling
locus
span
order
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
