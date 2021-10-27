"""
    Selector

Abstract supertype for all selectors.

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

val(sel::Selector) = sel.val

const SelTuple = Tuple{<:Selector,Vararg{<:Selector}}

"""
    At <: Selector

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
At(val; atol=nothing, rtol=nothing) = At(val, atol, rtol)

atol(sel::At) = sel.atol
rtol(sel::At) = sel.rtol

struct _True end
struct _False end

(sel::At)(lookup::LookupArray; kw...) = at(lookup, sel; kw...)

at(lookup::NoLookup, sel::At; kw...) = val(sel)
function at(lookup::LookupArray, sel::At; kw...)
    at(order(lookup), lookup, val(sel), atol(sel), rtol(sel); kw...)
end
function at(
    ::Ordered, lookup::LookupArray{<:Union{Number,Dates.TimeType}}, selval, atol, rtol::Nothing; 
    err=_True()
)
    x = unwrap(selval)
    i = searchsortedlast(lookup, x)
    # Try the current index
    if i === 0 
        i1 = i + 1
        if checkbounds(Bool, lookup, i1) && _is_at(x, lookup[i1], atol)
            return i1
        else
            return _selnotfound_or_nothing(err, lookup, selval)
        end
    elseif _is_at(x, lookup[i], atol)
        return i
    else 
        # Try again with the next index
        i1 = i + 1
        if checkbounds(Bool, lookup, i1) && _is_at(x, lookup[i1], atol)
            return i1
        else
            return _selnotfound_or_nothing(err, lookup, selval)
        end
    end
end
# catch-all for an unordered or non-number index
function at(order, lookup::LookupArray, selval, atol, rtol::Nothing; err=_True())
    i = findfirst(x -> _is_at(x, unwrap(selval), atol), parent(lookup))
    if i === nothing 
        return _selnotfound_or_nothing(err, lookup, selval)
    else
        return i
    end
end

@inline _is_at(x, y, atol) = x == y
@inline _is_at(x::Real, y::Real, atol::Real) = abs(x - y) <= atol

_selnotfound_or_nothing(err::_True, lookup, selval) = _selvalnotfound(lookup, selval)
_selnotfound_or_nothing(err::_False, lookup, selval) = nothing
@noinline _selvalnotfound(lookup, selval) = throw(ArgumentError("$selval not found in $lookup"))

"""
    Near <: Selector

    Near(x)

Selector that selects the nearest index to `x`.

With [`Points`](@ref) this is simply the index values nearest to the `x`,
however with [`Intervals`](@ref) it is the interval _center_ nearest to `x`.
This will be offset from the index value for `Start` and
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

(sel::Near)(lookup::LookupArray) = near(lookup, sel)

near(lookup::NoLookup, sel::Near) = val(sel)
function near(lookup::LookupArray, sel::Near)
    span(lookup) isa Irregular && locus(lookup) isa Union{Start,End} &&
        throw(ArgumentError("Near is not implemented for Irregular with Start or End loci. Use Contains"))
    near(order(lookup), sampling(lookup), lookup, sel)
end
near(order::Order, ::NoSampling, lookup::LookupArray, sel::Near) = at(lookup, At(val(sel)))
function near(order::Ordered, ::Union{Intervals,Points}, lookup::LookupArray, sel::Near)
    # Unwrap the selector value and adjust it for
    # inderval locus if neccessary
    v = unwrap(val(sel))
    v_adj = _locus_adjust(locus(lookup), v, lookup)
    # searchsortedfirst or searchsortedlast
    searchfunc = _searchfunc(order)
    # Search for the value
    found_i = _inbounds(searchfunc(lookup, v_adj), lookup)

    # Check if this is the lowest possible value allready,
    # and return if so
    if order isa ForwardOrdered
        found_i <= firstindex(lookup) && return found_i
    elseif order isa ReverseOrdered
        found_i >= lastindex(lookup) && return found_i
    end

    # Find which index is nearest,
    # the found index or previous index
    prev_i = found_i - _ordscalar(order)
    dist_to_prev = abs(v_adj - lookup[prev_i])
    dist_to_found = abs(v_adj - lookup[found_i])
    # Compare distance to the found and previous index values
    # We have to use the correct >/>= for Start/End locus 
    lessthan = _lt(locus(lookup)) 
    closest_i = lessthan(dist_to_prev, dist_to_found) ? prev_i : found_i

    return closest_i
end
function near(::Unordered, ::Union{Intervals,Points}, lookup::LookupArray, sel::Near)
    throw(ArgumentError("`Near` has no meaning in an `Unordered` `Sampled` index"))
end

_locus_adjust(locus::Center, v, lookup) = v
_locus_adjust(locus::Start, v, lookup) = v - abs(step(lookup)) / 2
_locus_adjust(locus::End, v, lookup) = v + abs(step(lookup)) / 2
_locus_adjust(locus::Start, v::DateTime, lookup) = v - (v - (v - abs(step(lookup)))) / 2
_locus_adjust(locus::End, v::DateTime, lookup) = v + (v + abs(step(lookup)) - v) / 2

"""
    Contains <: Selector

    Contains(x)

Selector that selects the interval the value is contained by. If the
interval is not present in the index, an error will be thrown.

Can only be used for [`Intervals`](@ref) or [`Categorical`](@ref).

## Example

```jldoctest
using DimensionalData
dims_ = X(10:10:20; sampling=Intervals(Center())),
        Y(5:7; sampling=Intervals(Center()))
A = DimArray([1 2 3; 4 5 6], dims_)
A[X(Contains(8)), Y(Contains(6.8))]

# output
3
```
"""
struct Contains{T} <: Selector{T}
    val::T
end

# Filter based on sampling and selector -----------------
(sel::Contains)(l::LookupArray; kw...) = contains(l, sel)

contains(l::NoLookup, sel::Contains; kw...) = val(sel)
contains(l::LookupArray, sel::Contains; kw...) = contains(sampling(l), l, sel; kw...)
# NoSampling (e.g. Categorical) just uses `at`
function contains(::NoSampling, lookup::LookupArray, sel::Contains; kw...)
    at(lookup, At(val(sel)); kw...)
end
# Points --------------------------------------
function contains(::Points, lookup::LookupArray, sel::Contains; err=_True())
    if err isa _True
        throw(ArgumentError("Points LookupArray cannot use `Contains`, use `Near` or `At` for Points."))
    else
        nothing
    end
end
# Intervals -----------------------------------
function contains(sampling::Intervals, lookup::LookupArray, sel::Contains; kw...)
    contains(span(lookup), sampling, order(lookup), locus(lookup), lookup, sel; kw...)
end
# Regular Intervals ---------------------------
function contains(span::Regular, ::Intervals, order, locus, lookup::LookupArray, sel::Contains; 
    err=_True()
)
    _locus_checkbounds(locus, lookup, sel) || return _boundserror_or_nothing(err)
    v = val(sel)
    absstep = abs(val(span))
    centeredval = _maybeaddhalf(locus, absstep, v)
    searchfunc = _whichsearch(locus, order)
    i = searchfunc(lookup, centeredval)
    # Check the value is in this cell. 
    # It is always for AbstractRange but might not be for Val tuple or Vector.
    if (parent(lookup) isa AbstractRange) || _lt(locus)(v, lookup[i] + absstep)
        return i
    else
        return _notcontained_or_nothing(err, v)
    end
end
# Explicit Intervals ---------------------------
function contains(
    span::Explicit, ::Intervals, order,locus, lookup::LookupArray, sel::Contains;
    err=_True()
)
    x = val(sel)
    i = searchsortedlast(view(val(span), 1, :), x)
    if i === 0 || val(span)[2, i] < x 
        return _notcontained_or_nothing(err, x)
    else
        return i
    end
end
# Irregular Intervals -------------------------
function contains(
    span::Irregular, ::Intervals, order::Order,
    locus::Locus,lookup::LookupArray, sel::Contains;
    err=_True()
)
    _locus_checkbounds(locus, lookup, sel) || return _boundserror_or_nothing(err)
    searchfunc =  _whichsearch(locus, order)
    i = searchfunc(lookup, val(sel))
    return i
end
function contains(
    span::Irregular, ::Intervals, order::Order,
    locus::Center, lookup::LookupArray, sel::Contains; 
    err=_True()
)
    _locus_checkbounds(locus, lookup, sel) || return _boundserror_or_nothing(err)
    v = val(sel)
    i = searchsortedfirst(lookup, v)
    i = if i <= firstindex(lookup) 
        firstindex(lookup)
    elseif i > lastindex(lookup) 
        lastindex(lookup)
    else
        interval = abs(lookup[i] - lookup[i - 1])
        distance = abs(lookup[i] - v)
        _order_lt(order)(interval / 2, distance) ? i - 1 : i
    end
    return i
end 

_boundserror_or_nothing(err::_True) = throw(BoundsError())
_boundserror_or_nothing(err::_False) = nothing

_notcontained_or_nothing(err::_True, selval) = _notcontainederror(selval)
_notcontained_or_nothing(err::_False, selval) = nothing
@noinline _notcontainederror(v) = throw(ArgumentError("No interval contains $(v)"))

_whichsearch(::Locus, ::ForwardOrdered) = searchsortedlast
_whichsearch(::Locus, ::ReverseOrdered) = searchsortedfirst
_whichsearch(::End, ::ForwardOrdered) = searchsortedfirst
_whichsearch(::End, ::ReverseOrdered) = searchsortedlast

_maybeaddhalf(::Locus, s, v) = v
_maybeaddhalf(::Center, s, v) = v + s / 2

_order_lt(::ForwardOrdered) = (<)
_order_lt(::ReverseOrdered) = (<=)

"""
    Between <: Selector

    Between(a, b)

Selector that retreive all indices located between 2 values,
evaluated with `>=` for the lower value, and `<` for the upper value.
This means the same value will not be counted twice in 2 adjacent 
`Between` selections.

For [`Intervals`](@ref) the whole interval must be lie between the
values. For [`Points`](@ref) the points must fall between
the values. Different [`Sampling`](@ref) types may give different
results with the same input - this is the intended behaviour.

`Between` for [`Irregular`](@ref) intervals is a little complicated. The
interval is the distance between a value and the next (for `Start` locus)
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

1×2 DimArray{Int64,2} with dimensions:
  X Sampled 20:10:20 ForwardOrdered Regular Points,
  Y Sampled 5:6 ForwardOrdered Regular Points
 4  5
```
"""
struct Between{T<:Union{Tuple{Any,Any},Nothing}} <: Selector{T}
    val::T
end
Between(args...) = Between(args)

Base.first(sel::Between) = first(val(sel))
Base.last(sel::Between) = last(val(sel))

struct _Upper end
struct _Lower end

(sel::Between)(lookup::LookupArray) = between(lookup, sel)

between(lookup::NoLookup, sel::Between) = val(sel)[1]:val(sel)[2]
between(lookup::LookupArray, sel::Between) = between(sampling(lookup), lookup, sel)
# This is the main method called above
function between(sampling::Sampling, lookup::LookupArray, sel::Between)
    o = order(lookup)
    o isa Unordered && throw(ArgumentError("Cannot use `Between` with Unordered"))
    a, b = between(sampling, o, lookup, sel)
    return a:b
end

function between(sampling::NoSampling, o::Order, lookup::LookupArray, sel::Between)
    between(Points(), o, lookup, sel)
end
# Points ------------------------------------
function between(sampling::Points, o::Order, lookup::LookupArray, sel::Between)
    b1, b2 = _maybeflipbounds(o, _sorttuple(sel))
    s1, s2 = _maybeflipbounds(o, (searchsortedfirst, searchsortedlast))
    low_i = s1(lookup, b1)
    high_i = s2(lookup, b2)
    return _inbounds((low_i, high_i), lookup)
end
# Intervals -------------------------
function between(sampling::Intervals, o::Order, lookup::LookupArray, sel::Between)
    between(span(lookup), sampling, o, lookup, sel)
end
# Regular Intervals -------------------------
function between(span::Regular, ::Intervals, o::Order, lookup::LookupArray, sel::Between)
    lowval, highval = _maybeflipbounds(o, _sorttuple(sel) .+ _locus_adjust(lookup))
    low_i = searchsortedfirst(lookup, lowval)
    high_i = searchsortedlast(lookup, highval)
    return _inbounds((low_i, high_i), lookup)
end
# Explicit Intervals -------------------------
function between(span::Explicit, ::Intervals, o::Order, lookup::LookupArray, sel::Between)
    lower_bounds = view(val(span), 1, :)
    upper_bounds = view(val(span), 2, :)
    low_i = searchsortedfirst(lower_bounds, first(val(sel)); lt=<)
    high_i = searchsortedlast(upper_bounds, last(val(sel)); lt=<)
    return _inbounds((low_i, high_i), lookup)
end
# Irregular Intervals -----------------------
function between(span::Irregular, ::Intervals, o::Order, l::LookupArray, sel::Between)
    lowval, highval = _sorttuple(sel) 
    lowerbound, upperbound = bounds(span)

    a = if lowval <= lowerbound 
        o isa ForwardOrdered ? firstindex(l) : lastindex(l)
    else
        _irregbetween(_Lower(), locus(l), o, l, lowval)
    end
    b = if highval >= upperbound 
        o isa ForwardOrdered ? lastindex(l) : firstindex(l)
    else
        _irregbetween(_Upper(), locus(l), o, l, highval)
    end
    return _maybeflipbounds(o, (a, b))
end
function _irregbetween(side, locus::Union{Start,End}, o::Order, m::LookupArray, v)
    _search(side, m, v) - _ordscalar(o) * (_locscalar(locus) + _endshift(side))
end
function _irregbetween(side, locus::Center, o::Order, l::LookupArray, v)
    r = _ordscalar(o) 
    sh = _endshift(side)
    i = _search(side, l, v)
    interval = abs(l[i] - l[i-r])
    distance = abs(l[i] - v)
    # Use the right >/>= to match interval bounds
    if _lt(side)(distance, (interval / 2)) 
        i - sh * r 
    else
        i - (1 + sh) * r
    end
end

function _search(side, lookup, val)
    searchfunc = _searchfunc(order(lookup))
    i = searchfunc(lookup, val; lt=_lt(side))
    _inbounds(i, lookup)
end

_locus_adjust(lookup) = _locus_adjust(locus(lookup), abs(step(span(lookup))))
_locus_adjust(locus::Start, step) = zero(step), -step
_locus_adjust(locus::Center, step) = step/2, -step/2
_locus_adjust(locus::End, step) = step, zero(step)

_locscalar(::Start) = 1
_locscalar(::End) = 0
_endshift(::_Lower) = -1
_endshift(::_Upper) = 1
_ordscalar(::ForwardOrdered) = 1
_ordscalar(::ReverseOrdered) = -1


_lt(::_Lower) = (<)
_lt(::_Upper) = (<=)

_maybeflipbounds(m::LookupArray, bounds) = _maybeflipbounds(order(m), bounds) 
_maybeflipbounds(o::ForwardOrdered, (a, b)) = (a, b)
_maybeflipbounds(o::ReverseOrdered, (a, b)) = (b, a)

"""
    Where <: Selector

    Where(f::Function)

Selector that filters a dimension lookup by any function that
accepts a single value and returns a `Bool`.

## Example

```jldoctest
using DimensionalData

A = DimArray([1 2 3; 4 5 6], (X(10:10:20), Y(19:21)))
A[X(Where(x -> x > 15)), Y(Where(x -> x in (19, 21)))]

# output

1×2 DimArray{Int64,2} with dimensions:
  X Sampled Int64[20] ForwardOrdered Regular Points,
  Y Sampled Int64[19, 21] ForwardOrdered Regular Points
 4  6
```
"""
struct Where{T} <: Selector{T}
    f::T
end

val(sel::Where) = sel.f

# Yes this is everything. `Where` doesn't need lookup specialisation  
@inline function (sel::Where)(lookup::LookupArray)
    [i for (i, v) in enumerate(parent(lookup)) if sel.f(v)]
end


# selectindices ==========================================================================


"""
    selectindices(lookups, selectors)

Converts [`Selector`](@ref) to regular indices.
"""
function selectindices end
@inline selectindices(lookups::LookupArrayTuple, s1, ss...) = selectindices(lookups, (s1, ss...))
@inline selectindices(lookups::LookupArrayTuple, selectors::Tuple) =
    map((l, s) -> selectindices(l, s), lookups, selectors)
@inline selectindices(lookups::LookupArrayTuple, selectors::Tuple{}) = ()
# @inline selectindices(dim::LookupArray, sel::Val) = selectindices(val(dim), At(sel))
# Standard indices are just returned.
@inline selectindices(::LookupArray, sel::StandardIndices) = sel
@inline function selectindices(l::LookupArray, sel)
    selstr = sprint(show, sel)
    throw(ArgumentError("Invalid index `$selstr`. Did you mean `At($selstr)`? Use stardard indices, `Selector`s, or `Val` for compile-time `At`."))
end
# Vectors are mapped
@inline selectindices(lookup::LookupArray, sel::Selector{<:AbstractVector}) =
    [selectindices(lookup, rebuild(sel; val=v)) for v in val(sel)]

# Otherwise apply the selector
@inline selectindices(lookup::LookupArray, sel::Selector) = sel(lookup)


# Unaligned LookupArray ------------------------------------------

# select_unalligned_indices is callled directly from dims2indices

# We use the transformation from the first Transformed dim.
# In practice the others could be empty.
@inline function select_unalligned_indices(lookups::LookupArrayTuple, sel::Tuple{<:Selector,Vararg{<:Selector}})
    coords = [map(val, sel)...]
    transformed = transformfunc(lookups[1])(coords)
    map(_transform2int, sel, transformed)
end

_transform2int(::Near, x) = round(Int, x)
_transform2int(sel::At, x) = _transform2int(sel::At, x, atol(sel))
_transform2int(::At, x, atol::Nothing) = convert(Int, x)
function _transform2int(::At, x, atol)
    i = round(Int, x)
    abs(x - i) <= atol ? i : _transform_notfound(x)
end

@noinline _transform_notfound(x) = throw(ArgumentError("$x not found in Transformed lookups"))


# Shared utils ============================================================================

# Return an inbounds index
_inbounds(is::Tuple, lookup::LookupArray) = map(i -> _inbounds(i, lookup), is)
function _inbounds(i::Int, lookup::LookupArray)
    if i > lastindex(lookup)
        lastindex(lookup)
    elseif i <= firstindex(lookup)
        firstindex(lookup)
    else
        i
    end
end

_sorttuple(sel::Between) = _sorttuple(val(sel))
_sorttuple((a, b)) = a < b ? (a, b) : (b, a)

_lt(::Locus) = (<)
_lt(::End) = (<=)
_gt(::Locus) = (>=)
_gt(::End) = (>)

_locus_checkbounds(loc, lookup::LookupArray, sel::Selector) =  _locus_checkbounds(loc, bounds(lookup), val(sel)) 
_locus_checkbounds(loc, (l, h)::Tuple, v) = !(_lt(loc)(v, l) || _gt(loc)(v, h))

_searchfunc(::ForwardOrdered) = searchsortedfirst
_searchfunc(::ReverseOrdered) = searchsortedlast

hasselection(lookup::LookupArray, sel::At) = at(lookup, sel; err=_False()) === nothing ? false : true
hasselection(lookup::LookupArray, sel::Contains) = contains(lookup, sel; err=_False()) === nothing ? false : true
# Near and Between only fail on Unordered
# Otherwise Near returns the nearest index, and Between and empty range
hasselection(lookup::LookupArray, selnear::Near) = order(lookup) isa Unordered ? false : true
hasselection(lookup::LookupArray, selnear::Between) = order(lookup) isa Unordered ? false : true
