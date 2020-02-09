# These functions do most of the work in the package.
# They are all type-stable recusive methods for performance and extensibility.

const UnionAllTupleOrVector = Union{Vector{UnionAll},Tuple{UnionAll,Vararg}}

_dimsmatch(a::DimOrDimType, b::DimOrDimType) =
    basetypeof(a) <: basetypeof(b) || basetypeof(dims(grid(a))) <: basetypeof(b)

"""
Sort dimensions into the order they take in the array.

Missing dimensions are replaced with `nothing`
"""
@inline Base.permutedims(tosort::AbDimTuple, perm::Union{Vector{<:Integer},Tuple{<:Integer,Vararg}}) =
    map(p -> tosort[p], Tuple(perm))

@inline Base.permutedims(tosort::AbDimTuple, order::UnionAllTupleOrVector) =
    permutedims(tosort, Tuple(map(d -> constructorof(d)(), order)))
@inline Base.permutedims(tosort::UnionAllTupleOrVector, order::AbDimTuple) =
    permutedims(Tuple(map(d -> constructorof(d)(), tosort)), order)
@inline Base.permutedims(tosort::AbDimTuple, order::AbDimVector) =
    permutedims(tosort, Tuple(order))
@inline Base.permutedims(tosort::AbDimVector, order::AbDimTuple) =
    permutedims(Tuple(tosort), order)
@inline Base.permutedims(tosort::AbDimTuple, order::AbDimTuple) =
    Base.permutedims(tosort, order)

Base.permutedims(tosort::AbDimTuple, order::AbDimTuple) =
    _sortdims(tosort, order, ())

_sortdims(tosort::Tuple, order::Tuple, rejected) =
    # Match dims to the order, and also check if the grid has a
    # transformed dimension that matches
    if _dimsmatch(order[1], tosort[1])
        (tosort[1], _sortdims((rejected..., tail(tosort)...), tail(order), ())...)
    else
        _sortdims(tail(tosort), order, (rejected..., tosort[1]))
    end
# Return nothing and start on a new dim
_sortdims(tosort::Tuple{}, order::Tuple, rejected) =
    (nothing, _sortdims(rejected, tail(order), ())...)
# Return an empty tuple if we run out of dims to sort
_sortdims(tosort::Tuple, order::Tuple{}, rejected) = ()
_sortdims(tosort::Tuple{}, order::Tuple{}, rejected) = ()


"""
Convert a tuple of AbstractDimension to indices, ranges or Colon.
"""
@inline dims2indices(A, lookup, emptyval=Colon()) =
    dims2indices(dims(A), lookup, emptyval)
@inline dims2indices(dims::AbDimTuple, lookup, emptyval=Colon()) =
    dims2indices(dims, (lookup,), emptyval)
@inline dims2indices(dims::AbDimTuple, lookup::Tuple{Vararg{StandardIndices}},
                     emptyval=Colon()) = lookup
@inline dims2indices(dims::AbDimTuple, lookup::Tuple, emptyval=Colon()) =
    dims2indices(map(grid, dims), dims, permutedims(lookup, dims), emptyval)

# Deal with irregular grid types that need multiple dimensions indexed together
@inline dims2indices(grids::Tuple{DependentGrid,Vararg}, dims::Tuple, lookup::Tuple, emptyval) = begin
    (irregdims, irreglookup), (regdims, reglookup) = splitgridtypes(grids, dims, lookup)
    (irreg2indices(map(grid, irregdims), irregdims, irreglookup, emptyval)...,
     dims2indices(map(grid, regdims), regdims, reglookup, emptyval)...)
end

@inline dims2indices(grids::Tuple, dims::Tuple, lookup::Tuple, emptyval) = begin
    (dims2indices(grids[1], dims[1], lookup[1], emptyval),
     dims2indices(tail(grids), tail(dims), tail(lookup), emptyval)...)
end
@inline dims2indices(grids::Tuple{}, dims::Tuple{}, lookup::Tuple{}, emptyval) = ()

@inline dims2indices(grid, dim::AbDim, lookup::Type{<:AbDim}, emptyval) = Colon()
@inline dims2indices(grid, dim::AbDim, lookup::Nothing, emptyval) = emptyval
@inline dims2indices(grid, dim::AbDim, lookup::AbDim, emptyval) = val(lookup)
@inline dims2indices(grid, dim::AbDim, lookup::AbDim{<:Selector}, emptyval) =
    sel2indices(grid, dim, val(lookup))

# Selectors select on grid dimensions
@inline irreg2indices(grids::Tuple, dims::Tuple, lookup::Tuple{AbDim{<:Selector},Vararg}, emptyval) =
    sel2indices(grids, dims, map(val, lookup))
# Other dims select on regular dimensions
@inline irreg2indices(grids::Tuple, dims::Tuple, lookup::Tuple, emptyval) = begin
    (dims2indices(grids[1], dims[1], lookup[1], emptyval),
     dims2indices(tail(grids), tail(dims), tail(lookup), emptyval)...)
end

@inline splitgridtypes(grids::Tuple{DependentGrid,Vararg}, dims, lookup) = begin
    (irregdims, irreglookup), reg = splitgridtypes(tail(grids), tail(dims), tail(lookup))
    irreg = (dims[1], irregdims...), (lookup[1], irreglookup...)
    irreg, reg
end
@inline splitgridtypes(grids::Tuple{IndependentGrid,Vararg}, dims, lookup) = begin
    irreg, (regdims, reglookup) = splitgridtypes(tail(grids), tail(dims), tail(lookup))
    reg = (dims[1], regdims...), (lookup[1], reglookup...)
    irreg, reg
end
@inline splitgridtypes(grids::Tuple{}, dims, lookup) = ((), ()), ((), ())


"""
Slice the dimensions to match the axis values of the new array

All methods returns a tuple conatining two tuples: the new dimensions,
and the reference dimensions. The ref dimensions are no longer used in
the new struct but are useful to give context to plots.

Called at the array level the returned tuple will also include the
previous reference dims attached to the array.
"""
# Results are split as (dims, refdims)
@inline slicedims(A, I::Tuple) = slicedims(dims(A), refdims(A), I)
@inline slicedims(dims::Tuple, refdims::Tuple, I::Tuple{}) = dims, refdims
@inline slicedims(dims::Tuple, refdims::Tuple, I::Tuple) = begin
    newdims, newrefdims = slicedims(dims, I)
    newdims, (refdims..., newrefdims...)
end
@inline slicedims(dims::Tuple{}, I::Tuple) = (), ()
@inline slicedims(dims::AbDimTuple, I::Tuple) = begin
    d = slicedims(dims[1], I[1])
    ds = slicedims(tail(dims), tail(I))
    (d[1]..., ds[1]...), (d[2]..., ds[2]...)
end
@inline slicedims(dims::Tuple{}, I::Tuple{}) = (), ()

@inline slicedims(d::AbDim, i::Colon) = (d,), ()
@inline slicedims(d::AbDim, i::Number) =
    (), (rebuild(d, d[_relate(d, i)], slicegrid(grid(d), val(d), i)),)
# TODO deal with unordered arrays trashing the index order
@inline slicedims(d::AbDim{<:AbstractArray}, i::AbstractArray) =
    (rebuild(d, d[_relate(d, i)]),), ()
@inline slicedims(d::AbDim{<:Colon}, i::Colon) = (d,), ()
@inline slicedims(d::AbDim{<:Colon}, i::AbstractArray) = (d,), ()
@inline slicedims(d::AbDim{<:Colon}, i::Number) = (), (d,)

_relate(d::AbDim, i) = _maybeflip(relationorder(d), d, i)

_maybeflip(::Forward, d::AbDim, i) = i
_maybeflip(::Reverse, d::AbDim, i::Integer) = lastindex(d) - i + 1
_maybeflip(::Reverse, d::AbDim, i::AbstractArray) = reverse(lastindex(d) .- i .+ 1)

"""
    dimnum(A, lookup)

Get the number(s) of `AbstractDimension`(s) as ordered in the
dimensions of an object.
"""
@inline dimnum(A, lookup) = dimnum(A, (lookup,))[1]
@inline dimnum(A, lookup::AbstractArray) = dimnum(A, (lookup...,))
@inline dimnum(A, lookup::Tuple) = dimnum(dims(A), lookup, (), 1)
# Match dim and lookup, also check if the grid has a transformed dimension that matches
@inline dimnum(d::Tuple, lookup::Tuple, rejected, n) =
    if !(d[1] isa Nothing) && _dimsmatch(d[1], lookup[1])
        # Replace found dim with nothing so it isn't found again but n is still correct
        (n, dimnum((rejected..., nothing, tail(d)...), tail(lookup), (), 1)...)
    else
        dimnum(tail(d), lookup, (rejected..., d[1]), n + 1)
    end
# Numbers are returned as-is
@inline dimnum(d::Tuple, lookup::Tuple{Number,Vararg}, rejected, n) = lookup
@inline dimnum(d::Tuple{}, lookup::Tuple{Number,Vararg}, rejected, n) = lookup
# Throw an error if the lookup is not found
@inline dimnum(d::Tuple{}, lookup::Tuple, rejected, n) =
    throw(ArgumentError("No $(basetypeof(lookup[1])) in dims"))
# Return an empty tuple when we run out of lookups
@inline dimnum(d::Tuple, lookup::Tuple{}, rejected, n) = ()
@inline dimnum(d::Tuple{}, lookup::Tuple{}, rejected, n) = ()

"""
    hasdim(A, lookup)

Check if an object or tuple contains an `AbstractDimension`,
or a tuple of dimensions.
"""
@inline hasdim(A, lookup::Tuple) = map(l -> hasdim(dims(A), l), lookup)
@inline hasdim(A, lookup::DimOrDimType) = hasdim(dims(A), lookup)
@inline hasdim(d::Tuple, lookup::DimOrDimType) =
    if _dimsmatch(d[1], lookup)
        true
    else
        hasdim(tail(d), lookup)
    end
@inline hasdim(::Tuple{}, ::DimOrDimType) = false

"""
    setdim(x, newdim)

Replaces the first dim matching newdim, with newdim, and returns
a new object or tuple with the dimension updated.
"""
setdim(A, newdim::AbDim) = rebuild(A; dims=setdim(dims(A), newdim))
setdim(dims::AbDimTuple, newdim::AbDim) = map(d -> setdim(d, newdim), dims)
setdim(dim::AbDim, newdim::AbDim) =
    basetypeof(dim) <: basetypeof(newdim) ? newdim : dim


"""
    formatdims(A, dims)

Format the passed-in dimension(s).

Mostily this means converting indexes of tuples and UnitRanges to
`LinRange`, which is easier to handle internally. Errors are also thrown if
dims don't match the array dims or size.

If a [`Grid`](@ref) hasn't been specified, a grid type is chosen
based on the type and element type of the index:
- `AbstractRange` become `RegularGrid`
- `AbstractArray` become `AlignedGrid`
- `AbstractArray` of `Symbol` or `String` become `CategoricalGrid`
"""
formatdims(A::AbstractArray, dim::DimOrDimType) = formatdims(A, (dim,))
formatdims(A::AbstractArray, dims::Tuple{Vararg{Type}}) = 
    formatdims(A, map(d -> d(), dims))
formatdims(A::AbstractArray{T,N}, dims::AbDimTuple) where {T,N} = begin
    dimlen = length(dims)
    dimlen == N || throw(ArgumentError("dims ($dimlen) don't match array dimensions $(N)"))
    formatdims(axes(A), dims)
end
formatdims(axes::Tuple, dims::AbDimTuple) where N = map(formatdims, map(val, dims), axes, dims)
formatdims(index::AbstractArray, axis::AbstractRange, dim) = begin
    checklen(dim, axis)
    rebuild(dim, index, identify(grid(dim), index))
end
formatdims(index::AbstractRange, axis::AbstractRange, dim) = begin
    checklen(dim, axis)
    rebuild(dim, index, identify(grid(dim), index))
end
formatdims(index::NTuple{2}, axis::AbstractRange, dim) = begin
    range = LinRange(first(dim), last(dim), length(axis))
    rebuild(dim, range, identify(grid(dim), range))
end
formatdims(index::Nothing, axis::AbstractRange, dim) =
    rebuild(dim, nothing, NoGrid())
# Fallback: dim remains unchanged
formatdims(index, axis::AbstractRange, dim) = dim

checklen(dim, axis) =
    length(dim) == length(axis) ||
        throw(ArgumentError("length of $(basetypeof(dim)) ($(length(dim))) does not match size of array dimension ($axis)"))

orderof(index::AbstractArray) = begin
    sorted = issorted(index; rev=isrev(indexorder(index)))
    order = sorted ? Ordered(; index=indexorder(index)) : Unordered()
end

indexorder(index::AbstractArray) =
    first(index) <= last(index) ? Forward() : Reverse()

"""
Replace the specified dimensions with an index of length 1 to match
a new array size where the dimension has been reduced to a length
of 1, but the number of dimensions has not changed.

Used in mean, reduce, etc.

Grid traits are also updated to correspond to the change in cell step, sampling
type and order.
"""
@inline reducedims(A, dimstoreduce) = reducedims(A, (dimstoreduce,))
@inline reducedims(A, dimstoreduce::Tuple) = reducedims(dims(A), dimstoreduce)
@inline reducedims(dims::AbDimTuple, dimstoreduce::Tuple) =
    map(reducedims, dims, permutedims(dimstoreduce, dims))
@inline reducedims(dims::AbDimTuple, dimstoreduce::Tuple{Vararg{Int}}) =
    map(reducedims, dims, permutedims(map(i -> dims[i], dimstoreduce), dims))

# Reduce matching dims but ignore nothing vals - they are the dims not being reduced
@inline reducedims(dim::AbDim, ::Nothing) = dim
@inline reducedims(dim::AbDim, ::AbDim) = reducedims(grid(dim), dim)

# Now reduce specialising on grid type

# UnknownGrid remains Unknown. Defaults to Start locus.
@inline reducedims(grid::UnknownGrid, dim) = rebuild(dim, first(val(dim)), UnknownGrid())
# Categories are combined. 
@inline reducedims(grid::CategoricalGrid, dim::AbDim{Vector{String}}) =
    rebuild(dim, ["combined"], CategoricalGrid(Ordered()))
@inline reducedims(grid::CategoricalGrid, dim) =
    rebuild(dim, [:combined], CategoricalGrid(Ordered()))

# For Regular/Aligned/Bounded Grid
# The reduced grid now has IntervalSampling, not a Point or Unknown
# order is Ordered{Forward,Forward,Forward}, as it has length 1.
# Bounds remain the same. Locus determines dimension index sampled,
# and remains the same after reduce
@inline reducedims(grid::AlignedGrid, dim) = begin
    grid = AlignedGrid(Ordered(), locus(grid), IntervalSampling())
    rebuild(dim, reducedims(locus(grid), dim), grid)
end
@inline reducedims(grid::BoundedGrid, dim) = begin
    grid = BoundedGrid(Ordered(), locus(grid), IntervalSampling(), bounds(grid, dim))
    rebuild(dim, reducedims(locus(grid), dim), grid)
end
@inline reducedims(grid::RegularGrid, dim) = begin
    grid = RegularGrid(Ordered(), locus(grid), IntervalSampling(), step(grid) * length(dim))
    rebuild(dim, reducedims(locus(grid), dim), grid)
end
@inline reducedims(grid::DependentGrid, dim) =
    rebuild(dim, [nothing], UnknownGrid)

# Get the index value at the reduced locus.
# This is the start, center or end point of the whole index.
reducedims(locus::Start, dim) = [first(val(dim))]
reducedims(locus::End, dim) = [last(val(dim))]
reducedims(locus::Center, dim) = begin
    index = val(dim)
    len = length(index)
    if iseven(len)
        [(index[len ÷ 2] + index[len ÷ 2 + 1]) / 2]
    else
        [index[len ÷ 2 + 1]]
    end
end


"""
    dims(A, lookup)

Get the dimension(s) matching the type(s) of the lookup dimension.

Lookup can be an Int or an AbstractDimension, or a tuple containing
any combination of either.
"""
@inline dims(A::AbstractArray, lookup) = dims(dims(A), lookup)
@inline dims(d::AbDimTuple, lookup) = dims(d, (lookup,))[1]
@inline dims(d::AbDimTuple, lookup::Tuple) = _dims(d, lookup, (), d)

@inline _dims(d, lookup::Tuple, rejected, remaining) =
    if !(remaining[1] isa Nothing) && _dimsmatch(remaining[1], lookup[1])
        # Remove found dim so it isn't found again
        (remaining[1], _dims(d, tail(lookup), (), (rejected..., tail(remaining)...))...)
    else
        _dims(d, lookup, (rejected..., remaining[1]), tail(remaining))
    end
# Numbers are returned as-is
@inline _dims(d, lookup::Tuple{Number,Vararg}, rejected, remaining::Tuple{AbDim,Vararg}) =
    (d[lookup[1]], _dims(d, tail(lookup), (), (rejected..., remaining...))...)
# Throw an error if the lookup is not found
@inline _dims(d, lookup::Tuple, rejected, remaining::Tuple{}) =
    throw(ArgumentError("No $(basetypeof(lookup[1])) in dims"))
# Return an empty tuple when we run out of lookups
@inline _dims(d, lookup::Tuple{}, rejected, remaining::Tuple) = ()
@inline _dims(d, lookup::Tuple{}, rejected, remaining::Tuple{}) = ()

"""
    comparedims(a, b)

Check that dimensions or tuples of dimensions are the same.
Empty tuples are allowed
"""
@inline comparedims(a::AbDimTuple, ::Nothing) = a
@inline comparedims(::Nothing, b::AbDimTuple) = b
@inline comparedims(::Nothing, ::Nothing) = nothing

@inline comparedims(a::AbDimTuple, b::AbDimTuple) = 
    (comparedims(a[1], b[1]), comparedims(tail(a), tail(b))...)
@inline comparedims(a::AbDimTuple, b::Tuple{}) = a
@inline comparedims(a::Tuple{}, b::AbDimTuple) = b
@inline comparedims(a::Tuple{}, b::Tuple{}) = ()
@inline comparedims(a::AbDim, b::AbDim) = begin
    basetypeof(a) == basetypeof(b) || 
        throw(DimensionMismatch("$(basetypeof(a)) and $(basetypeof(b)) dims on the same axis"))
    # TODO compare the grid, and maybe the index.
    return a
end
