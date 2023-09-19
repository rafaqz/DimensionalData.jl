# These functions do most of the work in the package.
# They are all type-stable recusive methods for performance and extensibility.

"""
    dimsmatch([f], dim, query) => Bool
    dimsmatch([f], dims::Tuple, query::Tuple) => Bool

Compare 2 dimensions or `Tuple` of `Dimension` are of the same base type,
or are at least rotations/transformations of the same type.

`f` is `<:` by default, but can be `>:` to match abstract types to concrete types.
"""
@inline dimsmatch(dims, query) = dimsmatch(<:, dims, query)
@inline function dimsmatch(f::Function, dims::Tuple, query::Tuple)
    length(dims) == length(query) || return false
    all(map((d, l) -> dimsmatch(f, d, l), dims, query))
end
@inline dimsmatch(f::Function, dim, query) = dimsmatch(f, typeof(dim), typeof(query))
@inline dimsmatch(f::Function, dim::Type, query) = dimsmatch(f, dim, typeof(query))
@inline dimsmatch(f::Function, dim, query::Type) = dimsmatch(f, typeof(dim), query)
@inline dimsmatch(f::Function, dim::Nothing, query::Type) = false
@inline dimsmatch(f::Function, dim::Type, ::Nothing) = false
@inline dimsmatch(f::Function, dim, query::Nothing) = false
@inline dimsmatch(f::Function, dim::Nothing, query) = false
@inline dimsmatch(f::Function, dim::Nothing, query::Nothing) = false
@inline function dimsmatch(f::Function, dim::Type{D}, match::Type{M}) where {D,M}
    # Compare regular dimension types
    f(basetypeof(unwrap(D)), basetypeof(unwrap(M))) ||
    # Compare the transformed dimensions, if they exist
    f(basetypeof(unwrap(D)), basetypeof(transformdim(lookuptype(unwrap(M))))) ||
    f(basetypeof(transformdim(lookuptype(unwrap(D)))), basetypeof(unwrap(M)))
end

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

# key2dim is defined for concrete instances in dimensions.jl

"""
    dim2key(dim::Dimension) => Symbol
    dim2key(dims::Type{<:Dimension}) => Symbol
    dim2key(dims::Tuple) => Tuple{Symbol,Vararg}

Convert a dimension object to a simbol. `X()`, `Y()`, `Ti()` etc will be converted.
to `:X`, `:Y`, `:Ti`, as with any other dims generated with the [`@dim`](@ref) macro.

All other `Dim{S}()` dimensions will generate `Symbol`s `S`.
"""
@inline dim2key(dims::Tuple) = map(dim2key, dims)
@inline dim2key(dim::Dimension) = dim2key(typeof(dim))
@inline dim2key(dim::Val{D}) where D <: Dimension = dim2key(D)
@inline dim2key(dt::Type{<:Dimension}) = Symbol(Base.nameof(dt))

# dim2key is defined for concrete instances in dimensions.jl

@inline _asfunc(::Type{typeof(<:)}) = <:
@inline _asfunc(::Type{typeof(>:)}) = >:

"""
    sortdims([f], tosort, order) => Tuple

Sort dimensions `tosort` by `order`. Dimensions
in `order` but missing from `tosort` are replaced with `nothing`.

`tosort` and `order` can be `Tuple`s or `Vector`s or Dimension
or dimension type. Abstract supertypes like [`TimeDim`](@ref)
can be used in `order`.

`f` is `<:` by default, but can be `>:` to sort abstract types by concrete types.
"""
@inline sortdims(a1, a2) = _call_primitive(_sortdims, MaybeFirst(), a1, a2)
@inline sortdims(f::Function, a1, a2) = _call_primitive(_sortdims, MaybeFirst(), f, a1, a2)

@inline _sortdims(f, tosort, order::Tuple{<:Integer,Vararg}) =map(p -> tosort[p], order)
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

LookupArray can be an Int or an Dimension, or a tuple containing
any combination of either.

## Arguments
- `x`: any object with a `dims` method, or a `Tuple` of `Dimension`.
- `query`: Tuple or a single `Dimension` or `Dimension` `Type`.

## Example
```jldoctest
julia> using DimensionalData

julia> A = DimArray(ones(2, 3, 2), (X, Y, Z))
2×3×2 DimArray{Float64,3} with dimensions: X, Y, Z
[:, :, 1]
 1.0  1.0  1.0
 1.0  1.0  1.0
[and 1 more slices...]

julia> dims(A, (X, Y))
X, Y

```
"""
@inline dims(a1, args...) = _call_primitive(_dims, MaybeFirst(), a1, args...)

@inline _dims(f, dims, query) = _remove_nothing(_sortdims(f, dims, query))

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
X

julia> commondims(A, (X, Z))
X, Z

julia> commondims(A, Ti)
()

```
"""
@inline commondims(a1, args...) = _call_primitive(_commondims, AlwaysTuple(), a1, args...)

_commondims(f, ds, query) = _dims(f, ds, _dims(_flip_subtype(f), query, ds))

"""
    dimnum(x, query::Tuple) => NTuple{Int}
    dimnum(x, query) => Int

Get the number(s) of `Dimension`(s) as ordered in the dimensions of an object.

## Arguments
- `x`: any object with a `dims` method, a `Tuple` of `Dimension` or a single `Dimension`.
- `query`: Tuple, Array or single `Dimension` or dimension `Type`.

The return type will be a Tuple of `Int` or a single `Int`,
depending on wether `query` is a `Tuple` or single `Dimension`.

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
@inline function dimnum(x, q1, query...)
    all(hasdim(x, q1, query...)) || _extradimserror()
    _call_primitive(_dimnum, MaybeFirst(), x, q1, query...)
end

@inline function _dimnum(f::Function, ds::Tuple, query::Tuple{Vararg{Int}})
    query
end
@inline function _dimnum(f::Function, ds::Tuple, query::Tuple)
    numbered = map(ds, ntuple(identity, length(ds))) do d, i
        rebuild(d, i)
    end
    map(val, _dims(f, numbered, query))
end

"""
    hasdim([f], x, query::Tuple) => NTUple{Bool}
    hasdim([f], x, query...) => NTUple{Bool}
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
@inline hasdim(x, a1, args...) =
    _call_primitive(_hasdim, MaybeFirst(), x, a1, args...)

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
Y, Z

julia> otherdims(A, (Y, Z))
X
```
"""
@inline otherdims(x, query) =
    _call_primitive(_otherdims_presort, AlwaysTuple(), x, query)
@inline otherdims(x) = ()

@inline _otherdims_presort(f, ds, query) = _otherdims(f, ds, _sortdims(_rev_op(f), query, ds))
# Work with a sorted query where the missing dims are `nothing`
@inline _otherdims(f, ds::Tuple, query::Tuple) =
    (_dimifmatching(f, first(ds), first(query))..., _otherdims(f, tail(ds), tail(query))...)
@inline _otherdims(f, dims::Tuple{}, ::Tuple{}) = ()

@inline _dimifmatching(f, dim, query) = dimsmatch(f, dim, query) ? () : (dim,)

_rev_op(::typeof(<:)) = >:
_rev_op(::typeof(>:)) = <:

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
using DimensionalData, DimensionalData.Dimensions, DimensionalData.LookupArrays
A = ones(X(10), Y(10:10:100))
B = setdims(A, Y(Categorical('a':'j'; order=ForwardOrdered())))
lookup(B, Y)
# output
Categorical{Char} ForwardOrdered
wrapping: 'a':1:'j'
```
"""
@inline setdims(x, d1, d2, ds...) = setdims(x, (d1, d2, ds...))
@inline setdims(x) = x
@inline setdims(x, newdims::Dimension) = rebuild(x; dims=setdims(dims(x), key2dim(newdims)))
@inline setdims(x, newdims::Tuple) = rebuild(x; dims=setdims(dims(x), key2dim(newdims)))
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
objectes replace the original dimension. `nothing` leaves the original
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
2×4×2 DimArray{Float64,3} with dimensions: Dim{:a}, Dim{:b}, Dim{:c}
[:, :, 1]
 1.0  1.0  1.0  1.0
 1.0  1.0  1.0  1.0
[and 1 more slices...]
```
"""
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

All methods return a tuple conatining two tuples: the new dimensions,
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
@inline slicedims(args...) = slicedims(getindex, args...)
@inline slicedims(f::Function, x, i1, i2, I...) = slicedims(f, x, (i1, i2, I...))
@inline slicedims(f::Function, x, I::CartesianIndex) = slicedims(f, x, Tuple(I))
@inline slicedims(f::Function, x, I::Tuple) = _slicedims(f, dims(x), refdims(x), I)
@inline slicedims(f::Function, dims::Tuple, I::Tuple) = _slicedims(f, dims, I)
@inline slicedims(f::Function, dims::Tuple, refdims::Tuple, i1, I...) = slicedims(f, dims, refdims, (i1, I...))
@inline slicedims(f::Function, dims::Tuple, refdims::Tuple, I) = _slicedims(f, dims, refdims, I)
@inline slicedims(f::Function, dims::Tuple, refdims::Tuple, I::CartesianIndex) =
    slicedims(f, dims, refdims, Tuple(I))

@inline function _slicedims(f, dims::Tuple, refdims::Tuple, I::Tuple)
    # Unnaligned may need grouped slicing
    newdims, newrefdims = if any(map(d -> lookup(d) isa Unaligned, dims))
        # Separate out unalligned dims
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

@inline _slicedims(f, dims::Tuple, refdims::Tuple, I::Tuple{}) = dims, refdims
@inline _slicedims(f, dims::DimTuple, I::Tuple{}) = dims, ()
@inline function _slicedims(f, dims::DimTuple, I::Tuple{<:CartesianIndex})
    return _slicedims(f, dims, Tuple(I[1]))
end
@inline _slicedims(f, dims::DimTuple, I::Tuple) = begin
    d = _slicedims(f, first(dims), first(I))
    ds = _slicedims(f, tail(dims), tail(I))
    (d[1]..., ds[1]...), (d[2]..., ds[2]...)
end
@inline _slicedims(f, dims::Tuple{}, I::Tuple) = (), ()
@inline _slicedims(f, dims::Tuple{}, I::Tuple{}) = (), ()
@inline _slicedims(f, d::Dimension, i::Colon) = (d,), ()
@inline _slicedims(f, d::Dimension, i::Integer) = (), (f(d, i:i),)
@inline _slicedims(f, d::Dimension, i) = (f(d, i),), ()

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

`LookupArray` traits are also updated to correspond to the change in
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
@inline _reducedims(dim::Dimension, ::DimOrDimType) = rebuild(dim, reducelookup(lookup(dim)))

const DimTupleOrEmpty = Union{DimTuple,Tuple{}}

struct _Throw end

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
- `warn`: a `String` or `nothing`. Used only for `Bool` methods,
    to give a warning for `false` values and include `warn` in the warning text.
"""
function comparedims end

@inline comparedims(args...; kw...) = _comparedims(_Throw, args...; kw...) 
@inline comparedims(T::Type, args...; kw...) = _comparedims(T, args...; kw...) 

@inline _comparedims(T::Type, ds::Dimension...; kw...) =
    map(d -> _comparedims(T, first(ds), d; kw...), ds)
@inline _comparedims(T::Type, A::Tuple; kw...) = _comparedims(T, map(dims, A)...; kw...)
@inline _comparedims(T::Type, A...; kw...) = _comparedims(T, map(dims, A)...; kw...)
@inline _comparedims(T::Type, dims::Vararg{Tuple{Vararg{Dimension}}}; kw...) =
    map(d -> _comparedims(T, first(dims), d; kw...), dims)

@inline _comparedims(T::Type{_Throw}, a::DimTuple, b::DimTuple; kw...) =
    (_comparedims(T, first(a), first(b); kw...), _comparedims(T, tail(a), tail(b); kw...)...)
@inline _comparedims(::Type{_Throw}, a::DimTupleOrEmpty, ::Nothing; kw...) = a
@inline _comparedims(::Type{_Throw}, ::Nothing, b::DimTupleOrEmpty; kw...) = b
@inline _comparedims(::Type{_Throw}, a::DimTuple, b::Tuple{}; kw...) = a
@inline _comparedims(::Type{_Throw}, a::Tuple{}, b::DimTuple; kw...) = b
@inline _comparedims(::Type{_Throw}, a::Tuple{}, b::Tuple{}; kw...) = ()
@inline _comparedims(::Type{_Throw}, ::Nothing, ::Nothing; kw...) = nothing
@inline _comparedims(::Type{_Throw}, a::AnonDim, b::AnonDim; kw...) = nothing
@inline _comparedims(::Type{_Throw}, a::Dimension, b::AnonDim; kw...) = a
@inline _comparedims(::Type{_Throw}, a::AnonDim, b::Dimension; kw...) = b
@inline function _comparedims(::Type{_Throw}, a::Dimension, b::Dimension;
    type=true, valtype=false, val=false, length=true, order=false, ignore_length_one=false,
)
    type && basetypeof(a) != basetypeof(b) && _dimsmismatcherror(a, b)
    valtype && typeof(parent(a)) != typeof(parent(b)) && _valtypeerror(a, b)
    val && parent(a) != parent(b) && _valerror(a, b)
    order && order(a) != order(b) && _ordererror(a, b)
    if ignore_length_one && (Base.length(a) == 1 || Base.length(b) == 1)
        return Base.length(b) == 1 ? a : b
    end
    length && Base.length(a) != Base.length(b) && _dimsizeerror(a, b)
    return a
end

@inline _comparedims(T::Type{Bool}, ds::Dimension...; kw...) =
    all(map(d -> _comparedims(T, first(ds), d; kw...), ds))
@inline _comparedims(T::Type{Bool}, dims::Vararg{Tuple{Vararg{Dimension}}}; kw...) =
    all(map(d -> _comparedims(T, first(dims), d; kw...), dims))
@inline _comparedims(T::Type{Bool}, a::DimTuple, b::DimTuple; kw...) =
    all((_comparedims(T, first(a), first(b); kw...), _comparedims(T, tail(a), tail(b); kw...)...))
@inline _comparedims(T::Type{Bool}, a::DimTupleOrEmpty, ::Nothing; kw...) = true
@inline _comparedims(T::Type{Bool}, ::Nothing, b::DimTupleOrEmpty; kw...) = true
@inline _comparedims(T::Type{Bool}, ::Nothing, ::Nothing; kw...) = true
@inline _comparedims(T::Type{Bool}, a::DimTuple, b::Tuple{}; kw...) = true
@inline _comparedims(T::Type{Bool}, a::Tuple{}, b::DimTuple; kw...) = true
@inline _comparedims(T::Type{Bool}, a::Tuple{}, b::Tuple{}; kw...) = true
@inline _comparedims(T::Type{Bool}, a::AnonDim, b::AnonDim; kw...) = true
@inline _comparedims(T::Type{Bool}, a::Dimension, b::AnonDim; kw...) = true
@inline _comparedims(T::Type{Bool}, a::AnonDim, b::Dimension; kw...) = true
@inline function _comparedims(::Type{Bool}, a::Dimension, b::Dimension;
    type=true, lookuptype=false, valtype=false, val=false, length=true, order=false, ignore_length_one=false, warn=nothing,
)
    if type && basetypeof(a) != basetypeof(b)
        isnothing(warn) || _dimsmismatchwarn(a, b, warn)
        return false
    end
    if lookuptype && basetypeof(lookup(a)) != basetypeof(lookup(b))
        isnothing(warn) || _typewarn(lookup(a), lookup(b), warn)
        return false
    end
    if valtype && typeof(parent(a)) != typeof(parent(b))
        isnothing(warn) || _valtypewarn(a, b, warn)
        return false
    end
    if val && parent(a) != parent(b)
        isnothing(warn) || _valwarn(a, b, warn)
        return false
    end
    if order && LookupArrays.order(a) != LookupArrays.order(b)
        isnothing(warn) || _orderwarn(a, b, warn)
        return false
    end
    if ignore_length_one && (Base.length(a) == 1 || Base.length(b) == 1) 
        return true
    end
    if length && Base.length(a) != Base.length(b)
        isnothing(warn) || _dimsizewarn(a, b, warn)
        return false
    end
    return true
end

"""
    combinedims(xs; check=true)

Combine the dimensions of each object in `xs`, in the order they are found.
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
    dimstride(x, dim) => Int

Get the stride of the dimension relative to the other dimensions.

This may or may not be equal to the stride of the related array,
although it will be for `Array`.

## Arguments

- `x` is any object with a `dims` method, or a `Tuple` of `Dimension`.
- `dim` is a `Dimension`, `Dimension` type, or and `Int`. Using an `Int` is not type-stable.
"""
@inline dimstride(x, n) = dimstride(dims(x), n)
@inline dimstride(::Nothing, n) = _dimsnotdefinederror()
@inline dimstride(dims::DimTuple, d::DimOrDimType) = dimstride(dims, dimnum(dims, d))
@inline dimstride(dims::DimTuple, n::Int) = prod(map(length, dims)[1:n-1])


@inline basedims(x) = basedims(dims(x))
@inline basedims(ds::Tuple) = map(basedims, ds)
@inline basedims(d::Dimension) = basetypeof(d)()
@inline basedims(d::Symbol) = key2dim(d)
@inline basedims(T::Type{<:Dimension}) = basetypeof(T)()


# Utils
struct MaybeFirst end
struct AlwaysTuple end

# Call the function f with stardardised args
# This looks like HELL, but it removes this complexity
# from every other method and makes sure they all behave the same way.
@inline _call_primitive(f::Function, t, a1, args...) =
    _call_primitive(f, t, <:, _wraparg(a1, args...)...)
@inline _call_primitive(f::Function, t, op::Function, a1, args...) =
    _call_primitive1(f, t, op, _wraparg(a1, args...)...)

@inline _call_primitive1(f, t, op::Function, x, l1, l2, ls...) = _call_primitive1(f, t, op, x, (l1, l2, ls...))
@inline _call_primitive1(f, t, op::Function, x) = _call_primitive1(f, t, op, dims(x))
@inline _call_primitive1(f, t, op::Function, x, query) = _call_primitive1(f, t, op, dims(x), query)
@inline _call_primitive1(f, t, op::Function, x::Nothing) = _dimsnotdefinederror()
@inline _call_primitive1(f, t, op::Function, x::Nothing, query) = _dimsnotdefinederror()
@inline function _call_primitive1(f, t, op::Function, d::Tuple, query)
    ds = dims(query)
    isnothing(ds) && _dims_are_not_dims()
    _call_primitive1(f, t, op, d, ds)
end

_dims_are_not_dims() = throw(ArgumentError("`dims` are not `Dimension`s"))

@inline _call_primitive1(f, t::AlwaysTuple, op::Function, d::Tuple, query::Union{Dimension,DimType,Val,Integer}) =
    _call_primitive1(f, t, op, d, (query,))
@inline _call_primitive1(f, t::MaybeFirst, op::Function, d::Tuple, query::Union{Dimension,DimType,Val,Integer}) =
    _call_primitive1(f, t, op, d, (query,)) |> _maybefirst
@inline _call_primitive1(f, t, op::Function, d::Tuple, query::Tuple) = map(unwrap, f(op, d, query))
@inline _call_primitive1(f, t, op::Function, d::Tuple) = map(unwrap, f(op, d))


_maybefirst(xs::Tuple) = first(xs)
_maybefirst(::Tuple{}) = nothing

@inline kwdims(kw::Base.Iterators.Pairs) = kwdims(values(kw))
# Convert `Symbol` keyword arguments to a `Tuple` of `Dimension`
@inline kwdims(kw::NamedTuple{Keys}) where Keys = kwdims(key2dim(Keys), values(kw))
@inline kwdims(dims::Tuple, vals::Tuple) =
    (rebuild(first(dims), first(vals)), kwdims(tail(dims), tail(vals))...)
@inline kwdims(dims::Tuple{}, vals::Tuple{}) = ()

@inline pairdims(pairs::Pair...) = map(p -> basetypeof(key2dim(first(p)))(last(p)), pairs)

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
@inline _w(s::Symbol) = key2dim(s)
@inline _w(x::Type{T}) where T = Val{T}()

@inline _flip_subtype(::typeof(<:)) = >:
@inline _flip_subtype(::typeof(>:)) = <:

_astuple(t::Tuple) = t
_astuple(x) = (x,)


# Warnings and Error methods. 
_dimsmismatchmsg(a, b) = "$(basetypeof(a)) and $(basetypeof(b)) dims on the same axis."
_valmsg(a, b) = "Lookup values for $(basetypeof(a)) of $(parent(a)) and $(parent(b)) do not match."
_dimsizemsg(a, b) = "Found both lengths $(length(a)) and $(length(b)) for $(basetypeof(a))."
_valtypemsg(a, b) = "Lookup for $(basetypeof(a)) of $(lookup(a)) and $(lookup(b)) do not match."
_extradimsmsg(extradims) = "$(map(basetypeof, extradims)) dims were not found in object."
_extradimsmsg(::Tuple{}) = "Some dims were not found in object."
_metadatamsg(a, b) = "Metadata $(metadata(a)) and $(metadata(b)) do not match."
_dimordermsg(a, b) = "Lookups do not all have the same order: $(order(a)), $(order(b))."

# Warning: @noinline to avoid allocations when it isn't used
@noinline _dimsmismatchwarn(a, b, msg="") = @warn _dimsmismatchmsg(a, b) * msg
@noinline _valwarn(a, b, msg="") = @warn _valmsg(a, b) * msg
@noinline _dimsizewarn(a, b, msg="") = @warn _dimsizemsg(a, b) * msg
@noinline _valtypewarn(a, b, msg="") = @warn _valtypemsg(a, b)  * msg
@noinline _extradimswarn(dims, msg="") = @warn _extradimsmsg(dims) * msg

# Error
@noinline _dimsmismatcherror(a, b) = throw(DimensionMismatch(_dimsmismatchmsg(a, b)))
@noinline _dimordererror(a, b) = throw(DimensionMismatch(_dimsizemsg(a, b)))
@noinline _dimsizeerror(a, b) = throw(DimensionMismatch(_dimsizemsg(a, b)))
@noinline _valtypeerror(a, b) = throw(DimensionMismatch(_valtypemsg(a, b)))
@noinline _valerror(a, b) = throw(DimensionMismatch(_valmsg(a, b)))
@noinline _metadataerror(a, b) = throw(DimensionMismatch(_metadatamsg(a, b)))
@noinline _extradimserror(args...) = throw(ArgumentError(_extradimsmsg(args)))
@noinline _dimsnotdefinederror() = throw(ArgumentError("Object does not define a `dims` method"))
