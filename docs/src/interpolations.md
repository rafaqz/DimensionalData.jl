```@meta
Description = "Interpolate and extrapolate `DimArray` data - interoperability with `DataInterpolations.jl` and `DataInterpolationsND.jl`"
```

# Interpolation of `DimensionalData.jl` Objects

The following functionalities are available
for DimensionalData version 0.29.25
with DataInterpolations version 
but are experimental and under development.
Breaking changes may come in future patches.

## 1D Interpolation with `DataInterpolations.jl`

Convenience interpolation methods of `DimensionalData` objects
has been implemented as the package extension
`DimensionalDataDataInterpolationsExt`,
which is loaded simply by loading the two dependent packages:

```@ansi Interpolation1D
using DimensionalData
using DataInterpolations
```

All interpolation methods provided by `DataInterpolations`
are supported. Explicitly:

* `LinearInterpolation`
* `QuadraticInterpolation`
* `LagrangeInterpolation`
* `AkimaInterpolation`
* `ConstantInterpolation`
* `SmoothedConstantInterpolation`
* `QuadraticSpline`
* `CubicSpline`
* `BSplineInterpolation`
* `CubicHermiteSpline`
* `PCHIPInterpolation`
* `QuinticHermiteSpline`

All extrapolation types provided by `DataInterpolations`
are also supported. Explicitly:

* `ExtrapolationType.None`
* `ExtrapolationType.Constant`
* `ExtrapolationType.Linear`
* `ExtrapolationType.Extension`
* `ExtrapolationType.Periodic`
* `ExtrapolationType.Reflective`

The extension methods are defined such that
the two positional arguments of `u` and `t` are replaced with
the single positional argument of an `AbstractDimVector`.
The `parent` vector is defined as `u`
and the `Dimension` vector is defined as `t`.

For the following examples, the following `DimArray` is used:

```@ansi Interpolation1D
A = DimArray(
    [14.7, 11.51, 10.41, 14.95, 12.24, 11.22],
    [0.0, 62.25, 109.66, 162.66, 205.8, 252.3] |> X
)
dA = [-0.047, -0.058, 0.054, 0.012, -0.068, 0.0011]
ddA = [0.0, -0.00033, 0.0051, -0.0067, 0.0029, 0.0]

nothing # hide
```

### Linear Interpolation Examples

::: tabs


== Interpolation

```@ansi Interpolation1D
itp = LinearInterpolation(A)
```

```@ansi Interpolation1D
itp(12.34)
```

```@ansi Interpolation1D
itp(0 : 10.0 : 100)
```


== Extrapolation

```@ansi Interpolation1D
itp = LinearInterpolation(
    A;
    extrapolation = ExtrapolationType.Periodic
)
```

```@ansi Interpolation1D
itp(12.34)
```

```@ansi Interpolation1D
itp(-12.34)
```

```@ansi Interpolation1D
itp(1234.56)
```

```@ansi Interpolation1D
itp(-250 : 100.0 : 450)
```


== Left Extrapolation

```@ansi Interpolation1D
itp = LinearInterpolation(
    A;
    extrapolation_left = ExtrapolationType.Extension
)
```

```@ansi Interpolation1D
itp(12.34)
```

```@ansi Interpolation1D
itp(-12.34)
```

```@ansi Interpolation1D
itp(-250 : 100.0 : 250)
```


== Right Extrapolation

```@ansi Interpolation1D
itp = LinearInterpolation(
    A;
    extrapolation_right = ExtrapolationType.Reflective
)
```

```@ansi Interpolation1D
itp(12.34)
```

```@ansi Interpolation1D
itp(1234.56)
```

```@ansi Interpolation1D
itp(50 : 100.0 : 250)
```


== Mixed Extrapolation

```@ansi Interpolation1D
itp = LinearInterpolation(
    A;
    extrapolation_left = ExtrapolationType.Constant,
    extrapolation_right = ExtrapolationType.Reflective
)
```

```@ansi Interpolation1D
itp(12.34)
```

```@ansi Interpolation1D
itp(-12.34)
```

```@ansi Interpolation1D
itp(1234.56)
```

```@ansi Interpolation1D
itp(-250 : 100.0 : 450)
```

### Quadratic Interpolation Examples

::: tabs


== Interpolation

```@ansi Interpolation1D
itp = QuadraticInterpolation(A)
```

```@ansi Interpolation1D
itp(12.34)
```

```@ansi Interpolation1D
itp(0 : 10.0 : 100)
```


== Backward

```@ansi Interpolation1D
itp = QuadraticInterpolation(A, :Backward)
```

```@ansi Interpolation1D
itp(12.34)
```

```@ansi Interpolation1D
itp(0 : 10.0 : 100)
```


== Extrapolation

```@ansi Interpolation1D
itp = QuadraticInterpolation(
    A;
    extrapolation = ExtrapolationType.Periodic
)
```

```@ansi Interpolation1D
itp(12.34)
```

```@ansi Interpolation1D
itp(-12.34)
```

```@ansi Interpolation1D
itp(1234.56)
```

```@ansi Interpolation1D
itp(-250 : 100.0 : 450)
```


== Left Extrapolation

```@ansi Interpolation1D
itp = QuadraticInterpolation(
    A, :Backward;
    extrapolation_left = ExtrapolationType.Extension
)
```

```@ansi Interpolation1D
itp(12.34)
```

```@ansi Interpolation1D
itp(-12.34)
```

```@ansi Interpolation1D
itp(-250 : 100.0 : 250)
```


== Right Extrapolation

```@ansi Interpolation1D
itp = QuadraticInterpolation(
    A;
    extrapolation_right = ExtrapolationType.Reflective
)
```

```@ansi Interpolation1D
itp(12.34)
```

```@ansi Interpolation1D
itp(1234.56)
```

```@ansi Interpolation1D
itp(50 : 100.0 : 250)
```


== Mixed Extrapolation

```@ansi Interpolation1D
itp = QuadraticInterpolation(
    A, :Backward;
    extrapolation_left = ExtrapolationType.Constant,
    extrapolation_right = ExtrapolationType.Reflective
)
```

```@ansi Interpolation1D
itp(12.34)
```

```@ansi Interpolation1D
itp(-12.34)
```

```@ansi Interpolation1D
itp(1234.56)
```

```@ansi Interpolation1D
itp(-250 : 100.0 : 450)
```

### Quintic Hermite Spline Examples

::: tabs


== Interpolation

```@ansi Interpolation1D
itp = QuinticHermiteSpline(ddA, dA, A)
```

```@ansi Interpolation1D
itp(12.34)
```

```@ansi Interpolation1D
itp(0 : 10.0 : 100)
```


== Extrapolation

```@ansi Interpolation1D
itp = QuinticHermiteSpline(
    ddA, dA, A;
    extrapolation = ExtrapolationType.Periodic
)
```

```@ansi Interpolation1D
itp(12.34)
```

```@ansi Interpolation1D
itp(-12.34)
```

```@ansi Interpolation1D
itp(1234.56)
```

```@ansi Interpolation1D
itp(-250 : 100.0 : 450)
```


== Left Extrapolation

```@ansi Interpolation1D
itp = QuinticHermiteSpline(
    ddA, dA, A;
    extrapolation_left = ExtrapolationType.Extension
)
```

```@ansi Interpolation1D
itp(12.34)
```

```@ansi Interpolation1D
itp(-12.34)
```

```@ansi Interpolation1D
itp(-250 : 100.0 : 250)
```


== Right Extrapolation

```@ansi Interpolation1D
itp = QuinticHermiteSpline(
    ddA, dA, A;
    extrapolation_right = ExtrapolationType.Reflective
)
```

```@ansi Interpolation1D
itp(12.34)
```

```@ansi Interpolation1D
itp(1234.56)
```

```@ansi Interpolation1D
itp(50 : 100.0 : 250)
```


== Mixed Extrapolation

```@ansi Interpolation1D
itp = QuinticHermiteSpline(
    ddA, dA, A;
    extrapolation_left = ExtrapolationType.Constant,
    extrapolation_right = ExtrapolationType.Reflective
)
```

```@ansi Interpolation1D
itp(12.34)
```

```@ansi Interpolation1D
itp(-12.34)
```

```@ansi Interpolation1D
itp(1234.56)
```

```@ansi Interpolation1D
itp(-250 : 100.0 : 450)
```

## ND Interpolation with `DataInterpolationsND.jl`

Not yet implemented.

## Roadmap and Discussion Prompts

Feel free to follow, contribute to, and veto features in
the discussion on this functionality at
[Issue 420](https://github.com/rafaqz/DimensionalData.jl/issues/420),
especially regarding the following planned features.

For `itp::AbstractInterpolation`
(including `itp = PCHIPInterpolation(...)`):

* Enforce `<:Number` on array and dimension element types via stricter method signatures.
* `itp(::Dimension)` and `itp(::DimArray)` return a `DimArray` instead of a raw `Array`.
* `itp` construction requiring/accepting additional numerical information (such as derivatives at data points), define signatures for specification of the derivatives in a `DimStack` and `DimTree`.
* Expansion of functionality of 1D interpolation to receive `DimArray`s and specify the `Dimension` for the interpolation.
* Check downstream functionalities of `DimensionalData` extensions such as `Rasters.jl`.
* Package extension for `DataInterpolationsND.jl`.
* Package extension for `Interpolations.jl`.
