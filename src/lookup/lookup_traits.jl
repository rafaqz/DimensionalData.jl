

"""
    LookupTrait

Abstract supertype of all traits of a [`Lookup`](@ref).

These modify the behaviour of the lookup index.
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
like [`ForwardOrdered`](@ref) and [`ReverseOrdered`](@ref).
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

Trait indicating that the array or lookup has no order.
This means the index cannot be searched with `searchsortedfirst`,
or similar methods, and that plotting order does not matter.
"""
struct Unordered <: Order end

isrev(x) = isrev(typeof(x))
isrev(::Type{<:ForwardOrdered}) = false
isrev(::Type{<:ReverseOrdered}) = true

"""
   Locus <: LookupTrait

Abstract supertype of types that indicate the position of index values in cells.

These allow for values array cells to align with the `Start`,
[`Center`](@ref), or [`End`](@ref) of values in the lookup index.

This means they can be plotted with correct axis markers, and allows automatic
converrsions to between formats with different standards (such as NetCDF and GeoTiff).
"""
abstract type Locus <: LookupTrait end

"""
    Center <: Locus

    Center()

Indicates a lookup value is for the center of its corresponding array cell,
in the direction of the lookup index order.
"""
struct Center <: Locus end

"""
    Start <: Locus

    Start()

Indicates a lookup value is for the start of its corresponding array cell,
in the direction of the lookup index order.
"""
struct Start <: Locus end

"""
    End <: Locus

    End()

Indicates a lookup value is for the end of its corresponding array cell,
in the direction of the lookup index order.
"""
struct End <: Locus end

"""
    AutoLocus <: Locus

    AutoLocus()

Indicates a lookup where the index position is not yet known.
This will be filled with a default on object construction.
"""
struct AutoLocus <: Locus end


"""
    Sampling <: LookupTrait

Indicates the sampling method used by the index: [`Points`](@ref)
or [`Intervals`](@ref).
"""
abstract type Sampling <: LookupTrait end

struct NoSampling <: Sampling end
struct AutoSampling <: Sampling end

locus(sampling::AutoSampling) = AutoLocus()

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

    Intervals(locus::Locus)

[`Sampling`](@ref) specifying that sampled values are the mean (or similar)
value over an _interval_, rather than at one specific point.

Intervals require a [`Locus`](@ref) of `Start`, `Center` or `End`
to define the location in the interval that the index values refer to.
"""
struct Intervals{L} <: Sampling
    locus::L
end
Intervals() = Intervals(AutoLocus())

locus(sampling::Intervals) = sampling.locus

"""
    rebuild(::Intervals, locus::Locus) => Intervals

Rebuild `Intervals` with a new Locus.
"""
rebuild(::Intervals, locus) = Intervals(locus)

"""
    Span <: LookupTrait

Defines the type of span used in a [`Sampling`](@ref) index.
These are [`Regular`](@ref) or [`Irregular`](@ref).
"""
abstract type Span <: LookupTrait end

struct NoSpan <: Span end

"""
    AutoSpan <: Span

    AutoSpan()

Span will be guessed and replaced by a constructor using `format`, or by `set`.
"""
struct AutoSpan <: Span end

struct AutoStep end
struct AutoBounds end

"""
    Regular <: Span

    Regular(step=AutoStep())

Points or Intervals that have a fixed, regular step.
"""
struct Regular{S} <: Span
    step::S
end
Regular() = Regular(AutoStep())

val(span::Regular) = span.step

Base.step(span::Regular) = span.step

"""
    Irregular <: Span

    Irregular(bounds::Tuple)
    Irregular(lowerbound, upperbound)

Points or Intervals that have an `Irrigular` step size. To enable bounds tracking and
accuract selectors, the starting bounds are provided as a 2 tuple, or 2 arguments.
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

"""
    AutoIndex

Detect a `Lookup` index from the context. This is used in `NoLookup` to simply
use the array axis as the index when the array is constructed, and in `set` to
change the `Lookup` type without changing the index values.
"""
struct AutoIndex <: AbstractVector{Int} end

Base.size(::AutoIndex) = (0,)

