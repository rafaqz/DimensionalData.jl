
"""
    LookupTrait

Abstract supertype of all traits of a [`Lookup`](@ref).

These modify the behaviour of the lookup index.

The term "Trait" is used loosely - these may be fields of an object
of traits hard-coded to specific types.
"""
abstract type LookupTrait end

"""
    Order <: LookupTrait

Traits for the order of a [`Lookup`](@ref). These determine how
`searchsorted` finds values in the index, and how objects are plotted.
"""
abstract type Order <: LookupTrait end

"""
    Ordered <: Order

Supertype for the order of an ordered [`Lookup`](@ref),
including [`ForwardOrdered`](@ref) and [`ReverseOrdered`](@ref).
"""
abstract type Ordered <: Order end

"""
    AutoOrder <: Order

    AutoOrder()

Specifies that the `Order` of a `Lookup` will be found automatically
where possible.
"""
struct AutoOrder <: Order end

"""
    ForwardOrdered <: Ordered

    ForwardOrdered()

Indicates that the `Lookup` index is in the normal forward order.
"""
struct ForwardOrdered <: Ordered end

"""
    ReverseOrdered <: Ordered

    ReverseOrdered()

Indicates that the `Lookup` index is in the reverse order.
"""
struct ReverseOrdered <: Ordered end

"""
    Unordered <: Order

    Unordered()

Indicates that `Lookup` is unordered.

This means the index cannot be searched with `searchsortedfirst`
or similar optimised methods - instead it will use `findfirst`.
"""
struct Unordered <: Order end

isrev(x) = isrev(typeof(x))
isrev(::Type{<:ForwardOrdered}) = false
isrev(::Type{<:ReverseOrdered}) = true

"""
   Position <: LookupTrait

Abstract supertype of types that indicate the locus of index values
where they represent [`Intervals`](@ref).

These allow for values array cells to align with the [`Start`](@ref),
[`Center`](@ref), or [`End`](@ref) of values in the lookup index.

This means they can be plotted with correct axis markers, and allows automatic
converrsions to between formats with different standards (such as NetCDF and GeoTiff).
"""
abstract type Position <: LookupTrait end

"""
    Center <: Position

    Center()

Used to specify lookup values correspond to the center locus in an interval.
"""
struct Center <: Position end

"""
    Start <: Position

    Start()

Used to specify lookup values correspond to the start locus of an interval.
"""
struct Start <: Position end

"""
    Begin <: Position

    Begin()

Used to specify the `begin` index of a `Dimension` axis. 
as regular `begin` will not work with named dimensions.

Can be used with `:` to create a `BeginEndRange` or 
`BeginEndStepRange`.
"""
struct Begin <: Position end

"""
    End <: Position

    End()

Used to specify the `end` index of a `Dimension` axis, 
as regular `end` will not work with named dimensions.
Can be used with `:` to create a `BeginEndRange` or 
`BeginEndStepRange`.

Also used to specify lookup values correspond to the end 
locus of an interval.
"""
struct End <: Position end

"""
    AutoPosition <: Position

    AutoPosition()

Indicates a interval where the index locus is not yet known.
This will be filled with a default value on object construction.
"""
struct AutoPosition <: Position end

# Locus does not include `Begin` 
const Locus = Union{AutoPosition,Start,Center,End}
const AutoLocus = AutoPosition

"""
    Sampling <: LookupTrait

Indicates the sampling method used by the index: [`Points`](@ref)
or [`Intervals`](@ref).
"""
abstract type Sampling <: LookupTrait end

struct NoSampling <: Sampling end
locus(sampling::NoSampling) = Center()

struct AutoSampling <: Sampling end
locus(sampling::AutoSampling) = AutoPosition()

"""
    Points <: Sampling

    Points()

[`Sampling`](@ref) lookup where single samples at exact points.

These are always plotted at the center of array cells.
"""
struct Points <: Sampling end

locus(sampling::Points) = Center()

"""
    Intervals <: Sampling

    Intervals(locus::Position)

[`Sampling`](@ref) specifying that sampled values are the mean (or similar)
value over an _interval_, rather than at one specific point.

Intervals require a [`locus`](@ref) of [`Start`](@ref), [`Center`](@ref) or
[`End`](@ref) to define the location in the interval that the index values refer to.
"""
struct Intervals{P} <: Sampling
    locus::P
end
Intervals() = Intervals(AutoPosition())

locus(sampling::Intervals) = sampling.locus
rebuild(::Intervals, locus) = Intervals(locus)

"""
    Span <: LookupTrait

Defines the type of span used in a [`Sampling`](@ref) index.
These are [`Regular`](@ref) or [`Irregular`](@ref).
"""
abstract type Span <: LookupTrait end

struct NoSpan <: Span end

Adapt.adapt_structure(to, s::Span) = s

"""
    AutoSpan <: Span

    AutoSpan()

The span will be guessed and replaced in `format` or `set`.
"""
struct AutoSpan <: Span end

struct AutoStep end
struct AutoBounds end
struct AutoDim end

"""
    Regular <: Span

    Regular(step=AutoStep())

`Points` or `Intervals` that have a fixed, regular step.
"""
struct Regular{S} <: Span
    step::S
end
Regular() = Regular(AutoStep())

val(span::Regular) = span.step

Base.step(span::Regular) = span.step
Base.:(==)(l1::Regular, l2::Regular) = val(l1) == val(l2)

"""
    Irregular <: Span

    Irregular(bounds::Tuple)
    Irregular(lowerbound, upperbound)

`Points` or `Intervals` that have an `Irrigular` step size. To enable bounds tracking
and accuract selectors, the starting bounds are provided as a 2 tuple, or 2 arguments.
`(nothing, nothing)` is acceptable input, the bounds will be guessed from the index,
but may be innaccurate.
"""
struct Irregular{B<:Union{<:Tuple{<:Any,<:Any},AutoBounds}} <: Span
    bounds::B
end
Irregular() = Irregular(AutoBounds())
Irregular(lowerbound, upperbound) = Irregular((lowerbound, upperbound))

bounds(span::Irregular) = span.bounds
val(span::Irregular) = span.bounds

Base.:(==)(l1::Irregular, l2::Irregular) = val(l1) == val(l2)

"""
    Explicit(bounds::AbstractMatix)

Intervals where the span is explicitly listed for every interval.

This uses a matrix where with length 2 columns for each index value,
holding the lower and upper bounds for that specific index.
"""
struct Explicit{B} <: Span
    val::B
end
Explicit() = Explicit(AutoBounds())

val(span::Explicit) = span.val
Base.:(==)(l1::Explicit, l2::Explicit) = val(l1) == val(l2)

Adapt.adapt_structure(to, s::Explicit) = Explicit(Adapt.adapt_structure(to, val(s)))

"""
    AutoValues

Detect `Lookup` values from the context. This is used in `NoLookup` to simply
use the array axis as the index when the array is constructed, and in `set` to
change the `Lookup` type without changing the index values.
"""
struct AutoValues <: AbstractVector{Int} end

Base.size(::AutoValues) = (0,)
