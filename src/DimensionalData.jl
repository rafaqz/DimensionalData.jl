module DimensionalData

using RecipesBase

using Base: tail, OneTo

export AbstractDimension, Lat, Lon, Vert, Time

export AbstractDimensionArray, DimensionArray

export AbstractSelectionMode, Nearest, Contained, Exact

export AbstractDimensionData, DimensionData

export dims, refdims, dimname, dimtype, dimunits, name, shortname, label, select, bounds

include("interface.jl")
include("dimensions.jl")
include("select.jl")
include("abstract.jl")
include("dimensionarray.jl")
include("reducedims.jl")
include("macros.jl")
include("plotrecipes.jl")
include("utils.jl")


end
