module DimensionalData

using RecipesBase, Statistics

using Base: tail, OneTo

export AbstractDimension, Dim, Lat, Lon, Vert, Time, Band

export AbstractDimensionalArray, DimensionalArray

export AbstractDimensionalDataset, DimensionalDataset

export AbstractSelectionMode, Nearest, Contained, Exact

export dims, refdims, dimname, dimtype, 
       name, shortname, val, metadata, label, units

export select, bounds, getdim, dimnum


include("utils.jl")
include("interface.jl")
include("abstractdimension.jl")
include("abstractarray.jl")
include("dimension.jl")
include("array.jl")
include("primitives.jl")
include("select.jl")
include("band.jl")
include("plotrecipes.jl")


end
