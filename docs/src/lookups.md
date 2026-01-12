```@meta
Description = "Lookups in DimensionalData.jl - define the axes of your data using lookups!"
```

# Lookups

Lookups define the values along each dimension's axis. They wrap an `AbstractArray` and add traits that control indexing behavior, bounds calculations, and selector dispatch.

```@example lookups
using DimensionalData
using DimensionalData.Lookups
```

## Lookup Types

::: tabs

== Sampled

[`Sampled`](@ref) is for numeric/temporal data sampled along an axis. Supports `Points` or `Intervals` sampling with `Regular` or `Irregular` spacing.

```@ansi lookups
# Auto-detected from a range
A = rand(X(1.0:0.5:10.0))
lookup(A, X)
```

```@ansi lookups
# Manual construction with intervals
Sampled(1:10; sampling=Intervals(Start()), span=Regular(1))
```

```@ansi lookups
# Irregular spacing with explicit bounds
Sampled([1, 2, 5, 10, 20]; span=Irregular(0, 25), sampling=Intervals(Start()))
```

== Categorical

[`Categorical`](@ref) is for discrete categories. Auto-detected for `String`, `Symbol`, and `Char` arrays.

```@ansi lookups
A = rand(X([:a, :b, :c]))
lookup(A, X)
```

```@ansi lookups
# Unordered categories
Categorical(["red", "green", "blue"]; order=Unordered())
```

== Cyclic

[`Cyclic`](@ref) wraps values that cycle (longitudes, months, etc.). Selectors wrap around the cycle boundaries.

```@ansi lookups
using Dates
# Monthly data that cycles yearly
months = Cyclic(DateTime(2000):Month(1):DateTime(2000, 12); cycle=Year(1), sampling=Intervals(Start()))
A = DimArray(1:12, X(months))
A[X=At(DateTime(2025, 3))]  # Wraps to March
```

== NoLookup

[`NoLookup`](@ref) has no index values. Selectors don't work; only integer indexing. This is the default when no lookup values are provided.

```@ansi lookups
A = rand(X(5))
lookup(A, X)
```

== Transformed

[`Transformed`](@ref) uses a function to transform indices between coordinate systems.

```@ansi lookups
using CoordinateTransformations
m = LinearMap([0.5 0.0; 0.0 0.5])
A = DimArray([1 2; 3 4], (X(Transformed(m)), Y(Transformed(m))))
A[X=At(2.0), Y=At(2.0)]  # Transformed to index [1,1]
```

:::

## Traits

Lookups have four key traits that control their behavior:

### Order

Indicates how values are sorted along the axis.

| Type | Description |
|------|-------------|
| `ForwardOrdered()` | Values increase with index |
| `ReverseOrdered()` | Values decrease with index |
| `Unordered()` | No guaranteed order |
| `AutoOrder()` | Detect automatically (default) |

```@ansi lookups
order(Sampled(10:-1:1))
```

### Sampling

Specifies whether lookup values represent discrete points or intervals.

| Type | Description |
|------|-------------|
| `Points()` | Values are discrete samples (default) |
| `Intervals(locus)` | Values represent interval ranges |

```@ansi lookups
sampling(Sampled(1:10; sampling=Intervals(Start())))
```

### Span

Describes the spacing between lookup values.

| Type | Description |
|------|-------------|
| `Regular(step)` | Uniform spacing (auto-detected for ranges) |
| `Irregular(lo, hi)` | Variable spacing; optionally store outer bounds |
| `Explicit(matrix)` | 2×n matrix of `[start; end]` for each interval |

```@ansi lookups
span(Sampled(1:2:10))
span(Sampled([1, 3, 7, 8]))
```

### Locus (Position)

For `Intervals`, specifies where the lookup value sits within each interval.

| Type | Description |
|------|-------------|
| `Start()` | Value at interval start |
| `Center()` | Value at interval center (default) |
| `End()` | Value at interval end |

```@ansi lookups
locus(Sampled(1:10; sampling=Intervals(Start())))
```

## Common Operations

### Bounds

Get the outer bounds of a lookup:

```@ansi lookups
A = rand(X(1.0:0.5:5.0))
bounds(A, X)
```

For `Intervals`, bounds extend beyond the lookup values:

```@ansi lookups
l = Sampled(1:5; sampling=Intervals(Start()), span=Regular(1))
bounds(l)  # (1, 6) - extends to end of last interval
```

### Interval Bounds

Get bounds for each interval:

```@ansi lookups
l = Sampled(1:3; sampling=Intervals(Center()), span=Regular(1))
intervalbounds(l)
intervalbounds(l, 2)  # Single index
```

### Predicates

Query lookup properties:

```@ansi lookups
l = Sampled(1:10; sampling=Intervals(Start()))
issampled(l), isintervals(l), isregular(l), isforward(l)
```

```@ansi lookups
l = Categorical([:a, :b, :c])
iscategorical(l), isordered(l)
```

### Modify with `set`

Change lookup properties:

```@ansi lookups
l = Sampled(1:10)
set(l, ReverseOrdered())
set(l, Intervals(Start()))
```

On arrays:

```@ansi lookups
A = rand(X(1:10))
set(A, X => Intervals(Start()))
```

## Implementing a Custom Lookup

To create a new lookup type, extend `Aligned` (for axis-aligned lookups) or `Lookup` directly.

### Minimal Example

```julia
using DimensionalData.Lookups

# 1. Define your type, extending Aligned (or AbstractSampled/AbstractCategorical)
struct MyLookup{T,A<:AbstractVector{T},O<:Order,M} <: Aligned{T,O}
    data::A
    order::O
    metadata::M
end

# Default constructor
function MyLookup(data=AutoValues(); order=AutoOrder(), metadata=NoMetadata())
    MyLookup(data, order, metadata)
end

# 2. Implement parent() to return the wrapped array
Base.parent(l::MyLookup) = l.data

# 3. Implement rebuild() for immutable updates
function Lookups.rebuild(l::MyLookup;
    data=parent(l), order=order(l), metadata=metadata(l), kw...
)
    MyLookup(data, order, metadata)
end

# 4. Implement trait accessors
Lookups.order(l::MyLookup) = l.order
Lookups.metadata(l::MyLookup) = l.metadata
```

### Required Methods

| Method | Purpose |
|--------|---------|
| `Base.parent(l)` | Return the wrapped array |
| `rebuild(l; kw...)` | Create modified copy with new field values |
| `order(l)` | Return the `Order` trait |

### Optional Methods

Override these to customize behavior:

| Method | Default | Purpose |
|--------|---------|---------|
| `span(l)` | `NoSpan()` | Return `Span` trait |
| `sampling(l)` | `NoSampling()` | Return `Sampling` trait |
| `locus(l)` | `Center()` | Return `Position` trait |
| `metadata(l)` | `NoMetadata()` | Return metadata |
| `bounds(l)` | Computed from order | Outer bounds of lookup |
| `selectindices(l, sel)` | Dispatches on selector | Index lookup for selectors |

### Extending AbstractSampled

For lookups with `span` and `sampling`, extend `AbstractSampled`:

```julia
struct MySampled{T,A,O,Sp,Sa,M} <: AbstractSampled{T,O,Sp,Sa}
    data::A
    order::O
    span::Sp
    sampling::Sa
    metadata::M
end

# AbstractSampled already provides span(), sampling(), locus() accessors
# Just implement rebuild():
function Lookups.rebuild(l::MySampled;
    data=parent(l), order=order(l), span=span(l),
    sampling=sampling(l), metadata=metadata(l), kw...
)
    MySampled(data, order, span, sampling, metadata)
end
```

### Format Integration

To support auto-detection when used in `DimArray` constructors, implement `format`:

```julia
using DimensionalData.Dimensions: format

# Format is called during DimArray construction
function Dimensions.format(l::MyLookup, D::Type, index, axis::AbstractRange)
    # Detect order if Auto
    o = order(l) isa AutoOrder ? Lookups.orderof(parent(l)) : order(l)
    # Rebuild with detected values
    rebuild(l; data=axis, order=o)
end
```

### Example: Logarithmic Lookup

```julia
"""
    LogLookup(data; order=AutoOrder(), base=10, metadata=NoMetadata())

A lookup for logarithmically-spaced data.
"""
struct LogLookup{T,A<:AbstractVector{T},O<:Order,B,M} <: Aligned{T,O}
    data::A
    order::O
    base::B
    metadata::M
end

function LogLookup(data=AutoValues(); order=AutoOrder(), base=10, metadata=NoMetadata())
    LogLookup(data, order, base, metadata)
end

Base.parent(l::LogLookup) = l.data
Lookups.order(l::LogLookup) = l.order
Lookups.metadata(l::LogLookup) = l.metadata
logbase(l::LogLookup) = l.base

function Lookups.rebuild(l::LogLookup;
    data=parent(l), order=order(l), base=logbase(l), metadata=metadata(l), kw...
)
    LogLookup(data, order, base, metadata)
end

# Custom selector behavior: search in log space
function Lookups.selectindices(l::LogLookup, sel::Near)
    logval = log(l.base, val(sel))
    logdata = log.(l.base, parent(l))
    # Find nearest in log space
    _, idx = findmin(x -> abs(x - logval), logdata)
    return idx
end
```

### Example: Lookup with Internal Dimensions

Some lookups hold multi-dimensional coordinate data. For example, a lookup storing a matrix of (x, y) coordinates for each point along an axis. These lookups have "internal dimensions" that describe the structure of the coordinate data.

The key additions are:
- Store dimensions in the lookup struct
- Implement `dims(l)` to return the internal dimensions
- Implement `hasinternaldimensions(l) = true` trait

```julia
using DimensionalData
using DimensionalData.Lookups
using DimensionalData.Dimensions

"""
    MatrixLookup(data, dims; metadata=NoMetadata())

A lookup where each index maps to coordinates in a matrix.
The matrix columns correspond to the internal dimensions.

## Example

```julia
# 5-point lookup with X,Y coordinates for each point
coords = [1.0 2.0;   # point 1: (x=1, y=2)
          1.5 2.5;   # point 2: (x=1.5, y=2.5)
          2.0 3.0;   # point 3
          2.5 3.5;   # point 4
          3.0 4.0]   # point 5
lookup = MatrixLookup(coords, (X(), Y()))
```
"""
struct MatrixLookup{T,A<:AbstractMatrix{T},D<:Tuple,M} <: Lookup{T,1}
    data::A      # Matrix where each row is coordinates for one index
    dims::D      # Tuple of Dimensions describing the columns
    metadata::M
end

function MatrixLookup(data::AbstractMatrix, dims::Tuple; metadata=NoMetadata())
    # Validate: number of columns must match number of dims
    size(data, 2) == length(dims) ||
        throw(ArgumentError("Matrix has $(size(data,2)) columns but $(length(dims)) dims provided"))
    MatrixLookup(data, dims, metadata)
end

# Required: return wrapped data (here we return first column as the "index" values)
Base.parent(l::MatrixLookup) = view(l.data, :, 1)

# Required: size is the number of points (rows)
Base.size(l::MatrixLookup) = (size(l.data, 1),)

# Required: rebuild for immutable updates
function Lookups.rebuild(l::MatrixLookup;
    data=l.data, dims=l.dims, metadata=metadata(l), kw...
)
    MatrixLookup(data, dims, metadata)
end

# Required: order trait (unordered since points aren't necessarily sorted)
Lookups.order(::MatrixLookup) = Unordered()
Lookups.metadata(l::MatrixLookup) = l.metadata

# Key: declare this lookup has internal dimensions
Lookups.hasinternaldimensions(::MatrixLookup) = true

# Key: return the internal dimensions
Dimensions.dims(l::MatrixLookup) = l.dims

# Also forward dims from a Dimension wrapping this lookup
Dimensions.dims(d::Dimension{<:MatrixLookup}) = dims(val(d))

# Access coordinate matrix
matrix(l::MatrixLookup) = l.data

# Get coordinates for a specific dimension
function coords(l::MatrixLookup, dim)
    idx = dimnum(l.dims, dim)
    view(l.data, :, idx)
end

# Get all coordinates for index i as a NamedTuple
function getcoords(l::MatrixLookup, i::Int)
    names = map(name, l.dims)
    values = ntuple(j -> l.data[i, j], length(l.dims))
    NamedTuple{names}(values)
end

# Custom indexing: return coordinate tuple for each index
Base.getindex(l::MatrixLookup, i::Int) = getcoords(l, i)

# Custom bounds: return bounds for each internal dimension
function Lookups.bounds(l::MatrixLookup)
    map(1:length(l.dims)) do j
        col = view(l.data, :, j)
        (minimum(col), maximum(col))
    end
end
```

Usage:

```julia
# Create coordinates for 4 points in X-Y space
coords = [0.0 0.0;
          1.0 0.0;
          0.0 1.0;
          1.0 1.0]

lookup = MatrixLookup(coords, (X(), Y()))

# Access internal dimensions
dims(lookup)  # (X, Y)
hasinternaldimensions(lookup)  # true

# Get coordinates for point 3
lookup[3]  # (X = 0.0, Y = 1.0)

# Get X coordinates for all points
coords(lookup, X)  # [0.0, 1.0, 0.0, 1.0]

# Use in a DimArray
A = DimArray(rand(4), Dim{:point}(lookup))

# Access the internal dims through the dimension
dims(A, :point)  # Returns the Dimension
dims(lookup(A, :point))  # (X(), Y()) - the internal dims
```
