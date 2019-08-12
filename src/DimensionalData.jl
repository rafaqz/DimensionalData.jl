module DimensionalData

using RecipesBase, Statistics

using Base: tail, OneTo

export AbstractDimension, Dim, Lat, Lon, Vert, Time

export AbstractDimensionalArray, DimensionalArray

export AbstractDimensionalDataset, DimensionalDataset

export AbstractSelectionMode, Nearest, Contained, Exact

export dims, refdims, dimname, dimtype, 
       name, shortname, val, metadata, label, units

export select, bounds, getdim, dimnum


include("utils.jl")
include("interface.jl")
include("dimensions.jl")
include("abstract.jl")
include("select.jl")
include("array.jl")
include("dim_methods.jl")
include("macros.jl")
include("plotrecipes.jl")


end
