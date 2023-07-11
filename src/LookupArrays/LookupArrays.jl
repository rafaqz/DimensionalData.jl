"""
    LookupArrays

Module for [`LookupArrays`](@ref) and [`Selector`]s used in DimensionalData.jl

`LookupArrays` defines traits and `AbstractArray` wrappers
that give specific behaviours for a lookup index when indexed with [`Selector`](@ref).

For example, these allow tracking over array order so fast indexing works evne when 
the array is reversed.

To load LookupArrays types and methods into scope:

```julia
using DimensionalData
using DimensionalData.LookupArrays
```
"""
module LookupArrays

using Dates, IntervalSets, Extents
import Adapt, ConstructionBase

using Base: tail, OneTo, @propagate_inbounds

export order, sampling, span, bounds, locus, hasselection, transformdim,
    metadata, units, sort, selectindices, val, index, reducelookup, shiftlocus,
    maybeshiftlocus, intervalbounds

export Selector
export At, Between, Touches, Contains, Near, Where, All
export ..

export LookupArrayTrait
export Order, Ordered, ForwardOrdered, ReverseOrdered, Unordered, AutoOrder
export Sampling, Points, Intervals, AutoSampling, NoSampling
export Span, Regular, Irregular, Explicit, AutoSpan, NoSpan
export Locus, Center, Start, End, AutoLocus
export Metadata, NoMetadata
export AutoStep, AutoBounds, AutoIndex

export LookupArray
export AutoLookup, NoLookup
export Aligned, AbstractSampled, Sampled, AbstractCategorical, Categorical
export Unaligned, Transformed

const StandardIndices = Union{AbstractArray{<:Integer},Colon,Integer,CartesianIndex,CartesianIndices}

rebuild(x; kw...) = ConstructionBase.setproperties(x, (; kw...))

include("metadata.jl")
include("lookup_traits.jl")
include("lookup_arrays.jl")
include("selector.jl")
include("indexing.jl")
include("methods.jl")
include("utils.jl")
include("set.jl")
include("show.jl")

end
