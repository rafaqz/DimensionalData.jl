"""
Abstract type for dimension metadata wrappers.
"""
abstract type Metadata{K,V} <: AbstractDict{K,V} end

(::Type{T})() where T <: Metadata = T(Dict())

val(metadata::Metadata) = metadata.val

Base.get(metadata::Metadata, args...) = get(val(metadata), args...)
Base.getindex(metadata::Metadata, args...) = getindex(val(metadata), args...)
Base.setindex!(metadata::Metadata, args...) = setindex!(val(metadata), args...)
Base.keys(metadata::Metadata) = keys(val(metadata))
Base.iterate(metadata::Metadata, args...) = iterate(val(metadata), args...)
Base.IteratorSize(::Metadata{M})	where M = IteratorSize(M)
Base.IteratorEltype(::Metadata{M}) where M = IteratorEltype(M)
Base.eltype(::Metadata{M}) where M = eltype(M)
Base.length(metadata::Metadata) = length(val(metadata))

abstract type AbstractDimMetadata{K,V} <: Metadata{K,V} end

abstract type AbstractArrayMetadata{K,V} <: Metadata{K,V} end

struct ArrayMetadata{K,V} <: AbstractArrayMetadata{K,V}
    val::Dict{K,V}
end

struct DimMetadata{K,V} <: AbstractDimMetadata{K,V}
    val::Dict{K,V}
end
