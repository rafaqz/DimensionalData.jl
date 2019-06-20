"""
Some thoughts on this module.

The core goal is to define common types and methods for accessing and working with spatial
rasters in the form of matrices or multidimensional arrays - as opposed to a list of points
also refered to as rasters. But an interface for both types of data would be best.

Other goals:
- The ability to convert data between different types would be very useful, say to extract a
  2d spatial matrix from a NetCDF file that keeps information about its coordinates and
  projection, and plots correctly.
- Common plotting recipes


Method names need more thought, please change them at will.
"""
module GeoArrayBase

using Base: tail

export AbstractGeoArray, AbstractGeoDim, LongDim, LatDim, VertDim, TimeDim

export extract, bounds, coords, dimtype, dimname, dimunits

export lattitude, longitude, vertical, timespan

include("types.jl")
include("interface.jl")
include("dimensions.jl")
include("coordinates.jl")


end
