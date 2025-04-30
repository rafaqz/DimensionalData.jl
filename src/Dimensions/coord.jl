struct CoordLookup{T,A<:AbstractVector{T},D,Me} <: MultiDimensionalLookup{T}
    data::A
    dims::D
    metadata::Me
end
CoordLookup(data, dims; metadata=NoMetadata()) = CoordLookup(data, dims, metadata)
hasmultipledimensions(::CoordLookup) = true

dims(m::CoordLookup) = m.dims
order(m::CoordLookup) = Unordered()

"""
    Coord <: Dimension

A coordinate dimension itself holds dimensions.

This allows combining point data with other dimensions, such as time.

# Example

```jldoctest
julia> using DimensionalData

julia> dim = Coord([(1.0,1.0,1.0), (1.0,2.0,2.0), (3.0,4.0,4.0), (1.0,3.0,4.0)], (X(), Y(), Z()))
Coord MergedLookup{Tuple{Float64, Float64, Float64}} ↓ X, → Y, ↗ Z
wrapping: 4-element Vector{Tuple{Float64, Float64, Float64}}:
 (1.0, 1.0, 1.0)
 (1.0, 2.0, 2.0)
 (3.0, 4.0, 4.0)
 (1.0, 3.0, 4.0)

julia> da = DimArray(0.1:0.1:0.4, dim)
╭───────────────────────────────╮
│ 4-element DimArray{Float64,1} │
├───────────────────────────────┴───────────────────────────────────────────────────────────────────────────────────────────────────── dims ┐
  ↓ Coord MergedLookup{Tuple{Float64, Float64, Float64}} [(1.0, 1.0, 1.0), (1.0, 2.0, 2.0), (3.0, 4.0, 4.0), (1.0, 3.0, 4.0)] ↓ X, → Y, ↗ Z
└───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
 (1.0, 1.0, 1.0)  0.1
 (1.0, 2.0, 2.0)  0.2
 (3.0, 4.0, 4.0)  0.3
 (1.0, 3.0, 4.0)  0.4

julia> da[Coord(Z(At(1.0)), Y(Between(1, 3)))]
╭───────────────────────────────╮
│ 1-element DimArray{Float64,1} │
├───────────────────────────────┴────────────────────────────────────────────────── dims ┐
  ↓ Coord MergedLookup{Tuple{Float64, Float64, Float64}} [(1.0, 1.0, 1.0)] ↓ X, → Y, ↗ Z
└────────────────────────────────────────────────────────────────────────────────────────┘
 (1.0, 1.0, 1.0)  0.1

julia> da[Coord(4)] == 0.4
true

julia> da[Coord(Between(1, 5), :, At(4.0))]
╭───────────────────────────────╮
│ 2-element DimArray{Float64,1} │
├───────────────────────────────┴─────────────────────────────────────────────────────────────────── dims ┐
  ↓ Coord MergedLookup{Tuple{Float64, Float64, Float64}} [(3.0, 4.0, 4.0), (1.0, 3.0, 4.0)] ↓ X, → Y, ↗ Z
└─────────────────────────────────────────────────────────────────────────────────────────────────────────┘
 (3.0, 4.0, 4.0)  0.3
 (1.0, 3.0, 4.0)  0.4
```
"""
struct Coord{T} <: Dimension{T}
    val::T
end
function Coord(val::T, dims::Tuple) where {T<:AbstractVector}
    length(dims) == length(first(val)) || throw(ArgumentError("Number of dims must match number of points"))
    lookup = CoordLookup(val, name2dim(dims))
    Coord(lookup)
end
const SelOrStandard = Union{Selector,StandardIndices}
Coord(s1::SelOrStandard, s2::SelOrStandard, sels::SelOrStandard...) = Coord((s1, s2, sels...))
Coord(sel::Selector) = Coord((sel,))
Coord(d1::Dimension, dims::Dimension...) = Coord((d1, dims...))
Coord() = Coord(:)

dims(d::Coord) = dims(val(d))

_matches(sel::Dimension, x) = _matches(val(sel), x)
_matches(sel::Between, x) = (x >= first(sel)) & (x < last(sel))
_matches(sel::Lookups.AbstractInterval, x) = x in sel
_matches(sel::At, x) = x == val(sel)
_matches(sel::Colon, x) = true
_matches(sel::Nothing, x) = true

function _format(dim::Coord, axis::AbstractRange)
    checkaxis(dim, axis)
    return dim
end


Lookups.bounds(d::Coord) = ntuple(i -> extrema((x[i] for x in val(d))), length(first(d)))

# Return a Vector{Bool} for matching coordinates
Lookups.selectindices(lookup::CoordLookup, sel::DimTuple) = selectindices(lookup, sortdims(sel, dims(lookup)))
Lookups.selectindices(lookup::CoordLookup, sel::Tuple) = [all(map(_matches, sel, x)) for x in lookup]
Lookups.selectindices(lookup::CoordLookup, sel::StandardIndices) = sel

@inline Lookups.reducelookup(l::CoordLookup) = NoLookup(OneTo(1))

_tozero(xs) = map(x -> zero(x), xs)
@inline _reducedims(lookup::CoordLookup, dim::Dimension) =
    rebuild(dim, [_tozero(dim.val[1])], dim.lookup)
