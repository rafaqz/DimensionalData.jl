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
@inline function dimsmatch(f::Function, dims::Tuple, lookups::Tuple)
    all(map((d, l) -> dimsmatch(f, d, l), dims, lookups))
end
@inline dimsmatch(f::Function, dim, lookup) = dimsmatch(f, typeof(dim), typeof(lookup))
@inline dimsmatch(f::Function, dim::Type, lookup) = dimsmatch(f, dim, typeof(lookup))
@inline dimsmatch(f::Function, dim, lookup::Type) = dimsmatch(f, typeof(dim), lookup)
@inline dimsmatch(f::Function, dim::Nothing, lookup::Type) = false
@inline dimsmatch(f::Function, dim::Type, ::Nothing) = false
@inline dimsmatch(f::Function, dim, lookup::Nothing) = false
@inline dimsmatch(f::Function, dim::Nothing, lookup) = false
@inline dimsmatch(f::Function, dim::Nothing, lookup::Nothing) = false
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

"""
    sortdims([f], tosort, order) => Tuple

Sort dimensions `tosort` by `order`. Dimensions
in `order` but missing from `tosort` are replaced with `nothing`.

`tosort` and `order` can be `Tuple`s or `Vector`s or Dimension
or dimension type. Abstract supertypes like [`TimeDim`](@ref)
can be used in `order`.

`f` is `<:` by default, but can be `>:` to sort abstract types by concrete types.
"""
@inline sortdims(args...) = _call_primitive(_sortdims, MaybeFirst(), args...)

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
    return expr
end

"""
    dims(x, lookup) => Tuple{Vararg{<:Dimension}}
    dims(x, lookup...) => Tuple{Vararg{<:Dimension}}

Get the dimension(s) matching the type(s) of the lookup dimension.

LookupArray can be an Int or an Dimension, or a tuple containing
any combination of either.

## Arguments
- `x`: any object with a `dims` method, or a `Tuple` of `Dimension`.
- `lookup`: Tuple or a single `Dimension` or `Dimension` `Type`.

## Example
```jldoctest
julia> using DimensionalData

julia> A = DimArray(ones(2, 3, 2), (X, Y, Z))
2×3×2 DimArray{Float64,3} with dimensions: X , Y , Z
[:, :, 1]
 1.0  1.0  1.0
 1.0  1.0  1.0
[and 1 more slices...]

julia> dims(A, (X, Y))
X , Y

```
"""
@inline dims(args...) = _call_primitive(_dims, MaybeFirst(), args...)

@inline _dims(f, dims, lookup) = _remove_nothing(_sortdims(f, dims, lookup))

"""
    commondims([f], x, lookup) => Tuple{Vararg{<:Dimension}}

This is basically `dims(x, lookup)` where the order of the original is kept,
unlike [`dims`](@ref) where the lookup tuple determines the order

Also unlike `dims`,`commondims` always returns a `Tuple`, no matter the input.
No errors are thrown if dims are absent from either `x` or `lookup`.

`f` is `<:` by default, but can be `>:` to sort abstract types by concrete types.

```jldoctest
julia> using DimensionalData, .Dimensions

julia> A = DimArray(ones(10, 10, 10), (X, Y, Z));

julia> commondims(A, X)
X

julia> commondims(A, (X, Z))
X , Z

julia> commondims(A, Ti)
()

```
"""
@inline commondims(args...) = _call_primitive(_commondims, AlwaysTuple(), args...)

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
    _call_primitive(_dimnum, MaybeFirst(), args...)
end

@inline function _dimnum(f::Function, ds::Tuple, lookups::Tuple{Vararg{Int}})
    lookups
end
@inline function _dimnum(f::Function, ds::Tuple, lookups::Tuple)
    numbered = map(ds, ntuple(identity, length(ds))) do d, i
        rebuild(d, i)
    end
    map(val, _dims(f, numbered, lookups))
end

"""
    hasdim([f], x, lookup::Tuple) => NTUple{Bool}
    hasdim([f], x, lookups...) => NTUple{Bool}
    hasdim([f], x, lookup) => Bool

Check if an object `x` has dimensions that match or inherit from the `lookup` dimensions.

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
@inline hasdim(args...) = _call_primitive(_hasdim, MaybeFirst(), args...)

@inline _hasdim(f, dims, lookup) =
    map(d -> !(d isa Nothing), _sortdims(f, _commondims(f, dims, lookup), lookup))
@inline _hasdim(f, dims, lookup::Tuple{Vararg{Int}}) =
    map(l -> l in eachindex(dims), lookup)

"""
    otherdims(x, lookup) => Tuple{Vararg{<:Dimension,N}}

Get the dimensions of an object _not_ in `lookup`.

## Arguments
- `x`: any object with a `dims` method, a `Tuple` of `Dimension`.
- `lookup`: Tuple or single `Dimension` or dimension `Type`.
- `f`: `<:` by default, but can be `>:` to match abstract types to concrete types.

A tuple holding the unmatched dimensions is always returned.

## Example
```jldoctest
julia> using DimensionalData, DimensionalData.Dimensions

julia> A = DimArray(ones(10, 10, 10), (X, Y, Z));

julia> otherdims(A, X)
Y , Z

julia> otherdims(A, (Y, Z))
X
```
"""
@inline otherdims(args...) = _call_primitive(_otherdims_presort, AlwaysTuple(), args...)

@inline _otherdims_presort(f, ds, lookup) = _otherdims(f, ds, _sortdims(_rev_op(f), lookup, ds))
# Work with a sorted lookup where the missing dims are `nothing`
@inline _otherdims(f, ds::Tuple, lookup::Tuple) =
    (_dimifmatching(f, first(ds), first(lookup))..., _otherdims(f, tail(ds), tail(lookup))...)
@inline _otherdims(f, dims::Tuple{}, ::Tuple{}) = ()

@inline _dimifmatching(f, dim, lookup) = dimsmatch(f, dim, lookup) ? () : (dim,)

_rev_op(::typeof(<:)) = >:
_rev_op(::typeof(>:)) = <:

"""
    setdims(X, newdims) => AbstractArray
    setdims(::Tuple, newdims) => Tuple{Vararg{<:Dimension,N}}

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
Categorical 'a':1:'j' ForwardOrdered
```
"""
@inline setdims(x, d1, d2, ds...) = setdims(x, (d1, d2, ds...))
@inline setdims(x, newdims::Dimension) = rebuild(x; dims=setdims(dims(x), key2dim(newdims)))
@inline setdims(x, newdims::Tuple) = rebuild(x; dims=setdims(dims(x), key2dim(newdims)))
@inline setdims(dims::Tuple, newdim::Dimension) = setdims(dims, (newdim,))
@inline setdims(dims::Tuple, newdims::Tuple) = swapdims(dims, sortdims(newdims, dims))
@inline setdims(dims::Tuple, newdims::Tuple{}) = dims

"""
    swapdims(x::T, newdims) => T
    swapdims(dims::Tuple, newdims) => Tuple{Vararg{<:Dimension}}

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
2×4×2 DimArray{Float64,3} with dimensions: Dim{:a} , Dim{:b} , Dim{:c}
[:, :, 1]
 1.0  1.0  1.0  1.0
 1.0  1.0  1.0  1.0
[and 1 more slices...]
```
"""
@inline swapdims(x, d1, d2, ds...) = swapdims(x, (d1, d2, ds...))
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
    newdims, newrefdims = if any(d -> lookup(d) isa Unaligned, dims)
        # Separate out unalligned dims
        udims = _unalligned_dims(dims)
        odims = otherdims(dims, udims)
        oI = map(d -> I[dimnum(dims, d)], odims)
        uI = map(d -> I[dimnum(dims, d)], udims)
        d, rd = _slicedims(f, odims, oI)
        udims, urefdims = sliceunalligneddims(f, uI, udims...)
        # Recombine dims and refdims
        sortdims((d..., udims...), dims), (rd..., urefdims...)
    else
        _slicedims(f, dims, I)
    end
    return newdims, (refdims..., newrefdims...)
end
@inline _slicedims(f, dims::Tuple, refdims::Tuple, I::Tuple{}) = dims, refdims
@inline _slicedims(f, dims::DimTuple, I::Tuple{}) = dims, ()
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
    reducedims(x, dimstoreduce) => Tuple{Vararg{<:Dimension}}

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
@inline comparedims(x...; kw...) = comparedims(x; kw...)
@inline comparedims(A::Tuple; kw...) = comparedims(map(dims, A)...; kw...)
@inline comparedims(dims::Vararg{<:Tuple{Vararg{<:Dimension}}}; kw...) =
    map(d -> comparedims(first(dims), d), dims; kw...) |> first

@inline comparedims(a::DimTuple, ::Nothing; kw...) = a
@inline comparedims(::Nothing, b::DimTuple; kw...) = b
@inline comparedims(::Nothing, ::Nothing; kw...) = nothing
# Cant use `map` here, tuples may not be the same length
@inline comparedims(a::DimTuple, b::DimTuple; kw...) =
    (comparedims(first(a), first(b); kw...), comparedims(tail(a), tail(b); kw...)...)
@inline comparedims(a::DimTuple, b::Tuple{}; kw...) = a
@inline comparedims(a::Tuple{}, b::DimTuple; kw...) = b
@inline comparedims(a::Tuple{}, b::Tuple{}; kw...) = ()
@inline comparedims(a::AnonDim, b::AnonDim; kw...) = nothing
@inline comparedims(a::Dimension, b::AnonDim; kw...) = a
@inline comparedims(a::AnonDim, b::Dimension; kw...) = b
@inline function comparedims(a::Dimension, b::Dimension;
    type=true, length=true, lookup=false, val=false, metadata=false
)
    D = Dimensions
    type && basetypeof(a) != basetypeof(b) && _dimsmismatcherror(a, b)
    lookup && typeof(D.lookup(a)) != typeof(D.lookup(b)) && _lookuperror(a, b)
    length && Base.length(a) != Base.length(b) && _dimsizeerror(a, b)
    val && D.val(a) != D.val(b) && _valerror(a, b)
    metadata && D.metadata(a) != D.metadata(b) && _metadataerror(a, b)
    return a
end

const DimTupleOrEmpty = Union{DimTuple,Tuple{}}

"""
    combinedims(xs; check=true)

Combine the dimensions of each object in `xs`, in the order they are found.
"""
function combinedims end
# @inline combinedims(xs::Tuple) = combinedims(xs...)
@inline combinedims(xs...; kw...) = combinedims(map(dims, xs)...; kw...)
@inline combinedims(dt1::DimTupleOrEmpty; kw...) = dt1
@inline combinedims(dt1::DimTupleOrEmpty, dt2::DimTupleOrEmpty, dimtuples::DimTupleOrEmpty...; kw...) =
    reduce((dt2, dimtuples...); init=dt1) do dims1, dims2
        _combinedims(dims1, dims2; kw...)
    end
# Cant use `map` here, tuples may not be the same length
@inline _combinedims(a::DimTupleOrEmpty, b::DimTupleOrEmpty; check=true, kw...) = begin
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
@inline _call_primitive(f::Function, t, args...) = _call_primitive(f, t, <:, _wraparg(args...)...)
@inline _call_primitive(f::Function, t, op::Function, args...) = _call_primitive1(f, t, op, _wraparg(args...)...)

@inline _call_primitive1(f, t, op::Function, x, l1, l2, ls...) = _call_primitive1(f, t, op, x, (l1, l2, ls...))
@inline _call_primitive1(f, t, op::Function, x, lookup) = _call_primitive1(f, t, op, dims(x), lookup)
@inline _call_primitive1(f, t, op::Function, x::Nothing, lookup) = _dimsnotdefinederror()
@inline _call_primitive1(f, t, op::Function, d::Tuple, lookup) = _call_primitive1(f, t, op, d, dims(lookup))
@inline _call_primitive1(f, t::AlwaysTuple, op::Function, d::Tuple, lookup::Union{Dimension,DimType,Val,Integer}) =
    _call_primitive1(f, t, op, d, (lookup,))
@inline _call_primitive1(f, t::MaybeFirst, op::Function, d::Tuple, lookup::Union{Dimension,DimType,Val,Integer}) =
    _call_primitive1(f, t, op, d, (lookup,)) |> _maybefirst
@inline _call_primitive1(f, t, op::Function, d::Tuple, lookup::Tuple) = map(unwrap, f(op, d, lookup))


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

@inline _asfunc(::Type{typeof(<:)}) = <:
@inline _asfunc(::Type{typeof(>:)}) = >:

@inline _flip_subtype(::typeof(<:)) = >:
@inline _flip_subtype(::typeof(>:)) = <:

_astuple(t::Tuple) = t
_astuple(x) = (x,)

# Error methods. @noinline to avoid allocations.

@noinline _dimsnotdefinederror() = throw(ArgumentError("Object does not define a `dims` method"))
@noinline _dimsmismatcherror(a, b) = throw(DimensionMismatch("$(basetypeof(a)) and $(basetypeof(b)) for dims on the same axis"))
@noinline _dimsizeerror(a, b) = throw(DimensionMismatch("Found both lengths $(length(a)) and $(length(b)) for $(basetypeof(a))"))
@noinline _lookuperror(a, b) = throw(DimensionMismatch("Mode $(lookup(a)) and $(lookup(b)) do not match"))
@noinline _metadataerror(a, b) = throw(DimensionMismatch("Metadata $(metadata(a)) and $(madata(b)) do not match"))
@noinline _valerror(a, b) = throw(DimensionMismatch("Dimension index $(val(a)) and $(val(b)) do not match"))
@noinline _warnextradims(extradims) = @warn "$(map(basetypeof, extradims)) dims were not found in object"
@noinline _errorextradims() = throw(ArgumentError("Some dims were not found in object"))
