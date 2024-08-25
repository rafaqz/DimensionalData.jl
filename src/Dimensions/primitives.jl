# These functions do most of the work in the package.
# They are all type-stable recursive methods for performance and extensibility.

"""
    dimsmatch([f], dim, query) => Bool
    dimsmatch([f], dims::Tuple, query::Tuple) => Bool

Compare 2 dimensions or `Tuple` of `Dimension` are of the same base type,
or are at least rotations/transformations of the same type.

`f` is `<:` by default, but can be `>:` to match abstract types to concrete types.
"""
function dimsmatch end
@inline dimsmatch(dims, query)::Bool = dimsmatch(<:, dims, query)
@inline function dimsmatch(f::Function, dims::Tuple, query::Tuple)::Bool
    length(dims) == length(query) || return false
    all(map((d, l) -> dimsmatch(f, d, l), dims, query))
end
@inline dimsmatch(f::Function, dim, query)::Bool = dimsmatch(f, typeof(dim), typeof(query))
@inline dimsmatch(f::Function, dim::Type, query)::Bool = dimsmatch(f, dim, typeof(query))
@inline dimsmatch(f::Function, dim, query::Type)::Bool = dimsmatch(f, typeof(dim), query)
@inline dimsmatch(f::Function, dim::Nothing, query::Type)::Bool = false
@inline dimsmatch(f::Function, dim::Type, ::Nothing)::Bool = false
@inline dimsmatch(f::Function, dim, query::Nothing)::Bool = false
@inline dimsmatch(f::Function, dim::Nothing, query)::Bool = false
@inline dimsmatch(f::Function, dim::Nothing, query::Nothing) = false
@inline dimsmatch(f::Function, dim::Type{Val{D}}, match::Type{Val{M}}) where {D,M} =
    dimsmatch(f, D, M)
@inline dimsmatch(f::Function, dim::Type{D}, match::Type{Val{M}}) where {D,M} =
    dimsmatch(f, D, M)
@inline dimsmatch(f::Function, dim::Type{Val{D}}, match::Type{M}) where {D,M} =
    dimsmatch(f, D, M)
@inline function dimsmatch(f::Function, dim::Type{D}, match::Type{M})::Bool where {D,M}
    # Match based on type and inheritance
    f(basetypeof(unwrap(D)), basetypeof(unwrap(M))) ||
    # Or match based on name so that Dim{:X} matches X
    isconcretetype(D) && isconcretetype(M) && name(D) === name(M)
end

"""
    name2dim(s::Symbol) => Dimension
    name2dim(dims...) => Tuple{Dimension,Vararg}
    name2dim(dims::Tuple) => Tuple{Dimension,Vararg}

Convert a symbol to a dimension object. `:X`, `:Y`, `:Ti` etc will be converted
to `X()`, `Y()`, `Ti()`, as with any other dims generated with the [`@dim`](@ref) macro.

All other `Symbol`s `S` will generate `Dim{S}()` dimensions.
"""
function name2dim end
@inline name2dim(t::Tuple) = map(name2dim, t)
@inline name2dim(s::Symbol) = name2dim(Val{s}())
# Allow other things to pass through
@inline name2dim(d::Val{<:Dimension}) = d
@inline name2dim(d) = d

# name2dim is defined for concrete instances in dimensions.jl

@deprecate key2dim name2dim
@deprecate dim2key name

"""
    sortdims([f], tosort, order) => Tuple

Sort dimensions `tosort` by `order`. Dimensions in `order` but
missing from `tosort` are replaced with `nothing`.

`tosort` and `order` can be `Tuple`s or `Vector`s or Dimension
or dimension type. Abstract supertypes like [`TimeDim`](@ref)
can be used in `order`.

`f` is `<:` by default, but can be `>:` to sort abstract types by concrete types.
"""
function sortdims end
@inline sortdims(a1, a2) = _dim_query(_sortdims, MaybeFirst(), a1, a2)
@inline sortdims(f::Function, a1, a2) = _dim_query(_sortdims, f, MaybeFirst(), a1, a2)

# Defined before the @generated function for world age
_asfunc(::Type{typeof(<:)}) = <:
_asfunc(::Type{typeof(>:)}) = >:

@inline function _sortdims(f, tosort, order::Tuple{<:Integer,Vararg})
    map(order) do i
        if i in 1:length(tosort)
            tosort[i]
        else
            nothing
        end
    end
end
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
    return expr
end

"""
    dims(x, query) => Tuple{Vararg{Dimension}}
    dims(x, query...) => Tuple{Vararg{Dimension}}

Get the dimension(s) matching the type(s) of the query dimension.

Lookup can be an Int or an Dimension, or a tuple containing
any combination of either.

## Arguments
- `x`: any object with a `dims` method, or a `Tuple` of `Dimension`.
- `query`: Tuple or a single `Dimension` or `Dimension` `Type`.

## Example
```jldoctest
julia> using DimensionalData

julia> A = DimArray(ones(2, 3, 2), (X, Y, Z))
╭───────────────────────────╮
│ 2×3×2 DimArray{Float64,3} │
├───────────────────── dims ┤
  ↓ X, → Y, ↗ Z
└───────────────────────────┘
[:, :, 1]
 1.0  1.0  1.0
 1.0  1.0  1.0

julia> dims(A, (X, Y))
(↓ X, → Y)

```
"""
function dims end
@inline dims(a1, args...) = _dim_query(_dims, MaybeFirst(), a1, args...)
@inline dims(::Tuple{}, ::Tuple{}) = ()

@inline _dims(f, dims, query) = _remove_nothing(_sortdims(f, dims, query))
@inline _dims(f, dims, query...) = _remove_nothing(_sortdims(f, dims, query))

"""
    commondims([f], x, query) => Tuple{Vararg{Dimension}}

This is basically `dims(x, query)` where the order of the original is kept,
unlike [`dims`](@ref) where the query tuple determines the order

Also unlike `dims`,`commondims` always returns a `Tuple`, no matter the input.
No errors are thrown if dims are absent from either `x` or `query`.

`f` is `<:` by default, but can be `>:` to sort abstract types by concrete types.

```jldoctest
julia> using DimensionalData, .Dimensions

julia> A = DimArray(ones(10, 10, 10), (X, Y, Z));

julia> commondims(A, X)
(↓ X)

julia> commondims(A, (X, Z))
(↓ X, → Z)

julia> commondims(A, Ti)
()

```
"""
function commondims end
@inline commondims(a1, args...) = _dim_query(_commondims, AlwaysTuple(), a1, args...)

_commondims(f, ds, query) = _dims(f, ds, _dims(_flip_subtype(f), query, ds))

"""
    dimnum(x, query::Tuple) => NTuple{Int}
    dimnum(x, query) => Int

Get the number(s) of `Dimension`(s) as ordered in the dimensions of an object.

## Arguments
- `x`: any object with a `dims` method, a `Tuple` of `Dimension` or a single `Dimension`.
- `query`: Tuple, Array or single `Dimension` or dimension `Type`.

The return type will be a Tuple of `Int` or a single `Int`,
depending on whether `query` is a `Tuple` or single `Dimension`.

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
function dimnum end
@inline function dimnum(x, q1, query...)
    all(hasdim(x, q1, query...)) || _extradimserror(otherdims(x, (q1, query...)))
    _dim_query(_dimnum, MaybeFirst(), x, q1, query...)
end
@inline dimnum(x, query::Function) =
    _dim_query(_dimnum, MaybeFirst(), x, query)

@inline _dimnum(f::Function, ds::Tuple, query::Tuple{Vararg{Int}}) = query
@inline function _dimnum(f::Function, ds::Tuple, query::Tuple)
    numbered = map(ds, ntuple(identity, length(ds))) do d, i
        rebuild(d, i)
    end
    map(val, _dims(f, numbered, query))
end

"""
    hasdim([f], x, query::Tuple) => NTuple{Bool}
    hasdim([f], x, query...) => NTuple{Bool}
    hasdim([f], x, query) => Bool

Check if an object `x` has dimensions that match or inherit from the `query` dimensions.

## Arguments
- `x`: any object with a `dims` method, a `Tuple` of `Dimension` or a single `Dimension`.
- `query`: Tuple or single `Dimension` or dimension `Type`.
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
function hasdim end
@inline hasdim(x, a1, args...) =
    _dim_query(_hasdim, MaybeFirst(), x, a1, args...)

@inline _hasdim(f, dims, query) =
    map(d -> !(d isa Nothing), _sortdims(f, _commondims(f, dims, query), query))
@inline _hasdim(f, dims, query::Tuple{Vararg{Int}}) =
    map(l -> l in eachindex(dims), query)

"""
    otherdims(x, query) => Tuple{Vararg{Dimension,N}}

Get the dimensions of an object _not_ in `query`.

## Arguments
- `x`: any object with a `dims` method, a `Tuple` of `Dimension`.
- `query`: Tuple or single `Dimension` or dimension `Type`.
- `f`: `<:` by default, but can be `>:` to match abstract types to concrete types.

A tuple holding the unmatched dimensions is always returned.

## Example
```jldoctest
julia> using DimensionalData, DimensionalData.Dimensions

julia> A = DimArray(ones(10, 10, 10), (X, Y, Z));

julia> otherdims(A, X)
(↓ Y, → Z)

julia> otherdims(A, (Y, Z))
(↓ X)
```
"""
function otherdims end
@inline otherdims(x, query...) =
    _dim_query(_otherdims, AlwaysTuple(), x, query...)

@inline _otherdims(f, ds) = ds
@inline function _otherdims(f, ds, query)
    sorted = sortdims(f, dims(ds, query), ds)
    _otherdims_from_nothing(f, ds, sorted)
end
# Work with a sorted query where the missing dims are `nothing`
@inline _otherdims_from_nothing(f, ds::Tuple, query::Tuple) =
    (_dimifnothing(f, first(ds), first(query))..., _otherdims_from_nothing(f, tail(ds), tail(query))...)
@inline _otherdims_from_nothing(f, ::Tuple{}, ::Tuple{}) = ()

@inline _dimifnothing(f, dim, query) = ()
@inline _dimifnothing(f, dim, query::Nothing) = (dim,)


"""
    setdims(X, newdims) => AbstractArray
    setdims(::Tuple, newdims) => Tuple{Vararg{Dimension,N}}

Replaces the first dim matching `<: basetypeof(newdim)` with newdim,
and returns a new object or tuple with the dimension updated.

## Arguments
- `x`: any object with a `dims` method, a `Tuple` of `Dimension` or a single `Dimension`.
- `newdim`: Tuple or single `Dimension`, `Type` or `Symbol`.

# Example
```jldoctest
using DimensionalData, DimensionalData.Dimensions, DimensionalData.Lookups
A = ones(X(10), Y(10:10:100))
B = setdims(A, Y(Categorical('a':'j'; order=ForwardOrdered())))
lookup(B, Y)
# output
Categorical{Char} ForwardOrdered
wrapping: 'a':1:'j'
```
"""
function setdims end
@inline setdims(x, d1, d2, ds...) = setdims(x, (d1, d2, ds...))
@inline setdims(x) = x
@inline setdims(x, newdims::Dimension) = rebuild(x; dims=setdims(dims(x), name2dim(newdims)))
@inline setdims(x, newdims::Tuple) = rebuild(x; dims=setdims(dims(x), name2dim(newdims)))
@inline setdims(dims::Tuple, newdim::Dimension) = setdims(dims, (newdim,))
@inline setdims(dims::Tuple, newdims::Tuple) = swapdims(dims, sortdims(newdims, dims))
@inline setdims(dims::Tuple, newdims::Tuple{}) = dims

"""
    swapdims(x::T, newdims) => T
    swapdims(dims::Tuple, newdims) => Tuple{Vararg{Dimension}}

Swap dimensions for the passed in dimensions, in the
order passed.

Passing in the `Dimension` types rewraps the dimension index,
keeping the index values and metadata, while constructed `Dimension`
objects replace the original dimension. `nothing` leaves the original
dimension as-is.

## Arguments
- `x`: any object with a `dims` method or a `Tuple` of `Dimension`.
- `newdim`: Tuple of `Dimension` or dimension `Type`.

# Example

```jldoctest
using DimensionalData
A = ones(X(2), Y(4), Z(2))
Dimensions.swapdims(A, (Dim{:a}, Dim{:b}, Dim{:c}))

# output
╭───────────────────────────╮
│ 2×4×2 DimArray{Float64,3} │
├───────────────────── dims ┤
  ↓ a, → b, ↗ c
└───────────────────────────┘
[:, :, 1]
 1.0  1.0  1.0  1.0
 1.0  1.0  1.0  1.0
```
"""
function swapdims end
@inline swapdims(x, d1, d2, ds...) = swapdims(x, (d1, d2, ds...))
@inline swapdims(x) = x
@inline swapdims(x, newdims::Tuple) =
    rebuild(x; dims=format(swapdims(dims(x), newdims), x))
@inline swapdims(dims::DimTuple, newdims::Tuple) =
    map((d, nd) -> _swapdims(d, nd), dims, newdims)

@inline _swapdims(dim::Dimension, newdim::DimType) = basetypeof(newdim)(val(dim))
@inline _swapdims(dim::Dimension, newdim::Dimension) = newdim
@inline _swapdims(dim::Dimension, newdim::Nothing) = dim

"""
    slicedims(x, I) => Tuple{Tuple,Tuple}
    slicedims(f, x, I) => Tuple{Tuple,Tuple}

Slice the dimensions to match the axis values of the new array.

All methods return a tuple containing two tuples: the new dimensions,
and the reference dimensions. The ref dimensions are no longer used in
the new struct but are useful to give context to plots.

Called at the array level the returned tuple will also include the
previous reference dims attached to the array.

# Arguments

- `f`: a function `getindex`,  `view` or `dotview`. This will be used for slicing
    `getindex` is the default if `f` is not included.
- `x`: An `AbstractDimArray`, `Tuple` of `Dimension`, or `Dimension`
- `I`: A tuple of `Integer`, `Colon` or `AbstractArray`
"""
function slicedims end
@propagate_inbounds slicedims(args...) = slicedims(getindex, args...)
@propagate_inbounds slicedims(f::Function, x, i1, i2, I...) = slicedims(f, x, (i1, i2, I...))
@propagate_inbounds slicedims(f::Function, x, I::CartesianIndex) = slicedims(f, x, Tuple(I))
@propagate_inbounds slicedims(f::Function, x, I::Tuple) = _slicedims(f, dims(x), refdims(x), I)
@propagate_inbounds slicedims(f::Function, dims::Tuple, I::Tuple) = _slicedims(f, dims, I)
@propagate_inbounds slicedims(f::Function, dims::Tuple, refdims::Tuple, i1, I...) = slicedims(f, dims, refdims, (i1, I...))
@propagate_inbounds slicedims(f::Function, dims::Tuple, refdims::Tuple, I) = _slicedims(f, dims, refdims, I)
@propagate_inbounds slicedims(f::Function, dims::Tuple, refdims::Tuple, I::CartesianIndex) =
    slicedims(f, dims, refdims, Tuple(I))

@propagate_inbounds function _slicedims(f, dims::Tuple, refdims::Tuple, I::Tuple)
    # Unaligned may need grouped slicing
    newdims, newrefdims = if any(map(d -> lookup(d) isa Unaligned, dims))
        # Separate out unaligned dims
        udims = _unalligned_dims(dims)
        odims = otherdims(dims, udims)
        oI = map(d -> I[dimnum(dims, d)], odims)
        uI = map(d -> I[dimnum(dims, d)], udims)
        d, rd = _slicedims(f, odims, oI)
        udims, urefdims = sliceunalligneddims(f, uI, udims...)
        # Recombine dims and refdims
        Dimensions.dims((d..., udims...), dims), (rd..., urefdims...)
    else
        _slicedims(f, dims, I)
    end
    return newdims, (refdims..., newrefdims...)
end

@propagate_inbounds _slicedims(f, dims::Tuple, refdims::Tuple, I::Tuple{}) = dims, refdims
@propagate_inbounds _slicedims(f, dims::DimTuple, I::Tuple{}) = dims, ()
@propagate_inbounds function _slicedims(f, dims::DimTuple, I::Tuple{<:CartesianIndex})
    return _slicedims(f, dims, Tuple(I[1]))
end
@propagate_inbounds _slicedims(f, dims::DimTuple, I::Tuple) = begin
    d = _slicedims(f, first(dims), first(I))
    ds = _slicedims(f, tail(dims), tail(I))
    (d[1]..., ds[1]...), (d[2]..., ds[2]...)
end
# Return an AnonDim where e.g. a trailing Colon was passed
@propagate_inbounds function _slicedims(f, dims::Tuple{}, I::Tuple{Base.Slice,Vararg})
    d = (AnonDim(_unwrapinds(first(I))),), ()
    ds = _slicedims(f, (), tail(I))
    (d[1]..., ds[1]...), (d[2]..., ds[2]...)
end
# Drop trailing Integers
@propagate_inbounds _slicedims(f, dims::Tuple{}, I::Tuple{Integer,Vararg}) = _slicedims(f, (), tail(I))
@propagate_inbounds _slicedims(f, dims::Tuple{}, I::Tuple{CartesianIndices{0,Tuple{}},Vararg}) = _slicedims(f, (), tail(I))
@propagate_inbounds _slicedims(f, dims::Tuple{}, I::Tuple{}) = (), ()
@propagate_inbounds _slicedims(f, d::Dimension, i::Colon) = (d,), ()
@propagate_inbounds _slicedims(f::F, d::Dimension, i::Integer) where F = (), (f(d, i:i),)
@propagate_inbounds _slicedims(f::F, d::Dimension, i) where F = (f(d, i),), ()

_unwrapinds(s::Base.Slice) = s.indices
_unwrapinds(x) = x # Not sure this can ever be hit? But just in case

_unalligned_dims(dims::Tuple) = _unalligned_dims(dims...)
_unalligned_dims(dim::Dimension{<:Unaligned}, args...) = (dim, _unalligned_dims(args...)...)
_unalligned_dims(dim::Dimension, args...) = _unalligned_dims(args...)
_unalligned_dims() = ()

# Default
function sliceunalligneddims(f, uI, udims...)
    udims, ()
end

"""
    reducedims(x, dimstoreduce) => Tuple{Vararg{Dimension}}

Replace the specified dimensions with an index of length 1.
This is usually to match a new array size where an axis has been
reduced with a method like `mean` or `reduce` to a length of 1,
but the number of dimensions has not changed.

`Lookup` traits are also updated to correspond to the change in
cell step, sampling type and order.
"""
function reducedims end
@inline reducedims(x, dimstoreduce) = _reducedims(x, name2dim(dimstoreduce))

@inline _reducedims(x, dimstoreduce) = _reducedims(x, (dimstoreduce,))
@inline _reducedims(x, dimstoreduce::Tuple) = _reducedims(dims(x), dimstoreduce)
@inline _reducedims(dims::DimTuple, dimstoreduce::Tuple) =
    map(_reducedims, dims, sortdims(dimstoreduce, dims))
# Map numbers to corresponding dims. Not always type-stable
@inline _reducedims(dims::DimTuple, dimstoreduce::Tuple{Vararg{Int}}) =
    map(_reducedims, dims, sortdims(map(i -> dims[i], dimstoreduce), dims))
# Reduce matching dims but ignore nothing vals - they are the dims not being reduced
@inline _reducedims(dim::Dimension, ::Nothing) = dim
@inline _reducedims(dim::Dimension, ::DimOrDimType) = rebuild(dim, reducelookup(lookup(dim)))

const DimTupleOrEmpty = Union{DimTuple,Tuple{}}

"""
    comparedims(A::AbstractDimArray...; kw...)
    comparedims(A::Tuple...; kw...)
    comparedims(A::Dimension...; kw...)
    comparedims(::Type{Bool}, args...; kw...)

Check that dimensions or tuples of dimensions passed as each
argument are the same, and return the first valid dimension.
If `AbstractDimArray`s are passed as arguments their dimensions are compared.

Empty tuples and `nothing` dimension values are ignored,
returning the `Dimension` value if it exists.

Passing `Bool` as the first argument means `true`/`false` will be returned,
rather than throwing an error.

# Keywords

These are all `Bool` flags:

- `type`: compare dimension type, `true` by default.
- `valtype`: compare wrapped value type, `false` by default.
- `val`: compare wrapped values, `false` by default.
- `order`: compare order, `false` by default.
- `length`: compare lengths, `true` by default.
- `ignore_length_one`: ignore length `1` in comparisons, and return whichever
    dimension is not length 1, if any. This is useful in e.g. broadcasting comparisons.
    `false` by default.
- `msg`: DimensionalData.Warn or DimensionalData.Throw. Both may contain string,
    which will be added to error or warning mesages.
"""
function comparedims end
@inline comparedims(args...; kw...)::Bool =
    _comparedims(args...; msg=Throw(), kw...)
@inline comparedims(::Type{Bool}, args...; kw...)::Bool =
    _comparedims(args...; msg=nothing, kw...)

abstract type AbstractMessage{M} end

msg(t::AbstractMessage) = t.msg
msg(::AbstractMessage{Nothing}) = ""

Base.string(m::AbstractMessage) = msg(m)

struct Warn{M<:Union{AbstractString,Nothing}} <: AbstractMessage{M}
    msg::M
end
Warn() = Warn(nothing)

struct Throw{M<:Union{AbstractString,Nothing}} <: AbstractMessage{M}
    msg::M
end
Throw() = Throw(nothing)

_dimsmismatchmsg(a, b) = "$(basetypeof(a)) and $(basetypeof(b)) dims on the same axis."
_valmsg(a, b) = "Lookup values for $(basetypeof(a)) of $(parent(a)) and $(parent(b)) do not match."
_dimsizemsg(a, b) = "Found both lengths $(length(a)) and $(length(b)) for $(basetypeof(a))."
_valtypemsg(a, b) = "Lookup for $(basetypeof(a)) of $(lookup(a)) and $(lookup(b)) do not match."
_ordermsg(a, b) = "Lookups do not all have the same order: $(order(a)), $(order(b))."

@noinline _dimsmismatchaction(err, a, b) = _failed_comparedims(err, _dimsmismatchmsg(a, b))
@noinline _valaction(err, a, b) = _failed_comparedims(err, _valmsg(a, b))
@noinline _dimsizeaction(err, a, b) = _failed_comparedims(err, _dimsizemsg(a, b))
@noinline _valtypeaction(err, a, b) = _failed_comparedims(err, _valtypemsg(a, b))
@noinline _orderaction(err, a, b) = _failed_comparedims(err, _ordermsg(a, b))

_failed_comparedims(w::Warn, msg_intro) = @warn string(msg_intro, msg(w))
_failed_comparedims(t::Throw, msg_intro) = throw(DimensionMismatch(string(msg_intro, msg(t))))

@inline _comparedims(xs...; kw...) = _comparedims(map(dims, xs)...; kw...)
@inline _comparedims(; kw...) = true
@inline _comparedims(dt::DimTupleOrEmpty, (dt1, dts...)::Union{DimTupleOrEmpty,Nothing}...; kw...) =
    all((_comparedims(dt, dt1; kw...), _comparedims(dt, dts...; kw...)...))
@inline _comparedims(dt::DimTupleOrEmpty, ::Nothing) = true
@inline _comparedims(dt::Nothing, (dt1, dts...)::Union{DimTupleOrEmpty,Nothing}...; kw...) =
    _comparedims(dt, dts...; kw...)
@inline _comparedims(::Nothing, ::Nothing...; kw...) = true
@inline _comparedims((a1, as...)::DimTupleOrEmpty, (b1, bs...)::DimTupleOrEmpty; kw...) =
    all((_comparedims(a1, b1; kw...), _comparedims(as, bs; kw...)...))
@inline _comparedims(dt::DimTupleOrEmpty; kw...) = true

@inline _comparedims(d1::Dimension, ds::Union{Dimension,Nothing}...; kw...) =
    all(map(d -> _comparedims(d1, d; kw...), ds))
@inline _comparedims(d1::Nothing, ds::Union{Dimension,Nothing}...; kw...) =
    _comparedims(ds; kw...)
@inline _comparedims()
@inline _comparedims(::Nothing, b::DimTupleOrEmpty; kw...) = true
@inline _comparedims(::Nothing, ::Nothing; kw...) = true
@inline _comparedims(a::DimTuple, b::Tuple{}; kw...) = true
@inline _comparedims(a::Tuple{}, b::DimTuple; kw...) = true
@inline _comparedims(a::Tuple{}, b::Tuple{}; kw...) = true
@inline _comparedims(a::AnonDim, b::AnonDim; kw...) = true
@inline _comparedims(a::Dimension, b::AnonDim; kw...) = true
@inline _comparedims(a::AnonDim, b::Dimension; kw...) = true
@inline function _comparedims(a::Dimension, b::Dimension;
    type=true, valtype=false, val=false, length=true, order=false,
    ignore_length_one=false, msg
)
    if type && basetypeof(a) != basetypeof(b)
        isnothing(msg) || _dimsmismatchaction(msg, a, b)
        return false
    end
    if ignore_length_one && (Base.length(a) == 1 || Base.length(b) == 1)
        return true
    end
    if valtype && typeof(parent(a)) != typeof(parent(b))
        isnothing(msg) || _valtypeaction(msg, a, b)
        return false
    end
    pa, pb = parent(lookup(a)), parent(lookup(b))
    if val && !(isnolookup(a) || isnolookup(b)) && pa != pb
        if eltype(pa) <: Number && eltype(pb) <: Number
            if !all(((a, b),) -> a ≈ b, zip(pa, pb))
                isnothing(msg) || _valaction(msg, a, b)
                return false
            end
        else
            isnothing(msg) || _valaction(msg, a, b)
            return false
        end
    end
    if order && !(isnolookup(a) || isnolookup(b) || Lookups.order(a) == Lookups.order(b))
        isnothing(msg) || _orderaction(msg, a, b)
        return false
    end
    if length && Base.length(a) != Base.length(b)
        isnothing(msg) || _dimsizeaction(msg, a, b)
        return false
    end
    return true
end

@inline promotedims(; kw...) = ()
@inline promotedims(dt1::DimTuple, dts::DimTuple...; kw...)::DimTupleOrEmpty =
    (promotedims(first(dt1), map(first, dts)...; kw...), promotedims(tail(dt1), map(tail, dts)...; kw...)...)
@inline promotedims(dt1::DimTupleOrEmpty, dts::DimTupleOrEmpty...; kw...)::DimTupleOrEmpty =
    promotedims(_remove_empty(dt1, dts...)...; kw...)
@inline promotedims(dt::DimTuple)::DimTupleOrEmpty = dt
@inline promotedims(::Tuple{}; kw...) = ()

@inline promotedims(d1::Dimension; kw...) = d1
@inline function promotedims(d1::Dimension, ds::Dimension...; skip_length_one=false)
    ls = lookup(ds)
    l = promote_first(lookup(d1), ls...)
    promoted_l = if skip_length_one
        _promote_non_length_one(l, l, ls...)
    else
        l
    end

    return rebuild(d1, promoted_l)
end

@inline function _promote_non_length_one(template, l1, ls...)
    if length(l1) > 1
        promote_first(l1, template)
    else
        _promote_non_length_one(template, ls...)
    end
end
@inline _promote_non_length_one(template, l1) = promote_first(l1, template)


"""
    combinedims(xs; check=true, kw...)

Combine the dimensions of each object in `xs`, in the order they are found.

Keywords are passed to [`comparedims`](@ref).
"""
function combinedims end
function combinedims(xs::Vector; kw...)
    if length(xs) > 0
        reduce(xs; init=dims(first(xs))) do ds, A
            _combinedims(ds, dims(A); kw...)
        end
    else
        ()
    end
end
combinedims(; kw...) = ()
combinedims(x1, xs...; kw...) = combinedims(map(dims, (x1, xs...))...; kw...)
combinedims(dt1::DimTupleOrEmpty; kw...) = dt1
combinedims(dt1::DimTupleOrEmpty, dt2::DimTupleOrEmpty, dimtuples::DimTupleOrEmpty...; kw...) =
    reduce((dt2, dimtuples...); init=dt1) do dims1, dims2
        _combinedims(dims1, dims2; kw...)
    end
# Cant use `map` here, tuples may not be the same length
_combinedims(a::DimTupleOrEmpty, b::DimTupleOrEmpty; check=true, kw...) = begin
    if check # Check the matching dims are the same
        common = commondims(a, b)
        comparedims(dims(a, common), dims(b, common); kw...)
    end
    # Take them from a, and add any extras from b
    (a..., otherdims(b, a)...)
end

"""
    basedims(ds::Tuple)
    basedims(d::Union{Dimension,Symbol,Type})

Returns `basetypeof(d)()` or a `Tuple` of called on a `Tuple`.

See [`basetypeof`](@ref)
"""
function basedims end
@inline basedims(x) = basedims(dims(x))
@inline basedims(ds::Tuple) = map(basedims, ds)
@inline basedims(d::Dimension) = basetypeof(d)()
@inline basedims(d::Symbol) = name2dim(d)
@inline basedims(T::Type{<:Dimension}) = basetypeof(T)()

@inline pairs2dims(pairs::Pair...) = map(p -> basetypeof(name2dim(first(p)))(last(p)), pairs)

@inline kw2dims(kw::Base.Iterators.Pairs) = kw2dims(values(kw))
# Convert `Symbol` keyword arguments to a `Tuple` of `Dimension`
@inline kw2dims(kw::NamedTuple{Keys}) where Keys = kw2dims(name2dim(Keys), values(kw))
@inline kw2dims(dims::Tuple, vals::Tuple) =
    (rebuild(first(dims), first(vals)), kw2dims(tail(dims), tail(vals))...)
@inline kw2dims(::Tuple{}, ::Tuple{}) = ()


# Queries

# Most primitives use these for argument handling

abstract type QueryMode end
struct MaybeFirst <: QueryMode end
struct AlwaysTuple <: QueryMode end

(::AlwaysTuple)(xs::Tuple) = xs
(::MaybeFirst)(xs::Tuple) = first(xs)
(::MaybeFirst)(::Tuple{}) = nothing

# Call the function f with standardised args
# This looks like HELL, but it removes this complexity
# from every other method and makes sure they all behave the same way.
@inline _dim_query(f::F, t::QueryMode, args...) where F<:Function =
    _dim_query(f, <:, t::QueryMode, args...)
@inline _dim_query(f::F, t::QueryMode, op::O, args...) where {F<:Function,O<:Union{typeof(<:),typeof(>:)}} =
    _dim_query(f, op, t::QueryMode, args...)
@inline _dim_query(f::F, t::QueryMode, op::O, a1, args::Tuple) where {F<:Function,O<:Union{typeof(<:),typeof(>:)}} =
    _dim_query(f, op, t::QueryMode, a1, args...)
@inline _dim_query(f::F, op::O, t::QueryMode, a1, args...) where {F<:Function,O<:Union{typeof(<:),typeof(>:)}} =
    _dim_query1(f, op, t, _wraparg(a1, args...)...)
@inline _dim_query(f::F, op::O, t::QueryMode, a1, args::Tuple) where {F<:Function,O<:Union{typeof(<:),typeof(>:)}}  =
    _dim_query1(f, op, t::QueryMode, _wraparg(a1)..., _wraparg(args...))

@inline _dim_query1(f::F, op::O, t, x, l1, l2, ls...) where {F,O} =
    _dim_query1(f, op, t, x, (l1, l2, ls...))
@inline _dim_query1(f::F, op::O, t, x) where {F,O} =
    _dim_query1(f, op, t, dims(x))
@inline _dim_query1(f::F, op::O, t, x, query::Q) where {F,O,Q} =
    _dim_query1(f, op, t, dims(x), query)
@inline _dim_query1(f::F, op::O, t, x::Nothing) where {F,O} =
    _dimsnotdefinederror()
@inline _dim_query1(f::F, op::O, t, x::Nothing, query::Q) where {F,O,Q} =
    _dimsnotdefinederror()
@inline _dim_query1(f::F, op::O, t, ds::Tuple, query::Colon) where {F,O} =
    _dim_query1(f, op, t, ds, basedims(ds))
@inline function _dim_query1(f::F, op::O, t, ds::Tuple, query::Q) where {F,O,Q<:Function}
    selection = foldl(ds; init=()) do acc, d
        query(d) ? (acc..., d) : acc
    end
    _dim_query1(f, op, t, ds, selection)
end
@inline function _dim_query1(f::F, op::O, t, d::Tuple, query::Q) where {F,O,Q}
    ds = dims(query)
    isnothing(ds) && _dims_are_not_dims()
    _dim_query1(f, op, t, d, ds)
end
@inline _dim_query1(f::F, op::O, t::QueryMode, d::Tuple, query::Union{Dimension,DimType,Val,Integer}) where {F,O} =
    _dim_query1(f, op, t, d, (query,)) |> t
@inline _dim_query1(f::F, op::O, ::QueryMode, d::Tuple, query::Tuple) where {F,O} = map(unwrap, f(op, d, query))
@inline _dim_query1(f::F, op::O, ::QueryMode, d::Tuple) where {F,O} = map(unwrap, f(op, d))


# Utils

# Remove empty tuples
@inline _remove_empty(::Tuple{}, xs...) = _remove_empty(xs...)
@inline _remove_empty(x::Tuple, xs...) = (x, _remove_empty(xs...)...)
@inline _remove_empty(::Tuple{}) = ()
@inline _remove_empty(x::Tuple) = (x,)

# Remove `nothing` from a `Tuple`
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
@inline _w(s::Symbol) = name2dim(s)
@inline _w(::Type{T}) where T = Val{T}()

@inline _flip_subtype(::typeof(<:)) = >:
@inline _flip_subtype(::typeof(>:)) = <:

_astuple(t::Tuple) = t
_astuple(x) = (x,)


# Warnings and Error methods.

_extradimsmsg(::Tuple{}) = "Some dims were not found in object."
_extradimsmsg(extradims) = "$(map(basetypeof, extradims)) dims were not found in object."
_metadatamsg(a, b) = "Metadata $(metadata(a)) and $(metadata(b)) do not match."
_typemsg(a, b) = "Lookups do not all have the same type: $(order(a)), $(order(b))."

# Warn
@noinline _extradimswarn(dims, msg="") = @warn string(_extradimsmsg(dims), msg)

# Error
@noinline _metadataerror(a, b) = throw(DimensionMismatch(_metadatamsg(a, b)))
@noinline _extradimserror(args) = throw(ArgumentError(_extradimsmsg(args)))
@noinline _dimsnotdefinederror() = throw(ArgumentError("Object does not define a `dims` method"))

@noinline _dims_are_not_dims() = throw(ArgumentError("`dims` are not `Dimension`s"))
