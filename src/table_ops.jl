#=
Restore a dimensional array from its tabular representation.

- `data`: An `AbstractVector` containing the flat data to be written to a `DimArray`.
- `indices`: An `AbstractVector` containing the dimensional indices corresponding to each element in `data`.
- `dims`: The dimensions of the destination `DimArray`.
- `missingval`: The value to write for missing elements in `data`.

# Returns

An `Array` containing the ordered valued in `data` with the size specified by `dims`.
=#
function restore_array(data::AbstractVector, indices::AbstractVector, dims::Tuple, missingval)
    # Allocate Destination Array
    dst = DimArray{eltype(data)}(undef, dims)
    for (idx, d) in zip(indices, data)
        dst[idx] = d
    end

    if length(indices) !== length(dst)
        # Handle Missing Rows
        _missingval = _cast_missing(data, missingval)
        missing_rows = trues(dims)
        for idx in indices # looping is faster than broadcasting
            missing_rows[idx] = false 
        end
        return ifelse.(missing_rows, _missingval, dst)
    end
    return dst
end

#=
    coords_to_indices(table, dims; [selector, atol])

Return the dimensional index of each row in `table` based on its associated coordinates.
Dimension columns are determined from the name of each dimension in `dims`.

# Arguments

- a table 
- `dims`: A `Tuple` of `Dimension` corresponding to the source/destination array.

# Keywords 

- `selector`: The selector type to use. This defaults to `Near()` for orderd, sampled dimensions
    and `At()` for all other dimensions. 
- `atol`: The absolute tolerance to use with `At()`. This defaults to `1e-6`.
=#
coords_to_indices(table, dims::Tuple; selector=nothing, atol=1e-6) =
    _coords_to_indices(table, dims, selector, atol)

#=
    guess_dims(table; kw...)
    guess_dims(table, dims; precision=6)

Guesses the dimensions of an array based on the provided tabular representation.

# Arguments

- a table 
The dimensions will be inferred from the corresponding coordinate collumns in the table.

- `dims`: One or more dimensions to be inferred. If no dimensions are specified, then `guess_dims` will default
to any available dimensions in the set `(:X, :Y, :Z, :Ti, :Band)`. Dimensions can be given as either a singular
value or as a `Pair` with both the dimensions and corresponding order. The order will be inferred from the data
when none is given. This should work for sorted coordinates, but will not be sufficient when the table's rows are
out of order.
  
# Keywords

- `precision`: Specifies the number of digits to use for guessing dimensions (default = `6`).

# Returns
A tuple containing the inferred dimensions from the table.
=#
guess_dims(table; kw...) = guess_dims(table, _dim_col_names(table); kw...)
guess_dims(table, dims::Tuple; precision=6, kw...) =
    map(dim -> _guess_dims(get_column(table, name(dim)), dim, precision), dims)

#Retrieve the coordinate data stored in the column specified by `dim`.
get_column(table, x) = Tables.getcolumn(table, name(x))


#Return the names of all columns that don't match the dimensions given by `dims`.
function data_col_names(table, dims::Tuple)
    dim_cols = name(dims)
    return filter(x -> !(x in dim_cols), Tables.columnnames(table))
end

_guess_dims(coords::AbstractVector, dim::Type{<:Dimension}, args...) = 
    _guess_dims(coords, name(dim), args...)
_guess_dims(coords::AbstractVector, dim::Pair, args...) = 
    _guess_dims(coords, first(dim), last(dim), args...)
function _guess_dims(coords::AbstractVector, dim::Symbol, ::Type{T}, precision::Int) where {T <: Order}
    return _guess_dims(coords, dim, T(), precision)
end
function _guess_dims(coords::AbstractVector, dim::Symbol, precision::Int)
    dim_vals = _dim_vals(coords, dim, precision)
    return format(Dim{dim}(dim_vals))
end
function _guess_dims(coords::AbstractVector, dim::Type{<:Dimension}, precision::Int)
    dim_vals = _dim_vals(coords, dim, precision)
    return format(dim(dim_vals))
end
function _guess_dims(coords::AbstractVector, dim::Dimension, precision::Int) 
    newl = _guess_dims(coords, lookup(dim), precision)
    return format(rebuild(dim, newl))
end
function _guess_dims(coords::AbstractVector, l::Lookup, precision::Int)
    dim_vals = _dim_vals(coords, l, precision)
    return rebuild(l; data = dim_vals)
end
# lookup(dim) could just return a vector - then we keep those values
_guess_dims(coords::AbstractVector, l::AbstractVector, precision::Int) = l

# Extract coordinate columns from table
function _dim_cols(table, dims::Tuple)
    dim_cols = name(dims)
    return NamedTuple{dim_cols}(Tables.getcolumn(table, col) for col in dim_cols)
end

# Extract dimension column names from the given table
_dim_col_names(table) = filter(x -> x in Tables.columnnames(table), (:X,:Y,:Z,:Ti,:Band))
_dim_col_names(table, dims::Tuple) = map(col -> Tables.getcolumn(table, col), name(dims))

_coords_to_indices(table, dims::Tuple, sel, atol) = 
    _coords_to_indices(_dim_cols(table, dims), dims, sel, atol)
# Determine the ordinality of a set of coordinates
function _coords_to_indices(coords::Tuple, dims::Tuple, sel, atol)
    map(zip(coords...)) do coords
        map(coords, dims) do c, d
            _coords_to_indices(c, d, sel, atol)
        end
    end
end
_coords_to_indices(coords::NamedTuple, dims::Tuple, sel, atol) = _coords_to_indices(map(x -> coords[x], name(dims)), dims, sel, atol)
# implement some default selectors
_coords_to_indices(coord, dim::Dimension, sel::Nothing, atol) = 
    _coords_to_indices(coord, dim, _default_selector(dim), atol)

# get indices of the coordinates
_coords_to_indices(coord, dim::Dimension, sel::Selector, atol) = 
    return rebuild(dim, selectindices(dim, rebuild(sel, coord)))
# get indices of the coordinates
_coords_to_indices(coord, dim::Dimension, sel::At, atol) = 
    return rebuild(dim, selectindices(dim, rebuild(sel; val = coord, atol)))

function _default_selector(dim::Dimension{<:AbstractSampled})
    if sampling(dim) isa Intervals
        Contains()
    elseif isordered(dim) && !(eltype(dim) <: Integer)
        Near()
    else 
        At()
    end
end
_default_selector(dim::Dimension{<:AbstractCategorical}) = At()
_default_selector(dim::Dimension) = Near()

# Extract dimension value from the given vector of coordinates
function _dim_vals(coords::AbstractVector, dim, precision::Int)
    vals = _unique_vals(coords, precision)
    return _maybe_as_range(vals, precision)
end
function _dim_vals(coords::AbstractVector, l::Lookup, precision::Int)
    val(l) isa AutoValues || return val(l) # do we want to have some kind of check that the values match?
    vals = _unique_vals(coords, precision)
    _maybe_order!(vals, order(l))
    return _maybe_as_range(vals, precision)
end
_dim_vals(coords::AbstractVector, l::AbstractVector, precision::Int) = l # same comment as above?

_maybe_order!(A::AbstractVector, ::Order) = A
_maybe_order!(A::AbstractVector, ::ForwardOrdered) = sort!(A)
_maybe_order!(A::AbstractVector, ::ReverseOrdered) = sort!(A, rev=true)

# Extract all unique coordinates from the given vector
_unique_vals(coords::AbstractVector, ::Int) = unique(coords)
_unique_vals(coords::AbstractVector{<:Real}, precision::Int) = round.(coords, digits=precision) |> unique
_unique_vals(coords::AbstractVector{<:Integer}, ::Int) = unique(coords)

# Estimate the span between consecutive coordinates
_maybe_as_range(A::AbstractVector, precision) = A # for non-numeric types
function _maybe_as_range(A::AbstractVector{<:Real}, precision::Int)
    A_r = range(first(A), last(A), length(A))
    atol = 10.0^(-precision)
    return all(i -> isapprox(A_r[i], A[i]; atol), eachindex(A)) ? A_r : A
end
function _maybe_as_range(A::AbstractVector{<:Integer}, precision::Int)
    idx1, idxrest = Iterators.peel(eachindex(A))
    step = A[idx1+1] - A[idx1]
    for idx in idxrest
        A[idx] - A[idx-1] == step || return A
    end
    return first(A):step:last(A)
end
function _maybe_as_range(A::AbstractVector{<:Dates.AbstractTime}, precision::Int)
    steps = (@view A[2:end]) .- (@view A[1:end-1])
    span = argmin(abs, steps)
    isregular = all(isinteger, round.(steps ./ span, digits=precision))
    return isregular ? range(first(A), last(A), length(A)) : A
end

_cast_missing(::AbstractArray, missingval::Missing) = missing
function _cast_missing(::AbstractArray{T}, missingval) where {T}
    try
        return convert(T, missingval)
    catch e
        return missingval
    end
end
