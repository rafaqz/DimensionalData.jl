
"""
    AbstractMetadata{X,K,V,T}

Abstract supertype for all metadata wrappers.

Metadata wrappers allow tracking the contents and origin of metadata. This can 
facilitate conversion between metadata types (for saving a file to a different format)
or simply saving data back to the same file type with identical metadata.

Using a wrapper instead of `Dict` or `NamedTuple` also lets us pass metadata 
objects to [`set`](@ref) without ambiguity about where to put them.
"""
abstract type AbstractMetadata{X,K,V,T} <: AbstractDict{K,V} end

const MetadataContents = Union{AbstractDict,NamedTuple}
const DefaultDict = Dict{Symbol,Any}
const AllMetadata = Union{AbstractMetadata,AbstractDict}

valtype(::AbstractMetadata{<:Any,<:Any,<:Any,T}) where T = T
valtype(::Type{<:AbstractMetadata{<:Any,<:Any,<:Any,T}})where T  = T

Base.get(m::AbstractMetadata, args...) = get(val(m), args...)
Base.getindex(m::AbstractMetadata, key) = getindex(val(m), key)
Base.setindex!(m::AbstractMetadata, x, key) = setindex!(val(m), x, key)
Base.haskey(m::AbstractMetadata, key) = haskey(val(m), key)
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
struct Metadata{X,T<:MetadataContents,K,V} <: AbstractMetadata{X,T,K,V}
    val::T
end
Metadata{X,T}(val::T) where {X,T<:NamedTuple} =
    Metadata{X,T,Symbol,Any}(val)
Metadata{X,T}(val::T) where {X,T<:AbstractDict{K,V}} where {K,V} =
    Metadata{X,T,K,V}(val)
Metadata(val::T) where {T<:MetadataContents} = Metadata{Nothing,T}(val)
Metadata{X}(val::T) where {X,T<:MetadataContents} = Metadata{X,T}(val)

# NamedTuple/Dict constructor
(::Type{M})(p1::Pair, ps::Pair...) where M <: Metadata = M(Dict(p1, ps...))
function (::Type{M})(; kw...) where M <: Metadata
    M((; kw...))
end
Metadata() = Metadata(DefaultDict())
Metadata{X}() where X = Metadata{X}(DefaultDict())
Metadata{X,T}() where {X,T} = Metadata{X,T}(T())

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

Indicates an object has no metadata. But unlike using `nothing`, 
`get`, `keys` and `haskey` will still work on it, `get` always
returning the fallback argument. `keys` returns `()` while `haskey`
always returns `false`.
"""
struct NoMetadata <: AbstractMetadata{Nothing,Dict{Symbol,Any},Symbol,Any} end

val(m::NoMetadata) = NamedTuple()

Base.keys(::NoMetadata) = ()
Base.get(::NoMetadata, key, fallback) = fallback
Base.length(::NoMetadata) = 0
Base.convert(::Type{NoMetadata}, s::Union{NamedTuple,AbstractMetadata,AbstractDict}) =
    NoMetadata()

Base.convert(::Type{Metadata}, ::NoMetadata) = Metadata()
Base.convert(::Type{Metadata}, m::MetadataContents) = Metadata(m)
Base.convert(::Type{Metadata{X}}, m::MetadataContents) where X = Metadata{X}(m)
Base.convert(::Type{Metadata{X,T}}, m::AbstractDict) where {X,T<:AbstractDict} =
    Metadata{X,T}(T(m))
Base.convert(::Type{Metadata{X,T}}, m::NamedTuple) where {X,T<:AbstractDict} = 
    Metadata{X,T}(T(metadatadict(m)))
Base.convert(::Type{Metadata{X,T}}, m::NamedTuple) where {X,T<:NamedTuple} = 
    Metadata{X,T}(T(m))
Base.convert(::Type{Metadata{X,T}}, m::AbstractDict) where {X,T<:NamedTuple} = 
    Metadata{X,T}(T(pairs(metadatadict(m))))


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

metadatadict(dict) = metadatadict(DefaultDict, dict)
function metadatadict(::Type{T}, dict) where T
    symboldict = T()
    for (k, v) in pairs(dict)
        symboldict[Symbol(k)] = v
    end
    return symboldict
end

metadata(x) = NoMetadata()

units(x) = units(metadata(x))
units(m::NoMetadata) = nothing
units(m::Nothing) = nothing
units(m::Metadata) = get(m, :units, nothing)
units(m::AbstractDict) = get(m, :units, nothing)