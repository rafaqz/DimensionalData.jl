function _write_vals(data, dims::Tuple, perm, missingval)
    # Allocate Destination Array
    dst_size = prod(map(length, dims))
    dst = Vector{eltype(data)}(undef, dst_size)
    dst[perm] .= data

    # Handle Missing Rows
    _missingval = _cast_missing(data, missingval)
    missing_rows = ones(Bool, dst_size)
    missing_rows[perm] .= false
    return ifelse.(missing_rows, _missingval, dst)
end

# Find the order of the table's rows according to the coordinate values 
_sort_coords(table, dims::Tuple) = _sort_coords(_dim_cols(table, dims), dims)
function _sort_coords(coords::NamedTuple, dims::Tuple)
    ords = _coords_to_ords(coords, dims)
    indices = _ords_to_indices(ords, dims)
    return indices
end

# Extract coordinate columns from table
function _dim_cols(table, dims::Tuple)
    dim_cols = map(name, dims)
    return NamedTuple{dim_cols}(Tables.getcolumn(table, col) for col in dim_cols)
end

# Extract data columns from table
function _data_cols(table, dims::Tuple)
    data_cols = _data_col_names(table, dims)
    return NamedTuple{Tuple(data_cols)}(Tables.getcolumn(table, col) for col in data_cols)
end

# Get names of data columns from table
function _data_col_names(table, dims::Tuple)
    dim_cols = map(name, dims)
    return filter(x -> !(x in dim_cols), Tables.columnnames(table))
end

# Determine the ordinality of a set of regularly spaced numerical coordinates with a starting locus
function _coords_to_ords(
    coords::AbstractVector, 
    dim::Dimension, 
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
    ::Type{<:Real},
    ::DimensionalData.End, 
    ::DimensionalData.Regular)
    step = (last(dim) - first(dim)) / (length(dim) - 1)
    return ceil.(Int, ((coords .- first(dim)) ./ step) .+ 1)
end

# Determine the ordinality of a set of categorical or irregular coordinates
function _coords_to_ords(coords::AbstractVector, dim::Dimension, ::Any, ::Any, ::Any)
    return map(c -> DimensionalData.selectindices(dim, At(c)), coords)
end

# Preprocessing methods for _coords_to_ords
_coords_to_ords(coords::AbstractVector, dim::Dimension) = _coords_to_ords(coords, dim, eltype(dim), locus(dim), span(dim))
_coords_to_ords(coords::Tuple, dims::Tuple) = Tuple(_coords_to_ords(c, d) for (c, d) in zip(coords, dims))
_coords_to_ords(coords::NamedTuple, dims::Tuple) = _coords_to_ords(Tuple(coords[d] for d in name.(dims)), dims)

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