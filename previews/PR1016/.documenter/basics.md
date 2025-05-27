
## Installation {#Installation}

If you want to use this package you need to install it first. You can do it using the following commands:

```julia
julia> ] # ']' should be pressed
pkg> add DimensionalData
```


or

```julia
julia> using Pkg
julia> Pkg.add("DimensionalData")
```


Additionally, it is recommended to check the version that you have installed with the status command.

```julia
julia> ]
pkg> status DimensionalData
```


## Basics {#Basics}

Start using the package:

```julia
using DimensionalData
```


and create your first DimArray

```julia
julia> A = DimArray(rand(4,5), (a=1:4, b=1:5))
```

```ansi
[90m┌ [39m[38;5;209m4[39m×[38;5;32m5[39m DimArray{Float64, 2}[90m ┐[39m
[90m├──────────────────────────┴─────────────────────── dims ┐[39m
  [38;5;209m↓ [39m[38;5;209ma[39m Sampled{Int64} [38;5;209m1:4[39m [38;5;244mForwardOrdered[39m [38;5;244mRegular[39m [38;5;244mPoints[39m,
  [38;5;32m→ [39m[38;5;32mb[39m Sampled{Int64} [38;5;32m1:5[39m [38;5;244mForwardOrdered[39m [38;5;244mRegular[39m [38;5;244mPoints[39m
[90m└────────────────────────────────────────────────────────┘[39m
 [38;5;209m↓[39m [38;5;32m→[39m  [38;5;32m1[39m         [38;5;32m2[39m         [38;5;32m3[39m         [38;5;32m4[39m         [38;5;32m5[39m
 [38;5;209m1[39m    0.919181  0.954159  0.789493  0.123538  0.464413
 [38;5;209m2[39m    0.426019  0.845895  0.619259  0.74002   0.824787
 [38;5;209m3[39m    0.746586  0.586749  0.477645  0.705747  0.579592
 [38;5;209m4[39m    0.819201  0.121813  0.804193  0.991961  0.803867
```


or

```julia
julia> C = DimArray(rand(Int8, 10), (alpha='a':'j',))
```

```ansi
[90m┌ [39m[38;5;209m10-element [39mDimArray{Int8, 1}[90m ┐[39m
[90m├──────────────────────────────┴───────────────── dims ┐[39m
  [38;5;209m↓ [39m[38;5;209malpha[39m Categorical{Char} [38;5;209m'a':1:'j'[39m [38;5;244mForwardOrdered[39m
[90m└──────────────────────────────────────────────────────┘[39m
 [38;5;209m'a'[39m    74
 [38;5;209m'b'[39m    89
 [38;5;209m'c'[39m    58
 [38;5;209m'd'[39m    30
 [38;5;209m'e'[39m   -89
 [38;5;209m'f'[39m     5
 [38;5;209m'g'[39m   -71
 [38;5;209m'h'[39m  -118
 [38;5;209m'i'[39m   -52
 [38;5;209m'j'[39m   -89
```


or something a little bit more complicated:

```julia
julia> data = rand(Int8, 2, 10, 3) .|> abs
```

```ansi
2×10×3 Array{Int8, 3}:
[:, :, 1] =
 93   9   2  89  116   16  37  60  91  95
 44  29  92  18  120  109  90  18  17  19

[:, :, 2] =
 60  68  126  62  15  99  53  22  119  100
 84  41   81  78  27  53  22  31   50   53

[:, :, 3] =
 88  42  113  12  86  77  117   40  92   94
  9  40   34  93   0  16  122  114  33  102
```

```julia
julia> B = DimArray(data, (channel=[:left, :right], time=1:10, iter=1:3))
```

```ansi
[90m┌ [39m[38;5;209m2[39m×[38;5;32m10[39m×[38;5;81m3[39m DimArray{Int8, 3}[90m ┐[39m
[90m├──────────────────────────┴─────────────────────────────── dims ┐[39m
  [38;5;209m↓ [39m[38;5;209mchannel[39m Categorical{Symbol} [38;5;209m[:left, :right][39m [38;5;244mForwardOrdered[39m,
  [38;5;32m→ [39m[38;5;32mtime[39m Sampled{Int64} [38;5;32m1:10[39m [38;5;244mForwardOrdered[39m [38;5;244mRegular[39m [38;5;244mPoints[39m,
  [38;5;81m↗ [39m[38;5;81miter[39m Sampled{Int64} [38;5;81m1:3[39m [38;5;244mForwardOrdered[39m [38;5;244mRegular[39m [38;5;244mPoints[39m
[90m└────────────────────────────────────────────────────────────────┘[39m
[[38;5;209m:[39m, [38;5;32m:[39m, [38;5;81m1[39m]
 [38;5;209m↓[39m [38;5;32m→[39m       [38;5;32m1[39m   [38;5;32m2[39m   [38;5;32m3[39m   [38;5;32m4[39m    [38;5;32m5[39m    [38;5;32m6[39m   [38;5;32m7[39m   [38;5;32m8[39m   [38;5;32m9[39m  [38;5;32m10[39m
  [38;5;209m:left[39m   93   9   2  89  116   16  37  60  91  95
  [38;5;209m:right[39m  44  29  92  18  120  109  90  18  17  19
```

