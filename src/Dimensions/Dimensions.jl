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

import Adapt, ConstructionBase, Extents
using Dates 

include("../LookupArrays/LookupArrays.jl")

using .LookupArrays

const LA = LookupArrays

import .LookupArrays: rebuild, order, span, sampling, locus, val, index, set, _set,
    metadata, bounds, intervalbounds, units, basetypeof, unwrap, selectindices, hasselection,
    shiftlocus, maybeshiftlocus, SelectorOrInterval, Interval
using .LookupArrays: StandardIndices, SelTuple, CategoricalEltypes,
    LookupArrayTrait, AllMetadata, LookupArraySetters

using Base: tail, OneTo, @propagate_inbounds

export name, label, dimnum, hasdim, hasselection, otherdims, commondims, combinedims,
    setdims, swapdims, sortdims, lookup, set, format, rebuild, key2dim, dim2key,
    basetypeof, basedims, dimstride, dims2indices, slicedims, dimsmatch, comparedims, reducedims

export Dimension, IndependentDim, DependentDim, XDim, YDim, ZDim, TimeDim,
    X, Y, Z, Ti, Dim, AnonDim, Coord, MergedLookup, AutoVal

export @dim

include("dimension.jl")
include("dimunitrange.jl")
include("primitives.jl")
include("format.jl")
include("indexing.jl")
include("set.jl")
include("show.jl")
include("merged.jl")

end
