using DimensionalData: to_indices, slicedims, dimnum, show_main, show_after, print_block_separator

"""
    CoordArray <: AbstractDimArray

A dimensional array type that supporting both dimension coordinates and non-dimension coordinates.

## Example

```julia
using DimensionalData

# Create dimension coordinates
time_dim = Ti(DateTime(2020, 1, 1):Day(1):DateTime(2020, 1, 10))
x_dim = X(1:5)
y_dim = Y(1:3)
z_dim = Z(1:4)

# Create non-dimension coordinates
lat = rand(5, 3)  # 2D coordinate
lon = rand(5, 3)  # 2D coordinate  
elevation = rand(4)  # 1D coordinate along X dimension

# Create the CoordArray
data = rand(10, 5, 3, 4)
da = CoordArray(
    data, 
    (time_dim, x_dim, y_dim, z_dim),
    coords=(; 
        latitude = ((X, Y), lat),
        longitude = ((X, Y), lon),
        elevation = ((Z,), elevation)
    ),
    name="temperature"
)

da[Ti(At(DateTime(2020, 1, 5))), X(2:4), Y(1)]
```
"""

abstract type AbstractCoordArray{T,N,D,C,A} <: AbstractDimArray{T,N,D,A} end

struct CoordArray{T,N,D<:Tuple,R<:Tuple,A<:AbstractArray{T,N},C,Na,Me} <: AbstractCoordArray{T,N,D,C,A}
    data::A
    dims::D
    refdims::R
    coords::C  # Non-dimension coordinates: Symbol => AbstractArray
    name::Na
    metadata::Me

    function CoordArray(
        data::A, dims::D, refdims::R, coords::C, name::Na, metadata::Me
    ) where {D<:Tuple,R<:Tuple,A<:AbstractArray{T,N},C,Na,Me} where {T,N}
        checkdims(data, dims)
        checkcoords(coords, dims)
        new{T,N,D,R,A,C,Na,Me}(data, dims, refdims, coords, name, metadata)
    end
end

# Constructors
function CoordArray(
    data::AbstractArray, dims; refdims=(), coords=(;), name=NoName(), metadata=NoMetadata()
)
    # Process coordinates: convert (dims, data) tuples to DimArrays
    dims = format(dims, data)
    processed_coords = _process_coords(coords, dims)
    CoordArray(data, dims, refdims, processed_coords, name, metadata)
end

function _process_coords(specs, parent_dims)
    map(specs) do spec
        _process_coord_spec(spec, parent_dims)
    end
end

_process_coord_spec(spec, parent_dims) = spec

function _process_coord_spec(spec::Tuple{Tuple,AbstractArray}, parent_dims)
    coord_dims, coord_data = spec
    DimArray(coord_data, dims(parent_dims, coord_dims))
end


# Interface methods
coords(_) = nothing
coords(x::CoordArray) = getfield(x, :coords)

# Override rebuildsliced to handle coordinate slicing
function rebuildsliced(f::Function, A::CoordArray, data::AbstractArray, I::Tuple)
    # Get the sliced dimensions and refdims using DimensionalData's logic
    I1 = to_indices(A, I)
    newdims, newrefdims = slicedims(f, A, I1)
    coords = slicecoords(f, A, I1)
    rebuild(A; data, dims=newdims, refdims=newrefdims, coords)
end

function slicecoords(f::Function, A::CoordArray, indices::Tuple)
    Adims = dims(A)
    return map(coords(A)) do coord
        # For DimArray coordinates, slice them according to the indexing pattern
        # For other coordinates, preserve as-is
        isa(coord, AbstractDimArray) ? _slice_coordinate(f, coord, indices, Adims) : coord
    end
end

function _slice_coordinate(f::Function, coord::AbstractDimArray, indices, parent_dims)
    # Map the indices to the coordinate's dimensions
    coord_indices = map(dims(coord)) do dim
        indices[dimnum(parent_dims, dim)]
    end
    return f(coord, coord_indices...)
end

function checkcoords(coords, dims)
end

include("show.jl")