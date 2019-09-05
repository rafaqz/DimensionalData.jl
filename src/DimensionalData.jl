module DimensionalData

using RecipesBase, Statistics

using Base: tail, OneTo

export AbstractDimension, Dim

export AbstractDimensionalArray, DimensionalArray

export AbstractSelectionMode, Near, Between, At

export dims, refdims, metadata, longname, shortname, 
       val, dimnum, label, units, order, <|

include("interface.jl")
include("dimension.jl")
include("select.jl")
include("array.jl")
include("primitives.jl")
include("utils.jl")
include("plotrecipes.jl")

end
