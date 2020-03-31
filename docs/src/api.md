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
PlaceholderDim
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
AlignedIndex
AbstractSampledIndex
SampledIndex
AbstractCategoricalIndex
CategoricalIndex
UnalignedIndex
TransformedIndex
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

Index modes for [`SampledIndex`](@ref)

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
RegularSpan
IrregularSpan
AutoSpan
```

### Sampling

```@docs
Sampling
PointSampling
IntervalSampling
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
