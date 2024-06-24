
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
Dimensions.AnonDim
Dimensions.@dim
```

### Exported methods

These are widely useful methods for working with dimensions.

```@docs; canonical=false
dims
otherdims
dimnum
hasdim
```

### Non-exported methods

```@docs
Dimensions.lookup
Dimensions.label
Dimensions.format
Dimensions.dims2indices
Dimensions.selectindices
```

### Primitive methods

These low-level methods are really for internal use, but 
can be useful for writing dimensional algorithms.

They are not guaranteed to keep their interface, but usually will.

```@docs
Dimensions.commondims
Dimensions.name2dim
Dimensions.reducedims
Dimensions.swapdims
Dimensions.slicedims
Dimensions.comparedims
Dimensions.combinedims
Dimensions.sortdims
Dimensions.basetypeof
Dimensions.basedims
Dimensions.setdims
Dimensions.dimsmatch
```
