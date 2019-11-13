"""
DimensionalData.jl provides types and methods for indexing with named dimensions,
using named dimensions in Base and Statistics methods instead of Integer dims,
and selecting data from dimension values instead of using indices directly.

## Dimensions

Dimensions are simply types that wrap values. They both store dimension values
and are used for dimension lookup or indices, ranges or dimension number.
`X`, `Y`, `Z` and `Time` are the unexported defaults, add this line to use them:  
```julia
using DimensionalData: X, Y, Z, Time
```

A generalised [`Dim`](@ref) type is available to use arbitrary symbols to name dimensions. 
Custom dimensions can be defined using the [`@dim`](@ref) macro.

We can use dim wrappers for indexing, so that the dimension order in the underlying array 
does not need to be known:

```
a[X(1:10), Y(1:4)]
```

## Selectors

Selectors find indices in the dimension based on values `At`, `Near`, or `Between`
the index value(s).

We can use selectors in conjuction with dim wrappers:

```julia
a[X(1:10), Y<|At(25.7)]
```

Without dim wrappers selectors must be in the right order:

```julia
usin Unitful
a[Near(23u"s"), Between(10.5u"m", 50.5u"m")]
```

Dim types or objects can be used instead of a dimension number in many 
Base and Statistics methods:

```julia
mean(a; dims=X)
std(a; dims=Y())
```

"""
module DimensionalData

using ConstructionBase, LinearAlgebra, RecipesBase, Statistics

using Base: tail, OneTo

export AbstractDimension, Dim

export Selector, Near, Between, At

export Locus, Center, Start, End, UnknownLocus

export Sampling, SingleSample, MultiSample, UnknownSampling

export Order, Ordered, Unordered

export Grid, UnknownGrid, IndependentGrid, AbstractAllignedGrid, AllignedGrid

export AbstractCategoricalGrid, CategoricalGrid 

export DependentGrid, TransformedGrid, LookupGrid

export AbstractDimensionalArray, DimensionalArray

export dims, refdims, metadata, name, shortname, 
       val, label, units, order, bounds, <|

include("interface.jl")
include("order.jl")
include("grid.jl")
include("dimension.jl")
include("selector.jl")
include("array.jl")
include("methods.jl")
include("primitives.jl")
include("utils.jl")
include("plotrecipes.jl")

end
