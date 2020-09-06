"""
Selectors are wrappers that indicate that passed values are not the array indices,
but values to be selected from the dimension index, such as `DateTime` objects for
a `Ti` dimension.

Selectors provided in DimensionalData are:

- [`At`](@ref)
- [`Between`](@ref)
- [`Near`](@ref)
- [`Where`](@ref)
- [`Contains`](@ref)

"""
abstract type Selector{T} end

const SelectorOrStandard = Union{Selector,StandardIndices}

val(sel::Selector) = sel.val
rebuild(sel::Selector, val) = basetypeof(sel)(val)

@inline maybeselector(I...) = maybeselector(I)
@inline maybeselector(I::Tuple) = map(maybeselector, I)
# Int AbstractArray and Colon do normal indexing
@inline maybeselector(i::StandardIndices) = i
# Selectors are allready selectors
@inline maybeselector(i::Selector) = i
# Anything else becomes `At`
@inline maybeselector(i) = At(i)

"""
    At(x, atol, rtol)
    At(x; atol=nothing, rtol=nothing)

Selector that exactly matches the value on the passed-in dimensions, or throws an error.
For ranges and arrays, every intermediate value must match an existing value -
not just the end points.

`x` can be any value or `Vector` of values.

`atol` and `rtol` are passed to `isapprox`.
For `Number` `rtol` will be set to `Base.rtoldefault`, otherwise `nothing`,
and wont be used.

## Example

```jldoctest
using DimensionalData

A = DimArray([1 2 3; 4 5 6], (X(10:10:20), Y(5:7)))
A[X(At(20)), Y(At(6))]

# output

5
```
"""
struct At{T,A,R} <: Selector{T}
    val::T
    atol::A
    rtol::R
end
At(val; atol=nothing, rtol=nothing) =
    At{typeof.((val, atol, rtol))...}(val, atol, rtol)

atol(sel::At) = sel.atol
rtol(sel::At) = sel.rtol

"""
    Near(x)

Selector that selects the nearest index to `x`.

With [`Points`](@ref) this is simply the index values nearest to the `x`,
however with [`Intervals`](@ref) it is the interval _center_ nearest to `x`.
This will be offset from the index value for [`Start`](@ref) and
[`End`](@ref) loci.

## Example

```jldoctest
using DimensionalData

A = DimArray([1 2 3; 4 5 6], (X(10:10:20), Y(5:7)))
A[X(Near(23)), Y(Near(5.1))]

# output

4
```
"""
struct Near{T} <: Selector{T}
    val::T
end

"""
    Contains(x)

Selector that selects the interval the value is contained by. If the
interval is not present in the index, an error will be thrown.

Can only be used for [`Intervals`](@ref) or [`Categorical`](@ref).

## Example

```jldoctest
using DimensionalData

dims_ = X(10:10:20; mode=Sampled(sampling=Intervals())),
        Y(5:7; mode=Sampled(sampling=Intervals()))
A = DimArray([1 2 3; 4 5 6], dims_)
A[X(Contains(8)), Y(Contains(6.8))]

# output

3
```
"""
struct Contains{T} <: Selector{T}
    val::T
end

"""
    Between(a, b)

Selector that retreive all indices located between 2 values,
evaluated with `>=` for the lower value, and `<` for the upper value.
This means the same value will not be counted twice in 2 `Between`
selections.

For [`Intervals`](@ref) the whole interval must be lie between the
values. For [`Points`](@ref) the points must fall between
the values. Different [`Sampling`](@ref) types may give different
results with the same input - this is the intended behaviour.

`Between` for [`Irregular`](@ref) intervals is a little complicated. The
interval is the distance between a value and the next (for [`Start`](ref) locus)
or previous (for [`End`](@ref) locus) value.

For [`Center`](@ref), we take the mid point between two index values
as the start and end of each interval. This may or may not make sense for
the values in your indes, so use `Between` with `Irregular` `Intervals(Center())`
with caution.

## Example

```jldoctest
using DimensionalData

A = DimArray([1 2 3; 4 5 6], (X(10:10:20), Y(5:7)))
A[X(Between(15, 25)), Y(Between(4, 6.5))]

# output

DimArray with dimensions:
 X: 20:10:20 (Sampled: Ordered Regular Points)
 Y: 5:6 (Sampled: Ordered Regular Points)
and data: 1×2 Array{Int64,2}
 4  5
```
"""
struct Between{T<:Union{Tuple{Any,Any},Nothing}} <: Selector{T}
    val::T
end
Between(args...) = Between{typeof(args)}(args)
Between(x::Tuple) = Between{typeof(x)}(x)

"""
    Where(f::Function)

Selector that filters a dimension by any function that accepts
a single value from the index and returns a `Bool`.

## Example

```jldoctest
using DimensionalData

A = DimArray([1 2 3; 4 5 6], (X(10:10:20), Y(19:21)))
A[X(Where(x -> x > 15)), Y(Where(x -> x in (19, 21)))]

# output

DimArray with dimensions:
 X: Int64[20] (Sampled: Ordered Regular Points)
 Y: Int64[19, 21] (Sampled: Ordered Regular Points)
and data: 1×2 Array{Int64,2}
 4  6
```
"""
struct Where{T} <: Selector{T}
    f::T
end

val(sel::Where) = sel.f


# sel2indices ==========================================================================

# Converts Selectors to regular indices
#
@inline sel2indices(A::AbstractArray, lookup) = sel2indices(dims(A), lookup)
@inline sel2indices(dims::Tuple, lookup) = sel2indices(dims, (lookup,))
@inline sel2indices(dims::Tuple, lookup::Tuple) =
    map((d, l) -> sel2indices(d, l), dims, lookup)


# First filter based on rough selector properties -----------------

# Standard indices are just returned.
@inline sel2indices(::Dimension, sel::StandardIndices) = sel
# Vectors are mapped
@inline sel2indices(dim::Dimension, sel::Selector{<:AbstractVector}) =
    [sel2indices(mode(dim), dim, rebuild(sel, v)) for v in val(sel)]
@inline sel2indices(dim::Dimension, sel::Selector) =
    sel2indices(mode(dim), dim, sel)


# Where selector ==============================
# Yes this is everything. 
# Where doesn't need mode specialisation  
@inline sel2indices(dim::Dimension, sel::Where) =
    [i for (i, v) in enumerate(index(dim)) if sel.f(v)]



# Then dispatch based on IndexMode -----------------

# Selectors can have varied behaviours depending on 
# the index mode.

# NoIndex -----------------------------
# This just converts the selector to standard indices. Implemented just
# so the Selectors actually work, not because what they do is useful or interesting.
@inline sel2indices(mode::NoIndex, dim::Dimension, sel::Union{At,Near,Contains}) = 
    val(sel)
@inline sel2indices(mode::NoIndex, dim::Dimension, sel::Union{Between}) =
    val(sel)[1]:val(sel)[2]

# Categorical IndexMode -------------------------
@inline sel2indices(mode::Categorical, dim::Dimension, sel::Selector) =
    if sel isa Union{Contains,Near}
        sel2indices(Points(), mode, dim, At(val(sel)))
    else
        sel2indices(Points(), mode, dim, sel)
    end


# Sampled IndexMode -----------------------------
@inline sel2indices(mode::AbstractSampled, dim::Dimension, sel::Selector) =
    sel2indices(sampling(mode), mode, dim, sel)

# For Sampled filter based on sampling type and selector -----------------

# At selector -------------------------
@inline sel2indices(sampling::Sampling, mode::IndexMode, dim::Dimension, sel::At) =
    at(sampling, mode, dim, sel)

# Near selector -----------------------
@inline sel2indices(sampling::Sampling, mode::IndexMode, dim::Dimension, sel::Near) = begin
    if span(mode) isa Irregular && locus(mode) isa Union{Start,End}
        error("Near is not implemented for Irregular with Start or End loci. Use Contains")
    end
    near(sampling, mode, dim, sel)
end

# Contains selector -------------------
@inline sel2indices(sampling::Points, mode::T, dim::Dimension, sel::Contains) where T =
    throw(ArgumentError("`Contains` has no meaning with `Points`. Use `Near`"))
@inline sel2indices(sampling::Intervals, mode::IndexMode, dim::Dimension, sel::Contains) =
    contains(sampling, mode, dim, sel)

# Between selector --------------------
@inline sel2indices(sampling::Sampling, mode::IndexMode, dim::Dimension, sel::Between{<:Tuple}) =
    between(sampling, mode, dim, sel)



# Unaligned IndexMode ------------------------------------------

# unalligned2indices is callled directly from dims2indices

# We use the transformation from the first Transformed dim.
# In practice the others could be empty.
@inline unalligned2indices(dims::DimTuple, sel::Tuple) = sel
@inline unalligned2indices(dims::DimTuple, sel::Tuple{<:Dimension,Vararg{<:Dimension}}) =
    unalligned2indices(dims, map(val, sel))
@inline unalligned2indices(dims::DimTuple, sel::Tuple{<:Selector,Vararg{<:Selector}}) = begin
    coords = [map(val, sel)...]
    transformed = transformfunc(mode(dims[1]))(coords)
    map(_to_int, sel, transformed)
end

_to_int(::At, x) = convert(Int, x)
_to_int(::Near, x) = round(Int, x)



# Selector methods

# at =============================================================================

@inline at(dim::Dimension, sel::At) =
    at(sampling(mode(dim)), mode(dim), dim, sel)
@inline at(::Sampling, mode::IndexMode, dim::Dimension, sel::At) =
    relate(dim, at(dim, val(sel), atol(sel), rtol(sel)))
@inline at(dim::Dimension{<:Val{Index}}, selval, atol::Nothing, rtol::Nothing) where Index = begin
    i = findfirst(x -> x == unwrap(selval), Index)
    i == nothing && selvalnotfound(dim, selval)
    return i
end
@inline at(dim::Dimension{<:Val{Index}}, selval::Val{X}, atol::Nothing, rtol::Nothing) where {Index,X} = begin
    i = findfirst(x -> x == X, Index)
    i == nothing && selvalnotfound(dim, selval)
    return i
end
@inline at(dim::Dimension, selval, atol::Nothing, rtol::Nothing) = begin
    i = findfirst(x -> x == selval, index(dim))
    i == nothing && selvalnotfound(dim, selval)
    return i
end

@noinline selvalnotfound(dim, selval) =
    throw(ArgumentError("$selval not found in $dim"))


# near ===========================================================================

# Finds the nearest point in the index, adjusting for locus if necessary.
# In Intevals we are finding the nearest point to the center of the interval.

near(dim::Dimension, sel::Near) = near(sampling(mode(dim)), mode(dim), dim, sel)
near(::Sampling, mode::IndexMode, dim::Dimension, sel::Near) = begin
    order = indexorder(dim)
    order isa UnorderedIndex && throw(ArgumentError("`Near` has no meaning in an `Unordered` index"))
    locus = DD.locus(dim)

    v = _locus_adjust(locus, val(sel), dim)
    i = _inbounds(_searchorder(order)(order, dim, v), dim)
    i = if (order isa ForwardIndex ? (<=) : (>=))(i, _dimlower(order, dim))
        _dimlower(order, dim)
    else
        previ = _prevind(order, i)
        vl, vi = map(abs, (dim[previ] - v, dim[i] - v))
        # We have to use the right >/>= for Start/End locus 
        _lt(locus)(vl, vi) ? previ : i
    end
    relate(dim, i)
end

_locus_adjust(locus::Start, v, dim) = v - abs(step(dim)) / 2
_locus_adjust(locus::Center, v, dim) = v
_locus_adjust(locus::End, v, dim) = v + abs(step(dim)) / 2


# contains ================================================================================

# Finds which interval contains a point

contains(dim::Dimension, sel::Contains) =
    contains(sampling(mode(dim)), mode(dim), dim, sel)

# Points --------------------------------------
contains(::Points, ::IndexMode, dim::Dimension, sel::Contains) =
    throw(ArgumentError("Points IndexMode cannot use 'Contains', use 'Near' instead."))

# Intervals -----------------------------------
contains(sampling::Intervals, mode::IndexMode, dim::Dimension, sel::Contains) =
    relate(dim, contains(span(mode), sampling, indexorder(mode), locus(mode), dim, sel))

# Regular Intervals ---------------------------
contains(span::Regular, ::Intervals, order, locus, dim::Dimension, sel::Contains) = begin
    v = val(sel); s = abs(val(span))
    _locus_checkbounds(locus, bounds(dim), v)
    i = _whichsearch(locus, order)(order, dim, maybeaddhalf(locus, s, v))
    # Check the value is in this cell - it might not be for Val or Vector.
    if !(val(dim) isa AbstractRange) 
        _lt(locus)(v, dim[i] + s) || error("No interval contains $(v)")
    end
    i
end

# Irregular Intervals -------------------------
contains(span::Irregular, ::Intervals, order::IndexOrder, locus::Locus, dim::Dimension, sel::Contains) = begin
    _locus_checkbounds(locus, bounds(span), val(sel))
    _whichsearch(locus, order)(order, dim, val(sel))
end
contains(span::Irregular, ::Intervals, order::IndexOrder, locus::Center, dim::Dimension, sel::Contains) = begin
    v = val(sel)
    _locus_checkbounds(locus, bounds(span), v)
    i = _searchfirst(order, dim, v)
    i <= firstindex(dim) && return firstindex(dim)
    i > lastindex(dim) && return lastindex(dim)
    
    interval = abs(dim[i] - dim[i - 1])
    distance = abs(dim[i] - v)
    _order_lt(order)(interval / 2, distance) ? i - 1 : i
end 

_whichsearch(::Locus, ::ForwardIndex) = _searchlast
_whichsearch(::Locus, ::ReverseIndex) = _searchfirst
_whichsearch(::End, ::ForwardIndex) = _searchfirst
_whichsearch(::End, ::ReverseIndex) = _searchlast

maybeaddhalf(::Locus, s, v) = v
maybeaddhalf(::Center, s, v) = v + s / 2

_order_lt(::ForwardIndex) = (<)
_order_lt(::ReverseIndex) = (<=)



# between ================================================================================

# Finds all values between two points, adjusted for locus where necessary

between(dim::Dimension, sel::Between) =
    between(sampling(mode(dim)), mode(dim), dim, sel)
between(sampling::Sampling, mode::IndexMode, dim::Dimension, sel::Between) = begin
    order = indexorder(dim)
    order isa UnorderedIndex && throw(ArgumentError("Cannot use `Between` with UnorderedIndex"))
    a, b = between(sampling, order, mode, dim, sel)
    relate(dim, a:b)
end

# Points ------------------------------------
between(sampling::Points, o::IndexOrder, ::IndexMode, dim::Dimension, sel::Between) = begin
    b1, b2 = _maybeflip(o, _sorttuple(sel))
    s1, s2 = _maybeflip(o, (_searchfirst, _searchlast))
    _inbounds((s1(o, dim, b1), s2(o, dim, b2)), dim)
end

# Intervals -------------------------
between(sampling::Intervals, o::IndexOrder, mode::IndexMode, dim::Dimension, sel::Between) =
    between(span(mode), sampling, o, mode, dim, sel)

# Regular Intervals -------------------------
between(span::Regular, ::Intervals, o::IndexOrder, mode::IndexMode, dim::Dimension, sel::Between) = begin
    b1, b2 = _maybeflip(o, _sorttuple(sel) .+ _locus_adjust(mode))
    _inbounds((_searchfirst(o, dim, b1), _searchlast(o, dim, b2)), dim)
end

_locus_adjust(mode) = _locus_adjust(locus(mode), abs(step(span(mode))))
_locus_adjust(locus::Start, step) = zero(step), -step
_locus_adjust(locus::Center, step) = step/2, -step/2
_locus_adjust(locus::End, step) = step, zero(step)


# Irregular Intervals -----------------------

struct Upper end
struct Lower end

between(span::Irregular, ::Intervals, o::IndexOrder, mode::IndexMode, d::Dimension, sel::Between) = begin
    l, h = _sorttuple(sel) 
    bl, bh = bounds(span)
    a = l <= bl ? _dimlower(o, d) : between(Lower(), locus(mode), o, d, l)
    b = h >= bh ? _dimupper(o, d) : between(Upper(), locus(mode), o, d, h)
    _maybeflip(o, (a, b))
end

between(x, locus::Union{Start,End}, o::IndexOrder, d::Dimension, v) =
    _search(x, o, d, v) - ordscalar(o) * (locscalar(locus) + endshift(x))
between(x, locus::Center, o::IndexOrder, d::Dimension, v) = begin
    r = ordscalar(o); sh = endshift(x)
    i = _search(x, o, d, v)
    interval = abs(d[i] - d[i-r])
    distance = abs(d[i] - v)
    # Use the right >/>= to match interval bounds
    _lt(x)(distance, (interval / 2)) ? i - sh * r : i - (1 + sh) * r
end

locscalar(::Start) = 1
locscalar(::End) = 0
endshift(::Lower) = -1
endshift(::Upper) = 1
ordscalar(::ForwardIndex) = 1
ordscalar(::ReverseIndex) = -1

_search(x, order, dim, v) = 
    _inbounds(_searchorder(order)(order, dim, v; lt=_lt(x)), dim)

_lt(::Lower) = (<)
_lt(::Upper) = (<=)


# Shared utils ============================================================================

_searchlast(o::IndexOrder, dim::Dimension, v; kwargs...) =
    searchsortedlast(val(dim), v; rev=isrev(o), kwargs...)
_searchlast(o::IndexOrder, dim::Dimension{<:Val{Index}}, v; kwargs...) where Index =
    searchsortedlast(Index, v; rev=isrev(o), kwargs...)

_searchfirst(o::IndexOrder, dim::Dimension, v; kwargs...) =
    searchsortedfirst(val(dim), v; rev=isrev(o), kwargs...)
_searchfirst(o::IndexOrder, dim::Dimension{<:Val{Index}}, v; kwargs...) where Index =
    searchsortedfirst(Index, v; rev=isrev(o), kwargs...)

# Return an inbounds index
_inbounds(is::Tuple, dim::Dimension) = map(i -> _inbounds(i, dim), is)
_inbounds(i::Int, dim::Dimension) =
    if i > lastindex(dim)
        lastindex(dim)
    elseif i <= firstindex(dim)
        firstindex(dim)
    else
        i
    end

_sorttuple(sel::Between) = _sorttuple(val(sel))
_sorttuple((a, b)) = a < b ? (a, b) : (b, a)

_maybeflip(o::ForwardIndex, (a, b)) = (a, b)
_maybeflip(o::ReverseIndex, (a, b)) = (b, a)

_lt(::Locus) = (<)
_lt(::End) = (<=)
_gt(::Locus) = (>=)
_gt(::End) = (>)

_locus_ineq(locus) = _lt(locus), _gt(locus)

_locus_checkbounds(loc, (l, h), v) = 
    (_lt(loc)(v, l) || _gt(loc)(v, h)) && throw(BoundsError())

_prevind(::ForwardIndex, i) = i - 1
_prevind(::ReverseIndex, i) = i + 1

_dimlower(o::ForwardIndex, d) = firstindex(d)
_dimlower(o::ReverseIndex, d) = lastindex(d)
_dimupper(o::ForwardIndex, d) = lastindex(d)
_dimupper(o::ReverseIndex, d) = firstindex(d)

_searchorder(::ForwardIndex) = _searchfirst
_searchorder(::ReverseIndex) = _searchlast
