# These functions do most of the work in the package.
# They are all type-stable recusive methods for performance and extensibility.

const UnionAllTupleOrVector = Union{Vector{UnionAll},Tuple{UnionAll,Vararg}}

"""
    sortdims(tosort, order; op=(<:)) => Tuple

Sort dimensions `tosort` by `order`. Dimensions
in `order` but missing from `tosort` are replaced with `nothing`.

`tosort` and `order` can be `Tuple`s or `Vector`s or Dimension
or dimension type. Abstract supertypes like [`TimeDim`](@ref)
can be used in `order`.

`op` is `<:` by default, but can be `>:` to sort abstract types by concrete types.
"""
@inline sortdims(tosort, order; op=<:) = sortdims(Tuple(tosort), Tuple(order); op=op)
@inline sortdims(tosort::Tuple, order::Tuple{<:Integer,Vararg}; op=<:) =
    map(p -> tosort[p], Tuple(order))
@inline sortdims(tosort::Tuple, order::Tuple; op=<:) = begin
    extradims = otherdims(tosort, order; op=op)
    length(extradims) > 0 && _warnextradims(extradims)
    _sortdims(_maybeconstruct(Tuple(tosort)), Tuple(order), op)
end

@generated _sortdims(tosort::Tuple{Vararg{<:Dimension}}, order::Tuple{Vararg{<:Dimension}}, op) = begin
    indexexps = []
    ts = (tosort.parameters...,)
    allreadyfound = Int[]
    for (i, od) in enumerate(order.parameters)
        # Make sure we don't find the same dim twice
        found = 0
        while true
            found = findnext(sd -> dimsmatch(sd, od; op=_opasfunc(op)), ts, found + 1)
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
@inline _sortdims(tosort::Tuple, order::Tuple, op) = _sortdims(tosort, order, (), op)
@inline _sortdims(tosort::Tuple, order::Tuple, rejected, op) =
    # Match dims to the order, and also check if the mode has a
    # transformed dimension that matches
    if dimsmatch(tosort[1], order[1]; op=op)
        (tosort[1], _sortdims((rejected..., tail(tosort)...), tail(order), (), op)...)
    else
        _sortdims(tail(tosort), order, (rejected..., tosort[1]), op)
    end
# Return nothing and start on a new dim
@inline _sortdims(tosort::Tuple{}, order::Tuple, rejected, op) =
    (nothing, _sortdims(rejected, tail(order), (), op)...)
# Return an empty tuple if we run out of dims to sort
@inline _sortdims(tosort::Tuple, order::Tuple{}, rejected, op) = ()
@inline _sortdims(tosort::Tuple{}, order::Tuple{}, rejected, op) = ()

# @inline _maybeconstruct(dims::Array) = _maybeconstruct((dims...,)) 
@inline _maybeconstruct(dims::Tuple) = 
    (_maybeconstruct(dims[1]), _maybeconstruct(tail(dims))...)
@inline _maybeconstruct(::Tuple{}) = ()
@inline _maybeconstruct(dim::Dimension) = dim
@inline _maybeconstruct(dimtype::DimType) = isabstracttype(dimtype) ? dimtype : dimtype()

_opasfunc(::Type{typeof(<:)}) = <:
_opasfunc(::Type{typeof(>:)}) = >:

"""
    commondims(x, lookup; op=<:) => Tuple{Vararg{<:Dimension}}

This is basically `dims(x, lookup)` where the order of the original is kept, 
unlike [`dims`](@ref) where the lookup tuple determines the order

Also unlike `dims`,`commondims` always returns a `Tuple`, no matter the input.
No errors are thrown if dims are absent from either `x` or `lookup`.

`op` is `<:` by default, but can be `>:` to sort abstract types by concrete types.

```jldoctest
julia> using DimensionalData

julia> A = DimArray(ones(10, 10, 10), (X, Y, Z));

julia> commondims(A, X)
(X (type X) (NoIndex),)

julia> commondims(A, (X, Z))
(X (type X) (NoIndex), Z (type Z) (NoIndex))

julia> commondims(A, Ti)
()
```
"""
@inline commondims(A::AbstractArray, B::AbstractArray; op=<:) = 
    commondims(dims(A), dims(B); op=op)
@inline commondims(A::AbstractArray, lookup; op=<:) = commondims(dims(A), lookup; op=op)
@inline commondims(dims::Tuple, lookup; op=<:) = commondims(dims, (lookup,); op=op)
@inline commondims(dims::Tuple, lookup::Tuple; op=<:) = 
    _commondims(key2dim(dims), key2dim(lookup), (), op)

@inline _commondims(dims::Tuple, lookup::Tuple, rejected, op) =
    if dimsmatch(dims[1], lookup[1]; op=op)
        # Remove found lookup so it isn't found again
        (dims[1], _commondims(tail(dims), (rejected..., tail(lookup)...), (), op)...)
    else
        _commondims(dims, tail(lookup), (rejected..., lookup[1]), op)
    end
# Return an empty tuple when we run out of dims or lookups
@inline _commondims(dims::Tuple, lookup::Tuple{}, rejected, op) = 
    _commondims(tail(dims), rejected, (), op)
@inline _commondims(dims::Tuple{}, lookup::Tuple, rejected, op) = ()
@inline _commondims(dims::Tuple{}, lookup::Tuple{}, rejected, op) = ()


"""
    dimsmatch(dim::DimOrDimType, match::DimOrDimType; op=<:) => Bool

Compare 2 dimensions are of the same base type, or 
are at least rotations/transformations of the same type.

`op` is `<:` by default, but can be `>:` to match abstract types to concrete types.
"""
@inline dimsmatch(dims::Tuple, lookups::Tuple; op=<:) = 
    all(map((d, l) -> dimsmatch(d, l; op=op), dims, lookups))
@inline dimsmatch(dim::Dimension, lookup::Dimension; op=<:) = dimsmatch(typeof(dim), typeof(lookup); op=op)
@inline dimsmatch(dim::Type, lookup::Dimension; op=<:) = dimsmatch(dim, typeof(lookup); op=op)
@inline dimsmatch(dim::Dimension, lookup::Type; op=<:) = dimsmatch(typeof(dim), lookup; op=op)
@inline dimsmatch(dim::DimOrDimType, lookup::Nothing; op=<:) = false
@inline dimsmatch(dim::Nothing, lookup::DimOrDimType; op=<:) = false
@inline dimsmatch(dim::Nothing, lookup::Nothing; op=<:) = false
@inline dimsmatch(dim::Type, lookup::Type; op=<:) =
    op(basetypeof(dim), basetypeof(lookup)) || 
    op(basetypeof(dim), basetypeof(dims(modetype(lookup)))) ||
    op(basetypeof(dims(modetype(dim))), basetypeof(lookup))


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
function slicedims end
@inline slicedims(A, I::Tuple) = slicedims(dims(A), refdims(A), I)
@inline slicedims(dims::Tuple, refdims::Tuple, I::Tuple{}) = dims, refdims
@inline slicedims(dims::Tuple, refdims::Tuple, I::Tuple) = begin
    newdims, newrefdims = slicedims(dims, I)
    newdims, (refdims..., newrefdims...)
end
@inline slicedims(dims::Tuple, refdims::Tuple, I::Tuple{<:CartesianIndex}) = 
    slicedims(dims, refdims, Tuple(I)) 
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

@inline relate(d::Dimension, i) = _maybeflip(relation(d), d, i)

@inline _maybeflip(::Union{ForwardRelation,ForwardIndex}, d, i) = i
@inline _maybeflip(::Union{ReverseRelation,ReverseIndex}, d, i::Integer) = 
    lastindex(d) - i + 1
@inline _maybeflip(::Union{ReverseRelation,ReverseIndex}, d, i::AbstractArray) = 
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
@inline dimnum(d::Tuple, lookup::Colon) = Colon()

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
# For ambiguity
@inline _dimnum(dims::Tuple{}, lookup::Tuple{Number,Vararg}, rejected, n) = lookup
# Throw an error if the lookup is not found
@noinline _dimnum(dims::Tuple{}, lookup::Tuple, rejected, n) = _nolookuperror(lookup)
# Return an empty tuple when we run out of lookups
@inline _dimnum(dims::Tuple, lookup::Tuple{}, rejected, n) = ()
@inline _dimnum(dims::Tuple{}, lookup::Tuple{}, rejected, n) = ()

"""
    hasdim(x, lookup::Tuple) => NTUple{Bool}
    hasdim(x, lookup) => Bool

## Arguments
- `x`: any object with a `dims` method, a `Tuple` of `Dimension` or a single `Dimension`.
- `lookup`: Tuple or single `Dimension` or dimension `Type`.
- `op`: `<:` by default, but can be `>:` to match abstract types to concrete types.

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
@inline hasdim(x, lookup; op=<:) = hasdim(dims(x), lookup; op=op)
@inline hasdim(x::Nothing, lookup; op=<:) = _dimsnotdefinederror()
@inline hasdim(d::Tuple, lookup::Tuple; op=<:) = map(l -> hasdim(d, l; op=op), lookup)
@inline hasdim(d::Tuple, lookup::Symbol; op=<:) = hasdim(d, key2dim(lookup); op=op)
@inline hasdim(d::Tuple, lookup::DimOrDimType; op=<:) =
    if dimsmatch(d[1], lookup; op=op)
        true
    else
        hasdim(tail(d), lookup; op=op)
    end
@inline hasdim(::Tuple{}, ::DimOrDimType; op=<:) = false

"""
    otherdims(x, lookup) => Tuple{Vararg{<:Dimension,N}}

## Arguments
- `x`: any object with a `dims` method, a `Tuple` of `Dimension`.
- `lookup`: Tuple or single `Dimension` or dimension `Type`.
- `op`: `<:` by default, but can be `>:` to match abstract types to concrete types.

A tuple holding the unmatched dimensions is always returned.

## Example
```jldoctest
julia> using DimensionalData

julia> A = DimArray(ones(10, 10, 10), (X, Y, Z));

julia> otherdims(A, X)
(Y (type Y) (NoIndex), Z (type Z) (NoIndex))

julia> otherdims(A, (Y, Z))
(X (type X) (NoIndex),)

julia> otherdims(A, Ti)
(X (type X) (NoIndex), Y (type Y) (NoIndex), Z (type Z) (NoIndex))
```
"""
@inline otherdims(x, lookup; op=<:) = otherdims(dims(x), lookup; op=op)
@inline otherdims(::Nothing, lookup; op=<:) = _dimsnotdefinederror()
@inline otherdims(dims::DimOrDimType, lookup; op=<:) = otherdims((dims,), lookup; op=op)
@inline otherdims(dims::Tuple, lookup::DimOrDimType; op=<:) = otherdims(dims, (lookup,); op=op)
@inline otherdims(dims::Tuple, lookup::Tuple; op=<:) =
    _otherdims(dims, _sortdims(key2dim(lookup), key2dim(dims), op), op)

#= Work with a sorted lookup where the missing dims are `nothing`.
Then we can compare with `dimsmatch`, and splat away the matches. =#
@inline _otherdims(dims::Tuple, sortedlookup::Tuple, op) =
    (_otherdims(dims[1], sortedlookup[1], op)..., _otherdims(tail(dims), tail(sortedlookup), op)...)
@inline _otherdims(dims::Tuple{}, ::Tuple{}, op) = ()
@inline _otherdims(dim::DimOrDimType, lookup, op) = dimsmatch(dim, lookup; op=op) ? () : (dim,)

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
@inline setdims(x, newdims) = rebuild(x, data(x), setdims(dims(x), key2dim(newdims)))
@inline setdims(dims::DimTuple, newdim::Dimension) = setdims(dims, (newdim,))
@inline setdims(dims::DimTuple, newdims::DimTuple) = swapdims(dims, sortdims(newdims, dims))

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
@inline reducedims(x, dimstoreduce) = _reducedims(x, key2dim(dimstoreduce))

@inline _reducedims(x, dimstoreduce) = _reducedims(x, (dimstoreduce,))
@inline _reducedims(x, dimstoreduce::Tuple) = _reducedims(dims(x), dimstoreduce)
@inline _reducedims(dims::DimTuple, dimstoreduce::Tuple) =
    map(_reducedims, dims, sortdims(dimstoreduce, dims))
# Map numbers to corresponding dims. Not always type-stable
@inline _reducedims(dims::DimTuple, dimstoreduce::Tuple{Vararg{Int}}) =
    map(_reducedims, dims, sortdims(map(i -> dims[i], dimstoreduce), dims))
# Reduce matching dims but ignore nothing vals - they are the dims not being reduced
@inline _reducedims(dim::Dimension, ::Nothing) = dim
@inline _reducedims(dim::Dimension, ::DimOrDimType) = _reducedims(mode(dim), dim)
# Now reduce specialising on mode type
# NoIndex. Defaults to Start locus.
@inline _reducedims(mode::NoIndex, dim::Dimension) =
    rebuild(dim, first(index(dim)), NoIndex())
# Categories are combined.
@inline _reducedims(mode::Unaligned, dim::Dimension) = rebuild(dim, [nothing], NoIndex)
@inline _reducedims(mode::Categorical, dim::Dimension{Vector{String}}) =
    rebuild(dim, ["combined"], Categorical())
@inline _reducedims(mode::Categorical, dim::Dimension) =
    rebuild(dim, [:combined], Categorical())
@inline _reducedims(mode::AbstractSampled, dim::Dimension) =
    _reducedims(span(mode), sampling(mode), mode, dim)
@inline _reducedims(::Irregular, ::Points, mode::AbstractSampled, dim::Dimension) =
    rebuild(dim, _reducedims(Center(), dim::Dimension), mode)
@inline _reducedims(::Irregular, ::Intervals, mode::AbstractSampled, dim::Dimension) = begin
    mode = rebuild(mode; order=Ordered(), span=span(mode))
    rebuild(dim, _reducedims(locus(mode), dim), mode)
end
@inline _reducedims(::Regular, ::Any, mode::AbstractSampled, dim::Dimension) = begin
    mode = rebuild(mode; order=Ordered(), span=Regular(step(mode) * length(dim)))
    rebuild(dim, _reducedims(locus(mode), dim), mode)
end
# Get the index value at the reduced locus.
# This is the start, center or end point of the whole index.
@inline _reducedims(locus::Start, dim::Dimension) = [first(index(dim))]
@inline _reducedims(locus::End, dim::Dimension) = [last(index(dim))]
@inline _reducedims(locus::Center, dim::Dimension) = begin
    index = val(dim)
    len = length(index)
    if iseven(len)
        _centerval(index, len)
    else
        [index[len ÷ 2 + 1]]
    end
end
@inline _reducedims(locus::Locus, dim::Dimension) = _reducedims(Center(), dim)

# Need to specialise for more types
@inline _centerval(index::AbstractArray{<:AbstractFloat}, len) =
    [(index[len ÷ 2] + index[len ÷ 2 + 1]) / 2]
@inline _centerval(index::AbstractArray, len) = [index[len ÷ 2 + 1]]

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
@inline dims(x::Nothing, lookup) = _dimsnotdefinederror()
@inline dims(d::DimTuple, lookup) = dims(d, (lookup,))[1]
@inline dims(d::DimTuple, lookup::Tuple) = _dims(d, key2dim(lookup), (), d)

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
@noinline _dims(d, lookup::Tuple, rejected, remaining::Tuple{}) = _nolookuperror(lookup)
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
    basetypeof(a) == basetypeof(b) || _dimsmismatcherror(a, b)
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

All other `Dim{S}()` dimensions will generate `Symbol`s `S`.
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
@inline dimstride(::Nothing, n) = _dimsnotdefinederror()
@inline dimstride(dims::DimTuple, d::DimOrDimType) = dimstride(dims, dimnum(dims, d)) 
@inline dimstride(dims::DimTuple, n::Int) = prod(map(length, dims)[1:n-1])

@inline _kwdims(kw::Base.Iterators.Pairs) = _kwdims(kw.data)
@inline _kwdims(kw::NamedTuple{Keys}) where Keys = _kwdims(key2dim(Keys), values(kw))
@inline _kwdims(dims::Tuple, vals::Tuple) =
    (rebuild(dims[1], vals[1]), _kwdims(tail(dims), tail(vals))...)
_kwdims(dims::Tuple{}, vals::Tuple{}) = ()

@inline _pairdims(pairs::Pair...) = map(p -> basetypeof(key2dim(first(p)))(last(p)), pairs)

_remove_nothing(xs::Tuple) = _remove_nothing(xs...)
_remove_nothing(x, xs...) = (x, _remove_nothing(xs...)...)
_remove_nothing(::Nothing, xs...) = _remove_nothing(xs...)
_remove_nothing() = ()

# Error methods. @noinline to avoid allocations.
@noinline _dimsnotdefinederror() = throw(ArgumentError("Object does not define a `dims` method"))
@noinline _nolookuperror(lookup) = throw(ArgumentError("No $(name(lookup[1])) in dims"))
@noinline _dimsmismatcherror(a, b) = throw(DimensionMismatch("$(name(a)) and $(name(b)) dims on the same axis"))
@noinline _warnextradims(extradims) = @warn "$(map(basetypeof, extradims)) dims were not found in object"
