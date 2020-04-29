"""
Traits for the order of the array, index and the relation between them.
"""
abstract type Order end

"""
Container object for dimension and array ordering.

The default is `Ordered(Forward()`, `Forward(), Forward())`

All combinations of forward and reverse order for data and indices seem to occurr
in real datasets, as strange as that seems. We cover these possibilities by specifying
the order of both explicitly.

Knowing the order of indices is important for using methods like `searchsortedfirst()`
to find indices in sorted lists of values. Knowing the order of the data is then
required to map to the actual indices. It's also used to plot the data later - which
always happens in smallest to largest order.

Base also defines Forward and Reverse, but they seem overly complicated for our purposes.
"""
struct Ordered{D,A,R} <: Order
    index::D
    array::A
    relation::R
end
Ordered(; index=Forward(), array=Forward(), relation=Forward()) =
    Ordered(index, array, relation)

indexorder(order::Ordered) = order.index
arrayorder(order::Ordered) = order.array
relationorder(order::Ordered) = order.relation

"""
Trait indicating that the array or dimension has no order.
"""
struct Unordered{R} <: Order
    relation::R
end
Unordered() = Unordered(Forward())

indexorder(order::Unordered) = Unordered()
arrayorder(order::Unordered) = Unordered()
relationorder(order::Unordered) = order.relation

"""
Order will be found automatically where possible.

This will fail for all types without `isless` methods.
"""
struct AutoOrder <: Order end

"""
Order is not known and can't be determined.
"""
struct UnknownOrder <: Order end

"""
Indicates that the array or dimension is in the normal forward order.
"""
struct Forward <: Order end

"""
Indicates that the array or dimension is in the reverse order.
Selector lookup or plotting will be reversed.
"""
struct Reverse <: Order end

Base.reverse(::Reverse) = Forward()
Base.reverse(::Forward) = Reverse()

reverseindex(o::Unordered) =
    Unordered(reverse(relationorder(o)))
reverseindex(o::Ordered) =
    Ordered(reverse(indexorder(o)), arrayorder(o), reverse(relationorder(o)))

reversearray(o::Unordered) =
    Unordered(reverse(relationorder(o)))
reversearray(o::Ordered) =
    Ordered(indexorder(o), reverse(arrayorder(o)), reverse(relationorder(o)))

isrev(::Forward) = false
isrev(::Reverse) = true

"""
Locii indicate the position of index values in cells.

Locii are often `Start` for time series, but often `Center`
for spatial data.
"""
abstract type Locus end

"""
Indicates dimension index that matches the center coordinates/time/position.
"""
struct Center <: Locus end

"""
Indicates dimension index that matches the start coordinates/time/position.
"""
struct Start <: Locus end

"""
Indicates dimension index that matches the end coordinates/time/position.
"""
struct End <: Locus end

"""
Indicates dimension where the index position is not known.
"""
struct AutoLocus <: Locus end


"""
Indicates the sampling method used by the index.
"""
abstract type Sampling end

"""
[`Sampling`](@ref) mode where single samples at exact points.
"""
struct Points <: Sampling end

locus(sampling::Points) = Center()

"""
[`Sampling`](@ref) mode where samples are the mean (or similar) value over an interval.
"""
struct Intervals{L} <: Sampling
    locus::L
end
Intervals() = Intervals(AutoLocus())
rebuild(::Intervals, locus) = Intervals(locus)

locus(sampling::Intervals) = sampling.locus


"""
Mode defining the type of interval used in a InervalSampling index.
"""
abstract type Span end

struct AutoStep end

"""
Intervalss have regular size. This is passed to the constructor,
although these are normally build automatically.
"""
struct Regular{S} <: Span
    step::S
end
Regular() = Regular(AutoStep())

Base.step(span::Regular) = span.step

val(span::Regular) = span.step

"""
Irregular have irrigular size. To enable bounds tracking and accuract
selectors, the starting bounds must be provided as a 2 tuple,
or 2 arguments.
"""
struct Irregular{B<:Union{<:Tuple{<:Any,<:Any},Nothing}} <: Span
    bounds::B
end
Irregular() = Irregular(nothing, nothing)
Irregular(a, b) = Irregular((a, b))

bounds(span::Irregular) = span.bounds

"""
Span will be guessed and replaced by a constructor.
"""
struct AutoSpan <: Span end




"""
IndexModes are types defining the behaviour of a dimension, how they are plotted and
how [`Selector`](@ref)s like [`Between`](@ref) work.

An IndexMode may be a simple type like [`NoIndex`](@ref) indicating that the index is
just the underlying array axis. It could also be a [`Categorical`](@ref) index indicating
the index is ordered or unordered categories, or a [`Sampled`](@ref) index indicating
sampling along some transect.
"""
abstract type IndexMode end

bounds(mode::IndexMode, dim) = bounds(indexorder(mode), mode, dim)
bounds(::Forward, ::IndexMode, dim) = first(dim), last(dim)
bounds(::Reverse, ::IndexMode, dim) = last(dim), first(dim)
bounds(::Unordered, ::IndexMode, dim) = error("Cannot call `bounds` on an unordered mode")

dims(::IndexMode) = nothing
order(::IndexMode) = Unordered()
arrayorder(mode::IndexMode) = arrayorder(order(mode))
indexorder(mode::IndexMode) = indexorder(order(mode))
relationorder(mode::IndexMode) = relationorder(order(mode))
locus(mode::IndexMode) = Center()

reversearray(mode::IndexMode) = rebuild(mode, reversearray(order(mode)))
reverseindex(mode::IndexMode) = rebuild(mode, reverseindex(order(mode)))

Base.step(mode::T) where T <: IndexMode =
    error("No step provided by $T. Use a `Sampled` with `Regular`")

slicemode(mode::IndexMode, index, I) = mode

"""
    Auto()

Automatic [`IndexMode`](@ref), the default mode. It will be converted automatically to
another [`IndexMode`](@ref) when it is possible to detect it from the index.
"""
struct Auto{O<:Order} <: IndexMode
    order::O
end
Auto() = Auto(AutoOrder())

order(mode::Auto) = mode.order



"""
Supertype for [`IndexMode`](@ref) where the index is aligned with the array axes.
This is by far the most common case.
"""
abstract type Aligned{O} <: IndexMode end

order(mode::Aligned) = mode.order

"""
    NoIndex()

An [`IndexMode`](@ref) that is identical to the array axis.

## Example

Defining a [`DimensionalArray`](@ref) without passing an index
to the dimension, the IndexMode will be `NoIndex`:

```jldoctest
A = DimensionalArray(rand(3, 3), (X, Y))
map(mode, dims(A))

# output

(NoIndex(), NoIndex())
```

Is identical to:

```jldoctest
A = DimensionalArray(rand(3, 3), (X(; mode=NoIndex()), Y(; mode=NoIndex())))
map(mode, dims(A))

# output

(NoIndex(), NoIndex())
```
"""
struct NoIndex <: Aligned{Ordered{Forward,Forward,Forward}} end

order(mode::NoIndex) = Ordered(Forward(), Forward(), Forward())

"""
Abstract supertype for [`IndexMode`](@ref)s where the index is aligned with the array, 
and is independent of other dimensions. [`Sampled`](@ref) is provided by this package, 
`Projected` in GeoData.jl also extends [`AbstractSampled`](@ref), adding crs projections.
"""
abstract type AbstractSampled{O<:Order,Sp<:Span,Sa<:Sampling} <: Aligned{O} end

span(mode::AbstractSampled) = mode.span
sampling(mode::AbstractSampled) = mode.sampling
locus(mode::AbstractSampled) = locus(sampling(mode))

Base.step(mode::AbstractSampled) = step(span(mode))

bounds(mode::AbstractSampled, dim) =
    bounds(sampling(mode), span(mode), mode, dim)

bounds(::Points, span, mode::AbstractSampled, dim) =
    bounds(indexorder(mode), mode, dim)

bounds(::Intervals, span::Irregular, mode::AbstractSampled, dim) =
    bounds(span)

bounds(::Intervals, span::Regular, mode::AbstractSampled, dim) =
    bounds(locus(mode), indexorder(mode), span, mode, dim)

bounds(::Start, ::Forward, span, mode, dim) =
    first(dim), last(dim) + step(span)
bounds(::Start, ::Reverse, span, mode, dim) =
    last(dim), first(dim) - step(span)
bounds(::Center, ::Forward, span, mode, dim) =
    first(dim) - step(span) / 2, last(dim) + step(span) / 2
bounds(::Center, ::Reverse, span, mode, dim) =
    last(dim) + step(span) / 2, first(dim) - step(span) / 2
bounds(::End, ::Forward, span, mode, dim) =
    first(dim) - step(span), last(dim)
bounds(::End, ::Reverse, span, mode, dim) =
    last(dim) + step(span), first(dim)

sortbounds(mode::IndexMode, bounds) = sortbounds(indexorder(mode), bounds)
sortbounds(mode::Forward, bounds) = bounds
sortbounds(mode::Reverse, bounds) = bounds[2], bounds[1]

# TODO: deal with unordered AbstractArray indexing
slicemode(mode::AbstractSampled, index, I) =
    slicemode(sampling(mode), span(mode), mode, index, I)
slicemode(::Any, ::Any, mode::AbstractSampled, index, I) = mode
slicemode(::Intervals, ::Irregular, mode::AbstractSampled, index, I) = begin
    span = Irregular(slicebounds(mode, index, I))
    rebuild(mode, order(mode), span, sampling(mode))
end

slicebounds(m::IndexMode, index, I) =
    slicebounds(locus(m), bounds(span(m)), index, maybeflip(indexorder(m), index, I))
slicebounds(locus::Start, bounds, index, I) =
    index[first(I)], last(I) >= lastindex(index) ? bounds[2] : index[last(I) + 1]
slicebounds(locus::End, bounds, index, I) =
    first(I) <= firstindex(index) ? bounds[1] : index[first(I) - 1], index[last(I)]
slicebounds(locus::Center, bounds, index, I) =
    first(I) <= firstindex(index) ? bounds[1] : (index[first(I) - 1] + index[first(I)]) / 2,
    last(I)  >= lastindex(index)  ? bounds[2] : (index[last(I) + 1]  + index[last(I)]) / 2


""" 
    Sampled(order::Order, span::Span, sampling::Sampling)
    Sampled(; order=AutoOrder(), span=AutoSpan(), sampling=Points())

A concrete implementation of [`AbstractSampled`](@ref). It can be used to represent
points or intervals, with `sampling` of [`Points`](@ref) or [`Intervals`](@ref).

It should be capable of representing gridded data from a wide range of sources, allowing 
correct `bounds` and [`Selector`](@ref)s for points or intervals of regular, irregular, 
forward and reverse indexes.

`Sampled` will be detected for all ranges not assigned to [`Categorical`](@ref).
[`Order`](@ref) detected. The span will be assigned to [`Regular`](@ref) for 
`AbstractRange` and [`Irregular`](@ref) for `AbstractArray` unless assigned manually.

Sampling is be assigned to [`Points`](@ref), unless set to [`Intervals`](@ref) 
manually. Using [`Intervals`](@ref) will change the behaviour of `bounds` and `Selectors`s 
to take account for the full size of the interval, rather than the point alone.

## Fields
- `order`: [`Order`](@ref) indicating array and index order
- `span::Span`: [`Span`](@ref) indicating [`Regular`](@ref) or [`Irregular`](@ref)
  size of intervals or distance between points
- `sampling::Sampling`: [`Sampling`](@ref) of [`Intervals`](@ref) or [`Points`](@ref) (the default)

## Example

Create an array with [`Interval`] sampling.

```jldoctest
dims_ = (X(100:-10:10; mode=Sampled(sampling=Intervals())), 
         Y([1, 4, 7, 10]; mode=Sampled(span=Regular(2), sampling=Intervals()))) 
A = DimensionalArray(rand(10, 4), dims_)
map(mode, dims(A))

# output

(Sampled{Ordered{DimensionalData.Reverse,DimensionalData.Forward,DimensionalData.Forward},Regular{Int64},Intervals{Center}}(Ordered{DimensionalData.Reverse,DimensionalData.Forward,DimensionalData.Forward}(DimensionalData.Reverse(), DimensionalData.Forward(), DimensionalData.Forward()), Regular{Int64}(-10), Intervals{Center}(Center())), Sampled{Ordered{DimensionalData.Forward,DimensionalData.Forward,DimensionalData.Forward},Regular{Int64},Intervals{Center}}(Ordered{DimensionalData.Forward,DimensionalData.Forward,DimensionalData.Forward}(DimensionalData.Forward(), DimensionalData.Forward(), DimensionalData.Forward()), Regular{Int64}(2), Intervals{Center}(Center())))
```
"""
struct Sampled{O,Sp,Sa} <: AbstractSampled{O,Sp,Sa}
    order::O
    span::Sp
    sampling::Sa
end
Sampled(; order=AutoOrder(), span=AutoSpan(), sampling=Points()) =
    Sampled(order, span, sampling)

rebuild(m::Sampled, order=order(m), span=span(m), sampling=sampling(m)) =
    Sampled(order, span, sampling)


"""
[`IndexMode`](@ref)s for dimensions where the values are categories.

[`Categorical`](@ref) is the provided concrete implementation.
"""
abstract type AbstractCategorical{O} <: Aligned{O} end

order(mode::AbstractCategorical) = mode.order

"""
    Categorical(o::Order)
    Categorical(; order=Unordered())

An IndexMode where the values are categories.

This will be automatically assigned if the index contains `AbstractString`, 
`Symbol` or `Char`. Otherwise it can be assigned manually.

[`Order`](@ref) will not be determined automatically for [`Categorical`](@ref),
it instead defaults to [`Unordered`].

## Fields
- `order`: [`Order`](@ref) indicating array and index order.

## Example

Create an array with [`Interval`] sampling.

```jldoctest
dims_ = X(["one", "two", "thee"]), Y([:a, :b, :c, :d])
A = DimensionalArray(rand(3, 4), dims_)
map(mode, dims(A))

# output

(Categorical{Unordered{DimensionalData.Forward}}(Unordered{DimensionalData.Forward}(DimensionalData.Forward())), Categorical{Unordered{DimensionalData.Forward}}(Unordered{DimensionalData.Forward}(DimensionalData.Forward())))
```
"""
struct Categorical{O<:Order} <: AbstractCategorical{O}
    order::O
end
Categorical(; order=Unordered()) = Categorical(order)

rebuild(mode::Categorical, order) = Categorical(order)





"""
Supertype for [`IndexMode`](@ref) where the `Dimension` index is not aligned to the grid.

Indexing with an [`Unaligned`](@ref) dimension with [`Selector`](@ref)s must provide all
other [`Unaligned`](@ref) dimensions.
"""
abstract type Unaligned <: IndexMode end

"""
    Transformed(f, dim::Dimension)

[`IndexMode`](@ref) that uses an affine transformation to convert
dimensions from `dims(mode)` to `dims(array)`. This can be useful
when the dimensions are e.g. rotated from a more commonly used axis.

Any function can be used to do the transformation, but transformations
from CoordinateTransformations.jl may be useful.

## Fields
- `f`: transformation function
- `dims`: a tuple containing dimenension types or symbols matching the
  order needed by the transform function.

## Example

```jldoctest
using CoordinateTransformations

m = LinearMap([0.5 0.0; 0.0 0.5])
A = [1 2  3  4
     5 6  7  8
     9 10 11 12];
dimz = Dim{:t1}(mode=Transformed(m, X)),
              Dim{:t2}(mode=Transformed(m, Y))
da = DimensionalArray(A, dimz)

da[X(At(6)), Y(At(2))]

# output

9
```
"""
struct Transformed{F,D} <: Unaligned
    f::F
    dim::D
end

transform(mode::Transformed) = mode.f
dims(mode::Transformed) = mode.dim

rebuild(mode::Transformed, f=transform(mode), dim=dims(mode)) =
    Transformed(f, dim)

# TODO bounds

const CategoricalEltypes = Union{AbstractChar,Symbol,AbstractString}

"""
    identify(indexmode, index)

Identify an `IndexMode` or its fields from index content and existing `IndexMode`.
"""
function identify end

identify(IM::Type{<:IndexMode}, dimtype::Type, index) =
    identify(IM(), dimtype, index)

# No more identification required for some types
identify(mode::IndexMode, dimtype::Type, index) = mode

# Auto
identify(mode::Auto, dimtype::Type, index::AbstractArray) =
    identify(Sampled(), dimtype, index)
identify(mode::Auto, dimtype::Type, index::AbstractArray{<:CategoricalEltypes}) =
    order(mode) isa AutoOrder ? Categorical() : Categorical(order(mode))

# Sampled
identify(mode::AbstractSampled, dimtype::Type, index::AbstractArray) = begin
    mode = rebuild(mode,
        identify(order(mode), dimtype, index),
        identify(span(mode), dimtype, index),
        identify(sampling(mode), dimtype, index)
    )
end

# Order
identify(order::Order, dimtype::Type, index) = order
identify(order::AutoOrder, dimtype::Type, index) = _orderof(index)

_orderof(index::AbstractRange) =
    Ordered(index=_indexorder(index))
_orderof(index::AbstractArray) = begin
    local sorted
    local indord
    try
        indord = _indexorder(index)
        sorted = issorted(index; rev=isrev(indord))
    catch
        sorted = false
    end
    sorted ? Ordered(index=indord) : Unordered()
end

_indexorder(index::AbstractArray) =
    first(index) <= last(index) ? Forward() : Reverse()

# Span
identify(span::AutoSpan, dimtype::Type, index::AbstractArray) =
    Irregular()
identify(span::AutoSpan, dimtype::Type, index::AbstractRange) =
    Regular(step(index))
identify(span::Regular{AutoStep}, dimtype::Type, index::AbstractArray) =
    throw(ArgumentError("`Regular` must specify `step` size with an index other than `AbstractRange`"))
identify(span::Regular, dimtype::Type, index::AbstractArray) =
    span
identify(span::Regular{AutoStep}, dimtype::Type, index::AbstractRange) =
    Regular(step(index))
identify(span::Regular, dimtype::Type, index::AbstractRange) = begin
    step(span) ≈ step(index) || throw(ArgumentError("mode step $(step(span)) does not match index step $(step(index))"))
    span
end
identify(span::Irregular{Nothing}, dimtype, index) =
    if length(index) > 1
        bound1 = index[1] - (index[2] - index[1]) / 2
        bound2 = index[end] + (index[end] - index[end-1]) / 2
        Irregular(sortbounds(bound1, bound2))
    else
        Irregular(nothing, nothing)
    end
identify(span::Irregular{<:Tuple}, dimtype, index) = span

# Sampling
identify(sampling::Points, dimtype::Type, index) = sampling
identify(sampling::Intervals, dimtype::Type, index) =
    rebuild(sampling, identify(locus(sampling), dimtype, index))

# Locus
identify(locus::AutoLocus, dimtype::Type, index) = Center()
identify(locus::Locus, dimtype::Type, index) = locus
