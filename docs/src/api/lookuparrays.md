
```@meta
Description = "DimensionalData.jl Lookups API - types for dimension values including Sampled, Categorical, Cyclic, and custom lookup arrays"
```

# Lookups

```@docs
Lookups.Lookups
```

```@docs
Lookups.Lookup
Lookups.Aligned
Lookups.AbstractSampled
Lookups.Sampled
Lookups.AbstractCyclic
Lookups.Cyclic
Lookups.AbstractCategorical
Lookups.Categorical
Lookups.Unaligned
Lookups.Transformed
Dimensions.MergedLookup
Lookups.NoLookup
Lookups.AutoLookup
Lookups.AutoValues
```

The generic value getter `val`

```@docs
Lookups.val
```

Lookup methods:

```@docs
bounds
hasselection
Lookups.sampling
Lookups.span
Lookups.order
Lookups.locus
Lookups.shiftlocus
```

## Selectors

```@docs
Lookups.Selector
Lookups.IntSelector
Lookups.ArraySelector
At
Near
Between
Touches
Contains
Where
All
```

## Lookup traits

```@docs
Lookups.LookupTrait
```

### Order

```@docs
Lookups.Order
Lookups.Ordered
Lookups.ForwardOrdered
Lookups.ReverseOrdered
Lookups.Unordered
Lookups.AutoOrder
```

### Span

```@docs
Lookups.Span
Lookups.Regular
Lookups.Irregular
Lookups.Explicit
Lookups.AutoSpan
```

### Sampling

```@docs
Lookups.Sampling
Lookups.Points
Lookups.Intervals
```

### Positions

```@docs
Position
Lookups.Center
Lookups.Start
Lookups.Begin
Lookups.End
Lookups.AutoPosition
```

## Metadata

```@docs
Lookups.AbstractMetadata
Lookups.Metadata
Lookups.NoMetadata
Lookups.units
```
