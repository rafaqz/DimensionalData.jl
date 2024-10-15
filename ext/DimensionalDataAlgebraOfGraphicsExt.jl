module DimensionalDataAlgebraOfGraphicsExt

import AlgebraOfGraphics as AoG
import DimensionalData as DD

#=

This extension allows DimensionalData `Dimension` types to be used
as column selectors for AlgebraOfGraphics.jl.

Specifically, this implements the `AoG.select` method for `Columns`
objects, which is the type that `AlgebraOfGraphics.data` returns.

=#

# The generic selector, to enable this to work even in `DataFrame(dimarray)`
function AoG.select(data::AoG.Columns, dim::Type{<: DD.Dimensions.Dimension})
    name = DD.name(dim)
    v = AoG.getcolumn(data.columns, Symbol(name))
    return (v,) => identity => AoG.to_string(name) => nothing
end

# The specific selector for `DimTable`s.
# This searches the dimensions of the dimtable for the appropriate dimension,
# so that e.g. `X` also applies to any `XDim`, and so forth.
function AoG.select(data::AoG.Columns{<: DD.DimTable}, dim::Type{<: DD.Dimensions.Dimension})
    available_dimension = DD.dims(data.columns, dim)
    name = DD.name(available_dimension)
    v = AoG.getcolumn(data.columns, Symbol(name))
    return (v,) => identity => AoG.to_string(name) => nothing
end

end