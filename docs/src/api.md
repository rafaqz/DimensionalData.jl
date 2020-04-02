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
AutoIndex
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

Index modes for [`Sampled`](@ref)

### Loci

```@docs
Locus
Center
Start
End
AutoLocus
```

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
metadata
name
rebuild
refdims
shortname
units
val
```

And some utility methods:

```@docs
setdim
swapdims
```

## Low-level methods

```@docs
DimensionalData.dims2indices
DimensionalData.formatdims
DimensionalData.reducedims
DimensionalData.slicedims
DimensionalData.comparedims
DimensionalData.identify
DimensionalData.DimensionalStyle
```
