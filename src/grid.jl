abstract type RegularGrid{T} end

"""
    RegularProductGrid

Trait describing a regular grid along all axes. 
To implement the trait, a dims() function is required, returning a list of 
dimension objects for each axis, which provide a `name` and a `vals` method.
"""
struct RegularProductGrid{T} <: RegularGrid{T} end

"""
    Center

To be used as a type parameter to described grids that are defined by their center coordinates.  
"""
struct Center end

#Fallback for regular arrays
struct UnknownGrid <: RegularGrid{Center} end
#One might think about using Base.axes here to support things like OffsetArrays etc...
hasgrid(::AbstractArray) = UnknownGrid()

struct UnknownDimension{I}
    length::Int
end

# Now an example for moving grids or grids that are not a product of some axes

"""
    IrregularGrid

Traits describing a grid where the coordinates of one or more axes change along another axis. 
Subtypes of this should directly implement the functions `gridcoordinates` as well as `gridbounds`
"""
abstract type IrregularGrid{T} end
