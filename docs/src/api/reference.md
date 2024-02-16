
# API Reference

## Arrays

```@docs
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
```

## Multi-array datasets

```@docs
AbstractDimStack
DimStack
```

## Dimension generators

```@docs
DimIndices
DimKeys
DimPoints
```

## Tables.jl/TableTraits.jl interface

```@docs
DimensionalData.AbstractDimTable
DimTable
DimensionalData.DimColumn
```

# Utility methods

For transforming DimensionalData objects:

```@docs
set
rebuild
modify
broadcast_dims
broadcast_dims!
mergedims
unmergedims
reorder
```

Base methods

```@docs
Base.cat
Base.map
Base.copy!
Base.eachslice
```


Most base methods work as expected, using `Dimension` wherever a `dims`
keyword is used. They are not allspecifically documented here.

## Name

```@docs
DimensionalData.AbstractName
DimensionalData.Name
DimensionalData.NoName
```

## Internal interface methods

```@docs
DimensionalData.rebuild_from_arrays
DimensionalData.show_main
DimensionalData.show_after
```
