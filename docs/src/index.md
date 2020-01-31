# Introduction

Dimensional.jl is a Julia package for using Julia arrays (or other `AbstractArray` types) along with indexable named dimensions.
We further provide several convenient selectors that allow you to select each dimension of your array by the value of the dimension (e.g. selecting all points near given values, see below).

DimensionalData.jl provides tools and abstractions for working with datasets that have named dimensions with positional values.
It's a pluggable, generalised version of [AxisArrays.jl](https://github.com/JuliaArrays/AxisArrays.jl) with a cleaner syntax, and additional functionality found in NamedDimensions.jl.
It has similar goals to Python's [xarray](http://xarray.pydata.org/en/stable/).

!!! warn
    DimensionalData.jl is currently under active development.
    It may be a while before the interface stabilises and things are fully documented.
    Please report bugs or cluncky interfaces on GitHub.

# Crash course
This is brief a tutorial for DimensionalData.jl.
All main functionality is explained here, but the full list of features is listed at the [API](@ref) page.

## Dimensions and DimensionalArrays
The core type of DimensionalData.jl is [`DimensionalArray`](@ref), which bundles a standard array with dimensions.
The dimensions are in the form of an [`AbstractDimension`](@ref), and types that inherit from it, such as `Time`, `X`, `Y`, `Z`, the generic `Dim{:x}` or others you define manually using the [`@dim`](@ref) macro.
A `DimensionalArray` is constructed by passing the data and the dimensions like so
```@example
using Dates, DimensionalData
using DimensionalData: Time, X
timespan = DateTime(2001):Month(1):DateTime(2001,12)
```
Here both `X` and `Time` are already created dimensions from within the `DimensionalData` module. We use them now to make a `DimensionalArra`:
```@example
A = DimensionalArray(rand(12,10), (Time(timespan), X(10:10:100)))
```

These dimensions (here `X, Time`) can then be used to index the array by name, without having to worry about the order of the dimensions.
For example, simple index-based access of `A` at let's say every 2 points of the `Time` dimension and every 3rd point of the `X` dimension happens like so:
```@example
A[Time(1:2:end), X(1:3:end)]
```

!!! info "Indexing"
    All indexing on `DimensionalArray`s works with `getindex` (the above example), `setindex!` as well as `view`. In addition, indexing like this always preserves the nature of the data, i.e. the result is still a `DimensionalArray`.

## Selecting by value
The above example is useful because one does not have to care about the ordering of the dimensions.
But much more useful is to be able to select a dimension by value.
For example, we would like to get all values of `A` where the `X` dimension is between two values.
This is done with the so-called selectors, all of which are listed in the [Selectors](@ref) page.
For simplicity, here we showcase the [`Between`](@ref) selector but many others exist, like [`At`](@ref) or [`Near`](@ref).
```@example
A[X <| Between(12, 35), Time <| Between(Date(2001,5), Date(2001, 7))]
```
Notice that the selectors have to be applied to a dimension (here we use the notation `x <| f`, which literally translates to `f(x)`).

## Selecting by position
Selection, including all selector function, also works by position (when the target dimension is not specified).
I.e. if `X, Y` are the two dimensions of `A` (in order), then `A[At([1, 2]), At([4, 5])]` , `A[X <| At([1, 2]), Y <| At([4, 5])]` and `A[Y <| At([4, 5]), X <| At([1, 2])]` are all equivalent.
When selecting by position applying the selector to a target dimension is not necessary, as is evident by the expression `A[At([1, 2]), At([4, 5])]`.

When PR#48 is done, this section will be updated.

## Specifying `dim` by dimension name
In many Julia functions, like e.g. `size, sum` etc., one can specify the dimension (as an integer) along which to perform the operation.
It is possible to do this for `DimensionalArray` by specifying the dimension by its name (its Type actually), for example
```@docs
sum(A, dims = X)
```
(both dimensions of `A` need to be kept, as the standard Julia functions also keep the extra dimensions, but make them singular). All methods that have been extended to support this are listed in the [Methods with dim keyword](@ref) section.


## Referenced dimensions
Here @rafaqz needs to write, because I really don't know refdims... :)

## Grid functionality
Here @rafaqz needs to write, because I really don't know grids... :)



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
