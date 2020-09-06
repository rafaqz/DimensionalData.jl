
"""
    reverse(A; dims) => AbstractDimArray
    reverse(dim::Dimension) => Dimension

Reverse the array order, and update the dim to match.
"""
Base.reverse(A::AbstractDimArray; dims=1) = reverse(ArrayOrder, A, dims)
Base.reverse(ot::Type{<:SubOrder}, A::AbstractDimArray; dims) = reverse(ot, A, dims)
Base.reverse(ot::Type{<:SubOrder}, A::AbstractDimArray, lookup) =
    set(A, reverse(ot, dims(A, lookup)))
Base.reverse(ot::Type{<:ArrayOrder}, A::AbstractDimArray, lookup) = begin
    newdims = reverse(ot, dims(A, lookup))
    newdata = reverse(parent(A); dims=dimnum(A, lookup))
    A = rebuild(A, newdata)
    set(A, newdims)
end
Base.reverse(ot::Type{<:SubOrder}, dims::DimTuple) = map(d -> reverse(ot, d), dims)
Base.reverse(ot::Type{<:SubOrder}, dim::Dimension) = set(dim, reverse(ot, order(dim)))
# Reverse the index
Base.reverse(ot::Type{<:IndexOrder}, dim::Dimension) =
    rebuild(dim, reverse(index(dim)), reverse(ot, mode(dim)))
Base.reverse(ot::Type{<:IndexOrder}, dim::Dimension{<:Val{Keys}}) where Keys =
    rebuild(dim, Val(reverse(Keys)), reverse(ot, mode(dim)))
Base.reverse(dim::Dimension) = reverse(IndexOrder, dim)

Base.reverse(ot::Type{<:SubOrder}, mode::IndexMode) = set(mode, reverse(ot, order(mode)))

"""
    fliparray(Order, A, dims) => AbstractDimArray
    fliparray(dim::Dimension) => Dimension

`Flip` the array order without changing any data.
"""
function flip end

flip(ot::Type{<:SubOrder}, A::AbstractDimArray; lookup) = flip(ot, A, lookup)
flip(ot::Type{<:SubOrder}, A::AbstractDimArray, lookup) = set(A, flip(ot, dims(A, lookup)))
flip(ot::Type{<:SubOrder}, dims::DimTuple) = map(d -> flip(ot, d), dims)
flip(ot::Type{<:SubOrder}, dim::Dimension) = set(dim, flip(ot, mode(dim)))
flip(ot::Type{<:SubOrder}, mode::IndexMode) = set(mode, flip(ot, order(mode)))
flip(ot::Type{<:SubOrder}, o::Order) = set(o, reverse(ot, o))


"""
    reorder(::order, A::AbstractDimArray) => AbstractDimArray
    reorder(A::AbstractDimArray, order::Union{Order,Dimension{<:Order},Tuple}) => AbstractDimArray
    reorder(A::AbstractDimArray, order::Pair{<:Dimension,<:SubOrder}...) => AbstractDimArray

Reorder every dims index/array/relation to `order`, or reorder index for
the the given dimension(s) to the `Order` they wrap.

Reorderind `RelationOrder` will reverse the array, not the dimension index.

`order` can be an [`Order`](@ref), a single [`Dimension`](@ref)
or a `Tuple` of `Dimension`.
"""
function reorder end

reorder(A::AbstractDimArray, args...; kwargs...) =
    reorder(A, (args..., _kwargdims(kwargs)...))
reorder(A::AbstractDimArray, nt::NamedTuple) = reorder(A, _kwargdims(nt))
reorder(A::AbstractDimArray, p::Pair, ps::Vararg{<:Pair}) = reorder(A, (p, ps...))
reorder(A::AbstractDimArray, ps::Tuple{Vararg{<:Pair}}) = reorder(A, _pairdims(ps...))
# Reorder specific dims.
reorder(A::AbstractDimArray, dimwrappers::Tuple) = _reorder(A, dimwrappers)
# Reorder all dims.
reorder(ot::Union{SubOrder,Type{<:SubOrder}}, A::AbstractDimArray) =
    _reorder(A, map(d -> basetypeof(d)(ot), dims(A)))
reorder(A::AbstractDimArray, orderdim::Dimension) =
    _reorder(val(orderdim), A, dims(A, orderdim))

# Recursive reordering. A may be reversed here for ot <: ArrayOrder.
_reorder(A::AbstractDimArray, dims::DimTuple) =
    _reorder(reorder(A, dims[1]), tail(dims))
_reorder(A::AbstractDimArray, dims::Tuple{}) = A

_reorder(neworder::SubOrder, A::AbstractDimArray, dim::DimOrDimType) =
    _reorder(basetypeof(neworder), A, dim)
_reorder(ot::Type{<:IndexOrder}, A::AbstractDimArray, dim::DimOrDimType) =
    ot == basetypeof(order(ot, dim)) ? A : set(A, reverse(ot, dim))
# If either ArrayOrder or RelationOrder are reversed, we reverse the array as well
_reorder(ot::Type{<:Union{ArrayOrder,RelationOrder}}, A::AbstractDimArray, dim::DimOrDimType) =
    ot == basetypeof(order(ot, dim)) ? A : reverse(A; dims=dim)


"""
    modify(f, A::AbstractDimArray) => AbstractDimArray

Modify the parent data, rebuilding the `AbstractDimArray` wrapper without
change. `f` must return a `AbstractArray` of the same size as the original.
"""
modify(f, A::AbstractDimArray) = begin
    newdata = f(parent(A))
    size(newdata) == size(A) || error("$f returns an array with a different size")
    rebuild(A, newdata)
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
dimwise(f, A::AbstractDimArray, B::AbstractDimArray) =
    dimwise!(f, similar(A, promote_type(eltype(A), eltype(B))), A, B)

"""
    dimwise!(f, dest::AbstractDimArray{T1,N}, A::AbstractDimArray{T2,N}, B::AbstractDimArray) => dest

Dimension-wise application of function `f`.

## Arguments

- `dest`: `AbstractDimArray` to update
- `a`: `AbstractDimArray` to broacast from, along dimensions not in `b`.
- `b`: `AbstractDimArray` to broadcast from all dimensions. Dimensions must be a subset of a.

This is like broadcasting over every slice of `A` if it is
sliced by the dimensions of `B`, and storing the value in `dest`.
"""
dimwise!(f, dest::AbstractDimArray{T,N}, a::AbstractDimArray{TA,N}, b::AbstractDimArray{TB,NB}
        ) where {T,TA,TB,N,NB} = begin
    N >= NB || error("B-array cannot have more dimensions than A array")
    comparedims(dest, a)
    common = commondims(a, dims(b))
    generators = dimwise_generators(otherdims(a, common))
    # Lazily permute B dims to match the order in A, if required
    if !dimsmatch(common, dims(b))
        b = PermutedDimsArray(b, common)
    end
    # Broadcast over b for each combination of dimensional indices D
    map(generators) do D
        dest[D...] .= f.(a[D...], b)
    end
    return dest
end

# Single dimension generator
dimwise_generators(dims::Tuple{<:Dimension}) =
    ((basetypeof(dims[1])(i),) for i in axes(dims[1], 1))

# Multi dimensional generators
dimwise_generators(dims::Tuple) = begin
    dim_constructors = map(basetypeof, dims)
    # Get the axes of the dims to iterate over
    dimaxes = map(d -> axes(d, 1), dims)
    # Make an iterator over all axes
    proditr = Base.Iterators.ProductIterator(dimaxes)
    # Wrap the produced index I in dimensions as it is generated
    Base.Generator(proditr) do I
        map((D, i) -> D(i), dim_constructors, I)
    end
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
basetypeof(x) = basetypeof(typeof(x))
@generated function basetypeof(::Type{T}) where T
    getfield(parentmodule(T), nameof(T))
end

# Left pipe operator for cleaning up brackets
f <| x = f(x)

unwrap(::Val{X}) where X = X
unwrap(::Type{Val{X}}) where X = X
unwrap(x) = x

