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

A = rand(X(10:10:100), Y([:a, :b, :c]))
Makie.plot(A; colormap=:inferno)
```

Other plots also work, here DD ignores the axis order and instead 
favours the categorical variable for the X axis:

```@example Makie
Makie.rainclouds(A)
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

# AlgebraOfGraphics.jl

`AlgebraOfGraphics` is a grammar-of-graphics front end for `Makie`.

## `DimArray`: Some noisy sinuisoidal data...

```@example AoG_DimArrays_1D
using DimensionalData
using CairoMakie, AlgebraOfGraphics

sin2pi(t) = sinpi(2t)
c = 1.0

signal_components = rebuild(
    [
        sin2pi(c*t/λ + φ) + 0.5rand()
        for t in Ti(0 : 0.01 : 5),
            λ in Dim{:λ}(1:3),
            φ in Dim{:φ}(0 : 0.1 : 0.5)
    ];
    name = :A
)

data_layer = data(signal_components)
mapping_1d = mapping(:Ti => "Time (seconds)", :A => "Amplitude")
layers_1d = data_layer * mapping_1d
liner = visual(Lines, linestyle = :dot, alpha = 0.5)
line_vis = layers_1d * liner
```

### ...colored by wavelength and gridded by phase

```@example AoG_DimArrays_1D
wavelength = :λ => (λ -> "$λ m") => "Wavelength"
gridding = mapping(color = wavelength, layout = :φ => nonnumeric)
line_vis * gridding |> draw
```

### ...smoothed

```@example AoG_DimArrays_1D
layer_1d_for_smoothing = layers_1d * gridding
smoother = AlgebraOfGraphics.smooth(span = 0.2)
layer_1d_for_smoothing * smoother |> draw
```

### ...smoothing compared with data

```@example AoG_DimArrays_1D
layer_1d_for_smoothing * (smoother + liner) |> draw
```

### ...for only some wavelengths and phases

(Does not work yet.)

```@example AoG_DimArrays_1D
vis = data_layer
vis *= mapping_1d
# vis *= mapping(color = Dim{:λ}) # not subsetting, but demo prospective semantics
# vis *= mapping(color = Dim{:λ}(1:2))
# vis *= mapping(color = Dim{:λ}(1:2) => nonnumeric)
vis *= mapping(color = wavelength) # subsetting doesn't work yet
# vis *= mapping(layout = Dim{:φ}) # not subsetting, but demo prospective semantics
# vis *= mapping(layout = Dim{:φ}(0.0 : 0.1 : 0.3))
# vis *= mapping(layout = Dim{:φ}(0.0 : 0.1 : 0.3) => nonnumeric)
vis *= mapping(layout = :φ => nonnumeric) # subsetting doesn't work yet
vis *= (smoother + liner)
draw(vis)
```

## `DimStack`: A complex function's...

```@example AoG_DimArrays_2D
using DimensionalData
using CairoMakie, AlgebraOfGraphics

f(z::Complex) = ((im*z)^17 - 1) / (im*z - 1)
f(x::Real, y::Real) = f(x + im*y)

cartesian_data = [
    f(x, y)
    for x in X(2range(-1, 1, 301)),
        y in Y(2range(-1, 1, 301))
]

polar_data = DimStack((
    A_log = cartesian_data .|> abs .|> log10,
    φ = cartesian_data .|> angle .|> rad2deg,
    u = cartesian_data .|> real,
    v = cartesian_data .|> imag
))

data_layer = data(polar_data)
domain_mapping = data_layer * mapping(:X, :Y)
```

### ...analytic landscape

```@example AoG_DimArrays_2D
# Alabel = rich("A", subscript("log")) # doesn't work
Alabel = "A_log"
analytic_landscape = mapping(:A_log => Alabel) * visual(Surface, colormap = :jet)
domain_mapping * analytic_landscape |> draw(axis = (; type = Axis3))
```

### ...phase portrait

```@example AoG_DimArrays_2D
phase_portrait = mapping(:φ) * visual(Heatmap)
# phase_portrait *= visual(colormap = :phase) # doesn't parse the colormap
domain_mapping * phase_portrait |> draw
```

### ...modulus contours

```@example AoG_DimArrays_2D
modulus_contours = mapping(:A_log) * visual(Contour, colormap = :grays)
# modulus_contours *= visual(nan_color = :white) # doesn't work for complex functions with zero modulus, i.e. A_log = log10(0)
domain_mapping * modulus_contours |> draw
```

### ...phase contours

```@example AoG_DimArrays_2D
phase_contours = mapping(:φ) * visual(Contour, colormap = :grays)
domain_mapping * phase_contours |> draw
```

### ...phase portrait with contours

```@example AoG_DimArrays_2D
enhanced_phase_portrait = phase_portrait + modulus_contours + phase_contours
domain_mapping * enhanced_phase_portrait |> draw
```

### ...and some other silly examples

```@example AoG_DimArrays_2D
data_layer * mapping(:u, :v, color = :X) * visual(Scatter) |> draw
```

```@example AoG_DimArrays_2D
data_layer * mapping(:u, :v, :X, color = :φ) * visual(Scatter) |> draw(
    axis = (; type = Axis3)
)
```

```@example AoG_DimArrays_2D
data_layer * mapping(:X, :Y, :φ, color = :A_log) * visual(Scatter) |> draw(
    axis = (; type = Axis3)
)
```
