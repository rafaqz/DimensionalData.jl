"""
    restore_array(data, indices, dims; missingval=missing)

Restore a dimensional array from a set of values and their corresponding indices.

# Arguments
- `data`: An `AbstractVector` of values to write to the destination array. 
- `indices`: The flat index of each value in `data`.
- `dims`: A `Tuple` of `Dimension` for the corresponding destination array.
- `missingval`: The value to store for missing indices.

# Example
```julia
julia> d = DimArray(rand(256, 256), (X, Y));

julia> t = DimTable(d);

julia> indices = coords_to_index(t, dims(d));

julia> restored = restore_array(Tables.getcolumn(t, :value), indices, dims(d));

julia> all(restored .== d)
true
```
"""
function restore_array(data::AbstractVector, indices::AbstractVector{<:Integer}, dims::Tuple; missingval=missing)
    # Allocate Destination Array
    dst_size = prod(map(length, dims))
    dst = Vector{eltype(data)}(undef, dst_size)
    dst[indices] .= data

    # Handle Missing Rows
    _missingval = _cast_missing(data, missingval)
    missing_rows = ones(Bool, dst_size)
    missing_rows[indices] .= false
    data = ifelse.(missing_rows, _missingval, dst)

    # Reshape Array
    return reshape(data, size(dims))
end

"""
    coords_to_index(table, dims; selector=Contains)

Return the flat index of each row in `table` based on its associated coordinates.
Dimension columns are determined from the name of each dimension in `dims`.
It is assumed that the source/destination array has the same dimension order as `dims`.

# Arguments
- `table`: A table representation of a dimensional array. 
- `dims`: A `Tuple` of `Dimension` corresponding to the source/destination array.
- `selector`: The selector type to use for non-numerical/irregular coordinates.

# Example
```julia
julia> d = DimArray(rand(256, 256), (X, Y));

julia> t = DimTable(d);

julia> coords_to_index(t, dims(d))
65536-element Vector{Int64}:
     1
     2
     ⋮
 65535
 65536
```
"""
function coords_to_index(table, dims::Tuple; selector=DimensionalData.Contains())
    return _sort_coords(table, dims, selector)
end

# Find the order of the table's rows according to the coordinate values 
_sort_coords(table, dims::Tuple, ::Type{T}) where {T <: DimensionalData.Selector} = _sort_coords(_dim_cols(table, dims), dims, T)
function _sort_coords(coords::NamedTuple, dims::Tuple, ::Type{T}) where {T <: DimensionalData.Selector}
    ords = _coords_to_ords(coords, dims, T)
    indices = _ords_to_indices(ords, dims)
    return indices
end

# Extract coordinate columns from table
function _dim_cols(table, dims::Tuple)
    dim_cols = name(dims)
    return NamedTuple{dim_cols}(Tables.getcolumn(table, col) for col in dim_cols)
end

# Extract data columns from table
function _data_cols(table, dims::Tuple)
    data_cols = _data_col_names(table, dims)
    return NamedTuple{Tuple(data_cols)}(Tables.getcolumn(table, col) for col in data_cols)
end

# Get names of data columns from table
function _data_col_names(table, dims::Tuple)
    dim_cols = name(dims)
    return filter(x -> !(x in dim_cols), Tables.columnnames(table))
end

# Determine the ordinality of a set of regularly spaced numerical coordinates with a starting locus
function _coords_to_ords(
    coords::AbstractVector, 
    dim::Dimension, 
    ::Type{<:DimensionalData.Selector},
    ::Type{<:Real},
    ::DimensionalData.Start, 
    ::DimensionalData.Regular)
    step = (last(dim) - first(dim)) / (length(dim) - 1)
    return floor.(Int, ((coords .- first(dim)) ./ step) .+ 1)
end

# Determine the ordinality of a set of regularly spaced numerical coordinates with a central locus
function _coords_to_ords(
    coords::AbstractVector, 
    dim::Dimension, 
    ::Type{<:DimensionalData.Selector},
    ::Type{<:Real},
    ::DimensionalData.Center, 
    ::DimensionalData.Regular)
    step = (last(dim) - first(dim)) / (length(dim) - 1)
    return round.(Int, ((coords .- first(dim)) ./ step) .+ 1)
end

# Determine the ordinality of a set of regularly spaced numerical coordinates with an end locus
function _coords_to_ords(
    coords::AbstractVector, 
    dim::Dimension, 
    ::Type{<:DimensionalData.Selector},
    ::Type{<:Real},
    ::DimensionalData.End, 
    ::DimensionalData.Regular)
    step = (last(dim) - first(dim)) / (length(dim) - 1)
    return ceil.(Int, ((coords .- first(dim)) ./ step) .+ 1)
end

# Determine the ordinality of a set of categorical or irregular coordinates
function _coords_to_ords(coords::AbstractVector, dim::Dimension, ::Type{T}, ::Any, ::Any, ::Any) where {T<:DimensionalData.Selector}
    return map(c -> DimensionalData.selectindices(dim, T(c)), coords)
end

# Determine the ordinality of a set of coordinates
_coords_to_ords(coords::AbstractVector, dim::Dimension, ::Type{T}) where {T <: DimensionalData.Selector} = _coords_to_ords(coords, dim, T, eltype(dim), locus(dim), span(dim))
_coords_to_ords(coords::Tuple, dims::Tuple, ::Type{T}) where {T <: DimensionalData.Selector} = Tuple(_coords_to_ords(c, d, T) for (c, d) in zip(coords, dims))
_coords_to_ords(coords::NamedTuple, dims::Tuple, ::Type{T}) where {T <: DimensionalData.Selector} = _coords_to_ords(map(x -> coords[x], name(dims)), dims, T)

# Determine the index from a tuple of coordinate orders
function _ords_to_indices(ords, dims)
    stride = 1
    indices = ones(Int, length(ords[1]))
    for (ord, dim) in zip(ords, dims)
        indices .+= (ord .- 1) .* stride
        stride *= length(dim)
    end
    return indices
end

_cast_missing(::AbstractArray, missingval::Missing) = missing
function _cast_missing(::AbstractArray{T}, missingval) where {T}
    try
        return convert(T, missingval)
    catch e
        return missingval
    end
end