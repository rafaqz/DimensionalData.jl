
# API Reference

## Arrays

```@docs
DimensionalData.AbstractBasicDimArray
AbstractDimArray
DimArray
```

Shorthand `AbstractDimArray` constructors:

```@docs
Base.fill
Base.rand
Base.zeros
Base.ones
```

Functions for getting information from objects:

```@docs
dims
refdims
metadata
name
otherdims
dimnum
hasdim
```

## Multi-array datasets

```@docs
AbstractDimStack
DimStack
```

## Dimension generators

```@docs
DimIndices
DimSelectors
DimPoints
```

## Tables.jl/TableTraits.jl interface

```@docs
DimensionalData.AbstractDimTable
DimTable
```

# Group by methods

For transforming DimensionalData objects:

```@docs
groupby
DimensionalData.DimGroupByArray
Bins
ranges
intervals
CyclicBins
seasons
months
hours
```

# Utility methods

For transforming DimensionalData objects:

```@docs
set
rebuild
modify
@d
broadcast_dims
broadcast_dims!
mergedims
unmergedims
reorder
```

Base methods

```@docs
Base.cat
Base.copy!
Base.eachslice
```

Most base methods work as expected, using `Dimension` wherever a `dims`
keyword is used. They are not all specifically documented here.

## Name

```@docs
DimensionalData.AbstractName
DimensionalData.Name
DimensionalData.NoName
```

## Internal interface

```@docs
DimensionalData.DimArrayInterface
DimensionalData.DimStackInterface
DimensionalData.rebuild_from_arrays
DimensionalData.show_main
DimensionalData.show_after
DimensionalData.refdims_title
```
