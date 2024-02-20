# Extending DimensionalData

Nearly everything in DimensionalData.jl is designed to be extensible.

- `AbstractDimArray` are easily extended to custom array types. `Raster` or
  `YAXArray` are examples from other packages.
- `AbstractDimStack` are easily extended to custom mixed array dataset.
    `RasterStack` or `ArViZ.Dataset` are examples.
- `LookupArray` can have new types added, e.g. to `AbstractSampled` or
  `AbstractCategorical`. `Rasters.Projected` is a lookup that knows
  its coordinate reference system, but otherwise behaves as a regular
  `Sampled` lookup.

`dims`, `rebuild` and `format` are the key interface methods in most of these cases.

## `dims`

Objects extending DimensionalData.jl that have dimensions must return 
a `Tuple` of constructed `Dimension`s from `dims(obj)`. 

### `Dimension` axes

Dimensions return from `dims` should hold a `LookupArray` or in some cases 
just an `AbstractArray` (like wiht `DimIndices`). When attached to 
mullti-dimensional objects, lookups must be the _same length_ as the axis 
of the array it represents, and `eachindex(A, i)` and `eachindex(dim)` must 
return the same values. 

This means that if the array has OffsetArrays.jl axes, the array the dimension 
wraps must also have OffsetArrays.jl axes.

### `dims` keywords

To any `dims` keyword argument that only marks the dimension name,
objects should accept any `Dimension`, `Type{<:Dimension}`, `Symbol`,
`Val{:Symbol}`, `Val{<:Type{<:Dimension}}` or regular `Integer`. 
This is easier than it sounds, calling `DD.dims(objs, dims)` will
return the matching dimension and `DD.dimnum(obj, dims)` will return
the matching `Int` for any of these inputs as long as `dims(obj)` is
implemented.


## `rebuild`

Rebuild methods are used to rebuild immutable objects with new field values,
in a way that is more flexible and extensible than just using ConstructionBase.jl
reconstruction. Developers can choose to ignore some of the fields passed
by `rebuild`.

The function signature is always one of:

```julia
rebuild(obj, args...)
rebuild(obj; kw...)
```

`rebuild` has keyword versions automatically generated for all objects
using [ConstructionBase.jl](https://github.com/JuliaObjects/ConstructionBase.jl). 

These will work without further work as long as your object has the fields 
used by DimensionalData.jl objects. For example, `AbstractDimArray` will 
receive these keywords in `rebuild`: `data`, `dims`, `refdims`, `name`, `metadata`. 

If your `AbstractDimArray` does not have all these fields, you must implement
`rebuild(x::YourDimArray; kw...)` manually.

An argument method is also defined with the same arguments as the 
keyword version. For `AbstractDimArray` it should only be used for 
updating `data` and `dims`, any more that that is confusing.

For `Dimension` and `Selector` the single argument versions are easiest to use, 
as there is only one argument.

### `rebuild(obj, ...)` argument table

| Type             | Keywords                                                    | Arguments            |
|------------------|------------------------------------------------------------ |----------------------|
| AbstractDimArray | data, dims, [refdims, name, metadata]                       | as with kw, in order |
| AbstractDimStack | data, dims, [refdims], layerdims, [metadata, layermetadata] | as with kw, in order |
| Dimension        | val                                                         | val                  |
| Selector         | val, [atol]                                                 | val                  |
| LookupArray      | data, [order, span, sampling, metadata]                     | keywords only        |

You can always add your ownd keywords to `rebuild` calls, but these will only
work on your own objects or other objects with those fields.


## `format`

When constructing an `AbstractDimArray` or `AbstractDimStack` 
[`DimensionalData.format`](@ref) must be called on the `dims` tuple and the parent array:

```julia
dims=`format(dims, array)`
```

This lets DimensionalData detect the lookup properties, fill in missing fields
of LookupArray, pass keywords from `Dimension` to detected `LookupArray`, and accept 
a wider range of dimension inputs like tuples of `Symbol` and `Type`.

Not calling `format` whille constructing an `AbstractDimArray` has 
undefined behaviour.


