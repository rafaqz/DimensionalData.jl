"""
    @dim typ name [shortname=name]
Define dimensions
"""
macro dim(typ, name=string(typ), shortname=string(typ))
    esc(quote
        struct $typ{T,M} <: AbstractDimension{T,M}
            val::T
            metadata::M
        end
        $typ(val=:; metadata=nothing) = $typ(val, metadata)
        DimensionalData.dimname(::Type{<:$typ}) = $name
        DimensionalData.shortname(::Type{<:$typ}) = $shortname
    end)
end

#= Define some common dimensions

Dimension types are intentionally a little more standardised than AxisArrays 
arbitrary Axis{:x} symbols, which also requires less keystrokes. 
They should be used in packages and expected to work accross multiple 
AbstractDimensionArray/Data types.

What should go here exactly?
=#

"""
A generic dimension. For use when custom dims are required when loading
data from a file. The sintax is ugly and verbose to use for indexing, 
ie `Dim{:lat}(1:9)` rather than `Lat(1:9)`. This is the main reason 
they are not the only type of dimension availabile.
"""
struct Dim{X,T,M} <: AbstractDimension{T,M} 
    val::T
    metadata::M
    Dim{X}(val, metadata) where X = 
        new{X,typeof(val),typeof(metadata)}(val, metadata)
end
Dim{X}(val; metadata=nothing) where X = Dim{X}(val, metadata)

basetype(::Type{<:Dim{X,T,N}}) where {X,T,N} = Dim{X}
dimname(dim::Dim{X}) where X = string(X)
shortname(dim::Dim{X}) where X = string(X)

@dim Time
@dim Lat "Latitude"
@dim Lon "Longitude"
@dim Vert "Vertical"
@dim Band
