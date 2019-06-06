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

# For points, lines, polygons etc
using GeoInterface 


"""
Define some common Coordinate Reference System formats.
May belong in another package like ProjectionsBase.jl

In some other package like Projections.jl etc:

`convert(::Type{Proj4}, wkt::WellKnowText) = GDAL/Proj4 does something...`

See https://github.com/evetion/GeoArrays.jl/blob/master/src/crs.jl

But we should use the type system and `convert` instead of specific functions
"""
abstract type AbstractCRSformat end

struct Proj4 <: AbstractCRSformat
    crs::String
end

struct WellKnownText <: AbstractCRSformat
    crs::String
end

struct EPSGcode <: AbstractCRSformat
    crs::Int
end



"""
AbstractGeoDim formalises the dimensions in an AbstractGeoArray

This could be acomplished by using axis arrays, but that locks
us into a particular implementation, while this is flexible.

It should facilitate conversion between the most common dimension arrangements.

Can also be used in methods like `bounds` to get the bounds for a particular dimension,
Instead of passing an Int.
"""
abstract type AbstractGeoDim end

struct LattitudeDim <: AbstractGeoDim end

struct LongitudeDim <: AbstractGeoDim end

struct LevelDim <: AbstractGeoDim end

struct TimeDim <: AbstractGeoDim end

"""
Returns the GeoDim of a dimension, or a tuple for all dimensions.

eg. LongitudeDim() or `(LattitudeDim(), LongitudeDim(), TimeDim())`
"""
function dimtype end

"""
Get the name of a dimension. Might be usefull for printing
and working with axis arrays etc. I'm not sure.
"""
function dimname end

dimname(::Type{LattitudeDim}) = :lattitude
dimname(::Type{LongitudeDim}) = :longitude
dimname(::Type{LevelDim}) = :level
dimname(::Type{TimeDim}) = :time



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
dimtypes
coordinates
lattitude
longitude
bounds
extract
"""
abstract type AbstractGeoData{T,N} end


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

basic array interface
iterable interface?

# Required methods
crs
dimtypes
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
abstract type AbstractGeoArray{T,N} <: AbstractArray{T,N} end


"""
Stack object for holding multiple arrays and datasets
with the same spatial metadata and bounds. As in Rs raster stack.
"""
abstract type AbstractGeoStack end


# Spatial methods

"""
Returns the coordinate reference system used as an AbstractCRSFormat

crs is also defined in GeoInterface but not very clearly
"""
function crs end

"""
Return 2d coordinates for a point, polygon, range or the complete array.

also defined in GeoInterface and GeoStatsBase
"""
function coordinates end

"""
Return lattitude for the point, polygon, range or array.
"""
function lattitude end

"""
Return longitude for the point, polygon, range or array.
"""
function longitude end

"""
Return the vertical level at a z axis position or range, or for the complete array

Should this be called vertical or elevation?

"""
function level end

"""
Handling units is a big question.

Ubiquitous Unitful units is my preference but it's not practical,
so a method like this might be required, with some wrapper types.

A utility package that does conversion between standard 
unit strings in NetCDF etc. and Unitful units would help bridge the gap and alow
automated conversion between unitless and unitful GeoArray types.  

This might help:
https://github.com/Alexander-Barth/UDUnits.jl
"""
function levelunits end

abstract type AbstractUnitFormat end

struct UnitfulUnitFormat{U} 
    unit::U
end

struct NetCDFUnitFormat
    unit::String
end


# Temporal methods

"""
Return the time at an index, range or the complete dataset

Unitful days or hours are very fast and powerful for simulations, but limited to 
periods of days and shorter. DataTime and calendars are needed for longer timespans 
and calender months etc.

What name as `time` is taken in Base?
"""
function times end

"""
The same units questions as for `level`, but with the complication of calendars.
"""
function timeunits end # ?


# Calendars are implemented in NCDatasets with lots of helper methods
# https://github.com/Alexander-Barth/NCDatasets.jl/blob/85c0bd07ade58d2c20308c8da6653f6d80cab20d/src/time.jl#L281
#
# We should pull them out into a separate CalendarBase package
# Although I like the `Calendar` prefix better than the `DateTime` prefix in NCDatasets

abstract type AbstractCalendar end

# Calendars taken from the NetCDF standard
struct CalendarGregorian <: AbstractCalendar end
struct CalendarProlepticGregorian <: AbstractCalendar end
struct CalendarNoLeap <: AbstractCalendar end
struct CalendarAllLeap <: AbstractCalendar end
struct Calendar360Day <: AbstractCalendar end
struct CalendarJulian <: AbstractCalendar end
struct CalendarNone <: AbstractCalendar end

# And add any additional calendars outside of the NetCDF spec
# Like my favourite high-performance modelling calendar: equal month/year lengths
struct CalendarEqualised <: AbstractCalendar end

"""
Calendar used for the temporal dimension
"""
function calendar end


# Common methods

"""
Returns bounding box coords, but for any dimensions
because this is Julia and we can :)

## Examples:

For a 2d raster array:
```
bounds(a)
((125.342, 22.234), (145.988, 41.23))
```

For the vertical dimension of a 3d raster array:
```
bounds(LevelDim, x)
(0.0m, 2000.0m)

etc.
```

Or something. Allowing units would be useful if the dimension has units.
"""
function bounds end

"""
Return the value/vector/matrix/list? at the specified 
coordinates, rectangle, line, polygon, etc, and time and level
when required.
"""
function extract end

"""
Name(s) of the included data.

e.g. `"Air temperature"`

Maybe we should suggest an existing naming standard as well.
"""
# use Base.names


dimname(a::AbstractGeoArray) = dimname.(dimtypes(a))
dimname(a::AbstractGeoData) = dimname.(dimtypes(a))


end # module
