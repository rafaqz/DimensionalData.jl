
"""
Supertype for all metadata wrappers.

These allow tracking the contents and origin of metadata. 
This can facilitate conversion between metadata types (for saving 
a file to a differenet format) or simply saving data back to the 
same file type with identical metadata.
"""
abstract type Metadata{T} end

# NamedTuple constructor
(::Type{T})(; kwargs...) where T <: Metadata = T((; kwargs...))

struct NoMetadata <: Metadata{NamedTuple{(),Tuple{}}} end
Base.keys(::NoMetadata) = ()
Base.length(::NoMetadata) = 0
# TODO: what else is needed here


val(metadata::Metadata) = metadata.val

Base.get(metadata::Metadata, args...) = get(val(metadata), args...)
Base.getindex(metadata::Metadata, args...) = getindex(val(metadata), args...)
Base.setindex!(metadata::Metadata, args...) = setindex!(val(metadata), args...)
Base.keys(metadata::Metadata) = keys(val(metadata))
Base.iterate(metadata::Metadata, args...) = iterate(val(metadata), args...)
Base.IteratorSize(::Metadata) = Base.IteratorSize(m)
Base.IteratorEltype(m::Metadata) = Base.IteratorEltype(m)
Base.eltype(m::Metadata) = eltype(m)
Base.length(m::Metadata) = length(val(m))


"""
Abstract supertype for `Metadata` wrappers to be attached to `Dimension`s.
"""
abstract type AbstractDimMetadata{T} <: Metadata{T} end

"""
Abstract supertype for `Metadata` wrappers to be attached to `AbstractGeoArrays`.
"""
abstract type AbstractArrayMetadata{T} <: Metadata{T} end

"""
Abstract supertype for `Metadata` wrappers to be attached to `AbstractGeoStack`.
"""
abstract type AbstractStackMetadata{T} <: Metadata{T} end


struct DimMetadata{T<:Union{AbstractDict,NamedTuple}} <: Metadata{T}
    val::T
end
DimMetadata(p::Pair, ps::Pair...) = DimMetadata(Dict(p, ps...))

struct ArrayMetadata{T<:Union{AbstractDict,NamedTuple}} <: Metadata{T} 
    val::T
end
ArrayMetadata(p::Pair, ps::Pair...) = ArrayMetadata(Dict(p, ps...))

struct StackMetadata{T<:Union{AbstractDict,NamedTuple}} <: Metadata{T} 
    val::T
end
StackMetadata(p::Pair, ps::Pair...) = StackMetadata(Dict(p, ps...))
