
"""
    Lookup

Types defining the behaviour of a lookup index, how it is plotted
and how [`Selector`](@ref)s like [`Between`](@ref) work.

A `Lookup` may be a simple type like [`NoLookup`](@ref) indicating that the index is
just the underlying array axis. It could also be a [`Categorical`](@ref) index indicating
the index is ordered or unordered categories, or a [`Sampled`](@ref) index indicating
sampling.
"""
abstract type Lookup{T,N} <: AbstractArray{T,N} end

const LookupTuple = Tuple{<:Lookup,Vararg{<:Lookup}}

span(lookup::Lookup) = NoSpan() 
sampling(lookup::Lookup) = NoSampling()

dims(::Lookup) = nothing
index(lookup::Lookup) = parent(lookup)
locus(lookup::Lookup) = Center()

Base.parent(l::Lookup) = l.data
Base.size(l::Lookup) = size(parent(l))
Base.axes(l::Lookup) = axes(parent(l))
Base.first(l::Lookup) = first(parent(l))
Base.last(l::Lookup) = last(parent(l))
Base.firstindex(l::Lookup) = firstindex(parent(l))
Base.lastindex(l::Lookup) = lastindex(parent(l))

function Base.searchsortedfirst(lookup::Lookup, val; lt=<)
    searchsortedfirst(parent(lookup), unwrap(val); order=_ordering(order(lookup)), lt=lt)
end
function Base.searchsortedlast(lookup::Lookup, val; lt=<)
    searchsortedlast(parent(lookup), unwrap(val); order=_ordering(order(lookup)), lt=lt)
end

function Base.:(==)(l1::Lookup, l2::Lookup)
    typeof(l1) == typeof(l2) && parent(l1) == parent(l2)
end

function Adapt.adapt_structure(to, l::Lookup)
    rebuild(l; data=Adapt.adapt(to, parent(l)), metadata=NoMetadata())
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

const Auto = AutoLookup

bounds(lookup::Lookup) = _bounds(order(lookup), lookup)

_bounds(::ForwardOrdered, l::Lookup) = first(l), last(l)
_bounds(::ReverseOrdered, l::Lookup) = last(l), first(l)
_bounds(::Unordered, l::Lookup) = (nothing, nothing)

@noinline Base.step(lookup::T) where T <: Lookup =
    error("No step provided by $T. Use a `Sampled` with `Regular`")

"""
    Aligned <: Lookup

Abstract supertype for [`Lookup`](@ref)s where the index is aligned with the array axes.

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

Defining a [`DimArray`](@ref) without passing an index
to the dimensions, it will be assigned `NoLookup`:

```jldoctest NoLookup
using DimensionalData

A = DimArray(rand(3, 3), (X, Y))
lookup(A)

# output

NoLookup, NoLookup
```

Which is identical to:

```jldoctest NoLookup
A = DimArray(rand(3, 3), (X(NoLookup()), Y(NoLookup())))
lookup(A)

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

Base.step(lookup::NoLookup) = 1

rebuild(l::NoLookup; data=parent(l), kw...) = NoLookup(data)


"""
    AbstractSampled <: Aligned

Abstract supertype for [`Lookup`](@ref)s where the index is aligned with the array,
and is independent of other dimensions. [`Sampled`](@ref) is provided by this package,
`Projected` in GeoData.jl also extends [`AbstractSampled`](@ref), adding crs projections.

`AbstractSampled` must have  `order`, `span` and `sampling` fields,
or a `rebuild` method that accpts them as keyword arguments.
"""
abstract type AbstractSampled{T,O<:Order,Sp<:Span,Sa<:Sampling} <: Aligned{T,O} end

span(lookup::AbstractSampled) = lookup.span
sampling(lookup::AbstractSampled) = lookup.sampling
metadata(lookup::AbstractSampled) = lookup.metadata
locus(lookup::AbstractSampled) = locus(sampling(lookup))

Base.step(lookup::AbstractSampled) = step(span(lookup))

# bounds
bounds(lookup::AbstractSampled) = _bounds(sampling(lookup), span(lookup), lookup)

_bounds(::Points, span, lookup::AbstractSampled) = _bounds(order(lookup), lookup)
_bounds(::Intervals, span::Irregular, lookup::AbstractSampled) = bounds(span)
_bounds(sampling::Intervals, span::Explicit, lookup::AbstractSampled) = 
    _bounds(order(lookup), sampling, span, lookup)
_bounds(::ForwardOrdered, ::Intervals, span::Explicit, lookup::AbstractSampled) = 
    (val(span)[1, 1], val(span)[2, end])
_bounds(::ReverseOrdered, ::Intervals, span::Explicit, lookup::AbstractSampled) = 
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

"""
    Sampled <: AbstractSampled

    Sampled(data::AbstractVector, order::Order, span::Span, sampling::Sampling, metadata)
    Sampled(; data=AutoIndex(), order=AutoOrder(), span=AutoSpan(), sampling=Points(), metadata=NoMetadata())

A concrete implementation of the [`Lookup`](@ref) [`AbstractSampled`](@ref).
It can be used to represent [`Points`](@ref) or [`Intervals`](@ref).

`Sampled` is capable of representing gridded data from a wide range of sources, allowing
correct `bounds` and [`Selector`](@ref)s for points or intervals of regular, irregular,
forward and reverse indexes.

On `AbstractDimArray` construction, `Sampled` lookup is assigned for all lookups of 
`AbstractRange` not assigned to [`Categorical`](@ref).

## Arguments

- `data`: An `AbstractVector` of index values, matching the length of the curresponding
    array axis. 
- `order`: [`Order`](@ref)) indicating the order of the index, [`AutoOrder`](@ref) by
    default, detected from the order of `data` to be `ForwardOrdered`, `ReverseOrdered`
    or `Unordered`. Can be provided if this is known and performance is important.
- `span`: indicates the size of intervals or distance between points, and will be set to
    [`Regular`](@ref) for `AbstractRange` and [`Irregular`](@ref) for `AbstractArray`,
    unless assigned manually.
- `sampling`: is assigned to [`Points`](@ref), unless set to [`Intervals`](@ref) manually. 
    Using [`Intervals`](@ref) will change the behaviour of `bounds` and `Selectors`s
    to take account for the full size of the interval, rather than the point alone.
- `metadata`: a `Dict` or `Metadata` wrapper that holds any metadata object adding more
    information about the array axis - useful for extending DimensionalData for specific
    contexts, like geospatial data in GeoData.jl. By default it is `NoMetadata()`.

## Example

Create an array with [`Interval`] sampling, and `Regular` span for a vector with known spacing.

We set the [`Locus`](@ref) of the `Intervals` to `Start` specifying that the index 
values are for the point at the start of the interval.

```jldoctest Sampled
using DimensionalData

x = X(Sampled(100:-10:10; sampling=Intervals(Start()))),
y = Y(Sampled([1, 4, 7, 10]; span=Regular(3), sampling=Intervals(Start())))
A = rand(x, y)
lookup(A)

# output
ERROR: syntax: "Sampled(100:-10:10,; sampling = Intervals(Start()))" is not a valid function argument name
Stacktrace:
 [1] top-level scope
   @ none:1
```
"""
struct Sampled{T,A<:AbstractVector{T},O,Sp,Sa,M} <: AbstractSampled{T,O,Sp,Sa}
    data::A
    order::O
    span::Sp
    sampling::Sa
    metadata::M
end
function Sampled(
    data=AutoIndex();
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

"""
    Categorical <: AbstractCategorical

    Categorical(o::Order)
    Categorical(; order=Unordered())

An Lookup where the values are categories.

This will be automatically assigned if the index contains `AbstractString`,
`Symbol` or `Char`. Otherwise it can be assigned manually.

[`Order`](@ref) will not be determined automatically for [`Categorical`](@ref),
it instead defaults to [`Unordered`].

## Arguments

- `data`: An `AbstractVector` of index values, matching the length of the curresponding
    array axis. 
- `order`: [`Order`](@ref)) indicating the order of the index, [`AutoOrder`](@ref) by
    default, detected from the order of `data` to be `ForwardOrdered`, `ReverseOrdered`
    or `Unordered`. Can be provided if this is known and performance is important.
- `metadata`: a `Dict` or `Metadata` wrapper that holds any metadata object adding more
    information about the array axis - useful for extending DimensionalData for specific
    contexts, like geospatial data in GeoData.jl. By default it is `NoMetadata()`.

## Example

Create an array with [`Interval`] sampling.

```jldoctest Categorical
using DimensionalData

ds = X(["one", "two", "three"]), Y([:a, :b, :c, :d])
A = DimArray(rand(3, 4), ds)
lookup(A)

# output

Categorical String[one, two, three] Unordered,
Categorical Symbol[a, b, c, d] ForwardOrdered
```
"""
struct Categorical{T,A<:AbstractVector{T},O<:Order,M} <: AbstractCategorical{T,O}
    data::A
    order::O
    metadata::M
end
function Categorical(data=AutoIndex(); order=Unordered(), metadata=NoMetadata())
    Categorical(data, order, metadata)
end

function rebuild(l::Categorical; 
    data=parent(l), order=order(l), metadata=metadata(l), kw...
)
    Categorical(data, order, metadata)
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
- `dims`: a tuple containing dimenension types or symbols matching the
    order needed by the transform function.

## Keyword Arguments

- `metdata`: 

## Example

```jldoctest
using DimensionalData, CoordinateTransformations

m = LinearMap([0.5 0.0; 0.0 0.5])
A = [1 2  3  4
     5 6  7  8
     9 10 11 12];
da = DimArray(A, (t1=Transformed(m, X), t2=Transformed(m, Y)))

da[X(At(6)), Y(At(2))]

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
function Transformed(f, dim; metadata=NoMetadata())
    Transformed(AutoIndex(), f, basedims(key2dim(dim)), metadata)
end

function rebuild(l::Transformed; 
    data=data(l), f=f(l), dim=dim(l), metadata=metadata(l)
)
    Transformed(data, f, dim, metadata)
end

f(lookup::Transformed) = lookup.f
dim(lookup::Transformed) = lookup.dim

transformfunc(lookup::Transformed) = f(lookup)
transformdim(x) = nothing
transformdim(lookup::Transformed) = lookup.dim
transformdim(::Type{<:Transformed{<:Any,<:Any,<:Any,D}}) where D = D

Base.:(==)(l1::Transformed, l2::Transformed) = typeof(l1) == typeof(l2) && f(l1) == f(l2)

# TODO Transformed bounds


# Common methods

# TODO deal with unordered arrays trashing the index order
for f in (:getindex, :view, :dotview)
    @eval begin
        @propagate_inbounds Base.$f(l::Lookup, i::AbstractArray) = 
            rebuild(l; data=Base.$f(parent(l), i))
        @propagate_inbounds Base.$f(l::Lookup, i::Int) = Base.$f(parent(l), i)
        @propagate_inbounds Base.$f(l::AbstractSampled, i::AbstractRange) = 
            rebuild(l; data=Base.$f(parent(l), i), span=slicespan(l, i))
        @propagate_inbounds Base.$f(l::NoLookup, i::Int) = i
    end
end

slicespan(l::Lookup, i::Colon) = span(l)
slicespan(l::Lookup, i) = _slicespan(span(l), l, i)

_slicespan(span::Regular, l::Lookup, i::Int) = span
_slicespan(span::Regular, l::Lookup, i::AbstractRange) = Regular(step(l) * step(i))
_slicespan(span::Regular, l::Lookup, i::AbstractArray) = _slicespan(Irregular(bounds(l)), l, i) 
_slicespan(span::Explicit, l::Lookup, i::Int) = Explicit(val(span)[:, i])
_slicespan(span::Explicit, l::Lookup, i::AbstractArray) = Explicit(val(span)[:, i])

function _slicespan(span::Irregular, l::Lookup, i::StandardIndices)
    Irregular(_maybeflipbounds(l, _slicespan(locus(l), span, l, i)))
end
function _slicespan(locus::Start, span::Irregular, l::Lookup, i::StandardIndices)
    l[first(i)], last(i) >= lastindex(l) ? _maybeflipbounds(l, bounds(span))[2] : l[last(i) + 1]
end
function _slicespan(locus::End, span::Irregular, l::Lookup, i::StandardIndices)
    first(i) <= firstindex(l) ? _maybeflipbounds(l, bounds(span))[1] : l[first(i) - 1], l[last(i)]
end
function _slicespan(locus::Center, span::Irregular, l::Lookup, i::StandardIndices)
    first(i) <= firstindex(l) ? _maybeflipbounds(l, bounds(span))[1] : (l[first(i) - 1] + l[first(i)]) / 2,
    last(i)  >= lastindex(l)  ? _maybeflipbounds(l, bounds(span))[2] : (l[last(i) + 1]  + l[last(i)]) / 2
end
# Have to special-case date/time so we work with seconds and add to the original
function _slicespan(locus::Center, span::Irregular, l::Lookup{<:Dates.AbstractTime}, i::StandardIndices)
    frst = if first(i) <= firstindex(l)
        _maybeflipbounds(l, bounds(span))[1]
    else
        if isrev(order(l))
            (l[first(i)] - l[first(i) - 1]) / 2 + l[first(i) - 1]
        else
            (l[first(i) - 1] - l[first(i)]) / 2 + l[first(i)] 
        end
    end
    lst = if last(i) >= lastindex(l)
        _maybeflipbounds(l, bounds(span))[2]
    else
        if isrev(order(l))
            (l[last(i)] - l[last(i) + 1]) / 2 + l[last(i) + 1]
        else
            (l[last(i) + 1] - l[last(i)]) / 2 + l[last(i)]
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

_ordering(::ForwardOrdered) = Base.Order.ForwardOrdering()
_ordering(::ReverseOrdered) = Base.Order.ReverseOrdering()
