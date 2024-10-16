# Plots.jl

Plots.jl and Makie.jl functions mostly work out of the box on `AbstractDimArray`,
although not with the same results - they choose to follow each packages default
behaviour as much as possible. 

This will plot a line plot with 'a', 'b' and 'c' in the legend,
and values 1-10 on the labelled X axis:


Plots.jl support is deprecated, as development is moving to Makie.jl


# Makie.jl

Makie.jl functions also mostly work with [`AbstractDimArray`](@ref) and will `permute` and 
[`reorder`](@ref) axes into the right places, especially if `X`/`Y`/`Z`/`Ti` dimensions are used.

In Makie a `DimMatrix` will plot as a heatmap by default, but it will have labels 
and axes in the right places:

```@example Makie
using DimensionalData, CairoMakie
CairoMakie.activate!(type = :svg) # hide

A = rand(X(10:10:100), Y([:a, :b, :c]))
Makie.plot(A; colormap=:inferno)
```

Other plots also work, here DD ignores the axis order and instead 
favours the categorical variable for the X axis:

```@example Makie
Makie.rainclouds(A)
```

## AlgebraOfGraphics.jl

AlgebraOfGraphics.jl is a high-level plotting library built on top of Makie.jl that provides a declarative "grammar of graphics" for creating complex visualizations. It allows you to construct plots using algebraic operations like `*` and `+`, making it easy to create sophisticated graphics with minimal code.

Any `DimensionalArray` is also a `Tables.jl` table, so it can be used with `AlgebraOfGraphics.jl` directly.  You can indicate columns in `mapping` with Symbols directly (like `:X` or `:Y`), **or** you can use the `Dim` type directly (like `X` or `Y`)! 

```@example Makie
using DimensionalData, AlgebraOfGraphics, CairoMakie
CairoMakie.activate!(type = :svg) # hide

A = DimArray(rand(10, 10), (X(1:10), Y(1:10)), name = :data)

data(A) * mapping(X, Y; color = :data) * visual(Scatter) |> draw
```




## Test series plots

### default colormap

```@example Makie
B = rand(X(10:10:100), Y([:a, :b, :c, :d, :e, :f, :g, :h, :i, :j]))
Makie.series(B)
```

### A different colormap
The colormap is controlled by the `color` argument, which can take as an input a named colormap, i.e. `:plasma` or a list of colours. 

```@example Makie
Makie.series(B; color=:plasma)
```

```@example Makie
Makie.series(A; color=[:red, :blue, :orange])
```
### with markers

```@example Makie
Makie.series(A; color=[:red, :blue, :orange], markersize=15)
```

A lot more is planned for Makie.jl plots in future!
