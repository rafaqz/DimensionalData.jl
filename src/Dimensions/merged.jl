abstract type AbstractMergedLookup{T} <: Lookup{T,1} end

"""
    MergedLookup <: Lookup

    MergedLookup(data, dims; [metadata])

A [`Lookup`](@ref) that holds multiple combined dimensions.

`MergedLookup` can be indexed with [`Selector`](@ref)s like `At`, 
`Between`, and `Where` although `Near` has undefined meaning.

# Arguments

- `data`: A `Vector` of `Tuple`.
- `dims`: A `Tuple` of [`Dimension`](@ref) indicating the dimensions in the tuples in `data`.

# Keywords

- `metadata`: a `Dict` or `Metadata` object to attach dimension metadata.

"""
struct MergedLookup{T,A<:AbstractVector{T},D,Me} <: AbstractMergedLookup{T}
    data::A
    dims::D
    metadata::Me
end
MergedLookup(data, dims; metadata=NoMetadata()) = MergedLookup(data, dims, metadata)

order(m::MergedLookup) = Unordered()
dims(m::MergedLookup) = m.dims
dims(d::Dimension{<:MergedLookup}) = dims(val(d))

# Lookup interface methods

Lookups.bounds(d::Dimension{<:MergedLookup}) =
    ntuple(i -> extrema((x[i] for x in val(d))), length(first(d)))

# Return an `Int` or  Vector{Bool}
Lookups.selectindices(lookup::MergedLookup, sel::DimTuple) =
    selectindices(lookup, map(_val_or_nothing, sortdims(sel, dims(lookup))))
function Lookups.selectindices(lookup::MergedLookup, sel::NamedTuple{K}) where K
    dimsel = map(rebuild, map(name2dim, K), values(sel))
    selectindices(lookup, dimsel) 
end
Lookups.selectindices(lookup::MergedLookup, sel::StandardIndices) = sel
function Lookups.selectindices(lookup::MergedLookup, sel::Tuple)
    if (length(sel) == length(dims(lookup))) && all(map(s -> s isa At, sel))
        i = findfirst(x -> all(map(_matches, sel, x)), lookup)
        isnothing(i) && _coord_not_found_error(sel)
        return i
    else
        return [_matches(sel, x) for x in lookup]
    end
end

@inline Lookups.reducelookup(l::MergedLookup) = NoLookup(OneTo(1))

function Lookups.show_properties(io::IO, mime, lookup::MergedLookup)
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
_matches(sel::Lookups.AbstractInterval, x) = x in sel
_matches(sel::At, x) = x == val(sel)
_matches(sel::Colon, x) = true
_matches(sel::Nothing, x) = true
_matches(sel::Where, x) = sel.f(x)
@noinline _matches(::Near, x) = throw(ArgumentError("`Near` is not implemented for coordinates"))


# TODO: Do we still need `Coord` as a dimension?

const SelOrStandard = Union{Selector,StandardIndices}

struct Coord{T} <: Dimension{T}
    val::T
end
function Coord(val::T, dims::Tuple) where {T<:AbstractVector}
    length(dims) == length(first(val)) || throw(ArgumentError("Number of dims must match number of points"))
    lookup = MergedLookup(val, name2dim(dims))
    Coord(lookup)
end
Coord(s1::SelOrStandard, s2::SelOrStandard, sels::SelOrStandard...) = Coord((s1, s2, sels...))
Coord(sel::Selector) = Coord((sel,))
Coord(d1::Dimension, dims::Dimension...) = Coord((d1, dims...))
Coord() = Coord(:)
