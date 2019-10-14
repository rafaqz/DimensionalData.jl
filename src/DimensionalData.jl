"""
DimensionalData.jl provides types and methods for indexing with named dimensions,
using named dimensions in Base and Statistics methods instead of Integer dims,
and selecting data from dimension values instead of using indices directly.

Dimensions are simply types that wrap values. They both store dimension values
and are used for dimension lookup or indices, ranges or dimension number.
`X`, Y`, `Z` and `Time` are the unexported defaults, add this line to use them:  
```julia
using DimensionalData: X, Y, Z, Time
```

Selectors find indices in the dimension based on values `At`, `Near`, or `Between`
the passed in value(s).

These are some examples of valid syntax:

```julia
# Indexing with dim wrappers
a[X(1:10), Y(1:4)]
# Dim wrappers and a selector
a[X(1:10), Y<|At(25.7)]
# Unitful.jl selectors. Without dim wrappers selectors must be in the right order
a[Near(23"s"), Between(10.5u"m", 50.5u"m")]
# Dim type used instead of a dimension number
mean(a; dims=X)
```
"""
module DimensionalData

using RecipesBase, Statistics, LinearAlgebra

using Base: tail, OneTo

export AbstractDimension, Dim

export Selector, Near, Between, At

export Order

export AbstractDimensionalArray, DimensionalArray

export dims, refdims, metadata, name, shortname, 
       val, label, units, order, bounds, <|

include("interface.jl")
include("order.jl")
include("dimension.jl")
include("selector.jl")
include("array.jl")
include("methods.jl")
include("primitives.jl")
include("utils.jl")
include("plotrecipes.jl")

end
