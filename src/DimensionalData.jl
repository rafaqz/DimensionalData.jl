module DimensionalData

using RecipesBase, Statistics

using Base: tail, OneTo

export AbstractDimension, Dim

export AbstractDimensionalArray, DimensionalArray

export AbstractDimensionalDataset, DimensionalDataset

export AbstractSelectionMode, Near, Between, At

export AbstractMetadata

export dims, refdims, metadata, longname, shortname, 
       val, dimnum, label, units, <|

export select, selectview, bounds


include("interface.jl")
include("metadata.jl")
include("abstractdimension.jl")
include("abstractarray.jl")
include("dimension.jl")
include("array.jl")
include("primitives.jl")
include("select.jl")
include("utils.jl")
include("plotrecipes.jl")


end
