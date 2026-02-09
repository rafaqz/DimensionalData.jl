"""
    isregular(l)

Predicate that returns `true` if the lookup in `l` has a [`Regular`](@ref) [`Span`](@ref), false otherwise.
"""
function isregular end

"""
    isexplicit(l)

Predicate that returns `true` if the lookup in `l` has an [`Explicit`](@ref) [`Span`](@ref), false otherwise.
"""
function isexplicit end

"""
    isaligned(l)

Predicate that returns `true` if the lookup in `l` is an [`Aligned`](@ref) lookup, false otherwise.
"""
function isaligned end

"""
    issampled(l)

Predicate that returns `true` if the lookup in `l` is a [`Sampled`](@ref) lookup, false otherwise.
"""
function issampled end

"""
    iscategorical(l)

Predicate that returns `true` if the lookup in `l` is a [`Categorical`](@ref) lookup, false otherwise.
"""
function iscategorical end

"""
    iscyclic(l)

Predicate that returns `true` if the lookup in `l` is a [`Cyclic`](@ref) lookup, false otherwise.
"""
function iscyclic end

"""
    isnolookup(l)

Predicate that returns `true` if the lookup in `l` is a [`NoLookup`](@ref) lookup, false otherwise.
"""
function isnolookup end

"""
    isstart(l)

Predicate that returns `true` if the lookup in `l` is has a [`Start`](@ref) locus (it must be `Sampled` to use this), false otherwise.
"""
function isstart end

"""
    iscenter(l)

Predicate that returns `true` if the lookup in `l` is `Sampled` and has a [`Center`](@ref) locus (it must be `Sampled` to use this)1, false otherwise.
"""
function iscenter end

"""
    isend(l)

Predicate that returns `true` if the lookup in `l` has an [`End`](@ref) locus (it must be `Sampled` to use this), false otherwise.
"""
function isend end

"""
    isforward(l)

Predicate that returns `true` if the lookup in `l` is [`ForwardOrdered`](@ref), false otherwise.
"""
function isforward end

"""
    isreverse(l)

Predicate that returns `true` if the lookup in `l` is [`ReverseOrdered`](@ref), false otherwise.
"""
function isreverse end

"""
    isordered(l)

Predicate that returns `true` if the lookup in `l` is [`Ordered`](@ref), false otherwise.
"""
function isordered end

"""
    isintervals(l)

Predicate that returns `true` if the lookup in `l` is [`Intervals`](@ref), false otherwise.
"""
function isintervals end

"""
    ispoints(l)

Predicate that returns `true` if the lookup in `l` is [`Points`](@ref), false otherwise.
"""
function ispoints end

"""
    hasinternaldimensions(l)

Predicate that returns `true` if the lookup in `l` has internal dimensions, false otherwise.

Lookups like [`MergedLookup`](@ref) have internal dimensions, so do things like a GeometryLookup or ArrayLookup.

If you declare that your lookup has internal dimensions, you must:
- Implement a `bounds(lookup)` method that returns a tuple of 2-tuples - one for each internal dimension, in order of the internal dimensions.

Implementing this trait will also cause `bounds(lookup)` to return the bounds of the internal dimensions, and the same for `extent(lookup)`.
"""
function hasinternaldimensions end

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


# Docs
@doc """
    hasinternaldimensions(l::Lookup)::Bool

Return `true` if the lookup has internal dimensions, `false` otherwise.

If this is `true` for your lookup, then it must:
- Implement `DD.dims(lookup)::Tuple{Vararg{Dimension}}`
- Return a tuple of bounds, one per internal dimension, from `DD.bounds(lookup)`.  
  This means a length-`n` tuple of 2-tuples, where `n` is the number of internal dimensions.
"""
hasinternaldimensions