# Key methods to add for a new dimensional data type

"""
    dims(x)

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
dims(x::Nothing) = nothing

"""
    refdims(x)

Reference dimensions for an array that is a slice or view of another 
array with more dimensions. 

`slicedims(a, dims)` returns a tuple containing the current new dimensions
and the new reference dimensions. Refdims can be stored in a field or disgarded, 
as it is mostly to give context to plots. Ignoring refdims will simply leave some captions empty.  """
function refdims end
refdims(x) = ()
"""
    rebuild(x::AbstractDimensionalArray, data, [dims], [refdims])
    rebuild(x::AbstractDimension, val, [grid], [metadata])
    rebuild(x; kwargs...)

Rebuild an object struct with updated values.
"""
function rebuild end
rebuild(x; kwargs...) = ConstructionBase.setproperties(x, (;kwargs...))

"""
    val(x)

Return the contained value of a wrapper object, otherwise just returns the object.
"""
function val end
val(x) = x

"""
    metadata(x)

Return the metadata of a dimension or data object.
"""
function metadata end

"""
    units(x)

Return the units of a dimension. This could be a string, a unitful unit, or nothing. 
"""
function units end
units(x) = nothing
units(xs::Tuple) = map(units, xs)

"""
    name(x)

Get the name of data or a dimension.
"""
function name end
name(x) = name(typeof(x))
name(x::Type) = ""
name(xs::Tuple) = map(name, xs)

"""
    shortname(x)

Get the short name of array data or a dimension.
"""
function shortname end
shortname(x) = shortname(typeof(x))
shortname(xs::Tuple) = map(shortname, xs)
shortname(x::Type) = ""

"""
    label(x)

Get a plot label for data or a dimension. This will include the name and units 
if they exist, and anything else that should be shown on a plot.
"""
function label end
label(x) = string(name(x), (units(x) === nothing ? "" : string(" ", units(x))))
label(xs::Tuple) = join(map(label, xs), ", ")
