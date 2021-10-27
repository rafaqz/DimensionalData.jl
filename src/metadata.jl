
"""
    AbstractMetadata{X,T}

Abstract supertype for all metadata wrappers.

Metadata wrappers allow tracking the contents and origin of metadata. This can 
facilitate conversion between metadata types (for saving a file to a differenet format)
or simply saving data back to the same file type with identical metadata.

Using a wrapper instead of `Dict` or `NamedTuple` also lets us pass metadata 
objects to [`set`](@ref) without ambiguity about where to put them.
"""
abstract type AbstractMetadata{X,T} end

const _MetadataContents =Union{AbstractDict,NamedTuple}
const AllMetadata = Union{AbstractMetadata,AbstractDict}

Base.get(m::AbstractMetadata, args...) = get(val(m), args...)
Base.getindex(m::AbstractMetadata, key) = getindex(val(m), Symbol(key))
Base.setindex!(m::AbstractMetadata, x, key) = setindex!(val(m), x, Symbol(key))
Base.haskey(m::AbstractMetadata, key) = haskey(val(m), Symbol(key))
Base.keys(m::AbstractMetadata) = keys(val(m))
Base.iterate(m::AbstractMetadata, args...) = iterate(val(m), args...)
Base.IteratorSize(m::AbstractMetadata) = Base.IteratorSize(val(m))
Base.IteratorEltype(m::AbstractMetadata) = Base.IteratorEltype(val(m))
Base.eltype(m::AbstractMetadata) = eltype(val(m))
Base.length(m::AbstractMetadata) = length(val(m))
Base.:(==)(m1::AbstractMetadata, m2::AbstractMetadata) = m1 isa typeof(m2) && val(m1) == val(m2)

"""
    Metadata <: AbstractMetadata

    Metadata{X}(val::Union{Dict,NamedTuple})
    Metadata{X}(pairs::Pair...) => Metadata{Dict}
    Metadata{X}(; kw...) => Metadata{NamedTuple}

General [`Metadata`](@ref) object. The `X` type parameter
categorises the metadata for method dispatch, if required. 
"""
struct Metadata{X,T<:_MetadataContents} <: AbstractMetadata{X,T}
    val::T
end
Metadata(val::T) where {T<:_MetadataContents} = Metadata{Nothing,T}(val)
Metadata{X}(val::T) where {X,T<:_MetadataContents} = Metadata{X,T}(val)

# NamedTuple/Dict constructor
# We have to combine these because the no-arg method is overwritten by empty kw.
function (::Type{M})(ps...; kw...) where M <: Metadata
    if length(ps) > 0 && length(kw) > 0
        throw(ArgumentError("Metadata can be constructed with args of Pair to make a Dict, or kw for a NamedTuple. But not both."))
    end
    length(kw) > 0 ? M((; kw...)) : M(Dict(ps...))
end

ConstructionBase.constructorof(::Type{<:Metadata{X}}) where {X} = Metadata{X}

val(m::Metadata) = m.val

# Metadata nearly always contains strings, which break GPU compat.
# For now just remove everything, but we could strip all strings
# and replace Dict with NamedTuple. 
# This might also be a problem with non-GPU uses of Adapt.jl where keeping
# the metadata is fine.
Adapt.adapt_structure(to, m::Metadata) = NoMetadata()

"""
    NoMetadata <: AbstractMetadata

    NoMetadata()

Indicates an object has no metadata. Can be used in `set`
to remove any existing metadata.
"""
struct NoMetadata <: AbstractMetadata{Nothing,NamedTuple{(),Tuple{}}} end

val(m::NoMetadata) = NamedTuple()

Base.keys(::NoMetadata) = ()
Base.haskey(::NoMetadata, args...) = false
Base.get(::NoMetadata, key, fallback) = fallback
Base.length(::NoMetadata) = 0

function Base.show(io::IO, mime::MIME"text/plain", metadata::Metadata{N}) where N
    print(io, "Metadata")
    if N !== Nothing
        print(io, "{")
        show(io, N)
        print(io, "}")
    end
    printstyled(io, " of "; color=:light_black)
    show(io, mime, val(metadata))
end

# Metadata utils

function metadatadict(dict)
    symboldict = Dict{Symbol,Any}()
    for (k, v) in dict
        symboldict[Symbol(k)] = v
    end
    symboldict
end

metadata(x) = NoMetadata()

units(x) = units(metadata(x))
units(m::NoMetadata) = nothing
units(m::Nothing) = nothing
units(m::Metadata) = get(m, :units, nothing)
units(m::AbstractDict) = get(m, :units, nothing)

label(x) = string(string(name(x)), (units(x) === nothing ? "" : string(" ", units(x))))
