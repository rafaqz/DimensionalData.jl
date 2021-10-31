
"""
    reorder(A::AbstractDimArray, order::Pair) => AbstractDimArray
    reorder(A::Dimension, order::Order) => AbstractDimArray

Reorder every dims index/array to `order`, or reorder index for
the the given dimension(s) to the `Order` they wrap.

`order` can be an [`Order`](@ref), or `Dimeension => Order` pairs.

If no axis reversal is required the same objects will be returned, without allocation.
"""
function reorder end

reorder(x, p::Pair, ps::Vararg{<:Pair}) = reorder(x, (p, ps...))
reorder(x, ps::Tuple{Vararg{<:Pair}}) = reorder(x, Dimensions.pairdims(ps...))
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

_astuple(t::Tuple) = t
_astuple(x) = (x,)
