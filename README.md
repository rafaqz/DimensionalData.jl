# DimensionalData

[![Build Status](https://travis-ci.com/rafaqz/DimensionalData.jl.svg?branch=master)](https://travis-ci.com/rafaqz/DimensionalData.jl)
[![Codecov](https://codecov.io/gh/rafaqz/DimensionalData.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/rafaqz/DimensionalData.jl)

Add named dimensions to Julia data types. This is a work in progress
under active development, it may be a while before the interface stabilises and
things are fully documented.


DimensionalData.jl provides tools and abstractions for working with datasets
that have named dimensions. It's a pluggable, generalised version of
[AxisArrays.jl](https://github.com/JuliaArrays/AxisArrays.jl) with a cleaner
syntax. It has similar goals to pythons [xarray](http://xarray.pydata.org/en/stable/).

The core component is the `AbstractDimension`, and types that inherit from it,
such as `Time`, `Lat`, `Lon`, `Vert`, the generic `Dim{:x}` or others you
define manually using the `@dim` macro.

These can be used to select data from dimensional arrays: `select(a,
Time(DateTime(2002, 08)))`, for indexing and views without knowing dimension
order: `a[Lon(20)]`, `view(a, Lon(1:20), Lat(30:40))`  and for indicating
dimesions to reduce `mean(a, dims=Time)`, or permute `permutedims(a, [Long, Lat,
Vert, Time])`.

# For package developers

Goals:
- Flexibility: types are all parametric, new functionality is easy to add 
- Abstraction: never dispatch on concrete types, maximum reusability of methods
- Minimal interface: implementing a dimension aware type should be very easy.
- Metadata: everything has a metadata field (that defaults to `nothing`).
- Functional style: structs are always rebuild, and other than the array data, 
  fields are never mutated


Array dimensions use the same types that are used for indexing. The `dims(a)`
method should return a tuple something like this:

```julia
(Lat(-40.5:40.5, Dict(units=>"degrees_north"), Lon(1.0:40.0, Dict(units=>"degrees_east"))`) 
```

either stored or generated from other data (obviously storing them will be
faster). The metadata can be anything, but some standards will be introduced as
they are worked out.


DimensionalData.jl provides the `DimenstionalArray` type. But its
real focus is to be easily used with existing types.

Some of the functionality in DimensionalData.jl will work without inheriting
from `AbstractDimensionalArray`. The main requirement define a `dims` method
that returns a `Tuple` of `AbstractDimension` that matches the dimension order
and axis values of your data. Define `rebuild`, and base methods for `similar`
and `parent` if you want the metadata to persist through transformations (see
the `DimensionalArray` and `AbstractDimensionalArray` types). A `refdims` method
returns the lost dimensions of a previous transformation, past in to the
`rebuild` method. Refdims can be discarded, the main loss being plot labels.

Inheriting from `AbstractDimensionalArray` will give a few benefits, such as
methods currently blocked by problems with `dims` dispatch in julia Base, and
indexing using regular integer dimensions but updating your wrapper type with
new dims. 

New dimensions can be generated with the `@dim` macro  at top level scope:

```julia
@dim Cloud "Cloud cover"
```

Dims have val and metadata fields, each of which accept any type for maximum
flexibility. `dims(x)` should return a tuple of dimensions that contain types
that represent the dimension of the data - vectors, ranges or a tuple of end
points. `Tuple` and `UnitRange` are converted to `LinRange` by `formatdims`.
