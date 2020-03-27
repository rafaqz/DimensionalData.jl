"""
Traits for the order of the array, index and the relation between them.
"""
abstract type Order end

"""
Trait container for dimension and array ordering.

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

struct UnknownOrder <: Order end

struct AutoOrder <: Order end

"""
Trait indicating that the array or dimension is in the normal forward order.
"""
struct Forward <: Order end

"""
Trait indicating that the array or dimension is in the reverse order.
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
Locii indicate the position of index values in grid cells.

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
struct UnknownLocus <: Locus end


"""
Traits for the sampling method referenced by the index.
"""
abstract type Sampling end

"""
Single samples at exact points
"""
struct PointSampling <: Sampling end

locus(sampling::PointSampling) = Center()

"""
Mean (or similar) of samples over an interval
"""
struct IntervalSampling{L} <: Sampling
    locus::L
end
IntervalSampling() = IntervalSampling(UnknownLocus())
rebuild(::IntervalSampling, locus) = IntervalSampling(locus)

locus(sampling::IntervalSampling) = sampling.locus


"""
Traits defining the type of step used in the dimension index.
"""
abstract type Span end

"""
Spans have regular size. This is passed to the constructor,
although these are normally build automatically.
"""
struct RegularSpan{S} <: Span
    step::S
end
RegularSpan() = RegularSpan(nothing)

Base.step(span::RegularSpan) = span.step

val(span::RegularSpan) = span.step

"""
Spans have irrigular size. To enable bounds tracking and accuract
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
Unknown span. Will be guessed and replaced by a constructor.
"""
struct UnknownSpan <: Span end



"""
Traits describing the grid type of a dimension.
"""
abstract type Grid end

bounds(grid::Grid, dim) = bounds(indexorder(grid), grid, dim)
bounds(::Forward, grid, dim) = first(dim), last(dim)
bounds(::Reverse, grid, dim) = last(dim), first(dim)
bounds(::Unordered, grid, dim) = error("Cannot call `bounds` on an unordered grid")

dims(g::Grid) = nothing
order(g::Grid) = Unordered()
arrayorder(grid::Grid) = arrayorder(order(grid))
indexorder(grid::Grid) = indexorder(order(grid))
relationorder(grid::Grid) = relationorder(order(grid))

reversearray(g::Grid) = rebuild(g, reversearray(order(g)))
reverseindex(g::Grid) = rebuild(g, reverseindex(order(g)))

Base.step(grid::T) where T <: Grid =
    error("No step provided by $T. Use a `SampledGrid` with `RegularSpan`")

slicegrid(grid::Grid, index, I) = grid


struct NoGrid <: Grid end

"""
Unkwown grid type. Will be converted automatically to another
grid type when possible.
"""
struct UnknownGrid{O<:Order} <: Grid
    order::O
end
UnknownGrid() = UnknownGrid(UnknownOrder())

order(g::UnknownGrid) = g.order

abstract type AlignedGrid{O} <: Grid end

order(g::AlignedGrid) = g.order

"""
A grid dimension whos index is aligned with the array,
and is independent of other grid dimensions.
"""
abstract type AbstractSampledGrid{O,Sp,Sa} <: AlignedGrid{O} end

span(grid::AbstractSampledGrid) = grid.span
sampling(grid::AbstractSampledGrid) = grid.sampling
locus(grid::AbstractSampledGrid) = locus(sampling(grid))

Base.step(grid::AbstractSampledGrid) = step(span(grid))

bounds(grid::AbstractSampledGrid, dim) =
    bounds(sampling(grid), span(grid), grid, dim)

bounds(::PointSampling, span, grid::AbstractSampledGrid, dim) =
    bounds(indexorder(grid), grid, dim)

bounds(::IntervalSampling, span::IrregularSpan, grid::AbstractSampledGrid, dim) =
    bounds(span)

bounds(s::IntervalSampling, span::RegularSpan, g::AbstractSampledGrid, dim) =
    bounds(locus(s), indexorder(g), span, g, dim)

bounds(::Start, ::Forward, span, grid, dim) = first(dim), last(dim) + step(span)
bounds(::Start, ::Reverse, span, grid, dim) = last(dim), first(dim) - step(span)
bounds(::Center, ::Forward, span, grid, dim) = first(dim) - step(span) / 2, last(dim) + step(span) / 2
bounds(::Center, ::Reverse, span, grid, dim) = last(dim) + step(span) / 2, first(dim) - step(span) / 2
bounds(::End, ::Forward, span, grid, dim) = first(dim) - step(span), last(dim)
bounds(::End, ::Reverse, span, grid, dim) = last(dim) + step(span), first(dim)


sortbounds(grid::Grid, bounds) = sortbounds(indexorder(grid), bounds)
sortbounds(grid::Forward, bounds) = bounds
sortbounds(grid::Reverse, bounds) = bounds[2], bounds[1]


# TODO: deal with unordered AbstractArray indexing
slicegrid(g::AbstractSampledGrid, index, I) =
    slicegrid(sampling(g), span(g), g, index, I)
slicegrid(::Any, ::Any, g::AbstractSampledGrid, index, I) = g
slicegrid(::IntervalSampling, ::IrregularSpan, g::AbstractSampledGrid, index, I) = begin
    span = IrregularSpan(slicebounds(g, index, I))
    rebuild(g, order(g), span, sampling(g))
end

slicebounds(g, index, I) =
    slicebounds(locus(g), bounds(span(g)),  index, maybeflip(indexorder(g), index, I))
slicebounds(locus::Start, bounds, index, I) =
    index[first(I)], last(I) >= lastindex(index) ? bounds[2] : index[last(I) + 1]
slicebounds(locus::End, bounds, index, I) =
    first(I) <= firstindex(index) ? bounds[1] : index[first(I) - 1], index[last(I)]
slicebounds(locus::Center, bounds, index, I) =
    first(I) <= firstindex(index) ? bounds[1] : (index[first(I) - 1] + index[first(I)]) / 2,
    last(I)  >= lastindex(index)  ? bounds[2] : (index[last(I) + 1]  + index[last(I)]) / 2


"""
A concrete implementation of [`AbstractSampledGrid`](@ref) where all cells are
the same size and evenly spaced. These grids will often be paired with a range,
but may also be paired with a vector.

## Fields
- `order::Order`: `Order` trait indicating array and index order
- `locus::Locus`: `Locus` trait indicating the position of the indexed
  point within the cell step
- `step::Number`: the size of a grid step, such as 1u"km" or `Month(1)`
"""
struct SampledGrid{O<:Order,Sp<:Span,Sa<:Sampling} <: AbstractSampledGrid{O,Sp,Sa}
    order::O
    span::Sp
    sampling::Sa
end
SampledGrid(; order=Ordered(), span=UnknownSpan(), sampling=PointSampling()) =
    SampledGrid(order, span, sampling)

rebuild(g::SampledGrid, order=order(g), span=span(g), sampling=sampling(g)) =
    SampledGrid(order, span, sampling)


"""
[Grid](@ref)s traits for dimensions where the values are categories.
"""
abstract type AbstractCategoricalGrid{O} <: AlignedGrid{O} end

order(g::AbstractCategoricalGrid) = g.order
rebuild(g::AbstractCategoricalGrid, order=order(g)) = CategoricalGrid(order)

"""
A grid dimension where the values are categories.

## Fields
- `order`: `Order` trait indicating array and index order
"""
struct CategoricalGrid{O<:Order} <: AbstractCategoricalGrid{O}
    order::O
end
CategoricalGrid(; order=Ordered()) = CategoricalGrid(order)



"""
Abtract supertype for [Grid](@ref) traits describing a grid dimension that is
dependent on other grid dimensions.

Indexing into a dependent dimension must provide all other dependent dimensions.
"""
abstract type UnalignedGrid <: Grid end

locus(g::UnalignedGrid) = g.locus
dims(g::UnalignedGrid) = g.dims

"""
Grid trait that uses an affine transformation to convert dimensions from
`dims(grid)` to `dims(array)`.

## Fields
- `dims`: a tuple containing dimenension types or symbols matching the
  order needed by the transform function.
"""
struct TransformedGrid{D,L} <: UnalignedGrid
    dims::D
    locus::L
end
TransformedGrid(dims; locus=Start()) = TransformedGrid(dims, locus)

rebuild(g::TransformedGrid, dims=dims(g), locus=locus(g) ) =
    TransformedGrid(dims, locus)

# TODO bounds

# """
# A grid dimension that uses an array lookup to convert dimension from
# `dim(grid)` to `dims(array)`.

# ## Fields
# - `dims`: a tuple containing dimenension types or symbols matching the order
          # needed to index the lookup matrix.
# """
# struct LookupGrid{D,L} <: UnalignedGrid
    # dims::D
    # locus::L
# end
# LookupGrid(dims=(), locus=Start())) =
    # LookupGrid(dims, locus)

# rebuild(g::LookupGrid; dims=dims(g), locus=locus(g)) =
    # LookupGrid(dims, locus)


"""
    identify(::Grid, index)

Identify grid type from index content.
"""
identify(gridtype::Type{<:Grid}, dimtype::Type, index) =
    identify(gridtype(), dimtype, index)
identify(grid::Grid, dimtype::Type, index) = grid

identify(grid::UnknownGrid, dimtype::Type, index::AbstractArray) =
    identify(SampledGrid(), dimtype, index)
identify(grid::UnknownGrid, dimtype::Type, index::AbstractArray{<:Union{AbstractChar,Symbol,AbstractString}}) =
    CategoricalGrid()
identify(grid::CategoricalGrid, dimtype::Type, index) = grid

identify(grid::AbstractSampledGrid, dimtype::Type, index::AbstractArray) = begin
    grid = rebuild(grid,
        identify(order(grid), dimtype, index),
        identify(span(grid), dimtype, index),
        identify(sampling(grid), dimtype, index),
    )
end

identify(span::UnknownSpan, dimtype::Type, index::AbstractArray) =
    IrregularSpan()
identify(span::UnknownSpan, dimtype::Type, index::AbstractRange) =
    RegularSpan(step(index))

identify(span::RegularSpan, dimtype::Type, index::AbstractArray) =
    span
identify(span::RegularSpan, dimtype::Type, index::AbstractRange) = begin
    step(span) == step(index) || throw(ArgumentError("grid step $(step(span)) does not match index step $(step(index))"))
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

identify(locus::UnknownLocus, dimtype::Type, index) = Center()
identify(locus::Locus, dimtype::Type, index) = locus

identify(order::UnknownOrder, dimtype::Type, index) = Ordered()
identify(order::AutoOrder, dimtype::Type, index) = _orderof(index)
identify(order::Order, dimtype::Type, index) = order


_orderof(index::AbstractArray) = begin
    indord = _indexorder(index)
    sorted = issorted(index; rev=isrev(indord))
    order = sorted ? Ordered(; index=indord) : Unordered()
end

_indexorder(index::AbstractArray) =
    first(index) <= last(index) ? Forward() : Reverse()
