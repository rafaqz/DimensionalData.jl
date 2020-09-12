# These functions do most of the work in the package.
# They are all type-stable recusive methods for performance and extensibility.

const UnionAllTupleOrVector = Union{Vector{UnionAll},Tuple{UnionAll,Vararg}}

"""
    sortdims(tosort, order) => Tuple

Sort dimensions `tosort` by `order`. Dimensions
in `order` but missing from `tosort` are replaced with `nothing`.

`tosort` and `order` can be `Tuple`s or `Vector`s or Dimension
or dimension type. Abstract supertypes like [`TimeDim`](@ref)
can be used in `order`.
"""
@inline sortdims(tosort, order::Union{Vector{<:Integer},Tuple{<:Integer,Vararg}}) =
    map(p -> tosort[p], Tuple(order))
@inline sortdims(tosort, order) = 
    _sortdims(_maybeconstruct(Tuple(tosort)), Tuple(order))

@generated _sortdims(tosort::Tuple{Vararg{<:Dimension}}, 
                      order::Tuple{Vararg{<:Dimension}}) = begin
    indexexps = []
    ts = (tosort.parameters...,)
    allreadyfound = Int[]
    for (i, od) in enumerate(order.parameters)
        # Make sure we don't find the same dim twice
        found = 0
        while true
            found = findnext(sd -> dimsmatch(sd, od), ts, found + 1)
            if found == nothing
                push!(indexexps, :(nothing))
                break
            elseif !(found in allreadyfound)
                push!(indexexps, :(tosort[$found]))
                push!(allreadyfound, found)
                break
            end
        end
    end
    Expr(:tuple, indexexps...)
end

# Fallback for Unionall reuired for plotting by abstract
# Dimension type
@inline _sortdims(tosort::Tuple, order::Tuple) = _sortdims(tosort, order, ())
@inline _sortdims(tosort::Tuple, order::Tuple, rejected) =
    # Match dims to the order, and also check if the mode has a
    # transformed dimension that matches
    if dimsmatch(tosort[1], order[1])
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

@inline _maybeconstruct(dims::Array) = _maybeconstruct((dims...,)) 
@inline _maybeconstruct(dims::Tuple) = 
    (_maybeconstruct(dims[1]), _maybeconstruct(tail(dims))...)
@inline _maybeconstruct(::Tuple{}) = ()
@inline _maybeconstruct(dim::Dimension) = dim
@inline _maybeconstruct(dimtype::UnionAll) = 
    isabstracttype(dimtype) ? dimtype : dimtype()
@inline _maybeconstruct(dimtype::DimType) = 
    isabstracttype(dimtype) ? dimtype : dimtype()

"""
    commondims(x, lookup) => Tuple{Vararg{<:Dimension}}

This is basically `dims(x, lookup)` where the order of the original is kept, 
unlike [`dims`](@ref) where the lookup tuple determines the order

Also unlike `dims`,`commondims` always returns a `Tuple`, no matter the input.
```jldoctest
julia> using DimensionalData

julia> A = DimArray(ones(10, 10, 10), (X, Y, Z));

julia> commondims(A, X)
(X: Base.OneTo(10) (NoIndex),)

julia> commondims(A, (X, Z))
(X: Base.OneTo(10) (NoIndex), Z: Base.OneTo(10) (NoIndex))

julia> commondims(A, Ti)
()
```
"""
@inline commondims(A::AbstractArray, B::AbstractArray) = commondims(dims(A), dims(B))
@inline commondims(A::AbstractArray, lookup) = commondims(dims(A), lookup)
@inline commondims(dims::Tuple, lookup) = commondims(dims, (lookup,))
@inline commondims(dims::Tuple, lookup::Tuple) = _commondims(key2dim(dims), key2dim(lookup))
@inline _commondims(dims::Tuple, lookup::Tuple) = 
    if hasdim(lookup, dims[1])
        (dims[1], commondims(tail(dims), lookup)...)
    else
        commondims(tail(dims), lookup) 
    end
@inline _commondims(dims::Tuple{}, lookup::Tuple) = ()


"""
    dimsmatch(dim::DimOrDimType, match::DimOrDimType) => Bool

Compare 2 dimensions are of the same base type, or 
are at least rotations/transformations of the same type.
"""
@inline dimsmatch(dims::Tuple, lookups::Tuple) = all(map(dimsmatch, dims, lookups))
@inline dimsmatch(dim::Dimension, match::Dimension) = dimsmatch(typeof(dim), typeof(match))
@inline dimsmatch(dim::Type, match::Dimension) = dimsmatch(dim, typeof(match))
@inline dimsmatch(dim::Dimension, match::Type) = dimsmatch(typeof(dim), match)
@inline dimsmatch(dim::DimOrDimType, match::Nothing) = false
@inline dimsmatch(dim::Nothing, match::DimOrDimType) = false
@inline dimsmatch(dim::Nothing, match::Nothing) = false
@inline dimsmatch(dim::Type, match::Type) =
    basetypeof(dim) <: basetypeof(match) || 
    basetypeof(dim) <: basetypeof(dims(modetype(match))) ||
    basetypeof(dims(modetype(dim))) <: basetypeof(match)

"""
    dims2indices(dim::Dimension, lookup, [emptyval=Colon()]) => NTuple{Union{Colon,AbstractArray,Int}}

Convert a `Dimension` or `Selector` lookup to indices, ranges or Colon.
"""
@inline dims2indices(dim::Dimension, lookup, emptyval=Colon()) =
    _dims2indices(dim, lookup, emptyval)
@inline dims2indices(dim::Dimension, lookup::StandardIndices, emptyval=Colon()) = lookup
@inline dims2indices(x, lookup, emptyval=Colon()) =
    dims2indices(dims(x), lookup, emptyval)
@inline dims2indices(::Nothing, lookup, emptyval=Colon()) = dimerror()

@noinline dimerror() = throw(ArgumentError("Object not define a `dims` method"))

@inline dims2indices(dims::DimTuple, lookup, emptyval=Colon()) =
    dims2indices(dims, (lookup,), emptyval)
# Standard array indices are simply returned
@inline dims2indices(dims::DimTuple, lookup::Tuple{Vararg{<:StandardIndices}}, 
                     emptyval=Colon()) = lookup
# Otherwise attempt to convert dims to indices
@inline dims2indices(dims::DimTuple, lookup::Tuple, emptyval=Colon()) =
    _dims2indices(map(mode, dims), dims, sortdims(lookup, dims), emptyval)

# Handle tuples with @generated
@inline _dims2indices(modes::Tuple{}, dims::Tuple{}, lookup::Tuple{}, emptyval) = ()
@generated _dims2indices(modes::Tuple, dims::Tuple, lookup::Tuple, emptyval) =
    _dims2indices_inner(modes, dims, lookup, emptyval)

_dims2indices_inner(modes::Type, dims::Type, lookup::Type, emptyval) = begin
    unalligned = Expr(:tuple) 
    ualookups = Expr(:tuple)
    alligned = Expr(:tuple)
    dimmerge = Expr(:tuple)
    a_count = ua_count = 0
    for (i, mp) in enumerate(modes.parameters)
        if mp <: Unaligned
            ua_count += 1
            push!(unalligned.args, :(dims[$i]))
            push!(ualookups.args, :(lookup[$i]))
            push!(dimmerge.args, :(uadims[$ua_count])) 
        else
            a_count += 1
            push!(alligned.args, :(_dims2indices(dims[$i], lookup[$i], emptyval)))
            # Update  the merged tuple
            push!(dimmerge.args, :(adims[$a_count])) 
        end
    end

    if length(unalligned.args) > 1
        # Output the dimmerge, that will combine uadims and adims in the right order 
        quote 
             adims = $alligned 
             # Unaligned dims have to be run together as a set
             uadims = unalligned2indices($unalligned, $ualookups)
             $dimmerge
        end
    else
        alligned
    end
end

# Single dim methods

# A Dimension type always means Colon(), as if it was constructed with the default value.
@inline _dims2indices(dim::Dimension, lookup::Type{<:Dimension}, emptyval) = Colon()
# Nothing means nothing was passed for this dimension, return the emptyval
@inline _dims2indices(dim::Dimension, lookup::Nothing, emptyval) = emptyval
# Simply unwrap dimensions
@inline _dims2indices(dim::Dimension, lookup::Dimension, emptyval) = val(lookup)
# Pass `Selector`s to sel2indices
@inline _dims2indices(dim::Dimension, lookup::Dimension{<:Selector}, emptyval) =
    sel2indices(dim, val(lookup))


"""
    slicedims(x, I) => Tuple{Tuple,Tuple}

Slice the dimensions to match the axis values of the new array

All methods returns a tuple conatining two tuples: the new dimensions,
and the reference dimensions. The ref dimensions are no longer used in
the new struct but are useful to give context to plots.

Called at the array level the returned tuple will also include the
previous reference dims attached to the array.

# Arguments

- `x`: An `AbstractDimArray`, `Tuple` of `Dimension`, or `Dimension`
- `I`: A tuple of `Integer`, `Colon` or `AbstractArray`
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
@inline slicedims(d::Dimension, i::Integer) =
    (), (rebuild(d, d[relate(d, i)], slicemode(mode(d), val(d), i)),)
# TODO deal with unordered arrays trashing the index order
@inline slicedims(d::Dimension{<:Union{AbstractArray,Val}}, i::AbstractArray) =
    (rebuild(d, d[relate(d, i)], slicemode(mode(d), val(d), i)),), ()
@inline slicedims(d::Dimension{<:Union{AbstractArray,Val}}, i::AbstractArray{Bool}) =
    (rebuild(d, d[relate(d, i)], slicemode(mode(d), val(d), i)),), ()
@inline slicedims(d::Dimension{<:Colon}, i::Colon) = (d,), ()
@inline slicedims(d::Dimension{<:Colon}, i::AbstractArray) = (d,), ()
@inline slicedims(d::Dimension{<:Colon}, i::Integer) = (), (d,)

@inline relate(d::Dimension, i) = maybeflip(relation(d), d, i)

@inline maybeflip(::Union{ForwardRelation,ForwardIndex}, d, i) = i
@inline maybeflip(::Union{ReverseRelation,ReverseIndex}, d, i::Integer) = 
    lastindex(d) - i + 1
@inline maybeflip(::Union{ReverseRelation,ReverseIndex}, d, i::AbstractArray) = 
    reverse(lastindex(d) .- i .+ 1)

"""
    dimnum(x, lookup::Tuple) => NTuple{Int}
    dimnum(x, lookup) => Int

Get the number(s) of `Dimension`(s) as ordered in the dimensions of an object.

## Arguments
- `x`: any object with a `dims` method, a `Tuple` of `Dimension` or a single `Dimension`.
- `lookup`: Tuple, Array or single `Dimension` or dimension `Type`.

The return type will be a Tuple of `Int` or a single `Int`,
depending on wether `lookup` is a `Tuple` or single `Dimension`.

## Example

```jldoctest
julia> using DimensionalData

julia> A = DimArray(ones(10, 10, 10), (X, Y, Z));

julia> dimnum(A, (Z, X, Y))
(3, 1, 2)

julia> dimnum(A, Y)
2
```
"""
@inline dimnum(A, lookup) = dimnum(dims(A), lookup)
@inline dimnum(d::Tuple, lookup) = dimnum(d, (lookup,))[1]
@inline dimnum(d::Tuple, lookup::AbstractArray) = dimnum(d, (lookup...,))
@inline dimnum(d::Tuple, lookup::Tuple) = _dimnum(d, key2dim(lookup), (), 1)

# Match dim and lookup, also check if the mode has a transformed dimension that matches
@inline _dimnum(d::Tuple, lookup::Tuple, rejected, n) =
    if dimsmatch(d[1], lookup[1])
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
    throw(ArgumentError("No $(name(lookup[1])) in dims"))
# Return an empty tuple when we run out of lookups
@inline _dimnum(dims::Tuple, lookup::Tuple{}, rejected, n) = ()
@inline _dimnum(dims::Tuple{}, lookup::Tuple{}, rejected, n) = ()

"""
    hasdim(x, lookup::Tuple) => NTUple{Bool}
    hasdim(x, lookup) => Bool

## Arguments
- `x`: any object with a `dims` method, a `Tuple` of `Dimension` or a single `Dimension`.
- `lookup`: Tuple or single `Dimension` or dimension `Type`.

Check if an object or tuple contains an `Dimension`, or a tuple of dimensions.

## Example
```jldoctest
julia> using DimensionalData

julia> A = DimArray(ones(10, 10, 10), (X, Y, Z));

julia> hasdim(A, X)
true

julia> hasdim(A, (Z, X, Y))
(true, true, true)

julia> hasdim(A, Ti)
false
```
"""
@inline hasdim(x, lookup) = hasdim(dims(x), lookup)
@inline hasdim(x::Nothing, lookup) = dimerror()
@inline hasdim(d::Tuple, lookup::Tuple) = map(l -> hasdim(d, l), lookup)
@inline hasdim(d::Tuple, lookup::Symbol) = hasdim(d, key2dim(lookup))
@inline hasdim(d::Tuple, lookup::DimOrDimType) =
    if dimsmatch(d[1], lookup)
        true
    else
        hasdim(tail(d), lookup)
    end
@inline hasdim(::Tuple{}, ::DimOrDimType) = false

"""
    otherdims(x, lookup) => Tuple{Vararg{<:Dimension,N}}

## Arguments
- `x`: any object with a `dims` method, a `Tuple` of `Dimension`.
- `lookup`: Tuple or single `Dimension` or dimension `Type`.

A tuple holding the unmatched dimensions is always returned.

## Example
```jldoctest
julia> using DimensionalData

julia> A = DimArray(ones(10, 10, 10), (X, Y, Z));

julia> otherdims(A, X)
(Y: Base.OneTo(10) (NoIndex), Z: Base.OneTo(10) (NoIndex))

julia> otherdims(A, (Y, Z))
(X: Base.OneTo(10) (NoIndex),)

julia> otherdims(A, Ti)
(X: Base.OneTo(10) (NoIndex), Y: Base.OneTo(10) (NoIndex), Z: Base.OneTo(10) (NoIndex))
```
"""
@inline otherdims(x, lookup) = otherdims(dims(x), lookup)
@inline otherdims(::Nothing, lookup) = dimerror()
@inline otherdims(dims::Tuple, lookup::DimOrDimType) = otherdims(dims, (lookup,))
@inline otherdims(dims::Tuple, lookup::Tuple) =
    _otherdims(dims, _sortdims(key2dim(lookup), key2dim(dims)))

#= Work with a sorted lookup where the missing dims are `nothing`.
Then we can compare with `dimsmatch`, and splat away the matches. =#
@inline _otherdims(dims::Tuple, sortedlookup::Tuple) =
    (_otherdims(dims[1], sortedlookup[1])..., 
     _otherdims(tail(dims), tail(sortedlookup))...)
@inline _otherdims(dims::Tuple{}, ::Tuple{}) = ()
@inline _otherdims(dim::DimOrDimType, lookupdim) =
    dimsmatch(dim, lookupdim) ? () : (dim,)

"""
    setdims(A::AbstractArray, newdims) => AbstractArray
    setdims(::Tuple, newdims) => Tuple{Vararg{<:Dimension,N}}

Replaces the first dim matching `<: basetypeof(newdim)` with newdim, 
and returns a new object or tuple with the dimension updated.

## Arguments
- `x`: any object with a `dims` method, a `Tuple` of `Dimension` or a single `Dimension`.
- `newdim`: Tuple or single `Dimension` or dimension `Type`.

# Example
```jldoctest
using DimensionalData

A = DimArray(ones(10, 10), (X, Y(10:10:100)))
B = setdims(A, Y('a':'j'))
val(dims(B, Y))

# output

'a':1:'j'
```
"""
@inline setdims(A, newdims) = 
    rebuild(A, parent(A), setdims(dims(A), key2dim(newdims)))
@inline setdims(dims::DimTuple, newdim::Dimension) =
    setdims(dims, (newdim,))
@inline setdims(dims::DimTuple, newdims::DimTuple) = 
    swapdims(dims, sortdims(newdims, dims))

"""
    swapdims(x::T, newdims) => T
    swapdims(dims::Tuple, newdims) => Tuple{Dimension} 

Swap dimensions for the passed in dimensions, in the
order passed.

Passing in the `Dimension` types rewraps the dimension index, 
keeping the index values and metadata, while constructed `Dimension` 
objectes replace the original dimension. `nothing` leaves the original 
dimension as-is.

## Arguments
- `x`: any object with a `dims` method or a `Tuple` of `Dimension`.
- `newdim`: Tuple of `Dimension` or dimension `Type`.

# Example
```jldoctest
julia> using DimensionalData

julia> A = DimArray(ones(10, 10, 10), (X, Y, Z));

```
"""
@inline swapdims(x, newdims::Tuple) =
    rebuild(x; dims=formatdims(x, swapdims(dims(x), newdims)))
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
@inline reducedims(x, dimstoreduce) = reducedims(x, (dimstoreduce,))
@inline reducedims(x, dimstoreduce::Tuple) = reducedims(dims(x), dimstoreduce)
@inline reducedims(dims::DimTuple, dimstoreduce::Tuple) =
    map(reducedims, dims, sortdims(dimstoreduce, dims))
# Map numbers to corresponding dims. Not always type-stable
@inline reducedims(dims::DimTuple, dimstoreduce::Tuple{Vararg{Int}}) =
    map(reducedims, dims, sortdims(map(i -> dims[i], dimstoreduce), dims))

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
    mode = rebuild(mode; order=Ordered(), span=span(mode))
    rebuild(dim, reducedims(locus(mode), dim), mode)
end
@inline reducedims(::Regular, ::Any, mode::AbstractSampled, dim::Dimension) = begin
    mode = rebuild(mode; order=Ordered(), span=Regular(step(mode) * length(dim)))
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
julia> using DimensionalData

julia> A = DimArray(ones(10, 10, 10), (X, Y, Z));

```
"""
@inline dims(x, lookup) = dims(dims(x), lookup)
@inline dims(x::Nothing, lookup) = dimerror()
@inline dims(d::DimTuple, lookup) = dims(d, (lookup,))[1]
@inline dims(d::DimTuple, lookup::Tuple) = 
    _dims(d, key2dim(lookup), (), d)

@inline _dims(d, lookup::Tuple, rejected, remaining) =
    if dimsmatch(remaining[1], lookup[1])
        # Remove found dim so it isn't found again
        (remaining[1], _dims(d, tail(lookup), (), (rejected..., tail(remaining)...))...)
    else
        _dims(d, lookup, (rejected..., remaining[1]), tail(remaining))
    end
# Numbers are returned as-is
@inline _dims(d, lookup::Tuple{Number,Vararg}, rejected, remaining) =
    (d[lookup[1]], _dims(d, tail(lookup), (), (rejected..., remaining...))...)
# For method ambiguities
@inline _dims(d, lookup::Tuple{Number,Vararg}, rejected, remaining::Tuple{}) = ()
# Throw an error if the lookup is not found
@inline _dims(d, lookup::Tuple, rejected, remaining::Tuple{}) =
    throw(ArgumentError("No $(name(lookup[1])) in dims"))
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

@inline comparedims(x...) = comparedims(x)
@inline comparedims(A::Tuple) = comparedims(map(dims, A)...)
@inline comparedims(dims::Vararg{<:Tuple{Vararg{<:Dimension}}}) = 
    map(d -> comparedims(dims[1], d), dims)[1]
@inline comparedims() = ()

@inline comparedims(a::DimTuple, ::Nothing) = a
@inline comparedims(::Nothing, b::DimTuple) = b
@inline comparedims(::Nothing, ::Nothing) = nothing

# Cant use `map` here, tuples may not be the same length
@inline comparedims(a::DimTuple, b::DimTuple) =
    (comparedims(a[1], b[1]), comparedims(tail(a), tail(b))...)
@inline comparedims(a::DimTuple, b::Tuple{}) = a
@inline comparedims(a::Tuple{}, b::DimTuple) = b
@inline comparedims(a::Tuple{}, b::Tuple{}) = ()
@inline comparedims(a::AnonDim, b::AnonDim) = nothing
@inline comparedims(a::Dimension, b::AnonDim) = a
@inline comparedims(a::AnonDim, b::Dimension) = b
@inline comparedims(a::Dimension, b::Dimension) = begin
    basetypeof(a) == basetypeof(b) ||
        throw(DimensionMismatch("$(name(a)) and $(name(b)) dims on the same axis"))
    # TODO compare the mode, and maybe the index.
    return a
end

"""
    key2dim(s::Symbol) => Dimension
    key2dim(dims::Tuple) => Dimension

Convert a symbol to a dimension object. `:X`, `:Y`, `:Ti` etc will be converted.
to `X()`, `Y()`, `Ti()`, as with any other dims generated with the [`@dim`](@ref) macro.

All other `Symbol`s `S` will generate `Dim{S}()` dimensions. 
"""
@inline key2dim(s::Symbol) = key2dim(Val(s))
@inline key2dim(dims::Tuple) = map(key2dim, dims)
# Allow other things to pass through
@inline key2dim(dim::Dimension) = dim
@inline key2dim(dimtype::Type{<:Dimension}) = dimtype
@inline key2dim(dim) = dim


"""
    dim2key(dim::Dimension) => Symbol
    dim2key(dims::Type{<:Dimension}) => Symbol

Convert a dimension object to a simbol. `X()`, `Y()`, `Ti()` etc will be converted.
to `:X`, `:Y`, `:Ti`, as with any other dims generated with the [`@dim`](@ref) macro.

All other `Symbol`s `S` will generate `Dim{S}()` dimensions. 
"""
@inline dim2key(dim::Dimension) = dim2key(typeof(dim))
@inline dim2key(dt::Type{<:Dimension}) = Symbol(Base.typename(dt))

"""
    dimstride(x, dim)

Will get the stride of the dimension relative to the other dimensions. 

This may or may not be eual to the stride of the related array, 
although it will be for `Array`.

## Arguments

- `x` is any object with a `dims` method, or a `Tuple` of `Dimension`.
- `dim` is a `Dimension`, `Dimension` type, or and `Int`. Using an `Int` is not type-stable. 
"""
@inline dimstride(x, n) = dimstride(dims(x), n) 
@inline dimstride(::Nothing, n) = error("no dims Tuple available")
@inline dimstride(dims::DimTuple, d::DimOrDimType) = dimstride(dims, dimnum(dims, d)) 
@inline dimstride(dims::DimTuple, n::Int) = prod(map(length, dims)[1:n-1])


@inline _kwargdims(kwargs::Base.Iterators.Pairs) = _kwargdims(kwargs.data)
@inline _kwargdims(kwargsdata::NamedTuple{Keys}) where Keys =
    _kwargdims(key2dim(Keys), values(kwargsdata))
@inline _kwargdims(dims::Tuple, vals::Tuple) =
    (rebuild(dims[1], vals[1]), _kwargdims(tail(dims), tail(vals))...)
_kwargdims(dims::Tuple{}, vals::Tuple{}) = ()

@inline _pairdims(pairs::Pair...) = 
    map(p -> basetypeof(key2dim(first(p)))(last(p)), pairs)
