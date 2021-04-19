struct CoordMode{D} <: IndexMode 
    dims::D
end

# dims(m::CoordMode) = dims(m)
order(m::CoordMode) = Unordered()

struct Coord{T,Mo<:IndexMode,Me<:AllMetadata} <: Dimension{T,Mo,Me}
    val::T
    mode::Mo
    metadata::Me
end
Coord(lookup::T) where T<:Tuple = Coord{T,AutoMode,NoMetadata}(lookup, AutoMode(), NoMetadata())
function Coord(val::T, dims::Tuple, metadata::Me=NoMetadata()) where {T<:AbstractVector,Me<:AllMetadata}
    length(dims) = length(first(val))
    mode = CoordMode(key2dim(dims))
    Coord{T,typeof(mode),Me}(val, mode, metadata)
end
Coord(sel::Union{Colon,Selector}...) = Coord(sel)
Coord() = Coord(Colon(), AutoMode(), NoMetadata())

# dims(d::Coord) = dims(mode(d))
bounds(d::Coord) = map((x...,) -> (x...,), extrema(val(d))...)

# Return a Vector{Bool} for matching coordinates  
sel2indices(dim::Coord, sel::Tuple) = [all(map(_matches, sel, x)) for x in val(dim)] 
sel2indices(dim::Coord, sel::Colon) = Colon()

_matches(sel::Between, x) = (x >= first(sel)) & (x < last(sel))
_matches(sel::At, x) = x == val(sel)
_matches(sel::Colon, x) = true
