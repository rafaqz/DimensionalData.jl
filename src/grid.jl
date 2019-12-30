abstract type Order end

"""
Trait container for dimension and array ordering in AlignedGrid.

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

indexorder(order::Unordered) = order
arrayorder(order::Unordered) = order
relationorder(order::Unordered) = order.relation

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
# Base.reverse(o::Ordered) =
    # Ordered(indexorder(o), reverse(relationorder(o)), reverse(arrayorder(o)))
# Base.reverse(o::Unordered) =
    # Unordered(reverse(relationorder(o)))

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
Indicates wether the cell value is specific to the locus point
or is related to the whole of the step.

The step may contain a value if the distance between locii if known.
This will often be identical to the distance between any two sequential
cell values, but may be distinct due to rounding errors in a vector index,
or context-dependent step such as `Month`.
"""
abstract type Sampling end

"""
Each cell value represents a siegle discrete sample taken at the index location.
"""
struct SingleSample <: Sampling end

"""
Multiple samples from the step combined using method `M`,
where `M` is `typeof(mean)`, `typeof(sum)` etc.
"""
struct MultiSample{M} <: Sampling end
MultiSample() = MultiSample{Nothing}()

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

bounds(grid::Grid, dim) = bounds(indexorder(grid), grid, dim)
bounds(::Forward, grid, dim) = first(dim), last(dim)
bounds(::Reverse, grid, dim) = last(dim), first(dim)
bounds(::Unordered, grid, dim) = error("Cannot call `bounds` on an unordered grid")

dims(g::Grid) = nothing
order(g::Grid) = Unordered()
arrayorder(grid::Grid) = arrayorder(order(grid))
indexorder(grid::Grid) = indexorder(order(grid))
relationorder(grid::Grid) = relationorder(order(grid))

Base.reverse(g::Grid) = rebuild(g, reverse(order(g)))
reversearray(g::Grid) = rebuild(g, reversearray(order(g)))
reverseindex(g::Grid) = rebuild(g, reverseindex(order(g)))

Base.step(grid::T) where T <: Grid = 
    error("No step provided by $T. Use a `RegularGrid` for $(basetypeof(dim))")

slicegrid(grid::Grid, index, I) = grid

struct NoGrid <: Grid end


"""
Fallback grid type
"""
struct UnknownGrid <: Grid end

"""
A grid dimension that is independent of other grid dimensions.
"""
abstract type IndependentGrid{O} <: Grid end

"""
A grid dimension aligned exactly with a standard dimension, such as lattitude or longitude.
"""
abstract type AbstractAlignedGrid{O,L,Sa} <: IndependentGrid{O} end

order(g::AbstractAlignedGrid) = g.order
locus(g::AbstractAlignedGrid) = g.locus
sampling(g::AbstractAlignedGrid) = g.sampling

"""
An [`AlignedGrid`](@ref) grid without known regular spacing. These grids will generally be paired
with a vector of coordinates along the dimension, instead of a range.

Bounds are given as the first and last points, which omits the step of one cell, 
as it is not known. To fix this use either a [`BoundedGrid`](@ref) with specified 
starting bounds or a [`RegularGrid`](@ref) with a known constand cell step.

## Fields
- `order::Order`: `Order` trait indicating array and index order
- `locus::Locus`: `Locus` trait indicating the position of the indexed point within the cell step
- `sampling::Sampling`: `Sampling` trait indicating wether the grid cells are single samples or means
"""
struct AlignedGrid{O<:Order,L<:Locus,Sa<:Sampling} <: AbstractAlignedGrid{O,L,Sa}
    order::O
    locus::L
    sampling::Sa
end
AlignedGrid(; order=Ordered(), locus=Start(), sampling=UnknownSampling()) =
    AlignedGrid(order, locus, sampling)

rebuild(g::AlignedGrid, order=order(g), locus=locus(g), sampling=sampling(g)) =
    AlignedGrid(order, locus, sampling)

"""
An alligned grid without known regular spacing and tracked bounds.
These grids will generally be paired with a vector of coordinates along the
dimension, instead of a range.

As the size of the cells is not known, the bounds must be actively tracked.

## Fields
- `order::Order`: `Order` trait indicating array and index order
- `locus::Locus`: `Locus` trait indicating the position of the indexed point within the cell step
- `sampling::Sampling`: `Sampling` trait indicating wether the grid cells are single samples or means
- `bounds`: the outer edges of the grid (different to the first and last coordinate).
"""
struct BoundedGrid{O<:Order,L<:Locus,Sa<:Sampling,B} <: AbstractAlignedGrid{O,L,Sa}
    order::O
    locus::L
    sampling::Sa
    bounds::B
end
BoundedGrid(; order=Ordered(), locus=Start(), sampling=UnknownSampling(), bounds=nothing) =
    BoundedGrid(order, locus, sampling, bounds)

bounds(g::BoundedGrid) = g.bounds

rebuild(g::BoundedGrid, order=order(g), locus=locus(g), sampling=sampling(g), bounds=bounds(g)) =
    BoundedGrid(order, locus, sampling, bounds)

# TODO: deal with unordered AbstractArray
slicegrid(g::BoundedGrid, index, I) =
    rebuild(g, order(g), locus(g), sampling(g), slicebounds(locus(g), bounds(g), index, I))

slicebounds(loci::Start, bounds, index, I) =
    index[first(I)], 
    last(I) >= lastindex(index)  ? bounds[2] : index[last(I) + 1]
slicebounds(loci::End, bounds, index, I) =
    first(I) <= firstindex(index) ? bounds[1] : index[first(I) - 1],  
    index[last(I)]
slicebounds(loci::Center, bounds, index, I) =
    first(I) <= firstindex(index) ? bounds[1] : (index[first(I) - 1]   + index[first(I)]) / 2,
    last(I)  >= lastindex(index)  ? bounds[2] : (index[last(I) + 1] + index[last(I)]) / 2


abstract type AbstractRegularGrid{O,L,Sa,St} <: AbstractAlignedGrid{O,L,Sa} end

"""
An [`AlignedGrid`](@ref) where all cells are the same size and evenly spaced.

## Fields
- `order::Order`: `Order` trait indicating array and index order
- `locus::Locus`: `Locus` trait indicating the position of the indexed point within the cell step
- `sampling::Sampling`: `Sampling` trait indicating wether the grid cells are single samples or means
- `step::Number`: the size of a grid step, such as 1u"km" or `Month(1)`
"""
struct RegularGrid{O<:Order,L<:Locus,Sa<:Sampling,St} <: AbstractRegularGrid{O,L,Sa,St}
    order::O
    locus::L
    sampling::Sa
    step::St
end
RegularGrid(; order=Ordered(), locus=Start(), sampling=UnknownSampling(), step=nothing) =
    RegularGrid(order, locus, sampling, step)

rebuild(g::RegularGrid, order=order(g), locus=locus(g), sampling=sampling(g), step=step(g)) =
    RegularGrid(order, locus, sampling, step)

bounds(grid::RegularGrid, dim) = bounds(indexorder(grid), locus(grid), grid, dim)
bounds(::Forward, ::Start, grid, dim) = first(dim), last(dim) + step(grid)
bounds(::Reverse, ::Start, grid, dim) = last(dim), first(dim) + step(grid)
bounds(::Forward, ::Center, grid, dim) = first(dim) - step(grid) / 2, last(dim) + step(grid) / 2
bounds(::Reverse, ::Center, grid, dim) = last(dim) - step(grid) / 2, first(dim) + step(grid) / 2
bounds(::Forward, ::End, grid, dim) = first(dim) - step(grid), last(dim)
bounds(::Reverse, ::End, grid, dim) = last(dim) - step(grid), first(dim)

Base.step(grid::RegularGrid) = grid.step


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

rebuild(g::CategoricalGrid, order=order(g)) = CategoricalGrid(order)

bounds(grid::CategoricalGrid, dim) = bounds(indexorder(grid), grid, dim)



"""
Traits describing a grid dimension that is dependent on other grid dimensions.

Indexing into a dependent dimension must provide all other dependent dimensions.
"""
abstract type DependentGrid <: Grid end

locus(g::DependentGrid) = g.locus
dims(g::DependentGrid) = g.dims
sampling(g::DependentGrid) = g.sampling

"""
Grid type using an affine transformation to convert dimension from
`dim(grid)` to `dims(array)`.

## Fields
- `dims`: a tuple containing dimenension types or symbols matching the order
          needed by the transform function.
- `sampling`: a `Sampling` trait indicating wether the grid cells are sampled points or means
"""
struct TransformedGrid{D,L,Sa<:Sampling} <: DependentGrid
    dims::D
    locus::L
    sampling::Sa
end
TransformedGrid(dims=(), locus=Start(), sampling=UnknownSampling()) =
    TransformedGrid(dims, locus, sampling)

rebuild(g::TransformedGrid, dims=dims(g), locus=locus(g), sampling=sampling(g)) =
    TransformedGrid(dims, locus, sampling)

"""
A grid dimension that uses an array lookup to convert dimension from
`dim(grid)` to `dims(array)`.

## Fields
- `dims`: a tuple containing dimenension types or symbols matching the order
          needed to index the lookup matrix.
- `sampling`: a `Sampling` trait indicating wether the grid cells are sampled points or means
"""
struct LookupGrid{D,L,Sa<:Sampling} <: DependentGrid
    dims::D
    locus::L
    sampling::Sa
end
LookupGrid(dims=(), locus=Start(), sampling=UnknownSampling()) =
    LookupGrid(dims, locus, sampling)

rebuild(g::LookupGrid; dims=dims(g), locus=locus(g), sampling=sampling(g)) =
    LookupGrid(dims, locus, sampling)
