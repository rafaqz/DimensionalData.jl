
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
Lookups.AutoIndex
```

The generic value getter `val`

```@docs
Lookups.val
```

Lookup methods:

```@docs
bounds
hasselection
Lookups.index
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

### Loci

```@docs
Lookups.Locus
Lookups.Center
Lookups.Start
Lookups.End
Lookups.AutoLocus
```

## Metadata

```@docs
Lookups.AbstractMetadata
Lookups.Metadata
Lookups.NoMetadata
Lookups.units
```
