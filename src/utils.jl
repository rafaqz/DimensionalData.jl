
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
reorder(x, ps::Tuple{Vararg{<:Pair}}) = reorder(x, _pairdims(ps...))
# Reorder specific dims.
reorder(x, dimwrappers::Tuple) = _reorder(x, dimwrappers)
# Reorder all dims.
reorder(x, ot::Order) = reorder(x, typeof(ot))
reorder(x, ot::Type{<:Order}) = _reorder(x, map(d -> basetypeof(d)(ot), dims(x)))
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
dim2boundsmatrix(dim::Dimension)  = dim2boundsmatrix(lookup(dim))
function dim2boundsmatrix(lookup::Lookup)
    samp = sampling(lookup)
    samp isa Intervals || error("Cannot create a bounds matrix for $(nameof(typeof(samp)))")
    _dim2boundsmatrix(locus(lookup), span(lookup), lookup)
end

_dim2boundsmatrix(::Locus, span::Explicit, lookup) = val(span)
_dim2boundsmatrix(::Locus, span::Regular, lookup) =
    vcat(permutedims(_shiftindexlocus(Start(), lookup)), permutedims(_shiftindexlocus(End(), lookup)))
@noinline _dim2boundsmatrix(::Center, span::Regular{Dates.TimeType}, lookupj) =
    error("Cannot convert a Center TimeType index to Explicit automatically: use a bounds matrix e.g. Explicit(bnds)")
@noinline _dim2boundsmatrix(::Start, span::Irregular, lookupj) =
    error("Cannot convert Irregular to Explicit automatically: use a bounds matrix e.g. Explicit(bnds)")


"""
    shiftlocus(locus::Locus, x)

Shift the index of `x` from the current locus to the new locus.

We only shift `Samped`, `Regular` or `Explicit`, `Intervals`. 
"""
shiftlocus(locus::Locus, dim::Dimension) = rebuild(dim, shiftlocus(locus, lookup(dim)))
function shiftlocus(locus::Locus, lookup::Lookup)
    samp = sampling(lookup)
    samp isa Intervals || error("Cannot shift locus of $(nameof(typeof(samp)))")
    newindex = _shiftindexlocus(locus, lookup)
    newlookup = rebuild(lookup; data=newindex)
    return set(newlookup, locus)
end

# Fallback - no shifting
_shiftindexlocus(locus::Locus, lookup::Lookup) = index(lookup)
# Sampled
function _shiftindexlocus(locus::Locus, lookup::AbstractSampled)
    _shiftindexlocus(locus, span(lookup), sampling(lookup), lookup)
end
# TODO:
_shiftindexlocus(locus::Locus, span::Irregular, sampling::Sampling, lookup::Lookup) = index(lookup)
# Sampled Regular
function _shiftindexlocus(destlocus::Center, span::Regular, sampling::Intervals, dim::Lookup)
    index(dim) .+ ((index(dim) .+ abs(step(span))) .- index(dim)) * _offset(locus(sampling), destlocus)
end
function _shiftindexlocus(destlocus::Locus, span::Regular, sampling::Intervals, lookup::Lookup)
    index(lookup) .+ (abs(step(span)) * _offset(locus(sampling), destlocus))
end
# Sampled Explicit
_shiftindexlocus(::Start, span::Explicit, sampling::Intervals, lookup::Lookup) = val(span)[1, :]
_shiftindexlocus(::End, span::Explicit, sampling::Intervals, lookup::Lookup) = val(span)[2, :]
function _shiftindexlocus(destlocus::Center, span::Explicit, sampling::Intervals, lookup::Lookup)
    _shiftindexlocus(destlocus, locus(lookup), span, sampling, lookup)
end
_shiftindexlocus(::Center, ::Center, span::Explicit, sampling::Intervals, lookup::Lookup) = index(lookup)
function _shiftindexlocus(::Center, ::Locus, span::Explicit, sampling::Intervals, lookup::Lookup)
    # A little complicated so that DateTime works
    (view(val(span), 2, :)  .- view(val(span), 1, :)) ./ 2 .+ view(val(span), 1, :)
end

_offset(::Start, ::Center) = 0.5
_offset(::Start, ::End) = 1
_offset(::Center, ::Start) = -0.5
_offset(::Center, ::End) = 0.5
_offset(::End, ::Start) = -1
_offset(::End, ::Center) = -0.5
_offset(::T, ::T) where T<:Locus = 0

maybeshiftlocus(locus::Locus, d::Dimension) = rebuild(d, maybeshiftlocus(locus, lookup(d)))
maybeshiftlocus(locus::Locus, l::Lookup) = _maybeshiftlocus(locus, sampling(l), l)

_maybeshiftlocus(locus::Locus, sampling::Intervals, l::Lookup) = shiftlocus(locus, l)
_maybeshiftlocus(locus::Locus, sampling::Sampling, l::Lookup) = l

_astuple(t::Tuple) = t
_astuple(x) = (x,)
