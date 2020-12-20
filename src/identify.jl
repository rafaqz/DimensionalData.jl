
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
# No more identification required for some types
identify(mode::IndexMode, dimtype::Type, index) = mode
# AutoMode
identify(mode::AutoMode, dimtype::Type, index::AbstractArray{T}) where T = begin
    # A mixed type index is Categorical
    if isconcretetype(T)
        identify(Sampled(), dimtype, index)
    else
        identify(Categorical(), dimtype, index)
    end
end
identify(mode::AutoMode, dimtype::Type, index::AbstractArray{<:CategoricalEltypes}) =
    order(mode) isa AutoOrder ? Categorical(Unordered()) : Categorical(order(mode))
identify(mode::AutoMode, dimtype::Type, index::Val) =
    order(mode) isa AutoOrder ? Categorical(Unordered()) : Categorical(order(mode))
# Sampled
identify(mode::AbstractSampled, dimtype::Type, index) =
    rebuild(mode;
        order=identify(order(mode), dimtype, index),
        span=identify(span(mode), dimtype, index),
        sampling=identify(sampling(mode), dimtype, index)
    )
identify(order::Order, dimtype::Type, index) = order
identify(order::AutoOrder, dimtype::Type, index) = _orderof(index)
# Span
identify(span::AutoSpan, dimtype::Type, index::Union{AbstractArray,Val}) = Irregular()
identify(span::AutoSpan, dimtype::Type, index::AbstractRange) = Regular(step(index))
identify(span::Regular{AutoStep}, dimtype::Type, index::Union{AbstractArray,Val}) = _arraynosteperror()
identify(span::Regular, dimtype::Type, index::Union{AbstractArray,Val}) = span
identify(span::Regular{AutoStep}, dimtype::Type, index::AbstractRange) = Regular(step(index))
identify(span::Regular, dimtype::Type, index::AbstractRange) = begin
    step(span) isa Number && !(step(span) ≈ step(index)) && _steperror(index, span)
    span
end
identify(span::Irregular{AutoBounds}, dimtype, index) = Irregular(nothing, nothing)
identify(span::Irregular{<:Tuple}, dimtype, index) = span
identify(span::Explicit, dimtype, index) = span
# Sampling
identify(sampling::AutoSampling, dimtype::Type, index) = Points()
identify(sampling::Points, dimtype::Type, index) = sampling
identify(sampling::Intervals, dimtype::Type, index) =
    rebuild(sampling, identify(locus(sampling), dimtype, index))
# Locus
identify(locus::AutoLocus, dimtype::Type, index) = Center()
identify(locus::Locus, dimtype::Type, index) = locus


_orderof(index::AbstractUnitRange) = Ordered()
_orderof(index::AbstractRange) = Ordered(index=_indexorder(index))
_orderof(index::Val) = _detectorder(unwrap(index))
_orderof(index::AbstractArray) = _detectorder(index)

function _detectorder(index)
    local sorted, indord
    # This is awful. But we don't know if we can
    # call `issorted` on the contents of `index`.
    # This may be resolved by: https://github.com/JuliaLang/julia/pull/37239
    try
        indord = _indexorder(index)
        sorted = issorted(index; rev=isrev(indord))
    catch
        sorted = false
    end
    sorted ? Ordered(index=indord) : Unordered()
end

_indexorder(index) = first(index) <= last(index) ? ForwardIndex() : ReverseIndex()

@noinline _steperror(index, span) =
    throw(ArgumentError("mode step $(step(span)) does not match index step $(step(index))"))
@noinline _arraynosteperror() =
    throw(ArgumentError("`Regular` must specify `step` size with an index other than `AbstractRange`"))
