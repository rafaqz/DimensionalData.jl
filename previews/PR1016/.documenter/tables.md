
# Tables and DataFrames {#Tables-and-DataFrames}

[Tables.jl](https://github.com/JuliaData/Tables.jl) provides an ecosystem-wide interface to tabular data in Julia, ensuring interoperability with [DataFrames.jl](https://dataframes.juliadata.org/stable/), [CSV.jl](https://csv.juliadata.org/stable/), and hundreds of other packages that implement the standard.

DimensionalData.jl implements the Tables.jl interface for `AbstractDimArray` and `AbstractDimStack`. `DimStack` layers are unrolled so they are all the same size, and dimensions loop to match the length of the largest layer.

Columns are given the [`name`](/api/reference#DimensionalData.Dimensions.name) of the array or stack layer, and the result of `DD.name(dimension)` for `Dimension` columns.

Looping of dimensions and stack layers is done _lazily_, and does not allocate unless collected.

## Example {#Example}

```julia
using DimensionalData
using Dates
using DataFrames
```


Define some dimensions:

```julia
julia> x, y, c = X(1:10), Y(1:10), Dim{:category}('a':'z')
```

```ansi
([38;5;209m↓ [39m[38;5;209mX[39m [38;5;209m1:10[39m,
[38;5;32m→ [39m[38;5;32mY[39m [38;5;32m1:10[39m,
[38;5;81m↗ [39m[38;5;81mcategory[39m [38;5;81m'a':1:'z'[39m)
```


::: tabs

== Create a `DimArray`

```julia
julia> A = rand(x, y, c; name=:data)
```

```ansi
[90m┌ [39m[38;5;209m10[39m×[38;5;32m10[39m×[38;5;81m26[39m DimArray{Float64, 3}[38;5;37m data[39m[90m ┐[39m
[90m├────────────────────────────────────┴────────────── dims ┐[39m
  [38;5;209m↓ [39m[38;5;209mX[39m Sampled{Int64} [38;5;209m1:10[39m [38;5;244mForwardOrdered[39m [38;5;244mRegular[39m [38;5;244mPoints[39m,
  [38;5;32m→ [39m[38;5;32mY[39m Sampled{Int64} [38;5;32m1:10[39m [38;5;244mForwardOrdered[39m [38;5;244mRegular[39m [38;5;244mPoints[39m,
  [38;5;81m↗ [39m[38;5;81mcategory[39m Categorical{Char} [38;5;81m'a':1:'z'[39m [38;5;244mForwardOrdered[39m
[90m└─────────────────────────────────────────────────────────┘[39m
[[38;5;209m:[39m, [38;5;32m:[39m, [38;5;81m1[39m]
  [38;5;209m↓[39m [38;5;32m→[39m  [38;5;32m1[39m          [38;5;32m2[39m         [38;5;32m3[39m          …  [38;5;32m8[39m          [38;5;32m9[39m         [38;5;32m10[39m
  [38;5;209m1[39m    0.960754   0.73427   0.71403       0.0450694  0.685225   0.66882
  [38;5;209m2[39m    0.0965086  0.122976  0.731753      0.474659   0.391502   0.0648408
  [38;5;209m3[39m    0.889194   0.356028  0.550553      0.348197   0.495366   0.433724
  ⋮                                    ⋱                        ⋮
  [38;5;209m7[39m    0.122571   0.245564  0.431383      0.258165   0.351907   0.99726
  [38;5;209m8[39m    0.418412   0.939201  0.666574      0.0908083  0.802274   0.747231
  [38;5;209m9[39m    0.224351   0.240351  0.0933704     0.773992   0.99531    0.365215
 [38;5;209m10[39m    0.767136   0.390515  0.782823   …  0.91991    0.605097   0.113556
```


== Create a `DimStack`

```julia
julia> st = DimStack((data1 = rand(x, y), data2=rand(x, y, c)))
```

```ansi
[90m┌ [39m[38;5;209m10[39m×[38;5;32m10[39m×[38;5;81m26[39m DimStack[90m ┐[39m
[90m├───────────────────┴─────────────────────────────────── dims ┐[39m
  [38;5;209m↓ [39m[38;5;209mX[39m Sampled{Int64} [38;5;209m1:10[39m [38;5;244mForwardOrdered[39m [38;5;244mRegular[39m [38;5;244mPoints[39m,
  [38;5;32m→ [39m[38;5;32mY[39m Sampled{Int64} [38;5;32m1:10[39m [38;5;244mForwardOrdered[39m [38;5;244mRegular[39m [38;5;244mPoints[39m,
  [38;5;81m↗ [39m[38;5;81mcategory[39m Categorical{Char} [38;5;81m'a':1:'z'[39m [38;5;244mForwardOrdered[39m
[90m├───────────────────────────────────────────────────── layers ┤[39m
[38;5;37m  :data1[39m[90m eltype: [39mFloat64[90m dims: [39m[38;5;209mX[39m, [38;5;32mY[39m[90m size: [39m[38;5;209m10[39m×[38;5;32m10[39m
[38;5;37m  :data2[39m[90m eltype: [39mFloat64[90m dims: [39m[38;5;209mX[39m, [38;5;32mY[39m, [38;5;81mcategory[39m[90m size: [39m[38;5;209m10[39m×[38;5;32m10[39m×[38;5;81m26[39m
[90m└─────────────────────────────────────────────────────────────┘[39m
```


::: 

## Converting to DataFrame {#Converting-to-DataFrame}

::: tabs

== Array Default

Arrays will have columns for each dimension, and only one data column

```julia
julia> DataFrame(A)
```

```ansi
[1m2600×4 DataFrame
[1m  Row │[1m X     [1m Y     [1m category [1m data
      │[90m Int64 [90m Int64 [90m Char     [90m Float64
──────┼───────────────────────────────────
    1 │     1      1  a         0.960754
    2 │     2      1  a         0.0965086
    3 │     3      1  a         0.889194
    4 │     4      1  a         0.685603
    5 │     5      1  a         0.0987646
    6 │     6      1  a         0.191188
    7 │     7      1  a         0.122571
    8 │     8      1  a         0.418412
  ⋮   │   ⋮      ⋮       ⋮          ⋮
 2594 │     4     10  z         0.227142
 2595 │     5     10  z         0.635786
 2596 │     6     10  z         0.210417
 2597 │     7     10  z         0.849817
 2598 │     8     10  z         0.261216
 2599 │     9     10  z         0.0459272
 2600 │    10     10  z         0.434794
[36m                         2585 rows omitted
```


== Stack Default

Stacks will become a table with a column for each dimension, and one for each layer:

```julia
julia> DataFrame(st)
```

```ansi
[1m2600×5 DataFrame
[1m  Row │[1m X     [1m Y     [1m category [1m data1     [1m data2
      │[90m Int64 [90m Int64 [90m Char     [90m Float64   [90m Float64
──────┼───────────────────────────────────────────────
    1 │     1      1  a         0.267433   0.550148
    2 │     2      1  a         0.599241   0.0930075
    3 │     3      1  a         0.192192   0.489525
    4 │     4      1  a         0.607291   0.793832
    5 │     5      1  a         0.921958   0.00191986
    6 │     6      1  a         0.449491   0.861278
    7 │     7      1  a         0.581131   0.207584
    8 │     8      1  a         0.194849   0.0236468
  ⋮   │   ⋮      ⋮       ⋮          ⋮          ⋮
 2594 │     4     10  z         0.887294   0.233504
 2595 │     5     10  z         0.0120967  0.795927
 2596 │     6     10  z         0.266342   0.377799
 2597 │     7     10  z         0.485876   0.2276
 2598 │     8     10  z         0.271354   0.113253
 2599 │     9     10  z         0.252366   0.250736
 2600 │    10     10  z         0.965627   0.407471
[36m                                     2585 rows omitted
```


== layersfrom

Using [`DimTable`](/api/reference#DimensionalData.DimTable) we can specify that a `DimArray`  should take columns from one of the dimensions:

```julia
julia> DataFrame(DimTable(A; layersfrom=:category))
```

```ansi
[1m100×28 DataFrame
[1m Row │[1m X     [1m Y     [1m category_a [1m category_b [1m category_c [1m category_d [1m category_ ⋯
     │[90m Int64 [90m Int64 [90m Float64    [90m Float64    [90m Float64    [90m Float64    [90m Float64   ⋯
─────┼──────────────────────────────────────────────────────────────────────────
   1 │     1      1   0.960754     0.579501   0.997558    0.768418     0.56866 ⋯
   2 │     2      1   0.0965086    0.993835   0.664597    0.778423     0.33766
   3 │     3      1   0.889194     0.436571   0.0615946   0.157991     0.38587
   4 │     4      1   0.685603     0.482268   0.496268    0.505639     0.90529
   5 │     5      1   0.0987646    0.227811   0.653044    0.701935     0.95257 ⋯
   6 │     6      1   0.191188     0.887106   0.724507    0.0898829    0.95802
   7 │     7      1   0.122571     0.663593   0.380474    0.43225      0.26501
   8 │     8      1   0.418412     0.631207   0.0379033   0.380525     0.24871
  ⋮  │   ⋮      ⋮        ⋮           ⋮           ⋮           ⋮           ⋮     ⋱
  94 │     4     10   0.197531     0.402627   0.936435    0.639993     0.75968 ⋯
  95 │     5     10   0.207916     0.993473   0.442975    0.92641      0.57048
  96 │     6     10   0.848785     0.202238   0.2477      0.290933     0.26999
  97 │     7     10   0.99726      0.556427   0.463976    0.490566     0.81084
  98 │     8     10   0.747231     0.505666   0.49413     0.344407     0.39400 ⋯
  99 │     9     10   0.365215     0.579865   0.449062    0.558133     0.30969
 100 │    10     10   0.113556     0.510277   0.634405    0.731217     0.42383
[36m                                                  22 columns and 85 rows omitted
```

```julia
julia> DimStack(A; layersfrom=:category)
```

```ansi
[90m┌ [39m[38;5;209m10[39m×[38;5;32m10[39m DimStack[90m ┐[39m
[90m├────────────────┴────────────────────────────────── dims ┐[39m
  [38;5;209m↓ [39m[38;5;209mX[39m Sampled{Int64} [38;5;209m1:10[39m [38;5;244mForwardOrdered[39m [38;5;244mRegular[39m [38;5;244mPoints[39m,
  [38;5;32m→ [39m[38;5;32mY[39m Sampled{Int64} [38;5;32m1:10[39m [38;5;244mForwardOrdered[39m [38;5;244mRegular[39m [38;5;244mPoints[39m
[90m├───────────────────────────────────────────────── layers ┤[39m
[38;5;37m  :a[39m[90m eltype: [39mFloat64[90m dims: [39m[38;5;209mX[39m, [38;5;32mY[39m[90m size: [39m[38;5;209m10[39m×[38;5;32m10[39m
[38;5;37m  :b[39m[90m eltype: [39mFloat64[90m dims: [39m[38;5;209mX[39m, [38;5;32mY[39m[90m size: [39m[38;5;209m10[39m×[38;5;32m10[39m
[38;5;37m  :c[39m[90m eltype: [39mFloat64[90m dims: [39m[38;5;209mX[39m, [38;5;32mY[39m[90m size: [39m[38;5;209m10[39m×[38;5;32m10[39m
[38;5;37m  :d[39m[90m eltype: [39mFloat64[90m dims: [39m[38;5;209mX[39m, [38;5;32mY[39m[90m size: [39m[38;5;209m10[39m×[38;5;32m10[39m
[38;5;37m  :e[39m[90m eltype: [39mFloat64[90m dims: [39m[38;5;209mX[39m, [38;5;32mY[39m[90m size: [39m[38;5;209m10[39m×[38;5;32m10[39m
[38;5;37m  :f[39m[90m eltype: [39mFloat64[90m dims: [39m[38;5;209mX[39m, [38;5;32mY[39m[90m size: [39m[38;5;209m10[39m×[38;5;32m10[39m
[38;5;37m  :g[39m[90m eltype: [39mFloat64[90m dims: [39m[38;5;209mX[39m, [38;5;32mY[39m[90m size: [39m[38;5;209m10[39m×[38;5;32m10[39m
[38;5;37m  :h[39m[90m eltype: [39mFloat64[90m dims: [39m[38;5;209mX[39m, [38;5;32mY[39m[90m size: [39m[38;5;209m10[39m×[38;5;32m10[39m
[38;5;37m  :i[39m[90m eltype: [39mFloat64[90m dims: [39m[38;5;209mX[39m, [38;5;32mY[39m[90m size: [39m[38;5;209m10[39m×[38;5;32m10[39m
[38;5;37m  :j[39m[90m eltype: [39mFloat64[90m dims: [39m[38;5;209mX[39m, [38;5;32mY[39m[90m size: [39m[38;5;209m10[39m×[38;5;32m10[39m
[38;5;37m  :k[39m[90m eltype: [39mFloat64[90m dims: [39m[38;5;209mX[39m, [38;5;32mY[39m[90m size: [39m[38;5;209m10[39m×[38;5;32m10[39m
[38;5;37m  :l[39m[90m eltype: [39mFloat64[90m dims: [39m[38;5;209mX[39m, [38;5;32mY[39m[90m size: [39m[38;5;209m10[39m×[38;5;32m10[39m
[38;5;37m  :m[39m[90m eltype: [39mFloat64[90m dims: [39m[38;5;209mX[39m, [38;5;32mY[39m[90m size: [39m[38;5;209m10[39m×[38;5;32m10[39m
[38;5;37m  :n[39m[90m eltype: [39mFloat64[90m dims: [39m[38;5;209mX[39m, [38;5;32mY[39m[90m size: [39m[38;5;209m10[39m×[38;5;32m10[39m
[38;5;37m  :o[39m[90m eltype: [39mFloat64[90m dims: [39m[38;5;209mX[39m, [38;5;32mY[39m[90m size: [39m[38;5;209m10[39m×[38;5;32m10[39m
[38;5;37m  :p[39m[90m eltype: [39mFloat64[90m dims: [39m[38;5;209mX[39m, [38;5;32mY[39m[90m size: [39m[38;5;209m10[39m×[38;5;32m10[39m
[38;5;37m  :q[39m[90m eltype: [39mFloat64[90m dims: [39m[38;5;209mX[39m, [38;5;32mY[39m[90m size: [39m[38;5;209m10[39m×[38;5;32m10[39m
[38;5;37m  :r[39m[90m eltype: [39mFloat64[90m dims: [39m[38;5;209mX[39m, [38;5;32mY[39m[90m size: [39m[38;5;209m10[39m×[38;5;32m10[39m
[38;5;37m  :s[39m[90m eltype: [39mFloat64[90m dims: [39m[38;5;209mX[39m, [38;5;32mY[39m[90m size: [39m[38;5;209m10[39m×[38;5;32m10[39m
[38;5;37m  :t[39m[90m eltype: [39mFloat64[90m dims: [39m[38;5;209mX[39m, [38;5;32mY[39m[90m size: [39m[38;5;209m10[39m×[38;5;32m10[39m
[38;5;37m  :u[39m[90m eltype: [39mFloat64[90m dims: [39m[38;5;209mX[39m, [38;5;32mY[39m[90m size: [39m[38;5;209m10[39m×[38;5;32m10[39m
[38;5;37m  :v[39m[90m eltype: [39mFloat64[90m dims: [39m[38;5;209mX[39m, [38;5;32mY[39m[90m size: [39m[38;5;209m10[39m×[38;5;32m10[39m
[38;5;37m  :w[39m[90m eltype: [39mFloat64[90m dims: [39m[38;5;209mX[39m, [38;5;32mY[39m[90m size: [39m[38;5;209m10[39m×[38;5;32m10[39m
[38;5;37m  :x[39m[90m eltype: [39mFloat64[90m dims: [39m[38;5;209mX[39m, [38;5;32mY[39m[90m size: [39m[38;5;209m10[39m×[38;5;32m10[39m
[38;5;37m  :y[39m[90m eltype: [39mFloat64[90m dims: [39m[38;5;209mX[39m, [38;5;32mY[39m[90m size: [39m[38;5;209m10[39m×[38;5;32m10[39m
[38;5;37m  :z[39m[90m eltype: [39mFloat64[90m dims: [39m[38;5;209mX[39m, [38;5;32mY[39m[90m size: [39m[38;5;209m10[39m×[38;5;32m10[39m
[90m└─────────────────────────────────────────────────────────┘[39m
```


== mergedims

Using [`DimTable`](/api/reference#DimensionalData.DimTable) we can merge the spatial  dimensions so the column is a tuple:

```julia
julia> DataFrame(DimTable(st; mergedims=(:X, :Y)=>:XY))
```

```ansi
[1m2600×4 DataFrame
[1m  Row │[1m XY       [1m category [1m data1     [1m data2
      │[90m Tuple…   [90m Char     [90m Float64   [90m Float64
──────┼───────────────────────────────────────────
    1 │ (1, 1)    a         0.267433   0.550148
    2 │ (2, 1)    a         0.599241   0.0930075
    3 │ (3, 1)    a         0.192192   0.489525
    4 │ (4, 1)    a         0.607291   0.793832
    5 │ (5, 1)    a         0.921958   0.00191986
    6 │ (6, 1)    a         0.449491   0.861278
    7 │ (7, 1)    a         0.581131   0.207584
    8 │ (8, 1)    a         0.194849   0.0236468
  ⋮   │    ⋮         ⋮          ⋮          ⋮
 2594 │ (4, 10)   z         0.887294   0.233504
 2595 │ (5, 10)   z         0.0120967  0.795927
 2596 │ (6, 10)   z         0.266342   0.377799
 2597 │ (7, 10)   z         0.485876   0.2276
 2598 │ (8, 10)   z         0.271354   0.113253
 2599 │ (9, 10)   z         0.252366   0.250736
 2600 │ (10, 10)  z         0.965627   0.407471
[36m                                 2585 rows omitted
```


::: 

## Converting to CSV {#Converting-to-CSV}

We can also write arrays and stacks directly to CSV.jl, or any other data type supporting the Tables.jl interface.

```julia
using CSV
CSV.write("dimstack.csv", st)
readlines("dimstack.csv")
```


```
2601-element Vector{String}:
 "X,Y,category,data1,data2"
 "1,1,a,0.2674330482715843,0.5501481631111826"
 "2,1,a,0.5992407552660244,0.09300753748828394"
 "3,1,a,0.19219227965820063,0.48952511607945026"
 "4,1,a,0.6072910004472037,0.7938317326707394"
 "5,1,a,0.9219584479428687,0.0019198597596568057"
 "6,1,a,0.449490631413745,0.8612776980335002"
 "7,1,a,0.5811306546643178,0.20758428874582302"
 "8,1,a,0.1948490023468078,0.023646798570656102"
 "9,1,a,0.20144095329862288,0.11925244363082943"
 ⋮
 "2,10,z,0.9341886269251364,0.6005065544080029"
 "3,10,z,0.29448593792551514,0.36851882799081104"
 "4,10,z,0.8872944242976297,0.23350386812772128"
 "5,10,z,0.012096736709184541,0.7959265671836858"
 "6,10,z,0.26634216134156385,0.3777991041100621"
 "7,10,z,0.4858762080349691,0.2276004407628871"
 "8,10,z,0.27135422404853515,0.1132529224292641"
 "9,10,z,0.25236585444042137,0.25073570045665916"
 "10,10,z,0.9656269833042522,0.40747087988600206"
```

