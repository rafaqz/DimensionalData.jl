# API

To use the functionality of DimensionalData in your module, dispatch on `AbstractDimensionalArray` and `AbstractDimension`.

## Core types

```@docs
AbstractDimensionalArray
AbstractDimension
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
At
Near
Between
```

## Methods with dims keyword

The following functions support specifying the dimension by name instead of by integer for a `DimensionalArray`:

- `size`
- `axes`
- `permutedims`
- `mapslices`
- `eachslice`
- `reverse`
- `dropdims`
- `reduce`
- `mapreduce`
- `sum`
- `prod`
- `maximum`
- `minimum`
- `mean`
- `std `
- `var`
- `cor`
- `cov`
- `median`

## Low-level API

```@docs
DimensionalData.Dim
DimensionalData.@dim
DimensionalData.rebuild
DimensionalData.formatdims
DimensionalData.reducedims
DimensionalData.slicedims
```

## Grids

```@docs
IndependentGrid
AlignedGrid
BoundedGrid
CategoricalGrid
UnknownGrid
RegularGrid
DependentGrid
TransformedGrid
```

Ordered
SingleSample
