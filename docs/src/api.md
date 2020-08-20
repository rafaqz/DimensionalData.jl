
# API

To use the functionality of DimensionalData in your module, dispatch on `AbstractDimensionalArray` and `AbstractDimension`.

Arrays:

```@docs
AbstractDimensionalArray
DimensionalArray
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

## Index Modes

```@docs
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
DimensionalData.Forward
DimensionalData.Reverse
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

## Methods

## Getting basic info

These useful functions for obtaining information from your dimensional data:

```@docs
bounds
data
dimnum
dims
hasdim
label
mode
metadata
name
refdims
shortname
units
val
```

And some utility methods for transforming DimensionalData objects:

```@docs
rebuild
modify
setdims
swapdims
reorderindex
reorderarray
reorderrelation
```

## Non-exported methods for developers

```@docs
DimensionalData.dims2indices
DimensionalData.formatdims
DimensionalData.reducedims
DimensionalData.slicedims
DimensionalData.comparedims
DimensionalData.identify
```
