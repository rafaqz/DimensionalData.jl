
# Dimensions {#Dimensions}

Dimensions are &quot;wrapper types&quot; that can be used to wrap any  object to associate it with a named dimension. 

`X`, `Y`, `Z`, `Ti` are predefined as types:

```julia
julia> using DimensionalData

julia> X(1)
```

```ansi
[38;5;209mX[39m [38;5;1m1[39m
```

```julia
julia> X(1), Y(2), Z(3)
```

```ansi
([38;5;209m↓ [39m[38;5;209mX[39m [38;5;209m1[39m, [38;5;32m→ [39m[38;5;32mY[39m [38;5;32m2[39m, [38;5;81m↗ [39m[38;5;81mZ[39m [38;5;81m3[39m)
```


You can also create [`Dim`](/api/dimensions#DimensionalData.Dimensions.Dim) dimensions with any name:

```julia
julia> Dim{:a}(1), Dim{:b}(1)
```

```ansi
([38;5;209m↓ [39m[38;5;209ma[39m [38;5;209m1[39m, [38;5;32m→ [39m[38;5;32mb[39m [38;5;32m1[39m)
```


The wrapped value can be retrieved with `val`:

```julia
julia> val(X(1))
```

```ansi
1
```


DimensionalData.jl uses `Dimensions` everywhere: 
- `Dimension`s are returned from `dims` to specify the names of the dimensions of an object
  
- They can wrap [`Lookups`](/api/lookuparrays#DimensionalData.Dimensions.Lookups) to associate the lookups with those names
  
- To index into these objects, they can wrap indices like `Int` or a `Selector` 
  

This symmetry means we can ignore how data is organized,  and label and access it by name, letting DD work out the details for us.

Dimensions are defined in the [`Dimensions`](/api/dimensions#DimensionalData.Dimensions) submodule, and some  Dimension-specific methods can be brought into scope with:

```julia
using DimensionalData.Dimensions
```

