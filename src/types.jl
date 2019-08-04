"""
Abstract type for spatial data that isn't an abstract array but uses some of the same methods

I don't really use these formats, so help is required here.

Examples:
`SpatialGrids.Raster`
`GeoStatsBase.AbstractSpatialObject`

Interface: ???

iterable interface?

# Required methods
crs
dimtype
coordinates
lattitude
longitude
bounds
extract
"""
abstract type AbstractGeoData{T,N,D} end


"""
    AbstractGeoArray

2+ dimensional spatial data arrays

# Possible array dimensions:
- 2d array with standard lat / long dimensions
- 3d array with time dimension
- 3d array with vertical/z/level dimension
- 4d array with vertical and time dimension (used in ClimateTools.jl and Microclimate.jl)
- 3/4/5/6d raster with a additional non-spatial/temporal dimensions
    - See: https://www.unidata.ucar.edu/software/netcdf/netcdf/Dimensions.html
- non-standard dimension order order are likely

## Coordinate transformations for various dimensions
- Spatial coordinates always use a projection, but it might not be important for all applications.
  - Implementations can use AffineMap (see GEOArrays)
- Temporal dimension may be fixed length like hours, or irregular like months - needing a calendar
- Vertical dimension may or may not be equally-spaced.

Interface:

basic array interface iterable interface?

# Required methods
crs
dimtype
coordinates
lattitude
longitude
bounds
extract
convert (from any AbstractGeoArray)

# With 3+ dimensions
level
time
"""
abstract type AbstractGeoArray{T,N,D} <: AbstractArray{T,N} end


"""
Stack object for holding multiple arrays and datasets
with the same spatial metadata and bounds. As in Rs raster stack.

Contained objects must share common dims D?
"""
abstract type AbstractGeoStack{D} end


