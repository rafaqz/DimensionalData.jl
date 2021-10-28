module DimensionalData

# Use the README as the module docs
@doc let
    path = joinpath(dirname(@__DIR__), "README.md")
    include_dependency(path)
    read(path, String)
end DimensionalData

# Standard lib
using Dates,
      LinearAlgebra,
      Random,
      Statistics,
      SparseArrays

using Base.Broadcast: Broadcasted, BroadcastStyle, DefaultArrayStyle, AbstractArrayStyle,
      Unknown

using Base: tail, OneTo, @propagate_inbounds
      
# Ecosystem
import Adapt, 
       ArrayInterface,
       ConstructionBase, 
       RecipesBase,
       Tables

using RecipesBase: @recipe

# Dimension
export X, Y, Z, Ti, Dim, Coord

# Selector
export At, Between, Contains, Near, Where

export AbstractDimArray, DimArray

export AbstractDimStack, DimStack

export AbstractDimTable, DimTable

export DimIndices, DimKeys

# getter methods
export dims, refdims, lookup, metadata, name, val, order, sampling, span, bounds

# Dimension/Lookup primitives
export dimnum, hasdim, hasselection, otherdims

# utils
export set, rebuild, reorder, modify, dimwise, dimwise!

export @dim

const DD = DimensionalData

const StandardIndices = Union{AbstractArray{<:Integer},Colon,Integer}

# Shared deps
include("interface.jl")
include("name.jl")
include("metadata.jl")
# LookupArrays
include("lookup/lookup_traits.jl")
include("lookup/lookup.jl")
include("lookup/selector.jl")
include("lookup/methods.jl")
include("lookup/show.jl")
# Dimensions
include("dimension/dimension.jl")
include("dimension/primitives.jl")
include("dimension/format.jl")
include("dimension/indexing.jl")
include("dimension/coord.jl")
include("dimension/show.jl")
# Arrays
include("array/array.jl")
include("array/indexing.jl")
include("array/methods.jl")
include("array/matmul.jl")
include("array/broadcast.jl")
include("array/show.jl")
# Stacks
include("stack/stack.jl")
include("stack/indexing.jl")
include("stack/methods.jl")
include("stack/show.jl")
# Other
include("dimindices.jl")
include("tables.jl")
# Combined (easier to work on these in one file)
include("plotrecipes.jl")
include("utils.jl")
include("set.jl")

function _precompile()
    precompile(DimArray, (Array{Int,1}, typeof(X())))
    precompile(DimArray, (Array{Int,2}, Tuple{typeof(X()), typeof(Y())}))
    precompile(DimArray, (Array{Float64,1}, typeof(X())))
    precompile(DimArray, (Array{Float64,2}, Tuple{typeof(X()), typeof(Y())}))
    precompile(DimArray, (Array{Float64,3}, Tuple{typeof(X()), typeof(Y()), typeof(Z())}))
end

_precompile()

end
