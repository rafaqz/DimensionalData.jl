"""
    restore_array(table; kw...)
    restore_array(table, dims::Tuple; name=NoName(), missingval=missing, selector=Near(), precision=6)

Restore a dimensional array from its tabular representation.

# Arguments
- `table`: The input data table, which could be a `DataFrame`, `DimTable`, or any other tabular data structure. 
Rows can be missing or out of order.
- `dims`: The dimensions of the corresponding `DimArray`. The dimensions may be explicitly defined, or they
may be inferred from the data. In the second case, `restore_array` accepts the same arguments as `guess_dims`.
  
# Keyword Arguments
- `name`: The name of the column in `table` from which to restore the array. Defaults to the 
first non-dimensional column.
- `missingval`: The value to store for missing rows.
- `selector`: The `Selector` to use when matching coordinates in `table` to their corresponding
indices in `dims`.
- `precision`: Specifies the number of digits to use for guessing dimensions (default = `6`).

# Example
```julia
julia> d = DimArray(rand(256, 256), (X, Y));

julia> t = DimTable(d);

julia> restored = restore_array(t);

julia> all(restored .== d)
true
```
"""
restore_array(table; kw...) = restore_array(table, _dim_col_names(table); kw...)
function restore_array(table, dims::Tuple; name=NoName(), missingval=missing, selector=DimensionalData.Near(), precision=6)
    # Get array dimensions
    dims = guess_dims(table, dims, precision=precision)

    # Determine row indices based on coordinate values
    indices = coords_to_indices(table, dims; selector=selector)

    # Extract the data column correspondong to `name`
    col = name == NoName() ? _data_col_names(table, dims) |> first : Symbol(name)
    data = _get_column(table, col)

    # Restore array data
    return _restore_array(data, indices, dims, missingval)
end

function _restore_array(data::AbstractVector, indices::AbstractVector{<:Integer}, dims::Tuple, missingval)
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
    coords_to_indices(table, dims; selector=Near())

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

julia> coords_to_indices(t, dims(d))
65536-element Vector{Int64}:
     1
     2
     ⋮
 65535
 65536
```
"""
function coords_to_indices(table, dims::Tuple; selector=DimensionalData.Near())
    return _coords_to_indices(table, dims, selector)
end

# Find the order of the table's rows according to the coordinate values 
_coords_to_indices(table, dims::Tuple, sel::DimensionalData.Selector) = 
    _coords_to_indices(_dim_cols(table, dims), dims, sel)
function _coords_to_indices(coords::NamedTuple, dims::Tuple, sel::DimensionalData.Selector)
    ords = _coords_to_ords(coords, dims, sel)
    indices = _ords_to_indices(ords, dims)
    return indices
end

"""
    guess_dims(table; kw...)
    guess_dims(table, dims; precision=6)

Guesses the dimensions of an array based on the provided tabular representation.

# Arguments
- `table`: The input data table, which could be a `DataFrame`, `DimTable`, or any other Tables.jl compatible data structure. 
The dimensions will be inferred from the corresponding coordinate collumns in the table.
- `dims`: One or more dimensions to be inferred. If no dimensions are specified, then `guess_dims` will default
to any available dimensions in the set `(:X, :Y, :Z, :Ti, :Band)`. Dimensions can be given as either a singular
value or as a `Pair` with both the dimensions and corresponding order. The order will be inferred from the data
when none is given. This should work for sorted coordinates, but will not be sufficient when the table's rows are
out of order.
  
# Keyword Arguments
- `precision`: Specifies the number of digits to use for guessing dimensions (default = `6`).

# Returns
A tuple containing the inferred dimensions from the table.

# Example
```julia
julia> xdims = X(LinRange{Float64}(610000.0, 661180.0, 2560));

julia> ydims = Y(LinRange{Float64}(6.84142e6, 6.79024e6, 2560));

julia> bdims = Dim{:Band}([:B02, :B03, :B04]);

julia> d = DimArray(rand(UInt16, 2560, 2560, 3), (xdims, ydims, bdims));

julia> t = DataFrame(d);

julia> t_rand = Random.shuffle(t);

julia> dims(d)
↓ X    Sampled{Float64} LinRange{Float64}(610000.0, 661180.0, 2560) ForwardOrdered Regular Points,
→ Y    Sampled{Float64} LinRange{Float64}(6.84142e6, 6.79024e6, 2560) ReverseOrdered Regular Points,
↗ Band Categorical{Symbol} [:B02, :B03, :B04] ForwardOrdered

julia> DD.guess_dims(t)
↓ X    Sampled{Float64} LinRange{Float64}(610000.0, 661180.0, 2560) ForwardOrdered Regular Points,
→ Y    Sampled{Float64} LinRange{Float64}(6.84142e6, 6.79024e6, 2560) ReverseOrdered Regular Points,
↗ Band Categorical{Symbol} [:B02, :B03, :B04] ForwardOrdered

julia> DD.guess_dims(t, (X, Y, :Band))
↓ X    Sampled{Float64} LinRange{Float64}(610000.0, 661180.0, 2560) ForwardOrdered Regular Points,
→ Y    Sampled{Float64} LinRange{Float64}(6.84142e6, 6.79024e6, 2560) ReverseOrdered Regular Points,
↗ Band Categorical{Symbol} [:B02, :B03, :B04] ForwardOrdered

julia> DD.guess_dims(t_rand, (X => DD.ForwardOrdered(), Y => DD.ReverseOrdered(), :Band => DD.ForwardOrdered()))
↓ X    Sampled{Float64} LinRange{Float64}(610000.0, 661180.0, 2560) ForwardOrdered Regular Points,
→ Y    Sampled{Float64} LinRange{Float64}(6.84142e6, 6.79024e6, 2560) ReverseOrdered Regular Points,
↗ Band Categorical{Symbol} [:B02, :B03, :B04] ForwardOrdered
```
"""
guess_dims(table; kw...) = guess_dims(table, filter(x -> x in Tables.columnnames(table), (:X,:Y,:Z,:Ti,:Band)); kw...)
guess_dims(table, dims::Tuple; kw...) = map(dim -> guess_dims(table, dim; kw...), dims)
guess_dims(table, dim; precision=6) = _guess_dims(_get_column(table, dim), dim, precision)

_guess_dims(coords::AbstractVector, dim::DD.Dimension, args...) = dim
_guess_dims(coords::AbstractVector, dim::Type{<:DD.Dimension}, args...) = _guess_dims(coords, DD.name(dim), args...)
_guess_dims(coords::AbstractVector, dim::Pair, args...) = _guess_dims(coords, first(dim), last(dim), args...)
function _guess_dims(coords::AbstractVector, dim::Symbol, precision::Int)
    dim_vals = _dim_vals(coords, precision)
    order = _guess_dim_order(dim_vals)
    span = _guess_dim_span(dim_vals, order, precision)
    return _build_dim(dim_vals, dim, order, span)
end
function _guess_dims(coords::AbstractVector, dim::Symbol, order::DD.Order, precision::Int)
    dim_vals = _dim_vals(coords, order, precision)
    span = _guess_dim_span(dim_vals, order, precision)
    return _build_dim(dim_vals, dim, order, span)
end

# Extract coordinate columns from table
function _dim_cols(table, dims::Tuple)
    dim_cols = DD.name(dims)
    return NamedTuple{dim_cols}(Tables.getcolumn(table, col) for col in dim_cols)
end

# Extract dimension column names from the given table
_dim_col_names(table) = filter(x -> x in Tables.columnnames(table), (:X,:Y,:Z,:Ti,:Band))
_dim_col_names(table, dims::Tuple) = map(col -> Tables.getcolumn(table, col), DD.name(dims))

# Extract data columns from table
function _data_cols(table, dims::Tuple)
    data_cols = _data_col_names(table, dims)
    return NamedTuple{Tuple(data_cols)}(Tables.getcolumn(table, col) for col in data_cols)
end

# Get names of data columns from table
function _data_col_names(table, dims::Tuple)
    dim_cols = DD.name(dims)
    return filter(x -> !(x in dim_cols), Tables.columnnames(table))
end

# Determine the ordinality of a set of coordinates
_coords_to_ords(coords::AbstractVector, dim::Dimension, sel::DD.Selector) = _coords_to_ords(coords, dim, sel, DD.locus(dim), DD.span(dim))
_coords_to_ords(coords::Tuple, dims::Tuple, sel::DD.Selector) = Tuple(_coords_to_ords(c, d, sel) for (c, d) in zip(coords, dims))
_coords_to_ords(coords::NamedTuple, dims::Tuple, sel::DD.Selector) = _coords_to_ords(map(x -> coords[x], DD.name(dims)), dims, sel)

# Determine the ordinality of a set of regularly spaced numerical coordinates
function _coords_to_ords(
    coords::AbstractVector{<:Real}, 
    dim::Dimension, 
    ::DimensionalData.Near,
    position::DimensionalData.Position, 
    span::DimensionalData.Regular)
    step = DD.step(span)
    float_ords = ((coords .- first(dim)) ./ step) .+ 1
    int_ords = _round_ords(float_ords, position)
    return clamp!(int_ords, 1, length(dim))
end

# Determine the ordinality of a set of categorical or irregular coordinates
function _coords_to_ords(
    coords::AbstractVector, 
    dim::Dimension, 
    sel::DimensionalData.Selector, 
    ::DimensionalData.Position, 
    ::DimensionalData.Span)
    return map(c -> DimensionalData.selectindices(dim, rebuild(sel, c)), coords)
end

# Round coordinate ordinality to the appropriate integer given the specified locus
_round_ords(ords::AbstractVector{<:Real}, ::DimensionalData.Start) = floor.(Int, ords)
_round_ords(ords::AbstractVector{<:Real}, ::DimensionalData.Center) = round.(Int, ords)
_round_ords(ords::AbstractVector{<:Real}, ::DimensionalData.End) = ceil.(Int, ords)

# Extract dimension value from the given vector of coordinates
_dim_vals(coords::AbstractVector, precision::Int) = _unique_vals(coords, precision)
_dim_vals(coords::AbstractVector, ::DD.Order, precision::Int) = _unique_vals(coords, precision)
_dim_vals(coords::AbstractVector, ::DD.ForwardOrdered, precision::Int) = sort!(_unique_vals(coords, precision))
_dim_vals(coords::AbstractVector, ::DD.ReverseOrdered, precision::Int) = sort!(_unique_vals(coords, precision), rev=true)

# Extract all unique coordinates from the given vector
_unique_vals(coords::AbstractVector, ::Int) = unique(coords)
_unique_vals(coords::AbstractVector{<:Real}, precision::Int) = round.(coords, digits=precision) |> unique

# Determine if the given coordinates are forward ordered, reverse ordered, or unordered
function _guess_dim_order(coords::AbstractVector)
    try
        if issorted(coords)
            return DD.ForwardOrdered()
        elseif issorted(coords, rev=true)
            return DD.ReverseOrdered()
        else
            return DD.Unordered()
        end
    catch 
        return DD.Unordered()
    end
end

# Estimate the span between consecutive coordinates
_guess_dim_span(::AbstractVector, ::DD.Order, ::Int) = DD.Irregular()
function _guess_dim_span(coords::AbstractVector{<:Real}, ::DD.Ordered, precision::Int)
    steps = round.((@view coords[2:end]) .- (@view coords[1:end-1]), digits=precision)
    span = argmin(abs, steps)
    return all(isinteger, round.(steps ./ span, digits=precision)) ? DD.Regular(span) : DD.Irregular()
end
function _guess_dim_span(coords::AbstractVector{<:Dates.AbstractTime}, ::DD.Ordered, precision::Int)
    steps = (@view coords[2:end]) .- (@view coords[1:end-1])
    span = argmin(abs, steps)
    return all(isinteger, round.(steps ./ span, digits=precision)) ? DD.Regular(span) : DD.Irregular()
end

function _build_dim(vals::AbstractVector, dim::Symbol, order::DD.Order, ::DD.Span)
    return rebuild(name2dim(dim), DD.Categorical(vals, order=order))
end
function _build_dim(vals::AbstractVector{<:Union{Number,Dates.AbstractTime}}, dim::Symbol, order::DD.Order, span::DD.Irregular)
    return Dim{dim}(DD.Sampled(vals, order=order, span=span, sampling=DD.Points()))
end
function _build_dim(vals::AbstractVector{<:Union{Number,Dates.AbstractTime}}, dim::Symbol, order::DD.Order, span::DD.Regular)
    n = round(Int, abs((last(vals) - first(vals)) / span.step) + 1)
    dim_vals = LinRange(first(vals), last(vals), n)
    return Dim{dim}(DD.Sampled(dim_vals, order=order, span=span, sampling=DD.Points()))
end

_get_column(table, x::Type{<:DD.Dimension}) = Tables.getcolumn(table, DD.name(x))
_get_column(table, x::DD.Dimension) = Tables.getcolumn(table, DD.name(x))
_get_column(table, x::Symbol) = Tables.getcolumn(table, x)
_get_column(table, x::Pair) = _get_column(table, first(x))


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