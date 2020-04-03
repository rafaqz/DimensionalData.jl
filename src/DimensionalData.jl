module DimensionalData

# Use the README as the module docs
@doc let
    path = joinpath(dirname(@__DIR__), "README.md")
    include_dependency(path)
    read(path, String)
end DimensionalData

using Base.Broadcast:
    Broadcasted, BroadcastStyle, DefaultArrayStyle, AbstractArrayStyle, Unknown

using ConstructionBase, LinearAlgebra, RecipesBase, Statistics, Dates

using Base: tail, OneTo


export Dimension, IndependentDim, DependentDim, XDim, YDim, ZDim, TimeDim, 
       X, Y, Z, Ti, ParametricDimension, Dim, AnonDim

export Selector, Between, At, Contains, Near

export Locus, Center, Start, End, AutoLocus, NoLocus

export Order, Ordered, Unordered, UnknownOrder, AutoOrder

export Sampling, Points, Intervals

export Span, Regular, Irregular, AutoSpan

export IndexMode, Auto, UnknownIndex, NoIndex

export Aligned, AbstractSampled, Sampled,
       AbstractCategorical, Categorical

export Unaligned, Transformed

export AbstractDimensionalArray, DimensionalArray

export data, dims, refdims, metadata, name, shortname,
       val, label, units, order, bounds, locus, mode, <|

export dimnum, hasdim, setdims, swapdims, rebuild

export @dim


include("interface.jl")
include("mode.jl")
include("dimension.jl")
include("array.jl")
include("selector.jl")
include("broadcast.jl")
include("methods.jl")
include("primitives.jl")
include("utils.jl")
include("plotrecipes.jl")
include("prettyprint.jl")

end
