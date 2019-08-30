# DimensionalData

[![Build Status](https://travis-ci.org/rafaqz/DimensionalData.jl.svg?branch=master)](https://travis-ci.org/rafaqz/DimensionalData.jl)
[![Codecov](https://codecov.io/gh/rafaqz/DimensionalData.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/rafaqz/DimensionalData.jl)

Add named dimensions to Julia arrays and other types. This is a work in progress
under active development, it may be a while before the interface stabilises and
things are fully documented.

DimensionalData.jl provides tools and abstractions for working with datasets
that have named dimensions. It's a pluggable, generalised version of
[AxisArrays.jl](https://github.com/JuliaArrays/AxisArrays.jl) with a cleaner
syntax. It has similar goals to pythons
[xarray](http://xarray.pydata.org/en/stable/), and is primarily written for use
with spatial data in [GeoData.jl](https://github.com/rafaqz/GeoData.jl).


The core component is the `AbstractDimension`, and types that inherit from it,
such as `Time`, `X`, `Y`, `Z`, the generic `Dim{:x}` or others you
define manually using the `@dim` macro.

Dims can be used to select data from dimensional arrays: `select(a,
Time(DateTime(2002, 08)))`, for indexing and views without knowing dimension
order: `a[X(20)]`, `view(a, X(1:20), Y(30:40))`  and for indicating
dimesions to reduce `mean(a, dims=Time)`, or permute `permutedims(a, [X, Y,
Z, Time])` in julia `Base` and `Statistics` functions that have dims
arguments.

# For package developers

## Goals:

- Flexibility: types are all parametric, new functionality is easy to add 
- Abstraction: never dispatch on concrete types, maximum re-usability of methods
- Minimal interface: implementing a dimension-aware type should be very easy.
- Functional style: structs are always rebuilt, and other than the array data,
  fields are not mutated in place.
- Zero cost dimensional indexing `a[Y(4), X(5)]` of a single value. This is
  very important for use in simulations.
- Low cost for range getindex and views: these cant be zero as dim ranges have
  to be updated for plots to be accurate.
- Plots are easy: data should plot sensibly with useful labels
- Least surprise: everything works the same as in Base, but with dim wrappers.
  If you can use `dims` in base, you can probably use DimensionalData dims.
- Prioritise spatial data, as in xarray: other use cases are a free bonus of the
  modular approach, but will be supported as much as possible.

## Why this package

Why not [AxisArrays.jl](https://github.com/JuliaArrays/AxisArrays.jl) or
[NamedDims.jl](https://github.com/invenia/NamedDims.jl/)? 

### Structure

Both AxisArrays and NamedDims use concrete types for dispatch on arrays, and for
dimension type in AxisArrays. This makes them harder to extend. In contrast its 
easy to inherit from AbstractDimensionalArray or just implement `dims` and
`rebuild` and add a `dims` field to a type.

### Syntax

AxisArrays is verbose: `a[Axis{:y}(1)]` vs `a[Y(1)]` used here. NamedDims
has nice syntax, but the dimensions are no longer types. Again this makes it harder to
extend the package, and makes performance depend on the dark art of constant
propagation, instead of relatively simple `@generated` functions and recursion
that predictably compiles away.

## Data types and the interface

DimensionalData.jl provides the `DimenstionalArray` type. But its
real focus is to be easily used with existing types.

Some of the functionality in DimensionalData.jl will work without inheriting
from `AbstractDimensionalArray`. The main requirement define a `dims` method
that returns a `Tuple` of `AbstractDimension` that matches the dimension order
and axis values of your data. Define `rebuild`, and base methods for `similar`
and `parent` if you want the metadata to persist through transformations (see
the `DimensionalArray` and `AbstractDimensionalArray` types). A `refdims` method
returns the lost dimensions of a previous transformation, passed in to the
`rebuild` method. Refdims can be discarded, the main loss being plot labels.

Inheriting from `AbstractDimensionalArray` will give a few benefits, such as
methods currently blocked by problems with `dims` dispatch in julia Base, and
indexing using regular integer dimensions but updating your wrapper type with
new dims. 

New dimensions can be generated with the `@dim` macro  at top level scope:

```julia
@dim Band "Raster band"
```

Dimensions use the same types that are used for indexing. The `dims(a)`
method should return a tuple something like this:

```julia
(Y(-40.5:40.5, (units="degrees_north"), X(1.0:40.0, (units="degrees_east"))`) 
```

either stored or generated from other data. The metadata can be anything,
preferably in a NamedTuple. Some standards may be introduced as they are worked
out over time.
