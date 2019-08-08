"""
    @dim typ name [shortname=name]

Define dimensions for array indexing
"""
macro dim(typ, name, shortname=name)
    esc(quote
        struct $typ{T,M} <: AbstractDimension{T}
            val::T
            metadata::M
        end
        $typ(val; metadata=nothing) = $typ(val, metadata)
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

@dim Time "Time"
@dim Lat "Lattitude" "Lat"
@dim Lon "Longitude" "Lon"
@dim Vert "Vertical" "Vert"
