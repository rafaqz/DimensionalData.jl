
# Dimensions

Dimensions are kept in the sub-module `Dimensions`.

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
```

### Exported methods

These are widely useful methods for working with dimensions.

```@docs
dims
dimnum
hasdim
otherdims
val
```

### Non-exported methods

```@docs
Dimensions.label
DimensionalData.format
DimensionalData.dims2indices
DimensionalData.selectindices
```

### Primitive methods

These low-level methods are really for internal use, but 
can be useful for writing dimensional algorithms.

They are not guaranteed to keep their interface, but usually will.

```@docs
DimensionalData.commondims
DimensionalData.dim2key
DimensionalData.key2dim
DimensionalData.reducedims
DimensionalData.swapdims
DimensionalData.slicedims
DimensionalData.comparedims
DimensionalData.combinedims
DimensionalData.sortdims
DimensionalData.basetypeof
DimensionalData.basedims
DimensionalData.setdims
DimensionalData.dimsmatch
DimensionalData.dimstride
DimensionalData.refdims_title
```
