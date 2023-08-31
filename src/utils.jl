
"""
    reorder(A::AbstractDimArray, order::Pair) => AbstractDimArray
    reorder(A::Dimension, order::Order) => AbstractDimArray

Reorder every dims index/array to `order`, or reorder index for
the the given dimension(s) to the `Order` they wrap.

`order` can be an [`Order`](@ref), or `Dimeension => Order` pairs.

If no axis reversal is required the same objects will be returned, without allocation.
"""
function reorder end

reorder(x, p::Pair, ps::Vararg{Pair}) = reorder(x, (p, ps...))
reorder(x, ps::Tuple{Vararg{Pair}}) = reorder(x, Dimensions.pairdims(ps...))
# Reorder specific dims.
reorder(x, dimwrappers::Tuple) = _reorder(x, dimwrappers)
# Reorder all dims.
reorder(x, ot::Order) = reorder(x, typeof(ot))
reorder(x, ot::Type{<:Order}) = _reorder(x, map(d -> rebuild(d, ot), dims(x)))
reorder(dim::Dimension, ot::Type{<:Order}) =
    ot <: basetypeof(order(dim)) ? dim : reverse(dim)

# Recursive reordering. x may be reversed here
_reorder(x, orderdims::DimTuple) = _reorder(reorder(x, orderdims[1]), tail(orderdims))
_reorder(x, orderdims::Tuple{}) = x

reorder(x, orderdim::Dimension) = _reorder(val(orderdim), x, dims(x, orderdim))

_reorder(neworder::Order, x, dim::DimOrDimType) = _reorder(basetypeof(neworder), x, dim)
# Reverse the dimension index
_reorder(::Type{O}, x, dim::DimOrDimType) where O<:Ordered =
    order(dim) isa O ? x : reverse(x; dims=dim)
_reorder(ot::Type{Unordered}, x, dim::DimOrDimType) = x

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
modify(f, dim::Dimension) = rebuild(dim, modify(f, val(dim)))
function modify(f, lookup::LookupArray)
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
function broadcast_dims(f, As::AbstractDimArray...)
    dims = combinedims(As...)
    T = Base.Broadcast.combine_eltypes(f, As)
    broadcast_dims!(f, similar(first(As), T, dims), As...)
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
function broadcast_dims!(f, dest::AbstractDimArray{<:Any,N}, As::AbstractDimArray...) where {N}
    As = map(As) do A
        isempty(otherdims(A, dims(dest))) || throw(DimensionMismatch("Cannot broadcast over dimensions not in the dest array"))
        # comparedims(dest, dims(A, dims(dest)))
        # Lazily permute B dims to match the order in A, if required
        if !dimsmatch(commondims(A, dest), commondims(dest, A))
            PermutedDimsArray(A, commondims(dest, A))
        else
            A
        end
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
            all(hasdim(A, dims(dest))) ? parent(A) : _insert_length_one_dims(A, dims(dest))
        end
        dest .= f.(reshaped...)
    end
    return dest
end

function _insert_length_one_dims(A, alldims)
    lengths = map(alldims) do d 
        hasdim(A, d) ? size(A, d) : 1
    end
    return reshape(parent(A), lengths)
end

@deprecate dimwise broadcast_dims
@deprecate dimwise! broadcast_dims!

# Get a tuple of unique keys for DimArrays. If they have the same
# name we call them layerI.
function uniquekeys(das::Tuple{AbstractDimArray,Vararg{AbstractDimArray}})
    uniquekeys(map(Symbol ∘ name, das))
end
function uniquekeys(das::Vector{<:AbstractDimArray})
    map(uniquekeys ∘ Symbol ∘ name, das)
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
