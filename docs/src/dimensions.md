```@meta
Description = "Dimensions in DimensionalData.jl - named wrapper types for array axes, including spatial (X,Y,Z) and temporal (Ti) dimensions"
```

# Dimensions

Dimensions are "wrapper types" that can be used to wrap any 
object to associate it with a named dimension. 

`X`, `Y`, `Z`, `Ti` are predefined as types:

```@ansi dimensions
using DimensionalData
X(1)
X(1), Y(2), Z(3)
```

You can also create [`Dim`](@ref) dimensions with any name:

```@ansi dimensions
Dim{:a}(1), Dim{:b}(1)
```

The wrapped value can be retrieved with `val`:

```@ansi dimensions
val(X(1))
```

DimensionalData.jl uses `Dimensions` everywhere: 

- `Dimension`s are returned from `dims` to specify the names of the dimensions of an object
- They can wrap [`Dimensions.Lookups`](@ref) to associate the lookups with those names
- To index into these objects, they can wrap indices like `Int` or a `Selector` 

This symmetry means we can ignore how data is organized, 
and label and access it by name, letting DD work out the details for us.

Dimensions are defined in the [`DimensionalData.Dimensions`](@ref) submodule, and some 
Dimension-specific methods can be brought into scope with:

```julia
using DimensionalData.Dimensions
```
