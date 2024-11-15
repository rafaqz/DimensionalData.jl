"""
    shiftlocus(locus::Locus, x)

Shift the values of `x` from the current locus to the new locus.

We only shift `Sampled`, `Regular` or `Explicit`, `Intervals`. 
"""
function shiftlocus(locus::Locus, lookup::Lookup)
    samp = sampling(lookup)
    samp isa Intervals || error("Cannot shift locus of $(nameof(typeof(samp)))")
    newvalues = _shiftlocus(locus, lookup)
    newlookup = rebuild(lookup; data=newvalues)
    return set(newlookup, locus)
end

# Fallback - no shifting
_shiftlocus(locus::Locus, lookup::Lookup) = parent(lookup)
# Sampled
function _shiftlocus(locus::Locus, lookup::AbstractSampled)
    _shiftlocus(locus, span(lookup), sampling(lookup), lookup)
end
# TODO:
_shiftlocus(locus::Locus, span::Irregular, sampling::Sampling, lookup::Lookup) = parent(lookup)
# Sampled Regular
function _shiftlocus(destlocus::Center, span::Regular, sampling::Intervals, l::Lookup)
    if destlocus === locus(sampling)
        return parent(l)
    else
        offset = _offset(locus(sampling), destlocus)
        shift = ((parent(l) .+ abs(step(span))) .- parent(l)) .* offset
        return parent(l) .+ shift
    end
end
function _shiftlocus(destlocus::Locus, span::Regular, sampling::Intervals, lookup::Lookup)
    parent(lookup) .+ (abs(step(span)) * _offset(locus(sampling), destlocus))
end
# Sampled Explicit
_shiftlocus(::Start, span::Explicit, sampling::Intervals, lookup::Lookup) = val(span)[1, :]
_shiftlocus(::End, span::Explicit, sampling::Intervals, lookup::Lookup) = val(span)[2, :]
function _shiftlocus(destlocus::Center, span::Explicit, sampling::Intervals, lookup::Lookup)
    _shiftlocus(destlocus, locus(lookup), span, sampling, lookup)
end
_shiftlocus(::Center, ::Center, span::Explicit, sampling::Intervals, lookup::Lookup) = parent(lookup)
function _shiftlocus(::Center, ::Locus, span::Explicit, sampling::Intervals, lookup::Lookup)
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

maybeshiftlocus(locus::Locus, l::Lookup) = _maybeshiftlocus(locus, sampling(l), l)

_maybeshiftlocus(locus::Locus, sampling::Intervals, l::Lookup) = shiftlocus(locus, l)
_maybeshiftlocus(locus::Locus, sampling::Sampling, l::Lookup) = l

"""
    basetypeof(x) => Type

Get the "base" type of an object - the minimum required to
define the object without it's fields. By default this is the full
`UnionAll` for the type. But custom `basetypeof` methods can be
defined for types with free type parameters.

In DimensionalData this is primarily used for comparing `Dimension`s,
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
    sorted = issorted(A; rev=Lookups.isrev(indord), by=x -> x.left)
    return sorted ? indord : Unordered()
end
function orderof(A::AbstractArray)
    local sorted, indord
    # This is awful. But we don't know if we can
    # call `issorted` on the contents of `A`.
    # This may be resolved by: https://github.com/JuliaLang/julia/pull/37239
    try
        indord = _order(A)
        sorted = issorted(A; rev=Lookups.isrev(indord))
    catch
        sorted = false
    end
    return sorted ? indord : Unordered()
end

_order(A) = first(A) <= last(A) ? ForwardOrdered() : ReverseOrdered()
_order(A::AbstractArray{<:IntervalSets.Interval}) = first(A).left <= last(A).left ? ForwardOrdered() : ReverseOrdered()

@deprecate maybeshiftlocus maybeshiftlocus
@deprecate shiftlocus shiftlocus

# Remove objects of type T from a 
Base.@assume_effects :foldable _remove(::Type{T}, x, xs...) where T = (x, _remove(T, xs...)...)
Base.@assume_effects :foldable _remove(::Type{T}, ::T, xs...) where T = _remove(T, xs...)
Base.@assume_effects :foldable _remove(::Type) = ()
