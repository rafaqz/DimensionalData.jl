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
