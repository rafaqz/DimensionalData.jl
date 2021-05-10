struct CoordMode{D} <: IndexMode
    dims::D
end

dims(m::CoordMode) = m.dims
order(m::CoordMode) = Unordered()

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

# Fix for https://github.com/rafaqz/DimensionalData.jl/issues/263
@inline _reducedims(mode::CoordMode, dim::Dimension) = rebuild(dim, [zero(eltype(dim.val))], dim.mode)
