"""
    Lookups

Module for [`Lookup`](@ref)s and [`Selector`](@ref)s used in DimensionalData.jl

`Lookup` defines traits and `AbstractArray` wrappers
that give specific behaviours for a lookup index when indexed with [`Selector`](@ref).

For example, these allow tracking over array order so fast indexing works evne when 
the array is reversed.

To load `Lookup` types and methods into scope:

```julia
using DimensionalData
using DimensionalData.Lookups
```
"""
module Lookups

using Dates, IntervalSets, Extents
import Adapt, ConstructionBase
import InvertedIndices

using InvertedIndices: Not
using Base: tail, OneTo, @propagate_inbounds

export order, sampling, span, bounds, locus, hasselection, transformdim,
    metadata, units, sort, selectindices, val, index, reducelookup, shiftlocus,
    maybeshiftlocus, intervalbounds

export issampled, iscategorical, iscyclic, isnolookup, isintervals, ispoints, isregular,
    isexplicit, isstart, iscenter, isend, isordered, isforward, isreverse

export Selector
export At, Between, Touches, Contains, Near, Where, All
export ..
export Not

export LookupTrait
export Order, Ordered, ForwardOrdered, ReverseOrdered, Unordered, AutoOrder
export Sampling, Points, Intervals, AutoSampling, NoSampling
export Span, Regular, Irregular, Explicit, AutoSpan, NoSpan
export Locus, Center, Start, End, AutoLocus
export Metadata, NoMetadata
export AutoStep, AutoBounds, AutoIndex

export Lookup
export AutoLookup, NoLookup
export Aligned, AbstractSampled, Sampled, AbstractCyclic, Cyclic, AbstractCategorical, Categorical
export Unaligned, Transformed

const StandardIndices = Union{AbstractArray{<:Integer},Colon,Integer,CartesianIndex,CartesianIndices}

# As much as possible keyword rebuild is automatic
rebuild(x; kw...) = ConstructionBase.setproperties(x, (; kw...))

include("metadata.jl")
include("lookup_traits.jl")
include("lookup_arrays.jl")
include("predicates.jl")
include("selector.jl")
include("indexing.jl")
include("methods.jl")
include("utils.jl")
include("set.jl")
include("show.jl")

end
