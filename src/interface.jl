# Key methods to add for a new dimensional data type

"""
    rebuild(x, args...)
    rebuild(x; kwargs...)

Rebuild an object struct with updated field values. 

This is an abstraction that alows inbuilt and custom types to be rebuilt 
functionally to update them, as most objects in DimensionalData are immutable.

`x` can be a `AbstractDimArray`, a `Dimension`, `IndexMode` or other custom types.

The arguments reuired are defined for the abstract type that has a `rebuild` method.
"""
function rebuild end
rebuild(x; kwargs...) = ConstructionBase.setproperties(x, (;kwargs...))

"""
    dims(x) => Tuple{Vararg{<:Dimension}}

Return a tuple of `Dimension`s for an object, in the order that matches 
the axes or columns etc. of the underlying data.
"""
function dims end
dims(x) = nothing

"""
    refdims(x) => Tuple{Vararg{<:Dimension}}

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
    val(x)

Return the contained value of a wrapper object, otherwise just returns the object.
"""
function val end

"""
    metadata(x)

Return the metadata of a dimension or data object.
"""
function metadata end

"""
    mode(x) => IndexMode 

Returns the [`IndexMode`](@ref) of a dimension. This dictates
properties of the dimension such as array axis and index order, 
and sampling properties.
"""
function mode end

"""
    bounds(x, [dims]) => Union{Tuple{T,T},Tuple{Vararg{<:Tuple{T,T}}}

Return the bounds of all dimensions of an object, of a specific dimension,
or of a tuple of dimensions.

Returns a `Tuple` of length 2 `Tuple` in ascending order for each dimension.

A single value for `dims` will return a single bounds `Tuple`.
"""
function bounds end

"""
    name(x) => String

Get the name of data or a dimension.
"""
function name end
name(x) = name(typeof(x))
name(x::Type) = ""
name(xs::Tuple) = map(name, xs)

"""
    shortname(x) => String

Get the short name of array data or a dimension.

This may be a shorter version more suitable for small labels than 
`name`, but it may also be identical to `name`.
"""
function shortname end
shortname(x) = shortname(typeof(x))
shortname(xs::Tuple) = map(shortname, xs)
shortname(x::Type) = ""

"""
    units(x) => Union{Nothing,Any}

Return the units of a dimension. This could be a string, a unitful unit, or `nothing`.

Units do not have a field, and may or may not be included in `metadata`.
This method is to facilitate use in labels and plots when units are available, 
not a guarantee that they will be.
"""
function units end
units(x) = nothing
units(xs::Tuple) = map(units, xs)

"""
    label(x) => String

Get a plot label for data or a dimension. This will include the name and units
if they exist, and anything else that should be shown on a plot.
"""
function label end
label(x) = string(name(x), (units(x) === nothing ? "" : string(" ", units(x))))
label(xs::Tuple) = join(map(label, xs), ", ")
