abstract type Safety end
struct Safe <: Safety end
struct Unsafe <: Safety end

const LookupSetters = Union{AllMetadata,Lookup,LookupTrait,Nothing,AbstractArray}

set(lookup::Lookup, x::LookupSetters) =__set(Safe(), lookup, x)
set(a::LookupTrait, b::LookupTrait) =__set(Safe(), a, b)
set(lookup::Lookup, ::Type{T}) where T =__set(Safe(), lookup, T())

unsafe_set(lookup::Lookup, x::LookupSetters) =__set(Unsafe(), lookup, x)
unsafe_set(a::LookupTrait, b::LookupTrait) =__set(Unsafe(), a, b)
unsafe_set(lookup::Lookup, ::Type{T}) where T =__set(Unsafe(), lookup, T())

# Types are constructed
# Note: this is the only `_set` where `x` is untyped
__set(s::Safety, x, ::Type{T}) where T =__set(s, x, T())
__set(s::Safety, x, ::Type{T}) where T =__set(s, x, T())
# Set with no keywords or arguments does nothing
__set(::Safety, x) = x

__set(s::Unsafe, lookup::AbstractCategorical, newlookup::AutoLookup) =
    __set(s, lookup, parent(newlookup))
__set(::Safe, lookup::AbstractCategorical, newlookup::AutoValues) = lookup
__set(::Unsafe, lookup::AbstractCategorical, newlookup::AutoValues) = lookup
__set(s::Safe, lookup::AbstractCategorical, newlookup::AutoLookup) = begin
    lookup =__set(Unsafe(), lookup, newlookup)
    o = __set(s, order(lookup), order(newlookup))
    md = __set(s, metadata(lookup), metadata(newlookup))
    rebuild(lookup; order=o, metadata=md)
end
__set(s::Unsafe, lookup::Lookup, newlookup::AbstractCategorical) =
   __set(s, lookup, parent(newlookup))
__set(s::Safe, lookup::Lookup, newlookup::AbstractCategorical) = begin
    lookup =__set(Unsafe(), lookup, newlookup)
    o =__set(s, order(lookup), order(newlookup))
    md =__set(s, metadata(lookup), metadata(newlookup))
    rebuild(newlookup; data=parent(lookup), order=o, metadata=md)
end
__set(s::Unsafe, lookup::AbstractSampled, newlookup::AutoLookup) =
   __set(s, lookup, parent(newlookup))
#__set(s::Safe, lookup::AbstractSampled, newlookup::AutoLookup) = begin
#     # Update lookup values
#     lookup =__set(Unsafe(), lookup, newlookup)
#     o =__set(s, order(lookup), order(newlookup))
#     sa =__set(s, sampling(lookup), sampling(newlookup))
#     sp =__set(s, span(lookup), span(newlookup))
#     md =__set(s, metadata(lookup), metadata(newlookup))
#     rebuild(lookup; data=parent(lookup), order=o, span=sp, sampling=sa, metadata=md)
# end
__set(s::Unsafe, lookup::Lookup, newlookup::AbstractSampled) = 
   __set(s, lookup, parent(newlookup))
__set(s::Safe, lookup::Lookup, newlookup::AbstractSampled) = begin
    # Update each field separately. The old lookup may not have these fields, or may have
    # a subset with the rest being traits. The new lookup may have some auto fields.
    lookup =__set(Unsafe(), lookup, newlookup)
    o =__set(s, order(lookup), order(newlookup))
    sp =__set(s, span(lookup), span(newlookup))
    sa =__set(s, sampling(lookup), sampling(newlookup))
    md =__set(s, metadata(lookup), metadata(newlookup))
    # Rebuild the new lookup with the merged fields
    rebuild(newlookup; data=parent(lookup), order=o, span=sp, sampling=sa, metadata=md)
end
for T in (:Safe, :Unsafe)
    @eval __set(::$T, lookup::AbstractArray, newlookup::NoLookup{<:AutoValues}) = NoLookup(axes(lookup, 1))
    @eval __set(::$T, lookup::Lookup, newlookup::NoLookup{<:AutoValues}) = NoLookup(axes(lookup, 1))
    @eval __set(::$T, lookup::Lookup, newlookup::NoLookup) = newlookup
end

# Set the lookup values
__set(::Safety, lookup::Lookup, values::Colon) = lookup
__set(::Safety, lookup::Lookup, values::AutoLookup) = lookup
#__set(::Unsafe, lookup::Lookup, values::AbstractArray) = rebuild(lookup; data=values)

__set(::Safe, lookup::Lookup, values::AutoValues) = lookup
__set(::Unsafe, lookup::Lookup, values::AutoValues) = lookup

# Need both for ambiguity
__set(::Safety, lookup::Lookup, values::AbstractVector) = rebuild(lookup; data=values)
__set(s::Safe, lookup::AbstractCategorical, values::AbstractVector) =
    rebuild(lookup; data=_set(s, parent(lookup), values), order=orderof(values))
# Safe detects order and updates span
__set(s::Safe, lookup::AbstractSampled, values::AbstractRange) = begin
    data =__set(s, parent(lookup), values)
    order = orderof(values)
    span = Regular(step(values))
    rebuild(lookup; data, span, order)
end
__set(s::Safe, lookup::AbstractSampled, values::AbstractVector) = begin
    data =__set(s, parent(lookup), values)
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
__set(s::Safe, lookup::AbstractNoLookup, neworder::Order) = lookup
__set(s::Unsafe, lookup::AbstractNoLookup, neworder::Order) = lookup
# Unsafe leaves the lookup values as-is
__set(s::Unsafe, lookup::Lookup, neworder::Order) = 
    rebuild(lookup; order=_set(s, order(lookup), neworder))
__set(::Safe, lookup::Lookup, neworder::AutoOrder) = lookup
# Safe reorders them to match `neworder`
__set(::Safe, lookup::Lookup, neworder::Order) = reorder(lookup, neworder)
__set(s::Safety, order::Order, neworder::Order) = neworder 
__set(s::Safety, order::Order, neworder::AutoOrder) = order

# Span
__set(::Safety, lookup::AbstractSampled, ::Irregular{AutoBounds}) = begin
    bnds = if parent(lookup) isa AutoValues || span(lookup) isa AutoSpan
        AutoBounds()
    else
        bounds(lookup)
    end
    rebuild(lookup; span=Irregular(bnds))
end
__set(s::Safety, lookup::AbstractSampled, ::Regular{AutoStep}) = begin
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
__set(::Safety, lookup::AbstractSampled, span::Span) = rebuild(lookup; span=span)
__set(::Safety, lookup::AbstractSampled, span::AutoSpan) = lookup
__set(::Safety, span::Span, newspan::Span) = newspan
__set(::Safety, span::Span, newspan::AutoSpan) = span

# Sampling
# TODO does this need to fix bounds?
__set(s::Safety, lookup::AbstractSampled, newsampling::Sampling) =
    rebuild(lookup; sampling=_set(s, sampling(lookup), newsampling))
__set(::Safety, lookup::AbstractSampled, sampling::AutoSampling) = lookup
__set(::Safety, sampling::Sampling, newsampling::Sampling) = newsampling
__set(::Safety, sampling::Sampling, newsampling::AutoSampling) = sampling
__set(s::Safety, sampling::Sampling, newsampling::Intervals) =
   __set(s, newsampling,__set(s, locus(sampling), locus(newsampling)))

# Locus
__set(s::Unsafe, lookup::AbstractSampled, locus::Locus) =
    rebuild(lookup; sampling=_set(s, sampling(lookup), locus))
__set(::Safe, lookup::AbstractSampled, locus::Locus) = shiftlocus(l1, locus)
__set(::Safety, sampling::Points, locus::Union{AutoPosition,Center}) = Points()
__set(::Safety, sampling::Points, locus::Locus) = _locuserror()
__set(::Safety, sampling::Intervals, locus::Locus) = Intervals(locus)
__set(::Safety, sampling::Intervals, locus::AutoPosition) = sampling

__set(::Safety, locus::Locus, newlocus::Locus) = newlocus
__set(::Safety, locus::Locus, newlocus::AutoPosition) = locus

# Metadata
__set(::Safety, lookup::Lookup, newmetadata::AllMetadata) = 
    rebuild(lookup; metadata=newmetadata)
__set(::Safety, metadata::AllMetadata, newmetadata::AllMetadata) = newmetadata

# Lookup values
__set(::Safety, values::AbstractArray, newvalues::AbstractArray) = newvalues
__set(::Safety, values::AbstractArray, newvalues::AutoLookup) = values
__set(::Safety, values::AbstractArray, newvalues::Colon) = values
__set(::Safety, values::Colon, newvalues::AbstractArray) = newvalues
__set(::Safety, values::Colon, newvalues::Colon) = values

# Other things error
#__set(::Safety, A, x) = _cantseterror(A, x)

@noinline _locuserror() = throw(ArgumentError("Can't set a locus for `Points` sampling other than `Center` - the lookup values are the exact points"))
@noinline _cantseterror(a, b) = throw(ArgumentError("Can not set any fields of $(typeof(a)) to $(typeof(b))"))