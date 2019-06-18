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

export AbstractGeoArray, LongDim, LatDim, VertDim, TimeDim

export extract, bounds, dimtype, dimname, dimunits


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
abstract type AbstractGeoArray{T,N} <: AbstractArray{T,N} end


"""
Stack object for holding multiple arrays and datasets
with the same spatial metadata and bounds. As in Rs raster stack.
"""
abstract type AbstractGeoStack end


"""
AbstractGeoDim formalises the dimensions in an AbstractGeoArray

This could be acomplished by using axis arrays, but that locks
us into a particular implementation, while this is flexible.

It should facilitate conversion between the most common dimension arrangements.

Can also be used in methods like `bounds` to get the bounds for a particular dimension,
Instead of passing an Int.
"""
abstract type AbstractGeoDim end

struct LatDim{T} <: AbstractGeoDim
    val::T
end
LatDim() = LatDim(:)

struct LongDim{T}<: AbstractGeoDim
    val::T
end
LongDim() = LongDim(:)

struct VertDim{T} <: AbstractGeoDim
    val::T
end
VertDim() = VertDim(:)

struct TimeDim{T} <: AbstractGeoDim
    val::T
end
TimeDim() = TimeDim(:)

val(dim::AbstractGeoDim) = dim.val


# Coordinate traits

struct HasAffineMap end
struct HasDimCoords end
struct HasNoCoords end

coordtype(a::AbstractGeoArray) = HasNoCoords()

lattitude(a::AbstractGeoArray, i) = lattitude(coordtype(a), a, i)
lattitude(::HasAffineMap, a::AbstractGeoArray, i) = lattitude(a, LatDim(i))
lattitude(::HasDimCoords , a::AbstractGeoArray, i) = lattitude(a, LatDim(i))
lattitude(::HasNoCoords , a::AbstractGeoArray, i) = error(typeof(a).name, "has no coordinates")


"""
Return an AffineMap that maps indices to coordinates
"""
function affinemap end

"""
Returns the GeoDim of a dimension, or a tuple for all dimensions.

eg. LongDim or `(LatDim, LongDim, TimeDim)`
"""
function dimtype end

function dimnum end

"""
Get the name of a dimension. Might be usefull for printing
and working with axis arrays etc. I'm not sure.
"""
function dimname end

dimname(::Type{LatDim}) = :lattitude
dimname(::Type{LongDim}) = :longitude
dimname(::Type{VertDim}) = :vertical
dimname(::Type{TimeDim}) = :time

"""
Return 2d coordinates for a point, polygon, range or the complete array.

also defined in GeoInterface and GeoStatsBase
"""
function coordinates end

"""
Return lattitude(s) for the point, polygon, range or array.
"""
function lattitude end

"""
Return longitude(s) for the point, polygon, range or array.
"""
function longitude end

"""
Return the vertical level at a z axis position or range, or for the complete array

Should this be called vertical or elevation?

"""

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
function dimunits end

abstract type AbstractUnitFormat end

struct UnitfulUnitFormat{U}
    unit::U
end

struct NetCDFUnitFormat
    unit::String
end

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
bounds(a, LevelDim)
(0.0m, 2000.0m)

etc.
```

Or something. Allowing units would be useful if the dimension has units.
"""
function bounds end

"""
Returns a tuple of the cell ranges for long, lat, vertical, time
points, ranges polygons etc.

Have to think about how to do this.
"""
function cells end

"""
Return the value/vector/matrix/list? at the specified
coordinates, rectangle, line, polygon, etc, and time and level
when required.
"""
function extract end

"""
Masks the raster by a polygon. Creates a new raster where points falling outside
the polygon have been replaced by `missing` or whatever is used for missing
in this type.
"""
function mask end

"""
Name(s) of the included data.

e.g. `"Air temperature"`

Maybe we should suggest an existing naming standard as well.
"""
# use Base.names


dimname(a::AbstractGeoArray) = dimname.(dimtype(a))
dimname(a::AbstractGeoData) = dimname.(dimtype(a))

dimnum(a::AbstractGeoArray, d::AbstractGeoDim) = findfirst(x -> x == d, dimtype(a))

# coordinates(d::AbstractGeoDim) =
extract(a::AbstractGeoArray, dims::Vararg{<:AbstractGeoDim}) =
    extract(a, dimstoargs(dimtype(a), dims)...)

dimstoargs(a::AbstractGeoArray, dims::Tuple) = dimstoargs(dimtype(a), dims)
@generated dimstoargs(dimtypes::Type{DT}, dims::Tuple) where DT = dimstoargs_inner(DT, dims)

dimstoargs_inner(dimtypes::Type, dims::Type) = begin
    indexexps = []
    for dimtype in dimtypes.parameters
        index = findfirst(d -> d <: dimtype, dims.parameters)
        if index == nothing
            push!(indexexps, :(Colon()))
        else
            push!(indexexps, :(GeoArrayBase.val(dims[$index])))
        end
    end
    Expr(:tuple, indexexps...)
end

argstodims(a::AbstractGeoArray, I::Tuple) = argstodims(dimtype(a), I)
@generated argstodims(dimtypes::Type{DT}, dims::Tuple) where DT = argstodims_inner(DT, dims)

argstodims_inner(dimtypes::Type, dims::Type) = begin
    indexexps = []
    for (i, dim) in enumerate(dims.parameters)
        dim <: Number || push!(indexexps, dimtypes.parameters[i])
    end
    Expr(:curly, Tuple, indexexps...)
end

    # (finddim(dimtypes[1], dims), sortdims(Base.tail(dimtypes), dims)...)
# sortdims(dimtype::Tuple{}, dims::Tuple) = ()

# finddim(::Type{D}, dims::Tuple{T,Vararg}) where {D,T} = begin
    # T <: D ? :(val($(dims[1]))) : finddim(D, Base.tail(dims))
# end
# finddim(::Type{D}, dims::Tuple{}) where {D,T} = :(Colon())

Base.@propagate_inbounds Base.getindex(a::AbstractGeoArray, dims::Vararg{<:AbstractGeoDim}) =
    getindex(a, dimstoargs(a, dims)...)

Base.view(a::AbstractGeoArray, dims::Vararg{<:AbstractGeoDim}) =
    view(a, dimstoargs(a, dims)...)

end
