"""
Abstract type for dimension metadata wrappers.
"""
abstract type Metadata end

val(metadata::Metadata) = metadata.val

abstract type AbstractDimMetadata <: Metadata end

abstract type AbstractArrayMetadata <: Metadata end

struct ArrayMetadata{M} <: AbstractArrayMetadata
    val::M
end

struct DimMetadata{M} <: AbstractDimMetadata
    val::M
end

