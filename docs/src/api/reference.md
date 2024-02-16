
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

## Common methods

Common functions for obtaining information from objects:

```@docs
dims
refdims
metadata
name
```

Utility methods for transforming DimensionalData objects:

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

```
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
