"""
Some thoughts on this module.

The core goal is to define common types and methods for accessing and working with spatial 
data to simplify development and use of spatial packages in Julia.

Other goals:
- The ability to convert data between different types would be very useful, say to extract a
  matrix from a NetCDF file that keeps information about its coordinates and
  projection, and plots correctly.
- Spatial data remains attached to arrays after subsetting with getindex or view, and is updated
  to match the subset where necessary.
- N dimensions can be handled in any order: lat, long, vertical and time. Custom dims can be added.
- Common plotting recipes work for all AbstractGeoArrays


Method names need more thought, please change them at will.
"""
module GeoArrayBase

using RecipesBase, CoordinateReferenceSystemsBase

using Base: tail

export AbstractGeoDim, LongDim, LatDim, VertDim, TimeDim
export AbstractGeoArray, GeoArray
export dims, refdims, label, dimname, dimtype, dimunits, extract, bounds
export lattitude, longitude, vertical, timespan

include("types.jl")
include("interface.jl")
include("dimensions.jl")
include("coordinates.jl")
include("geoarray.jl")
include("plotrecipes.jl")


end
