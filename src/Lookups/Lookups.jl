"""
    Lookups

Module for [`Lookup`](@ref)s and [`Selector`](@ref)s used in DimensionalData.jl

`Lookup` defines traits and `AbstractArray` wrappers
that give specific behaviours for a lookup index when indexed with [`Selector`](@ref).

For example, these allow tracking over array order so fast indexing works even when 
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

export order, sampling, span, bounds, dim,
    metadata, units, sort, val, locus, intervalbounds

export hasselection, selectindices

export reducelookup, shiftlocus, maybeshiftlocus, promote_first

# Deprecated
export index

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
export Position, Locus, Center, Start, End, AutoLocus, AutoPosition
export Metadata, NoMetadata
export AutoStep, AutoBounds, AutoValues

export Lookup
export AutoLookup, AbstractNoLookup, NoLookup
export Aligned, AbstractSampled, Sampled, AbstractCyclic, Cyclic, AbstractCategorical, Categorical
export Unaligned, Transformed

# Deprecated
export LookupArray

const StandardIndices = Union{AbstractArray{<:Integer},Colon,Integer,CartesianIndex,CartesianIndices}

# As much as possible keyword rebuild is automatic
rebuild(x; kw...) = ConstructionBase.setproperties(x, (; kw...))

include("metadata.jl")
include("lookup_traits.jl")
include("lookup_arrays.jl")
include("predicates.jl")
include("selector.jl")
include("beginend.jl")
include("indexing.jl")
include("methods.jl")
include("utils.jl")
include("set.jl")
include("show.jl")

end
