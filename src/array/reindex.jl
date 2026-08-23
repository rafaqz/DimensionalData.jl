using Base: promote_op

"""
    reindex(A, old_coords, new_coords; method=:nearest, fill_value=missing, tolerance=nothing, dim=1)

Reindex array `A` from original coordinate values `old_coords` to new coordinate values `new_coords` along dimension `dim`.

This function conforms the array to new coordinate values. 
When new coordinates don't match existing ones, values are determined by the `method` parameter.
Available `method` options include: 
    `:nearest` (nearest neighbor), `:linear` (linear interpolation), `:ffill` (forward fill), and `:bfill` (backward fill)

# Arguments
- `fill_value=missing`: Value to use for coordinates outside the original range
- `tolerance=nothing`: Maximum distance for `:nearest` method (beyond this, use `fill_value`)

# Examples
```julia
# Simple 1D reindexing
A = [10, 20, 30, 40, 50]
old_coords = [1.0, 2.0, 3.0, 4.0, 5.0]
new_coords = [1.5, 2.5, 3.5]

# Nearest neighbor (works with unsorted coords)
reindex(A, old_coords, new_coords; method=:nearest)  # [10, 20, 30]

# Linear interpolation (requires sorted coords)
reindex(A, old_coords, new_coords; method=:linear)   # [15.0, 25.0, 35.0]

# 2D array reindexing along dimension 2
A2d = [1 2 3; 4 5 6]
reindex(A2d, [1.0, 2.0, 3.0], [1.5, 2.5]; dim=2)
```
"""
@inline function reindex(
        A, old_coords, new_coords; method = :nearest,
        fill_value::FV = missing,
        tolerance = nothing,
        dim::Int = 1
    ) where {FV}
    @assert length(old_coords) == size(A, dim)
    new_size = ntuple(i -> i == dim ? length(new_coords) : size(A, i), ndims(A))
    T = Base.promote_type(method == :linear ? float(eltype(A)) : eltype(A), FV)
    result = similar(A, T, new_size)

    return if method == :linear
        _reindex_linear!(result, A, old_coords, new_coords, fill_value, dim)
    elseif method == :nearest
        _reindex_nearest!(result, A, old_coords, new_coords, fill_value, tolerance, dim)
    elseif method == :ffill
        _reindex_ffill!(result, A, old_coords, new_coords, fill_value, dim)
    elseif method == :bfill
        _reindex_bfill!(result, A, old_coords, new_coords, fill_value, dim)
    else
        throw(ArgumentError("Unknown method: $method. Use :nearest, :linear, :ffill, or :bfill"))
    end
end

function _dist_typemax(x, y)
    T = promote_type(eltype(x), eltype(y))
    return typemax(promote_op(-, T, T))
end

# Reindex using linear interpolation.
@inline function _reindex_linear!(result, A, old_coords, new_coords, fill_value, dim)
    old_min, old_max = extrema(old_coords)
    _max = _dist_typemax(old_coords, new_coords)
    for (i, new_coord) in enumerate(new_coords)
        # Check if out of bounds
        if new_coord < old_min || new_coord > old_max
            selectdim(result, dim, i) .= fill_value
            continue
        end

        # Find bracketing indices
        idx_lower = findmin(c -> c <= new_coord ? abs(c - new_coord) : _max, old_coords)[2]
        idx_upper = findmin(c -> c >= new_coord ? abs(c - new_coord) : _max, old_coords)[2]

        selectdim(result, dim, i) .= if idx_lower == idx_upper
            selectdim(A, dim, idx_lower)
        else
            # Linear interpolation weight
            x0, x1 = old_coords[idx_lower], old_coords[idx_upper]
            weight = (new_coord - x0) / (x1 - x0)
            # Interpolate
            val_lower = selectdim(A, dim, idx_lower)
            val_upper = selectdim(A, dim, idx_upper)
            val_lower .* (1 .- weight) .+ val_upper .* weight
        end
    end

    return result
end

# Reindex using nearest neighbor method.
@inline function _reindex_nearest!(result, A, old_coords, new_coords, fill_value, tolerance, dim)
    for (i, new_coord) in enumerate(new_coords)
        dist, idx = findmin(old_coords) do x
            abs(x - new_coord)
        end
        flag = !isnothing(tolerance) && dist > tolerance
        selectdim(result, dim, i) .= flag ? fill_value : selectdim(A, dim, idx)
    end
    return result
end

# Reindex using forward fill.
@inline function _reindex_ffill!(result, A, old_coords, new_coords, fill_value, dim)
    old_min = minimum(old_coords)
    _max = _dist_typemax(old_coords, new_coords)
    for (i, new_coord) in enumerate(new_coords)
        selectdim(result, dim, i) .= if new_coord < old_min
            fill_value
        else
            src_idx = findmin(old_coords) do x
                x <= new_coord ? abs(x - new_coord) : _max
            end[2]
            selectdim(A, dim, src_idx)
        end
    end

    return result
end

# Reindex using backward fill.
@inline function _reindex_bfill!(result, A, old_coords, new_coords, fill_value, dim)
    old_max = maximum(old_coords)
    _max = _dist_typemax(old_coords, new_coords)
    for (i, new_coord) in enumerate(new_coords)
        # Backward fill: use first value >= new_coord
        selectdim(result, dim, i) .= if new_coord > old_max
            fill_value
        else
            src_idx = findmin(old_coords) do x
                x >= new_coord ? abs(x - new_coord) : _max
            end[2]
            selectdim(A, dim, src_idx)
        end
    end

    return result
end


"""
    reindex(A::AbstractDimArray, dims::Dimension...; kw...)

Reindex DimensionalData array `A` to new coordinate values along specified dimensions.

# Examples
```julia
using DimensionalData, Dates

times = DateTime(2020, 1, 1):Day(1):DateTime(2020, 1, 10)
da = DimArray(1:10, Ti(times))

# Reindex to new times
new_times = DateTime(2020, 1, 1, 12):Day(1):DateTime(2020, 1, 5, 12)
reindex(da, Ti(new_times); method=:linear)

# Multiple dimensions
da2d = DimArray(rand(5, 10), (X(1:5), Y(1:10)))
reindex(da2d, X([1.5, 2.5, 3.5]), Y([2, 4, 6, 8]))
```
"""
function reindex(A::AbstractDimArray, dims::Dimension...; kw...)
    result = A
    for new_dim in dims
        result = _reindex_dimarray(result, new_dim; kw...)
    end
    return result
end

# Reindex a DimensionalData array along a single dimension.
function _reindex_dimarray(A::AbstractDimArray, new_dim::Dimension; kw...)
    dim_type = basetypeof(new_dim)
    dim = dimnum(A, dim_type)
    old_coords = lookup(dims(A, dim))
    # Use the general reindex implementation
    new_data = reindex(parent(A), old_coords, new_dim.val; kw..., dim)
    new_dims = ntuple(ndims(A)) do i
        i == dim ? new_dim : dims(A, i)
    end
    return rebuild(A, new_data, DD.format(new_dims, new_data))
end
