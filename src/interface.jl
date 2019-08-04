"""
Return dimensions of the dataset containing the coordinate ranges
"""
function dims end

"""
Returns the type for dims, either singular `AbstractGeoDim`
or wrapped in `Tuple{}`
"""
function dimtype end

"""
Reference dimensions for an array that is a slice or
view of another array with more dimensions. 

Mostly to give context to plots.
"""
function refdims end

"""
Specify the value of missing
"""
function missingval end

"""
Specify the units of an array or dimensions. This could be a string,
a unitful unit or nothing. 

These should allways be real fields, not Dict metadata, so that unitful 
can be fast when you need it to be.
"""
function units end

"""
Get the name of a the data or a dimension.
"""
function name end

"""
Get the short name of array data or a dimension.
"""
function shortname end


# Common methods

"""
Returns bounding box coords

## Examples:

For a 2d raster array:
```
bounds(a)
((125.342, 22.234), (145.988, 41.23))
```

For the vertical dimension of a 3d raster array:
```
bounds(a, Vert)
(0.0m, 2000.0m)

etc.
```

Or something. Allowing units would be useful if the dimension has units.
"""
function bounds end

"""
Return 2d coordinates for a dataset or array.
"""
function coordinates end

"""
Select the value/array/dataset? at the specified
coordinates, rectangle, line, polygon, etc.
"""
function select end
