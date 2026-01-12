# src/Lookups/faced_grid_lookup.jl

"""
    FacedGridLookup <: Lookup

A lookup for multi-face grids (e.g., cubed sphere) where array indices are
`i, j, face` and coordinates X, Y are stored as 3D matrices.

Follows the `ArrayLookup` pattern: `data` holds 1D axis indices (what `parent()`
returns), while `coords` holds the multi-dimensional coordinate matrix.

## Fields
- `data`: 1D axis indices (e.g., `1:ni`) - returned by `parent(l)`
- `coords`: Coordinate matrix `[ni, nj, nfaces]` for X or Y values
- `coord_dim`: The coordinate dimension (e.g., `X()` or `Y()`)
- `position`: Which axis of `coords` this lookup indexes (1 for I, 2 for J)
- `order`: Order trait (typically `Unordered()`)
- `metadata`: Metadata

## Example

```julia
using DimensionalData

ni, nj, nfaces = 10, 10, 6
X_coords = rand(ni, nj, nfaces) .* 360 .- 180  # [ni, nj, nfaces] longitudes
Y_coords = rand(ni, nj, nfaces) .* 180 .- 90   # [ni, nj, nfaces] latitudes

# data is 1D axis, coords is 3D coordinate matrix
I_dim = Dim{:I}(FacedGridLookup(1:ni, X_coords, X(), 1))
J_dim = Dim{:J}(FacedGridLookup(1:nj, Y_coords, Y(), 2))
face_dim = Dim{:face}(1:nfaces)

A = DimArray(rand(ni, nj, nfaces), (I_dim, J_dim, face_dim))
```
"""
struct FacedGridLookup{T,D<:AbstractVector,C<:AbstractArray{T},CD,O<:Order,M} <: Lookup{T,1}
    data::D
    coords::C
    coord_dim::CD
    position::Int
    order::O
    metadata::M
end

function FacedGridLookup(
    data::AbstractVector,
    coords::AbstractArray{T},
    coord_dim,
    position::Int;
    order::Order=Unordered(),
    metadata=NoMetadata()
) where {T}
    # Validate: data length must match coords size along position
    length(data) == size(coords, position) ||
        throw(ArgumentError("data length $(length(data)) != coords size $(size(coords, position)) along position $position"))
    FacedGridLookup{T,typeof(data),typeof(coords),typeof(coord_dim),typeof(order),typeof(metadata)}(
        data, coords, coord_dim, position, order, metadata
    )
end

# Convenience constructor: auto-generate data as 1:n
function FacedGridLookup(
    coords::AbstractArray{T},
    coord_dim,
    position::Int;
    order::Order=Unordered(),
    metadata=NoMetadata()
) where {T}
    data = Base.OneTo(size(coords, position))
    FacedGridLookup(data, coords, coord_dim, position; order, metadata)
end

# parent() returns 1D data - satisfies Lookup{T,1} contract
Base.parent(l::FacedGridLookup) = l.data

# Size/length from 1D data - required for AbstractArray{T,1}
Base.size(l::FacedGridLookup) = size(l.data)
Base.length(l::FacedGridLookup) = length(l.data)
Base.axes(l::FacedGridLookup) = axes(l.data)

Base.firstindex(l::FacedGridLookup) = firstindex(l.data)
Base.lastindex(l::FacedGridLookup) = lastindex(l.data)

# Indexing returns values from data (the axis indices)
Base.getindex(l::FacedGridLookup, i::Int) = l.data[i]

# Lookup interface
order(l::FacedGridLookup) = l.order
metadata(l::FacedGridLookup) = l.metadata
span(::FacedGridLookup) = Irregular()
sampling(::FacedGridLookup) = Points()

# Accessors for our extra fields
coords(l::FacedGridLookup) = l.coords
coord_dim(l::FacedGridLookup) = l.coord_dim
grid_position(l::FacedGridLookup) = l.position

# rebuild accepts data= (standard) plus coords= (our extension)
function rebuild(l::FacedGridLookup;
    data=parent(l),
    coords=l.coords,
    coord_dim=l.coord_dim,
    position=l.position,
    order=order(l),
    metadata=metadata(l),
    kw...  # Accept and ignore extra kwargs for compatibility
)
    FacedGridLookup(data, coords, coord_dim, position; order, metadata)
end

# Internal dimensions - has coordinate dimensions
hasinternaldimensions(::FacedGridLookup) = true

# Slicing with AbstractArray: slice both data and coords along this position
@propagate_inbounds function Base.getindex(l::FacedGridLookup, i::AbstractVector)
    new_data = l.data[i]
    new_coords = selectdim(l.coords, l.position, i)
    rebuild(l; data=new_data, coords=new_coords)
end

# View version
@propagate_inbounds function Base.view(l::FacedGridLookup, i::AbstractVector)
    new_data = view(l.data, i)
    new_coords = selectdim(l.coords, l.position, i)
    rebuild(l; data=new_data, coords=new_coords)
end

# Colon - return as-is
Base.getindex(l::FacedGridLookup, ::Colon) = l
Base.view(l::FacedGridLookup, ::Colon) = l

"""
    slice_coords(l::FacedGridLookup, dim_position::Int, idx)

Slice the coordinate matrix along a dimension OTHER than this lookup's position.
Used when another dimension (e.g., face) is selected.

Returns a new FacedGridLookup with sliced coords (data unchanged since we're
not slicing along this lookup's axis).
"""
function slice_coords(l::FacedGridLookup, dim_position::Int, idx::Int)
    new_coords = selectdim(l.coords, dim_position, idx)
    rebuild(l; coords=new_coords)
end

function slice_coords(l::FacedGridLookup, dim_position::Int, idx::AbstractVector)
    new_coords = selectdim(l.coords, dim_position, idx)
    rebuild(l; coords=new_coords)
end

# Bounds returns coordinate extent (for hasinternaldimensions interface)
# Returns (min, max) pair for our coord_dim
function bounds(l::FacedGridLookup)
    c = l.coords
    (minimum(c), maximum(c))
end
