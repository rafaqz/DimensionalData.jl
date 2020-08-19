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

@inline _sortdims(tosort::Tuple, order::Tuple) = _sortdims(tosort, order, ())
@inline _sortdims(tosort::Tuple, order::Tuple, rejected) =
    # Match dims to the order, and also check if the mode has a
    # transformed dimension that matches
    if _dimsmatch(tosort[1], order[1])
        (tosort[1], _sortdims((rejected..., tail(tosort)...), tail(order), ())...)
    else
        _sortdims(tail(tosort), order, (rejected..., tosort[1]))
    end
# Return nothing and start on a new dim
@inline _sortdims(tosort::Tuple{}, order::Tuple, rejected) =
    (nothing, _sortdims(rejected, tail(order), ())...)
# Return an empty tuple if we run out of dims to sort
@inline _sortdims(tosort::Tuple, order::Tuple{}, rejected) = ()
@inline _sortdims(tosort::Tuple{}, order::Tuple{}, rejected) = ()

@inline _dimsmatch(dim::DimOrDimType, match::DimOrDimType) =
    basetypeof(dim) <: basetypeof(match) || basetypeof(dim) <: basetypeof(dims(mode(match)))

"""
    dims2indices(dim::Dimension, lookup, [emptyval=Colon()])

Convert a `Dimension` or `Selector` lookup to indices, ranges or Colon.
"""
@inline dims2indices(dim::Dimension, lookup, emptyval=Colon()) =
    _dims2indices(mode(dim), dim, lookup, emptyval)
@inline dims2indices(dim::Dimension, lookup::StandardIndices, emptyval=Colon()) = lookup

"""
    dims2indices(A, lookup, [emptyval=Colon()])

Convert `Dimension` or `Selector` to regular indices for any object with a `dims` method,
usually an array.
"""
@inline dims2indices(A, lookup, emptyval=Colon()) =
    dims2indices(dims(A), lookup, emptyval)
"""
dims2indices(dims, lookup, [emptyval=Colon()])

Convert `Dimension` or `Selector` to regular indices for `dims` - a `Tuple` of `Dimension`.
`lookup` can be a `Tuple` or a single object.
"""
@inline dims2indices(dims::DimTuple, lookup, emptyval=Colon()) =
    dims2indices(dims, (lookup,), emptyval)
# Standard array indices are simply returned
@inline dims2indices(dims::DimTuple, lookup::Tuple{Vararg{StandardIndices}},
                     emptyval=Colon()) = lookup
# Otherwise attempt to convert dims to indices
@inline dims2indices(dims::DimTuple, lookup::Tuple, emptyval=Colon()) =
    _dims2indices(map(mode, dims), dims, permutedims(lookup, dims), emptyval)
# Recursively apply dims2indices over tuples of dims and lookups
@inline _dims2indices(modes::Tuple{<:Aligned,Vararg}, dims::Tuple, lookup::Tuple, emptyval) =
    (_dims2indices(modes[1], dims[1], lookup[1], emptyval),
     _dims2indices(tail(modes), tail(dims), tail(lookup), emptyval)...)
@inline _dims2indices(modes::Tuple{}, dims::Tuple{}, lookup::Tuple{}, emptyval) = ()

# Single dim methods

# A Dimension type always means Colon(), as if it was constructed with the default value.
@inline _dims2indices(mode, dim::Dimension, lookup::Type{<:Dimension}, emptyval) = Colon()
# Nothing means nothing was passed for this dimension, return the emptyval
@inline _dims2indices(mode, dim::Dimension, lookup::Nothing, emptyval) = emptyval
# Simply unwrap dimensions
@inline _dims2indices(mode, dim::Dimension, lookup::Dimension, emptyval) = val(lookup)
# Pass `Selector`s to sel2indices
@inline _dims2indices(mode, dim::Dimension, lookup::Dimension{<:Selector}, emptyval) =
    sel2indices(val(lookup), mode, dim)


# Deal with unaligned mode that need multiple dimensions indexed together
@inline _dims2indices(modes::Tuple{<:Unaligned,Vararg}, dims::Tuple, lookup::Tuple, emptyval) = begin
    # Split dims and lookups into aligned and unaligned
    (unaligneddims, unalignedlookup), (aligneddims, alignedlookup) = splitmodes(modes, dims, lookup)
    # Convert aligned and unaligned separately. This is recursive, so there may have been
    # other `Aligned` dims previously. There is at maximum one block of `Unaligned` dims in
    # any set, so we don't have to worry about finding more at the end.
    (unaligned2indices(map(mode, unaligneddims), unaligneddims, unalignedlookup, emptyval)...,
     _dims2indices(map(mode, aligneddims), aligneddims, alignedlookup, emptyval)...)
end

# For `Unaligned` mode, `Selector`s select on mode dimensions
@inline unaligned2indices(modes::Tuple, dims::Tuple,
                          lookup::Tuple{Dimension{<:Selector},Vararg}, emptyval) =
    sel2indices(map(val, lookup), modes, dims)
# For non-selector dims, use regular dimension indexing
@inline unaligned2indices(modes::Tuple, dims::Tuple, lookup::Tuple, emptyval) =
    (_dims2indices(modes[1], dims[1], lookup[1], emptyval),
     _dims2indices(tail(modes), tail(dims), tail(lookup), emptyval)...)

# Split out dims with Aligned and Unaligned modes
@inline splitmodes(modes::Tuple{Unaligned,Vararg}, dims, lookup) = begin
    (unaligneddims, unalignedlookup), aligned = splitmodes(tail(modes), tail(dims), tail(lookup))
    unaligned = (dims[1], unaligneddims...), (lookup[1], unalignedlookup...)
    unaligned, aligned
end
@inline splitmodes(modes::Tuple{IndexMode,Vararg}, dims, lookup) = begin
    unaligned, (aligneddims, alignedlookup) = splitmodes(tail(modes), tail(dims), tail(lookup))
    aligned = (dims[1], aligneddims...), (lookup[1], alignedlookup...)
    unaligned, aligned
end
@inline splitmodes(modes::Tuple{}, dims, lookup) = ((), ()), ((), ())


"""
    slicedims(A, I)

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
# TODO why is `relate` used here? we care about the index order not the relation order
@inline slicedims(d::Dimension, i::Number) =
    (), (rebuild(d, d[relate(d, i)], slicemode(mode(d), val(d), i)),)
# TODO deal with unordered arrays trashing the index order
@inline slicedims(d::Dimension{<:Union{AbstractArray,Val}}, i::AbstractArray) =
    (rebuild(d, d[relate(d, i)], slicemode(mode(d), val(d), i)),), ()
@inline slicedims(d::Dimension{<:Colon}, i::Colon) = (d,), ()
@inline slicedims(d::Dimension{<:Colon}, i::AbstractArray) = (d,), ()
@inline slicedims(d::Dimension{<:Colon}, i::Number) = (), (d,)

@inline relate(d::Dimension, i) = maybeflip(relationorder(d), d, i)

@inline maybeflip(::Forward, d, i) = i
@inline maybeflip(::Reverse, d, i::Integer) = lastindex(d) - i + 1
@inline maybeflip(::Reverse, d, i::AbstractArray) = reverse(lastindex(d) .- i .+ 1)

"""
    dimnum(x, lookup)

Get the number(s) of `Dimension`(s) as ordered in the dimensions of an object.

## Arguments
- `x`: any object with a `dims` method, a `Tuple` of `Dimension` or a single `Dimension`.
- `lookup`: Tuple, Array or single `Dimension` or dimension `Type`.

The return type will be a Tuple of `Int` or a single `Int`,
depending on wether `lookup` is a `Tuple` or single `Dimension`.

## Example
```jldoctest
julia> A = DimensionalArray(ones(10, 10, 10), (X, Y, Z));


julia> dimnum(A, Z)
3
```
"""
@inline dimnum(A, lookup) = dimnum(dims(A), lookup)
@inline dimnum(d::Tuple, lookup) = dimnum(d, (lookup,))[1]
@inline dimnum(d::Tuple, lookup::AbstractArray) = dimnum(d, (lookup...,))
@inline dimnum(d::Tuple, lookup::Tuple) = _dimnum(d, lookup, (), 1)

# Match dim and lookup, also check if the mode has a transformed dimension that matches
@inline _dimnum(d::Tuple, lookup::Tuple, rejected, n) =
    if !(d[1] isa Nothing) && _dimsmatch(d[1], lookup[1])
        # Replace found dim with nothing so it isn't found again but n is still correct
        (n, _dimnum((rejected..., nothing, tail(d)...), tail(lookup), (), 1)...)
    else
        _dimnum(tail(d), lookup, (rejected..., d[1]), n + 1)
    end
# Numbers are returned as-is
@inline _dimnum(dims::Tuple, lookup::Tuple{Number,Vararg}, rejected, n) = lookup
@inline _dimnum(dims::Tuple{}, lookup::Tuple{Number,Vararg}, rejected, n) = lookup
# Throw an error if the lookup is not found
@inline _dimnum(dims::Tuple{}, lookup::Tuple, rejected, n) =
    throw(ArgumentError("No $(basetypeof(lookup[1])) in dims"))
# Return an empty tuple when we run out of lookups
@inline _dimnum(dims::Tuple, lookup::Tuple{}, rejected, n) = ()
@inline _dimnum(dims::Tuple{}, lookup::Tuple{}, rejected, n) = ()

"""
    hasdim(x, lookup)

## Arguments
- `x`: any object with a `dims` method, a `Tuple` of `Dimension` or a single `Dimension`.
- `lookup`: Tuple or single `Dimension` or dimension `Type`.

Check if an object or tuple contains an `Dimension`, or a tuple of dimensions.

## Example
```jldoctest
julia> A = DimensionalArray(ones(10, 10, 10), (X, Y, Z));

julia> hasdim(A, X)
true

julia> hasdim(A, Ti)
false
```
"""
@inline hasdim(A::AbstractArray, lookup) = hasdim(dims(A), lookup)
@inline hasdim(d::Tuple, lookup::Tuple) = map(l -> hasdim(d, l), lookup)
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

## Arguments
- `x`: any object with a `dims` method, a `Tuple` of `Dimension` or a single `Dimension`.
- `newdim`: Tuple or single `Dimension` or dimension `Type`.

# Example
```jldoctest
A = DimensionalArray(ones(10, 10), (X, Y(10:10:100)))
B = setdims(A, Y('a':'j'))
val(dims(B, Y))

# output

'a':1:'j'
```
"""
@inline setdims(A, newdims::Union{Dimension,DimTuple}) = rebuild(A, data(A), setdims(dims(A), newdims))
@inline setdims(dims::DimTuple, newdims::DimTuple) = map(nd -> setdims(dims, nd), newdims)
# TODO handle the multiples of the same dim.
@inline setdims(dims::DimTuple, newdim::Dimension) = map(d -> setdims(d, newdim), dims)
@inline setdims(dim::Dimension, newdim::Dimension) =
    basetypeof(dim) <: basetypeof(newdim) ? newdim : dim

"""
    swapdims(x, newdims)

Swap dimensions for the passed in dimensions, in the
order passed.

Passing in the `Dimension` types rewraps the dimension index, 
keeping the index values and metadata, while constructed `Dimension` 
objectes replace the original dimension. `nothing` leaves the original 
dimension as-is.

## Arguments
- `x`: any object with a `dims` method, a `Tuple` of `Dimension` or a single `Dimension`.
- `newdim`: Tuple or single `Dimension` or dimension `Type`.

# Example
```jldoctest
julia> A = DimensionalArray(ones(10, 10, 10), (X, Y, Z));


julia> B = swapdims(A, (Z, Dim{:custom}, Ti));


julia> dimnum(B, Ti)
3
```
"""
@inline swapdims(A::AbstractArray, newdims::Tuple) =
    rebuild(A, data(A), formatdims(A, swapdims(dims(A), newdims)))
@inline swapdims(dims::DimTuple, newdims::Tuple) =
    map((d, nd) -> _swapdims(d, nd), dims, newdims)

@inline _swapdims(dim::Dimension, newdim::DimType) =
    basetypeof(newdim)(val(dim), mode(dim), metadata(dim))
@inline _swapdims(dim::Dimension, newdim::Dimension) = newdim
@inline _swapdims(dim::Dimension, newdim::Nothing) = dim

"""
    reducedims(x, dimstoreduce)

Replace the specified dimensions with an index of length 1.
This is usually to match a new array size where an axis has been
reduced with a method like `mean` or `reduce` to a length of 1,
but the number of dimensions has not changed.

`IndexMode` traits are also updated to correspond to the change in
cell step, sampling type and order.
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
@inline reducedims(dim::Dimension, ::DimOrDimType) = reducedims(mode(dim), dim)

# Now reduce specialising on mode type

# NoIndex. Defaults to Start locus.
@inline reducedims(mode::NoIndex, dim::Dimension) =
    rebuild(dim, first(val(dim)), NoIndex())
# Categories are combined.
@inline reducedims(mode::Unaligned, dim::Dimension) =
    rebuild(dim, [nothing], NoIndex)
@inline reducedims(mode::Categorical, dim::Dimension{Vector{String}}) =
    rebuild(dim, ["combined"], Categorical())
@inline reducedims(mode::Categorical, dim::Dimension) =
    rebuild(dim, [:combined], Categorical())

@inline reducedims(mode::AbstractSampled, dim::Dimension) =
    reducedims(span(mode), sampling(mode), mode, dim)
@inline reducedims(::Irregular, ::Points, mode::AbstractSampled, dim::Dimension) =
    rebuild(dim, reducedims(Center(), dim::Dimension), mode)
@inline reducedims(::Irregular, ::Intervals, mode::AbstractSampled, dim::Dimension) = begin
    mode = rebuild(mode, Ordered(), span(mode))
    rebuild(dim, reducedims(locus(mode), dim), mode)
end
@inline reducedims(::Regular, ::Any, mode::AbstractSampled, dim::Dimension) = begin
    mode = rebuild(mode, Ordered(), Regular(step(mode) * length(dim)))
    rebuild(dim, reducedims(locus(mode), dim), mode)
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
@inline centerval(index::AbstractArray{<:AbstractFloat}, len) =
    [(index[len ÷ 2] + index[len ÷ 2 + 1]) / 2]
@inline centerval(index::AbstractArray, len) =
    [index[len ÷ 2 + 1]]


"""
    dims(x, lookup)

Get the dimension(s) matching the type(s) of the lookup dimension.

Lookup can be an Int or an Dimension, or a tuple containing
any combination of either.

## Arguments
- `x`: any object with a `dims` method, or a `Tuple` of `Dimension`.
- `lookup`: Tuple or a single `Dimension` or `Type`.

## Example
```jldoctest
julia> A = DimensionalArray(ones(10, 10, 10), (X, Y, Z));


julia> dims(A, Z)
dimension Z:
val: Base.OneTo(10)
mode: NoIndex()
metadata: nothing
type: Z{Base.OneTo{Int64},NoIndex,Nothing}
```
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
    comparedims(A::AbstractDimArray...)
    comparedims(A::Tuple...)
    comparedims(a, b)

Check that dimensions or tuples of dimensions are the same,
and return the first valid dimension. If `AbstractDimArray`s
are passed as arguments their dimensions are compared.

Empty tuples and `nothing` dimension values are ignored,
returning the `Dimension` value if it exists.
"""
function comparedims end

@inline comparedims(A::AbstractArray...) = comparedims(map(dims, A)...)
@inline comparedims(dims::DimTuple...) = map(d -> comparedims(dims[1], d), dims)
@inline comparedims(::Tuple{}) = ()

@inline comparedims(a::DimTuple, ::Nothing) = a
@inline comparedims(::Nothing, b::DimTuple) = b
@inline comparedims(::Nothing, ::Nothing) = nothing

# Cant use `map` here, tuples may not be the same length
@inline comparedims(a::DimTuple, b::DimTuple) =
    (comparedims(a[1], b[1]), comparedims(tail(a), tail(b))...)
@inline comparedims(a::DimTuple, b::Tuple{}) = a
@inline comparedims(a::Tuple{}, b::DimTuple) = b
@inline comparedims(a::Tuple{}, b::Tuple{}) = ()
@inline comparedims(a::Dimension, b::AnonDim) = a
@inline comparedims(a::AnonDim, b::Dimension) = b
@inline comparedims(a::Dimension, b::Dimension) = begin
    basetypeof(a) == basetypeof(b) ||
        throw(DimensionMismatch("$(basetypeof(a)) and $(basetypeof(b)) dims on the same axis"))
    # TODO compare the mode, and maybe the index.
    return a
end
