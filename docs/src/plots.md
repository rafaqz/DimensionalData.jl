# Plots.jl

Plots.jl and Makie.jl functions mostly work out of the box on `AbstractDimArray`,
although not with the same results - they choose to follow each packages default
behaviour as much as possible. 

This will plot a line plot with 'a', 'b' and 'c' in the legend,
and values 1-10 on the labelled X axis:


Plots.jl support is deprecated, as development is moving to Makie.jl


# Makie.jl

Makie.jl functions also mostly work with `AbstractDimArray` and will `permute` and 
`reorder` axes into the right places, especially if `X`/`Y`/`Z`/`Ti` dimensions are used.

In makie a `DimMatrix` will plot as a heatmap by defualt, but again it will have labels 
and axes in the right places:

```@example Makie
using DimensionalData, CairoMakie

A = rand(X(1:10), Y([:a, :b, :c]))
Makie.plot(A; colormap=:inferno)
```

Other plots also work, here we ignore the axis order and instead favour the
categorical varable for the X axis:

```@example Makie
Makie.rainclouds(A)
```

A lot more is planned for Make.jl plots in future!
