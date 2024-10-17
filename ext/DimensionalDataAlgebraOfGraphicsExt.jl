module DimensionalDataAlgebraOfGraphicsExt

import AlgebraOfGraphics as AoG
import DimensionalData as DD

# We can't use `DD.Dimensions.DimOrDimType` because that's a union with Symbol,
# which causes an ambiguity and would otherwise override the dedicated Symbol 
# `select` method in AoG.
const DimOrType = Union{DD.Dimensions.Dimension, Type{<: DD.Dimensions.Dimension}}

#=

This extension allows DimensionalData `Dimension` types to be used
as column selectors for AlgebraOfGraphics.jl.

Specifically, this implements the `AoG.select` method for `Columns`
objects, which is the type that `AlgebraOfGraphics.data` returns.

=#

# The generic selector, to enable this to work even in `DataFrame(dimarray)`
function AoG.select(data::AoG.Columns, dim::DimOrType)
    name = DD.name(dim)
    v = AoG.getcolumn(data.columns, Symbol(name))
    return (v,) => identity => AoG.to_string(name) => nothing
end

# The specific selector for `DimTable`s.
# This searches the dimensions of the dimtable for the appropriate dimension,
# so that e.g. `X` also applies to any `XDim`, and so forth.
function AoG.select(data::AoG.Columns{<: DD.AbstractDimTable}, dim::DimOrType)
    # Query the dimensions in the table for the dimension
    available_dimension = DD.dims(data.columns, dim)
    # If the dimension is not found, it might be the name of the 
    # underlying array.
    name = if isnothing(available_dimension)
        if DD.name(dim) in DD.name(parent(data.columns))
            # TODO: should we error here, and tell the user they should
            # use a symbol instead of a dimension?
            return DD.name(dim)
        else
            error("Dimension $dim not found in DimTable with dimensions $(DD.dims(data.columns)), and neither was it the name of the array ($(DD.name(parent(data.columns)))).")
        end
    else
        # The dimension was found, so use that name.
        DD.name(available_dimension)
    end
    # Get the column from the table
    v = AoG.getcolumn(data.columns, Symbol(name))
    # Return the column, with the appropriate labels
    return (v,) => identity => AoG.to_string(name) => nothing
end

end