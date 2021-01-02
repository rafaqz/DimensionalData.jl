
"""
    reverse(A; dims) => AbstractDimArray
    reverse(dim::Dimension) => Dimension

Reverse the array order, and update the dim to match.
"""
Base.reverse(A::AbstractDimArray; dims=1) =
    reverse(IndexOrder, reverse(ArrayOrder, A, dims), dims)
Base.reverse(s::AbstractDimStack; dims=1) = reverse(ArrayOrder, s, dims)
Base.reverse(ot::Type{<:SubOrder}, x; dims) = reverse(ot, x, dims)
Base.reverse(ot::Type{<:SubOrder}, x, lookup) = set(x, reverse(ot, dims(x, lookup)))
Base.reverse(ot::Type{<:ArrayOrder}, x, lookup) = begin
    newdims = reverse(ot, dims(x, lookup))
    newdata = _reversedata(x, dimnum(x, lookup))
    setdims(rebuild(x, newdata), newdims)
end
# Dimension
Base.reverse(ot::Type{<:SubOrder}, dims::DimTuple) = map(d -> reverse(ot, d), dims)
Base.reverse(ot::Type{<:SubOrder}, dim::Dimension) = _set(dim, reverse(ot, order(dim)))
# Reverse the index
Base.reverse(ot::Type{<:IndexOrder}, dim::Dimension) =
    rebuild(dim, reverse(index(dim)), reverse(ot, mode(dim)))
Base.reverse(ot::Type{<:IndexOrder}, dim::Dimension{<:Val{Keys}}) where Keys =
    rebuild(dim, Val(reverse(Keys)), reverse(ot, mode(dim)))
Base.reverse(dim::Dimension) = reverse(IndexOrder, dim)
# Mode
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
Base.reverse(::Type{<:IndexOrder}, span::Regular) = reverse(span)
Base.reverse(::Type{<:SubOrder}, span::Span) = span
Base.reverse(span::Regular) = Regular(-step(span))

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
flip(ot::Type{<:SubOrder}, o::Order) = _set(o, reverse(ot, o))

Base.diff(A::AbstractDimVector) = diff(A; dims=1)
Base.diff(A::AbstractDimArray; dims) = _diff(A; dims=dimnum(A, dims))

function _diff(a::AbstractArray{T,N}; dims::Integer) where {T,N}
    Base.require_one_based_indexing(a)
    1 <= dims <= N || throw(ArgumentError("dimension $dims out of range (1:$N)"))
    r = axes(a)
    r0 = ntuple(i -> i == dims ? UnitRange(1, last(r[i]) - 1) : UnitRange(r[i]), N)
    r1 = ntuple(i -> i == dims ? UnitRange(2, last(r[i])) : UnitRange(r[i]), N)

    return view(a, r1...) .- view(a, r0...)
end

"""
    reorder(::order, A::AbstractDimArray) => AbstractDimArray
    reorder(A::AbstractDimArray, order::Union{Order,Dimension{<:Order},Tuple}) => AbstractDimArray
    reorder(A::AbstractDimArray, order::Pair{<:Dimension,<:SubOrder}...) => AbstractDimArray

Reorder every dims index/array/relation to `order`, or reorder index for
the the given dimension(s) to the `Order` they wrap.

Reorderind `Relation` will reverse the array, not the dimension index.

`order` can be an [`Order`](@ref), a single [`Dimension`](@ref)
or a `Tuple` of `Dimension`.
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
reorder(x, ot::Union{SubOrder,Type{<:SubOrder}}, dims_) =
    _reorder(x, map(d -> basetypeof(d)(ot), dims(x, dims_)))

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
modify(f, s::AbstractDimStack) = map(f, s)
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
- `a`: `AbstractDimArray` to broacast from, along dimensions not in `b`.
- `b`: `AbstractDimArray` to broadcast from all dimensions. Dimensions must be a subset of a.

This is like broadcasting over every slice of `A` if it is
sliced by the dimensions of `B`, and storing the value in `dest`.
"""
function dimwise!(
    f, dest::AbstractDimArray{T,N}, a::AbstractDimArray{TA,N}, b::AbstractDimArray{TB,NB}
) where {T,TA,TB,N,NB}
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
function dimwise_generators(dims::Tuple{<:Dimension})
    ((basetypeof(dims[1])(i),) for i in axes(dims[1], 1))
end
# Multi dimensional generators
function dimwise_generators(dims::Tuple)
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
@inline basetypeof(x::T) where T = basetypeof(T)
@generated function basetypeof(::Type{T}) where T
    if T isa Union
        T
    else
        getfield(parentmodule(T), nameof(T))
    end
end

# Left pipe operator for cleaning up brackets
f <| x = f(x)

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
uniquekeys(keys::Tuple{String,Vararg{<:String}}) = uniquekeys(map(Symbol, keys))
