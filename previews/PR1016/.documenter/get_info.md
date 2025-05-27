
# Getters {#Getters}

DimensionalData.jl defines consistent methods to retrieve information from objects like `DimArray`, `DimStack`, `Tuple`s of `Dimension`, `Dimension`, and `Lookup`.

First, we will define an example `DimArray`.

```julia
using DimensionalData
using DimensionalData.Lookups
x, y = X(10:-1:1), Y(100.0:10:200.0)
```


```
(↓ X 10:-1:1,
→ Y 100.0:10.0:200.0)
```


```julia
julia> A = rand(x, y)
```

```ansi
[90m┌ [39m[38;5;209m10[39m×[38;5;32m11[39m DimArray{Float64, 2}[90m ┐[39m
[90m├────────────────────────────┴─────────────────────────────────── dims ┐[39m
  [38;5;209m↓ [39m[38;5;209mX[39m Sampled{Int64} [38;5;209m10:-1:1[39m [38;5;244mReverseOrdered[39m [38;5;244mRegular[39m [38;5;244mPoints[39m,
  [38;5;32m→ [39m[38;5;32mY[39m Sampled{Float64} [38;5;32m100.0:10.0:200.0[39m [38;5;244mForwardOrdered[39m [38;5;244mRegular[39m [38;5;244mPoints[39m
[90m└──────────────────────────────────────────────────────────────────────┘[39m
  [38;5;209m↓[39m [38;5;32m→[39m  [38;5;32m100.0[39m         [38;5;32m110.0[39m        [38;5;32m120.0[39m         …  [38;5;32m190.0[39m       [38;5;32m200.0[39m
 [38;5;209m10[39m      0.19093       0.311676     0.983506         0.636648    0.758395
  [38;5;209m9[39m      0.694156      0.607075     0.973842         0.796537    0.110399
  [38;5;209m8[39m      0.0904123     0.106733     0.456896         0.484191    0.488705
  [38;5;209m7[39m      0.545064      0.688881     0.824833         0.753238    0.00956875
  ⋮                                             ⋱    ⋮
  [38;5;209m4[39m      0.490313      0.222829     0.289705         0.518723    0.532442
  [38;5;209m3[39m      0.00529101    0.239808     0.679315         0.202343    0.744793
  [38;5;209m2[39m      0.444203      0.0574469    0.00132494       0.978464    0.271525
  [38;5;209m1[39m      0.367348      0.474425     0.863738    …    0.744349    0.696446
```


::: tabs

== dims

`dims` retrieves dimensions from any object that has them.

What makes it so useful is that you can filter which dimensions you want, and specify in what order, using any `Dimension`, `Type{Dimension}` or `Symbol`.

```julia
julia> dims(A)
```

```ansi
([38;5;209m↓ [39m[38;5;209mX[39m Sampled{Int64} [38;5;209m10:-1:1[39m [38;5;244mReverseOrdered[39m [38;5;244mRegular[39m [38;5;244mPoints[39m,
[38;5;32m→ [39m[38;5;32mY[39m Sampled{Float64} [38;5;32m100.0:10.0:200.0[39m [38;5;244mForwardOrdered[39m [38;5;244mRegular[39m [38;5;244mPoints[39m)
```

```julia
julia> dims(A, Y)
```

```ansi
[38;5;209mY[39m Sampled{Float64} [38;5;244mForwardOrdered[39m [38;5;244mRegular[39m [38;5;244mPoints[39m
[90mwrapping: [39m100.0:10.0:200.0
```

```julia
julia> dims(A, Y())
```

```ansi
[38;5;209mY[39m Sampled{Float64} [38;5;244mForwardOrdered[39m [38;5;244mRegular[39m [38;5;244mPoints[39m
[90mwrapping: [39m100.0:10.0:200.0
```

```julia
julia> dims(A, :Y)
```

```ansi
[38;5;209mY[39m Sampled{Float64} [38;5;244mForwardOrdered[39m [38;5;244mRegular[39m [38;5;244mPoints[39m
[90mwrapping: [39m100.0:10.0:200.0
```

```julia
julia> dims(A, (X,))
```

```ansi
([38;5;209m↓ [39m[38;5;209mX[39m Sampled{Int64} [38;5;209m10:-1:1[39m [38;5;244mReverseOrdered[39m [38;5;244mRegular[39m [38;5;244mPoints[39m)
```

```julia
julia> dims(A, (Y, X))
```

```ansi
([38;5;209m↓ [39m[38;5;209mY[39m Sampled{Float64} [38;5;209m100.0:10.0:200.0[39m [38;5;244mForwardOrdered[39m [38;5;244mRegular[39m [38;5;244mPoints[39m,
[38;5;32m→ [39m[38;5;32mX[39m Sampled{Int64} [38;5;32m10:-1:1[39m [38;5;244mReverseOrdered[39m [38;5;244mRegular[39m [38;5;244mPoints[39m)
```

```julia
julia> dims(A, reverse(dims(A)))
```

```ansi
([38;5;209m↓ [39m[38;5;209mY[39m Sampled{Float64} [38;5;209m100.0:10.0:200.0[39m [38;5;244mForwardOrdered[39m [38;5;244mRegular[39m [38;5;244mPoints[39m,
[38;5;32m→ [39m[38;5;32mX[39m Sampled{Int64} [38;5;32m10:-1:1[39m [38;5;244mReverseOrdered[39m [38;5;244mRegular[39m [38;5;244mPoints[39m)
```

```julia
julia> dims(A, isregular)
```

```ansi
([38;5;209m↓ [39m[38;5;209mX[39m Sampled{Int64} [38;5;209m10:-1:1[39m [38;5;244mReverseOrdered[39m [38;5;244mRegular[39m [38;5;244mPoints[39m,
[38;5;32m→ [39m[38;5;32mY[39m Sampled{Float64} [38;5;32m100.0:10.0:200.0[39m [38;5;244mForwardOrdered[39m [38;5;244mRegular[39m [38;5;244mPoints[39m)
```


== otherdims

`otherdims` is just like `dims` but returns whatever `dims` would _not_ return from the same query.

```julia
julia> otherdims(A, Y)
```

```ansi
([38;5;209m↓ [39m[38;5;209mX[39m Sampled{Int64} [38;5;209m10:-1:1[39m [38;5;244mReverseOrdered[39m [38;5;244mRegular[39m [38;5;244mPoints[39m)
```

```julia
julia> otherdims(A, Y())
```

```ansi
([38;5;209m↓ [39m[38;5;209mX[39m Sampled{Int64} [38;5;209m10:-1:1[39m [38;5;244mReverseOrdered[39m [38;5;244mRegular[39m [38;5;244mPoints[39m)
```

```julia
julia> otherdims(A, :Y)
```

```ansi
([38;5;209m↓ [39m[38;5;209mX[39m Sampled{Int64} [38;5;209m10:-1:1[39m [38;5;244mReverseOrdered[39m [38;5;244mRegular[39m [38;5;244mPoints[39m)
```

```julia
julia> otherdims(A, (X,))
```

```ansi
([38;5;209m↓ [39m[38;5;209mY[39m Sampled{Float64} [38;5;209m100.0:10.0:200.0[39m [38;5;244mForwardOrdered[39m [38;5;244mRegular[39m [38;5;244mPoints[39m)
```

```julia
julia> otherdims(A, (Y, X))
```

```ansi
()
```

```julia
julia> otherdims(A, dims(A))
```

```ansi
()
```

```julia
julia> otherdims(A, isregular)
```

```ansi
()
```


== lookup

Get all the `Lookup` in an object

```julia
julia> lookup(A)
```

```ansi
Sampled{Int64} [37m10:-1:1[39m [38;5;244mReverseOrdered[39m [38;5;244mRegular[39m [38;5;244mPoints[39m,
Sampled{Float64} [37m100.0:10.0:200.0[39m [38;5;244mForwardOrdered[39m [38;5;244mRegular[39m [38;5;244mPoints[39m
```

```julia
julia> lookup(dims(A))
```

```ansi
Sampled{Int64} [37m10:-1:1[39m [38;5;244mReverseOrdered[39m [38;5;244mRegular[39m [38;5;244mPoints[39m,
Sampled{Float64} [37m100.0:10.0:200.0[39m [38;5;244mForwardOrdered[39m [38;5;244mRegular[39m [38;5;244mPoints[39m
```

```julia
julia> lookup(A, X)
```

```ansi
Sampled{Int64} [38;5;244mReverseOrdered[39m [38;5;244mRegular[39m [38;5;244mPoints[39m
[90mwrapping: [39m10:-1:1
```

```julia
julia> lookup(dims(A, Y))
```

```ansi
Sampled{Float64} [38;5;244mForwardOrdered[39m [38;5;244mRegular[39m [38;5;244mPoints[39m
[90mwrapping: [39m100.0:10.0:200.0
```


== val

`val` is used where there is an unambiguous single value:

```julia
julia> val(X(7))
```

```ansi
7
```

```julia
julia> val(At(10.5))
```

```ansi
10.5
```


== order

Get the order of a `Lookup`, or a `Tuple` from a `DimArray` or `DimTuple`.

```julia
julia> order(A)
```

```ansi
(ReverseOrdered(), ForwardOrdered())
```

```julia
julia> order(dims(A))
```

```ansi
(ReverseOrdered(), ForwardOrdered())
```

```julia
julia> order(A, X)
```

```ansi
ReverseOrdered()
```

```julia
julia> order(lookup(A, Y))
```

```ansi
ForwardOrdered()
```


== sampling

Get the sampling of a `Lookup`, or a `Tuple` from a `DimArray` or `DimTuple`.

```julia
julia> sampling(A)
```

```ansi
(Points(), Points())
```

```julia
julia> sampling(dims(A))
```

```ansi
(Points(), Points())
```

```julia
julia> sampling(A, X)
```

```ansi
Points()
```

```julia
julia> sampling(lookup(A, Y))
```

```ansi
Points()
```


== span

Get the span of a `Lookup`, or a `Tuple` from a `DimArray` or `DimTuple`.

```julia
julia> span(A)
```

```ansi
(Regular{Int64}(-1), Regular{Float64}(10.0))
```

```julia
julia> span(dims(A))
```

```ansi
(Regular{Int64}(-1), Regular{Float64}(10.0))
```

```julia
julia> span(A, X)
```

```ansi
Regular{Int64}(-1)
```

```julia
julia> span(lookup(A, Y))
```

```ansi
Regular{Float64}(10.0)
```


== locus

Get the locus of a `Lookup`, or a `Tuple` from a `DimArray` or `DimTuple`.

(`locus` is our term for distinguishing if an lookup value specifies the start, center, or end of an interval)

```julia
julia> locus(A)
```

```ansi
(Center(), Center())
```

```julia
julia> locus(dims(A))
```

```ansi
(Center(), Center())
```

```julia
julia> locus(A, X)
```

```ansi
Center()
```

```julia
julia> locus(lookup(A, Y))
```

```ansi
Center()
```


== bounds

Get the bounds of each dimension. This is different for `Points`  and `Intervals` - the bounds for points of a `Lookup` are  simply `(first(l), last(l))`.

```julia
julia> bounds(A)
```

```ansi
((1, 10), (100.0, 200.0))
```

```julia
julia> bounds(dims(A))
```

```ansi
((1, 10), (100.0, 200.0))
```

```julia
julia> bounds(A, X)
```

```ansi
(1, 10)
```

```julia
julia> bounds(lookup(A, Y))
```

```ansi
(100.0, 200.0)
```


== intervalbounds

Get the bounds of each interval along a dimension.

```julia
julia> intervalbounds(A)
```

```ansi
([(10, 10), (9, 9), (8, 8), (7, 7), (6, 6), (5, 5), (4, 4), (3, 3), (2, 2), (1, 1)], [(100.0, 100.0), (110.0, 110.0), (120.0, 120.0), (130.0, 130.0), (140.0, 140.0), (150.0, 150.0), (160.0, 160.0), (170.0, 170.0), (180.0, 180.0), (190.0, 190.0), (200.0, 200.0)])
```

```julia
julia> intervalbounds(dims(A))
```

```ansi
([(10, 10), (9, 9), (8, 8), (7, 7), (6, 6), (5, 5), (4, 4), (3, 3), (2, 2), (1, 1)], [(100.0, 100.0), (110.0, 110.0), (120.0, 120.0), (130.0, 130.0), (140.0, 140.0), (150.0, 150.0), (160.0, 160.0), (170.0, 170.0), (180.0, 180.0), (190.0, 190.0), (200.0, 200.0)])
```

```julia
julia> intervalbounds(A, X)
```

```ansi
10-element Vector{Tuple{Int64, Int64}}:
 (10, 10)
 (9, 9)
 (8, 8)
 (7, 7)
 (6, 6)
 (5, 5)
 (4, 4)
 (3, 3)
 (2, 2)
 (1, 1)
```

```julia
julia> intervalbounds(lookup(A, Y))
```

```ansi
11-element Vector{Tuple{Float64, Float64}}:
 (100.0, 100.0)
 (110.0, 110.0)
 (120.0, 120.0)
 (130.0, 130.0)
 (140.0, 140.0)
 (150.0, 150.0)
 (160.0, 160.0)
 (170.0, 170.0)
 (180.0, 180.0)
 (190.0, 190.0)
 (200.0, 200.0)
```


== extent

[Extents.jl](https://github.com/rafaqz/Extent) provides an `Extent`  object that combines the names of dimensions with their bounds. 

```julia
julia> using Extents: extent

julia> extent(A)
```

```ansi
Extent(X = (1, 10), Y = (100.0, 200.0))
```

```julia
julia> extent(A, X)
```

```ansi
Extent(X = (1, 10),)
```

```julia
julia> extent(dims(A))
```

```ansi
Extent(X = (1, 10), Y = (100.0, 200.0))
```

```julia
julia> extent(dims(A, Y))


```


:::

## Predicates {#Predicates}

These always return `true` or `false`. With multiple dimensions, `false` means `!all` and `true` means `all`.

`dims` and all other methods listed above can use predicates to filter the returned dimensions.

::: tabs

== issampled

```julia
julia> issampled(A)
```

```ansi
true
```

```julia
julia> issampled(dims(A))
```

```ansi
true
```

```julia
julia> issampled(A, Y)
```

```ansi
true
```

```julia
julia> issampled(lookup(A, Y))
```

```ansi
true
```

```julia
julia> dims(A, issampled)
```

```ansi
([38;5;209m↓ [39m[38;5;209mX[39m Sampled{Int64} [38;5;209m10:-1:1[39m [38;5;244mReverseOrdered[39m [38;5;244mRegular[39m [38;5;244mPoints[39m,
[38;5;32m→ [39m[38;5;32mY[39m Sampled{Float64} [38;5;32m100.0:10.0:200.0[39m [38;5;244mForwardOrdered[39m [38;5;244mRegular[39m [38;5;244mPoints[39m)
```

```julia
julia> otherdims(A, issampled)
```

```ansi
()
```

```julia
julia> lookup(A, issampled)
```

```ansi
Sampled{Int64} [37m10:-1:1[39m [38;5;244mReverseOrdered[39m [38;5;244mRegular[39m [38;5;244mPoints[39m,
Sampled{Float64} [37m100.0:10.0:200.0[39m [38;5;244mForwardOrdered[39m [38;5;244mRegular[39m [38;5;244mPoints[39m
```


== iscategorical

```julia
julia> iscategorical(A)
```

```ansi
false
```

```julia
julia> iscategorical(dims(A))
```

```ansi
false
```

```julia
julia> iscategorical(dims(A, Y))
```

```ansi
false
```

```julia
julia> iscategorical(lookup(A, Y))
```

```ansi
false
```

```julia
julia> dims(A, iscategorical)
```

```ansi
()
```

```julia
julia> otherdims(A, iscategorical)
```

```ansi
([38;5;209m↓ [39m[38;5;209mX[39m Sampled{Int64} [38;5;209m10:-1:1[39m [38;5;244mReverseOrdered[39m [38;5;244mRegular[39m [38;5;244mPoints[39m,
[38;5;32m→ [39m[38;5;32mY[39m Sampled{Float64} [38;5;32m100.0:10.0:200.0[39m [38;5;244mForwardOrdered[39m [38;5;244mRegular[39m [38;5;244mPoints[39m)
```

```julia
julia> lookup(A, iscategorical)
```

```ansi
()
```


== iscyclic

```julia
julia> iscyclic(A)
```

```ansi
false
```

```julia
julia> iscyclic(dims(A))
```

```ansi
false
```

```julia
julia> iscyclic(dims(A, Y))
```

```ansi
false
```

```julia
julia> iscyclic(lookup(A, Y))
```

```ansi
false
```

```julia
julia> dims(A, iscyclic)
```

```ansi
()
```

```julia
julia> otherdims(A, iscyclic)
```

```ansi
([38;5;209m↓ [39m[38;5;209mX[39m Sampled{Int64} [38;5;209m10:-1:1[39m [38;5;244mReverseOrdered[39m [38;5;244mRegular[39m [38;5;244mPoints[39m,
[38;5;32m→ [39m[38;5;32mY[39m Sampled{Float64} [38;5;32m100.0:10.0:200.0[39m [38;5;244mForwardOrdered[39m [38;5;244mRegular[39m [38;5;244mPoints[39m)
```


== isordered

```julia
julia> isordered(A)
```

```ansi
true
```

```julia
julia> isordered(dims(A))
```

```ansi
true
```

```julia
julia> isordered(A, X)
```

```ansi
true
```

```julia
julia> isordered(lookup(A, Y))
```

```ansi
true
```

```julia
julia> dims(A, isordered)
```

```ansi
([38;5;209m↓ [39m[38;5;209mX[39m Sampled{Int64} [38;5;209m10:-1:1[39m [38;5;244mReverseOrdered[39m [38;5;244mRegular[39m [38;5;244mPoints[39m,
[38;5;32m→ [39m[38;5;32mY[39m Sampled{Float64} [38;5;32m100.0:10.0:200.0[39m [38;5;244mForwardOrdered[39m [38;5;244mRegular[39m [38;5;244mPoints[39m)
```

```julia
julia> otherdims(A, isordered)
```

```ansi
()
```


== isforward

```julia
julia> isforward(A)
```

```ansi
false
```

```julia
julia> isforward(dims(A))
```

```ansi
false
```

```julia
julia> isforward(A, X)
```

```ansi
false
```

```julia
julia> dims(A, isforward)
```

```ansi
([38;5;209m↓ [39m[38;5;209mY[39m Sampled{Float64} [38;5;209m100.0:10.0:200.0[39m [38;5;244mForwardOrdered[39m [38;5;244mRegular[39m [38;5;244mPoints[39m)
```

```julia
julia> otherdims(A, isforward)
```

```ansi
([38;5;209m↓ [39m[38;5;209mX[39m Sampled{Int64} [38;5;209m10:-1:1[39m [38;5;244mReverseOrdered[39m [38;5;244mRegular[39m [38;5;244mPoints[39m)
```


== isreverse

```julia
julia> isreverse(A)
```

```ansi
false
```

```julia
julia> isreverse(dims(A))
```

```ansi
false
```

```julia
julia> isreverse(A, X)
```

```ansi
true
```

```julia
julia> dims(A, isreverse)
```

```ansi
([38;5;209m↓ [39m[38;5;209mX[39m Sampled{Int64} [38;5;209m10:-1:1[39m [38;5;244mReverseOrdered[39m [38;5;244mRegular[39m [38;5;244mPoints[39m)
```

```julia
julia> otherdims(A, isreverse)
```

```ansi
([38;5;209m↓ [39m[38;5;209mY[39m Sampled{Float64} [38;5;209m100.0:10.0:200.0[39m [38;5;244mForwardOrdered[39m [38;5;244mRegular[39m [38;5;244mPoints[39m)
```


== isintervals

```julia
julia> isintervals(A)
```

```ansi
false
```

```julia
julia> isintervals(dims(A))
```

```ansi
false
```

```julia
julia> isintervals(A, X)
```

```ansi
false
```

```julia
julia> isintervals(lookup(A, Y))
```

```ansi
false
```

```julia
julia> dims(A, isintervals)
```

```ansi
()
```

```julia
julia> otherdims(A, isintervals)
```

```ansi
([38;5;209m↓ [39m[38;5;209mX[39m Sampled{Int64} [38;5;209m10:-1:1[39m [38;5;244mReverseOrdered[39m [38;5;244mRegular[39m [38;5;244mPoints[39m,
[38;5;32m→ [39m[38;5;32mY[39m Sampled{Float64} [38;5;32m100.0:10.0:200.0[39m [38;5;244mForwardOrdered[39m [38;5;244mRegular[39m [38;5;244mPoints[39m)
```


== ispoints

```julia
julia> ispoints(A)
```

```ansi
true
```

```julia
julia> ispoints(dims(A))
```

```ansi
true
```

```julia
julia> ispoints(A, X)
```

```ansi
true
```

```julia
julia> ispoints(lookup(A, Y))
```

```ansi
true
```

```julia
julia> dims(A, ispoints)
```

```ansi
([38;5;209m↓ [39m[38;5;209mX[39m Sampled{Int64} [38;5;209m10:-1:1[39m [38;5;244mReverseOrdered[39m [38;5;244mRegular[39m [38;5;244mPoints[39m,
[38;5;32m→ [39m[38;5;32mY[39m Sampled{Float64} [38;5;32m100.0:10.0:200.0[39m [38;5;244mForwardOrdered[39m [38;5;244mRegular[39m [38;5;244mPoints[39m)
```

```julia
julia> otherdims(A, ispoints)
```

```ansi
()
```


== isregular

```julia
julia> isregular(A)
```

```ansi
true
```

```julia
julia> isregular(dims(A))
```

```ansi
true
```

```julia
julia> isregular(A, X)
```

```ansi
true
```

```julia
julia> dims(A, isregular)
```

```ansi
([38;5;209m↓ [39m[38;5;209mX[39m Sampled{Int64} [38;5;209m10:-1:1[39m [38;5;244mReverseOrdered[39m [38;5;244mRegular[39m [38;5;244mPoints[39m,
[38;5;32m→ [39m[38;5;32mY[39m Sampled{Float64} [38;5;32m100.0:10.0:200.0[39m [38;5;244mForwardOrdered[39m [38;5;244mRegular[39m [38;5;244mPoints[39m)
```

```julia
julia> otherdims(A, isregular)
```

```ansi
()
```


== isexplicit

```julia
julia> isexplicit(A)
```

```ansi
false
```

```julia
julia> isexplicit(dims(A))
```

```ansi
false
```

```julia
julia> isexplicit(A, X)
```

```ansi
false
```

```julia
julia> dims(A, isexplicit)
```

```ansi
()
```

```julia
julia> otherdims(A, isexplicit)
```

```ansi
([38;5;209m↓ [39m[38;5;209mX[39m Sampled{Int64} [38;5;209m10:-1:1[39m [38;5;244mReverseOrdered[39m [38;5;244mRegular[39m [38;5;244mPoints[39m,
[38;5;32m→ [39m[38;5;32mY[39m Sampled{Float64} [38;5;32m100.0:10.0:200.0[39m [38;5;244mForwardOrdered[39m [38;5;244mRegular[39m [38;5;244mPoints[39m)
```


== isstart

```julia
julia> isstart(A)
```

```ansi
false
```

```julia
julia> isstart(dims(A))
```

```ansi
false
```

```julia
julia> isstart(A, X)
```

```ansi
false
```

```julia
julia> dims(A, isstart)
```

```ansi
()
```

```julia
julia> otherdims(A, isstart)
```

```ansi
([38;5;209m↓ [39m[38;5;209mX[39m Sampled{Int64} [38;5;209m10:-1:1[39m [38;5;244mReverseOrdered[39m [38;5;244mRegular[39m [38;5;244mPoints[39m,
[38;5;32m→ [39m[38;5;32mY[39m Sampled{Float64} [38;5;32m100.0:10.0:200.0[39m [38;5;244mForwardOrdered[39m [38;5;244mRegular[39m [38;5;244mPoints[39m)
```


== iscenter

```julia
julia> iscenter(A)
```

```ansi
true
```

```julia
julia> iscenter(dims(A))
```

```ansi
true
```

```julia
julia> iscenter(A, X)
```

```ansi
true
```

```julia
julia> dims(A, iscenter)
```

```ansi
([38;5;209m↓ [39m[38;5;209mX[39m Sampled{Int64} [38;5;209m10:-1:1[39m [38;5;244mReverseOrdered[39m [38;5;244mRegular[39m [38;5;244mPoints[39m,
[38;5;32m→ [39m[38;5;32mY[39m Sampled{Float64} [38;5;32m100.0:10.0:200.0[39m [38;5;244mForwardOrdered[39m [38;5;244mRegular[39m [38;5;244mPoints[39m)
```

```julia
julia> otherdims(A, iscenter)
```

```ansi
()
```


== isend

```julia
julia> isend(A)
```

```ansi
false
```

```julia
julia> isend(dims(A))
```

```ansi
false
```

```julia
julia> isend(A, X)
```

```ansi
false
```

```julia
julia> dims(A, isend)
```

```ansi
()
```

```julia
julia> otherdims(A, isend)
```

```ansi
([38;5;209m↓ [39m[38;5;209mX[39m Sampled{Int64} [38;5;209m10:-1:1[39m [38;5;244mReverseOrdered[39m [38;5;244mRegular[39m [38;5;244mPoints[39m,
[38;5;32m→ [39m[38;5;32mY[39m Sampled{Float64} [38;5;32m100.0:10.0:200.0[39m [38;5;244mForwardOrdered[39m [38;5;244mRegular[39m [38;5;244mPoints[39m)
```


:::
