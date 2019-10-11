"""
Indicate the position of coordinates on the grid. 
"""
abstract type CoordLocation end

"""
Indicates dimensions that are defined by their center coordinates/time/position.  
"""
struct Center <: CoordLocation end

"""
Indicates dimensions that are defined by their start coordinates/time/position.
"""
struct Start <: CoordLocation  end

"""
Indicates dimensions that are defined by their end coordinates/time/position
"""
struct End <: CoordLocation  end



"""
Traits describing the grid type of a dimension
"""
abstract type AbstractGrid end

"""
Traits describing regular grids
"""
abstract type AbstractRegularGrid <: AbstractGrid end

"""
Trait describing a regular grid along a dimension. 

The span field indicates the size of a grid step like, such as `Month(1)`.
"""
struct RegularGrid{T,S} <: AbstractRegularGrid 
    span::S
end
RegularGrid(span=nothing) = RegularGrid{Center, typeof(span)}(span) 

"""
Fallback grid type for regular arrays
"""
struct UnknownGrid <: AbstractRegularGrid end



"""
Traits describing a dimension where the dimension values are categories.
"""
abstract type AbstractCategoricalGrid <: AbstractGrid end

struct CategoricalGrid <: AbstractCategoricalGrid end



"""
Traits describing a dimension whos coordinates change along another dimension. 
"""
abstract type AbstractIrregularGrid end

dims(grid::AbstractIrregularGrid) = grid.dims

"""
Grid type using an affine transformation to convert dimension from 
`dim(grid)` to `dims(array)`.
"""
struct TransformedGrid{T,D} <: AbstractIrregularGrid 
    transform::T
    dims::D
end

transform(grid::TransformedGrid) = grid.transform

# Get the dims in the same order as the grid
# This would be called after RegularGrid and/or CategoricalGrid
# dimensions are removed
dims2indices(grid::TransformedGrid, dimz::Tuple) = 
    sel2indices(grid, map(val, permutedims(dimz, dims(grid))))

# This is an example, I don't really know how it will work but this would be 
# something like the syntax using something from CoordinateTransforms.jl in 
# the transform field
sel2indices(grid::TransformedGrid, sel::Vararg{At}) = 
    transform(grid)(SVector(map(val, sel)))
sel2indices(grid::TransformedGrid, sel::Vararg{Near}) = 
    round.(transform(grid)(SVector(map(val, sel))))

"""
Grid type using an array lookup to convert dimension from 
`dim(grid)` to `dims(array)`.
"""
struct LookupGrid{L,D} <: AbstractIrregularGrid 
    lookup::L
    dims::D
end

lookup(grid::LookupGrid) = grid.lookup

# Get the dims in the same order as the grid
dims2indices(grid::TransformedGrid, dimz::Tuple) = 
    sel2indices(grid, map(val, permutedims(dimz, dims(grid))))

# Another example!
# Do the input values need some kind of scalar conversion? 
# what is the scale of these lookup matrices?
sel2indices(grid::TransformedGrid, sel::Vararg{At}) = 
    lookup(grid)[map(val, sel)...]
# Say there is a scalar conversion, we round to the nearest existing 
# index when using Near?
sel2indices(grid::TransformedGrid, sel::Vararg{Near}) = 
    lookup(grid)[round.(map(val, sel))...]
