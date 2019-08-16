# Key methods to add for a new dimensional data type

"""
Return a tuple of the dimensions for a dataset. These can 
contain the coordinate ranges if `bounds()` and `select()` are to be used, 
or you want them to be shown on plots in place of the array indices.

They can also contain a units string or unitful unit to use and plot 
dimension units.

This is the only method required for this package to work. It probably 
requires defining a dims field on your object to store dims in.
"""
function dims end
dims(x::T) where T = error("`dims` not defined for type $T")

"""
Reference dimensions for an array that is a slice or view of another 
array with more dimensions. 

`slicedims(a, dims)` returns a tuple containing the current new dimensions
and the new reference dimensions. Refdims can be stored in a field or disgarded, 
as it is mostly to give context to plots. Ignoring refdims will simply leave some 
captions empty.
"""
function refdims end
refdims(x) = ()

"""
Define rebuild to rebuild your sctuct after a dims operation.
"""
function rebuild end
rebuild(original, newdata, newdims, newrefdims) = data


# Methods defined in Dimesions.jl

function val end
val(x) = x

"""
Return the metadata of a dimensions.
"""
function metadata end

"""
Return the units of a dimensions. This could be a string, a unitful unit, or nothing. 
"""
function units end
units(x) = ""

"""
Returns the type for dims, either singular `AbstractDimension` or wrapped in `Tuple{}`
"""
function dimtype end

"""
Get the name of data or a dimension.
"""
function dimname end
dimname(x) = dimname(typeof(x))
dimname(x::Type) = ""

"""
Get the short name of array data or a dimension.
"""
function shortname end
shortname(x) = ""
name(x) = dimname(x)

"""
Get a plot label of data or a dimension. This should include
units if they exist, and anything else that should be shown on 
a plot.
"""
function label end
label(x) = string(string(name(x)), " ", getstring(units(x)))

"""
Returns a tuple containing the start and end values
of the dimension.
"""
function bounds end

"""
Select the value/array/dataset? within the specified values
"""
function select end

