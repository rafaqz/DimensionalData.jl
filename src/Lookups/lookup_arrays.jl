
"""
    Lookup

Types defining the behaviour of a lookup index, how it is plotted
and how [`Selector`](@ref)s like [`Between`](@ref) work.

A `Lookup` may be [`NoLookup`](@ref) indicating that the index is just the
underlying array axis, [`Categorical`](@ref) for ordered or unordered categories,
or a [`Sampled`](@ref) index for [`Points`](@ref) or [`Intervals`](@ref).
"""
abstract type Lookup{T,N} <: AbstractArray{T,N} end

const LookupArray = Lookup
const LookupTuple = Tuple{Lookup,Vararg{Lookup}}

span(lookup::Lookup) = NoSpan()
sampling(lookup::Lookup) = NoSampling()

dims(::Lookup) = nothing
val(l::Lookup) = parent(l)
index(l::Lookup) = parent(l)
locus(l::Lookup) = Center()

Base.eltype(l::Lookup{T}) where T = T
Base.parent(l::Lookup) = l.data
Base.size(l::Lookup) = size(parent(l))
Base.axes(l::Lookup) = axes(parent(l))
Base.first(l::Lookup) = first(parent(l))
Base.last(l::Lookup) = last(parent(l))
Base.firstindex(l::Lookup) = firstindex(parent(l))
Base.lastindex(l::Lookup) = lastindex(parent(l))
function Base.:(==)(l1::Lookup, l2::Lookup)
    basetypeof(l1) == basetypeof(l2) && parent(l1) == parent(l2)
end

ordered_first(l::Lookup) = l[ordered_firstindex(l)]
ordered_last(l::Lookup) = l[ordered_lastindex(l)]

ordered_firstindex(l::Lookup) = ordered_firstindex(order(l), l)
ordered_lastindex(l::Lookup) = ordered_lastindex(order(l), l)
ordered_firstindex(o::ForwardOrdered, l::Lookup) = firstindex(parent(l))
ordered_firstindex(o::ReverseOrdered, l::Lookup) = lastindex(parent(l))
ordered_firstindex(o::Unordered, l::Lookup) = firstindex(parent(l))
ordered_lastindex(o::ForwardOrdered, l::Lookup) = lastindex(parent(l))
ordered_lastindex(o::ReverseOrdered, l::Lookup) = firstindex(parent(l))
ordered_lastindex(o::Unordered, l::Lookup) = lastindex(parent(l))

function Base.searchsortedfirst(lookup::Lookup, val; lt=<, kw...)
    searchsortedfirst(parent(lookup), unwrap(val); order=ordering(order(lookup)), lt=lt, kw...)
end
function Base.searchsortedlast(lookup::Lookup, val; lt=<, kw...)
    searchsortedlast(parent(lookup), unwrap(val); order=ordering(order(lookup)), lt=lt, kw...)
end

function Adapt.adapt_structure(to, l::Lookup)
    rebuild(l; data=Adapt.adapt(to, parent(l)))
end

"""
    AutoLookup <: Lookup

    AutoLookup()
    AutoLookup(index=AutoIndex(); kw...)

Automatic [`Lookup`](@ref), the default lookup. It will be converted automatically
to another [`Lookup`](@ref) when it is possible to detect it from the index.

Keywords will be used in the detected `Lookup` constructor.
"""
struct AutoLookup{T,A<:AbstractVector{T},K} <: Lookup{T,1}
    data::A
    kw::K
end
AutoLookup(index=AutoIndex(); kw...) = AutoLookup(index, kw)

order(lookup::AutoLookup) = hasproperty(lookup.kw, :order) ? lookup.kw.order : AutoOrder()
span(lookup::AutoLookup) = hasproperty(lookup.kw, :span) ? lookup.kw.span : AutoSpan()
sampling(lookup::AutoLookup) = hasproperty(lookup.kw, :sampling) ? lookup.kw.sampling : AutoSampling()
metadata(lookup::AutoLookup) = hasproperty(lookup.kw, :metadata) ? lookup.kw.metadata : NoMetadata()

Base.step(lookup::AutoLookup) = Base.step(parent(lookup))

bounds(lookup::Lookup) = _bounds(order(lookup), lookup)

_bounds(::ForwardOrdered, l::Lookup) = first(l), last(l)
_bounds(::ReverseOrdered, l::Lookup) = last(l), first(l)
_bounds(::Unordered, l::Lookup) = (nothing, nothing)

@noinline Base.step(lookup::T) where T <: Lookup =
    error("No step provided by $T. Use a `Sampled` with `Regular`")

"""
    Aligned <: Lookup

Abstract supertype for [`Lookup`](@ref)s
where the index is aligned with the array axes.

This is by far the most common supertype for `Lookup`.
"""
abstract type Aligned{T,O} <: Lookup{T,1} end

order(lookup::Aligned) = lookup.order

"""
    NoLookup <: Lookup

    NoLookup()

A [`Lookup`](@ref) that is identical to the array axis.
[`Selector`](@ref)s can't be used on this lookup.

## Example

Defining a `DimArray` without passing an index
to the dimensions, it will be assigned `NoLookup`:

```jldoctest NoLookup
using DimensionalData

A = DimArray(rand(3, 3), (X, Y))
Dimensions.lookup(A)

# output

NoLookup, NoLookup
```

Which is identical to:

```jldoctest NoLookup
using .Lookups
A = DimArray(rand(3, 3), (X(NoLookup()), Y(NoLookup())))
Dimensions.lookup(A)

# output

NoLookup, NoLookup
```
"""
struct NoLookup{A<:AbstractVector{Int}} <: Aligned{Int,Order}
    data::A
end
NoLookup() = NoLookup(AutoIndex())

order(lookup::NoLookup) = ForwardOrdered()
span(lookup::NoLookup) = Regular(1)

rebuild(l::NoLookup; data=parent(l), kw...) = NoLookup(data)

Base.step(lookup::NoLookup) = 1

"""
    AbstractSampled <: Aligned

Abstract supertype for [`Lookup`](@ref)s where the index is
aligned with the array, and is independent of other dimensions. [`Sampled`](@ref)
is provided by this package.

`AbstractSampled` must have  `order`, `span` and `sampling` fields,
or a `rebuild` method that accpts them as keyword arguments.
"""
abstract type AbstractSampled{T,O<:Order,Sp<:Span,Sa<:Sampling} <: Aligned{T,O} end

span(lookup::AbstractSampled) = lookup.span
sampling(lookup::AbstractSampled) = lookup.sampling
metadata(lookup::AbstractSampled) = lookup.metadata
locus(lookup::AbstractSampled) = locus(sampling(lookup))

Base.step(lookup::AbstractSampled) = step(span(lookup))

function Base.:(==)(l1::AbstractSampled, l2::AbstractSampled)
    order(l1) == order(l2) &&
    span(l1) == span(l2) &&
    sampling(l1) == sampling(l2) &&
    parent(l1) == parent(l2)
end

for f in (:getindex, :view, :dotview)
    @eval begin
        # span may need its step size or bounds updated
        @propagate_inbounds function Base.$f(l::AbstractSampled, i::AbstractArray)
            i1 = Base.to_indices(l, (i,))[1]
            rebuild(l; data=Base.$f(parent(l), i1), span=slicespan(l, i1))
        end
    end
end

function Adapt.adapt_structure(to, l::AbstractSampled)
    rebuild(l; data=Adapt.adapt(to, parent(l)), metadata=NoMetadata(), span=Adapt.adapt(to, span(l)))
end

# bounds
bounds(l::AbstractSampled) = _bounds(order(l), sampling(l), l)

_bounds(order::Order, ::Points, l::AbstractSampled) = _bounds(order, l)
_bounds(::Unordered, ::Intervals, l::AbstractSampled) = (nothing, nothing)
_bounds(::Ordered, sampling::Intervals, l::AbstractSampled) =
    _bounds(sampling, span(l), l)

_bounds(::Intervals, span::Irregular, lookup::AbstractSampled) = bounds(span)
_bounds(sampling::Intervals, span::Explicit, lookup::AbstractSampled) =
    _bounds(order(lookup), sampling, span, lookup)
_bounds(::ForwardOrdered, ::Intervals, span::Explicit, ::AbstractSampled) =
    (val(span)[1, 1], val(span)[2, end])
_bounds(::ReverseOrdered, ::Intervals, span::Explicit, ::AbstractSampled) =
    (val(span)[1, end], val(span)[2, 1])
_bounds(::Intervals, span::Regular, lookup::AbstractSampled) =
    _bounds(locus(lookup), order(lookup), span, lookup)
_bounds(::Start, ::ForwardOrdered, span, lookup) = first(lookup), last(lookup) + step(span)
_bounds(::Start, ::ReverseOrdered, span, lookup) = last(lookup), first(lookup) - step(span)
_bounds(::Center, ::ForwardOrdered, span, lookup) =
    first(lookup) - step(span) / 2, last(lookup) + step(span) / 2
_bounds(::Center, ::ReverseOrdered, span, lookup) =
    last(lookup) + step(span) / 2, first(lookup) - step(span) / 2
_bounds(::End, ::ForwardOrdered, span, lookup) = first(lookup) - step(span), last(lookup)
_bounds(::End, ::ReverseOrdered, span, lookup) = last(lookup) + step(span), first(lookup)


const SAMPLED_ARGUMENTS_DOC = """
- `data`: An `AbstractVector` of index values, matching the length of the curresponding
    array axis.
- `order`: [`Order`](@ref)) indicating the order of the index,
    [`AutoOrder`](@ref) by default, detected from the order of `data`
    to be [`ForwardOrdered`](@ref), [`ReverseOrdered`](@ref) or [`Unordered`](@ref).
    These can be provided explicitly if they are known and performance is important.
- `span`: indicates the size of intervals or distance between points, and will be set to
    [`Regular`](@ref) for `AbstractRange` and [`Irregular`](@ref) for `AbstractArray`,
    unless assigned manually.
- `sampling`: is assigned to [`Points`](@ref), unless set to [`Intervals`](@ref) manually.
    Using [`Intervals`](@ref) will change the behaviour of `bounds` and `Selectors`s
    to take account for the full size of the interval, rather than the point alone.
- `metadata`: a `Dict` or `Metadata` wrapper that holds any metadata object adding more
    information about the array axis - useful for extending DimensionalData for specific
    contexts, like geospatial data in GeoData.jl. By default it is `NoMetadata()`.
"""

"""
    Sampled <: AbstractSampled

    Sampled(data::AbstractVector, order::Order, span::Span, sampling::Sampling, metadata)
    Sampled(data=AutoIndex(); order=AutoOrder(), span=AutoSpan(), sampling=Points(), metadata=NoMetadata())

A concrete implementation of the [`Lookup`](@ref)
[`AbstractSampled`](@ref). It can be used to represent
[`Points`](@ref) or [`Intervals`](@ref).

`Sampled` is capable of representing gridded data from a wide range of sources, allowing
correct `bounds` and [`Selector`](@ref)s for points or intervals of regular,
irregular, forward and reverse indexes.

On `AbstractDimArray` construction, `Sampled` lookup is assigned for all lookups of
`AbstractRange` not assigned to [`Categorical`](@ref).

## Arguments

$SAMPLED_ARGUMENTS_DOC

## Example

Create an array with [`Interval`] sampling, and `Regular` span for a vector with known spacing.

We set the [`Locus`](@ref) of the `Intervals` to `Start` specifying
that the index values are for the positions at the start of each interval.

```jldoctest Sampled
using DimensionalData, DimensionalData.Lookups

x = X(Sampled(100:-20:10; sampling=Intervals(Start())))
y = Y(Sampled([1, 4, 7, 10]; span=Regular(3), sampling=Intervals(Start())))
A = ones(x, y)

# output
╭─────────────────────────╮
│ 5×4 DimArray{Float64,2} │
├─────────────────────────┴────────────────────────────────────────── dims ┐
  ↓ X Sampled{Int64} 100:-20:20 ReverseOrdered Regular Intervals{Start},
  → Y Sampled{Int64} [1, 4, 7, 10] ForwardOrdered Regular Intervals{Start}
└──────────────────────────────────────────────────────────────────────────┘
   ↓ →  1    4    7    10
 100    1.0  1.0  1.0   1.0
  80    1.0  1.0  1.0   1.0
  60    1.0  1.0  1.0   1.0
  40    1.0  1.0  1.0   1.0
  20    1.0  1.0  1.0   1.0
```
"""
struct Sampled{T,A<:AbstractVector{T},O,Sp,Sa,M} <: AbstractSampled{T,O,Sp,Sa}
    data::A
    order::O
    span::Sp
    sampling::Sa
    metadata::M
end
function Sampled(data=AutoIndex();
    order=AutoOrder(), span=AutoSpan(),
    sampling=AutoSampling(), metadata=NoMetadata()
)
    Sampled(data, order, span, sampling, metadata)
end

function rebuild(l::Sampled;
    data=parent(l), order=order(l), span=span(l), sampling=sampling(l), metadata=metadata(l), kw...
)
    Sampled(data, order, span, sampling, metadata)
end

# These are used to specialise dispatch:
# When Cycling, we need to modify any `Selector`. after that
# we swicth to `NotCycling` and use `AbstractSampled` fallbacks.
# We could switch to `Sampled` ata that point, but its less extensible.
abstract type CycleStatus end

struct Cycling <: CycleStatus end
struct NotCycling <: CycleStatus end

"""
    AbstractCyclic <: AbstractSampled end

An abstract supertype for cyclic lookups.

These are `AbstractSampled` lookups that are cyclic for `Selectors`.
"""
abstract type AbstractCyclic{X,T,O,Sp,Sa} <: AbstractSampled{T,O,Sp,Sa} end

cycle(l::AbstractCyclic) = l.cycle
cycle_status(l::AbstractCyclic) = l.cycle_status

bounds(l::AbstractCyclic{<:Any,T}) where T = (typemin(T), typemax(T))

# Indexing with `AbstractArray` must rebuild the lookup as
# `Sampled` as we no longer have the whole cycle.
for f in (:getindex, :view, :dotview)
    @eval @propagate_inbounds Base.$f(l::AbstractCyclic, i::AbstractArray) =
        Sampled(rebuild(l; data=Base.$f(parent(l), i)))
end


no_cycling(l::AbstractCyclic) = rebuild(l; cycle_status=NotCycling())

function cycle_val(l::AbstractCyclic, val)
    cycle_start = ordered_first(l)
    # This formulation is necessary for dates
    ncycles = (val - cycle_start) ÷ (cycle_start + cycle(l) - cycle_start)
    res = val - ncycles * cycle(l)
    # Catch precision errors
    if (cycle_start + (ncycles + 1) * cycle(l)) <= val
        i = 1
        while i < 10000
            if (cycle_start + (ncycles + i) * cycle(l)) > val
                return val - (ncycles + i - 1) * cycle(l)
            end
            i += 1
        end
    elseif res < cycle_start
        i = 1
        while i < 10000
            res = val - (ncycles - i + 1) * cycle(l)
            res >= cycle_start && return res
            i += 1
        end
    else
        return res
    end
    error("`Cyclic` lookup too innacurate, value not found")
end



"""
    Cyclic <: AbstractCyclic

    Cyclic(data; order=AutoOrder(), span=AutoSpan(), sampling=Points(), metadata=NoMetadata(), cycle)

A `Cyclic` lookup is similar to `Sampled` but out of range `Selectors` [`At`](@ref), 
[`Near`](@ref), [`Contains`](@ref) will cycle the values to `typemin` or `typemax` 
over the length of `cycle`. [`Where`](@ref) and `..` work as for [`Sampled`](@ref).

This is useful when we are using mean annual datasets over a real time-span,
or for wrapping longitudes so that `-360` and `360` are the same.

## Arguments

$SAMPLED_ARGUMENTS_DOC
- `cycle`: the length of the cycle. This does not have to exactly match the data, 
   the `step` size is `Week(1)` the cycle can be `Years(1)`.

## Notes

1. If you use dates and e.g. cycle over a `Year`, every year will have the 
    number and spacing of `Week`s and `Day`s as the cycle year. Using `At` may not be reliable
    in terms of exact dates, as it will be applied to the specified date plus or minus `n` years.
2. Indexing into a `Cycled` with any `AbstractArray` or `AbstractRange` will return 
    a [`Sampled`](@ref) as the full cycle is likely no longer available.
3. `..` or `Between` selectors do not work in a cycled way: they work as for [`Sampled`](@ref). 
    This may change in future to return cycled values, but there are problems with this, such as
    leap years breaking correct date cycling of a single year. If you actually need this behaviour, 
    please make a GitHub issue.
"""
struct Cyclic{X,T,A<:AbstractVector{T},O,Sp,Sa,M,C} <: AbstractCyclic{X,T,O,Sp,Sa}
    data::A
    order::O
    span::Sp
    sampling::Sa
    metadata::M
    cycle::C
    cycle_status::X
    function Cyclic(
        data::A, order::O, span::Sp, sampling::Sa, metadata::M, cycle::C, cycle_status::X
    ) where {A<:AbstractVector{T},O,Sp,Sa,M,C,X} where T
        _check_ordered_cyclic(order)
        new{X,T,A,O,Sp,Sa,M,C}(data, order, span, sampling, metadata, cycle, cycle_status)
    end
end
function Cyclic(data=AutoIndex();
    order=AutoOrder(), span=AutoSpan(),
    sampling=AutoSampling(), metadata=NoMetadata(),
    cycle, # Mandatory keyword, there are too many possible bugs with auto detection
)
    cycle_status = Cycling()
    Cyclic(data, order, span, sampling, metadata, cycle, cycle_status)
end

_check_ordered_cyclic(::AutoOrder) = nothing
_check_ordered_cyclic(::Ordered) = nothing
_check_ordered_cyclic(::Unordered) = throw(ArgumentError("Cyclic lookups must be `Ordered`"))

function rebuild(l::Cyclic;
    data=parent(l), order=order(l), span=span(l), sampling=sampling(l), metadata=metadata(l),
    cycle=cycle(l), cycle_status=cycle_status(l), kw...
)
    Cyclic(data, order, span, sampling, metadata, cycle, cycle_status)
end

"""
    AbstractCategorical <: Aligned

[`Lookup`](@ref)s where the values are categories.

[`Categorical`](@ref) is the provided concrete implementation.
but this can easily be extended - all methods are defined for `AbstractCategorical`.

All `AbstractCategorical` must provide a `rebuild`
method with `data`, `order` and `metadata` keyword arguments.
"""
abstract type AbstractCategorical{T,O} <: Aligned{T,O} end

order(lookup::AbstractCategorical) = lookup.order
metadata(lookup::AbstractCategorical) = lookup.metadata

const CategoricalEltypes = Union{AbstractChar,Symbol,AbstractString}

function Adapt.adapt_structure(to, l::AbstractCategorical)
    rebuild(l; data=Adapt.adapt(to, parent(l)), metadata=NoMetadata())
end


"""
    Categorical <: AbstractCategorical

    Categorical(o::Order)
    Categorical(; order=Unordered())

An Lookup where the values are categories.

This will be automatically assigned if the index contains `AbstractString`,
`Symbol` or `Char`. Otherwise it can be assigned manually.

[`Order`](@ref) will be determined automatically where possible.

## Arguments

- `data`: An `AbstractVector` of index values, matching the length of the curresponding
    array axis.
- `order`: [`Order`](@ref)) indicating the order of the index,
    [`AutoOrder`](@ref) by default, detected from the order of `data`
    to be `ForwardOrdered`, `ReverseOrdered` or `Unordered`.
    Can be provided if this is known and performance is important.
- `metadata`: a `Dict` or `Metadata` wrapper that holds any metadata object adding more
    information about the array axis - useful for extending DimensionalData for specific
    contexts, like geospatial data in GeoData.jl. By default it is `NoMetadata()`.

## Example

Create an array with [`Interval`] sampling.

```jldoctest Categorical
using DimensionalData

ds = X(["one", "two", "three"]), Y([:a, :b, :c, :d])
A = DimArray(rand(3, 4), ds)
Dimensions.lookup(A)

# output

Categorical{String} ["one", "two", "three"] Unordered,
Categorical{Symbol} [:a, :b, :c, :d] ForwardOrdered
```
"""
struct Categorical{T,A<:AbstractVector{T},O<:Order,M} <: AbstractCategorical{T,O}
    data::A
    order::O
    metadata::M
end
function Categorical(data=AutoIndex(); order=AutoOrder(), metadata=NoMetadata())
    Categorical(data, order, metadata)
end

function rebuild(l::Categorical;
    data=parent(l), order=order(l), metadata=metadata(l), kw...
)
    Categorical(data, order, metadata)
end

function Base.:(==)(l1::AbstractCategorical, l2::AbstractCategorical)
    order(l1) == order(l2) && parent(l1) == parent(l2)
end


"""
    Unaligned <: Lookup

Abstract supertype for [`Lookup`](@ref) where the index is not aligned to the grid.

Indexing an [`Unaligned`](@ref) with [`Selector`](@ref)s must provide all
other [`Unaligned`](@ref) dimensions.
"""
abstract type Unaligned{T,N} <: Lookup{T,N} end

"""
    Transformed <: Unaligned

    Transformed(f, dim::Dimension; metadata=NoMetadata())

[`Lookup`](@ref) that uses an affine transformation to convert
dimensions from `dims(lookup)` to `dims(array)`. This can be useful
when the dimensions are e.g. rotated from a more commonly used axis.

Any function can be used to do the transformation, but transformations
from CoordinateTransformations.jl may be useful.

## Arguments

- `f`: transformation function
- `dim`: a dimension to transform to.

## Keyword Arguments

- `metdata`:

## Example

```jldoctest
using DimensionalData, DimensionalData.Lookups, CoordinateTransformations

m = LinearMap([0.5 0.0; 0.0 0.5])
A = [1 2  3  4
     5 6  7  8
     9 10 11 12];
da = DimArray(A, (X(Transformed(m)), Y(Transformed(m))))

da[X(At(6.0)), Y(At(2.0))]

# output
9
```
"""
struct Transformed{T,A<:AbstractVector{T},F,D,M} <: Unaligned{T,1}
    data::A
    f::F
    dim::D
    metadata::M
end
function Transformed(f; metadata=NoMetadata())
    Transformed(AutoIndex(), f, AutoDim(), metadata)
end
function Transformed(f, data::AbstractArray; metadata=NoMetadata())
    Transformed(data, f, AutoDim(), metadata)
end

function rebuild(l::Transformed;
    data=parent(l), f=transformfunc(l), dim=dim(l), metadata=metadata(l)
)
    Transformed(data, f, dim, metadata)
end

dim(lookup::Transformed) = lookup.dim

transformfunc(lookup::Transformed) = lookup.f

Base.:(==)(l1::Transformed, l2::Transformed) = typeof(l1) == typeof(l2) && f(l1) == f(l2)

# TODO Transformed bounds

# Shared methods

intervalbounds(l::Lookup, args...) = _intervalbounds_no_interval_error()
intervalbounds(l::AbstractSampled, args...) = intervalbounds(span(l), sampling(l), l, args...)
intervalbounds(span::Span, ::Points, ls::Lookup) = map(l -> (l, l), ls) 
intervalbounds(span::Span, ::Points, ls::Lookup, i::Int) = ls[i], ls[i]
intervalbounds(span::Span, sampling::Intervals, l::Lookup, i::Int) =
    intervalbounds(order(l), locus(sampling), span, l, i)
function intervalbounds(order::ForwardOrdered, locus::Start, span::Span, l::Lookup, i::Int)
    if i == lastindex(l)
        (l[i], bounds(l)[2])
    else
        (l[i], l[i+1])
    end
end
function intervalbounds(order::ForwardOrdered, locus::End, span::Span, l::Lookup, i::Int)
    if i == firstindex(l)
        (bounds(l)[1], l[i])
    else
        (l[i-1], l[i])
    end
end
function intervalbounds(order::ReverseOrdered, locus::Start, span::Span, l::Lookup, i::Int)
    if i == firstindex(l)
        (l[i], bounds(l)[2])
    else
        (l[i], l[i-1])
    end
end
function intervalbounds(order::ReverseOrdered, locus::End, span::Span, l::Lookup, i::Int)
    if i == lastindex(l)
        (bounds(l)[1], l[i])
    else
        (l[i+1], l[i])
    end
end
# Regular Center
function intervalbounds(order::Ordered, locus::Center, span::Regular, l::Lookup, i::Int)
    halfstep = step(span) / 2
    x = l[i]
    bounds = (x - halfstep, x + halfstep)
    return _maybeflipbounds(order, bounds)
end
# Irregular Center
function intervalbounds(order::ForwardOrdered, locus::Center, span::Irregular, l::Lookup, i::Int)
    x = l[i]
    low  = i == firstindex(l) ? bounds(l)[1] : x + (l[i - 1] - x) / 2
    high = i == lastindex(l)  ? bounds(l)[2] : x + (l[i + 1] - x) / 2
    return (low, high)
end
function intervalbounds(order::ReverseOrdered, locus::Center, span::Irregular, l::Lookup, i::Int)
    x = l[i]
    low  = i == firstindex(l) ? bounds(l)[2] : x + (l[i - 1] - x) / 2
    high = i == lastindex(l)  ? bounds(l)[1] : x + (l[i + 1] - x) / 2
    return (low, high)
end
function intervalbounds(span::Span, sampling::Intervals, l::Lookup)
    map(axes(l, 1)) do i
        intervalbounds(span, sampling, l, i)
    end
end
# Explicit
function intervalbounds(span::Explicit, ::Intervals, l::Lookup, i::Int)
    return (l[1, i], l[2, i])
end
# We just reinterpret the bounds matrix rather than allocating
function intervalbounds(span::Explicit, ::Intervals, l::Lookup)
    m = val(span)
    T = eltype(m)
    return reinterpret(reshape, Tuple{T,T}, m)
end

_intervalbounds_no_interval_error() = error("Lookup does not have Intervals, `intervalbounds` cannot be applied")

# Slicespan should only be called after `to_indices` has simplified indices
slicespan(l::Lookup, i::Colon) = span(l)
slicespan(l::Lookup, i) = _slicespan(span(l), l, i)

_slicespan(span::Regular, l::Lookup, i::Union{AbstractRange,CartesianIndices}) = Regular(step(l) * step(i))
_slicespan(span::Regular, l::Lookup, i::AbstractArray) = _slicespan(Irregular(bounds(l)), l, i)
_slicespan(span::Explicit, l::Lookup, i::AbstractArray) = Explicit(val(span)[:, i])
_slicespan(span::Irregular, l::Lookup, i::AbstractArray) =
    _slicespan(sampling(l), span, l, i)
function _slicespan(span::Irregular, l::Lookup, i::Base.LogicalIndex)
    i1 = length(i) == 0 ? (1:0) : ((findfirst(i.mask)::Int):(findlast(i.mask)::Int))
    _slicespan(sampling(l), span, l, i1)
end
function _slicespan(span::Irregular, l::Lookup, i::InvertedIndices.InvertedIndexIterator)
    i1 = collect(i) # We could do something more efficient here, but I'm not sure what
    _slicespan(sampling(l), span, l, i1)
end
function _slicespan(::Points, span::Irregular, l::Lookup, i::AbstractArray)
    length(i) == 0 && return Irregular(nothing, nothing)
    fi, la = first(i), last(i)
    return Irregular(_maybeflipbounds(l, (l[fi], l[la])))
end
_slicespan(::Intervals, span::Irregular, l::Lookup, i::AbstractArray) =
    Irregular(_slicebounds(span, l, i))

function _slicebounds(span::Irregular, l::Lookup, i::AbstractArray)
    length(i) == 0 && return (nothing, nothing)
    _slicebounds(locus(l), span, l, i)
end
function _slicebounds(locus::Start, span::Irregular, l::Lookup, i::AbstractArray)
    fi, la = first(i), last(i)
    if isforward(l)
        l[fi], la >= lastindex(l) ? bounds(l)[2] : l[la + 1]
    else
        l[la], fi <= firstindex(l) ? bounds(l)[2] : l[fi - 1]
    end
end
function _slicebounds(locus::End, span::Irregular, l::Lookup, i::AbstractArray)
    fi, la = first(i), last(i)
    if isforward(l)
        fi <= firstindex(l) ? bounds(l)[1] : l[fi - 1], l[la]
    else
        la >= lastindex(l) ? bounds(l)[1] : l[la + 1], l[fi]
    end
end
function _slicebounds(locus::Center, span::Irregular, l::Lookup, i::AbstractArray)
    fi, la = first(i), last(i)
    a, b = if isforward(l)
        fi <= firstindex(l) ? bounds(l)[1] : (l[fi - 1] + l[fi]) / 2,
        la >= lastindex(l)  ? bounds(l)[2] : (l[la + 1] + l[la]) / 2
    else
        la >= lastindex(l)  ? bounds(l)[1] : (l[la + 1] + l[la]) / 2,
        fi <= firstindex(l) ? bounds(l)[2] : (l[fi - 1] + l[fi]) / 2
    end
    return a, b
end
# Have to special-case date/time so we work with seconds and add to the original
function _slicebounds(locus::Center, span::Irregular, l::Lookup{T}, i::AbstractArray) where T<:Dates.AbstractTime
    op = T === Date ? div : /
    frst = if first(i) <= firstindex(l)
        _maybeflipbounds(l, bounds(l))[1]
    else
        if isrev(order(l))
            op(l[first(i)] - l[first(i) - 1], 2) + l[first(i) - 1]
        else
            op(l[first(i) - 1] - l[first(i)], 2) + l[first(i)]
        end
    end
    lst = if last(i) >= lastindex(l)
        _maybeflipbounds(l, bounds(l))[2]
    else
        if isrev(order(l))
            op(l[last(i)] - l[last(i) + 1], 2) + l[last(i) + 1]
        else
            op(l[last(i) + 1] - l[last(i)], 2) + l[last(i)]
        end
    end
    return (frst, lst)
end

# reducing methods
@inline reducelookup(lookup::NoLookup) = NoLookup(OneTo(1))
# TODO what should this do?
@inline reducelookup(lookup::Unaligned) = NoLookup(OneTo(1))
# Categories are combined.
@inline reducelookup(lookup::Categorical{<:AbstractString}) =
    rebuild(lookup; data=["combined"])
@inline reducelookup(lookup::Categorical) = rebuild(lookup; data=[:combined])
# Sampled is resampled
@inline reducelookup(lookup::AbstractSampled) = _reducelookup(span(lookup), lookup)

@inline _reducelookup(::Irregular, lookup::AbstractSampled) = begin
    rebuild(lookup; data=_reduceindex(lookup), order=ForwardOrdered())
end
@inline _reducelookup(span::Regular, lookup::AbstractSampled) = begin
    newstep = step(span) * length(lookup)
    newindex = _reduceindex(lookup, newstep)
    # Make sure the step type matches the new index eltype
    newstep = convert(promote_type(eltype(newindex), typeof(newstep)), newstep)
    newspan = Regular(newstep)
    rebuild(lookup; data=newindex, order=ForwardOrdered(), span=newspan)
end
@inline _reducelookup(
    span::Regular{<:Dates.CompoundPeriod}, lookup::AbstractSampled
) = begin
    newstep = Dates.CompoundPeriod(step(span).periods .* length(lookup))
    # We don't pass the step here - the range doesn't work with CompoundPeriod
    newindex = _reduceindex(lookup)
    # Make sure the step type matches the new index eltype
    newspan = Regular(newstep)
    rebuild(lookup; data=newindex, order=ForwardOrdered(), span=newspan)
end
@inline _reducelookup(span::Explicit, lookup::AbstractSampled) = begin
    bnds = val(span)
    newstep = bnds[2] - bnds[1]
    newindex = _reduceindex(lookup, newstep)
    # Make sure the step type matches the new index eltype
    newstep = convert(promote_type(eltype(newindex), typeof(newstep)), newstep)
    newspan = Explicit(reshape([bnds[1, 1]; bnds[2, end]], 2, 1))
    newlookup = rebuild(lookup; data=newindex, order=ForwardOrdered(), span=newspan)
end
# Get the index value at the reduced locus.
# This is the start, center or end point of the whole index.
@inline _reduceindex(lookup::Lookup, step=nothing) = _reduceindex(locus(lookup), lookup, step)
@inline _reduceindex(locus::Start, lookup::Lookup, step) = _mayberange(first(lookup), step)
@inline _reduceindex(locus::End, lookup::Lookup, step) = _mayberange(last(lookup), step)
@inline _reduceindex(locus::Center, lookup::Lookup, step) = begin
    index = parent(lookup)
    len = length(index)
    newval = centerval(index, len)
    _mayberange(newval, step)
end
# Ranges with a known step always return a range
_mayberange(x, step) = x:step:x
# Arrays return a vector
_mayberange(x, step::Nothing) = [x]

@inline centerval(index::AbstractArray{<:Number}, len) = (first(index) + last(index)) / 2
@inline function centerval(index::AbstractArray{<:DateTime}, len)
    f = first(index)
    l = last(index)
    if f <= l
        return (l - f) / 2 + first(index)
    else
        return (f - l) / 2 + last(index)
    end
end
@inline centerval(index::AbstractArray, len) = index[len ÷ 2 + 1]

ordering(::ForwardOrdered) = Base.Order.ForwardOrdering()
ordering(::ReverseOrdered) = Base.Order.ReverseOrdering()
