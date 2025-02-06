abstract type Safety end
struct Safe <: Safety end
struct Unsafe <: Safety end

const LookupSetters = Union{AllMetadata,Lookup,LookupTrait,Nothing,AbstractArray}

set(lookup::Lookup, x::LookupSetters) = _set(Safe(), lookup, x)
set(lookup::Lookup, ::Type{T}) where T = _set(Safe(), lookup, T())
set(a::LookupTrait, b::LookupTrait) = _set(Safe(), a, b)

unsafe_set(lookup::Lookup, x::LookupSetters) = _set(Unsafe(), lookup, x)
unsafe_set(lookup::Lookup, ::Type{T}) where T = _set(Unsafe(), lookup, T())
unsafe_set(a::LookupTrait, b::LookupTrait) where T = _set(Unsafe(), a, b)

# Types are constructed
# Note: this is the only `_set` where `x` is untyped
_set(s::Safety, x, ::Type{T}) where T = _set(s, x, T())
# Set with no keywords or arguments does nothing
_set(::Safety, x) = x

_set(s::Unsafe, lookup::AbstractCategorical, newlookup::AutoLookup) =
    _set(s, lookup, parent(newlookup))
_set(::Safety, lookup::AbstractCategorical, newlookup::AutoValues) = lookup
_set(s::Safe, lookup::AbstractCategorical, newlookup::AutoLookup) = begin
    lookup = _set(Unsafe(), lookup, newlookup)
    o = _set(s, order(lookup), order(newlookup))
    md = _set(s, metadata(lookup), metadata(newlookup))
    rebuild(lookup; order=o, metadata=md)
end
_set(s::Unsafe, lookup::Lookup, newlookup::AbstractCategorical) =
    _set(s, lookup, parent(newlookup))
_set(s::Safe, lookup::Lookup, newlookup::AbstractCategorical) = begin
    lookup = _set(Unsafe(), lookup, newlookup)
    o = _set(s, order(lookup), order(newlookup))
    md = _set(s, metadata(lookup), metadata(newlookup))
    rebuild(newlookup; data=parent(lookup), order=o, metadata=md)
end
_set(s::Unsafe, lookup::AbstractSampled, newlookup::AutoLookup) =
    _set(s, lookup, parent(newlookup))
# _set(s::Safe, lookup::AbstractSampled, newlookup::AutoLookup) = begin
#     # Update lookup values
#     lookup = _set(Unsafe(), lookup, newlookup)
#     o = _set(s, order(lookup), order(newlookup))
#     sa = _set(s, sampling(lookup), sampling(newlookup))
#     sp = _set(s, span(lookup), span(newlookup))
#     md = _set(s, metadata(lookup), metadata(newlookup))
#     rebuild(lookup; data=parent(lookup), order=o, span=sp, sampling=sa, metadata=md)
# end
_set(s::Unsafe, lookup::Lookup, newlookup::AbstractSampled) = 
    _set(s, lookup, parent(newlookup))
_set(s::Safe, lookup::Lookup, newlookup::AbstractSampled) = begin
    # Update each field separately. The old lookup may not have these fields, or may have
    # a subset with the rest being traits. The new lookup may have some auto fields.
    lookup = _set(Unsafe(), lookup, newlookup)
    o = _set(s, order(lookup), order(newlookup))
    sp = _set(s, span(lookup), span(newlookup))
    sa = _set(s, sampling(lookup), sampling(newlookup))
    md = _set(s, metadata(lookup), metadata(newlookup))
    # Rebuild the new lookup with the merged fields
    rebuild(newlookup; data=parent(lookup), order=o, span=sp, sampling=sa, metadata=md)
end
_set(::Safety, lookup::AbstractArray, newlookup::NoLookup{<:AutoValues}) = NoLookup(axes(lookup, 1))
_set(::Safety, lookup::Lookup, newlookup::NoLookup{<:AutoValues}) = NoLookup(axes(lookup, 1))
_set(::Safety, lookup::Lookup, newlookup::NoLookup) = newlookup

# Set the lookup values
_set(::Safety, lookup::Lookup, values::Colon) = lookup
_set(::Safety, lookup::Lookup, values::AutoLookup) = lookup
# _set(::Unsafe, lookup::Lookup, values::AbstractArray) = rebuild(lookup; data=values)

_set(::Safety, lookup::Lookup, values::AutoValues) = lookup
# Need both for ambiguity
_set(::Safe, lookup::Lookup, values::AbstractVector) = rebuild(lookup; data=values)
_set(::Unsafe, lookup::Lookup, values::AbstractVector) = rebuild(lookup; data=values)
_set(s::Safe, lookup::AbstractCategorical, values::AbstractVector) =
    rebuild(lookup; data=_set(s, parent(lookup), values), order=orderof(values))
# Safe detects order and updates span
_set(s::Safe, lookup::AbstractSampled, values::AbstractRange) = begin
    data = _set(s, parent(lookup), values)
    order = orderof(values)
    span = Regular(step(values))
    rebuild(lookup; data, span, order)
end
_set(s::Safe, lookup::AbstractSampled, values::AbstractVector) = begin
    data = _set(s, parent(lookup), values)
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
_set(s::Safe, lookup::AbstractNoLookup, neworder::Order) = lookup
_set(s::Unsafe, lookup::AbstractNoLookup, neworder::Order) = lookup
# Unsafe leaves the lookup values as-is
_set(s::Unsafe, lookup::Lookup, neworder::Order) = 
    rebuild(lookup; order=_set(s, order(lookup), neworder))
_set(::Safe, lookup::Lookup, neworder::AutoOrder) = lookup
# Safe reorders them to match `neworder`
_set(::Safe, lookup::Lookup, neworder::Order) = reorder(lookup, neworder)
_set(s::Safety, order::Order, neworder::Order) = neworder 
_set(s::Safety, order::Order, neworder::AutoOrder) = order

# Span
_set(::Safety, lookup::AbstractSampled, ::Irregular{AutoBounds}) = begin
    bnds = if parent(lookup) isa AutoValues || span(lookup) isa AutoSpan
        AutoBounds()
    else
        bounds(lookup)
    end
    rebuild(lookup; span=Irregular(bnds))
end
_set(s::Safety, lookup::AbstractSampled, ::Regular{AutoStep}) = begin
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
_set(::Safety, lookup::AbstractSampled, span::Span) = rebuild(lookup; span=span)
_set(::Safety, lookup::AbstractSampled, span::AutoSpan) = lookup
_set(::Safety, span::Span, newspan::Span) = newspan
_set(::Safety, span::Span, newspan::AutoSpan) = span

# Sampling
# TODO does this need to fix bounds?
_set(s::Safety, lookup::AbstractSampled, newsampling::Sampling) =
    rebuild(lookup; sampling=_set(s, sampling(lookup), newsampling))
_set(::Safety, lookup::AbstractSampled, sampling::AutoSampling) = lookup
_set(::Safety, sampling::Sampling, newsampling::Sampling) = newsampling
_set(::Safety, sampling::Sampling, newsampling::AutoSampling) = sampling
_set(s::Safety, sampling::Sampling, newsampling::Intervals) =
    _set(s, newsampling, _set(s, locus(sampling), locus(newsampling)))

# Locus
_set(s::Unsafe, lookup::AbstractSampled, locus::Locus) =
    rebuild(lookup; sampling=_set(s, sampling(lookup), locus))
_set(::Safe, lookup::AbstractSampled, locus::Locus) = shiftlocus(l1, locus)
_set(::Safety, sampling::Points, locus::Union{AutoPosition,Center}) = Points()
_set(::Safety, sampling::Points, locus::Locus) = _locuserror()
_set(::Safety, sampling::Intervals, locus::Locus) = Intervals(locus)
_set(::Safety, sampling::Intervals, locus::AutoPosition) = sampling

_set(::Safety, locus::Locus, newlocus::Locus) = newlocus
_set(::Safety, locus::Locus, newlocus::AutoPosition) = locus

# Metadata
_set(::Safety, lookup::Lookup, newmetadata::AllMetadata) = 
    rebuild(lookup; metadata=newmetadata)
_set(::Safety, metadata::AllMetadata, newmetadata::AllMetadata) = newmetadata

# Lookup values
_set(::Safety, values::AbstractArray, newvalues::AbstractArray) = newvalues
_set(::Safety, values::AbstractArray, newvalues::AutoLookup) = values
_set(::Safety, values::AbstractArray, newvalues::Colon) = values
_set(::Safety, values::Colon, newvalues::AbstractArray) = newvalues
_set(::Safety, values::Colon, newvalues::Colon) = values

# Other things error
# _set(::Safety, A, x) = _cantseterror(A, x)

@noinline _locuserror() = throw(ArgumentError("Can't set a locus for `Points` sampling other than `Center` - the lookup values are the exact points"))
@noinline _cantseterror(a, b) = throw(ArgumentError("Can not set any fields of $(typeof(a)) to $(typeof(b))"))