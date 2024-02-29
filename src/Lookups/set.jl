const LookupSetters = Union{AllMetadata,Lookup,LookupTrait,Nothing,AbstractArray}
set(lookup::Lookup, x::LookupSetters) = _set(lookup, x)

# _set(lookup::Lookup, newlookup::Lookup) = lookup
_set(lookup::AbstractCategorical, newlookup::AutoLookup) = begin
    lookup = _set(lookup, parent(newlookup))
    o = _set(order(lookup), order(newlookup))
    md = _set(metadata(lookup), metadata(newlookup))
    rebuild(lookup; order=o, metadata=md)
end
_set(lookup::Lookup, newlookup::AbstractCategorical) = begin
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
_set(lookup::Lookup, newlookup::AbstractSampled) = begin
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
_set(lookup::AbstractArray, newlookup::NoLookup{<:AutoIndex}) = NoLookup(axes(lookup, 1))
_set(lookup::Lookup, newlookup::NoLookup{<:AutoIndex}) = NoLookup(axes(lookup, 1))
_set(lookup::Lookup, newlookup::NoLookup) = newlookup

# Set the index
_set(lookup::Lookup, index::Val) = rebuild(lookup; data=index)
_set(lookup::Lookup, index::Colon) = lookup
_set(lookup::Lookup, index::AutoLookup) = lookup
_set(lookup::Lookup, index::AbstractArray) = rebuild(lookup; data=index)

_set(lookup::Lookup, index::AutoIndex) = lookup
_set(lookup::Lookup, index::AbstractRange) =
    rebuild(lookup; data=_set(parent(lookup), index), order=orderof(index))
# Update the Sampling lookup of Sampled dims - it must match the range.
_set(lookup::AbstractSampled, index::AbstractRange) = begin
    i = _set(parent(lookup), index)
    o = orderof(index)
    sp = Regular(step(index))
    rebuild(lookup; data=i, span=sp, order=o)
end

# Order
_set(lookup::Lookup, neworder::Order) = rebuild(lookup; order=_set(order(lookup), neworder))
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
_set(sampling::Sampling, newsampling::Intervals) =
    _set(newsampling, _set(locus(sampling), locus(newsampling)))

# Locus
_set(lookup::AbstractSampled, locus::Locus) =
    rebuild(lookup; sampling=_set(sampling(lookup), locus))
_set(sampling::Points, locus::Union{AutoLocus,Center}) = Points()
_set(sampling::Points, locus::Locus) = _locuserror()
_set(sampling::Intervals, locus::Locus) = Intervals(locus)
_set(sampling::Intervals, locus::AutoLocus) = sampling

_set(locus::Locus, newlocus::Locus) = newlocus
_set(locus::Locus, newlocus::AutoLocus) = locus

# Metadata
_set(lookup::Lookup, newmetadata::AllMetadata) = rebuild(lookup; metadata=newmetadata)
_set(metadata::AllMetadata, newmetadata::AllMetadata) = newmetadata

# Index
_set(index::AbstractArray, newindex::AbstractArray) = newindex
_set(index::AbstractArray, newindex::AutoLookup) = index
_set(index::AbstractArray, newindex::Colon) = index
_set(index::Colon, newindex::AbstractArray) = newindex
_set(index::Colon, newindex::Colon) = index

_set(A, x) = _cantseterror(A, x)

@noinline _locuserror() = throw(ArgumentError("Can't set a locus for `Points` sampling other than `Center` - the index values are the exact points"))
@noinline _cantseterror(a, b) = throw(ArgumentError("Can not set any fields of $(typeof(a)) to $(typeof(b))"))
