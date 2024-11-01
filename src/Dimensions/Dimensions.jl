"""
    Dimensions

Sub-module for [`Dimension`](@ref)s wrappers,
and operations on them used in DimensionalData.jl.

To load `Dimensions` types and methods into scope:

```julia
using DimensionalData
using DimensionalData.Dimensions
```
"""
module Dimensions

import Adapt, ConstructionBase, Extents, IntervalSets
using Dates 

include("../Lookups/Lookups.jl")

using .Lookups

const LU = Lookups
const LookupArrays = Lookups

import .Lookups: rebuild, order, span, sampling, locus, val, index, set, _set,
    metadata, bounds, intervalbounds, units, basetypeof, unwrap, selectindices, hasselection,
    shiftlocus, maybeshiftlocus, ordered_first, ordered_last, ordered_firstindex, ordered_lastindex, 
    promote_first, _remove
using .Lookups: StandardIndices, SelTuple, CategoricalEltypes,
    LookupTrait, AllMetadata, LookupSetters, AbstractBeginEndRange,
    SelectorOrInterval, Interval

using Base: tail, OneTo, @propagate_inbounds

export name, label, dimnum, hasdim, hasselection, otherdims, commondims, combinedims,
    setdims, swapdims, sortdims, lookup, set, format, rebuild, name2dim,
    basetypeof, basedims, dims2indices, slicedims, dimsmatch, comparedims, reducedims

export Dimension, IndependentDim, DependentDim, XDim, YDim, ZDim, TimeDim,
    X, Y, Z, Ti, Dim, AnonDim, Coord, MergedLookup, AutoVal

export @dim

include("dimension.jl")
include("predicates.jl")
include("dimunitrange.jl")
include("primitives.jl")
include("format.jl")
include("indexing.jl")
include("set.jl")
include("show.jl")
include("merged.jl")

end
