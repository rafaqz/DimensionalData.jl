"""
Indicate the position of coordinates on the grid, wrapping with size 
of the grid step as an optional field (if it is constant or pseudo-constant 
like `Month(1)`.
"""
abstract type CoordType{T} end

"""
    Center{T}

Indicates dimensions that are defined by their center coordinates/time/position.  
"""
struct Center{T} <: CoordType{T} 
    span::T
end
"""
    Start{T}

Indicates dimensions that are defined by their start coordinates/time/position.
"""
struct Start{T} <: CoordType{T}  
    span::T
end

"""
    End{T}

Indicates dimensions that are defined by their end coordinates/time/position
"""
struct End{T} <: CoordType{T}  
    span::T
end


abstract type GridTrait end

abstract type RegularGrid{T} <: GridTrait  
    span::T
end

"""
    RegularProductGrid

Trait describing a regular grid along a dimension. 
"""
struct RegularProductGrid{T} <: RegularGrid{T} end

#Fallback for regular arrays
struct UnknownGrid <: RegularGrid{Center{Nothing}} end

"""
    IrregularGrid

Traits describing a dimension whos coordinates change along another dimension. 
"""
abstract type IrregularGrid{T} end


"""
    CategoricalGrid

Traits describing a dimension where the dimension values are categories.
"""
abstract type CategoricalGrid <: GridTrait end
