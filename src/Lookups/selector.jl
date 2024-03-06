struct SelectorError{L,S} <: Exception 
    lookup::L
    selector::S
end

function Base.showerror(io::IO, ex::SelectorError)
    if isordered(ex.lookup)
        println(io, "SelectorError: attempt to select $(ex.selector) from lookup $(typeof(ex.lookup)) with bounds $(bounds(ex.lookup))")
    else
        println(io, "SelectorError: attempt to select $(ex.selector) from lookup $(typeof(ex.lookup)) with values $(ex.lookup)")
    end
end
Base.showerror(io::IO, ex::SelectorError{<:Categorical}) = 
    println(io, "SelectorError: attempt to select $(ex.selector) from lookup $(typeof(ex.lookup)) with categories $(ex.lookup)")

"""
    Selector

Abstract supertype for all selectors.

Selectors are wrappers that indicate that passed values are not the array indices,
but values to be selected from the dimension index, such as `DateTime` objects for
a `Ti` dimension.

Selectors provided in DimensionalData are:

- [`At`](@ref)
- [`Between`](@ref)
- [`Touches`](@ref)
- [`Near`](@ref)
- [`Where`](@ref)
- [`Contains`](@ref)

"""
abstract type Selector{T} end

val(sel::Selector) = sel.val
rebuild(sel::Selector, val) = basetypeof(sel)(val)

Base.parent(sel::Selector) = sel.val
Base.to_index(sel::Selector) = sel

abstract type Selector{T} end

"""
    IntSelector <: Selector

Abstract supertype for [`Selector`](@ref)s that return a single `Int` index.

IntSelectors provided by DimensionalData are:

- [`At`](@ref)
- [`Contains`](@ref)
- [`Near`](@ref)
"""
abstract type IntSelector{T} <: Selector{T} end

"""
    ArraySelector <: Selector

Abstract supertype for [`Selector`](@ref)s that return an `AbstractArray`.

ArraySelectors provided by DimensionalData are:

- [`Between`](@ref)
- [`Touches`](@ref)
- [`Where`](@ref)
"""
abstract type ArraySelector{T} <: Selector{T} end

const SelectorOrInterval = Union{Selector,Interval,Not}

const SelTuple = Tuple{SelectorOrInterval,Vararg{SelectorOrInterval}}

# `Not` form InvertedIndices.jr
function selectindices(l::Lookup, sel::Not; kw...)
    indices = selectindices(l, sel.skip; kw...)
    return first(to_indices(l, (Not(indices),)))
end
@inline function selectindices(l::Lookup, sel; kw...)
    selstr = sprint(show, sel)
    throw(ArgumentError("Invalid index `$selstr`. Did you mean `At($selstr)`? Use stardard indices, `Selector`s, or `Val` for compile-time `At`."))
end

"""
    At <: IntSelector

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
struct At{T,A,R} <: IntSelector{T}
    val::T
    atol::A
    rtol::R
end
At(val; atol=nothing, rtol=nothing) = At(val, atol, rtol)
At() = At(nothing)

rebuild(sel::At, val) = At(val, sel.atol, sel.rtol)

atol(sel::At) = sel.atol
rtol(sel::At) = sel.rtol

Base.show(io::IO, x::At) = print(io, "At(", val(x), ", ", atol(x), ", ", rtol(x), ")")  

struct _True end
struct _False end

selectindices(l::Lookup, sel::At; kw...) = at(l, sel; kw...)
selectindices(l::Lookup, sel::At{<:AbstractVector}; kw...) = _selectvec(l, sel; kw...)

_selectvec(l, sel; kw...) = [selectindices(l, rebuild(sel, v); kw...) for v in val(sel)]

function at(lookup::AbstractCyclic{Cycling}, sel::At; kw...) 
    cycled_sel = rebuild(sel, cycle_val(lookup, val(sel)))
    return at(no_cycling(lookup), cycled_sel; kw...) 
end
function at(lookup::NoLookup, sel::At; err=_True(), kw...) 
    v = val(sel)
    r = round(Int, v)
    at = atol(sel)
    if isnothing(at)
        v == r || _selnotfound_or_nothing(err, lookup, v)
    else
        at >= 0.5 && error("atol must be small than 0.5 for NoLookup")
        isapprox(v, r; atol=at) || _selnotfound_or_nothing(err, lookup, v)
    end
    r in lookup || err isa _False || throw(SelectorError(lookup, sel))
    return r
end
function at(lookup::Lookup, sel::At; kw...)
    at(order(lookup), span(lookup), lookup, val(sel), atol(sel), rtol(sel); kw...)
end
function at(
    ::Ordered, span::Regular, lookup::Lookup{<:Integer}, selval, atol::Nothing, rtol::Nothing;
    err=_True()
)
    x = unwrap(selval)
    Δ = step(span)
    i, remainder = divrem(x - first(lookup), Δ)
    i += firstindex(lookup)
    if remainder == 0 && checkbounds(Bool, lookup, i)
        return i
    else
        return _selnotfound_or_nothing(err, lookup, selval)
    end
end
function at(
    ::Ordered, ::Span, lookup::Lookup{<:IntervalSets.Interval}, selval, atol, rtol::Nothing;
    err=_True()
)
    x = unwrap(selval)
    i = searchsortedlast(lookup, x; lt=(a, b) -> a.left < b.left)
    if lookup[i].left == x.left && lookup[i].right == x.right 
        return i
    else
        return _selnotfound_or_nothing(err, lookup, selval)
    end
end
function at(
    ::Ordered, ::Span, lookup::Lookup{<:Union{Number,Dates.TimeType,AbstractString}}, selval, atol, rtol::Nothing;
    err=_True()
)
    x = unwrap(selval)
    i = searchsortedlast(lookup, x)
    # Try the current index
    if i == firstindex(lookup) - 1
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
# catch-all for an unordered index
function at(::Order, ::Span, lookup::Lookup, selval, atol, rtol::Nothing; err=_True())
    i = findfirst(x -> _is_at(x, unwrap(selval), atol), parent(lookup))
    if i === nothing
        return _selnotfound_or_nothing(err, lookup, selval)
    else
        return i
    end
end

@inline _is_at(x, y, atol) = x == y
@inline _is_at(x::Real, y::Real, atol::Real) = abs(x - y) <= atol
@inline _is_at(x::Real, ys::AbstractArray, atol) = any(y -> _is_at(x, y, atol), ys)
@inline _is_at(xs::AbstractArray, y::Real, atol) = any(x -> _is_at(x, y, atol), xs)

_selnotfound_or_nothing(err::_True, lookup, selval) = _selnotfound(lookup, selval)
_selnotfound_or_nothing(err::_False, lookup, selval) = nothing
@noinline _selnotfound(lookup, selval) = throw(ArgumentError("$selval for not found in $lookup"))

"""
    Near <: IntSelector

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
struct Near{T} <: IntSelector{T}
    val::T
end
Near() = Near(nothing)

selectindices(l::Lookup, sel::Near) = near(l, sel)
selectindices(l::Lookup, sel::Near{<:AbstractVector}) = _selectvec(l, sel)

Base.show(io::IO, x::Near) = print(io, "Near(", val(x), ")")

function near(lookup::AbstractCyclic{Cycling}, sel::Near) 
    cycled_sel = rebuild(sel, cycle_val(lookup, val(sel)))
    near(no_cycling(lookup), cycled_sel) 
end
near(lookup::NoLookup, sel::Near{<:Real}) = max(1, min(round(Int, val(sel)), lastindex(lookup)))
function near(lookup::Lookup, sel::Near)
    !isregular(lookup) && !iscenter(lookup) &&
        throw(ArgumentError("Near is not implemented for Irregular or Explicit with Start or End loci. Use Contains"))
    near(order(lookup), sampling(lookup), lookup, sel)
end
near(order::Order, ::NoSampling, lookup::Lookup, sel::Near) = at(lookup, At(val(sel)))
function near(order::Ordered, ::Union{Intervals,Points}, lookup::Lookup, sel::Near)
    # Unwrap the selector value and adjust it for interval locus if neccessary
    v = unwrap(val(sel))
    # Allow Date and DateTime to be used interchangeably
    if v isa Union{Dates.DateTime,Dates.Date}
        v = eltype(lookup)(v)
    end
    v_adj = _locus_adjust(locus(lookup), v, lookup)
    # searchsortedfirst or searchsortedlast
    searchfunc = _searchfunc(order)
    # Search for the value
    found_i = _inbounds(searchfunc(lookup, v_adj), lookup)

    # Check if this is the lowest possible value allready, and return if so
    if order isa ForwardOrdered
        found_i <= firstindex(lookup) && return found_i
    elseif order isa ReverseOrdered
        found_i >= lastindex(lookup) && return found_i
    end

    # Find which index is nearest, the found index or previous index
    prev_i = found_i - _ordscalar(order)
    dist_to_prev = abs(v_adj - lookup[prev_i])
    dist_to_found = abs(v_adj - lookup[found_i])
    # Compare distance to the found and previous index values
    # We have to use the correct >/>= for Start/End locus
    lessthan = _lt(locus(lookup))
    closest_i = lessthan(dist_to_prev, dist_to_found) ? prev_i : found_i

    return closest_i
end
function near(order::Ordered, ::Intervals, lookup::Lookup{<:IntervalSets.Interval}, sel::Near)
    throw(ArgumentError("`Near` is not yet implemented for lookups of `IntervalSets.Interval`"))
end
function near(::Unordered, ::Union{Intervals,Points}, lookup::Lookup, sel::Near)
    throw(ArgumentError("`Near` has no meaning in an `Unordered` lookup"))
end

_locus_adjust(locus::Center, v, lookup) = v
_locus_adjust(locus::Start, v, lookup) = v - abs(step(lookup)) / 2
_locus_adjust(locus::End, v, lookup) = v + abs(step(lookup)) / 2
_locus_adjust(locus::Start, v::Dates.TimeType, lookup) = v - (v - (v - abs(step(lookup)))) / 2
_locus_adjust(locus::End, v::Dates.TimeType, lookup) = v + (v + abs(step(lookup)) - v) / 2
_locus_adjust(locus::Start, v::Dates.Date, lookup) = v - (v - (v - abs(step(lookup)))) ÷ 2
_locus_adjust(locus::End, v::Dates.Date, lookup) = v + (v + abs(step(lookup)) - v) ÷ 2

"""
    Contains <: IntSelector

    Contains(x)

Selector that selects the interval the value is contained by. If the
interval is not present in the index, an error will be thrown.

Can only be used for [`Intervals`](@ref) or [`Categorical`](@ref).
For [`Categorical`](@ref) it falls back to using [`At`](@ref).
`Contains` should not be confused with `Base.contains` - use `Where(contains(x))` to check for if values are contain in categorical values like strings.

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
struct Contains{T} <: IntSelector{T}
    val::T
end
Contains() = Contains(nothing)

# Filter based on sampling and selector -----------------
selectindices(l::Lookup, sel::Contains; kw...) = contains(l, sel; kw...)
selectindices(l::Lookup, sel::Contains{<:AbstractVector}; kw...) = _selectvec(l, sel; kw...)

Base.show(io::IO, x::Contains) = print(io, "Contains(", val(x), ")")

function contains(lookup::AbstractCyclic{Cycling}, sel::Contains; kw...) 
    cycled_sel = rebuild(sel, cycle_val(lookup, val(sel)))
    return contains(no_cycling(lookup), cycled_sel; kw...) 
end
function contains(l::NoLookup, sel::Contains; kw...) 
    i = Int(val(sel))
    i in l || throw(SelectorError(l, i))
    return i
end
contains(l::Lookup, sel::Contains; kw...) = contains(sampling(l), l, sel; kw...)
# NoSampling (e.g. Categorical) just uses `at`
function contains(::NoSampling, l::Lookup, sel::Contains; kw...)
    at(l, At(val(sel)); kw...)
end
# Points --------------------------------------
function contains(sampling::Points, l::Lookup, sel::Contains; kw...)
    contains(order(l), sampling, l, sel; kw...)
end
function contains(::Order, ::Points, l::Lookup, sel::Contains; kw...)
    at(l, At(val(sel)); kw...)
end
function contains(::Order, ::Points, l::Lookup{<:AbstractArray}, sel::Contains{<:AbstractArray}; 
    kw...
)
    at(l, At(val(sel)); kw...)
end
# Intervals -----------------------------------
function contains(sampling::Intervals, l::Lookup, sel::Contains; err=_True())
    _locus_checkbounds(locus(l), l, sel) || return _selector_error_or_nothing(err, l, sel)
    contains(order(l), span(l), sampling, locus(l), l, sel; err)
end
function contains(
    sampling::Intervals, l::Lookup{<:IntervalSets.Interval}, sel::Contains; 
    err=_True()
)
    v = val(sel)
    interval_sel = Contains(Interval{:closed,:open}(v, v))
    contains(sampling, l, interval_sel; err)
end
function contains(
    ::Intervals, 
    l::Lookup{<:IntervalSets.Interval}, 
    sel::Contains{<:IntervalSets.Interval}; 
    err=_True()
)
    v = val(sel)
    i = searchsortedlast(l, v; by=_by)
    if _in(v, l[i])
        return i
    else
        return _notcontained_or_nothing(err, v)
    end
end
# Regular Intervals ---------------------------
function contains(
    o::Ordered, span::Regular, ::Intervals, locus::Locus, l::Lookup, sel::Contains;
    err=_True()
)
    v = val(sel)
    i = _searchfunc(locus, o)(l, v)
    return check_regular_contains(span, locus, l, v, i, err)
end
function contains(
    o::Ordered, span::Regular, ::Intervals, locus::Center, l::Lookup, sel::Contains;
    err=_True()
)
    v = val(sel) + abs(val(span)) / 2
    i = _searchfunc(locus, o)(l, v)
    return check_regular_contains(span, locus, l, v, i, err)
end

function check_regular_contains(span::Span, locus::Locus, l::Lookup, v, i, err)
    absstep = abs(val(span))
    if (parent(l) isa AbstractRange) || _lt(locus)(v, l[i] + absstep)
        return i
    else
        return _notcontained_or_nothing(err, v)
    end
end

# Explicit Intervals ---------------------------
function contains(
    o::Ordered, span::Explicit, ::Intervals, locus, l::Lookup, sel::Contains;
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
    o::Ordered, span::Irregular, ::Intervals, locus::Locus, l::Lookup, sel::Contains;
    err=_True()
)
    return _searchfunc(locus, o)(l, val(sel))
end
function contains(
    o::Ordered, span::Irregular, ::Intervals, locus::Center, l::Lookup, sel::Contains;
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

_selector_error_or_nothing(err::_True, l, i) = throw(SelectorError(l, i))
_selector_error_or_nothing(err::_False, l, i) = nothing

_notcontained_or_nothing(err::_True, selval) = _notcontainederror(selval)
_notcontained_or_nothing(err::_False, selval) = nothing

_notcontainederror(v) = throw(ArgumentError("No interval contains $v"))

_searchfunc(::Locus, ::ForwardOrdered) = searchsortedlast
_searchfunc(::End, ::ForwardOrdered) = searchsortedfirst
_searchfunc(::Locus, ::ReverseOrdered) = searchsortedfirst
_searchfunc(::End, ::ReverseOrdered) = searchsortedlast

"""
    Between <: ArraySelector

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

╭───────────────────────╮
│ 1×2 DimArray{Int64,2} │
├───────────────────────┴────────────────────────────── dims ┐
  ↓ X Sampled{Int64} 20:10:20 ForwardOrdered Regular Points,
  → Y Sampled{Int64} 5:6 ForwardOrdered Regular Points
└────────────────────────────────────────────────────────────┘
  ↓ →  5  6
 20    4  5
```
"""
struct Between{T<:Union{<:AbstractVector{<:Tuple{Any,Any}},Tuple{Any,Any},Nothing}} <: ArraySelector{T}
    val::T
end
Between(args...) = Between(args)

Base.show(io::IO, x::Between) = print(io, "Between(", val(x), ")")
Base.first(sel::Between) = first(val(sel))
Base.last(sel::Between) = last(val(sel))

abstract type _Side end
struct _Upper <: _Side end
struct _Lower <: _Side end

selectindices(l::Lookup, sel::Union{Between{<:Tuple},Interval}) = between(l, sel)
function selectindices(lookup::Lookup, sel::Between{<:AbstractVector})
    inds = Int[]
    for v in val(sel)
        append!(inds, selectindices(lookup, rebuild(sel, v)))
    end
end

# between
# returns a UnitRange from an Interval
function between(l::Lookup, sel::Between)
    a, b = _sorttuple(sel)
    return between(l, a..b)
end
# NoIndex behaves like `Sampled` `ForwardOrdered` `Points` of 1:N Int
function between(l::NoLookup, sel::Interval)
    x = intersect(sel, first(axes(l, 1))..last(axes(l, 1)))
    return ceil(Int, x.left):floor(Int, x.right) 
end
# function between(l::AbstractCyclic{Cycling}, sel::Interval) 
#     cycle_val(l, sel.x)..cycle_val(l, sel.x)
#     cycled_sel = rebuild(sel; val=)
#     near(no_cycling(lookup), cycled_sel; kw...) 
# end
between(l::Lookup, interval::Interval) = between(sampling(l), l, interval)
# This is the main method called above
function between(sampling::Sampling, l::Lookup, interval::Interval)
    isordered(l) || throw(ArgumentError("Cannot use an interval or `Between` with `Unordered`"))
    between(sampling, order(l), l, interval)
end

function between(sampling::NoSampling, o::Ordered, l::Lookup, interval::Interval)
    between(Points(), o, l, interval)
end

function between(sampling, o::Ordered, l::Lookup, interval::Interval)
    lowerbound, upperbound = bounds(l)
    lowsel, highsel = endpoints(interval)
    a = if lowsel > upperbound
        ordered_lastindex(l) + _ordscalar(o)
    elseif lowsel < lowerbound
        ordered_firstindex(l)
    else
        _between_side(_Lower(), o, span(l), sampling, l, interval, lowsel)
    end
    b = if highsel < lowerbound
        ordered_firstindex(l) - _ordscalar(o)
    elseif highsel > upperbound
        ordered_lastindex(l)
    else
        _between_side(_Upper(), o, span(l), sampling, l, interval, highsel)
    end
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
function _between_side(side::_Lower, o::Ordered, span, ::Points, l, interval, v)
    i = v <= bounds(l)[1] ? ordered_firstindex(l) : _searchfunc(side, o)(l, v)
    return _close_interval(side, l, interval, l[i], i)
end
function _between_side(side::_Upper, o::Ordered, span, ::Points, l, interval, v)
    i = v >= bounds(l)[2] ? ordered_lastindex(l) : _searchfunc(side, o)(l, v)
    return _close_interval(side, l, interval, l[i], i)
end

# Regular Intervals -------------------------
# Adjust the value for the lookup locus before search
function _between_side(side, o::Ordered, ::Regular, ::Intervals, l, interval, v)
    adj = _locus_adjust(side, l)
    v1 = v + adj
    i = _searchfunc(side, o)(l, v1)
    # Sideshift (1 or -1) expands the selection to the outside of any touched intervals
    # We multiply by ordscalar (1 or -1) to allow for reversed lookups.
    i1 = i # + _sideshift(side) * _ordscalar(o)
    # Now find the edge of the cell and check that is not the edge of
    # an open interval. If so shrink the selected range.
    cellbound = if i > lastindex(l)
        l[end] + adj
    elseif i < firstindex(l)
        l[begin] + adj
    else
        l[i] - adj
    end
    return _close_interval(side, l, interval, cellbound, i)
end

# Explicit Intervals -------------------------
function _between_side(side, o::Ordered, span::Explicit, ::Intervals, l, interval, v)
    # Rebuild the lookup with the lower or upper bounds matrix values before searching
    boundsvec = side isa _Lower ? view(val(span), 1, :) : view(val(span), 2, :)
    l1 = rebuild(l; data=boundsvec)
    # Search for the cell boundary
    i = _searchfunc(side, o)(l1, v)
    # Add sideshift (1 or -1) to expand the selection to the outside of any touched intervals
    # If i is in bounds, check the cell boundary is not the edge of an open interval
    return if checkbounds(Bool, l1, i)
        @inbounds cellbound = l1[i]
        _close_interval(side, l1, interval, cellbound, i)
    else
        i
    end
end

# Irregular Intervals -----------------------
#
# This works a little differently to Regular variants, 
# as we have to work with unequal step sizes, calculating them
# as we find close values.
#
# Find the inteval the value falls in.
# We need to special-case Center locus for Irregular
_between_side(side, o, span::Irregular, ::Intervals, l, interval, v) =
    _between_irreg_side(side, locus(l), o, l, interval, v)

function _between_irreg_side(side, locus::Union{Start,End}, o, l, interval, v)
    if v == bounds(l)[1]
        i = ordered_firstindex(l)
        cellbound = v
    elseif v == bounds(l)[2]
        i = ordered_lastindex(l)
        cellbound = v
    else
        s = _ordscalar(o) 
        # Search for the value and offset per order/locus/side
        i = _searchfunc(o)(l, v; lt=_lt(side))
        i -= s * (_locscalar(locus) + _sideshift(side))
        # Get the value on the interval edge
        cellbound = if i < firstindex(l)
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
    return _close_interval(side, l, interval, cellbound, i)
end
function _between_irreg_side(side, locus::Center, o, l, interval, v)
    if v == bounds(l)[1]
        i = ordered_firstindex(l)
        cellbound = v
    elseif v == bounds(l)[2]
        i = ordered_lastindex(l)
        cellbound = v
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
        cellbound = l[i] + shift
    end
    return _close_interval(side, l, interval, cellbound, i)
end


_close_interval(side, l, interval, cellbound, i) = i
function _close_interval(side::_Lower, l, interval::Interval{:open,<:Any}, cellbound, i)
    cellbound == interval.left ? i + _ordscalar(l) : i
end
function _close_interval(side::_Upper, l, interval::Interval{<:Any,:open}, cellbound, i)
    cellbound == interval.right ? i - _ordscalar(l) : i
end

_locus_adjust(side, l) = _locus_adjust(side, locus(l), abs(step(span(l))))
_locus_adjust(::_Lower, locus::Start, step) = zero(step)
_locus_adjust(::_Upper, locus::Start, step) = -step
_locus_adjust(::_Lower, locus::Center, step) = step/2
_locus_adjust(::_Upper, locus::Center, step) = -step/2
_locus_adjust(::_Lower, locus::End, step) = step
_locus_adjust(::_Upper, locus::End, step) = -zero(step)

_locscalar(::Start) = 1
_locscalar(::End) = 0
_sideshift(::_Lower) = -1
_sideshift(::_Upper) = 1
_ordscalar(l) = _ordscalar(order(l))
_ordscalar(::ForwardOrdered) = 1
_ordscalar(::ReverseOrdered) = -1

_lt(::_Lower) = (<)
_lt(::_Upper) = (<=)

_maybeflipbounds(m::Lookup, bounds) = _maybeflipbounds(order(m), bounds)
_maybeflipbounds(o::ForwardOrdered, (a, b)) = (a, b)
_maybeflipbounds(o::ReverseOrdered, (a, b)) = (b, a)
_maybeflipbounds(o::Unordered, (a, b)) = (a, b)

"""
    Touches <: ArraySelector

    Touches(a, b)

Selector that retreives all indices touching the closed interval 2 values,
for the maximum possible area that could interact with the supplied range.

This can be better than `..` when e.g. subsetting an area to rasterize, as
you may wish to include pixels that just touch the area, rather than those
that fall within it.

Touches is different to using closed intervals when the lookups also
contain intervals - if any of the intervals touch, they are included.
With `..` they are discarded unless the whole cell interval falls inside
the selector interval.

## Example

```jldoctest
using DimensionalData

A = DimArray([1 2 3; 4 5 6], (X(10:10:20), Y(5:7)))
A[X(Touches(15, 25)), Y(Touches(4, 6.5))]

# output
╭───────────────────────╮
│ 1×2 DimArray{Int64,2} │
├───────────────────────┴────────────────────────────── dims ┐
  ↓ X Sampled{Int64} 20:10:20 ForwardOrdered Regular Points,
  → Y Sampled{Int64} 5:6 ForwardOrdered Regular Points
└────────────────────────────────────────────────────────────┘
  ↓ →  5  6
 20    4  5
```
"""
struct Touches{T<:Union{<:AbstractVector{<:Tuple{Any,Any}},Tuple{Any,Any},Nothing,Extents.Extent}} <: ArraySelector{T}
    val::T
end
Touches(a, b) = Touches((a, b))

Base.first(sel::Touches) = first(val(sel))
Base.last(sel::Touches) = last(val(sel))

selectindices(l::Lookup, sel::Touches) = touches(l, sel)
function selectindices(lookup::Lookup, sel::Touches{<:AbstractVector})
    inds = Int[]
    for v in val(sel)
        append!(inds, selectindices(lookup, rebuild(sel, v)))
    end
end

# touches for tuple intervals
# returns a UnitRange like Touches/Interval but for cells contained
# NoIndex behaves like `Sampled` `ForwardOrdered` `Points` of 1:N Int
touches(l::NoLookup, sel::Touches) = between(l, Interval(val(sel)...))
touches(l::Lookup, sel::Touches) = touches(sampling(l), l, sel)
# This is the main method called above
function touches(sampling::Sampling, l::Lookup, sel::Touches)
    o = order(l)
    o isa Unordered && throw(ArgumentError("Cannot use an sel or `Between` with Unordered"))
    touches(sampling, o, l, sel)
end

function touches(sampling::NoSampling, o::Ordered, l::Lookup, sel::Touches)
    touches(Points(), o, l, sel)
end

function touches(sampling, o::Ordered, l::Lookup, sel::Touches)
    lowerbound, upperbound = bounds(l)
    lowsel, highsel = val(sel)
    a = if lowsel > upperbound
        ordered_lastindex(l) + _ordscalar(o)
    elseif lowsel < lowerbound
        ordered_firstindex(l)
    else
        _touches(_Lower(), o, span(l), sampling, l, sel, lowsel)
    end
    b = if highsel < lowerbound
        ordered_firstindex(l) - _ordscalar(o)
    elseif highsel > upperbound
        ordered_lastindex(l)
    else
        _touches(_Upper(), o, span(l), sampling, l, sel, highsel)
    end
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
function _touches(side::_Lower, o::Ordered, span, ::Points, l, sel, v)
    i = v <= bounds(l)[1] ? ordered_firstindex(l) : _searchfunc(side, o)(l, v)
    return i
end
function _touches(side::_Upper, o::Ordered, span, ::Points, l, sel, v)
    i = v >= bounds(l)[2] ? ordered_lastindex(l) : _searchfunc(side, o)(l, v)
    return i
end

# Regular Intervals -------------------------
# Adjust the value for the lookup locus before search
function _touches(side, o::Ordered, ::Regular, ::Intervals, l, sel, v)
    adj = _locus_adjust(side, l)
    v1 = v + adj
    i = _searchfunc(side, o)(l, v1)
    # Sideshift (1 or -1) expands the selection to the outside of any touched sels
    # We multiply by ordscalar (1 or -1) to allow for reversed lookups.
    i1 = i + _sideshift(side) * _ordscalar(o)
    # Finally we need to make sure i2 is still inbounds after adding sideshift
    return min(max(i1, firstindex(l)), lastindex(l))
end

# Explicit Intervals -------------------------
function _touches(side, o::Ordered, span::Explicit, ::Intervals, l, sel, v)
    # Rebuild the lookup with the lower or upper bounds matrix values before searching
    boundsvec = side isa _Lower ? view(val(span), 1, :) : view(val(span), 2, :)
    l1 = rebuild(l; data=boundsvec)
    # Search for the cell boundary
    i = _searchfunc(side, o)(l1, v)
    # Add sideshift (1 or -1) to expand the selection to the outside of any touched sels
    i1 = i + _sideshift(side) * _ordscalar(o)
    # Finally we need to make sure i2 is still inbounds after adding sideshift
    return min(max(i1, firstindex(l)), lastindex(l))
end

# Irregular Intervals -----------------------
#
# This works a little differently to Regular variants, 
# as we have to work with unequal step sizes, calculating them
# as we find close values.
#
# Find the inteval the value falls in.
# We need to special-case Center locus for Irregular
_touches(side, o, span::Irregular, ::Intervals, l, sel, v) =
    _touches_irreg_side(side, locus(l), o, l, sel, v)

function _touches_irreg_side(side, locus::Union{Start,End}, o, l, sel, v)
    i = if v == bounds(l)[1]
        ordered_firstindex(l)
    elseif v == bounds(l)[2]
        ordered_lastindex(l)
    else
        # Search for the value and offset per order/locus/side
        _searchfunc(o)(l, v; lt=_lt(side)) - _ordscalar(o) * _locscalar(locus)
    end
    return i
end
function _touches_irreg_side(side, locus::Center, o, l, sel, v)
    if v == bounds(l)[1]
        i = ordered_firstindex(l)
    elseif v == bounds(l)[2]
        i = ordered_lastindex(l)
    else
        i = _searchfunc(o)(l, v; lt=_lt(side))
        i1 = i - _ordscalar(o)
        # We are at the start or end, return i
        if (i1 < firstindex(l) ||  i1 > lastindex(l)) 
            i
        else
            # Calculate the size of the current step
            half_step = abs(l[i] - l[i1]) / 2
            distance = abs(l[i] - v)
            # Use the correct less than </<= to match sel bounds
            i = if _lt(side)(distance, half_step)
                i
            else
                i1
            end
        end
    end
    return i
end


"""
    Where <: ArraySelector

    Where(f::Function)

Selector that filters a dimension lookup by any function that
accepts a single value and returns a `Bool`.

## Example

```jldoctest
using DimensionalData

A = DimArray([1 2 3; 4 5 6], (X(10:10:20), Y(19:21)))
A[X(Where(x -> x > 15)), Y(Where(x -> x in (19, 21)))]

# output

╭───────────────────────╮
│ 1×2 DimArray{Int64,2} │
├───────────────────────┴─────────────────────────────── dims ┐
  ↓ X Sampled{Int64} [20] ForwardOrdered Irregular Points,
  → Y Sampled{Int64} [19, 21] ForwardOrdered Irregular Points
└─────────────────────────────────────────────────────────────┘
  ↓ →  19  21
 20     4   6
```
"""
struct Where{T} <: ArraySelector{T}
    f::T
end

val(sel::Where) = sel.f

Base.show(io::IO, x::Where) = print(io, "Where(", repr(val(x)), ")")

# Yes this is everything. `Where` doesn't need lookup specialisation
@inline function selectindices(lookup::Lookup, sel::Where)
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
A[X=All(At(10.0), At(50.0)), Ti=All(1u"s"..10u"s", 90u"s"..100u"s")]

# output

╭───────────────────────╮
│ 2×4 DimArray{Int64,2} │
├───────────────────────┴──────────────────────────────────────────────── dims ┐
  ↓ X  Sampled{Float64} [10.0, 50.0] ForwardOrdered Irregular Points,
  → Ti Sampled{Unitful.Quantity{Int64, 𝐓, Unitful.FreeUnits{(s,), 𝐓, nothing}}} [1 s, 6 s, 91 s, 96 s] ForwardOrdered Irregular Points
└──────────────────────────────────────────────────────────────────────────────┘
  ↓ →  1 s  6 s  91 s  96 s
 10.0    1    2    19    20
 50.0    3    6    57    60
```
"""
struct All{S<:Tuple{Vararg{SelectorOrInterval}}} <: Selector{S}
    selectors::S
end
All(args::SelectorOrInterval...) = All(args)

Base.show(io::IO, x::All) = print(io, "All(", x.selectors, ")")

@inline function selectindices(lookup::Lookup, sel::All)
    results = map(s -> selectindices(lookup, s), sel.selectors)
    sort!(union(results...))
end


# selectindices ==========================================================================


"""
    selectindices(lookups, selectors)

Converts [`Selector`](@ref) to regular indices.
"""
function selectindices end
@inline selectindices(lookups::LookupTuple, s1, ss...) = selectindices(lookups, (s1, ss...))
@inline selectindices(lookups::LookupTuple, selectors::Tuple) =
    map((l, s) -> selectindices(l, s), lookups, selectors)
@inline selectindices(lookups::LookupTuple, selectors::Tuple{}) = ()
# @inline selectindices(dim::Lookup, sel::Val) = selectindices(val(dim), At(sel))
# Standard indices are just returned.
@inline selectindices(::Lookup, sel::StandardIndices) = sel
# Vectors are mapped
@inline selectindices(lookup::Lookup, sel::Selector{<:AbstractVector}) =
    [selectindices(lookup, rebuild(sel; val=v)) for v in val(sel)]


# Unaligned Lookup ------------------------------------------

# select_unalligned_indices is callled directly from dims2indices

# We use the transformation from the first unalligned dim.
# In practice the others could be empty.
function select_unalligned_indices(lookups::LookupTuple, sel::Tuple{IntSelector,Vararg{IntSelector}})
    transformed = transformfunc(lookups[1])(map(val, sel))
    map(_transform2int, lookups, sel, transformed)
end
function select_unalligned_indices(lookups::LookupTuple, sel::Tuple{Selector,Vararg{Selector}})
    throw(ArgumentError("only `Near`, `At` or `Contains` selectors currently work on `Unalligned` lookups"))
end

_transform2int(lookup::AbstractArray, ::Near, x) = min(max(round(Int, x), firstindex(lookup)), lastindex(lookup))
_transform2int(lookup::AbstractArray, ::Contains, x) = round(Int, x)
_transform2int(lookup::AbstractArray, sel::At, x) = _transform2int(sel, x, atol(sel))
_transform2int(::At, x, atol::Nothing) = convert(Int, x)
function _transform2int(::At, x, atol)
    i = round(Int, x)
    abs(x - i) <= atol ? i : _transform_notfound(x)
end

@noinline _transform_notfound(x) = throw(ArgumentError("$x not found in Transformed lookups"))


# Shared utils ============================================================================

# Return an inbounds index
_inbounds(is::Tuple, lookup::Lookup) = map(i -> _inbounds(i, lookup), is)
function _inbounds(i::Int, lookup::Lookup)
    if i > lastindex(lookup)
        lastindex(lookup)
    elseif i <= firstindex(lookup)
        firstindex(lookup)
    else
        i
    end
end

_sorttuple(sel::Between) = _sorttuple(val(sel))
_sorttuple((a, b)::Tuple{<:Any,<:Any}) = a < b ? (a, b) : (b, a)

_lt(::Locus) = (<)
_lt(::End) = (<=)
_gt(::Locus) = (>=)
_gt(::End) = (>)

_locus_checkbounds(loc, lookup::Lookup, sel::Selector) =  _locus_checkbounds(loc, bounds(lookup), val(sel))
_locus_checkbounds(loc, (l, h)::Tuple, v) = !(_lt(loc)(v, l) || _gt(loc)(v, h))

_searchfunc(::ForwardOrdered) = searchsortedfirst
_searchfunc(::ReverseOrdered) = searchsortedlast

_searchfunc(::_Lower, ::ForwardOrdered) = searchsortedfirst
_searchfunc(::_Lower, ::ReverseOrdered) = searchsortedlast
_searchfunc(::_Upper, ::ForwardOrdered) = searchsortedlast
_searchfunc(::_Upper, ::ReverseOrdered) = searchsortedfirst

# by helpers so sort and searchsorted works on more types
_by(x::Pair) = _by(x[1])
_by(x::Tuple) = map(_by, x)
_by(x::AbstractRange) = first(x)
_by(x::IntervalSets.Interval) = x.left
_by(x) = x

_in(needle::Dates.TimeType, haystack::Dates.TimeType) = needle == haystack
_in(needle, haystack) = needle in haystack
_in(needles::Tuple, haystacks::Tuple) = all(map(_in, needles, haystacks))
_in(needle::Interval, haystack::ClosedInterval) = needle.left in haystack && needle.right in haystack
_in(needle::Interval{<:Any,:open}, haystack::Interval{:closed,:open}) = needle.left in haystack && needle.right in haystack
_in(needle::Interval{:open,<:Any}, haystack::Interval{:open,:closed}) = needle.left in haystack && needle.right in haystack
_in(needle::OpenInterval, haystack::OpenInterval) = needle.left in haystack && needle.right in haystack

hasselection(lookup::Lookup, sel::At) = at(lookup, sel; err=_False()) === nothing ? false : true
hasselection(lookup::Lookup, sel::Contains) = contains(lookup, sel; err=_False()) === nothing ? false : true
# Near and Between only fail on Unordered
# Otherwise Near returns the nearest index, and Between an empty range
hasselection(lookup::Lookup, ::Near) = isordered(lookup) ? true : false
hasselection(lookup::Lookup, ::Union{Interval,Between}) = isordered(lookup) ? true : false
