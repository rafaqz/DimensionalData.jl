# API
To use the functionality of DimensionalData in your module, please dispatch on `AbstractDimensionalArray` and `AbstractDimension`.
## Core types
```@docs
DimensionalArray
Dim
@dim
```
In addition, DimensionalData.jl exports the pre-defined dimensions `X, Y, Z, Time`.

## Getting basic info
Here are some very useful functions for obtaining basic information from your dimensional data:
```@docs
dims
hasdim
dimnum
dims2indices
name
val
```
as well as others that are more related with obtained metadata:
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

## Methods with dim keyword
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

## Low level API
```@docs
DimensionalData.rebuild
DimensionalData.formatdims
DimensionalData.reducedims
DimensionalData.slicedims
```

## Grids
Here @rafaqz needs to write, because I really don't know grids... :)
```@docs
AlignedGrid
BoundedGrid
CategoricalGrid
DependentGrid
IndependentGrid
Ordered
RegularGrid
SingleSample
TransformedGrid
UnknownGrid
DimensionalData.identify
```
