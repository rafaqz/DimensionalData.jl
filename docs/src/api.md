
# API

To use the functionality of DimensionalData in your module, dispatch on `AbstractDimArray` and `AbstractDimension`.

## Arrays

```@docs
AbstractDimArray
DimArray
```

## Multi-array datasets

```@docs
AbstractDimDataset
DimDataset
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

## Modes

```@docs
Mode
IndexMode
Aligned
AbstractSampled
Sampled
AbstractCategorical
Categorical
Unaligned
Transformed
NoIndex
AutoMode
```

Order of arrays and indices:

```@docs
Order
Unordered
Ordered
AutoOrder
UnknownOrder
IndexOrder
ForwardIndex
ReverseIndex
ArrayOrder
ForwardArray
ReverseArray
RelationOrder
ForwardRelation
ReverseRelation
```

Index modes for [`Intervals`](@ref)

### Span

```@docs
Span
Regular
Irregular
AutoSpan
```

### Sampling

```@docs
Sampling
Points
Intervals
```

### Loci

Sampling positions for [`Intervals`](@ref)

```@docs
Locus
Center
Start
End
AutoLocus
```

## Tables.jl interface

```@docs
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

Dimesion and mode properties:

```@docs
val
index
mode
bounds
sampling
locus
span
order
indexorder
arrayorder
relation
```

Dimension querying

```@docs
hasdim
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
reverse
```

## Non-exported methods for developers

```@docs
DimensionalData.dim2key
DimensionalData.key2dim
DimensionalData.dims2indices
DimensionalData.formatdims
DimensionalData.reducedims
DimensionalData.swapdims
DimensionalData.slicedims
DimensionalData.comparedims
DimensionalData.sortdims
DimensionalData.identify
DimensionalData.basetypeof
DimensionalData.setdims
DimensionalData.flip
```
