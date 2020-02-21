# API

To use the functionality of DimensionalData in your module, dispatch on `AbstractDimensionalArray` and `AbstractDimension`.

## Core types

Arrays:

```@docs
AbstractDimensionalArray
DimensionalArray
```

Dimensions:

```@docs
AbstractDimension
XDim
YDim
ZDim
TimeDim
X
Y
Z
Ti
Dim
@dim
```

## Getting basic info

These useful functions for obtaining information from your dimensional data:

```@docs
dims
hasdim
dimnum
name
val
```

As well as others related to obtained metadata:

```@docs
bounds
label
metadata
refdims
shortname
units
data
```

## Selectors

```@docs
Selector
At
Near
Between
```

## Grids

```@docs
Grid
IndependentGrid
AlignedGrid
BoundedGrid
RegularGrid
CategoricalGrid
UnknownGrid
DependentGrid
TransformedGrid
```

Tracking the order of arrays and indices:

```@docs
Unordered
Ordered
```

### Loci

```@docs
Locus
Center
Start
End
UnknownLocus
```


## Low-level API

```@docs
DimensionalData.rebuild
DimensionalData.formatdims
DimensionalData.reducedims
DimensionalData.slicedims
```
