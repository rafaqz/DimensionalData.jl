"""
Abstract supertype for all metadata wrappers.

These allow tracking the contents and origin of metadata. This can facilitate
conversion between metadata types (for saving a file to a differenet format)
or simply saving data back to the same file type with identical metadata.
"""
abstract type Metadata{T} end

# NamedTuple/Dict constructor
# We have to combine these because the no-arg method is overwritten by empty kw.
function (::Type{T})(ps...; kw...) where T <: Metadata
    if length(ps) > 0 && length(kw) > 0
        throw(ArgumentError("Metadata can be constructed with args of Pair to make a Dict, or kw for a NamedTuple. But not both."))
    end
    length(kw) > 0 ? T((; kw...)) : T(Dict(ps...))
end

val(m::Metadata) = m.val

Base.get(m::Metadata, args...) = get(val(m), args...)
Base.getindex(m::Metadata, key) = getindex(val(m), Symbol(key))
Base.setindex!(m::Metadata, x, key) = setindex!(val(m), x, Symbol(key))
Base.haskey(m::Metadata, key) = haskey(val(m), Symbol(key))
Base.keys(m::Metadata) = keys(val(m))
Base.iterate(m::Metadata, args...) = iterate(val(m), args...)
Base.IteratorSize(m::Metadata) = Base.IteratorSize(val(m))
Base.IteratorEltype(m::Metadata) = Base.IteratorEltype(val(m))
Base.eltype(m::Metadata) = eltype(val(m))
Base.length(m::Metadata) = length(val(m))
Base.:(==)(m1::Metadata, m2::Metadata) = m1 isa typeof(m2) && val(m1) == val(m2)

# Metadata nearly always contains strings, which break GPU compat.
# For now just remove everything, but we could strip all strings
# and replace Dict with NamedTuple. 
# This might also be a problem with non-GPU uses of Adapt.jl where keeping
# the metadata is fine.
Adapt.adapt_structure(to, m::Metadata) = NoMetadata()

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


"""
    DimMetadata(val::Union{Dict,NamedTuple})
    DimMetadata(pairs::Pair...) => DimMetadata{Dict}
    DimMetadata(; kw...) => DimMetadata{NamedTuple}

[`Metadata`](@ref) for a [`Dimension`](@ref).
"""
struct DimMetadata{T<:Union{AbstractDict,NamedTuple}} <: AbstractDimMetadata{T}
    val::T
end

"""
    ArrayMetadata(val::Union{Dict,NamedTuple})
    ArrayMetadata(pairs::Pair...) => ArrayMetadata{Dict}
    ArrayMetadata(; kw...) => ArrayMetadata{NamedTuple}

[`Metadata`](@ref) for a [`DimArray`](@ref).
"""
struct ArrayMetadata{T<:Union{AbstractDict,NamedTuple}} <: AbstractArrayMetadata{T}
    val::T
end

"""
    StackMetadata(val::Union{Dict,NamedTuple})
    StackMetadata(pairs::Pair...) => StackMetadata{Dict}
    StackMetadata(; kw...) => StackMetadata{NamedTuple}

[`Metadata`](@ref)for a [`DimStack`](@ref).
"""
struct StackMetadata{T<:Union{AbstractDict,NamedTuple}} <: AbstractStackMetadata{T}
    val::T
end

"""
    NoMetadata()

Indicates an object has no metadata. Can be used in `set`
to remove any existing metadata.
"""
struct NoMetadata <: Metadata{NamedTuple{(),Tuple{}}} end

val(m::NoMetadata) = NamedTuple()

Base.keys(::NoMetadata) = ()
Base.haskey(::NoMetadata, args...) = false
Base.get(::NoMetadata, key, fallback) = fallback
Base.length(::NoMetadata) = 0

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

label(x) = string(string(name(x)), (units(x) === nothing ? "" : string(" ", units(x))))
