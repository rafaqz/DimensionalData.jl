# These functions do most of the work in the package.
# They are all type-stable recusive methods for performance and extensibility.

"""
    dimsmatch([f], dim, lookup) => Bool
    dimsmatch([f], dims::Tuple, lookups::Tuple) => Bool

Compare 2 dimensions or `Tuple` of `Dimension` are of the same base type, 
or are at least rotations/transformations of the same type.

`f` is `<:` by default, but can be `>:` to match abstract types to concrete types.
"""
@inline dimsmatch(dims, lookups) = dimsmatch(<:, dims, lookups)
@inline dimsmatch(f::Function, dims::Tuple, lookups::Tuple) =
    all(map((d, l) -> dimsmatch(f, d, l), dims, lookups))
@inline dimsmatch(f::Function, dim, lookup) = dimsmatch(f, typeof(dim), typeof(lookup))
@inline dimsmatch(f::Function, dim::Type, lookup) = dimsmatch(f, dim, typeof(lookup))
@inline dimsmatch(f::Function, dim, lookup::Type) = dimsmatch(f, typeof(dim), lookup)
@inline dimsmatch(f::Function, dim::Nothing, lookup::Type) = false
@inline dimsmatch(f::Function, dim::Type, ::Nothing) = false
@inline dimsmatch(f::Function, dim, lookup::Nothing) = false
@inline dimsmatch(f::Function, dim::Nothing, lookup) = false
@inline dimsmatch(f::Function, dim::Nothing, lookup::Nothing) = false
@inline dimsmatch(f::Function, dim::Type{D}, match::Type{M}) where {D,M} =
    f(basetypeof(unwrap(D)), basetypeof(unwrap(M))) ||
    f(basetypeof(unwrap(D)), basetypeof(dims(modetype(unwrap(M))))) ||
    f(basetypeof(dims(modetype(unwrap(D)))), basetypeof(unwrap(M)))

"""
    key2dim(s::Symbol) => Dimension
    key2dim(dims...) => Tuple{Dimension,Vararg}
    key2dim(dims::Tuple) => Tuple{Dimension,Vararg}

Convert a symbol to a dimension object. `:X`, `:Y`, `:Ti` etc will be converted.
to `X()`, `Y()`, `Ti()`, as with any other dims generated with the [`@dim`](@ref) macro.

All other `Symbol`s `S` will generate `Dim{S}()` dimensions.
"""
@inline key2dim(t::Tuple) = map(key2dim, t)
@inline key2dim(s::Symbol) = key2dim(Val{s}())
# Allow other things to pass through
@inline key2dim(d::Val{<:Dimension}) = d
@inline key2dim(d) = d

"""
    dim2key(dim::Dimension) => Symbol
    dim2key(dims::Type{<:Dimension}) => Symbol

Convert a dimension object to a simbol. `X()`, `Y()`, `Ti()` etc will be converted.
to `:X`, `:Y`, `:Ti`, as with any other dims generated with the [`@dim`](@ref) macro.

All other `Dim{S}()` dimensions will generate `Symbol`s `S`.
"""
@inline dim2key(dim::Dimension) = dim2key(typeof(dim))
@inline dim2key(dim::Val{D}) where D <: Dimension = dim2key(D)
@inline dim2key(dt::Type{<:Dimension}) = Symbol(Base.nameof(dt))

"""
    sortdims([f], tosort, order) => Tuple

Sort dimensions `tosort` by `order`. Dimensions
in `order` but missing from `tosort` are replaced with `nothing`.

`tosort` and `order` can be `Tuple`s or `Vector`s or Dimension
or dimension type. Abstract supertypes like [`TimeDim`](@ref)
can be used in `order`.

`f` is `<:` by default, but can be `>:` to sort abstract types by concrete types.
"""
@inline sortdims(args...) = _call(_sortdims, MaybeFirst(), args...)

@inline _sortdims(f, tosort, order::Tuple{<:Integer,Vararg}) = map(p -> tosort[p], order)
@inline _sortdims(f, tosort, order) = _sortdims_gen(f, tosort, order)

@generated _sortdims_gen(f, tosort::Tuple, order::Tuple) = begin
    expr = Expr(:tuple)
    allreadyfound = Int[]
    for (i, ord) in enumerate(order.parameters)
        # Make sure we don't find the same dim twice
        found = 0
        while true
            found = findnext((tosort.parameters...,), found + 1) do s
                dimsmatch(_asfunc(f), s, ord)
            end
            if found == nothing
                push!(expr.args, :(nothing))
                break
            elseif !(found in allreadyfound)
                push!(expr.args, :(tosort[$found]))
                push!(allreadyfound, found)
                break
            end
        end
    end
    expr
end

"""
    dims(x, lookup)
    dims(x, lookups...)

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
@inline dims(args...) = _call(_dims, MaybeFirst(), args...)

@inline _dims(f, dims, lookup) = _remove_nothing(_sortdims(f, dims, lookup))

"""
    commondims([f], x, lookup) => Tuple{Vararg{<:Dimension}}

This is basically `dims(x, lookup)` where the order of the original is kept,
unlike [`dims`](@ref) where the lookup tuple determines the order

Also unlike `dims`,`commondims` always returns a `Tuple`, no matter the input.
No errors are thrown if dims are absent from either `x` or `lookup`.

`f` is `<:` by default, but can be `>:` to sort abstract types by concrete types.

```jldoctest
julia> using DimensionalData

julia> A = DimArray(ones(10, 10, 10), (X, Y, Z));

julia> commondims(A, X)
(X (NoIndex),)

julia> commondims(A, (X, Z))
(X (NoIndex), Z (NoIndex))

julia> commondims(A, Ti)
()
```
"""
@inline commondims(args...) = _call(_commondims, AlwaysTuple(), args...)

_commondims(f, ds, lookup) = _dims(f, ds, _dims(_flip_subtype(f), lookup, ds)) 

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
@inline function dimnum(args...) 
    all(hasdim(args...)) || _errorextradims()
    _call(_dimnum, MaybeFirst(), args...)
end

@inline function _dimnum(f::Function, ds::Tuple, lookups::Tuple{Vararg{Int}})
    lookups
end
@inline function _dimnum(f::Function, ds::Tuple, lookups::Tuple)
    numbered = map(ds, ntuple(identity, length(ds))) do d, i
        basetypeof(d)(i)
    end
    map(val, _dims(f, numbered, lookups))
end

"""
    hasdim([f], x, lookup::Tuple) => NTUple{Bool}
    hasdim([f], x, lookups...) => NTUple{Bool}
    hasdim([f], x, lookup) => Bool

## Arguments
- `x`: any object with a `dims` method, a `Tuple` of `Dimension` or a single `Dimension`.
- `lookup`: Tuple or single `Dimension` or dimension `Type`.
- `f`: `<:` by default, but can be `>:` to match abstract types to concrete types.

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
@inline hasdim(args...) = _call(_hasdim, MaybeFirst(), args...)

@inline _hasdim(f, dims, lookup) =
    map(d -> !(d isa Nothing), _sortdims(f, _commondims(f, dims, lookup), lookup))
@inline _hasdim(f, dims, lookup::Tuple{Vararg{Int}}) = 
    map(l -> l in 1:length(dims), lookup)

"""
    otherdims(x, lookup) => Tuple{Vararg{<:Dimension,N}}

## Arguments
- `x`: any object with a `dims` method, a `Tuple` of `Dimension`.
- `lookup`: Tuple or single `Dimension` or dimension `Type`.
- `f`: `<:` by default, but can be `>:` to match abstract types to concrete types.

A tuple holding the unmatched dimensions is always returned.

## Example
```jldoctest
julia> using DimensionalData

julia> A = DimArray(ones(10, 10, 10), (X, Y, Z));

julia> otherdims(A, X)
(Y (NoIndex), Z (NoIndex))

julia> otherdims(A, (Y, Z))
(X (NoIndex),)

julia> otherdims(A, Ti)
(X (NoIndex), Y (NoIndex), Z (NoIndex))
```
"""
@inline otherdims(args...) = _call(_otherdims_presort, AlwaysTuple(), args...)

@inline _otherdims_presort(f, ds, lookup) = _otherdims(f, ds, _sortdims(f, lookup, ds))
# Work with a sorted lookup where the missing dims are `nothing`
@inline _otherdims(f, ds::Tuple, lookup::Tuple) =
    (_dimifmatching(f, first(ds), first(lookup))..., _otherdims(f, tail(ds), tail(lookup))...)
@inline _otherdims(f, dims::Tuple{}, ::Tuple{}) = ()

@inline _dimifmatching(f, dim, lookup) = dimsmatch(f, dim, lookup) ? () : (dim,)

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
@inline setdims(x, d1, d2, ds...) = setdims(x, (d1, d2, ds...))
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
@inline swapdims(x, d1, d2, ds...) = swapdims(x, (d1, d2, ds...))
@inline swapdims(x, newdims::Tuple) =
    rebuild(x; dims=formatdims(x, swapdims(dims(x), newdims)))
@inline swapdims(dims::DimTuple, newdims::Tuple) =
    map((d, nd) -> _swapdims(d, nd), dims, newdims)

@inline _swapdims(dim::Dimension, newdim::DimType) =
    basetypeof(newdim)(val(dim), mode(dim), metadata(dim))
@inline _swapdims(dim::Dimension, newdim::Dimension) = newdim
@inline _swapdims(dim::Dimension, newdim::Nothing) = dim

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
@inline slicedims(x, i1, i2, I...) = slicedims(x, (i1, i2, I...))
@inline slicedims(x, I::CartesianIndex) = slicedims(x, Tuple(I))
@inline slicedims(x, I::Tuple) = _slicedims(dims(x), refdims(x), I)
@inline slicedims(dims::Tuple, I::Tuple) = _slicedims(dims, I)
@inline slicedims(dims::Tuple, refdims::Tuple, i1, I...) = slicedims(dims, refdims, (i1, I...))
@inline slicedims(dims::Tuple, refdims::Tuple, I) = _slicedims(dims, refdims, I)
@inline slicedims(dims::Tuple, refdims::Tuple, I::CartesianIndex) = 
    slicedims(dims, refdims, Tuple(I))

@inline _slicedims(dims::Tuple, refdims::Tuple, I::Tuple) = begin
    newdims, newrefdims = _slicedims(dims, I)
    newdims, (refdims..., newrefdims...)
end
@inline _slicedims(dims::Tuple, refdims::Tuple, I::Tuple{}) = dims, refdims
@inline _slicedims(dims::DimTuple, I::Tuple{}) = dims, ()
@inline _slicedims(dims::DimTuple, I::Tuple) = begin
    d = _slicedims(first(dims), first(I))
    ds = _slicedims(tail(dims), tail(I))
    (d[1]..., ds[1]...), (d[2]..., ds[2]...)
end
@inline _slicedims(dims::Tuple{}, I::Tuple) = (), ()
@inline _slicedims(dims::Tuple{}, I::Tuple{}) = (), ()

@inline _slicedims(d::Dimension, i) = _slicedims(mode(d), d, i)
@inline _slicedims(::IndexMode, d::Dimension, i::Colon) = (d,), ()
@inline _slicedims(::IndexMode, d::Dimension, i::Integer) =
    (), (rebuild(d, d[relate(d, i)], _slicemode(mode(d), val(d), i)),)
@inline _slicedims(::NoIndex, d::Dimension, i::Integer) = (), (rebuild(d, i),)
# TODO deal with unordered arrays trashing the index order
@inline _slicedims(::IndexMode, d::Dimension{<:Val{Index}}, i::AbstractArray) where Index =
    (rebuild(d, Val{Index[relate(d, i)]}(), _slicemode(mode(d), val(d), i)),), ()
@inline _slicedims(::IndexMode, d::Dimension{<:AbstractArray}, i::AbstractArray) =
    (rebuild(d, d[relate(d, i)], _slicemode(mode(d), val(d), i)),), ()
@inline _slicedims(::NoIndex, d::Dimension{<:AbstractArray}, i::AbstractArray) =
    (rebuild(d, d[relate(d, i)]),), ()
# Should never happen, just for ambiguity
@inline _slicedims(::NoIndex, d::Dimension{<:Val}, i::AbstractArray) =
    (rebuild(d, d[relate(d, i)]),), ()

@inline relate(d::Dimension, i) = _maybeflip(relation(d), d, i)

@inline _maybeflip(::Union{ForwardRelation,ForwardIndex}, d, i) = i
@inline _maybeflip(::Union{ReverseRelation,ReverseIndex}, d, i::Integer) =
    lastindex(d) - i + 1
@inline _maybeflip(::Union{ReverseRelation,ReverseIndex}, d, i::AbstractArray) =
    reverse(lastindex(d) .- i .+ 1)

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
@inline _reducedims(mode::NoIndex, dim::Dimension) = rebuild(dim, Base.OneTo(1), NoIndex())
# TODO what should this do?
@inline _reducedims(mode::Unaligned, dim::Dimension) = rebuild(dim, [nothing], NoIndex)
# Categories are combined.
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
@inline _reducedims(span::Explicit, ::Intervals, mode::AbstractSampled, dim::Dimension) = begin
    index = _reducedims(locus(mode), dim)
    bnds = val(span)
    mode = rebuild(mode; order=Ordered(), span=Explicit(reshape([bnds[1, 1]; bnds[2, end]], 2, 1)))
    rebuild(dim, index, mode)
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

# Need to specialise for more types
@inline _centerval(index::AbstractArray{<:AbstractFloat}, len) =
    [(index[len ÷ 2] + index[len ÷ 2 + 1]) / 2]
@inline _centerval(index::AbstractArray, len) = [index[len ÷ 2 + 1]]

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
    map(d -> comparedims(first(dims), d), dims) |> first

@inline comparedims(a::DimTuple, ::Nothing) = a
@inline comparedims(::Nothing, b::DimTuple) = b
@inline comparedims(::Nothing, ::Nothing) = nothing

# Cant use `map` here, tuples may not be the same length
@inline comparedims(a::DimTuple, b::DimTuple) =
    (comparedims(first(a), first(b)), comparedims(tail(a), tail(b))...)
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


# Utils
struct MaybeFirst end
struct AlwaysTuple end

# Call the function f with stardardised args
@inline _call(f::Function, t, args...) = _call(f, t, <:, _wraparg(args...)...)
@inline _call(f::Function, t, op::Function, args...) = _call1(f, t, op, _wraparg(args...)...)

@inline _call1(f, t, op::Function, x, l1, l2, ls...) = _call1(f, t, op, x, (l1, l2, ls...))
@inline _call1(f, t, op::Function, x, lookup) = _call1(f, t, op, dims(x), lookup)
@inline _call1(f, t, op::Function, x::Nothing, lookup) = _dimsnotdefinederror()
@inline _call1(f, t, op::Function, d::Tuple, lookup) = _call1(f, t, op, d, dims(lookup))
@inline _call1(f, t::AlwaysTuple, op::Function, d::Tuple, lookup::Union{Dimension,DimType,Val,Integer}) =
    _call1(f, t, op, d, (lookup,))
@inline _call1(f, t::MaybeFirst, op::Function, d::Tuple, lookup::Union{Dimension,DimType,Val,Integer}) =
    _call1(f, t, op, d, (lookup,))[1]
@inline _call1(f, t, op::Function, d::Tuple, lookup::Tuple) = map(unwrap, f(op, d, lookup))

@inline _kwdims(kw::Base.Iterators.Pairs) = _kwdims(kw.data)
@inline _kwdims(kw::NamedTuple{Keys}) where Keys = _kwdims(key2dim(Keys), values(kw))
@inline _kwdims(dims::Tuple, vals::Tuple) =
    (rebuild(first(dims), first(vals)), _kwdims(tail(dims), tail(vals))...)
@inline _kwdims(dims::Tuple{}, vals::Tuple{}) = ()

@inline _pairdims(pairs::Pair...) = map(p -> basetypeof(key2dim(first(p)))(last(p)), pairs)

@inline _remove_nothing(xs::Tuple) = _remove_nothing(xs...)
@inline _remove_nothing(x, xs...) = (x, _remove_nothing(xs...)...)
@inline _remove_nothing(::Nothing, xs...) = _remove_nothing(xs...)
@inline _remove_nothing() = ()

# This looks ridiculous, but gives seven arguments with constant-propagation, 
# which means type stability using Symbols/types instead of objects. 
@inline _wraparg(d1, d2, d3, d4, d5, d6, d7, ds...) = 
    (_w(d1), _w(d2), _w(d3), _w(d4), _w(d5), _w(d6), _w(d7), _wraparg(ds...)...) 
@inline _wraparg(d1, d2, d3, d4, d5, d6) = _w(d1), _w(d2), _w(d3), _w(d4), _w(d5), _w(d6) 
@inline _wraparg(d1, d2, d3, d4, d5) = _w(d1), _w(d2), _w(d3), _w(d4), _w(d5)
@inline _wraparg(d1, d2, d3, d4) = _w(d1), _w(d2), _w(d3), _w(d4)
@inline _wraparg(d1, d2, d3) = _w(d1), _w(d2), _w(d3)
@inline _wraparg(d1, d2) = _w(d1), _w(d2)
@inline _wraparg(d1) = (_w(d1),)
@inline _wraparg() = ()

@inline _w(t::Tuple) = _wraparg(t...)
@inline _w(x) = x
@inline _w(s::Symbol) = key2dim(s)
@inline _w(x::Type{T}) where T = Val{T}()

@inline _asfunc(::Type{typeof(<:)}) = <:
@inline _asfunc(::Type{typeof(>:)}) = >:

@inline _flip_subtype(::typeof(<:)) = >:
@inline _flip_subtype(::typeof(>:)) = <:


# Error methods. @noinline to avoid allocations.

@noinline _dimsnotdefinederror() = throw(ArgumentError("Object does not define a `dims` method"))
@noinline _dimsmismatcherror(a, b) = throw(DimensionMismatch("$(basetypeof(a)) and $(basetypeof(b)) dims on the same axis"))
@noinline _warnextradims(extradims) = @warn "$(map(basetypeof, extradims)) dims were not found in object"
@noinline _errorextradims() = throw(ArgumentError("Some dims were not found in object"))
