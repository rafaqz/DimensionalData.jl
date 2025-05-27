
# Extending DimensionalData {#Extending-DimensionalData}

Nearly everything in DimensionalData.jl is designed to be extensible.
- `AbstractDimArray` is easily extended to custom array types. `Raster` or `YAXArray` are examples from other packages.
  
- `AbstractDimStack` is easily extended to custom mixed array datasets.   `RasterStack` or `ArViZ.Dataset` are examples.
  
- `Lookup` can have new types added, e.g. to `AbstractSampled` or `AbstractCategorical`. For example, `Rasters.Projected` is a lookup that knows its coordinate reference system, but otherwise behaves as a regular `Sampled` lookup.
  

`dims`, `rebuild` and `format` are the key interface methods in most of these cases.

## `dims` {#dims}

Objects extending DimensionalData.jl that have dimensions must return  a `Tuple` of constructed `Dimension`s from `dims(obj)`, like `(X(), Y())`.

### `Dimension` axes {#Dimension-axes}

Dimensions returned from `dims` should hold a `Lookup` or in some cases  just an `AbstractArray` (like with `DimIndices`). When attached to  multi-dimensional objects, lookups must be the _same length_ as the axis  of the array it represents, and `eachindex(A, i)` and `eachindex(dim)` must  return the same values. 

This means that if the array has OffsetArrays.jl axes, the array the dimension  wraps must also have OffsetArrays.jl axes.

### `dims` keywords {#dims-keywords}

To any `dims` keyword argument that usually requires the dimension I, objects should accept any `Dimension`, `Type{<:Dimension}`, `Symbol`, `Val{:Symbol}`, `Val{<:Type{<:Dimension}}` or also regular `Integer`. 

This is easier than it sounds, calling `DD.dims(objs, dims)` will return the matching dimension and `DD.dimnum(obj, dims)` will return the matching `Int` for any of these inputs as long as `dims(obj)` is implemented.

## `rebuild` {#rebuild}

Rebuild methods are used to rebuild immutable objects with new field values, in a more flexible and extensible way than just using ConstructionBase.jl reconstruction. Developers can choose to ignore some of the fields passed by `rebuild`.

The function signature is always one of:

```julia
rebuild(obj, args...)
rebuild(obj; kw...)
```


`rebuild` has keyword versions automatically generated for all objects using [ConstructionBase.jl](https://github.com/JuliaObjects/ConstructionBase.jl). 

These will work without further work as long as your object has the fields  used by DimensionalData.jl objects. For example, `AbstractDimArray` will  receive these keywords in `rebuild`: `data`, `dims`, `refdims`, `name`, `metadata`. 

If your `AbstractDimArray` does not have all these fields, you must implement `rebuild(x::YourDimArray; kw...)` manually.

An argument method is also defined with the same arguments as the  keyword version. For `AbstractDimArray` it should only be used for  updating `data` and `dims`, any more that that is confusing.

For `Dimension` and `Selector` the single argument versions are easiest to use,  as there is only one argument.

## `format` {#format}

When constructing an `AbstractDimArray` or `AbstractDimStack`  [`DimensionalData.format`](/api/dimensions#DimensionalData.Dimensions.format) must be called on the `dims` tuple and the parent array:

```julia
format(dims, array)
```


This lets DimensionalData detect the lookup properties, fill in missing fields of a `Lookup`, pass keywords from `Dimension` to detected `Lookup`  constructors, and accept a wider range of dimension inputs like tuples of `Symbol`  and `Type`.  The way you indicate that something needs to be filled is by using the `Auto` types, like `AutoOrder`](@ref) or `AutoSampling`.

Not calling `format` in the outer constructors of an `AbstractDimArray` has undefined behaviour.

When creating lookup types, you need to define `DimensionalData.format` on your lookup type.

## Interfaces.jl interface testing {#Interfaces.jl-interface-testing}

DimensionalData defines explicit, testable Interfaces.jl interfaces: `DimArrayInterface` and `DimStackInterface`.

::: tabs

== array

This is the implementation definition for `DimArray`:

```julia
julia> using DimensionalData, Interfaces

julia> @implements DimensionalData.DimArrayInterface{(:refdims,:name,:metadata)} DimArray [rand(X(10), Y(10)), zeros(Z(10))]


```


See the [`DimensionalData.DimArrayInterface`](/api/reference#DimensionalData.DimArrayInterface) docs for options. We can test it with:

```julia
julia> Interfaces.test(DimensionalData.DimArrayInterface)
```

```ansi

Testing [34mDimArrayInterface[39m is implemented for [34mDimArray[39m

[90mMandatory components[39m
[35mdims[39m: (defines a `dims` method [[32mtrue[39m, [32mtrue[39m],
       dims are updated on getindex [[32mtrue[39m, [32mtrue[39m])
[35mrefdims_base[39m: `refdims` returns a tuple of Dimension or empty [[32mtrue[39m, [32mtrue[39m]
[35mndims[39m: number of dims matches dimensions of array [[32mtrue[39m, [32mtrue[39m]
[35msize[39m: length of dims matches dimensions of array [[32mtrue[39m, [32mtrue[39m]
[35mrebuild_parent[39m: rebuild parent from args [[32mtrue[39m, [32mtrue[39m]
[35mrebuild_dims[39m: rebuild paaarnet and dims from args [[32mtrue[39m, [32mtrue[39m]
[35mrebuild_parent_kw[39m: rebuild parent from args [[32mtrue[39m, [32mtrue[39m]
[35mrebuild_dims_kw[39m: rebuild dims from args [[32mtrue[39m, [32mtrue[39m]
[35mrebuild[39m: all rebuild arguments and keywords are accepted [[32mtrue[39m, [32mtrue[39m]

[90mOptional components[39m
[35mrefdims[39m: (refdims are updated in args rebuild [[32mtrue[39m, [32mtrue[39m],
          refdims are updated in kw rebuild [[32mtrue[39m, [32mtrue[39m],
          dropped dimensions are added to refdims [[32mtrue[39m, [32mtrue[39m])
[35mname[39m: (rebuild updates name in arg rebuild [[32mtrue[39m, [32mtrue[39m],
       rebuild updates name in kw rebuild [[32mtrue[39m, [32mtrue[39m])
[35mmetadata[39m: (rebuild updates metadata in arg rebuild [[32mtrue[39m, [32mtrue[39m],
           rebuild updates metadata in kw rebuild [[32mtrue[39m, [32mtrue[39m])

Implementation summary:
[33m  DimArray[39m correctly implements [34mDimensionalData.DimArrayInterface: [39m[32mtrue[39m
true
```


== stack

The implementation definition for `DimStack`:

```julia
julia> @implements DimensionalData.DimStackInterface{(:refdims,:metadata)} DimStack [DimStack(zeros(Z(10))), DimStack(rand(X(10), Y(10))), DimStack(rand(X(10), Y(10)), rand(X(10)))]


```


See the [`DimensionalData.DimStackInterface`](/api/reference#DimensionalData.DimStackInterface) docs for options. We can test it with:

```julia
julia> Interfaces.test(DimensionalData.DimStackInterface)
```

```ansi

Testing [34mDimStackInterface[39m is implemented for [34mDimStack[39m

[90mMandatory components[39m
[35mdims[39m: (defines a `dims` method [[32mtrue[39m, [32mtrue[39m, [32mtrue[39m],
       dims are updated on getindex [[32mtrue[39m, [32mtrue[39m, [32mtrue[39m])
[35mrefdims_base[39m: `refdims` returns a tuple of Dimension or empty [[32mtrue[39m, [32mtrue[39m, [32mtrue[39m]
[35mndims[39m: number of dims matches ndims of stack [[32mtrue[39m, [32mtrue[39m, [32mtrue[39m]
[35msize[39m: length of dims matches size of stack [[32mtrue[39m, [32mtrue[39m, [32mtrue[39m]
[35mrebuild_parent[39m: rebuild parent from args [[32mtrue[39m, [32mtrue[39m, [32mtrue[39m]
[35mrebuild_dims[39m: rebuild paaarnet and dims from args [[32mtrue[39m, [32mtrue[39m, [32mtrue[39m]
[35mrebuild_layerdims[39m: rebuild paaarnet and dims from args [[32mtrue[39m, [32mtrue[39m, [32mtrue[39m]
[35mrebuild_dims_kw[39m: rebuild dims from args [[32mtrue[39m, [32mtrue[39m, [32mtrue[39m]
[35mrebuild_parent_kw[39m: rebuild parent from args [[32mtrue[39m, [32mtrue[39m, [32mtrue[39m]
[35mrebuild_layerdims_kw[39m: rebuild parent from args [[32mtrue[39m, [32mtrue[39m, [32mtrue[39m]
[35mrebuild[39m: all rebuild arguments and keywords are accepted [[32mtrue[39m, [32mtrue[39m, [32mtrue[39m]

[90mOptional components[39m
[35mrefdims[39m: (refdims are updated in args rebuild [[32mtrue[39m, [32mtrue[39m, [32mtrue[39m],
          refdims are updated in kw rebuild [[32mtrue[39m, [32mtrue[39m, [32mtrue[39m],
          dropped dimensions are added to refdims [[32mtrue[39m, [32mtrue[39m, [32mtrue[39m])
[35mmetadata[39m: (rebuild updates metadata in arg rebuild [[32mtrue[39m, [32mtrue[39m, [32mtrue[39m],
           rebuild updates metadata in kw rebuild [[32mtrue[39m, [32mtrue[39m, [32mtrue[39m])

Implementation summary:
[33m  DimStack[39m correctly implements [34mDimensionalData.DimStackInterface: [39m[32mtrue[39m
true
```


:::
