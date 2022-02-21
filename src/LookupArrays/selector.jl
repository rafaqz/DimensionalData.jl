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
Base.parent(sel::Selector) = sel.val

const SelectorOrInterval = Union{Selector,Interval}

const SelTuple = Tuple{<:SelectorOrInterval,Vararg{<:SelectorOrInterval}}

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

selectindices(l::LookupArray, sel::At; kw...) = at(l, sel; kw...)
selectindices(l::LookupArray, sel::At{<:AbstractVector}) = _selectvec(l, sel)

_selectvec(l, sel) = [selectindices(l, rebuild(sel; val=v)) for v in val(sel)]

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

selectindices(l::LookupArray, sel::Near) = near(l, sel)
selectindices(l::LookupArray, sel::Near{<:AbstractVector}) = _selectvec(l, sel)

near(lookup::NoLookup, sel::Near) = val(sel)
function near(lookup::LookupArray, sel::Near)
    span(lookup) isa Union{Irregular,Explicit} && locus(lookup) isa Union{Start,End} &&
        throw(ArgumentError("Near is not implemented for Irregular or Explicit with Start or End loci. Use Contains"))
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
using DimensionalData; const DD = DimensionalData
dims_ = X(10:10:20; sampling=DD.Intervals(DD.Center())),
        Y(5:7; sampling=DD.Intervals(DD.Center()))
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
selectindices(l::LookupArray, sel::Contains; kw...) = contains(l, sel)
selectindices(l::LookupArray, sel::Contains{<:AbstractVector}) = _selectvec(l, sel)

contains(l::NoLookup, sel::Contains; kw...) = val(sel)
contains(l::LookupArray, sel::Contains; kw...) = contains(sampling(l), l, sel; kw...)
# NoSampling (e.g. Categorical) just uses `at`
function contains(::NoSampling, l::LookupArray, sel::Contains; kw...)
    at(l, At(val(sel)); kw...)
end
# Points --------------------------------------
function contains(::Points, l::LookupArray, sel::Contains; err=_True())
    if err isa _True
        throw(ArgumentError("Points LookupArray cannot use `Contains`, use `Near` or `At` for Points."))
    else
        nothing
    end
end
# Intervals -----------------------------------
function contains(sampling::Intervals, l::LookupArray, sel::Contains; err=_True())
    _locus_checkbounds(locus(l), l, sel) || return _boundserror_or_nothing(err)
    contains(order(l), span(l), sampling, locus(l), l, sel; err)
end
# Regular Intervals ---------------------------
function contains(o::Ordered, span::Regular, ::Intervals, locus::Locus, l::LookupArray, sel::Contains;
    err=_True()
)
    v = val(sel)
    i = _searchfunc(locus, o)(l, v)
    return check_regular_contains(span, locus, l, v, i, err)
end
function contains(o::Ordered, span::Regular, ::Intervals, locus::Center, l::LookupArray, sel::Contains;
    err=_True()
)
    v = val(sel) + abs(val(span)) / 2
    i = _searchfunc(locus, o)(l, v)
    return check_regular_contains(span, locus, l, v, i, err)
end

function check_regular_contains(span::Span, locus::Locus, l::LookupArray, v, i, err)
    absstep = abs(val(span))
    if (parent(l) isa AbstractRange) || _lt(locus)(v, l[i] + absstep)
        return i
    else
        return _notcontained_or_nothing(err, v)
    end
end

# Explicit Intervals ---------------------------
function contains(
    o::Ordered, span::Explicit, ::Intervals, locus, l::LookupArray, sel::Contains;
    err=_True()
)
    v = val(sel)
    searchfunc = _searchfunc(_Upper(), o)
    i = searchfunc(view(val(span), 1, :), v; order=ordering(o), lt=_lt(locus))
    if i === 0 || val(span)[2, i] < v
        return _notcontained_or_nothing(err, v)
    else
        return i
    end
end
# Irregular Intervals -------------------------
function contains(
    o::Ordered, span::Irregular, ::Intervals, locus::Locus, l::LookupArray, sel::Contains;
    err=_True()
)
    return _searchfunc(locus, o)(l, val(sel))
end
function contains(
    o::Ordered, span::Irregular, ::Intervals, locus::Center, l::LookupArray, sel::Contains;
    err=_True()
)
    _order_lt(::ForwardOrdered) = (<)
    _order_lt(::ReverseOrdered) = (<=)

    v = val(sel)
    i = searchsortedfirst(l, v)
    i = if i <= firstindex(l)
        firstindex(l)
    elseif i > lastindex(l)
        lastindex(l)
    else
        interval = abs(l[i] - l[i - 1])
        distance = abs(l[i] - v)
        _order_lt(o)(interval / 2, distance) ? i - 1 : i
    end
    return i
end

_boundserror_or_nothing(err::_True) = throw(BoundsError())
_boundserror_or_nothing(err::_False) = nothing

_notcontained_or_nothing(err::_True, selval) = _notcontainederror(selval)
_notcontained_or_nothing(err::_False, selval) = nothing

_notcontainederror(v) = throw(ArgumentError("No interval contains $v"))

_searchfunc(::Locus, ::ForwardOrdered) = searchsortedlast
_searchfunc(::End, ::ForwardOrdered) = searchsortedfirst
_searchfunc(::Locus, ::ReverseOrdered) = searchsortedfirst
_searchfunc(::End, ::ReverseOrdered) = searchsortedlast

"""
    Between <: Selector

    Between(a, b)


Depreciated: use `a..b` instead of `Between(a, b)`. Other `Interval`
objects from IntervalSets.jl, like `OpenInterval(a, b) will also work,
giving the correct open/closed boundaries.

`Between` will e removed in furture to avoid clashes with `DataFrames.Between`.

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
struct Between{T<:Union{<:AbstractVector{<:Tuple{Any,Any}},Tuple{Any,Any},Nothing}} <: Selector{T}
    val::T
end
Between(args...) = Between(args)

Base.first(sel::Between) = first(val(sel))
Base.last(sel::Between) = last(val(sel))

abstract type _Side end
struct _Upper <: _Side end
struct _Lower <: _Side end

selectindices(l::LookupArray, sel::Union{Between{<:Tuple},Interval}) = between(l, sel)
function selectindices(lookup::LookupArray, sel::Between{<:AbstractVector})
    inds = Int[]
    for v in val(sel)
        append!(inds, selectindices(lookup, rebuild(sel; val=v)))
    end
end

function between(l::LookupArray, sel::Between)
    a, b = _sorttuple(sel)
    return between(l, a..b)
end
function between(l::NoLookup, sel::Interval)
    x = intersect(sel, first(axes(l, 1))..last(axes(l, 1)))
    return ceil(Int, x.left):floor(Int, x.right) 
end
between(l::LookupArray, sel::Interval) = between(sampling(l), l, sel)
# This is the main method called above
function between(sampling::Sampling, l::LookupArray, sel::Interval)
    o = order(l)
    o isa Unordered && throw(ArgumentError("Cannot use an interval or `Between` with Unordered"))
    between(sampling, o, l, sel)
end

_to_closed(T, i::Interval{:closed,:closed}) = i
_to_closed(T, i::Interval{:open,:open}) = (i.left + _minstep(T))..(i.right - _minstep(T))
_to_closed(T, i::Interval{:closed,:open}) = i.left..(i.right - _minstep(T))
_to_closed(T, i::Interval{:open,:closed}) = (i.left + _minstep(T))..i.right

# Maybe not the best way to do this but manipulating <= > etc
# inside `searchsorted` is already too complicated.
_minstep(T) = eps(T)
_minstep(T::Type{<:Integer}) = one(T)
_minstep(T::Type{<:Char}) = 1

function between(sampling::NoSampling, o::Ordered, l::LookupArray, sel::Interval)
    between(Points(), o, l, sel)
end

function between(sampling, o::Ordered, l::LookupArray, sel::Interval)
    lowerbound, upperbound = bounds(l)
    lowsel, highsel = endpoints(sel)
    a = if lowsel > upperbound
        ordered_lastindex(l) + _ordscalar(o)
    elseif lowsel < lowerbound
        ordered_firstindex(l)
    else
        _between_side(_Lower(), o, span(l), sampling, l, sel, lowsel)
    end
    b = if highsel < lowerbound
        ordered_firstindex(l) - _ordscalar(o)
    elseif highsel > upperbound
        ordered_lastindex(l)
    else
        _between_side(_Upper(), o, span(l), sampling, l, sel, highsel)
    end
    # Fix empty range values
    a, b = _maybeflipbounds(o, (a, b))
    # Fix empty range values
    if a > b
        if b < firstindex(l)
            return firstindex(l):(firstindex(l) - 1)
        elseif a > lastindex(l)
            return (lastindex(l) + 1):lastindex(l)
        end
    else
        return a:b
    end
    return a:b
end

# Points -------------------------
function _between_side(side::_Lower, o::Ordered, span, ::Points, l, sel, v)
    i = v <= bounds(l)[1] ? ordered_firstindex(l) : _searchfunc(side, o)(l, v)
    return _close_interval(side, l, sel, l[i], i)
end
function _between_side(side::_Upper, o::Ordered, span, ::Points, l, sel, v)
    i = v >= bounds(l)[2] ? ordered_lastindex(l) : _searchfunc(side, o)(l, v)
    return _close_interval(side, l, sel, l[i], i)
end

# Regular Intervals -------------------------
# Adjust the value for the lookup locus before search
function _between_side(side, o::Ordered, ::Regular, ::Intervals, l, sel, v)
    adj = _locus_adjust(side, l)
    v1 = v + adj
    s = _ordscalar(o)
    i = _searchfunc(side, o)(l, v1)
    fi, li = firstindex(l), lastindex(l)
    v2 = if i > li
        l[li] + adj
    elseif i < fi
        l[fi] + adj
    else
        l[i] - adj
    end
    return _close_interval(side, l, sel, v2, i)
end

_locus_adjust(side, l) = _locus_adjust(side, locus(l), abs(step(span(l))))
_locus_adjust(::_Lower, locus::Start, step) = zero(step)
_locus_adjust(::_Upper, locus::Start, step) = -step
_locus_adjust(::_Lower, locus::Center, step) = step/2
_locus_adjust(::_Upper, locus::Center, step) = -step/2
_locus_adjust(::_Lower, locus::End, step) = step
_locus_adjust(::_Upper, locus::End, step) = -zero(step)

# Explicit Intervals -------------------------
# Rebuild the lookup with the bounds matrix values before searching
function _between_side(side, o::Ordered, span::Explicit, ::Intervals, l, sel, v)
    boundsvec = side isa _Lower ? view(val(span), 1, :) : view(val(span), 2, :)
    l1 = rebuild(l; data=boundsvec)
    i = _searchfunc(side, o)(l1, v)
    return checkbounds(Bool, l1, i) ? (@inbounds _close_interval(side, l1, sel, l1[i], i)) : i
end

# Irregular Intervals -----------------------
#
# This works a little differently to Regular variants, 
# as we have to work with unequal step sizes, calculating them
# as we find close values.
#
# Find the inteval the value falls in.
# We need to special-case Center locus for Irregular
_between_side(side, o, span::Irregular, ::Intervals, l, sel, v) = _irreg_side(side, locus(l), o, l, sel, v)

function _irreg_side(side, locus::Union{Start,End}, o, l, sel, v)
    s = _ordscalar(o)
    if v == bounds(l)[1]
        i = ordered_firstindex(l)
        v1 = v
    elseif v == bounds(l)[2]
        i = ordered_lastindex(l)
        v1 = v
    else
        # Search for the value and offset per order/locus/side
        i = _searchfunc(o)(l, v; lt=_lt(side))
        i += - s * (_locscalar(locus) + _sideshift(side))
        # Get the value on the interval edge
        v1 = if i < firstindex(l)
            _maybeflipbounds(l, bounds(l))[1]
        elseif i > lastindex(l)
            _maybeflipbounds(l, bounds(l))[2]
        elseif side isa _Lower && locus isa End
            l[i-s]
        elseif side isa _Upper && locus isa Start
            l[i+s]
        else
            l[i]
        end
    end
    return _close_interval(side, l, sel, v1, i)
end
function _irreg_side(side, locus::Center, o, l, sel, v)
    if v == bounds(l)[1]
        i = ordered_firstindex(l)
        v1 = v
    elseif v == bounds(l)[2]
        i = ordered_lastindex(l)
        v1 = v
    else
        r = _ordscalar(o)
        sh = _sideshift(side)
        i = _searchfunc(o)(l, v; lt=_lt(side))
        (i - r < firstindex(l) ||  i - r > lastindex(l)) && return i
        half_step = abs(l[i] - l[i-r]) / 2
        distance = abs(l[i] - v)
        # Use the right less than </<= to match interval bounds
        i = if _lt(side)(distance, half_step)
            i - sh * r
        else
            i - (1 + sh) * r
        end
        shift = side isa _Lower ? -half_step : half_step
        v1 = l[i] + shift
    end
    return _close_interval(side, l, sel, v1, i)
end


_close_interval(side, l, sel, v, i) = i
function _close_interval(side::_Lower, l, sel::Interval{:open,<:Any}, v, i)
    v in sel ? i : i + _ordscalar(l)
end
function _close_interval(side::_Upper, l, sel::Interval{<:Any,:open}, v, i)
    v in sel ? i : i - _ordscalar(l)
end

_locscalar(::Start) = 1
_locscalar(::End) = 0
_sideshift(::_Lower) = -1
_sideshift(::_Upper) = 1
_ordscalar(l) = _ordscalar(order(l))
_ordscalar(::ForwardOrdered) = 1
_ordscalar(::ReverseOrdered) = -1

_lt(::_Lower) = (<)
_lt(::_Upper) = (<=)

_maybeflipbounds(m::LookupArray, bounds) = _maybeflipbounds(order(m), bounds)
_maybeflipbounds(o::ForwardOrdered, (a, b)) = (a, b)
_maybeflipbounds(o::ReverseOrdered, (a, b)) = (b, a)
_maybeflipbounds(o::Unordered, (a, b)) = (a, b)

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
@inline function selectindices(lookup::LookupArray, sel::Where)
    [i for (i, v) in enumerate(parent(lookup)) if sel.f(v)]
end

"""
    All <: Selector

    All(selectors::Selector...)

Selector that combines the results of other selectors. 
The indices used will be the union of all result sorted in ascending order.

## Example

```jldoctest
using DimensionalData, Unitful

dimz = X(10.0:20:200.0), Ti(1u"s":5u"s":100u"s")
A = DimArray((1:10) * (1:20)', dimz)
A[X=All(At(10.0), At(30.0), At(50.0)), Ti=All(1u"s"..10u"s", 90u"s"..100u"s")]

# output

3×4 DimArray{Int64,2} with dimensions:
  X Sampled Float64[10.0, 50.0] ForwardOrdered Regular Points,
  Ti Sampled Quantity{Int64, 𝐓, Unitful.FreeUnits{(s,), 𝐓, nothing}}[1 s, 6 s, 91 s, 96 s] ForwardOrdered Regular Points
 1  2  19  20
 3  6  57  60
```
"""
struct All{S<:Tuple{Vararg{<:SelectorOrInterval}}} <: Selector{S}
    selectors::S
end
All(args::SelectorOrInterval...) = All(args)

@inline function selectindices(lookup::LookupArray, sel::All)
    results = map(s -> selectindices(lookup, s), sel.selectors)
    sort!(union(results...))
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

_searchfunc(::_Lower, ::ForwardOrdered) = searchsortedfirst
_searchfunc(::_Lower, ::ReverseOrdered) = searchsortedlast
_searchfunc(::_Upper, ::ForwardOrdered) = searchsortedlast
_searchfunc(::_Upper, ::ReverseOrdered) = searchsortedfirst

hasselection(lookup::LookupArray, sel::At) = at(lookup, sel; err=_False()) === nothing ? false : true
hasselection(lookup::LookupArray, sel::Contains) = contains(lookup, sel; err=_False()) === nothing ? false : true
# Near and Between only fail on Unordered
# Otherwise Near returns the nearest index, and Between an empty range
hasselection(lookup::LookupArray, selnear::Near) = order(lookup) isa Unordered ? false : true
hasselection(lookup::LookupArray, selnear::Union{Interval,Between}) = order(lookup) isa Unordered ? false : true
