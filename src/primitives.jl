# These functions do most of the work in the package.
# They are all type-stable recusive methods for performance and extensibility.

const UnionAllTupleOrVector = Union{Vector{UnionAll},Tuple{UnionAll,Vararg}}

@inline Base.permutedims(tosort::DimTuple, perm::Union{Vector{<:Integer},Tuple{<:Integer,Vararg}}) =
    map(p -> tosort[p], Tuple(perm))
@inline Base.permutedims(tosort::DimTuple, order::UnionAllTupleOrVector) =
    _sortdims(tosort, Tuple(map(d -> basetypeof(d), order)))
@inline Base.permutedims(tosort::UnionAllTupleOrVector, order::DimTuple) =
    _sortdims(Tuple(map(d -> basetypeof(d), tosort)), order)
@inline Base.permutedims(tosort::DimTuple, order::DimVector) =
    _sortdims(tosort, Tuple(order))
@inline Base.permutedims(tosort::DimVector, order::DimTuple) =
    _sortdims(Tuple(tosort), order)
@inline Base.permutedims(tosort::DimTuple, order::DimTuple) =
    _sortdims(tosort, order)

_sortdims(tosort::Tuple, order::Tuple) = _sortdims(tosort, order, ())
_sortdims(tosort::Tuple, order::Tuple, rejected) =
    # Match dims to the order, and also check if the indexmode has a
    # transformed dimension that matches
    if _dimsmatch(tosort[1], order[1])
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

_dimsmatch(dim::DimOrDimType, match::DimOrDimType) =
    basetypeof(dim) <: basetypeof(match) || basetypeof(dim) <: basetypeof(dims(indexmode(match)))

"""
Convert a tuple of Dimension to indices, ranges or Colon.
"""
@inline dims2indices(A, lookup, emptyval=Colon()) =
    dims2indices(dims(A), lookup, emptyval)
@inline dims2indices(dims::DimTuple, lookup, emptyval=Colon()) =
    dims2indices(dims, (lookup,), emptyval)
@inline dims2indices(dims::DimTuple, lookup::Tuple{Vararg{StandardIndices}},
                     emptyval=Colon()) = lookup
@inline dims2indices(dims::DimTuple, lookup::Tuple, emptyval=Colon()) =
    dims2indices(map(indexmode, dims), dims, permutedims(lookup, dims), emptyval)

# Deal with irregular indexmode that need multiple dimensions indexed together
@inline dims2indices(modes::Tuple{UnalignedIndex,Vararg}, dims::Tuple, lookup::Tuple, emptyval) = begin
    (irregdims, irreglookup), (regdims, reglookup) = splitindexmodes(modes, dims, lookup)
    (irreg2indices(map(indexmode, irregdims), irregdims, irreglookup, emptyval)...,
     dims2indices(map(indexmode, regdims), regdims, reglookup, emptyval)...)
end

@inline dims2indices(modes::Tuple, dims::Tuple, lookup::Tuple, emptyval) = begin
    (dims2indices(modes[1], dims[1], lookup[1], emptyval),
     dims2indices(tail(modes), tail(dims), tail(lookup), emptyval)...)
end
@inline dims2indices(modes::Tuple{}, dims::Tuple{}, lookup::Tuple{}, emptyval) = ()

@inline dims2indices(mode, dim::Dimension, lookup::Type{<:Dimension}, emptyval) = Colon()
@inline dims2indices(mode, dim::Dimension, lookup::Nothing, emptyval) = emptyval
@inline dims2indices(mode, dim::Dimension, lookup::Dimension, emptyval) = val(lookup)
@inline dims2indices(mode, dim::Dimension, lookup::Dimension{<:Selector}, emptyval) =
    sel2indices(val(lookup), mode, dim)

# Selectors select on indexmode dimensions
@inline irreg2indices(modes::Tuple, dims::Tuple, lookup::Tuple{Dimension{<:Selector},Vararg}, emptyval) =
    sel2indices(map(val, lookup), modes, dims)
# Other dims select on regular dimensions
@inline irreg2indices(modes::Tuple, dims::Tuple, lookup::Tuple, emptyval) = begin
    (dims2indices(modes[1], dims[1], lookup[1], emptyval),
     dims2indices(tail(modes), tail(dims), tail(lookup), emptyval)...)
end

@inline splitindexmodes(modes::Tuple{UnalignedIndex,Vararg}, dims, lookup) = begin
    (irregdims, irreglookup), reg = splitindexmodes(tail(modes), tail(dims), tail(lookup))
    irreg = (dims[1], irregdims...), (lookup[1], irreglookup...)
    irreg, reg
end
@inline splitindexmodes(modes::Tuple{IndexMode,Vararg}, dims, lookup) = begin
    irreg, (regdims, reglookup) = splitindexmodes(tail(modes), tail(dims), tail(lookup))
    reg = (dims[1], regdims...), (lookup[1], reglookup...)
    irreg, reg
end
@inline splitindexmodes(modes::Tuple{}, dims, lookup) = ((), ()), ((), ())


"""
Slice the dimensions to match the axis values of the new array

All methods returns a tuple conatining two tuples: the new dimensions,
and the reference dimensions. The ref dimensions are no longer used in
the new struct but are useful to give context to plots.

Called at the array level the returned tuple will also include the
previous reference dims attached to the array.
"""
function slicedims(A, I) end

@inline slicedims(A, I::Tuple) = slicedims(dims(A), refdims(A), I)
@inline slicedims(dims::Tuple, refdims::Tuple, I::Tuple{}) = dims, refdims
@inline slicedims(dims::Tuple, refdims::Tuple, I::Tuple) = begin
    newdims, newrefdims = slicedims(dims, I)
    newdims, (refdims..., newrefdims...)
end
@inline slicedims(dims::Tuple{}, I::Tuple) = (), ()
@inline slicedims(dims::DimTuple, I::Tuple) = begin
    d = slicedims(dims[1], I[1])
    ds = slicedims(tail(dims), tail(I))
    (d[1]..., ds[1]...), (d[2]..., ds[2]...)
end
@inline slicedims(dims::Tuple{}, I::Tuple{}) = (), ()

@inline slicedims(d::Dimension, i::Colon) = (d,), ()
@inline slicedims(d::Dimension, i::Number) =
    (), (rebuild(d, d[relate(d, i)], sliceindexmode(indexmode(d), val(d), i)),)
# TODO deal with unordered arrays trashing the index order
@inline slicedims(d::Dimension{<:AbstractArray}, i::AbstractArray) =
    (rebuild(d, d[relate(d, i)]),), ()
@inline slicedims(d::Dimension{<:Colon}, i::Colon) = (d,), ()
@inline slicedims(d::Dimension{<:Colon}, i::AbstractArray) = (d,), ()
@inline slicedims(d::Dimension{<:Colon}, i::Number) = (), (d,)

relate(d::Dimension, i) = maybeflip(relationorder(d), d, i)

maybeflip(::Forward, d, i) = i
maybeflip(::Reverse, d, i::Integer) = lastindex(d) - i + 1
maybeflip(::Reverse, d, i::AbstractArray) = reverse(lastindex(d) .- i .+ 1)

"""
    dimnum(A, lookup)

Get the number(s) of `Dimension`(s) as ordered in the
dimensions of an object.
"""
@inline dimnum(A, lookup) = dimnum(A, (lookup,))[1]
@inline dimnum(A, lookup::AbstractArray) = dimnum(A, (lookup...,))
@inline dimnum(A, lookup::Tuple) = dimnum(dims(A), lookup, (), 1)
# Match dim and lookup, also check if the indexmode has a transformed dimension that matches
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

Check if an object or tuple contains an `Dimension`,
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

Replaces the first dim matching `<: basetypeof(newdim)` with newdim, and returns
a new object or tuple with the dimension updated.
"""
setdim(A, newdim::Union{Dimension,DimTuple}) = rebuild(A, data(A), setdim(dims(A), newdim))
setdim(dims::DimTuple, newdims::DimTuple) = map(nd -> setdim(dims, nd), newdims)
# TODO handle the multiples of the same dim.
setdim(dims::DimTuple, newdim::Dimension) = map(d -> setdim(d, newdim), dims)
setdim(dim::Dimension, newdim::Dimension) =
    basetypeof(dim) <: basetypeof(newdim) ? newdim : dim

"""
    swapdims(x, newdims)

Swap the dimension for the passed in dimensions.
Dimension wrapper types rewrap the original dimension, keeping
the values and metadata. Dimension instances replace the original
dimension, and `nothing` leaves the original dimension as-is.
"""
swapdims(A::AbstractArray, newdims::Tuple) =
    rebuild(A, data(A), formatdims(A, swapdims(dims(A), newdims)))
swapdims(dims::DimTuple, newdims::Tuple) =
    map((d, nd) -> _swapdims(d, nd), dims, newdims)
_swapdims(dim::Dimension, newdim::DimType) =
    basetypeof(newdim)(val(dim), indexmode(dim), metadata(dim))
_swapdims(dim::Dimension, newdim::Dimension) = newdim
_swapdims(dim::Dimension, newdim::Nothing) = dim


"""
    formatdims(A, dims)

Format the passed-in dimension(s).

Mostily this means converting indexes of tuples and UnitRanges to
`LinRange`, which is easier to handle internally. Errors are also thrown if
dims don't match the array dims or size.

If a [`IndexMode`](@ref) hasn't been specified, an indexmode is chosen
based on the type and element type of the index:
"""
formatdims(A::AbstractArray{T,N} where T, dims::NTuple{N,Any}) where N =
    formatdims(axes(A), dims)
formatdims(axes::Tuple{Vararg{<:AbstractRange}},
           dims::Tuple{Vararg{<:Union{<:Dimension,<:UnionAll}}}) =
    map(formatdims, axes, dims)
formatdims(axis::AbstractRange, dim::Dimension{<:AbstractArray}) = begin
    checkaxis(dim, axis)
    rebuild(dim, val(dim), identify(indexmode(dim), basetypeof(dim), val(dim)))
end
formatdims(axis::AbstractRange, dim::Dimension{<:NTuple{2}}) = begin
    start, stop = val(dim)
    range = LinRange(start, stop, length(axis))
    rebuild(dim, range, identify(indexmode(dim), basetypeof(dim), range))
end
formatdims(axis::AbstractRange, dim::Dimension{Colon}) =
    rebuild(dim, axis, NoIndex(), nothing)
formatdims(axis::AbstractRange, dimtype::Type{<:Dimension}) =
    dim = dimtype(axis, NoIndex(), nothing)
# Fallback: dim remains unchanged
formatdims(axis::AbstractRange, dim::Dimension) = dim

checkaxis(dim, axis) =
    first(axes(dim)) == axis ||
        throw(DimensionMismatch(
            "axes of $(basetypeof(dim)) of $(first(axes(dim))) do not match array axis of $axis"))

"""
Replace the specified dimensions with an index of length 1 to match
a new array size where the dimension has been reduced to a length
of 1, but the number of dimensions has not changed.

Used in mean, reduce, etc.

IndexMode traits are also updated to correspond to the change in cell step, sampling
type and order.
"""
@inline reducedims(A, dimstoreduce) = reducedims(A, (dimstoreduce,))
@inline reducedims(A, dimstoreduce::Tuple) = reducedims(dims(A), dimstoreduce)
@inline reducedims(dims::DimTuple, dimstoreduce::Tuple) =
    map(reducedims, dims, permutedims(dimstoreduce, dims))
# Map numbers to corresponding dims. Not always type-stable
@inline reducedims(dims::DimTuple, dimstoreduce::Tuple{Vararg{Int}}) =
    map(reducedims, dims, permutedims(map(i -> dims[i], dimstoreduce), dims))

# Reduce matching dims but ignore nothing vals - they are the dims not being reduced
@inline reducedims(dim::Dimension, ::Nothing) = dim
@inline reducedims(dim::Dimension, ::DimOrDimType) = reducedims(indexmode(dim), dim)

# Now reduce specialising on indexmode type

# NoIndex. Defaults to Start locus.
@inline reducedims(indexmode::NoIndex, dim::Dimension) =
    rebuild(dim, first(val(dim)), NoIndex())
# Categories are combined.
@inline reducedims(indexmode::UnalignedIndex, dim::Dimension) =
    rebuild(dim, [nothing], NoIndex)
@inline reducedims(indexmode::CategoricalIndex, dim::Dimension{Vector{String}}) =
    rebuild(dim, ["combined"], CategoricalIndex(Ordered()))
@inline reducedims(indexmode::CategoricalIndex, dim::Dimension) =
    rebuild(dim, [:combined], CategoricalIndex(Ordered()))

@inline reducedims(indexmode::AbstractSampledIndex, dim::Dimension) =
    reducedims(span(indexmode), sampling(indexmode), indexmode, dim)
@inline reducedims(::IrregularSpan, ::PointSampling, indexmode::AbstractSampledIndex, dim::Dimension) =
    rebuild(dim, reducedims(Center(), dim::Dimension), indexmode)
@inline reducedims(::IrregularSpan, ::IntervalSampling, indexmode::AbstractSampledIndex, dim::Dimension) = begin
    indexmode = rebuild(indexmode, Ordered(), span(indexmode))
    rebuild(dim, reducedims(locus(indexmode), dim), indexmode)
end
@inline reducedims(::RegularSpan, ::Any, indexmode::AbstractSampledIndex, dim::Dimension) = begin
    indexmode = rebuild(indexmode, Ordered(), RegularSpan(step(indexmode) * length(dim)))
    rebuild(dim, reducedims(locus(indexmode), dim), indexmode)
end

# Get the index value at the reduced locus.
# This is the start, center or end point of the whole index.
@inline reducedims(locus::Start, dim::Dimension) = [first(val(dim))]
@inline reducedims(locus::End, dim::Dimension) = [last(val(dim))]
@inline reducedims(locus::Center, dim::Dimension) = begin
    index = val(dim)
    len = length(index)
    if iseven(len)
        centerval(index, len)
    else
        [index[len ÷ 2 + 1]]
    end
end
@inline reducedims(locus::Locus, dim::Dimension) = reducedims(Center(), dim)

# Need to specialise for more types
centerval(index::AbstractArray{<:AbstractFloat}, len) =
    [(index[len ÷ 2] + index[len ÷ 2 + 1]) / 2]
centerval(index::AbstractArray, len) =
    [index[len ÷ 2 + 1]]


"""
    dims(A, lookup)

Get the dimension(s) matching the type(s) of the lookup dimension.

Lookup can be an Int or an Dimension, or a tuple containing
any combination of either.
"""
@inline dims(A::AbstractArray, lookup) = dims(dims(A), lookup)
@inline dims(d::DimTuple, lookup) = dims(d, (lookup,))[1]
@inline dims(d::DimTuple, lookup::Tuple) = _dims(d, lookup, (), d)

@inline _dims(d, lookup::Tuple, rejected, remaining) =
    if !(remaining[1] isa Nothing) && _dimsmatch(remaining[1], lookup[1])
        # Remove found dim so it isn't found again
        (remaining[1], _dims(d, tail(lookup), (), (rejected..., tail(remaining)...))...)
    else
        _dims(d, lookup, (rejected..., remaining[1]), tail(remaining))
    end
# Numbers are returned as-is
@inline _dims(d, lookup::Tuple{Number,Vararg}, rejected, remaining) =
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
@inline comparedims(a::DimTuple, ::Nothing) = a
@inline comparedims(::Nothing, b::DimTuple) = b
@inline comparedims(::Nothing, ::Nothing) = nothing

@inline comparedims(a::DimTuple, b::DimTuple) =
    (comparedims(a[1], b[1]), comparedims(tail(a), tail(b))...)
@inline comparedims(a::DimTuple, b::Tuple{}) = a
@inline comparedims(a::Tuple{}, b::DimTuple) = b
@inline comparedims(a::Tuple{}, b::Tuple{}) = ()
@inline comparedims(a::Dimension, b::PlaceholderDim) = a
@inline comparedims(a::PlaceholderDim, b::Dimension) = b
@inline comparedims(a::Dimension, b::Dimension) = begin
    basetypeof(a) == basetypeof(b) ||
        throw(DimensionMismatch("$(basetypeof(a)) and $(basetypeof(b)) dims on the same axis"))
    # TODO compare the indexmode, and maybe the index.
    return a
end

