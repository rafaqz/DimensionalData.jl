"""
    MergedLookup <: LookupArray

    MergedLookup(data, dims; [metadata])

A [`LookupArray`](@ref) that holds multiple combined dimensions.

`MergedLookup` can be indexed with [`Selector`](@ref)s like `At`, 
`Between`, and `Where` although `Near` has undefined meaning.

# Arguments

- `data`: A `Vector` of `Tuple`.
- `dims`: A `Tuple` of [`Dimension`](@ref) indicating the dimensions in the tuples in `data`.


# Keywords

- `metadata`: a `Dict` or `Metadata` object to attach dimension metadata.

"""
struct MergedLookup{T,A<:AbstractVector{T},D,Me} <: LookupArray{T,1}
    data::A
    dims::D
    metadata::Me
end
MergedLookup(data, dims; metadata=NoMetadata()) = MergedLookup(data, dims, metadata)

@deprecate CoordLookupArray MergedLookup

order(m::MergedLookup) = Unordered()
dims(m::MergedLookup) = m.dims
dims(d::Dimension{<:MergedLookup}) = dims(val(d))

# LookupArray interface methods

LookupArrays.bounds(d::Dimension{<:MergedLookup}) =
    ntuple(i -> extrema((x[i] for x in val(d))), length(first(d)))

# Return an `Int` or  Vector{Bool}
LookupArrays.selectindices(lookup::MergedLookup, sel::DimTuple) =
    selectindices(lookup, map(_val_or_nothing, sortdims(sel, dims(lookup))))
function LookupArrays.selectindices(lookup::MergedLookup, sel::NamedTuple{K}) where K
    dimsel = map(rebuild, map(key2dim, K), values(sel))
    selectindices(lookup, dimsel) 
end
LookupArrays.selectindices(lookup::MergedLookup, sel::StandardIndices) = sel
function LookupArrays.selectindices(lookup::MergedLookup, sel::Tuple)
    if (length(sel) == length(dims(lookup))) && all(map(s -> s isa At, sel))
        i = findfirst(x -> all(map(_matches, sel, x)), lookup)
        isnothing(i) && _coord_not_found_error(sel)
        return i
    else
        return [_matches(sel, x) for x in lookup]
    end
end

@inline LookupArrays.reducelookup(l::MergedLookup) = NoLookup(OneTo(1))

function LookupArrays.show_properties(io::IO, mime, lookup::MergedLookup)
    print(io, " ")
    show(IOContext(io, :inset => "", :dimcolor => 244), mime, basedims(lookup))
end

# Dimension methods

@inline _reducedims(lookup::MergedLookup, dim::Dimension) =
    rebuild(dim, [map(x -> zero(x), dim.val[1])])

function _format(dim::Dimension{<:MergedLookup}, axis::AbstractRange)
    checkaxis(dim, axis)
    return dim
end

# Local functions

@noinline _coord_not_found_error(sel) = error("$(map(val, sel)) not found in coord lookup")

_val_or_nothing(::Nothing) = nothing
_val_or_nothing(d::Dimension) = val(d)


_matches(sel::Tuple, x) = all(map(_matches, sel, x))
_matches(sel::Dimension, x) = _matches(val(sel), x)
_matches(sel::Between, x) = _matches(Interval(val(sel)...), x)
_matches(sel::Touches, x) = (x >= first(sel)) & (x <= last(sel))
_matches(sel::LookupArrays.AbstractInterval, x) = x in sel
_matches(sel::At, x) = x == val(sel)
_matches(sel::Colon, x) = true
_matches(sel::Nothing, x) = true
_matches(sel::Where, x) = sel.f(x)
@noinline _matches(sel::Near, x) = throw(ArgumentError("`Near` is not implemented for coordinates"))


# TODO: Do we still need `Coord` as a dimension?

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
  lookup: MergedLookup
Coord{Vector{Tuple{Float64, Float64, Float64}}, DimensionalData.MergedLookup{Tuple{X{Colon, AutoLookup{Auto
Order}, NoMetadata}, Y{Colon, AutoLookup{AutoOrder}, NoMetadata}, Z{Colon, AutoLookup{AutoOrder}, NoMetada
ta}}}, NoMetadata}

julia> da = DimArray(0.1:0.1:0.4, dim)
4-element DimArray{Float64,1} with dimensions:
  Coord (): Tuple{Float64, Float64, Float64}[(1.0, 1.0, 1.0), (1.0, 2.0, 2.0), (3.0, 4.0, 4.0), (1.0,
3.0, 4.0)]
    MergedLookup
 0.1
 0.2
 0.3
 0.4

julia> da[Coord(Z(At(1.0)), Y(Between(1, 3)))]
1-element DimArray{Float64,1} with dimensions:
  Coord (): Tuple{Float64, Float64, Float64}[(1.0, 1.0, 1.0)] MergedLookup
 0.1

julia> da[Coord(4)] == 0.4
true

julia> da[Coord(Between(1, 5), :, At(4.0))]
2-element DimArray{Float64,1} with dimensions:
  Coord (): Tuple{Float64, Float64, Float64}[(3.0, 4.0, 4.0), (1.0, 3.0, 4.0)] MergedLookup
 0.3
 0.4
```
"""
struct Coord{T} <: Dimension{T}
    val::T
end
function Coord(val::T, dims::Tuple) where {T<:AbstractVector}
    length(dims) == length(first(val)) || throw(ArgumentError("Number of dims must match number of points"))
    lookup = MergedLookup(val, key2dim(dims))
    Coord(lookup)
end
const SelOrStandard = Union{Selector,StandardIndices}
Coord(s1::SelOrStandard, s2::SelOrStandard, sels::SelOrStandard...) = Coord((s1, s2, sels...))
Coord(sel::Selector) = Coord((sel,))
Coord(d1::Dimension, dims::Dimension...) = Coord((d1, dims...))
Coord() = Coord(:)
