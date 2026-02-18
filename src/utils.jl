const Reorderable = Union{AbstractBasicDimArray,AbstractDimStack,DimTuple}
const DimensionOrLookup = Union{Dimension,Lookup}

"""
    reorder(A::Union{AbstractDimArray,AbstractDimStack}, order::Pair...)
    reorder(A::Union{AbstractDimArray,AbstractDimStack}, order)
    reorder(A::Dimension, order::Order)

Reorder every dims index/array to `order`, or reorder index for
the given dimension(s) in `order`.

`order` can be an [`Order`](@ref), `Dimension => Order` pairs.
A Tuple of Dimensions or any object that defines `dims` can be used
in which case the dimensions of this object are used for reordering.

If no axis reversal is required the same objects will be returned, without allocation.

## Example

```jldoctest
using DimensionalData

# Create a DimArray
da = DimArray([1 2 3; 4 5 6], (X(10:10:20), Y(300:-100:100)))

# Reverse it
rev = reverse(da, dims=Y)

# using `da` in reorder will return it to the original order
reorder(rev, da) == da

# output
true
```
"""
function reorder end

reorder(x::Reorderable, A::Union{AbstractDimArray,AbstractDimStack,AbstractDimIndices}) = 
    reorder(x, dims(A))
reorder(x::Reorderable, ::Nothing) = throw(ArgumentError("object has no dimensions"))
reorder(x::Reorderable, p::Pair, ps::Pair...) = reorder(x, (p, ps...))
reorder(x::Reorderable, ps::Tuple{Vararg{Pair}}) = reorder(x, Dimensions.pairs2dims(ps...))
reorder(x::Reorderable, ::Type{O}) where O<:Order = reorder(x, O())
function reorder(x::Reorderable, o::Order)
    ds = dims(x)
    isnothing(ds) && _dimsnotdefinederror()
    reorder(x, map(d -> rebuild(d, o), ds))
end
reorder(x::Reorderable, o::Tuple{Vararg{Order}}) = reorder(x, map(rebuild, dims(x), o))
# Recursive reordering. x may be reversed here
function reorder(x::Reorderable, orderdims::DimTuple)
    ods = commondims(orderdims, dims(x))
    reorder(reorder(x, ods[1]), tail(ods))
end
reorder(x::Reorderable, orderdims::Tuple{}) = x
function reorder(ds::DimTuple, orderdims::DimTuple)
    ods = commondims(orderdims, ds)
    map(ds) do d
        hasdim(ods, d) ? reorder(d, val(dims(ods, d))) : d
    end
end
reorder(ds::DimTuple, orderdims::Tuple{}) = ds

reorder(x::Reorderable, orderdim::Dimension{<:Order}) = _reorder(x, dims(x, orderdim), val(orderdim))
reorder(x::Reorderable, orderdim::Dimension{<:Lookup}) = _reorder(x, dims(x, orderdim), order(orderdim))

# AutoOrder: keep the current order unchanged
_reorder(x::Reorderable, dim::Dimension, ::AutoOrder) = x
# Unordered: do nothing, just set the order to Unordered
_reorder(x::Reorderable, dim::Dimension, o::Unordered) = unsafe_set(x, dim => o)
# Ordered: leave, reverse or sort
_reorder(x::Reorderable, dim::Dimension, o::Ordered) = _reorder(x, dim, order(dim), o)
# Order matches, nothing to do
_reorder(x::Reorderable, dim::Dimension, ::O, ::O) where O<:Ordered = x
# dimensional reverse can handle this
_reorder(x::Reorderable, dim::Dimension, ::Ordered, ::Ordered) =
    reverse(x; dims=basedims(dim))
function _reorder(x::AbstractDimIndices, dim::Dimension, o1::Unordered, o2::Ordered)
    newdim = _reorder(dims(x, dim), o1, o2)
    return unsafe_set(x, newdim)
end
# We need to sort the data along this dimension
function _reorder(
    x::Union{AbstractDimArray,AbstractDimStack}, dim::Dimension, ::Unordered, o::Ordered
)
    l = lookup(dim)
    # Sort forwards or reverse
    idxs = o isa ForwardOrdered ? sortperm(l) : sortperm(l; rev=true)
    # Reorder the values by indexing into dimension of dim
    output = x[rebuild(dim, idxs)]
    # Set the order
    return unsafe_set(output, dim => o)
end

reorder(x::Dimension, o::Order) = rebuild(x, _reorder(lookup(x), o))
reorder(x::Dimension, l::Lookup) = _reorder(x, order(l))
reorder(x::Dimension, d::Dimension) = _reorder(x, order(d))

# AutoOrder: keep the current order unchanged
_reorder(x::DimensionOrLookup, ::AutoOrder) = x
# Unordered: do nothing, just set the order to Unordered
_reorder(x::DimensionOrLookup, o::Unordered) = unsafe_set(x, o)
# Ordered: leave, reverse or sort
_reorder(x::DimensionOrLookup, o::Ordered) = _reorder(x, order(x), o)
# Order matches, nothing to do
_reorder(x::DimensionOrLookup, ::O, ::O) where O<:Ordered = x
# reverse can handle this
_reorder(x::DimensionOrLookup, ::Ordered, ::Ordered) = reverse(x)
# We need to sort
_reorder(dim::Dimension, ::Unordered, o::Ordered) =
    rebuild(dim, reorder(lookup(dim), o))
# For Lookups, delegate to Lookups.reorder which has the full implementation
_reorder(l::Lookup, ::Unordered, o::Ordered) = reorder(l, o)

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
modify(f, s::AbstractDimStack) = maplayers(a -> modify(f, a), s)
# Stack optimisation to avoid compilation to build all the `AbstractDimArray` 
# layers, and instead just modify the parent data directly.
modify(f, s::AbstractDimStack{<:Any,<:Any,<:NamedTuple}) = 
    rebuild(s; data=map(a -> modify(f, a), parent(s)))
function modify(f, A::AbstractDimArray)
    newdata = f(parent(A))
    size(newdata) == size(A) || error("$f returns an array with a different size")
    rebuild(A, newdata)
end
modify(f, x, dim::DimOrDimType) = set(x, modify(f, dims(x, dim)))
modify(f, dim::Dimension) = rebuild(dim, modify(f, val(dim)))
function modify(f, lookup::Lookup)
    newindex = modify(f, parent(lookup))
    rebuild(lookup; data=newindex)
end
function modify(f, index::AbstractArray)
    newindex = f(index)
    size(newindex) == size(index) || error("$f returns a vector with a different size")
    newindex
end

"""
    broadcast_dims(f, sources::AbstractDimArray...) => AbstractDimArray

Broadcast function `f` over the `AbstractDimArray`s in `sources`, permuting and reshaping
dimensions to match where required. The result will contain all the dimensions in 
all passed in arrays in the order in which they are found.

## Arguments

- `sources`: `AbstractDimArrays` to broadcast over with `f`.

This is like broadcasting over every slice of `A` if it is
sliced by the dimensions of `B`.
"""
function broadcast_dims(f, A1::AbstractBasicDimArray, As::AbstractBasicDimArray...)
    dims = combinedims(A1, As...)
    T = Base.Broadcast.combine_eltypes(f, (A1, As...))
    broadcast_dims!(f, similar(A1, T, dims), A1, As...)
end
function broadcast_dims(
    f, A1::Union{AbstractDimStack,AbstractBasicDimArray}, 
    As::Union{AbstractDimStack,AbstractBasicDimArray}...
)
    st = _firststack(A1, As...)::AbstractDimStack
    nts = _as_extended_nts(NamedTuple(st), A1, As...)
    layers = map(keys(st)) do name
        broadcast_dims(f, map(nt -> nt[name], nts)...)
    end
    rebuild_from_arrays(st, layers)
end

"""
    broadcast_dims!(f, dest::AbstractDimArray, sources::AbstractDimArray...) => dest

Broadcast function `f` over the `AbstractDimArray`s in `sources`, writing to `dest`. 
`sources` are permuting and reshaping dimensions to match where required.

The result will contain all the dimensions in all passed in arrays, in the order in
which they are found.

## Arguments

- `dest`: `AbstractDimArray` to update.
- `sources`: `AbstractDimArrays` to broadcast over with `f`.
"""
function broadcast_dims!(f, dest::AbstractDimArray{<:Any,N}, As::AbstractBasicDimArray...) where {N}
    As = map(As) do A
        isempty(otherdims(A, dims(dest))) || throw(DimensionMismatch("Cannot broadcast over dimensions not in the dest array"))
        # comparedims(dest, dims(A, dims(dest)))
        # Lazily permute B dims to match the order in A, if required
        _maybe_lazy_permute(A, dims(dest))
    end
    od = map(A -> otherdims(dest, dims(A)), As)
    return _broadcast_dims_inner!(f, dest, As, od)
end
function broadcast_dims!(f, dest::AbstractDimStack, stacks::AbstractDimStack...)
    maplayers(dest, stacks...) do d, layers...
        broadcast_dims!(f, d, layers...)
    end
end

# Function barrier
function _broadcast_dims_inner!(f, dest, As, od)
    # Broadcast over b for each combination of dimensional indices D
    if all(map(isempty, od))
        dest .= f.(As...)
    else
        not_shared_dims = combinedims(od...) 
        reshaped = map(As) do A
            _maybe_insert_length_one_dims(A, dims(dest))
        end
        dest .= f.(reshaped...)
    end
    return dest
end


# Get a tuple of unique keys for DimArrays. If they have the same
# name we call them layerI.
function uniquekeys(das::Tuple{AbstractDimArray,Vararg{AbstractDimArray}})
    uniquekeys(map(Symbol ∘ name, das))
end
function uniquekeys(das::Vector{<:AbstractDimArray})
    length(das) == 0 ? Symbol[] : uniquekeys(map(Symbol ∘ name, das))
end
function uniquekeys(keys::AbstractVector{Symbol})
    map(enumerate(keys)) do (id, k)
        count(k1 -> k == k1, keys) > 1 ? Symbol(:layer, id) : k
    end
end
function uniquekeys(keys::Tuple{Symbol,Vararg{Symbol}})
    ids = ntuple(identity, length(keys))
    map(keys, ids) do k, id
        if k == Symbol("") 
            Symbol(:layer, id)
        else
            count(k1 -> k == k1, keys) > 1 ? Symbol(:layer, id) : k
        end
    end
end
uniquekeys(t::Tuple) = ntuple(i -> Symbol(:layer, i), length(t))
uniquekeys(a::AbstractVector) = map(i -> Symbol(:layer, i), eachindex(a))
uniquekeys(nt::NamedTuple) = keys(nt)

_as_extended_nts(nt::NamedTuple{K}, A::AbstractDimArray, As...) where K = 
    (NamedTuple{K}(ntuple(x -> A, length(K))), _as_extended_nts(nt, As...)...)
function _as_extended_nts(nt::NamedTuple{K1}, st::AbstractDimStack{K2}, As...) where {K1,K2}
    K1 == K2 || throw(ArgumentError("Keys of stack $K2 do not match the keys of the first stack $K1"))
    extended_layers = map(layers(st)) do l
        if all(hasdim(l, dims(st)))
            l
        else
            DimExtensionArray(l, dims(st))
        end
    end
    return (extended_layers, _as_extended_nts(nt, As...)...)
end
_as_extended_nts(::NamedTuple) = ()


# Tuple map that is always unrolled
# mostly for stack indexing performance
_unrolled_map_inner(f, v::Type{T}) where T = 
    Expr(:tuple, (:(f(v[$i])) for i in eachindex(T.types))...)
_unrolled_map_inner(f, v1::Type{T}, v2::Type) where T = 
    Expr(:tuple, (:(f(v1[$i], v2[$i])) for i in eachindex(T.types))...)

@generated function unrolled_map(f, v::NamedTuple{K}) where K
    exp = _unrolled_map_inner(f, v)
    :(NamedTuple{K}($exp))
end
@generated function unrolled_map(f, v1::NamedTuple{K}, v2::NamedTuple{K}) where K
    exp = _unrolled_map_inner(f, v1, v2)
    :(NamedTuple{K}($exp))
end
@generated unrolled_map(f, v::Tuple) =
    _unrolled_map_inner(f, v)
@generated unrolled_map(f, v1::Tuple, v2::Tuple) = 
    _unrolled_map_inner(f, v1, v2)
