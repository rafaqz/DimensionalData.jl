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


export Dimension, IndependentDim, DependentDim, XDim, YDim, ZDim, TimeDim,
       X, Y, Z, Ti, ParametricDimension, Dim, AnonDim, Coord

export Selector, At, Between, Contains, Near, Where

export Locus, Center, Start, End, AutoLocus

export Order, Ordered, Unordered, AutoOrder

export Sampling, Points, Intervals

export Span, Regular, Irregular, Explicit, AutoSpan

export Lookup, Auto, AutoLookup, NoLookup

export Aligned, AbstractSampled, Sampled, AbstractCategorical, Categorical

export Unaligned, Transformed

export AbstractDimArray, DimArray

export AbstractDimTable, DimTable

export AbstractDimStack, DimStack

export DimIndices, DimKeys

export AbstractMetadata, Metadata, NoMetadata

export AbstractName, Name, NoName

export data, dims, refdims, lookup, metadata, name, label, units,
       val, index, order, sampling, span, bounds, locus, <|

export dimnum, hasdim, hasselection, otherdims, commondims, setdims, swapdims, sortdims,
       set, rebuild, reorder, modify, dimwise, dimwise!

export @dim

const DD = DimensionalData

const StandardIndices = Union{AbstractArray{<:Integer},Colon,Integer}

# Shared deps
include("interface.jl")
include("name.jl")
include("metadata.jl")
# Lookups
include("lookup/lookup_traits.jl")
include("lookup/lookup.jl")
include("lookup/selector.jl")
include("lookup/methods.jl")
# Dimensions
include("dimension/dimension.jl")
include("dimension/primitives.jl")
include("dimension/format.jl")
include("dimension/indexing.jl")
include("dimension/coord.jl")
# Arrays
include("array/array.jl")
include("array/indexing.jl")
include("array/methods.jl")
include("array/matmul.jl")
include("array/broadcast.jl")
# Stacks
include("stack/stack.jl")
include("stack/indexing.jl")
include("stack/methods.jl")
# Other
include("dimindices.jl")
include("tables.jl")
# Combined (easier to work on these in one file)
include("plotrecipes.jl")
include("utils.jl")
include("set.jl")
include("show.jl")

function _precompile()
    precompile(DimArray, (Array{Int,1}, typeof(X())))
    precompile(DimArray, (Array{Int,2}, Tuple{typeof(X()), typeof(Y())}))
    precompile(DimArray, (Array{Float64,1}, typeof(X())))
    precompile(DimArray, (Array{Float64,2}, Tuple{typeof(X()), typeof(Y())}))
    precompile(DimArray, (Array{Float64,3}, Tuple{typeof(X()), typeof(Y()), typeof(Z())}))
end

_precompile()

end
