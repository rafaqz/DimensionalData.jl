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
module GeoDataBase

using RecipesBase, CoordinateReferenceSystemsBase

using Base: tail, OneTo

export AbstractGeoDim, Lon, Lat, Vert, Time

export AbstractGeoArray, GeoArray

export AbstractGeoData, GeoData

export AbstractGeoStack, GeoStack

export dims, refdims, dimname, dimtype, dimunits 

export label, coordinates, coordinates!, extract, bounds

include("interface.jl")
include("types.jl")
include("dimensions.jl")
include("abstractgeoarray.jl")
include("coordinates.jl")
include("geoarray.jl")
include("plotrecipes.jl")
include("utils.jl")


end
