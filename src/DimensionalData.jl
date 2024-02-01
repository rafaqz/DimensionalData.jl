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
       Extents,
       InterfacesCore,
       InvertedIndices,
       IteratorInterfaceExtensions,
       RecipesBase,
       PrecompileTools,
       TableTraits,
       Tables

using RecipesBase: @recipe

include("Dimensions/Dimensions.jl")

using .Dimensions
using .Dimensions.LookupArrays
using .Dimensions: StandardIndices, DimOrDimType, DimTuple, DimTupleOrEmpty, DimType, AllDims
import .LookupArrays: metadata, set, _set, rebuild, basetypeof, 
    order, span, sampling, locus, val, index, bounds, intervalbounds, 
    hasselection, units, SelectorOrInterval
import .Dimensions: dims, refdims, name, lookup, dimstride, kwdims, hasdim, label, _astuple

export LookupArrays, Dimensions

# Dimension
export X, Y, Z, Ti, Dim, Coord

# Selector
export At, Between, Touches, Contains, Near, Where, All, .., Not

export AbstractDimArray, DimArray

export AbstractDimVector, AbstractDimMatrix, AbstractDimVecOrMat, DimVector, DimMatrix, DimVecOrMat

export AbstractDimStack, DimStack

export AbstractDimTable, DimTable

export DimIndices, DimKeys, DimPoints

# getter methods
export dims, refdims, metadata, name, lookup, bounds

# Dimension/Lookup primitives
export dimnum, hasdim, hasselection, otherdims

# utils
export set, rebuild, reorder, modify, broadcast_dims, broadcast_dims!, mergedims, unmergedims

const DD = DimensionalData

# Common
include("interface.jl")
include("name.jl")

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
include("precompile.jl")

end
