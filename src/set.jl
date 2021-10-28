const LookupArraySetters = Union{AllMetadata,LookupArray,LookupArrayTrait,Nothing}
const DimSetters = Union{LookupArraySetters,Type,UnionAll,Dimension,Symbol}
const DimArrayOrStack = Union{AbstractDimArray,AbstractDimStack}

"""
    set(x, val)
    set(x, args::Pairs...) => x with updated field/s
    set(x, args...; kw...) => x with updated field/s
    set(x, args::Tuple{Vararg{<:Dimension}}; kw...) => x with updated field/s

Set object dimensions or properties of wrapped `LookupArray`. 

As DimensionalData is so strongly typed you do not need to specify what field
of a [`LookupArray`](@ref) to `set` - there is no ambiguity.

To set fields of dimensions you need to specify the dimension. This can be done using
`X => val` pairs, `X = val` keyword arguments, or `X(val)` wrapped arguments.

When a `Dimension` or `LookupArray` is passed to `set` to replace the
existing ones, fields that are not set will keep their original values.

## Notes:

Changing the dimension index will also set the step size, and order where applicable.

Setting [`ForwardOrder`](@ref) will *not* reverse the array or dimension to match.
Use `reverse` and [`reorder`](@ref) to do this.


## Examples

```julia
da = DimArray(rand(3, 4), (Dim{:custom}(10.0:010.0:30.0), Z(-20:010.0:10.0)))

# Set the array values
set(da, zeros(3, 4))

# Set the array name
set(da, "newname") # Swap dimension type 
# Using Pairs 
# set(da, :Z => Ti, :custom => Z) 
# set(da, :custom => X, Z => Y)

# Set the dimension index

# To an `AbstractArray` set(da, Z => [:a, :b, :c, :d], :custom => [4, 5, 6])

# To a `Val` tuple index (compile time indexing)
set(da, Z(Val((:a, :b, :c, :d))), custom = 4:6)

# Set dim lookups
set(da, Z=NoLookup(), custom=Sampled())
set(da, :custom => Irregular(10, 12), Z => Regular(9.9))
set(da, (Z=NoLookup(), custom=Sampled()))
set(da, custom=Reverse(), Z=Unordered())
```
"""
function set end
set(A::DimArrayOrStack, x::T) where {T<:Union{LookupArray,LookupArrayTrait}} = _onlydimerror(x)
set(x::DimArrayOrStack, ::Type{T}) where T = set(x, T())

set(A::AbstractDimStack, x::LookupArray) = _cantseterror(A, x)
set(A::AbstractDimArray, x::LookupArray) = _cantseterror(A, x)
set(A, x) = _cantseterror(A, x)
set(A::DimArrayOrStack, args::Union{Dimension,DimTuple,Pair}...; kw...) =
    rebuild(A, data(A), _set(dims(A), args...; kw...))
set(A::AbstractDimArray, newdata::AbstractArray) = begin
    axes(A) == axes(newdata) || _axiserr(A, newdata)
    rebuild(A; data=newdata)
end
set(s::AbstractDimStack, newdata::NamedTuple) = begin
    dat = data(s)
    keys(dat) === keys(newdata) || _keyerr(keys(dat), keys(newdata))
    map(dat, newdata) do d, nd
        axes(d) == axes(nd) || _axiserr(d, nd)
    end
    rebuild(s; data=newdata)
end
"""
    set(s::AbstractDimStack, metadata::AbstractMetadata) => AbstractDimStack

Update the `metadata` field of the stack.
"""
set(s::AbstractDimStack, metadata::AbstractMetadata) = rebuild(s; metadata=metadata)
"""
    set(dim::Dimension, index::Unioon{AbstractArray,Val}) => Dimension
    set(dim::Dimension, lookup::LookupArray) => Dimension
    set(dim::Dimension, lookupcomponent::LookupArrayTrait) => Dimension
    set(dim::Dimension, metadata::AbstractMetadata) => Dimension

Set fields of the dimension
"""
set(dim::Dimension, x::DimSetters) = _set(dim, x)
set(lookup::LookupArray, x::LookupArraySetters) = _set(lookup, x)

# Array or Stack
_set(A, x) = _cantseterror(A, x)

# Dimension
# Convert args/kw to dims and set
_set(dims_::DimTuple, args::Dimension...; kw...) = _set(dims_, (args..., _kwdims(kw)...))
# Convert pairs to wrapped dims and set
_set(dims_::DimTuple, p::Pair, ps::Vararg{<:Pair}) = _set(dims_, (p, ps...))
_set(dims_::DimTuple, ps::Tuple{Vararg{<:Pair}}) = _set(dims_, _pairdims(ps...))
# Set dims with (possibly unsorted) wrapper vals
_set(dims::DimTuple, wrappers::DimTuple) = begin
    # Check the dimension types match
    map(wrappers) do w
        hasdim(dims, w) || _wrongdimserr(dims, w)
    end
    # Missing dims return `nothing` from sortdims
    newdims = map(_set, dims, sortdims(wrappers, dims))
    # Swaps existing dims with non-nothing new dims
    swapdims(dims, newdims)
end

# Set things wrapped in dims
_set(dim::Dimension, wrapper::Dimension{<:DimSetters}) = _set(dim::Dimension, val(wrapper))
# Set the dim, checking the lookup
_set(dim::Dimension, newdim::Dimension) = _set(newdim, _set(val(dim), val(newdim)))
# Construct types
_set(dim::Dimension, ::Type{T}) where T = _set(dim, T())
_set(dim::Dimension, key::Symbol) = _set(dim, key2dim(key))
_set(dim::Dimension, dt::DimType) = basetypeof(dt)(val(dim))
_set(dim::Dimension, x) = rebuild(dim; val=_set(val(dim), x))
# Set the lookup
# Otherwise pass this on to set fields on the lookup
_set(dim::Dimension, x::LookupArrayTrait) = rebuild(dim, _set(lookup(dim), x))

# LookupArray

# _set(lookup::LookupArray, newlookup::LookupArray) = lookup
_set(lookup::AbstractCategorical, newlookup::AutoLookup) = begin
    lookup = _set(lookup, parent(newlookup))
    o = _set(order(lookup), order(newlookup))
    md = _set(metadata(lookup), metadata(newlookup))
    rebuild(lookup; order=o, metadata=md)
end
_set(lookup::LookupArray, newlookup::AbstractCategorical) = begin
    lookup = _set(lookup, parent(newlookup))
    o = _set(order(lookup), order(newlookup))
    md = _set(metadata(lookup), metadata(newlookup))
    rebuild(newlookup; data=parent(lookup), order=o, metadata=md)
end
_set(lookup::AbstractSampled, newlookup::AutoLookup) = begin
    # Update index
    lookup = _set(lookup, parent(newlookup))
    o = _set(order(lookup), order(newlookup))
    sa = _set(sampling(lookup), sampling(newlookup))
    sp = _set(span(lookup), span(newlookup))
    md = _set(metadata(lookup), metadata(newlookup))
    rebuild(lookup; data=parent(lookup), order=o, span=sp, sampling=sa, metadata=md)
end
_set(lookup::LookupArray, newlookup::AbstractSampled) = begin
    # Update each field separately. The old lookup may not have these fields, or may have
    # a subset with the rest being traits. The new lookup may have some auto fields.
    lookup = _set(lookup, parent(newlookup))
    o = _set(order(lookup), order(newlookup))
    sp = _set(span(lookup), span(newlookup))
    sa = _set(sampling(lookup), sampling(newlookup))
    md = _set(metadata(lookup), metadata(newlookup))
    # Rebuild the new lookup with the merged fields
    rebuild(newlookup; data=parent(lookup), order=o, span=sp, sampling=sa, metadata=md)
end
_set(lookup::LookupArray, newlookup::NoLookup{<:AutoIndex}) = NoLookup(axes(lookup, 1))
_set(lookup::LookupArray, newlookup::NoLookup) = newlookup

# Set the index
_set(lookup::LookupArray, index::Val) = rebuild(lookup; data=index)
_set(lookup::LookupArray, index::Colon) = lookup
_set(lookup::LookupArray, index::AbstractArray) = rebuild(lookup; data=index)
_set(lookup::LookupArray, index::AutoIndex) = lookup
_set(lookup::LookupArray, index::AbstractRange) =
    rebuild(lookup; data=_set(parent(lookup), index), order=_orderof(index))
# Update the Sampling lookup of Sampled dims - it must match the range.
_set(lookup::AbstractSampled, index::AbstractRange) = begin
    i = _set(parent(lookup), index)
    o = _orderof(index)
    sp = Regular(step(index))
    rebuild(lookup; data=i, span=sp, order=o)
end

_set(index::AbstractArray, newindex::AbstractArray) = newindex
_set(index::AbstractArray, newindex::AutoLookup) = index
_set(index::Colon, newindex::AbstractArray) = newindex

# Order
_set(lookup::LookupArray, neworder::Order) = rebuild(lookup; order=_set(order(lookup), neworder))
_set(lookup::NoLookup, neworder::Order) = lookup
_set(order::Order, neworder::Order) = neworder 
_set(order::Order, neworder::AutoOrder) = order

# Span
_set(lookup::AbstractSampled, span::Span) = rebuild(lookup; span=span)
_set(lookup::AbstractSampled, span::AutoSpan) = lookup
_set(span::Span, newspan::Span) = newspan
_set(span::Span, newspan::AutoSpan) = span

# Sampling
_set(lookup::AbstractSampled, newsampling::Sampling) =
    rebuild(lookup; sampling=_set(sampling(lookup), newsampling))
_set(lookup::AbstractSampled, sampling::AutoSampling) = lookup
_set(sampling::Sampling, newsampling::Sampling) = newsampling
_set(sampling::Sampling, newsampling::AutoSampling) = sampling

# Locus
_set(lookup::AbstractSampled, locus::Locus) =
    rebuild(lookup; sampling=_set(sampling(lookup), locus))
_set(sampling::Points, locus::Union{AutoLocus,Center}) = Points()
_set(sampling::Points, locus::Locus) = _locuserror()
_set(sampling::Intervals, locus::Locus) = Intervals(locus)
_set(sampling::Intervals, locus::AutoLocus) = sampling

# Metadata
_set(dim::Dimension, newmetadata::AllMetadata) = rebuild(dim, _set(lookup(dim), newmetadata))
_set(lookup::LookupArray, newmetadata::AllMetadata) = rebuild(lookup; metadata=newmetadata)
_set(metadata::AllMetadata, newmetadata::AllMetadata) = newmetadata

_set(x::Dimension, ::Nothing) = x
_set(::Nothing, x::Dimension) = x
_set(x, ::Nothing) = x
_set(::Nothing, x) = x
_set(::Nothing, ::Nothing) = nothing


@noinline _locuserror() = throw(ArgumentError("Can't set a locus for `Points` sampling other than `Center` - the index values are the exact points"))
@noinline _cantseterror(a, b) = throw(ArgumentError("Can not set any fields of $(typeof(a)) to $(typeof(b))"))
@noinline _onlydimerror(x) = throw(ArgumentError("Can only set $(typeof(x)) for a dimension. Specify which dimension you mean with `X => property`"))
@noinline _axiserr(a, b) = throw(ArgumentError("passed in axes $(axes(b)) do not match the currect axes $(axes(a))"))
@noinline _wrongdimserr(dims, w) = throw(ArgumentError("dim $(basetypeof(w))) not in $(map(basetypeof, dims))"))
@noinline _keyerr(ka, kb) = throw(ArgumentError("keys $ka and $kb do not match"))
