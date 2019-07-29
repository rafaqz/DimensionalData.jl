
"""
Return dimensions containing their coordinate ranges
"""
function dims end

"""
A label for the data in the array
"""
function label end

"""
Calendar used for the temporal dimension
"""
function calendar end


"""
Return an AffineMap that maps indices to coordinates
"""
function affinemap end

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
function vertical end


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
Return the value/AbstractGeoArray/datalist? at the specified
coordinates, rectangle, line, polygon, etc, and time and level
when required.
"""
function extract end

"""
Specify the value of missing
"""
function missingval end

missingval(a::AbstractGeoArray) = missing

"""
Name(s) of the layers in a AbstractGeoStack object.

e.g. `"Air temperature"`

Maybe we should find an existing naming standard?
"""
# use Base.names

function dims end

"""
Returns the GeoDim of a dimension, or a tuple for all dimensions.

eg. LongDim or `(LatDim, LongDim, TimeDim)`
"""
function dimtype end

"""
Get the name of a dimension. Might be usefull for printing
and working with axis arrays etc. I'm not sure.
"""
function dimname end

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

"""
Reference dimensions for an array that is a slice or
view of an array with more dimensions.
"""
function refdims end
