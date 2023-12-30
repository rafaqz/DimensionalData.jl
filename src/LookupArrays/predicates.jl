# Define predicates directly on lookup traits
isregular(::Regular) = true
isregular(::Sampling) = false
isexplicit(::Explicit) = true
isexplicit(::Sampling) = false
issampled(::AbstractSampled) = true
issampled(::LookupArray) = false
iscategorical(::AbstractCategorical) = true
iscategorical(::LookupArray) = false
iscyclic(::AbstractCyclic) = true
iscyclic(::LookupArray) = false
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

# Forward them from lookups
for f in (:isregular, :isexplicit)
    @eval $f(l::LookupArray) = $f(span(l))
end
for f in (:isintervals, :ispoints)
    @eval $f(l::LookupArray) = $f(sampling(l))
end
for f in (:isstart, :isend)
    @eval $f(l::AbstractSampled) = $f(locus(l))
    @eval $f(l::LookupArray) = false
end
iscenter(l::AbstractSampled) = iscenter(locus(l))
iscenter(l::LookupArray) = true

for f in (:isordered, :isforward, :isreverse)
    @eval $f(l::LookupArray) = $f(order(l))
end
