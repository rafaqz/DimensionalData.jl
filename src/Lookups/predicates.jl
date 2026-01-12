# Define predicates directly on lookup traits
isregular(::Regular) = true
isregular(::Sampling) = false
isexplicit(::Explicit) = true
isexplicit(::Sampling) = false
isaligned(::Lookup) = false
isaligned(::Aligned) = true
issampled(::AbstractSampled) = true
issampled(::Lookup) = false
iscategorical(::AbstractCategorical) = true
iscategorical(::Lookup) = false
iscyclic(::AbstractCyclic) = true
iscyclic(::Lookup) = false
isnolookup(::Lookup) = false
isnolookup(::NoLookup) = true
isstart(::Start) = true
isstart(::Locus) = false
iscenter(::Center) = true
iscenter(::Locus) = false
isend(::End) = true
isend(::Locus) = false
isforward(::ForwardOrdered) = true
isforward(::Order) = false
isreverse(::ReverseOrdered) = true
isreverse(::Order) = false
isordered(::Ordered) = true
isordered(::Order) = false
isintervals(::Intervals) = true
isintervals(::Points) = false
ispoints(::Points) = true
ispoints(::Intervals) = false
hasinternaldimensions(::Lookup) = false
hasinternaldimensions(::Any) = false  # Fallback for non-Lookup types (e.g., raw arrays)

# Forward them from lookups
for f in (:isregular, :isexplicit)
    @eval $f(l::Lookup) = $f(span(l))
end
for f in (:isintervals, :ispoints)
    @eval $f(l::Lookup) = $f(sampling(l))
end
for f in (:isstart, :isend)
    @eval $f(l::AbstractSampled) = $f(locus(l))
    @eval $f(l::Lookup) = false
end
iscenter(l::AbstractSampled) = iscenter(locus(l))
iscenter(l::Lookup) = true

for f in (:isordered, :isforward, :isreverse)
    @eval $f(l::Lookup) = $f(order(l))
end
