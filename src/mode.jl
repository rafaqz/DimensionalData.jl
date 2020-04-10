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
Traits describing the mode of a dimension.
"""
abstract type IndexMode end

bounds(mode::IndexMode, dim) = bounds(indexorder(mode), mode, dim)
bounds(::Forward, mode, dim) = first(dim), last(dim)
bounds(::Reverse, mode, dim) = last(dim), first(dim)
bounds(::Unordered, mode, dim) = error("Cannot call `bounds` on an unordered mode")

dims(mode::IndexMode) = nothing
order(mode::IndexMode) = Unordered()
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
`IndexMode` that is identical to the array axis.
"""
struct NoIndex <: IndexMode end

order(mode::NoIndex) = Ordered(Forward(), Forward(), Forward())

"""
Automatic [`IndexMode`](@ref). Will be converted automatically to another
`IndexMode` when possible.
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
An [`IndexMode`](@ref) whos index is aligned with the array,
and is independent of other dimensions.
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
A concrete implementation of [`AbstractSampled`](@ref).
Can be used to represent points or intervals, with `sampling`
of [`Points`](@ref) or [`Intervals`](@ref).

## Fields
- `order`: [`Order`](@ref) indicating array and index order
- `span::Span`: [`Span`](@ref) indicating [`Regular`](@ref) or [`Irregular`](@ref)
  size of intervals or distance between points
- `sampling::Sampling`: [`Sampling`](@ref) of `Intervals` or `Points` (the default)
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
"""
abstract type AbstractCategorical{O} <: Aligned{O} end

order(mode::AbstractCategorical) = mode.order

"""
An IndexMode where the values are categories.

## Fields
- `order`: [`Order`](@ref) indicating array and index order.

`Order` will not be determined automatically for `Categorical`,
it instead defaults to `Unordered()`
"""
struct Categorical{O<:Order} <: AbstractCategorical{O}
    order::O
end
Categorical(; order=Unordered()) = Categorical(order)

rebuild(mode::Categorical, order) = Categorical(order)


"""
Supertype for [`IndexMode`](@ref) where the `Dimension` index is not aligned to the grid.

Indexing with an `Unaligned` dimension must provide all other `Unaligned` dimensions.
"""
abstract type Unaligned <: IndexMode end

locus(mode::Unaligned) = mode.locus
dims(mode::Unaligned) = mode.dims

"""
[`IndexMode`](@ref) that uses an affine transformation to convert
dimensions from `dims(mode)` to `dims(array)`.

## Fields
- `dims`: a tuple containing dimenension types or symbols matching the
  order needed by the transform function.
"""
struct Transformed{D,L} <: Unaligned
    dims::D
    locus::L
end
Transformed(dims; locus=Start()) = Transformed(dims, locus)

rebuild(mode::Transformed, dims=dims(m), locus=locus(m) ) =
    Transformed(dims, locus)

# TODO bounds

# """
# An IndexMode that uses an array lookup to convert dimension from
# `dim(mode)` to `dims(array)`.

# ## Fields
# - `dims`: a tuple containing dimenension types or symbols matching the order
          # needed to index the lookup matrix.
# """
# struct LookupIndex{D,L} <: Unaligned
    # dims::D
    # locus::L
# end
# LookupIndex(dims=(), locus=Start())) =
    # LookupIndex(dims, locus)

# rebuild(mode::LookupIndex; dims=dims(m), locus=locus(m)) =
    # LookupIndex(dims, locus)

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
