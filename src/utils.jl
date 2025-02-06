
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

reorder(x, A::Union{AbstractDimArray,AbstractDimStack,AbstractDimIndices}) = 
    reorder(x, dims(A))
reorder(x, ::Nothing) = throw(ArgumentError("object has no dimensions"))
reorder(x, p::Pair, ps::Pair...) = reorder(x, (p, ps...))
reorder(x, ps::Tuple{Vararg{Pair}}) = reorder(x, Dimensions.pairs2dims(ps...))
# Reorder specific dims.
reorder(x, dims::Tuple) = _reorder(x, dims)
# Reorder all dims.
reorder(x, ::Type{O}) where O<:Order = reorder(x, O())
reorder(x, o::Order) = _reorder(x, map(d -> rebuild(d, o), dims(x)))
reorder(x, o::Tuple{Vararg{Order}}) = reorder(x, map(rebuild, dims(x), o))
# Recursive reordering. x may be reversed here
function reorder(x, orderdims::DimTuple)
    ods = commondims(orderdims, dims(x))
    reorder(reorder(x, ods[1]), tail(ods))
end
reorder(x, orderdims::Tuple{}) = x

reorder(x, orderdim::Dimension) = _reorder(x, dims(x, orderdim), val(orderdim))
reorder(x, orderdim::Dimension{<:Lookup}) = _reorder(x, dims(x, orderdim), order(orderdim))

# Reverse the dimension index
_reorder(x, dim::Dimension, o::Unordered) = unsafe_set(x, dim => o)
_reorder(x, dim::Dimension, o::Ordered) = _reorder(x, dim, order(dim), o)
_reorder(x, dim::Dimension, ::O, ::O) where O<:Ordered = x
_reorder(x, dim::Dimension, ::Ordered, ::Ordered) = reverse(x; dims=basedims(dim))
# Sort an unordered dimension
function _reorder(x, dim::Dimension, ::Unordered, o::Ordered)
    pairs = parent(lookup(dim)) .=> eachindex(lookup(dim))
    o isa ForwardOrdered ? sort!(pairs) : sort!(pairs; rev=true)
    idxs = last.(pairs)
    return x[rebuild(dim, idxs)]
end

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
function broadcast_dims(f, As::AbstractBasicDimArray...)
    dims = combinedims(As...)
    T = Base.Broadcast.combine_eltypes(f, As)
    broadcast_dims!(f, similar(first(As), T, dims), As...)
end

function broadcast_dims(f, As::Union{AbstractDimStack,AbstractBasicDimArray}...)
    st = _firststack(As...)
    nts = _as_extended_nts(NamedTuple(st), As...)
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

@deprecate dimwise broadcast_dims
@deprecate dimwise! broadcast_dims!

# Get a tuple of unique keys for DimArrays. If they have the same
# name we call them layerI.
function uniquekeys(das::Tuple{AbstractDimArray,Vararg{AbstractDimArray}})
    uniquekeys(map(Symbol ∘ name, das))
end
function uniquekeys(das::Vector{<:AbstractDimArray})
    length(das) == 0 ? Symbol[] : uniquekeys(map(Symbol ∘ name, das))
end
function uniquekeys(keys::Vector{Symbol})
    map(enumerate(keys)) do (id, k)
        count(k1 -> k == k1, keys) > 1 ? Symbol(:layer, id) : k
    end
end
function uniquekeys(keys::Tuple{Symbol,Vararg{Symbol}})
    ids = ntuple(x -> x, length(keys))
    map(keys, ids) do k, id
        count(k1 -> k == k1, keys) > 1 ? Symbol(:layer, id) : k
    end
end
uniquekeys(t::Tuple) = ntuple(i -> Symbol(:layer, i), length(t))
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
