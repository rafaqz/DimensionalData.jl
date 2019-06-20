
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
Return the value/AbstractGeoArray/data? at the specified
coordinates, rectangle, line, polygon, etc, and time and level
when required.
"""
function extract end

"""
Name(s) of the layers in a AbstractGeoStack object.

e.g. `"Air temperature"`

Maybe we should find an existing naming standard?
"""
# use Base.names
