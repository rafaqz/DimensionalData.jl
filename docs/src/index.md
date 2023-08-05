## DimensionalData

DimensionalData.jl provides tools and abstractions for working with datasets
that have named dimensions, and optionally a lookup index.

DimensionalData is a pluggable, generalised version of
[AxisArrays.jl](https://github.com/JuliaArrays/AxisArrays.jl) with a cleaner
syntax, and additional functionality found in NamedDims.jl. It has similar goals
to pythons [xarray](http://xarray.pydata.org/en/stable/), and is primarily
written for use with spatial data in [Rasters.jl](https://github.com/rafaqz/Rasters.jl).

## Goals
!!! info ""

    - Clean, readable syntax. Minimise required parentheses, minimise of exported
    - Zero-cost dimensional indexing `a[Y(4), X(5)]` of a single value.
      methods, and instead extend Base methods whenever possible.
    - Plotting is easy: data should plot sensibly and correctly with useful labels, by default.
    - Least surprise: everything works the same as in Base, but with named dims. If
      a method accepts numeric indices or `dims=X` in base, you should be able to
      use DimensionalData.jl dims.
    - Minimal interface: implementing a dimension-aware type should be easy.
    - Maximum extensibility: always use method dispatch. Regular types over special
      syntax. Recursion over @generated. Always dispatch on abstract types.
    - Type stability: dimensional methods should be type stable _more often_ than Base methods
    - Functional style: structs are always rebuilt, and other than the array data,
      fields are not mutated in place.

## For package developers

## Data types and the interface

DimensionalData.jl provides the concrete `DimArray` type. But its
behaviours are intended to be easily applied to other array types.

```@raw html
??? question "more"

    The main requirement for extending DimensionalData.jl is to define a `dims` method
    that returns a `Tuple` of `Dimension` that matches the dimension order
    and axis values of your data. Define `rebuild` and base methods for `similar`
    and `parent` if you want the metadata to persist through transformations (see
    the `DimArray` and `AbstractDimArray` types). A `refdims` method
    returns the lost dimensions of a previous transformation, passed in to the
    `rebuild` method. `refdims` can be discarded, the main loss being plot labels
    and ability to reconstruct dimensions in `cat`.

    Inheriting from `AbstractDimArray` in this way will give nearly all the functionality
    of using `DimArray`.
```

## LookupArrays and Dimensions

Sub modules `LookupArrays` and `Dimensions` define the behviour of
dimensions and their lookup index.

[`LookupArrays`](@ref) and [`Dimensions`](@ref)
