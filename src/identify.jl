
"""
    identify(indexmode, index)

Identify an `IndexMode` and its fields from the index content 
and the existing `IndexMode`.

These methods guess which mode is most appropriate, encoding information
about the index in types that can later be used for dispatch. They also let
you fill in part of the information you need to specify, and guess the rest.

An example of the usefulness of identifying index traits up-front is if we 
check that the index is ordered, we can be sure it remains ordered
unless it is indexed with a `Vector`. This means we will always use the
correct `searchsorted` method for it.
"""
function identify end

identify(IM::Type{<:IndexMode}, dimtype::Type, index) =
    identify(IM(), dimtype, index)

# No more identification required for some types
identify(mode::IndexMode, dimtype::Type, index) = mode

# Auto
identify(mode::Auto, dimtype::Type, index::AbstractArray) =
    identify(Sampled(), dimtype, index)
identify(mode::Auto, dimtype::Type, index::AbstractArray{<:CategoricalEltypes}) =
    order(mode) isa AutoOrder ? Categorical(Unordered()) : Categorical(order(mode))
identify(mode::Auto, dimtype::Type, index::Val) =
    order(mode) isa AutoOrder ? Categorical(Unordered()) : Categorical(order(mode))

# Sampled
identify(mode::AbstractSampled, dimtype::Type, index) = begin
    mode = rebuild(mode;
        order=identify(order(mode), dimtype, index),
        span=identify(span(mode), dimtype, index),
        sampling=identify(sampling(mode), dimtype, index)
    )
end

# Order
identify(order::Order, dimtype::Type, index) = order
identify(order::AutoOrder, dimtype::Type, index) = _orderof(index)

_orderof(index::AbstractUnitRange) = Ordered()
_orderof(index::AbstractRange) = Ordered(index=_indexorder(index))
_orderof(index::Val) = _detectorder(unwrap(index))
_orderof(index::AbstractArray) = _detectorder(index)

function _detectorder(index)
    # This is awful. But we don't know if we can
    # call `issorted` on the contents of `index`.
    local sorted
    local indord 
    try
        indord = _indexorder(index)
        sorted = issorted(index; rev=isrev(indord))
    catch
        sorted = false
    end
    sorted ? Ordered(index=indord) : Unordered()
end

_indexorder(index) =
    first(index) <= last(index) ? ForwardIndex() : ReverseIndex()

# Span
identify(span::AutoSpan, dimtype::Type, index::Union{AbstractArray,Val}) =
    Irregular()
identify(span::AutoSpan, dimtype::Type, index::AbstractRange) =
    Regular(step(index))
identify(span::Regular{AutoStep}, dimtype::Type, index::Union{AbstractArray,Val}) =
    throw(ArgumentError("`Regular` must specify `step` size with an index other than `AbstractRange`"))
identify(span::Regular, dimtype::Type, index::Union{AbstractArray,Val}) =
    span
identify(span::Regular{AutoStep}, dimtype::Type, index::AbstractRange) =
    Regular(step(index))
identify(span::Regular, dimtype::Type, index::AbstractRange) = begin
    step(span) isa Number && !(step(span) ≈ step(index)) && 
        throw(ArgumentError("mode step $(step(span)) does not match index step $(step(index))"))
    span
end
identify(span::Irregular{Nothing}, dimtype, index) =
    if length(index) > 1
        bound1 = index[1] - (index[2] - index[1]) / 2
        bound2 = index[end] + (index[end] - index[end-1]) / 2
        Irregular(sortbounds(bound1, bound2))
    else
        Irregular(nothing, nothing)
    end
identify(span::Irregular{<:Tuple}, dimtype, index) = span

# Sampling
identify(sampling::AutoSampling, dimtype::Type, index) = Points()
identify(sampling::Points, dimtype::Type, index) = sampling
identify(sampling::Intervals, dimtype::Type, index) =
    rebuild(sampling, identify(locus(sampling), dimtype, index))

# Locus
identify(locus::AutoLocus, dimtype::Type, index) = Center()
identify(locus::Locus, dimtype::Type, index) = locus
