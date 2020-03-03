"""
Traits for the order of the array, index and the relation between them.
"""
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

indexorder(order::Unordered) = Unordered()
arrayorder(order::Unordered) = Unordered()
relationorder(order::Unordered) = order.relation

struct UnknownOrder <: Order end

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
    error("No step provided by $T. Use a `RegularGrid` for $(basetypeof(grid))")

slicegrid(grid::Grid, index, I) = grid


struct NoGrid <: Grid end

"""
Unkwown grid type. Will be converted automatically to another
grid type when possible.
"""
struct UnknownGrid <: Grid end

order(g::UnknownGrid) = Unordered()


"""
A grid dimension whos index is aligned with the array,
and is independent of other grid dimensions.
"""
abstract type AlignedGrid{O} <: Grid end

order(g::AlignedGrid) = g.order

"""
[`AlignedGrid`](@ref)s trait for dimensions representing point samples.
"""
abstract type AbstractPointGrid{O<:Order} <: AlignedGrid{O} end

"""
An [`AlignedGrid`](@ref) grid for point samples.

`bounds` are the first and last points, one cell smaller than
the same index in an IntervalGrid.

## Fields
- `order::Order`: `Order` trait indicating array and index order
"""
struct PointGrid{O<:Order} <: AbstractPointGrid{O}
    order::O
end
PointGrid(; order=Ordered()) = PointGrid(order)

rebuild(g::AlignedGrid, order=order(g)) = PointGrid(order)


"""
[AlignedGrid](@ref)s traits for dimensions that represent intervals,
as opposed to single points.

These grids have a [`locus`](@ref) to indicate the position of the
in the interval relative to the index value.
"""
abstract type IntervalGrid{O,L} <: AlignedGrid{O} end

locus(grid::IntervalGrid) = grid.locus

"""
Abstract supertype for [`IntervalGrid`](@ref) traits with uneven or
unknown interval size. Bounds are tracked through changes
to the dimension so that the bounding box is always known.
"""
abstract type AbstractBoundedGrid{O<:Order,L<:Locus,B} <: IntervalGrid{O,L} end

"""
An [`IntervalGrid`](@ref) with irregular or unknown interval size, and tracked bounds.
These grids will generally be paired with a vector of coordinates along the
dimension, instead of a range. The interval covered by each cell is determined by
the cell position, and the last or next cell positing, depending on the [`Locus`](@ref).

As the size of the cells is not known, the bounds must be actively tracked.

## Fields
- `order::Order`: `Order` trait indicating array and index order
- `locus::Locus`: `Locus` trait indicating the position of the indexed point within the
  cell step
- `bounds`: the outer edges of the grid (different to the first and last coordinate).
"""
struct BoundedGrid{O<:Order,L<:Locus,B} <: AbstractBoundedGrid{O,L,B}
    order::O
    locus::L
    bounds::B
end
BoundedGrid(; order=Ordered(), locus=UnknownLocus(), bounds=nothing) =
    BoundedGrid(order, locus, bounds)

bounds(g::BoundedGrid) = g.bounds
bounds(g::BoundedGrid, dims) = bounds(g)

rebuild(g::BoundedGrid, order=order(g), locus=locus(g), bounds=bounds(g)) =
    BoundedGrid(order, locus, bounds)

# TODO: deal with unordered AbstractArray indexing
slicegrid(g::AbstractBoundedGrid, index, I) =
    rebuild(g, order(g), locus(g), slicebounds(g, index, I))

slicebounds(g::AbstractBoundedGrid, index, I) =
    slicebounds(locus(g), bounds(g), index, reorderindices(g, index, I))
slicebounds(loci::Start, bounds, index, I) =
    index[first(I)],
    last(I) >= lastindex(index)  ? bounds[2] : index[last(I) + 1]
slicebounds(loci::End, bounds, index, I) =
    first(I) <= firstindex(index) ? bounds[1] : index[first(I) - 1],
    index[last(I)]
slicebounds(loci::Center, bounds, index, I) =
    first(I) <= firstindex(index) ? bounds[1] : (index[first(I) - 1] + index[first(I)]) / 2,
    last(I)  >= lastindex(index)  ? bounds[2] : (index[last(I) + 1]  + index[last(I)]) / 2

reorderindices(grid::Grid, index, I) = reorderindices(relationorder(grid), index, I)
reorderindices(::Order, index, I) = I
reorderindices(::Reverse, index, I::AbstractArray) = length(index) .- (last(I), first(I)) .+ 1

"""
Abtract supertype for [IntervalGrid](@ref)s traits for dimensions
where the values are equal-sized intervals with a known step size.

These grids have a `step` value, which is the same as the range step except
for some legnth 1 ranges, and can also be used for evenly spaced vectors.
"""
abstract type AbstractRegularGrid{O<:Order,L<:Locus,S} <: IntervalGrid{O,L} end

Base.step(grid::AbstractRegularGrid) = grid.step

bounds(grid::AbstractRegularGrid, dim) =
    sortbounds(grid, bounds(relationorder(grid), locus(grid), grid, dim))
bounds(::Forward, ::Start, grid, dim) = first(dim), last(dim) + step(grid)
bounds(::Reverse, ::Start, grid, dim) = first(dim) - step(grid), last(dim)
bounds(::Any, ::Center, grid, dim) = first(dim) - step(grid) / 2, last(dim) + step(grid) / 2
bounds(::Forward, ::End, grid, dim) = first(dim) - step(grid), last(dim)
bounds(::Reverse, ::End, grid, dim) = first(dim), last(dim) + step(grid)

sortbounds(grid::Grid, bounds) = sortbounds(indexorder(grid), bounds)
sortbounds(grid::Forward, bounds) = bounds
sortbounds(grid::Reverse, bounds) = bounds[2], bounds[1]

"""
A concrete implementation of [`AbstractRegularGrid`](@ref) where all cells are
the same size and evenly spaced. These grids will often be paired with a range,
but may also be paired with a vector.

## Fields
- `order::Order`: `Order` trait indicating array and index order
- `locus::Locus`: `Locus` trait indicating the position of the indexed
  point within the cell step
- `step::Number`: the size of a grid step, such as 1u"km" or `Month(1)`
"""
struct RegularGrid{O<:Order,L<:Locus,S} <: AbstractRegularGrid{O,L,S}
    order::O
    locus::L
    step::S
end
RegularGrid(; order=Ordered(), locus=UnknownLocus(), step=nothing) =
    RegularGrid(order, locus, step)

rebuild(g::RegularGrid, order=order(g), locus=locus(g), step=step(g)) =
    RegularGrid(order, locus, step)


"""
[Grid](@ref)s traits for dimensions where the values are categories.
"""
abstract type AbstractCategoricalGrid{O} <: AlignedGrid{O} end

order(g::AbstractCategoricalGrid) = g.order
rebuild(g::AbstractCategoricalGrid, order=order(g)) = CategoricalGrid(order)
bounds(grid::AbstractCategoricalGrid, dim) = bounds(indexorder(grid), grid, dim)

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
identify(grid::Grid, dimtype, index) = grid
identify(gridtype::Type{<:Grid}, dimtype, index) = gridtype()

identify(locus::UnknownLocus, dimtype, index) = Center()
identify(locus::Locus, dimtype, index) = locus
identify(order::UnknownOrder, dimtype, index) = _orderof(index)
identify(order::Order, dimtype, index) = order

identify(grid::AbstractRegularGrid, dimtype, index::AbstractRange) = begin
    grid = rebuild(grid; 
        order=identify(order(grid), dimtype, index),
        locus=identify(locus(grid), dimtype, index),
    )
    identify(step(grid), grid, dimtype, index)
end
identify(step_::Nothing, grid::AbstractRegularGrid, dimtype, index::AbstractRange) =
    rebuild(grid; step=step(index))
identify(step_::Nothing, grid::AbstractRegularGrid, dimtype, index::AbstractArray) =
    throw(ArgumentError("Assign the step keyword for the grid with AbstractArray index"))
identify(step_, grid::AbstractRegularGrid, dimtype, index) = begin
    step_ == step(grid) || throw(ArgumentError("grid step $step_ does not match index step $(step(val(index)))"))
    grid
end
identify(grid::BoundedGrid, dimtype, index) = begin
    grid = rebuild(grid; locus=identify(locus(grid), dimtype, index))
    identify(bounds(grid), grid, dimtype, index)
end

identify(bounds_::Nothing, grid::AbstractBoundedGrid, dimtype, index) = begin
    if length(index) > 2 # Not type-stable
        bounds_ = sortbounds(index[1] - (index[2] - index[1]) / 2,
                             index[end] + (index[end] - index[end-1]) / 2)
    end
    rebuild(grid; bounds=bounds_)
end
identify(bounds_, grid::AbstractBoundedGrid, dimtype, index) = begin
    bounds_ == bounds(grid) || throw(ArgumentError("grid bounds $bounds_ does not match index bounds $(bounds(grid))"))
    grid
end

identify(::UnknownGrid, dimtype, index::AbstractArray) =
    PointGrid(; order=_orderof(index))
identify(::UnknownGrid, dimtype, index::AbstractArray{<:Union{Symbol,String}}) =
    CategoricalGrid(; order=_orderof(index))

_orderof(index::AbstractArray) = begin
    indord = _indexorder(index)
    sorted = issorted(index; rev=isrev(indord))
    order = sorted ? Ordered(; index=indord) : Unordered()
end

_indexorder(index::AbstractArray) =
    first(index) <= last(index) ? Forward() : Reverse()
