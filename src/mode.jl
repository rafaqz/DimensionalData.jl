
"""
    ModeComponent

Abstract supertype of all component objects of [`Mode`](@ref).
"""
abstract type ModeComponent end

"""
    Order <: ModeComponent

Traits for the order of the array, index and the relation between them.
"""
abstract type Order <: ModeComponent end

"""
    AutoOrder <: Order

    AutoOrder()

Order will be found automatically where possible.

This will fail for all dim eltypes without `isless` methods.
"""
struct AutoOrder <: Order end

"""
    UnknownOrder <: Order

    UnknownOrder()

Specifies that Order is not known and can't be determined.
"""
struct UnknownOrder <: Order end


"""
    SubOrder <: Order

Abstract supertype for sub-components of `Order` types
"""
abstract type SubOrder <: Order end


"""
    IndexOrder <: SubOrder

Abstract supertype for dim index order
"""
abstract type IndexOrder <: SubOrder end

"""
    ForwardIndex <: IndexOrder

    ForwardIndex()

Indicates that the dimension index is in the normal forward order.
"""
struct ForwardIndex <: IndexOrder end

"""
    ReverseIndex <: IndexOrder

    ReverseIndex()

Indicates that the dimension index is in reverse order.
"""
struct ReverseIndex <: IndexOrder end

struct UnorderedIndex <: IndexOrder end

"""
    ArrayOrder <: IndexOrder

Abstract supertype for array ordering
"""
abstract type ArrayOrder <: SubOrder end

"""
    ForwardArray <: ArrayOrder

    ForwardArray()

Indicates that the array axis is in the normal forward order.
"""
struct ForwardArray <: ArrayOrder end

"""
    ReverseArray <: ArrayOrder

    ReverseArray()

Indicates that the array axis is in reverse order.

It will be plotted backwards.
"""
struct ReverseArray <: ArrayOrder end



"""
    Relation <: SubOrder

Abstract supertype for index/array relationship
"""
abstract type Relation <: SubOrder end

"""
    ForwardRelation <: Relation

    ForwardRelation()

Indicates that the relationship between the index and the array is 
in the normal forward direction.
"""
struct ForwardRelation <: Relation end

"""
    ReverseRelation <: Relation

    ReverseRelation()

Indicates that the relationship between the index and the array is reversed.
"""
struct ReverseRelation <: Relation end

arrayorder(args...) = order(ArrayOrder, args...)
indexorder(args...) = order(IndexOrder, args...)
relation(args...) = order(Relation, args...)

"""
    Ordered <: Order 

    Ordered(index, array, relation)
    Ordered(; index=ForwardIndex(), array=ForwardArray(), relation=ForwardRelation())

Container object for dimension and array ordering.

## Fields

Each can have a value of  `ForwardX` or `ReverseX`.

- `index`: The order of the dimension index
- `array`: The order of array axis, in terms of how you would want to plot it
- `relation`: The relation between the index and the array.

All combinations of forward and reverse order for data and index seem to occurr
in real datasets, as strange as that seems. We cover these possibilities by specifying
the order of both explicitly, and the direction of the relationship between them.

Knowing the order of indices is important for using methods like `searchsortedfirst()`
to find indices in sorted lists of values. Knowing the order of the data is then
required to map to the actual indices. It's also used to plot the data later.

The default is `Ordered(ForwardIndex()`, `ForwardArray(), ForwardRelation())`
"""
struct Ordered{D<:IndexOrder,A<:ArrayOrder,R<:Relation} <: Order
    index::D
    array::A
    relation::R
end
Ordered(; index=ForwardIndex(), array=ForwardArray(), relation=ForwardRelation()) =
    Ordered(index, array, relation)

indexorder(order::Ordered) = order.index
arrayorder(order::Ordered) = order.array
relation(order::Ordered) = order.relation

"""
    Unordered <: Order 

    Unordered(relation=ForwardRelation())

Trait indicating that the array or dimension has no order.
This means the index cannot be searched with `searchsortedfirst`,
or similar methods, and that plotting order does not matter.

It still has a relation between the array axis and the dimension index.
"""
struct Unordered{R} <: Order
    relation::R
end
Unordered() = Unordered(ForwardRelation())

indexorder(order::Unordered) = UnorderedIndex()
arrayorder(order::Unordered) = ForwardArray()
relation(order::Unordered) = order.relation

# Get the order specifying type
order(ot::Type{<:IndexOrder}, order::Union{Ordered,Unordered}) = indexorder(order)
order(ot::Type{<:ArrayOrder}, order::Union{Ordered,Unordered}) = arrayorder(order)
order(ot::Type{<:Relation}, order::Union{Ordered,Unordered}) = relation(order)

# Sometimes you need order as a Bool, like for serarchsorted
isrev(::SO) where SO<:SubOrder = isrev(SO)
isrev(::Type{ForwardIndex}) = false
isrev(::Type{ReverseIndex}) = true
isrev(::Type{ForwardArray}) = false
isrev(::Type{ReverseArray}) = true
isrev(::Type{ForwardRelation}) = false
isrev(::Type{ReverseRelation}) = true

"""
   Locus <: ModeComponent

Abstract supertype of types that indicate the position of index values in cells.

These allow for values array cells to align with the `Start`,
[`Center`](@ref), or [`End`](@ref) of values in the dimension index.

This means they can be plotted with correct axis markers, and allows automatic
converrsions to between formats with different standards (such as NetCDF and GeoTiff).

Locii are often `Start` for time series, but often `Center` for spatial data.

These are reflected in the default values: `Ti` dimensions with `Sampled` index mode
will default to `Start` Locii. All others default to `Center`.
"""
abstract type Locus <: ModeComponent end

"""
    Center <: Locus

    Center()

Indicates a dimension value is for the center of its corresponding array cell,
in the direction of the dimension index order.
"""
struct Center <: Locus end

"""
    Start <: Locus

    Start()

Indicates a dimension value is for the start of its corresponding array cell,
in the direction of the dimension index order.
"""
struct Start <: Locus end

"""
    End <: Locus

    End()

Indicates a dimension value is for the end of its corresponding array cell,
in the direction of the dimension index order.
"""
struct End <: Locus end

"""
    AutoLocus <: Locus

    AutoLocus()

Indicates a dimension where the index position is not yet known.
This will be filled with a default on object construction.
"""
struct AutoLocus <: Locus end


"""
    Sampling <: ModeComponent

Indicates the sampling method used by the index: [`Points`](@ref)
or [`Intervals`](@ref).
"""
abstract type Sampling <: ModeComponent end

struct AutoSampling <: Sampling end

"""
    Points <: Sampling

    Points()

[`Sampling`](@ref) mode where single samples at exact points.

These are always plotted at the center of array cells.
"""
struct Points <: Sampling end

locus(sampling::Points) = Center()

"""
    Intervals <: Sampling

    Intervals(locus::Locus)

[`Sampling`](@ref) mode where samples are the mean (or similar)
value over an interval.

Intervals require a [`Locus`](@ref) of `Start`, `Center` or `End`
to define where in the interval the index values refer to.
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
    Span <: ModeComponent

Defines the type of span used in a [`Sampling`](@ref) index.
These are [`Regular`](@ref) or [`Irregular`](@ref).
"""
abstract type Span <: ModeComponent end

"""
    AutoSpan <: Span

    AutoSpan()

Span will be guessed and replaced by a constructor.
"""
struct AutoSpan <: Span end

struct AutoStep end

"""
    Regular <: Span

    Regular(step=AutoStep())

Intervalss have regular size. This is passed to the constructor,
although these are normally build automatically.
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

Irregular have irrigular size. To enable bounds tracking and accuract
selectors, the starting bounds must be provided as a 2 tuple,
or 2 arguments.
"""
struct Irregular{B<:Union{<:Tuple{<:Any,<:Any},Nothing}} <: Span
    bounds::B
end
Irregular() = Irregular(nothing, nothing)
Irregular(lowerbound, upperbound) = Irregular((lowerbound, upperbound))

bounds(span::Irregular) = span.bounds

"""
    Mode 

Abstract supertype for all `Dimension` modes.
Defines or modifies dimension behaviour.
"""
abstract type Mode end

"""
    IndexMode <: Mode

Types defining the behaviour of a dimension index, how it is plotted 
and how [`Selector`](@ref)s like [`Between`](@ref) work.

An `IndexMode` may be a simple type like [`NoIndex`](@ref) indicating that the index is
just the underlying array axis. It could also be a [`Categorical`](@ref) index indicating
the index is ordered or unordered categories, or a [`Sampled`](@ref) index indicating
sampling along some transect.
"""
abstract type IndexMode <: Mode end

@noinline span(mode::T) where T<:IndexMode = 
    error("$T has no span. Pass a `span` field manually.")
@noinline sampling(mode::T) where T<:IndexMode = 
    error("$T has no sampling. Pass a `sampling` field manually.")

dims(::IndexMode) = nothing
dims(::Type{<:IndexMode}) = nothing
order(ot::Type{<:SubOrder}, mode::IndexMode) = order(ot, order(mode))
arrayorder(mode::IndexMode) = arrayorder(order(mode))
indexorder(mode::IndexMode) = indexorder(order(mode))
relation(mode::IndexMode) = relation(order(mode))
locus(mode::IndexMode) = Center()

Base.step(mode::IndexMode, dim) = Base.step(mode)

"""
    AutoMode <: Mode

    AutoMode()

Automatic [`IndexMode`](@ref), the default mode. It will be converted automatically
to another [`IndexMode`](@ref) when it is possible to detect it from the index.
"""
struct AutoMode{O<:Order} <: IndexMode
    order::O
end
AutoMode() = AutoMode(AutoOrder())

order(mode::AutoMode) = mode.order

Base.step(mode::AutoMode, dim) = Base.step(index(dim))

const Auto = AutoMode

bounds(mode::IndexMode, dim) = bounds(indexorder(mode), mode, dim)
bounds(::ForwardIndex, ::IndexMode, dim) = first(dim), last(dim)
bounds(::ReverseIndex, ::IndexMode, dim) = last(dim), first(dim)
bounds(::UnorderedIndex, ::IndexMode, dim) = (nothing, nothing)

@noinline Base.step(mode::T) where T <: IndexMode =
    error("No step provided by $T. Use a `Sampled` with `Regular`")

slicemode(mode::IndexMode, index, I) = mode


"""
    Aligned <: Mode

Abstract supertype for [`IndexMode`](@ref)s where the index is aligned with the array axes.
This is by far the most common case.
"""
abstract type Aligned{O} <: IndexMode end

order(mode::Aligned) = mode.order

"""
    NoIndex <: Mode

    NoIndex()

An [`IndexMode`](@ref) that is identical to the array axis.

## Example

Defining a [`DimArray`](@ref) without passing an index
to the dimension, the IndexMode will be `NoIndex`:

```jldoctest NoIndex
using DimensionalData

A = DimArray(rand(3, 3), (X, Y))
map(mode, dims(A))

# output

(NoIndex, NoIndex)
```

Is identical to:

```jldoctest NoIndex
A = DimArray(rand(3, 3), (X(; mode=NoIndex()), Y(; mode=NoIndex())))
map(mode, dims(A))

# output

(NoIndex, NoIndex)
```
"""
struct NoIndex <: Aligned{Ordered{ForwardIndex,ForwardArray,ForwardRelation}} end

order(mode::NoIndex) = Ordered(ForwardIndex(), ForwardArray(), ForwardRelation())

Base.step(mode::NoIndex) = 1

"""
    AbstractSampled <: Aligned

Abstract supertype for [`IndexMode`](@ref)s where the index is aligned with the array,
and is independent of other dimensions. [`Sampled`](@ref) is provided by this package,
`Projected` in GeoData.jl also extends [`AbstractSampled`](@ref), adding crs projections.

`AbstractSampled` must have  `order`, `span` and `sampling` fields,
or a `rebuild` method that accpts them as keyword arguments.
"""
abstract type AbstractSampled{O<:Order,Sp<:Span,Sa<:Sampling} <: Aligned{O} end

span(mode::AbstractSampled) = mode.span
sampling(mode::AbstractSampled) = mode.sampling
locus(mode::AbstractSampled) = locus(sampling(mode))

Base.step(mode::AbstractSampled) = step(span(mode))

# bounds
bounds(mode::AbstractSampled, dim) = bounds(sampling(mode), span(mode), mode, dim)
bounds(::Points, span, mode::AbstractSampled, dim) = bounds(indexorder(mode), mode, dim)
bounds(::Intervals, span::Irregular, mode::AbstractSampled, dim) = bounds(span)
bounds(::Intervals, span::Regular, mode::AbstractSampled, dim) =
    bounds(locus(mode), indexorder(mode), span, mode, dim)
bounds(::Start, ::ForwardIndex, span, mode, dim) = first(dim), last(dim) + step(span)
bounds(::Start, ::ReverseIndex, span, mode, dim) = last(dim), first(dim) - step(span)
bounds(::Center, ::ForwardIndex, span, mode, dim) =
    first(dim) - step(span) / 2, last(dim) + step(span) / 2
bounds(::Center, ::ReverseIndex, span, mode, dim) =
    last(dim) + step(span) / 2, first(dim) - step(span) / 2
bounds(::End, ::ForwardIndex, span, mode, dim) = first(dim) - step(span), last(dim)
bounds(::End, ::ReverseIndex, span, mode, dim) = last(dim) + step(span), first(dim)

# TODO: deal with unordered AbstractArray indexing
slicemode(mode::AbstractSampled, index, I) =
    slicemode(sampling(mode), span(mode), mode, index, I)
slicemode(::Any, ::Any, mode::AbstractSampled, index, I) = mode
slicemode(::Intervals, ::Irregular, mode::AbstractSampled, index, I) = begin
    span = Irregular(slicebounds(mode, index, I))
    rebuild(mode; order=order(mode), span=span, sampling=sampling(mode))
end

slicebounds(m::IndexMode, index, I) =
    slicebounds(locus(m), bounds(span(m)), index, _maybeflip(indexorder(m), index, I))
slicebounds(locus::Start, bounds, index, I) =
    index[first(I)], last(I) >= lastindex(index) ? bounds[2] : index[last(I) + 1]
slicebounds(locus::End, bounds, index, I) =
    first(I) <= firstindex(index) ? bounds[1] : index[first(I) - 1], index[last(I)]
slicebounds(locus::Center, bounds, index, I) =
    first(I) <= firstindex(index) ? bounds[1] : (index[first(I) - 1] + index[first(I)]) / 2,
    last(I)  >= lastindex(index)  ? bounds[2] : (index[last(I) + 1]  + index[last(I)]) / 2


"""
    Sampled <: AbstractSampled

    Sampled(order::Order, span::Span, sampling::Sampling)
    Sampled(; order=AutoOrder(), span=AutoSpan(), sampling=Points())

A concrete implementation of the [`IndexMode`](@ref) [`AbstractSampled`](@ref).
It can be used to represent [`Points`](@ref) or [`Intervals`](@ref).

It is capable of representing gridded data from a wide range of sources, allowing
correct `bounds` and [`Selector`](@ref)s for points or intervals of regular, irregular,
forward and reverse indexes.

The `Sampled` mode is assigned for all indexes of `AbstractRange`
not assigned to [`Categorical`](@ref).

## Fields

- `order` indicating array and index order (in [`Order`](@ref)), detected from the 
    range order.
- `span` indicates the size of intervals or distance between points, and will be set to
    [`Regular`](@ref) for `AbstractRange` and [`Irregular`](@ref) for `AbstractArray`,
    unless assigned manually.
- `sampling` is assigned to [`Points`](@ref), unless set to [`Intervals`](@ref) manually. 
    Using [`Intervals`](@ref) will change the behaviour of `bounds` and `Selectors`s
    to take account for the full size of the interval, rather than the point alone.

## Example

Create an array with [`Interval`] sampling.

```jldoctest Sampled
using DimensionalData

dims_ = (X(100:-10:10; mode=Sampled(sampling=Intervals())),
         Y([1, 4, 7, 10]; mode=Sampled(span=Regular(2), sampling=Intervals())))
A = DimArray(rand(10, 4), dims_)
map(mode, dims(A))

# output

(Sampled: Ordered Regular Intervals, Sampled: Ordered Regular Intervals)
```
"""
struct Sampled{O,Sp,Sa} <: AbstractSampled{O,Sp,Sa}
    order::O
    span::Sp
    sampling::Sa
end
Sampled(; order=AutoOrder(), span=AutoSpan(), sampling=AutoSampling()) =
    Sampled(order, span, sampling)

"""
    AbstractCategorical <: Aligned

[`IndexMode`](@ref)s for dimensions where the values are categories.

[`Categorical`](@ref) is the provided concrete implementation.

`AbstractCategorical` must have an `order` field or a `rebuild`
method with an `order` keyword argument.
"""
abstract type AbstractCategorical{O} <: Aligned{O} end

order(mode::AbstractCategorical) = mode.order


"""
    Categorical <: AbstractCategorical

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

```jldoctest Categorical
using DimensionalData

dims_ = X(["one", "two", "thee"]), Y([:a, :b, :c, :d])
A = DimArray(rand(3, 4), dims_)
map(mode, dims(A))

# output

(Categorical: Unordered, Categorical: Unordered)
```
"""
struct Categorical{O<:Order} <: AbstractCategorical{O}
    order::O
end
Categorical(; order=Unordered()) = Categorical(order)




"""
    Unaligned <: IndexMode

Abstract supertype for [`IndexMode`](@ref) where the `Dimension` index is not aligned to 
the grid.

Indexing with an [`Unaligned`](@ref) dimension with [`Selector`](@ref)s must provide all
other [`Unaligned`](@ref) dimensions.
"""
abstract type Unaligned <: IndexMode end

"""
    Transformed <: Unaligned

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
using DimensionalData, CoordinateTransformations

m = LinearMap([0.5 0.0; 0.0 0.5])
A = [1 2  3  4
     5 6  7  8
     9 10 11 12];
dimz = Dim{:t1}(mode=Transformed(m, X)),
              Dim{:t2}(mode=Transformed(m, Y))
da = DimArray(A, dimz)

da[X(At(6)), Y(At(2))]

# output

9
```
"""
struct Transformed{F,D} <: Unaligned
    f::F
    dim::D
end
Transformed(f, D::UnionAll) = Transformed(f, D())

f(mode::Transformed) = mode.f
transformfunc(mode::Transformed) = f(mode)
dims(mode::Transformed) = mode.dim
dims(::Type{<:Transformed{<:Any,D}}) where D = D

# TODO bounds

const CategoricalEltypes = Union{AbstractChar,Symbol,AbstractString}
