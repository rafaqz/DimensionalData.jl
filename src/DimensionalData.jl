module DimensionalData

# Standard lib
using Dates,
      LinearAlgebra,
      Random,
      Statistics,
      SparseArrays

using Base.Broadcast: Broadcasted, BroadcastStyle, DefaultArrayStyle, AbstractArrayStyle,
      Unknown

using Base: tail, OneTo, Callable, @propagate_inbounds, @assume_effects
      
# Ecosystem
import Adapt, 
       ArrayInterface,
       ConstructionBase, 
       DataAPI,
       Extents,
       Interfaces,
       IntervalSets,
       InvertedIndices,
       IteratorInterfaceExtensions,
       RecipesBase,
       PrecompileTools,
       TableTraits,
       Tables

using RecipesBase: @recipe

# using IntervalSets: .., Interval

include("Dimensions/Dimensions.jl")

using .Dimensions
using .Dimensions.Lookups
using .Dimensions: StandardIndices, DimOrDimType, DimTuple, DimTupleOrEmpty, DimType, AllDims
import .Lookups: metadata, set, _set, rebuild, basetypeof, 
    order, span, sampling, locus, val, index, bounds, intervalbounds,
    hasselection, units, SelectorOrInterval, Begin, End
import .Dimensions: dims, refdims, name, lookup, kw2dims, hasdim, label, _astuple

import DataAPI.groupby

export Lookups, Dimensions

# Deprecated
const LookupArrays = Lookups
const LookupArray = Lookup
export LookupArrays, LookupArray

# Dimension
export X, Y, Z, Ti, Dim, Coord

# Selector
export At, Between, Touches, Contains, Near, Where, All, .., Not, Bins, CyclicBins

export Begin, End

export AbstractDimArray, DimArray

export AbstractDimVector, AbstractDimMatrix, AbstractDimVecOrMat, DimVector, DimMatrix, DimVecOrMat

export AbstractDimStack, DimStack

export AbstractDimTable, DimTable

export DimIndices, DimSelectors, DimPoints, #= deprecated =# DimKeys

# getter methods
export dims, refdims, metadata, name, lookup, bounds, val, layers

# Dimension/Lookup primitives
export dimnum, hasdim, hasselection, otherdims

# utils
export set, rebuild, reorder, modify, broadcast_dims, broadcast_dims!, mergedims, unmergedims

export groupby, seasons, months, hours, intervals, ranges

export @d

const DD = DimensionalData

# Common
include("interface.jl")
include("name.jl")

# Arrays
include("array/array.jl")
include("dimindices.jl")
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
include("tables.jl")
# Combined (easier to work on these in one file)
include("plotrecipes.jl")
include("utils.jl")
include("set.jl")
include("groupby.jl")
include("precompile.jl")
include("interface_tests.jl")

end
