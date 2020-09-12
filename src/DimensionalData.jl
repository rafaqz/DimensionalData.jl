module DimensionalData

# Use the README as the module docs
@doc let
    path = joinpath(dirname(@__DIR__), "README.md")
    include_dependency(path)
    read(path, String)
end DimensionalData

using Base.Broadcast: Broadcasted, BroadcastStyle, DefaultArrayStyle, AbstractArrayStyle, 
      Unknown

using ConstructionBase, 
      Dates,
      LinearAlgebra, 
      RecipesBase, 
      Statistics, 
      SparseArrays,
      Tables

using Base: tail, OneTo


export Dimension, IndependentDim, DependentDim, XDim, YDim, ZDim, TimeDim, 
       X, Y, Z, Ti, ParametricDimension, Dim, AnonDim

export Selector, At, Between, Contains, Near, Where

export Locus, Center, Start, End, AutoLocus

export Order, Ordered, Unordered, UnknownOrder, AutoOrder

export IndexOrder, ArrayOrder, RelationOrder,
       ForwardIndex, ReverseIndex, UnorderedIndex,
       ForwardArray, ReverseArray, ForwardRelation, ReverseRelation

export Sampling, Points, Intervals

export Span, Regular, Irregular, AutoSpan

export IndexMode, Auto, AutoMode, NoIndex

export Aligned, AbstractSampled, Sampled,
       AbstractCategorical, Categorical

export Unaligned, Transformed

export AbstractDimArray, DimArray, AbstractDimensionalArray, DimensionalArray

export AbstractDimTable, DimTable

export AbstractDimDataset, DimDataset

export data, dims, refdims, mode, metadata, name, shortname, label, units,
       val, index, order, sampling, span, bounds, locus, layers, <|

export dimnum, hasdim, otherdims, commondims, setdims, swapdims, sortdims, 
       set, rebuild, reorder, modify, dimwise, dimwise!

export order, indexorder, arrayorder, relation

export @dim

include("interface.jl")
include("mode.jl")
include("identify.jl")
include("dimension.jl")
include("array.jl")
include("dataset.jl")
include("tables.jl")
include("selector.jl")
include("primitives.jl")
include("broadcast.jl")
include("methods.jl")
include("matmul.jl")
include("set.jl")
include("utils.jl")
include("plotrecipes.jl")
include("prettyprint.jl")

# For compat with old versions
const AbstractDimensionalArray = AbstractDimArray
const DimensionalArray = DimArray

const DD = DimensionalData

end
