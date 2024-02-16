"""
    shiftlocus(locus::Locus, x)

Shift the index of `x` from the current locus to the new locus.

We only shift `Sampled`, `Regular` or `Explicit`, `Intervals`. 
"""
function shiftlocus(locus::Locus, lookup::LookupArray)
    samp = sampling(lookup)
    samp isa Intervals || error("Cannot shift locus of $(nameof(typeof(samp)))")
    newindex = _shiftindexlocus(locus, lookup)
    newlookup = rebuild(lookup; data=newindex)
    return set(newlookup, locus)
end

# Fallback - no shifting
_shiftindexlocus(locus::Locus, lookup::LookupArray) = index(lookup)
# Sampled
function _shiftindexlocus(locus::Locus, lookup::AbstractSampled)
    _shiftindexlocus(locus, span(lookup), sampling(lookup), lookup)
end
# TODO:
_shiftindexlocus(locus::Locus, span::Irregular, sampling::Sampling, lookup::LookupArray) = index(lookup)
# Sampled Regular
function _shiftindexlocus(destlocus::Center, span::Regular, sampling::Intervals, dim::LookupArray)
    if destlocus === locus(sampling)
        return index(dim)
    else
        offset = _offset(locus(sampling), destlocus)
        shift = ((index(dim) .+ abs(step(span))) .- index(dim)) .* offset
        return index(dim) .+ shift
    end
end
function _shiftindexlocus(destlocus::Locus, span::Regular, sampling::Intervals, lookup::LookupArray)
    index(lookup) .+ (abs(step(span)) * _offset(locus(sampling), destlocus))
end
# Sampled Explicit
_shiftindexlocus(::Start, span::Explicit, sampling::Intervals, lookup::LookupArray) = val(span)[1, :]
_shiftindexlocus(::End, span::Explicit, sampling::Intervals, lookup::LookupArray) = val(span)[2, :]
function _shiftindexlocus(destlocus::Center, span::Explicit, sampling::Intervals, lookup::LookupArray)
    _shiftindexlocus(destlocus, locus(lookup), span, sampling, lookup)
end
_shiftindexlocus(::Center, ::Center, span::Explicit, sampling::Intervals, lookup::LookupArray) = index(lookup)
function _shiftindexlocus(::Center, ::Locus, span::Explicit, sampling::Intervals, lookup::LookupArray)
    # A little complicated so that DateTime works
    (view(val(span), 2, :)  .- view(val(span), 1, :)) ./ 2 .+ view(val(span), 1, :)
end

_offset(::Start, ::Center) = 0.5
_offset(::Start, ::End) = 1
_offset(::Center, ::Start) = -0.5
_offset(::Center, ::End) = 0.5
_offset(::End, ::Start) = -1
_offset(::End, ::Center) = -0.5
_offset(::T, ::T) where T<:Locus = 0

maybeshiftlocus(locus::Locus, l::LookupArray) = _maybeshiftlocus(locus, sampling(l), l)

_maybeshiftlocus(locus::Locus, sampling::Intervals, l::LookupArray) = shiftlocus(locus, l)
_maybeshiftlocus(locus::Locus, sampling::Sampling, l::LookupArray) = l

"""
    basetypeof(x) => Type

Get the "base" type of an object - the minimum required to
define the object without it's fields. By default this is the full
`UnionAll` for the type. But custom `basetypeof` methods can be
defined for types with free type parameters.

In DimensionalData this is primariliy used for comparing `Dimension`s,
where `Dim{:x}` is different from `Dim{:y}`.
"""
@inline basetypeof(x::T) where T = basetypeof(T)
@generated function basetypeof(::Type{T}) where T
    if T isa Union
        T
    else
        getfield(parentmodule(T), nameof(T))
    end
end

# unwrap
# Unwrap Val and Type{Val}, or return unchanged
unwrap(::Val{X}) where X = X
unwrap(::Type{Val{X}}) where X = X
unwrap(x) = x

# orderof
# Detect the order of an abstract array
orderof(A::AbstractUnitRange) = ForwardOrdered()
orderof(A::AbstractRange) = _order(A)
function orderof(A::AbstractArray{<:IntervalSets.Interval})
    indord = _order(A)
    sorted = issorted(A; rev=LookupArrays.isrev(indord), by=x -> x.left)
    return sorted ? indord : Unordered()
end
function orderof(A::AbstractArray)
    local sorted, indord
    # This is awful. But we don't know if we can
    # call `issorted` on the contents of `A`.
    # This may be resolved by: https://github.com/JuliaLang/julia/pull/37239
    try
        indord = _order(A)
        sorted = issorted(A; rev=LookupArrays.isrev(indord))
    catch
        sorted = false
    end
    return sorted ? indord : Unordered()
end

_order(A) = first(A) <= last(A) ? ForwardOrdered() : ReverseOrdered()
_order(A::AbstractArray{<:IntervalSets.Interval}) = first(A).left <= last(A).left ? ForwardOrdered() : ReverseOrdered()
