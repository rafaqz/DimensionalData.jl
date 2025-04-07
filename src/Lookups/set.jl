abstract type Safety end
struct Safe <: Safety end
struct Unsafe <: Safety end

const LookupSetters = Union{AllMetadata,Lookup,LookupTrait,AbstractArray}

set(x, ::Type{T}) where T = set(x, T())
set(lookup::Lookup, x::LookupSetters) =_set(Safe(), lookup, x)
set(a::LookupTrait, b::LookupTrait) =_set(Safe(), a, b)
set(lookup::Lookup, ::Type{T}) where T =_set(Safe(), lookup, T())

unsafe_set(lookup::Lookup, x::LookupSetters) =_set(Unsafe(), lookup, x)
unsafe_set(a::LookupTrait, b::LookupTrait) =_set(Unsafe(), a, b)
unsafe_set(lookup::Lookup, ::Type{T}) where T =_set(Unsafe(), lookup, T())

# Set with no keywords or arguments does nothing
_set(::Safety, x) = x
_set(s::Safety, lookup::Lookup, newlookup::Lookup) = _set_lookup(s, lookup, newlookup)
_set(s::Safety, lookup::Lookup, newlookup::AbstractArray) = _set_lookup_parent(s, lookup, newlookup)
_set(s::Safety, lookup::Lookup, prop::LookupSetters) = _set_lookup_property(s, lookup, prop)
# Lookup values
_set(::Safety, values::AbstractArray, newvalues::AbstractArray) = newvalues
_set(::Safety, values::AbstractArray, newvalues::Colon) = values
_set(::Safety, values::Colon, newvalues::AbstractArray) = newvalues
_set(::Safety, values::Colon, newvalues::Colon) = values

_set_lookup(s::Safety, lookup::Lookup, newlookup::AutoLookup) = 
    _set_lookup_parent(s, lookup, parent(newlookup))
_set_lookup(s::Safety, lookup::AbstractCategorical, newlookup::AutoLookup) = begin
    # With autolookup we have to allow for missing fields and detect them
    l1 = _set(Unsafe(), lookup, order(newlookup))
    l2 =_set(Unsafe(), l1, parent(newlookup))
    l3 = _set(s, l2, order(newlookup))
    _set(s, l3, metadata(newlookup))
end
_set_lookup(s::Safety, lookup::AbstractSampled, newlookup::AutoLookup) = begin
    # With autolookup we have to allow for missing fields and detect them
    # First force the new order to avoid unnecessary reordering of arrays
    lookup2 =_set(Unsafe(), lookup, order(newlookup))
    # Then update lookup values
    lookup1 =_set(s, lookup, parent(newlookup))
    # Then set the order again in case it changed 
    lookup2 =_set(s, lookup, order(newlookup))
    # Then set the span
    lookup3 =_set(s, lookup, span(newlookup))
    # Then set traits that dont affect each other
    sa =_set(s, sampling(lookup3), sampling(newlookup))
    md =_set(s, metadata(lookup3), metadata(newlookup))
    rebuild(lookup3; sampling=sa, metadata=md)
end
_set_lookup(s::Safety, lookup::Lookup, newlookup::AbstractCategorical) = begin
    lookup =_set(Unsafe(), lookup, parent(newlookup))
    o =_set(s, order(lookup), order(newlookup))
    md =_set(s, metadata(lookup), metadata(newlookup))
    rebuild(newlookup; data=parent(lookup), order=o, metadata=md)
end
_set_lookup(s::Unsafe, lookup::Lookup, newlookup::AbstractSampled) = 
   _set_lookup_parent(s, lookup, parent(newlookup))
_set_lookup(s::Safety, lookup::Lookup, newlookup::AbstractSampled) = begin
    # Update each field separately. The old lookup may not have these fields, or may have
    # a subset with the rest being traits. The new lookup may have some auto fields.
    data =_set(s, parent(lookup), parent(newlookup))
    o =_set(s, order(lookup), order(newlookup))
    sp =_set(s, span(lookup), span(newlookup))
    sa =_set(s, sampling(lookup), sampling(newlookup))
    md =_set(s, metadata(lookup), metadata(newlookup))
    # Rebuild the new lookup with the merged fields
    rebuild(newlookup; data, order=o, span=sp, sampling=sa, metadata=md)
end
_set_lookup(::Safety, lookup::Lookup, newlookup::NoLookup{<:AutoValues}) = NoLookup(axes(lookup, 1))
_set_lookup(::Safety, lookup::Lookup, newlookup::AbstractNoLookup) = newlookup

# Set the lookup values
_set_lookup_parent(::Safety, lookup::AbstractCategorical, newlookup::AutoValues) = lookup
_set_lookup_parent(::Safety, lookup::Lookup, values::Colon) = lookup
_set_lookup_parent(::Safety, lookup::Lookup, values::AutoValues) = lookup
_set_lookup_parent(::Safety, lookup::Lookup, values::AbstractVector) = rebuild(lookup; data=values)
_set_lookup_parent(::Safe, lookup::AbstractCategorical, ::AutoValues) = lookup
_set_lookup_parent(s::Safe, lookup::AbstractCategorical, values::AbstractVector) =
    rebuild(lookup; data=_set(s, parent(lookup), values), order=orderof(values))
# Safe detects order and updates span
_set_lookup_parent(::Safe, lookup::AbstractSampled, ::AutoValues) = lookup
_set_lookup_parent(s::Safe, lookup::AbstractSampled, values::AbstractRange) = begin
    data =_set(s, parent(lookup), values)
    order = orderof(values)
    span = Regular(step(values))
    rebuild(lookup; data, span, order)
end
_set_lookup_parent(s::Safe, lookup::AbstractSampled, values::AbstractVector) = begin
    data =_set(s, parent(lookup), values)
    order = orderof(values)
    span = if sampling(lookup) isa Start
        Irregular((first(values), nothing))
    elseif sampling(lookup) isa End
        Irregular((nothing, last(values)))
    else
        Irregular((nothing, nothing))
    end
    return rebuild(lookup; data, span, order)
end

# Order
_set_lookup_property(::Safety, lookup::AbstractNoLookup, neworder::Order) = lookup
_set_lookup_property(::Safety, lookup::AbstractNoLookup, neworder::AutoOrder) = lookup
_set_lookup_property(::Safety, lookup::Lookup, neworder::AutoOrder) = lookup

# Unsafe leaves the lookup values as-is
_set_lookup_property(s::Unsafe, lookup::Lookup, neworder::Order) = 
    rebuild(lookup; order=_set(s, order(lookup), neworder))
_set_lookup_property(s::Unsafe, lookup::Lookup, neworder::AutoOrder) = 
    lookup
# For disambiguity
_set_lookup_property(::Unsafe, lookup::AbstractNoLookup, ::Order) = lookup
_set_lookup_property(::Unsafe, lookup::AbstractNoLookup, ::AutoOrder) = lookup
_set_lookup_property(::Safe, lookup::AbstractNoLookup, ::Order) = lookup
_set_lookup_property(::Safe, lookup::AbstractNoLookup, ::AutoOrder) = lookup
# Safe reorders them to match `neworder`
_set_lookup_property(::Safe, lookup::Lookup, neworder::Order) = 
    reorder(lookup, neworder)
_set_lookup_property(s::Safe, lookup::Lookup, neworder::AutoOrder) = 
    lookup
# Lookup Span
_set_lookup_property(::Safety, lookup::AbstractSampled, ::Irregular{AutoBounds}) = begin
    bnds = if parent(lookup) isa AutoValues || span(lookup) isa AutoSpan
        AutoBounds()
    else
        bounds(lookup)
    end
    rebuild(lookup; span=Irregular(bnds))
end
_set_lookup_property(s::Safety, lookup::AbstractSampled, ::Regular{AutoStep}) = begin
    stp = if span(lookup) isa AutoSpan || step(lookup) isa AutoStep
        if parent(lookup) isa AbstractRange
            step(parent(lookup))
        else
            AutoStep()
        end
    else
        step(lookup)
    end
    rebuild(lookup; span=Regular(stp))
end
# Lookup Span
_set_lookup_property(::Safety, lookup::AbstractSampled, span::Span) = rebuild(lookup; span=span)
_set_lookup_property(::Safety, lookup::AbstractSampled, span::AutoSpan) = lookup
# Lookup Sampling
# TODO does this need to fix bounds?
_set_lookup_property(s::Safety, lookup::AbstractSampled, newsampling::Sampling) =
    rebuild(lookup; sampling=_set(s, sampling(lookup), newsampling))
_set_lookup_property(::Safety, lookup::AbstractSampled, sampling::AutoSampling) = lookup
# Lookup Locus
_set_lookup_property(s::Unsafe, lookup::AbstractSampled, locus::Locus) =
    rebuild(lookup; sampling=_set(s, sampling(lookup), locus))
_set(::Safe, lookup::AbstractSampled, locus::Locus) = maybeshiftlocus(locus, lookup)
# Lookup Metadata
_set_lookup_property(::Safety, lookup::Lookup, newmetadata::AllMetadata) = 
    rebuild(lookup; metadata=newmetadata)

# Order
_set(::Safety, order::Order, neworder::Order) = neworder 
_set(::Safety, order::Order, neworder::AutoOrder) = order
# Span
_set(::Safety, span::Span, newspan::Span) = newspan
_set(::Safety, span::Span, newspan::AutoSpan) = span
# Sampling
_set(::Safety, sampling::Sampling, newsampling::Sampling) = newsampling
_set(::Safety, sampling::Sampling, newsampling::AutoSampling) = sampling
_set(s::Safety, sampling::Sampling, newsampling::Intervals) =
   _set(s, newsampling,_set(s, locus(sampling), locus(newsampling)))
# Locus
_set(::Safety, sampling::Points, locus::Union{AutoPosition,Center}) = Points()
_set(::Safety, sampling::Points, locus::Locus) = _locuserror()
_set(::Safety, sampling::Intervals, locus::Locus) = Intervals(locus)
_set(::Safety, sampling::Intervals, locus::AutoPosition) = sampling
_set(::Safety, locus::Locus, newlocus::Locus) = newlocus
_set(::Safety, locus::Locus, newlocus::AutoPosition) = locus
# Metadata
_set(::Safety, metadata::AllMetadata, newmetadata::AllMetadata) = newmetadata

# Other things error
_set(::Safety, A, x) = _cantseterror(A, x)

@noinline _locuserror() = throw(ArgumentError("Can't set a locus for `Points` sampling other than `Center` - the lookup values are the exact points"))
@noinline _cantseterror(a, b) = throw(ArgumentError("Can not set any fields of $(typeof(a)) to $(typeof(b))"))