abstract type Order end

"""
Trait container for dimension and array ordering in AllignedGrid.

The default is `Ordered(Forward()`, `Forward())`

All combinations of forward and reverse order for data and indices seem to occurr
in real datasets, as strange as that seems. We cover these possibilities by specifying
the order of both explicitly.

Knowing the order of indices is important for using methods like `searchsortedfirst()`
to find indices in sorted lists of values. Knowing the order of the data is then
required to map to the actual indices. It's also used to plot the data later - which
always happens in smallest to largest order.

Base also defines Forward and Reverse, but they seem overly complicated for our purposes.
"""
struct Ordered{D,A} <: Order
    index::D
    array::A
end
Ordered() = Ordered(Forward(), Forward())

"""
Trait indicating that the array or dimension has no order.
"""
struct Unordered <: Order end

indexorder(order::Ordered) = order.index
indexorder(order::Unordered) = Unordered()
arrayorder(order::Ordered) = order.array
arrayorder(order::Unordered) = Unordered()

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
Base.reverse(o::Ordered) = Ordered(reverse(indexorder(o)), reverse(arrayorder(o)))
Base.reverse(::Unordered) = Unordered()

reverseindex(o::Unordered) = Unordered()
reverseindex(o::Ordered) = Ordered(reverse(indexorder(o)), arrayorder(o))

reversearray(o::Unordered) = Unordered()
reversearray(o::Ordered) = Ordered(indexorder(o), reverse(arrayorder(o)))


"""
Indicates wether the cell value is specific to the locus point
or is related to the whole the span.

The span may contain a value if the distance between locii if known.
This will often be identical to the distance between any two sequential
cell values, but may be distinct due to rounding errors in a vector index,
or context-dependent spans such as `Month`.
"""
abstract type Sampling end

"""
Each cell value represents a single discrete sample taken at the index location.
"""
struct SingleSample <: Sampling end

"""
Multiple samples from the span combined using method `M`, 
where `M` is `typeof(mean)`, `typeof(sum)` etc.
"""
struct MultiSample{M} <: Sampling end

"""
The sampling method is unknown.
"""
struct UnknownSampling <: Sampling end

"""
Indicate the position of index values in grid cells.

This is frequently `Start` for time series, but may be `Center`
for spatial data.
"""
abstract type Locus end

"""
Indicates dimensions that are defined by their center coordinates/time/position.
"""
struct Center <: Locus end

"""
Indicates dimensions that are defined by their start coordinates/time/position.
"""
struct Start <: Locus end

"""
Indicates dimensions that are defined by their end coordinates/time/position.
"""
struct End <: Locus end

struct UnknownLocus <: Locus end



"""
Traits describing the grid type of a dimension.
"""
abstract type Grid end

dims(g::Grid) = nothing
locus(g::Grid) = g.locus
arrayorder(grid::Grid) = arrayorder(order(grid))
indexorder(grid::Grid) = indexorder(order(grid))

"""
Fallback grid type
"""
struct UnknownGrid <: Grid end

order(::UnknownGrid) = Unordered()

"""
A grid dimension that is independent of other grid dimensions.
"""
abstract type IndependentGrid{O} <: Grid end

"""
A grid dimension aligned exactly with a standard dimension, such as lattitude or longitude.
"""
abstract type AbstractAllignedGrid{O} <: IndependentGrid{O} end

Base.reverse(g::AbstractAllignedGrid) = rebuild(g; order=reverse(order(g)))
reversearray(g::AbstractAllignedGrid) = rebuild(g; order=reversearray(order(g)))
reverseindex(g::AbstractAllignedGrid) = rebuild(g; order=reverseindex(order(g)))

order(g::AbstractAllignedGrid) = g.order
sampling(g::AbstractAllignedGrid) = g.sampling

"""
An alligned grid without known regular spacing. These grids will generally be paired
with a vector of coordinates along the dimension, instead of a range.

As the size of the cells is not known, the bounds must be actively tracked.

## Fields
- `order`: `Order` trait indicating array and index order
- `locus`: `Locus` trait indicating the position of the indexed point within the cell span
- `sampling`: `Sampling` trait indicating wether the grid cells are single samples or means
- `bounds`: the outer edges of the grid (different to the first and last coordinate).
"""
struct AllignedGrid{O<:Order,L<:Locus,Sa<:Sampling,B} <: AbstractAllignedGrid{O}
    order::O
    locus::L
    sampling::Sa
    bounds::B
end
AllignedGrid(; order=Ordered(), locus=Center(), sampling=UnknownSampling(), bounds=error("must supply bounds") =
    AllignedGrid(order, locus, sampling, bounds)

bounds(g::AllignedGrid) = g.bounds

rebuild(g::AllignedGrid; 
        order=order(g), locus=locus(g), sampling=sampling(g), bounds=bounds(g)) =
    AllignedGrid(order, locus, sampling, bounds)

"""
An alligned grid known to have equal spacing between all cells.

## Fields
- `order`: `Order` trait indicating array and index order
- `locus`: `Locus` trait indicating the position of the indexed point within the cell span
- `sampling`: `Sampling` trait indicating wether the grid cells are single samples or means
- `span`: the size of a grid step, such as 1u"km" or `Month(1)`
"""
struct RegularGrid{O<:Order,L<:Locus,Sp,Sa<:Sampling} <: AbstractAllignedGrid{O}
    order::O
    locus::L
    sampling::Sa
    span::Sp
end
RegularGrid(; order=Ordered(), locus=Center(), sampling=UnknownSampling(), span=nothing) =
    RegularGrid(order, locus, sampling, span)

span(g::RegularGrid) = g.span

rebuild(g::RegularGrid; 
        order=order(g), locus=locus(g), sampling=sampling(g), span=span(g)) =
    RegularGrid(order, locus, sampling, span)


abstract type AbstractCategoricalGrid{O} <: IndependentGrid{O} end

"""
A grid dimension where the values are categories.

## Fields
- `order`: `Order` trait indicating array and index order
"""
struct CategoricalGrid{O<:Order} <: AbstractCategoricalGrid{O}
    order::O
end
CategoricalGrid(; order=Ordered()) = CategoricalGrid(order)

order(g::CategoricalGrid) = g.order

rebuild(g::CategoricalGrid; order=order(g)) = CategoricalGrid(order)



"""
Traits describing a grid dimension that is dependent on other grid dimensions.

Indexing into a dependent dimension must provide all other dependent dimensions.
"""
abstract type DependentGrid <: Grid end

"""
Grid type using an affine transformation to convert dimension from
`dim(grid)` to `dims(array)`.

## Fields
- `dims`: a tuple containing dimenension types or symbols matching the order
          needed by the transform function.
- `sampling`: a `Sampling` trait indicating wether the grid cells are sampled points or means
"""
struct TransformedGrid{D,Sa<:Sampling} <: DependentGrid
    dims::D
    locus::L
    sampling::Sa
end
TransformedGrid(dims=(), locus=Center(), sampling=UnknownSampling()) = TransformedGrid(dims, sampling)

dims(g::TransformedGrid) = g.dims
sampling(g::TransformedGrid) = g.sampling

rebuild(g::TransformedGrid; dims=dims(g), locus=locus(g), sampling=sampling(g)) = 
    CategoricalGrid(dims, locus, sampling)

"""
A grid dimension that uses an array lookup to convert dimension from
`dim(grid)` to `dims(array)`.

## Fields
- `dims`: a tuple containing dimenension types or symbols matching the order
          needed to index the lookup matrix.
- `sampling`: a `Sampling` trait indicating wether the grid cells are sampled points or means
"""
struct LookupGrid{D,Sa<:Sampling} <: DependentGrid
    dims::D
    locus::L
    sampling::Sa
end
LookupGrid(dims=(), sampling=UnknownSampling()) = LookupGrid(dims, sampling)

dims(g::LookupGrid) = g.dims
sampling(g::LookupGrid) = g.sampling

rebuild(g::LookupGrid; dims=dims(g), locus=locus(g), sampling=sampling(g)) = 
    CategoricalGrid(dims, locus, sampling)
