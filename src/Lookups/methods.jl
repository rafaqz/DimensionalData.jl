
# reverse
Base.reverse(lookup::NoLookup) = lookup
Base.reverse(lookup::AutoLookup) = lookup
function Base.reverse(lookup::AbstractCategorical)
    i = reverse(parent(lookup))
    o = reverse(order(lookup))
    rebuild(lookup; data=i, order=o)
end
function Base.reverse(lookup::AbstractSampled)
    i = reverse(parent(lookup))
    o = reverse(order(lookup))
    sp = reverse(span(lookup))
    rebuild(lookup; data=i, order=o, span=sp)
end

# Order
Base.reverse(::ReverseOrdered) = ForwardOrdered()
Base.reverse(::ForwardOrdered) = ReverseOrdered()
Base.reverse(o::Unordered) = Unordered()

# Span
Base.reverse(span::Irregular) = span
Base.reverse(span::Regular) = Regular(-step(span))
Base.reverse(span::Explicit) = Explicit(reverse(val(span), dims=2))
