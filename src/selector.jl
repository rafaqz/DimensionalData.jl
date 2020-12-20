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
At(val; atol=nothing, rtol=nothing) =
    At{typeof.((val, atol, rtol))...}(val, atol, rtol)

atol(sel::At) = sel.atol
rtol(sel::At) = sel.rtol

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

"""
    Contains <: Selector

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

DimArray (named ) with dimensions:
 X: 20:10:20 (Sampled: Ordered Regular Points)
 Y: 5:6 (Sampled: Ordered Regular Points)
and data: 1×2 Array{Int64,2}
 4  5
```
"""
struct Between{T<:Union{Tuple{Any,Any},Nothing}} <: Selector{T}
    val::T
end
Between(args...) = Between(args)

"""
    Where <: Selector

    Where(f::Function)

Selector that filters a dimension by any function that accepts
a single value from the index and returns a `Bool`.

## Example

```jldoctest
using DimensionalData

A = DimArray([1 2 3; 4 5 6], (X(10:10:20), Y(19:21)))
A[X(Where(x -> x > 15)), Y(Where(x -> x in (19, 21)))]

# output

DimArray (named ) with dimensions:
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

@inline sel2indices(x, ls...) = sel2indices(dims(x), ls...)
@inline sel2indices(dims::Tuple, l1, ls...) = sel2indices(dims, (l1, ls...))
@inline sel2indices(dims::Tuple, lookup::Tuple) =
    map((d, l) -> sel2indices(d, l), dims, lookup)
@inline sel2indices(dims::Tuple, lookup::Tuple{}) = ()
@inline sel2indices(dim::Dimension, sel) = _sel2indices(dim, maybeselector(sel))

# First filter based on rough selector properties -----------------

# Standard indices are just returned.
@inline _sel2indices(::Dimension, sel::StandardIndices) = sel
# Vectors are mapped
@inline _sel2indices(dim::Dimension, sel::Selector{<:AbstractVector}) =
    [_sel2indices(mode(dim), dim, rebuild(sel, v)) for v in val(sel)]
@inline _sel2indices(dim::Dimension, sel::Selector) = _sel2indices(mode(dim), dim, sel)

# Where selector ==============================
# Yes this is everything. Where doesn't need mode specialisation  
@inline _sel2indices(dim::Dimension, sel::Where) =
    [i for (i, v) in enumerate(index(dim)) if sel.f(v)]

# Then dispatch based on IndexMode -----------------
# Selectors can have varied behaviours depending on the index mode.

# Noindex Contains just converts the selector to standard indices. Implemented
# so the Selectors actually work, not because what they do is useful or interesting.
@inline _sel2indices(mode::NoIndex, dim::Dimension, sel::Union{At,Near,Contains}) = val(sel)
@inline _sel2indices(mode::NoIndex, dim::Dimension, sel::Union{Between}) =
    val(sel)[1]:val(sel)[2]
@inline _sel2indices(mode::Categorical, dim::Dimension, sel::Selector) =
    if sel isa Union{Contains,Near}
        _sel2indices(Points(), mode, dim, At(val(sel)))
    else
        _sel2indices(Points(), mode, dim, sel)
    end
@inline _sel2indices(mode::AbstractSampled, dim::Dimension, sel::Selector) =
    _sel2indices(sampling(mode), mode, dim, sel)

# For Sampled filter based on sampling type and selector -----------------

@inline _sel2indices(sampling::Sampling, mode::IndexMode, dim::Dimension, sel::At) =
    at(sampling, mode, dim, sel)
@inline _sel2indices(sampling::Sampling, mode::IndexMode, dim::Dimension, sel::Near) = begin
    span(mode) isa Irregular && locus(mode) isa Union{Start,End} && _nearirregularerror()
    near(sampling, mode, dim, sel)
end
@inline _sel2indices(sampling::Points, mode::IndexMode, dim::Dimension, sel::Contains) = 
    _containspointserror()
@inline _sel2indices(sampling::Intervals, mode::IndexMode, dim::Dimension, sel::Contains) =
    contains(sampling, mode, dim, sel)
@inline _sel2indices(sampling::Sampling, mode::IndexMode, dim::Dimension, sel::Between{<:Tuple}) =
    between(sampling, mode, dim, sel)

@noinline _nearirregularerror() = throw(ArgumentError("Near is not implemented for Irregular with Start or End loci. Use Contains"))
@noinline _containspointserror() = throw(ArgumentError("`Contains` has no meaning with `Points`. Use `Near`"))


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
    map(_transform2int, sel, transformed)
end

_transform2int(::At, x) = convert(Int, x)
_transform2int(::Near, x) = round(Int, x)


# Selector methods

# at =============================================================================

@inline at(dim::Dimension, sel::At) = at(sampling(mode(dim)), mode(dim), dim, sel)
@inline function at(::Sampling, mode::IndexMode, dim::Dimension, sel::At)
    relate(dim, at(dim, val(sel), atol(sel), rtol(sel)))
end
@inline function at(dim::Dimension{<:Val{Index}}, selval, atol::Nothing, rtol::Nothing) where Index
    i = findfirst(x -> x == unwrap(selval), Index)
    i == nothing && _selvalnotfound(dim, selval)
    return i
end
@inline function at(dim::Dimension{<:Val{Index}}, selval::Val{X}, atol::Nothing, rtol::Nothing) where {Index,X}
    i = findfirst(x -> x == X, Index)
    i == nothing && _selvalnotfound(dim, selval)
    return i
end
@inline function at(dim::Dimension, selval, atol::Nothing, rtol::Nothing)
    i = findfirst(x -> x == unwrap(selval), index(dim))
    i == nothing && _selvalnotfound(dim, selval)
    return i
end

@noinline _selvalnotfound(dim, selval) = throw(ArgumentError("$selval not found in $dim"))


# near ===========================================================================

# Finds the nearest point in the index, adjusting for locus if necessary.
# In Intevals we are finding the nearest point to the center of the interval.

near(dim::Dimension, sel::Near) = near(sampling(mode(dim)), mode(dim), dim, sel)
function near(::Sampling, mode::IndexMode, dim::Dimension, sel::Near)
    order = indexorder(dim)
    order isa UnorderedIndex && _nearunorderederror()
    locus = DD.locus(dim)

    v = _locus_adjust(locus, unwrap(val(sel)), dim)
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

@noinline _nearunorderederror() = throw(ArgumentError("`Near` has no meaning in an `Unordered` index"))

_locus_adjust(locus::Center, v, dim) = v
_locus_adjust(locus::Start, v, dim) = v - abs(step(dim)) / 2
_locus_adjust(locus::End, v, dim) = v + abs(step(dim)) / 2
_locus_adjust(locus::Start, v::DateTime, dim) = v - (v - (v - abs(step(dim)))) / 2
_locus_adjust(locus::End, v::DateTime, dim) = v + (v + abs(step(dim)) - v) / 2


# contains ================================================================================

# Finds which interval contains a point

function contains(dim::Dimension, sel::Contains)
    contains(sampling(mode(dim)), mode(dim), dim, sel)
end
# Points --------------------------------------
@noinline function contains(::Points, ::IndexMode, dim::Dimension, sel::Contains)
    throw(ArgumentError("Points IndexMode cannot use 'Contains', use 'Near' instead."))
end
# Intervals -----------------------------------
function contains(sampling::Intervals, mode::IndexMode, dim::Dimension, sel::Contains)
    relate(dim, contains(span(mode), sampling, indexorder(mode), locus(mode), dim, sel))
end
# Regular Intervals ---------------------------
function contains(span::Regular, ::Intervals, order, locus, dim::Dimension, sel::Contains)
    v = val(sel); s = abs(val(span))
    _locus_checkbounds(locus, bounds(dim), v)
    i = _whichsearch(locus, order)(order, dim, _maybeaddhalf(locus, s, v))
    # Check the value is in this cell. 
    # It is always for AbstractRange but might not be for Val tuple or Vector.
    if !(val(dim) isa AbstractRange) 
        _lt(locus)(v, dim[i] + s) || _notcontainederror(v)
    end
    i
end
# Explicit Intervals ---------------------------
function contains(span::Explicit, ::Intervals, order, locus, dim::Dimension, sel::Contains)
    x = val(sel)
    i = searchsortedlast(view(val(span), 1, :), x; rev=isrev(order))
    if i <= 0 || val(span)[2, i] < x 
        _notcontainederror(x)
    end
    i
end
# Irregular Intervals -------------------------
function contains(span::Irregular, ::Intervals, order::IndexOrder, locus::Locus, dim::Dimension, sel::Contains)
    _locus_checkbounds(locus, bounds(span), val(sel))
    _whichsearch(locus, order)(order, dim, val(sel))
end
function contains(span::Irregular, ::Intervals, order::IndexOrder, locus::Center, dim::Dimension, sel::Contains)
    v = val(sel)
    _locus_checkbounds(locus, bounds(span), v)
    i = _searchfirst(order, dim, v)
    i <= firstindex(dim) && return firstindex(dim)
    i > lastindex(dim) && return lastindex(dim)
    
    interval = abs(dim[i] - dim[i - 1])
    distance = abs(dim[i] - v)
    _order_lt(order)(interval / 2, distance) ? i - 1 : i
end 

@noinline _notcontainederror(v) = throw(ArgumentError("No interval contains $(v)"))

_whichsearch(::Locus, ::ForwardIndex) = _searchlast
_whichsearch(::Locus, ::ReverseIndex) = _searchfirst
_whichsearch(::End, ::ForwardIndex) = _searchfirst
_whichsearch(::End, ::ReverseIndex) = _searchlast

_maybeaddhalf(::Locus, s, v) = v
_maybeaddhalf(::Center, s, v) = v + s / 2

_order_lt(::ForwardIndex) = (<)
_order_lt(::ReverseIndex) = (<=)


# between ================================================================================

# Finds all values between two points, adjusted for locus where necessary

struct _Upper end
struct _Lower end

between(dim::Dimension, sel::Between) = between(sampling(mode(dim)), mode(dim), dim, sel)
function between(sampling::Sampling, mode::IndexMode, dim::Dimension, sel::Between)
    order = indexorder(dim)
    order isa UnorderedIndex && throw(ArgumentError("Cannot use `Between` with UnorderedIndex"))
    a, b = between(sampling, order, mode, dim, sel)
    relate(dim, a:b)
end
# Points ------------------------------------
function between(sampling::Points, o::IndexOrder, ::IndexMode, dim::Dimension, sel::Between)
    b1, b2 = _maybeflip(o, _sorttuple(sel))
    s1, s2 = _maybeflip(o, (_searchfirst, _searchlast))
    _inbounds((s1(o, dim, b1), s2(o, dim, b2)), dim)
end
# Intervals -------------------------
function between(sampling::Intervals, o::IndexOrder, mode::IndexMode, dim::Dimension, sel::Between)
    between(span(mode), sampling, o, mode, dim, sel)
end
# Regular Intervals -------------------------
function between(span::Regular, ::Intervals, o::IndexOrder, mode::IndexMode, dim::Dimension, sel::Between)
    b1, b2 = _maybeflip(o, _sorttuple(sel) .+ _locus_adjust(mode))
    _inbounds((_searchfirst(o, dim, b1), _searchlast(o, dim, b2)), dim)
end
# Explicit Intervals -------------------------
function between(span::Explicit, ::Intervals, o::IndexOrder, mode::IndexMode, dim::Dimension, sel::Between)
    _inbounds(
        (searchsortedfirst(view(val(span), 1, :), first(val(sel)); rev=isrev(o), lt=<),
         searchsortedlast(view(val(span), 2, :), last(val(sel)); rev=isrev(o), lt=<)),
        dim
    )
end
# Irregular Intervals -----------------------
function between(span::Irregular, ::Intervals, o::IndexOrder, mode::IndexMode, d::Dimension, sel::Between)
    l, h = _sorttuple(sel) 
    bl, bh = bounds(span)
    a = l <= bl ? _dimlower(o, d) : between(_Lower(), locus(mode), o, d, l)
    b = h >= bh ? _dimupper(o, d) : between(_Upper(), locus(mode), o, d, h)
    _maybeflip(o, (a, b))
end
function between(x, locus::Union{Start,End}, o::IndexOrder, d::Dimension, v)
    _search(x, o, d, v) - _ordscalar(o) * (_locscalar(locus) + _endshift(x))
end
function between(x, locus::Center, o::IndexOrder, d::Dimension, v)
    r = _ordscalar(o); sh = _endshift(x)
    i = _search(x, o, d, v)
    interval = abs(d[i] - d[i-r])
    distance = abs(d[i] - v)
    # Use the right >/>= to match interval bounds
    _lt(x)(distance, (interval / 2)) ? i - sh * r : i - (1 + sh) * r
end

_locus_adjust(mode) = _locus_adjust(locus(mode), abs(step(span(mode))))
_locus_adjust(locus::Start, step) = zero(step), -step
_locus_adjust(locus::Center, step) = step/2, -step/2
_locus_adjust(locus::End, step) = step, zero(step)

_locscalar(::Start) = 1
_locscalar(::End) = 0
_endshift(::_Lower) = -1
_endshift(::_Upper) = 1
_ordscalar(::ForwardIndex) = 1
_ordscalar(::ReverseIndex) = -1

_search(x, order, dim, v) = _inbounds(_searchorder(order)(order, dim, v, _lt(x)), dim)

_lt(::_Lower) = (<)
_lt(::_Upper) = (<=)


# Shared utils ============================================================================

_searchlast(o::IndexOrder, dim::Dimension, v, lt=<) =
    searchsortedlast(index(dim), unwrap(v); rev=isrev(o), lt=lt)
_searchlast(o::IndexOrder, dim::Dimension{<:Val{Index}}, v, lt=<) where Index =
    searchsortedlast(Index, unwrap(v); rev=isrev(o), lt=lt)

_searchfirst(o::IndexOrder, dim::Dimension, v, lt=<) =
    searchsortedfirst(index(dim), unwrap(v); rev=isrev(o), lt=lt)
_searchfirst(o::IndexOrder, dim::Dimension{<:Val{Index}}, v, lt=<) where Index =
    searchsortedfirst(Index, unwrap(v); rev=isrev(o), lt=lt)

_asfunc(::Type{typeof(<)}) = <
_asfunc(::Type{typeof(<=)}) = <=

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
