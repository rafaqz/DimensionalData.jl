
"""
    reverse(A; dims) => AbstractDimArray
    reverse(dim::Dimension) => Dimension

Reverse the array order, and update the dim to match.
"""
Base.reverse(A::AbstractDimArray; dims=1) =
    _reverse(IndexOrder, _reverse(ArrayOrder, A, dims), dims)
Base.reverse(s::AbstractDimStack; dims=1) = map(A -> reverse(A; dims=dims), s)
Base.reverse(ot::Type{<:SubOrder}, x; dims) = _reverse(ot, x, dims)
_reverse(ot::Type{<:SubOrder}, x, lookup) = set(x, reverse(ot, dims(x, lookup)))
_reverse(ot::Type{<:ArrayOrder}, x, lookup) = begin
    newdims = reverse(ArrayOrder, dims(x, lookup))
    newdata = _reversedata(x, dimnum(x, lookup))
    setdims(rebuild(x, newdata), newdims)
end
# Dimension
Base.reverse(ot::Type{<:SubOrder}, dims::DimTuple) = map(d -> reverse(ot, d), dims)
Base.reverse(ot::Type{<:SubOrder}, dim::Dimension) = reverse(ot, mode(dim), dim)
Base.reverse(ot::Type{<:SubOrder}, mode::IndexMode, dim::Dimension) =
    rebuild(dim; mode=reverse(ot, mode))
# Reverse the index
Base.reverse(ot::Type{<:IndexOrder}, mode::IndexMode, dim::Dimension) =
    rebuild(dim, reverse(index(dim)), reverse(ot, mode))
Base.reverse(ot::Type{<:IndexOrder}, mode::IndexMode, dim::Dimension{<:Val{I}}) where I =
    rebuild(dim, Val(reverse(I)), reverse(ot, mode))
Base.reverse(ot::Type{<:IndexOrder}, mode::NoIndex, dim::Dimension) = dim
Base.reverse(dim::Dimension) = reverse(IndexOrder, dim)
# Mode
Base.reverse(ot::Type{<:SubOrder}, mode::NoIndex) = mode
Base.reverse(ot::Type{<:SubOrder}, mode::IndexMode) =
    rebuild(mode; order=reverse(ot, order(mode)))
Base.reverse(ot::Type{<:SubOrder}, mode::AbstractSampled) =
    rebuild(mode; order=reverse(ot, order(mode)), span=reverse(ot, span(mode)))
# Order
Base.reverse(::Type{<:IndexOrder}, o::Ordered) =
    Ordered(reverse(indexorder(o)), arrayorder(o), reverse(relation(o)))
Base.reverse(::Type{<:Union{ArrayOrder,Relation}}, o::Ordered) =
    Ordered(indexorder(o), reverse(arrayorder(o)), reverse(relation(o)))
Base.reverse(::Type{<:SubOrder}, o::Unordered) = Unordered(reverse(relation(o)))
# SubOrder
Base.reverse(::ReverseIndex) = ForwardIndex()
Base.reverse(::ForwardIndex) = ReverseIndex()
Base.reverse(::ReverseArray) = ForwardArray()
Base.reverse(::ForwardArray) = ReverseArray()
Base.reverse(::ReverseRelation) = ForwardRelation()
Base.reverse(::ForwardRelation) = ReverseRelation()
# Span
Base.reverse(::Type{<:SubOrder}, span::Span) = span
Base.reverse(::Type{<:IndexOrder}, span::Irregular) = span
Base.reverse(::Type{<:IndexOrder}, span::Span) = reverse(span)
Base.reverse(span::Regular) = Regular(-step(span))
Base.reverse(span::Explicit) = Explicit(reverse(val(span), dims=2))

_reversedata(A::AbstractDimArray, dimnum) = reverse(parent(A); dims=dimnum)
_reversedata(s::AbstractDimStack, dimnum) =
    map(a -> reverse(parent(a); dims=dimnum), data(s))

"""
    fliparray(Order, A, dims) => AbstractDimArray
    fliparray(dim::Dimension) => Dimension

`Flip` the array order without changing any data.
"""
function flip end

flip(ot::Type{<:SubOrder}, x; dims) = flip(ot, x, dims)
flip(ot::Type{<:SubOrder}, x, lookupdims) = set(x, flip(ot, dims(x, lookupdims)))
flip(ot::Type{<:SubOrder}, dims::DimTuple) = map(d -> flip(ot, d), dims)
flip(ot::Type{<:SubOrder}, dim::Dimension) = _set(dim, flip(ot, mode(dim)))
flip(ot::Type{<:SubOrder}, mode::IndexMode) = _set(mode, flip(ot, order(mode)))
flip(ot::Type{<:SubOrder}, mode::NoIndex) = mode
flip(ot::Type{<:SubOrder}, o::Order) = _set(o, reverse(ot, o))

"""
    reorder(::order, A::AbstractDimArray) => AbstractDimArray
    reorder(A::AbstractDimArray, order::Union{Order,Dimension{<:Order},Tuple}) => AbstractDimArray
    reorder(A::AbstractDimArray, order::Pair{<:Dimension,<:SubOrder}...) => AbstractDimArray

Reorder every dims index/array/relation to `order`, or reorder index for
the the given dimension(s) to the `Order` they wrap.

Reordering `Relation` will reverse the array, not the dimension index.

`order` can be an [`Order`](@ref), a single [`Dimension`](@ref)
or a `Tuple` of `Dimension`.

If no axis reversal is required the same objects will be returned, without allocation.
"""
function reorder end

reorder(x, args...; kw...) = reorder(x, (args..., _kwdims(kw)...))
reorder(x, nt::NamedTuple) = reorder(x, _kwdims(nt))
reorder(x, p::Pair, ps::Vararg{<:Pair}) = reorder(x, (p, ps...))
reorder(x, ps::Tuple{Vararg{<:Pair}}) = reorder(x, _pairdims(ps...))
# Reorder specific dims.
reorder(x, dimwrappers::Tuple) = _reorder(x, dimwrappers)
# Reorder all dims.
reorder(x, ot::Union{SubOrder,Type{<:SubOrder}}) =
    _reorder(x, map(d -> basetypeof(d)(ot), dims(x)))

# Recursive reordering. x may be reversed here
_reorder(x, dims::DimTuple) = _reorder(reorder(x, dims[1]), tail(dims))
_reorder(x, dims::Tuple{}) = x

reorder(x, orderdim::Dimension) = _reorder(val(orderdim), x, dims(x, orderdim))

_reorder(neworder::SubOrder, x, dim::DimOrDimType) = _reorder(basetypeof(neworder), x, dim)
# Reverse the dimension index
_reorder(ot::Type{<:IndexOrder}, x, dim::DimOrDimType) =
    ot == basetypeof(order(ot, dim)) ? x : set(x, reverse(ot, dim))
# If either ArrayOrder or Relation are reversed, we reverse the array
_reorder(ot::Type{<:Union{ArrayOrder,Relation}}, x, dim::DimOrDimType) =
    ot == basetypeof(order(ot, dim)) ? x : reverse(ArrayOrder, x; dims=dim)


"""
    modify(f, A::AbstractDimArray) => AbstractDimArray
    modify(f, s::AbstractDimStack) => AbstractDimStack
    modify(f, dim::Dimension) => Dimension
    modify(f, x, lookupdim::Dimension) => typeof(x)

Modify the parent data, rebuilding the object wrapper without
change. `f` must return a `AbstractArray` of the same size as the original.

This method is mostly useful as a way of swapping the parent array type of
an object.

## Example

If we have a previously-defined `DimArray`, we can copy it to an Nvidia GPU with:

```julia
A = DimArray(rand(100, 100), (X, Y))
modify(CuArray, A)
```

This also works for all the data layers in a `DimStack`.
"""
function modify end
modify(f, s::AbstractDimStack) = map(a -> modify(f, a), s)
function modify(f, A::AbstractDimArray)
    newdata = f(parent(A))
    size(newdata) == size(A) || error("$f returns an array with a different size")
    rebuild(A, newdata)
end
modify(f, x, dim::DimOrDimType) = set(x, modify(f, dims(x, dim)))
function modify(f, dim::Dimension)
    newindex = f(index(dim))
    size(newindex) == size(dim) || error("$f returns a vector with a different size")
    rebuild(dim, newindex)
end
function modify(f, dim::Dimension{<:Val{Index}}) where Index
    newindex = f(Index)
    length(newindex) == length(dim) || error("$f returns a Tuple with a different size")
    rebuild(dim, Val(newindex))
end


"""
    dimwise(f, A::AbstractDimArray{T,N}, B::AbstractDimArray{T2,M}) => AbstractDimArray{T3,N}

Dimension-wise application of function `f` to `A` and `B`.

## Arguments

- `a`: `AbstractDimArray` to broacast from, along dimensions not in `b`.
- `b`: `AbstractDimArray` to broadcast from all dimensions. Dimensions must be a subset of a.

This is like broadcasting over every slice of `A` if it is
sliced by the dimensions of `B`.
"""
function dimwise(f, A::AbstractDimArray, B::AbstractDimArray)
    dimwise!(f, similar(A, promote_type(eltype(A), eltype(B))), A, B)
end

"""
    dimwise!(f, dest::AbstractDimArray{T1,N}, A::AbstractDimArray{T2,N}, B::AbstractDimArray) => dest

Dimension-wise application of function `f`.

## Arguments

- `dest`: `AbstractDimArray` to update
- `A`: `AbstractDimArray` to broacast from, along dimensions not in `b`.
- `B`: `AbstractDimArray` to broadcast from all dimensions. Dimensions must be a subset of a.

This is like broadcasting over every slice of `A` if it is
sliced by the dimensions of `B`, and storing the value in `dest`.
"""
function dimwise!(
    f, dest::AbstractDimArray{T,N}, a::AbstractDimArray{TA,N}, b::AbstractDimArray{TB,NB}
) where {T,TA,TB,N,NB}
    N >= NB || error("B-array cannot have more dimensions than A array")
    comparedims(dest, a)
    common = commondims(a, dims(b))
    od = otherdims(a, common)
    # Lazily permute B dims to match the order in A, if required
    if !dimsmatch(common, dims(b))
        b = PermutedDimsArray(b, common)
    end
    # Broadcast over b for each combination of dimensional indices D
    if length(od) == 0
        dest .= f.(a, b)
    else
        map(DimIndices(od)) do D
            dest[D...] .= f.(a[D...], b)
        end
    end
    return dest
end

"""
    basetypeof(x) => Type

Get the "base" type of an object - the minimum required to
define the object without it's fields. By default this is the full
`UnionAll` for the type. But custom `basetypeof` methods can be
defined for types with free type parameters.

In DimensionalData this is primariliy used for comparing `Dimension`s,
where `Dim{:x}` is different from `Dim{:y}`.
"""
@inline basetypeof(x::T) where T = basetypeof(T)
@generated function basetypeof(::Type{T}) where T
    if T isa Union
        T
    else
        getfield(parentmodule(T), nameof(T))
    end
end

# Left pipe operator for cleaning up brackets
@deprecate f <| x f(x)

# Unwrap Val
unwrap(::Val{X}) where X = X
unwrap(::Type{Val{X}}) where X = X
unwrap(x) = x

# Get a tuple of unique keys for DimArrays. If they have the same
# name we call them layerI.
function uniquekeys(das::Tuple{AbstractDimArray,Vararg{<:AbstractDimArray}})
    uniquekeys(Symbol.(map(name, das)))
end
function uniquekeys(keys::Tuple{Symbol,Vararg{<:Symbol}})
    ids = ntuple(x -> x, length(keys))
    map(keys, ids) do k, id
        count(k1 -> k == k1, keys) > 1 ? Symbol(:layer, id) : k
    end
end

# Produce a 2 * length(dim) matrix of interval bounds from a dim
function dim2boundsmatrix(dim::Dimension) 
    samp = sampling(dim)
    samp isa Intervals || error("Cannot create a bounds matrix for $(nameof(typeof(samp)))")
    _dim2boundsmatrix(locus(dim), span(dim), dim)
end

_dim2boundsmatrix(::Locus, span::Explicit, dim) = val(span)
_dim2boundsmatrix(::Locus, span::Regular, dim) =
    vcat(permutedims(_shiftindexlocus(Start(), dim)), permutedims(_shiftindexlocus(End(), dim)))
@noinline _dim2boundsmatrix(::Center, span::Regular{Dates.TimeType}, dim) =
    error("Cannot convert a Center TimeType index to Explicit automatically: use a bounds matrix e.g. Explicit(bnds)")
@noinline _dim2boundsmatrix(::Start, span::Irregular, dim) =
    error("Cannot convert Irregular to Explicit automatically: use a bounds matrix e.g. Explicit(bnds)")

#=
Shift the index from the current locus to the new locus. We only actually
shift Regular Intervals, and do this my multiplying the offset of
-1, -0.5, 0, 0.5 or 1 by the absolute value of the span.
=#
function shiftlocus(locus::Locus, dim::Dimension)
    samp = sampling(dim)
    samp isa Intervals || error("Cannot shift locus of $(nameof(typeof(samp)))")
    rebuild(dim; val=_shiftindexlocus(locus, dim), mode=DD._set(mode(dim), locus))
end

_shiftindexlocus(locus::Locus, dim::Dimension) = _shiftindexlocus(locus::Locus, mode(dim), dim)
_shiftindexlocus(locus::Locus, mode::IndexMode, dim::Dimension) = index(dim)
_shiftindexlocus(locus::Locus, mode::AbstractSampled, dim::Dimension) =
    _shiftindexlocus(locus, span(mode), sampling(mode), dim)
_shiftindexlocus(locus::Locus, span::Span, sampling::Sampling, dim::Dimension) = index(dim)
_shiftindexlocus(destlocus::Locus, span::Regular, sampling::Intervals, dim::Dimension) =
    index(dim) .+ (abs(step(span)) * _offset(locus(sampling), destlocus))
_shiftindexlocus(::Start, span::Explicit, sampling::Intervals, dim::Dimension) = val(span)[1, :]
_shiftindexlocus(::End, span::Explicit, sampling::Intervals, dim::Dimension) = val(span)[2, :]
_shiftindexlocus(destlocus::Center, span::Explicit, sampling::Intervals, dim::Dimension) =
    _shiftindexlocus(destlocus, locus(dim), span, sampling, dim)
_shiftindexlocus(::Center, ::Center, span::Explicit, sampling::Intervals, dim::Dimension) = index(dim)
_shiftindexlocus(::Center, ::Locus, span::Explicit, sampling::Intervals, dim::Dimension) =
    view(val(span), 2, :)  .- view(val(span), 1, :)

_offset(::Start, ::Center) = 0.5
_offset(::Start, ::End) = 1
_offset(::Center, ::Start) = -0.5
_offset(::Center, ::End) = 0.5
_offset(::End, ::Start) = -1
_offset(::End, ::Center) = -0.5
_offset(::T, ::T) where T<:Locus = 0

maybeshiftlocus(locus::Locus, dim::Dimension) = _maybeshiftlocus(locus, sampling(dim), dim)

_maybeshiftlocus(locus::Locus, sampling::Intervals, dim::Dimension) = shiftlocus(locus, dim)
_maybeshiftlocus(locus::Locus, sampling::Sampling, dim::Dimension) = dim

_astuple(t::Tuple) = t
_astuple(x) = (x,)
