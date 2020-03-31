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
struct PointSampling <: Sampling end

locus(sampling::PointSampling) = Center()

"""
[`Sampling`](@ref) mode where samples are the mean (or similar) value over an interval.
"""
struct IntervalSampling{L} <: Sampling
    locus::L
end
IntervalSampling() = IntervalSampling(AutoLocus())
rebuild(::IntervalSampling, locus) = IntervalSampling(locus)

locus(sampling::IntervalSampling) = sampling.locus


"""
Mode defining the type of interval used in a InervalSampling index.
"""
abstract type Span end

"""
Intervals have regular size. This is passed to the constructor,
although these are normally build automatically.
"""
struct RegularSpan{S} <: Span
    step::S
end
RegularSpan() = RegularSpan(nothing)

Base.step(span::RegularSpan) = span.step

val(span::RegularSpan) = span.step

"""
IrregularSpan have irrigular size. To enable bounds tracking and accuract
selectors, the starting bounds must be provided as a 2 tuple,
or 2 arguments.
"""
struct IrregularSpan{B<:Union{<:Tuple{<:Any,<:Any},Nothing}} <: Span
    bounds::B
end
IrregularSpan() = IrregularSpan(nothing)
IrregularSpan(a, b) = IrregularSpan((a, b))

bounds(span::IrregularSpan) = span.bounds

"""
Span will be guessed and replaced by a constructor.
"""
struct AutoSpan <: Span end



"""
Traits describing the indexmode of a dimension.
"""
abstract type IndexMode end

bounds(indexmode::IndexMode, dim) = bounds(indexorder(indexmode), indexmode, dim)
bounds(::Forward, indexmode, dim) = first(dim), last(dim)
bounds(::Reverse, indexmode, dim) = last(dim), first(dim)
bounds(::Unordered, indexmode, dim) = error("Cannot call `bounds` on an unordered indexmode")

dims(m::IndexMode) = nothing
order(m::IndexMode) = Unordered()
arrayorder(indexmode::IndexMode) = arrayorder(order(indexmode))
indexorder(indexmode::IndexMode) = indexorder(order(indexmode))
relationorder(indexmode::IndexMode) = relationorder(order(indexmode))

reversearray(m::IndexMode) = rebuild(m, reversearray(order(m)))
reverseindex(m::IndexMode) = rebuild(m, reverseindex(order(m)))

Base.step(indexmode::T) where T <: IndexMode =
    error("No step provided by $T. Use a `SampledIndex` with `RegularSpan`")

sliceindexmode(indexmode::IndexMode, index, I) = indexmode


"""
`IndexMode` that is identical to the array axis.
"""
struct NoIndex <: IndexMode end

order(indexmode::NoIndex) = Ordered(Forward(), Forward(), Forward())

"""
Automatic [`IndexMode`](@ref). Will be converted automatically to another
`IndexMode` when possible.
"""
struct AutoIndex{O<:Order} <: IndexMode
    order::O
end
AutoIndex() = AutoIndex(AutoOrder())

order(m::AutoIndex) = m.order

"""
Supertype for [`IndexMode`](@ref) where the index is aligned with the array axes. 
This is by far the most common case.
"""
abstract type AlignedIndex{O} <: IndexMode end

order(m::AlignedIndex) = m.order

"""
An [`IndexMode`](@ref) whos index is aligned with the array,
and is independent of other dimensions.
"""
abstract type AbstractSampledIndex{O<:Order,Sp<:Span,Sa<:Sampling} <: AlignedIndex{O} end

span(indexmode::AbstractSampledIndex) = indexmode.span
sampling(indexmode::AbstractSampledIndex) = indexmode.sampling
locus(indexmode::AbstractSampledIndex) = locus(sampling(indexmode))

Base.step(indexmode::AbstractSampledIndex) = step(span(indexmode))

bounds(indexmode::AbstractSampledIndex, dim) =
    bounds(sampling(indexmode), span(indexmode), indexmode, dim)

bounds(::PointSampling, span, indexmode::AbstractSampledIndex, dim) =
    bounds(indexorder(indexmode), indexmode, dim)

bounds(::IntervalSampling, span::IrregularSpan, indexmode::AbstractSampledIndex, dim) =
    bounds(span)

bounds(s::IntervalSampling, span::RegularSpan, m::AbstractSampledIndex, dim) =
    bounds(locus(s), indexorder(m), span, m, dim)

bounds(::Start, ::Forward, span, indexmode, dim) =
    first(dim), last(dim) + step(span)
bounds(::Start, ::Reverse, span, indexmode, dim) =
    last(dim), first(dim) - step(span)
bounds(::Center, ::Forward, span, indexmode, dim) =
    first(dim) - step(span) / 2, last(dim) + step(span) / 2
bounds(::Center, ::Reverse, span, indexmode, dim) =
    last(dim) + step(span) / 2, first(dim) - step(span) / 2
bounds(::End, ::Forward, span, indexmode, dim) =
    first(dim) - step(span), last(dim)
bounds(::End, ::Reverse, span, indexmode, dim) =
    last(dim) + step(span), first(dim)


sortbounds(indexmode::IndexMode, bounds) = sortbounds(indexorder(indexmode), bounds)
sortbounds(indexmode::Forward, bounds) = bounds
sortbounds(indexmode::Reverse, bounds) = bounds[2], bounds[1]


# TODO: deal with unordered AbstractArray indexing
sliceindexmode(m::AbstractSampledIndex, index, I) =
    sliceindexmode(sampling(m), span(m), m, index, I)
sliceindexmode(::Any, ::Any, m::AbstractSampledIndex, index, I) = m
sliceindexmode(::IntervalSampling, ::IrregularSpan, m::AbstractSampledIndex, index, I) = begin
    span = IrregularSpan(slicebounds(m, index, I))
    rebuild(m, order(m), span, sampling(m))
end

slicebounds(m, index, I) =
    slicebounds(locus(m), bounds(span(m)),  index, maybeflip(indexorder(m), index, I))
slicebounds(locus::Start, bounds, index, I) =
    index[first(I)], last(I) >= lastindex(index) ? bounds[2] : index[last(I) + 1]
slicebounds(locus::End, bounds, index, I) =
    first(I) <= firstindex(index) ? bounds[1] : index[first(I) - 1], index[last(I)]
slicebounds(locus::Center, bounds, index, I) =
    first(I) <= firstindex(index) ? bounds[1] : (index[first(I) - 1] + index[first(I)]) / 2,
    last(I)  >= lastindex(index)  ? bounds[2] : (index[last(I) + 1]  + index[last(I)]) / 2


"""
A concrete implementation of [`AbstractSampledIndex`](@ref) where all cells are
the same size and evenly spaced. This [`IndexMode`](@ref) will often be paired
with a range, but may also be paired with a vector.

## Fields
- `order`: [`Order`](@ref) indicating array and index order
- `locus::Locus`: [`Locus`](@ref) indicating the position of the indexed
  point within the cell step
- `span::Span`: [`Span`](@ref) indicating regular or irregular size of intervals or distance between
  points
"""
struct SampledIndex{O,Sp,Sa} <: AbstractSampledIndex{O,Sp,Sa}
    order::O
    span::Sp
    sampling::Sa
end
SampledIndex(; order=Ordered(), span=AutoSpan(), sampling=PointSampling()) =
    SampledIndex(order, span, sampling)

rebuild(m::SampledIndex, order=order(m), span=span(m), sampling=sampling(m)) =
    SampledIndex(order, span, sampling)


"""
[`IndexMode`](@ref)s for dimensions where the values are categories.
"""
abstract type AbstractCategoricalIndex{O} <: AlignedIndex{O} end

order(m::AbstractCategoricalIndex) = m.order
rebuild(m::AbstractCategoricalIndex, order=order(m)) = CategoricalIndex(order)

"""
An IndexMode where the values are categories.

## Fields
- `order`: [`Order`](@ref) indicating array and index order
"""
struct CategoricalIndex{O<:Order} <: AbstractCategoricalIndex{O}
    order::O
end
CategoricalIndex(; order=Ordered()) = CategoricalIndex(order)



"""
Supertype for [`IndexMode`](@ref) where the index is not aligned to the grid.

Indexing into a unaligned dimension must provide all other unaligned dimensions.
"""
abstract type UnalignedIndex <: IndexMode end

locus(m::UnalignedIndex) = m.locus
dims(m::UnalignedIndex) = m.dims

"""
[`IndexMode`](@ref) that uses an affine transformation to convert
dimensions from `dims(indexmode)` to `dims(array)`.

## Fields
- `dims`: a tuple containing dimenension types or symbols matching the
  order needed by the transform function.
"""
struct TransformedIndex{D,L} <: UnalignedIndex
    dims::D
    locus::L
end
TransformedIndex(dims; locus=Start()) = TransformedIndex(dims, locus)

rebuild(m::TransformedIndex, dims=dims(m), locus=locus(m) ) =
    TransformedIndex(dims, locus)

# TODO bounds

# """
# An IndexMode that uses an array lookup to convert dimension from
# `dim(indexmode)` to `dims(array)`.

# ## Fields
# - `dims`: a tuple containing dimenension types or symbols matching the order
          # needed to index the lookup matrix.
# """
# struct LookupIndex{D,L} <: UnalignedIndex
    # dims::D
    # locus::L
# end
# LookupIndex(dims=(), locus=Start())) =
    # LookupIndex(dims, locus)

# rebuild(m::LookupIndex; dims=dims(m), locus=locus(m)) =
    # LookupIndex(dims, locus)


"""
    identify(::IndexMode, index)

Identify an `IndexMode` from index content and existing `IndexMode`.
"""
identify(IM::Type{<:IndexMode}, dimtype::Type, index) =
    identify(IM(), dimtype, index)
identify(indexmode::IndexMode, dimtype::Type, index) = indexmode

identify(indexmode::AutoIndex, dimtype::Type, index::AbstractArray) =
    identify(SampledIndex(), dimtype, index)
identify(indexmode::AutoIndex, dimtype::Type, index::AbstractArray{<:Union{AbstractChar,Symbol,AbstractString}}) =
    CategoricalIndex()
identify(indexmode::CategoricalIndex, dimtype::Type, index) = indexmode

identify(indexmode::AbstractSampledIndex, dimtype::Type, index::AbstractArray) = begin
    indexmode = rebuild(indexmode,
        identify(order(indexmode), dimtype, index),
        identify(span(indexmode), dimtype, index),
        identify(sampling(indexmode), dimtype, index),
    )
end

identify(span::AutoSpan, dimtype::Type, index::AbstractArray) =
    IrregularSpan()
identify(span::AutoSpan, dimtype::Type, index::AbstractRange) =
    RegularSpan(step(index))

identify(span::RegularSpan, dimtype::Type, index::AbstractArray) =
    span
identify(span::RegularSpan, dimtype::Type, index::AbstractRange) = begin
    step(span) == step(index) || throw(ArgumentError("indexmode step $(step(span)) does not match index step $(step(index))"))
    span
end

identify(span::IrregularSpan{Nothing}, dimtype, index) =
    if length(index) > 1
        bound1 = index[1] - (index[2] - index[1]) / 2
        bound2 = index[end] + (index[end] - index[end-1]) / 2
        IrregularSpan(sortbounds(bound1, bound2))
    else
        IrregularSpan(nothing)
    end
identify(span::IrregularSpan{<:Tuple}, dimtype, index) = span


identify(sampling::PointSampling, dimtype::Type, index) = sampling
identify(sampling::IntervalSampling, dimtype::Type, index) =
    rebuild(sampling, identify(locus(sampling), dimtype, index))

identify(locus::AutoLocus, dimtype::Type, index) = Center()
identify(locus::Locus, dimtype::Type, index) = locus

identify(order::AutoOrder, dimtype::Type, index) = _orderof(index)
identify(order::Order, dimtype::Type, index) = order


_orderof(index::AbstractRange) =
    Ordered(index=_indexorder(index))
_orderof(index::AbstractArray) =
    try
        indord = _indexorder(index)
        sorted = issorted(index; rev=isrev(indord))
    catch
        sorted = false
    finally
        sorted ? Ordered(index=indord) : Unordered()
    end

_indexorder(index::AbstractArray) =
    first(index) <= last(index) ? Forward() : Reverse()
