# DimensionalData

[![](https://img.shields.io/badge/docs-stable-blue.svg)](https://rafaqz.github.io/DimensionalData.jl/stable)
[![](https://img.shields.io/badge/docs-dev-blue.svg)](https://rafaqz.github.io/DimensionalData.jl/dev)
[![Build Status](https://travis-ci.org/rafaqz/DimensionalData.jl.svg?branch=master)](https://travis-ci.org/rafaqz/DimensionalData.jl)
[![Codecov](https://codecov.io/gh/rafaqz/DimensionalData.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/rafaqz/DimensionalData.jl)

Add named dimensions to Julia arrays and other types. This is a work in progress
under active development, it may be a while before the interface stabilises and
things are fully documented.

DimensionalData.jl provides tools and abstractions for working with datasets
that have named dimensions with positional values. It's a pluggable, generalised
version of [AxisArrays.jl](https://github.com/JuliaArrays/AxisArrays.jl) with a
cleaner syntax, and additional functionality found in NamedDimensions.jl. It has
similar goals to pythons [xarray](http://xarray.pydata.org/en/stable/), and is
primarily written for use with spatial data in
[GeoData.jl](https://github.com/rafaqz/GeoData.jl).

## Dimensions

The core component is the `AbstractDimension`, and types that inherit from it,
such as `Time`, `X`, `Y`, `Z`, the generic `Dim{:x}` or others you
define manually using the `@dim` macro.

Dims can be used for indexing and views without knowing dimension order:
`a[X(20)]`, `view(a, X(1:20), Y(30:40))` and for indicating dimesions to reduce
`mean(a, dims=Time)`, or permute `permutedims(a, [X, Y, Z, Time])` in julia
`Base` and `Statistics` functions that have dims arguments.


## Selectors

Selectors can be used in `getindex`, `setindex!` and `view` to select
indices matching the passed in value(s)

- `At(x)` : get indices exactly matching the passed in value(s)
- `Near(x)` : get the closest indices to the passed in value(s)
- `Between(a, b)` : get all indices between two values (inclusive)

It's easy to add your own custom `Selector` if your need a different behaviour.

_Example usage:_

```julia
using Dates, DimensionalData
using DimensionalData: Time, X
timespan = DateTime(2001):Month(1):DateTime(2001,12)
A = DimensionalArray(rand(12,10), (Time(timespan), X(10:10:100))) 
A[X<|Near([12, 35]), Time<|At(DateTime(2001,5))]
A[Near(DateTime(2001, 5, 4)), Between(20, 50)]
```


## Methods where dims can be used containing indices or Selectors

- `getindex`
- `setindex!`
- `view`

## Methods where dims can be used instead of integer dims, as `X()` or just the type `X`

- `size`
- `axes`
- `permutedims`
- `mapslices`
- `eachslice`
- `reverse`
- `dropdims`
- `reduce`
- `mapreduce`
- `sum`
- `prod`
- `maximum`
- `minimum`
- `mean`
- `std `
- `var`
- `cor`
- `cov`
- `median`

_Example usage:_

```julia
size(a, Time)

mean(a, dims=X)
```



# For package developers

## Goals:

- Maximum extensibility: always use method dispatch. Regular types over special
  syntax. Recursion over @generated.
- Flexibility: dims and selectors are parametric types with multiple uses
- Abstraction: never dispatch on concrete types, maximum re-usability of methods
- Clean, readable syntax. Minimise required parentheses, minimise of exported
  methods, and instead extend Base methods whenever possible.
- Minimal interface: implementing a dimension-aware type should be easy.
- Functional style: structs are always rebuilt, and other than the array data,
  fields are not mutated in place.
- Least surprise: everything works the same as in Base, but with named dims. If
  a method accepts numeric indices or `dims=X` in base, you should be able to
  use DimensionalData.jl dims.
- Type stability: dimensional methods should be type stable _more often_ than Base methods
- Zero cost dimensional indexing `a[Y(4), X(5)]` of a single value.
- Low cost indexing for range getindex and views: these cant be zero cost as dim
  ranges have to be updated.
- Plotting is easy: data should plot sensibly and correctly with useful labels -
  after all transformations using dims or indices
- Prioritise spatial data: other use cases are a free bonus of the modular
  approach.

## Why this package

Why not [AxisArrays.jl](https://github.com/JuliaArrays/AxisArrays.jl) or
[NamedDims.jl](https://github.com/invenia/NamedDims.jl/)? 

### Structure

Both AxisArrays and NamedDims use concrete types for dispatch on arrays, and for
dimension type `Axis` in AxisArrays. This makes them hard to extend. 

Its a little easier with DimensionalData.jl. You can inherit from
`AbstractDimensionalArray`, or just implement `dims` and `rebuild` methods. Dims
and selectors in DimensionalData.jl are also extensible. Recursive primitive
methods allow inserting whatever methods you want to add extra types.
`@generated` is only used to match and permute arbitrary tuples of types, and
contain no type-specific details. The `@generated` functions in AxisArrays
internalise axis/index conversion behaviour preventing extension in external
packages and scripts.

### Syntax

AxisArrays.jl is verbose by default: `a[Axis{:y}(1)]` vs `a[Y(1)]` used here.
NamedDims.jl has concise syntax, but the dimensions are no longer types.


## Data types and the interface

DimensionalData.jl provides the concrete `DimenstionalArray` type. But it's
core purpose is to be easily used with other array types.

Some of the functionality in DimensionalData.jl will work without inheriting
from `AbstractDimensionalArray`. The main requirement define a `dims` method
that returns a `Tuple` of `AbstractDimension` that matches the dimension order
and axis values of your data. Define `rebuild`, and base methods for `similar`
and `parent` if you want the metadata to persist through transformations (see
the `DimensionalArray` and `AbstractDimensionalArray` types). A `refdims` method
returns the lost dimensions of a previous transformation, passed in to the
`rebuild` method. Refdims can be discarded, the main loss being plot labels.

Inheriting from `AbstractDimensionalArray` will give a few benefits, such as
methods currently blocked by problems with `dims` dispatch in Julia Base, and
indexing using regular integer dimensions but updating your wrapper type with
new dims. 


New dimensions can be generated with the `@dim` macro  at top level scope:

```julia
@dim Band "Raster band"
```

Dimensions use the same types that are used for indexing. The `dims(a)`
method should return a tuple something like this:

```julia
(Y(-40.5:40.5, (units="degrees_north",), X(1.0:40.0, (units="degrees_east",))`) 
```

either stored or generated from other data. The metadata can be anything,
preferably in a `NamedTuple`. Some standards may be introduced as they are
worked out over time.
