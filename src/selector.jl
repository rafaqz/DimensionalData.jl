"""
Selectors indicate that passed values are not the array indices, but values to
be selected from the dimension index, such as `DateTime` objects for a `Ti` dimension.
"""
abstract type Selector{T} end

const SelectorOrStandard = Union{Selector, StandardIndices}

val(m::Selector) = m.val
rebuild(sel::Selector, val) = basetypeof(sel)(val)

# Selector indexing without dim wrappers. Must be in the right order!
Base.@propagate_inbounds Base.getindex(a::AbDimArray, I::Vararg{SelectorOrStandard}) =
    getindex(a, sel2indices(a, I)...)
Base.@propagate_inbounds Base.setindex!(a::AbDimArray, x, I::Vararg{SelectorOrStandard}) =
    setindex!(a, x, sel2indices(a, I)...)
Base.view(a::AbDimArray, I::Vararg{SelectorOrStandard}) =
    view(a, sel2indices(a, I)...)

"""
    At(x; atol=nothing, rtol=nothing)

Selector that exactly matches the value on the passed-in dimensions, or throws an error.
For ranges and arrays, every intermediate value must match an existing value - 
not just the end points.

`atol` and `rtol` are passed to `isapprox`.
"""
struct At{T,A,R} <: Selector{T}
    val::T
    atol::A
    rtol::R
end
At(val::Union{Number,AbstractArray{<:Number},Tuple{<:Number,Vararg}};
   atol=zero(eltype(val)),
   rtol=(atol > zero(eltype(val)) ? zero(rtol) : Base.rtoldefault(eltype(val)))
  ) = At{typeof.((val, atol, rtol))...}(val, atol, rtol)
At(val; atol=nothing, rtol=nothing) =
    At{typeof.((val, atol, rtol))...}(val, atol, rtol)

atol(sel::At) = sel.atol
rtol(sel::At) = sel.rtol

"""
    Near(x)

Selector that selects the nearest index.
With [`PointSampling`](@ref) this is simply the index nearest to the
contained value, however with [`IntervalSampling`](@ref) it is the interval
_center_ nearest to the contained value. This will be offset from the
index value for [`Start`](@ref) and [`End`](@ref) loci.
"""
struct Near{T} <: Selector{T}
    val::T
end

"""
    Contains(x)

Selector that selects the interval the value is contained by. If the
interval is not present in the index, an error will be thrown.

Can only be used for [`IntervalSampling`](@ref) or [`CategoricalIndex`](@ref).
"""
struct Contains{T} <: Selector{T}
    val::T
end

"""
    Between(a, b)

Selector that retreive all indices located between 2 values.

For [`IntervalSampling`](@ref) the whole interval must be lie between the
values. For [`PointSampling`](@ref) the points must fall between
the 2 values. These different sampling traits will often give different
results with the same index and values - this is the intended behaviour.
"""
struct Between{T<:Union{Tuple{Any,Any},Nothing}} <: Selector{T}
    val::T
end
Between(args...) = Between{typeof(args)}(args)
Between(x::Tuple) = Between{typeof(x)}(x)

# Get the dims in the same order as the indexmode
# This would be called after RegularIndex and/or CategoricalIndex
# dimensions are removed
dims2indices(mode::TransformedIndex, dims::Tuple, lookups::Tuple, emptyval) =
    sel2indices(mode, dims, map(val, permutedims(dimz, dims(mode))))

sel2indices(A::AbstractArray, lookup) = sel2indices(dims(A), lookup)
sel2indices(dims::Tuple, lookup) = sel2indices(dims, (lookup,))
sel2indices(dims::Tuple, lookup::Tuple) =
    map((d, l) -> sel2indices(l, indexmode(d), d), dims, lookup)

# First filter based on rough selector properties -----------------

# Standard indices are just returned
sel2indices(sel::StandardIndices, ::IndexMode, ::Dimension) = sel
# Vectors are mapped
sel2indices(sel::Selector{<:AbstractVector}, mode::IndexMode, dim::Dimension) =
    map(v -> sel2indices(mode, dim, rebuild(sel, v)), val(sel))
sel2indices(sel::Selector, mode::IndexMode, dim::Dimension) =
    sel2indices(mode, dim, sel)

# Then filter based on IndexMode -----------------

# NoIndex
# This just converts the selector to standard indices. Implemented just
# so the Selectors actually work, not because what they do is useful or interesting.
sel2indices(mode::NoIndex, dim::Dimension, sel::Union{At,Near,Contains}) = val(sel)
sel2indices(mode::NoIndex, dim::Dimension, sel::Union{Between}) =
    val(sel)[1]:val(sel)[2]

# CategoricalIndex
sel2indices(mode::CategoricalIndex, dim::Dimension, sel::Selector) =
    if sel isa Union{Contains,Near}
        sel2indices(PointSampling(), mode, dim, At(val(sel)))
    else
        sel2indices(PointSampling(), mode, dim, sel)
    end

# SampledIndex
sel2indices(mode::SampledIndex, dim::Dimension, sel::Selector) =
    sel2indices(sampling(mode), mode, dim, sel)

# For SampledIndex filter based on sampling type and selector -----------------

# At selector
sel2indices(::Sampling, mode::IndexMode, dim::Dimension, sel::At) = at(dim, sel)

# Near selector
sel2indices(::Sampling, mode::IndexMode, dim::Dimension, sel::Near) = begin
    if span(mode) isa IrregularSpan && locus(mode) isa Union{Start,End}
        error("Near is not implemented for IrregularSpan with Start or End loci. Use Contains")
    end
    near(dim, Near(val(sel)))
end

# Contains selector
sel2indices(::PointSampling, mode::T, dim::Dimension, sel::Contains) where T =
    throw(ArgumentError("`Contains` has no meaning with `PointSampling`. Use `Near`"))
sel2indices(::IntervalSampling, mode::IndexMode, dim::Dimension, sel::Contains) =
    contains(dim, sel)

# Between selector
sel2indices(sampling::Sampling, mode::IndexMode, dim::Dimension, sel::Between{<:Tuple}) =
    between(sampling, dim, sel)


# Transformed IndexMode

# We use the transformation from the first TransformedIndex dim.
# In practice the others could be empty.
sel2indices(indexmodess::Tuple{Vararg{<:TransformedIndex}}, dims::DimTuple,
            sel::Tuple{Vararg{<:Selector}}) =
    map(_to_int, sel, val(dims[1])([map(val, sel)...]))

_to_int(::At, x) = convert(Int, x)
_to_int(::Near, x) = round(Int, x)

# Do the input values need some kind of scalar conversion?
# what is the scale of these lookup matrices?
# sel2indices(mode::LookupIndex, sel::Tuple{Vararg{At}}) =
    # lookup(mode)[map(val, sel)...]


at(dim::Dimension, sel::At) =
    relate(dim, at(dim, val(sel), atol(sel), rtol(sel)))
at(dim, selval, atol::Nothing, rtol::Nothing) = begin
    i = findfirst(x -> x == selval, val(dim))
    i == nothing && throw(ArgumentError("$selval not found in $dim"))
    return i
end
at(dim, selval, atol, rtol) = begin
    # This is not particularly efficient. It should be separated
    # out for unordered dims and otherwise treated as an ordered list.
    i = findfirst(x -> isapprox(x, selval; atol=atol, rtol=rtol), val(dim))
    i == nothing && throw(ArgumentError("$selval not found in $dim"))
    return i
end


near(dim::Dimension, sel) =
    relate(dim, near(locus(indexmode(dim)), indexorder(dim), dim, sel))
near(::Locus, ::Unordered, dim, sel) =
    throw(ArgumentError("`Near` has no meaning in an `Unordered` index"))
# Start is just offset Center
near(::Start, ord::Order, dim, sel) =
    near(Center(), ord, dim, Near(val(sel) - abs(step(dim)) / 2))
near(::Center, ::Forward, dim, sel) = begin
    selval = val(sel)
    i = _inbounds(_searchfirst(dim, selval), dim)
    if i <= firstindex(dim)
        firstindex(dim)
    else
        abs(dim[i] - selval) <= abs(dim[i - 1] - selval) ? i : i - 1
    end
end
near(::Center, ::Reverse, dim, sel) = begin
    selval = val(sel)
    i = _inbounds(_searchlast(dim, selval), dim)
    if i >= lastindex(dim)
        lastindex(dim)
    else
        abs(dim[i] - selval) <= abs(dim[i + 1] - selval) ? i : i + 1
    end
end
# End is offset and backwards.
near(::End, ::Forward, dim, sel) = begin
    selval = val(sel) + step(dim) / 2
    i = _inbounds(_searchfirst(dim, selval), dim)
    if i <= firstindex(dim)
        firstindex(dim)
    else
        abs(dim[i] - selval) < abs(dim[i - 1] - selval) ? i : i - 1
    end
end
near(::End, ::Reverse, dim, sel) = begin
    selval = val(sel) - step(dim) / 2
    i = _inbounds(_searchlast(dim, selval), dim)
    if i >= lastindex(dim)
        lastindex(dim)
    else
        abs(dim[i] - selval) < abs(dim[i + 1] - selval) ? i : i + 1
    end
end


contains(dim::Dimension, sel::Selector) =
    relate(dim, contains(indexmode(dim), dim, sel))
contains(mode::AbstractSampledIndex, dim, sel) =
    contains(span(mode), locus(mode), sampling(mode), indexorder(mode), mode, dim, sel)
contains(::Any, ::Any, ::PointSampling, ord, mode, dim, sel) =
    throw(ArgumentError("PointSampling IndexMode cannot use 'Contains', us 'Near' instead."))

contains(span::RegularSpan, ::Start, ::IntervalSampling, ord::Forward, mode, dim, sel) = begin
    v = val(sel)
    s = val(span)
    (v < first(dim) || v >= last(dim) + s) && throw(BoundsError())
    i = _searchlast(dim, v)
    (dim[i] + abs(s) > v) || error("No span for $v")
    i
end
contains(span::RegularSpan, ::Start, ::IntervalSampling, ord::Reverse, mode, dim, sel) = begin
    v = val(sel)
    (v < last(dim) || v >= first(dim) - val(span)) && throw(BoundsError())
    i = _searchfirst(dim, v)
    (dim[i] + abs(val(span)) > v) || error("No span for $v")
    i
end
contains(span::RegularSpan, ::End, ::IntervalSampling, ord::Forward, mode, dim, sel) = begin
    v = val(sel)
    (v <= first(dim) - val(span) || v > last(dim)) && throw(BoundsError())
    i = _searchfirst(dim, v)
    (dim[i] - abs(val(span)) <= v) || error("No span for $v")
    i
end
contains(span::RegularSpan, ::End, ::IntervalSampling, ord::Reverse, mode, dim, sel) = begin
    v = val(sel)
    (v <= last(dim) + val(span) || v > first(dim)) && throw(BoundsError())
    i = _searchlast(dim, v)
    (dim[i] - abs(val(span)) <= v) || error("No span for $v")
    i
end
contains(span::RegularSpan, locus::Center, samp::IntervalSampling, ord::Forward, mode, dim, sel) = begin
    half = abs(val(span) / 2)
    v = val(sel)
    (v < first(dim) - half || v >= last(dim) + half) && throw(BoundsError())
    i = _searchlast(dim, v + half)
    (dim[i] <= v - abs(half)) || (dim[i] > v + abs(half)) && error("No span for $v")
    i
end
contains(span::RegularSpan, locus::Center, samp::IntervalSampling, ord::Reverse, mode, dim, sel) = begin
    half = abs(val(span) / 2)
    v = val(sel)
    (v < last(dim) - half || v >= first(dim) + half) && throw(BoundsError())
    i = _searchfirst(dim, v + half)
    (dim[i] <= v - abs(half)) || (dim[i] > v + abs(half)) && error("No span for $v")
    i
end


contains(::IrregularSpan, ::Start, ::IntervalSampling, ord::Order, mode, dim, sel) = begin
    i = _searchlast(dim, val(sel))
    checkbounds(val(dim), i)
    i
end
contains(::IrregularSpan, ::End, ::IntervalSampling, ord::Order, mode, dim, sel) = begin
    i = _searchfirst(dim, val(sel))
    checkbounds(val(dim), i)
    i
end
contains(::IrregularSpan, ::Center, ::IntervalSampling, ord::Reverse, mode, dim, sel) = begin
    i = _searchlast(dim, val(sel))
    checkbounds(val(dim), i)
    if i == firstindex(dim)
        firstindex(dim)
    else
        (dim[i] + dim[i - 1]) / 2 <= val(sel) ? i - 1 : i
    end
end
contains(::IrregularSpan, ::Center, ::IntervalSampling, ord::Forward, mode, dim, sel) = begin
    i = _searchlast(dim, val(sel))
    checkbounds(val(dim), i)
    if i == lastindex(dim)
        lastindex(dim)
    else
        (dim[i] + dim[i + 1]) / 2 <= val(sel) ? i + 1 : i
    end
end


between(dim::Dimension, sel) =
    between(sampling(dim), dim::Dimension, sel)
between(sampling::Sampling, dim::Dimension, sel) =
    between(indexorder(dim), sampling, dim, val(sel))
between(::Unordered, sampling::Sampling, dim::Dimension, sel) =
    throw(ArgumentError("Cannot use `Between` on an unordered mode"))

between(indexord::Forward, ::PointSampling, dim::Dimension, sel) = begin
    low, high = _sorttuple(sel)
    a = _inbounds(_searchfirst(dim, low), dim)
    b = _inbounds(_searchlast(dim, high), dim)
    relate(dim, a:b)
end
between(indexord::Reverse, ::PointSampling, dim::Dimension, sel) = begin
    low, high = _sorttuple(sel)
    a = _inbounds(_searchlast(dim, high), dim)
    b = _inbounds(_searchfirst(dim, low), dim)
    relate(dim, a:b)
end
between(indexord, s::IntervalSampling, dim::Dimension, sel) =
    between(span(indexmode(dim)), indexord, s, dim, sel)
between(span::RegularSpan, indexord::Forward, ::IntervalSampling, dim::Dimension, sel) = begin
    low, high = _sorttuple(sel) .+ _locus_adjustment(indexmode(dim), span)
    a = _inbounds(_searchfirst(dim, low), dim)
    b = _inbounds(_searchlast(dim, high), dim)
    relate(dim, a:b)
end
between(span::RegularSpan, indexord::Reverse, ::IntervalSampling, dim::Dimension, sel) = begin
    low, high = _sorttuple(sel) .+ _locus_adjustment(indexmode(dim), span)
    a = _inbounds(_searchfirst(dim, high), dim)
    b = _inbounds(_searchlast(dim, low), dim)
    relate(dim, a:b)
end

# Reverse index needs to use rev=true and lt=<= for searchsorted
# so that it is exactly the revsese of a forward index
_searchlast(dim::Dimension, v) = _searchlast(indexorder(dim), val(dim), v)
_searchlast(::Forward, index, v) = searchsortedlast(index, v)
_searchlast(::Reverse, index, v) = searchsortedlast(index, v; rev=true)

_searchfirst(dim::Dimension, v) = _searchfirst(indexorder(dim), val(dim), v)
_searchfirst(::Forward, index, v) = searchsortedfirst(index, v)
_searchfirst(::Reverse, index, v) = searchsortedfirst(index, v; rev=true)

_locus_adjustment(indexmode::AbstractSampledIndex, span::RegularSpan) =
    _locus_adjustment(locus(indexmode), abs(step(span)))
_locus_adjustment(locus::Start, step) = zero(step), -step
_locus_adjustment(locus::Center, step) = step * 0.5, step * -0.5
_locus_adjustment(locus::End, step) = step, zero(step)


# Return an inbounds index
_inbounds(i::Int, dim::Dimension) =
    if i > lastindex(dim)
        lastindex(dim)
    elseif i <= firstindex(dim)
        firstindex(dim)
    else
        i
    end

_sorttuple((a, b)) = a < b ? (a, b) : (b, a)
