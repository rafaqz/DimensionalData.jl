struct CoordMode{D} <: IndexMode
    dims::D
end

dims(m::CoordMode) = m.dims
order(m::CoordMode) = Unordered()

"""
    Coord <: Dimension

A coordinate dimension itself holds dimensions.

This allows combining point data with other dimensions, such as time.

# Example

```julia
julia> using DimensionalData

julia> dim = Coord([(1.0,1.0,1.0), (1.0,2.0,2.0), (3.0,4.0,4.0), (1.0,3.0,4.0)], (X(), Y(), Z()))
Coord ::
  val: Tuple{Float64, Float64, Float64}[(1.0, 1.0, 1.0), (1.0, 2.0, 2.0), (3.0, 4.0, 4.0), (1.0, 3.0,
4.0)]
  mode: CoordMode
Coord{Vector{Tuple{Float64, Float64, Float64}}, DimensionalData.CoordMode{Tuple{X{Colon, AutoMode{Auto
Order}, NoMetadata}, Y{Colon, AutoMode{AutoOrder}, NoMetadata}, Z{Colon, AutoMode{AutoOrder}, NoMetada
ta}}}, NoMetadata}

julia> da = DimArray(0.1:0.1:0.4, dim)
4-element DimArray{Float64,1} with dimensions:
  Coord (): Tuple{Float64, Float64, Float64}[(1.0, 1.0, 1.0), (1.0, 2.0, 2.0), (3.0, 4.0, 4.0), (1.0,
3.0, 4.0)]
    CoordMode
 0.1
 0.2
 0.3
 0.4

julia> da[Coord(Z(At(1.0)), Y(Between(1, 3)))]
1-element DimArray{Float64,1} with dimensions:
  Coord (): Tuple{Float64, Float64, Float64}[(1.0, 1.0, 1.0)] CoordMode
 0.1

julia> da[Coord(4)] == 0.4
true

julia> da[Coord(Between(1, 5), :, At(4.0))]
2-element DimArray{Float64,1} with dimensions:
  Coord (): Tuple{Float64, Float64, Float64}[(3.0, 4.0, 4.0), (1.0, 3.0, 4.0)] CoordMode
 0.3
 0.4
```
"""
struct Coord{T,Mo<:IndexMode,Me<:AllMetadata} <: Dimension{T,Mo,Me}
    val::T
    mode::Mo
    metadata::Me
end
function Coord(val::T, dims::Tuple, metadata::Me=NoMetadata()) where {T<:AbstractVector,Me<:AllMetadata}
    length(dims) = length(first(val))
    mode = CoordMode(key2dim(dims))
    Coord{T,typeof(mode),Me}(val, mode, metadata)
end
const SelOrStandard = Union{Selector,StandardIndices}
Coord(s1::SelOrStandard, s2::SelOrStandard, sels::SelOrStandard...) = Coord((s1, s2, sels...))
Coord(sel::Selector) = Coord((sel,))
Coord(d1::Dimension, dims::Dimension...) = Coord((d1, dims...))
Coord(val::T=:) where T = Coord{T,AutoMode,NoMetadata}(val, AutoMode(), NoMetadata())

dims(d::Coord) = dims(mode(d))
bounds(d::Coord) = ntuple(i -> extrema((x[i] for x in val(d))), length(first(d)))

# Return a Vector{Bool} for matching coordinates
sel2indices(dim::Coord, sel::DimTuple) = sel2indices(dim, sortdims(sel, dims(dim)))
sel2indices(dim::Coord, sel::Tuple) = [all(map(_matches, sel, x)) for x in val(dim)]
sel2indices(dim::Coord, sel::StandardIndices) = sel

_matches(sel::Dimension, x) = _matches(val(sel), x)
_matches(sel::Between, x) = (x >= first(sel)) & (x < last(sel))
_matches(sel::At, x) = x == val(sel)
_matches(sel::Colon, x) = true
_matches(sel::Nothing, x) = true

_tozero(xs) = map(x -> zero(x), xs)
@inline _reducedims(mode::CoordMode, dim::Dimension) =
    rebuild(dim, [_tozero(dim.val[1])], dim.mode)
