
# Modifying Objects {#Modifying-Objects}

DimensionalData.jl objects are all `struct` rather than `mutable struct`. The only things you can modify in-place are the values of the contained arrays or metadata `Dict`s if they exist.

Everything else must be _rebuilt_ and assigned to a variable.

## `modify` {#modify}

Modify the inner arrays of a `AbstractDimArray` or `AbstractDimStack`, with [`modify`](/object_modification#modify). This can be useful to e.g. replace all arrays with `CuArray` moving the data to the GPU, `collect` all inner arrays to `Array` without losing the outer `DimArray` wrappers, and similar things.

::::tabs

== array

```julia
julia> using DimensionalData

julia> A = falses(X(3), Y(5))
```

```ansi
[90m┌ [39m[38;5;209m3[39m×[38;5;32m5[39m DimArray{Bool, 2}[90m ┐[39m
[90m├───────────────── dims ┤[39m
  [38;5;209m↓ [39m[38;5;209mX[39m, [38;5;32m→ [39m[38;5;32mY[39m
[90m└───────────────────────┘[39m
 0  0  0  0  0
 0  0  0  0  0
 0  0  0  0  0
```

```julia
julia> parent(A)
```

```ansi
3×5 BitMatrix:
 0  0  0  0  0
 0  0  0  0  0
 0  0  0  0  0
```

```julia
julia> A_mod = modify(Array, A)
```

```ansi
[90m┌ [39m[38;5;209m3[39m×[38;5;32m5[39m DimArray{Bool, 2}[90m ┐[39m
[90m├───────────────── dims ┤[39m
  [38;5;209m↓ [39m[38;5;209mX[39m, [38;5;32m→ [39m[38;5;32mY[39m
[90m└───────────────────────┘[39m
 0  0  0  0  0
 0  0  0  0  0
 0  0  0  0  0
```

```julia
julia> parent(A_mod)
```

```ansi
3×5 Matrix{Bool}:
 0  0  0  0  0
 0  0  0  0  0
 0  0  0  0  0
```


== stack

For a stack, this applies to all layers, and is where `modify` starts to be more powerful:

```julia
julia> st = DimStack((a=falses(X(3), Y(5)), b=falses(X(3), Y(5))))
```

```ansi
[90m┌ [39m[38;5;209m3[39m×[38;5;32m5[39m DimStack[90m ┐[39m
[90m├──────────────┴────────────────── dims ┐[39m
  [38;5;209m↓ [39m[38;5;209mX[39m, [38;5;32m→ [39m[38;5;32mY[39m
[90m├─────────────────────────────── layers ┤[39m
[38;5;37m  :a[39m[90m eltype: [39mBool[90m dims: [39m[38;5;209mX[39m, [38;5;32mY[39m[90m size: [39m[38;5;209m3[39m×[38;5;32m5[39m
[38;5;37m  :b[39m[90m eltype: [39mBool[90m dims: [39m[38;5;209mX[39m, [38;5;32mY[39m[90m size: [39m[38;5;209m3[39m×[38;5;32m5[39m
[90m└───────────────────────────────────────┘[39m
```

```julia
julia> parent(st.a)
```

```ansi
3×5 BitMatrix:
 0  0  0  0  0
 0  0  0  0  0
 0  0  0  0  0
```

```julia
julia> parent(modify(Array, st).a)
```

```ansi
3×5 Matrix{Bool}:
 0  0  0  0  0
 0  0  0  0  0
 0  0  0  0  0
```

```julia
julia> parent(modify(Array, st).b)
```

```ansi
3×5 Matrix{Bool}:
 0  0  0  0  0
 0  0  0  0  0
 0  0  0  0  0
```


::::

## `reorder` {#reorder}

[`reorder`](/object_modification#reorder) is like reverse but declarative, rather than imperative: we tell it how we want the object to be, not what to do.

::::tabs

== specific dimension/s

Reorder a specific dimension

```julia
julia> using DimensionalData.Lookups;

julia> A = rand(X(1.0:3.0), Y('a':'n'));

julia> reorder(A, X => ReverseOrdered())
```

```ansi
[90m┌ [39m[38;5;209m3[39m×[38;5;32m14[39m DimArray{Float64, 2}[90m ┐[39m
[90m├───────────────────────────┴───────────────────────────────── dims ┐[39m
  [38;5;209m↓ [39m[38;5;209mX[39m Sampled{Float64} [38;5;209m3.0:-1.0:1.0[39m [38;5;244mReverseOrdered[39m [38;5;244mRegular[39m [38;5;244mPoints[39m,
  [38;5;32m→ [39m[38;5;32mY[39m Categorical{Char} [38;5;32m'a':1:'n'[39m [38;5;244mForwardOrdered[39m
[90m└───────────────────────────────────────────────────────────────────┘[39m
 [38;5;209m↓[39m [38;5;32m→[39m   [38;5;32m'a'[39m       [38;5;32m'b'[39m         [38;5;32m'c'[39m      …   [38;5;32m'l'[39m       [38;5;32m'm'[39m        [38;5;32m'n'[39m
 [38;5;209m3.0[39m  0.664038  0.602315    0.589564     0.85775   0.0684288  0.925042
 [38;5;209m2.0[39m  0.654537  0.639212    0.153219     0.711697  0.761295   0.202744
 [38;5;209m1.0[39m  0.380662  0.00832284  0.375166     0.969435  0.484251   0.475818
```


== all dimensions

```julia
julia> reorder(A, ReverseOrdered())
```

```ansi
[90m┌ [39m[38;5;209m3[39m×[38;5;32m14[39m DimArray{Float64, 2}[90m ┐[39m
[90m├───────────────────────────┴───────────────────────────────── dims ┐[39m
  [38;5;209m↓ [39m[38;5;209mX[39m Sampled{Float64} [38;5;209m3.0:-1.0:1.0[39m [38;5;244mReverseOrdered[39m [38;5;244mRegular[39m [38;5;244mPoints[39m,
  [38;5;32m→ [39m[38;5;32mY[39m Categorical{Char} [38;5;32m'n':-1:'a'[39m [38;5;244mReverseOrdered[39m
[90m└───────────────────────────────────────────────────────────────────┘[39m
 [38;5;209m↓[39m [38;5;32m→[39m   [38;5;32m'n'[39m       [38;5;32m'm'[39m        [38;5;32m'l'[39m      …   [38;5;32m'c'[39m       [38;5;32m'b'[39m         [38;5;32m'a'[39m
 [38;5;209m3.0[39m  0.925042  0.0684288  0.85775      0.589564  0.602315    0.664038
 [38;5;209m2.0[39m  0.202744  0.761295   0.711697     0.153219  0.639212    0.654537
 [38;5;209m1.0[39m  0.475818  0.484251   0.969435     0.375166  0.00832284  0.380662
```


::::

## `mergedims` {#mergedims}

[`mergedims`](/object_modification#mergedims) is like `reshape`, but simultaneously merges multiple dimensions into a single combined dimension with a lookup holding `Tuples` of the values of both dimensions.

## `rebuild` {#rebuild}

[`rebuild`](/api/reference#DimensionalData.Dimensions.Lookups.rebuild) is one of the core functions of DimensionalData.jl. Basically everything uses it somewhere. And you can too, with a few caveats.

::: warning Warning

`rebuild` assumes you _know what you are doing_. You can quite easily set values to things that don&#39;t make sense. The constructor may check a few things, like the number of dimensions matches the axes of the array. But not much else.

:::

:::: tabs

== change the name

```julia
julia> A1 = rebuild(A; name=:my_array)
```

```ansi
[90m┌ [39m[38;5;209m3[39m×[38;5;32m14[39m DimArray{Float64, 2}[38;5;37m my_array[39m[90m ┐[39m
[90m├────────────────────────────────────┴─────────────────────── dims ┐[39m
  [38;5;209m↓ [39m[38;5;209mX[39m Sampled{Float64} [38;5;209m1.0:1.0:3.0[39m [38;5;244mForwardOrdered[39m [38;5;244mRegular[39m [38;5;244mPoints[39m,
  [38;5;32m→ [39m[38;5;32mY[39m Categorical{Char} [38;5;32m'a':1:'n'[39m [38;5;244mForwardOrdered[39m
[90m└──────────────────────────────────────────────────────────────────┘[39m
 [38;5;209m↓[39m [38;5;32m→[39m   [38;5;32m'a'[39m       [38;5;32m'b'[39m         [38;5;32m'c'[39m      …   [38;5;32m'l'[39m       [38;5;32m'm'[39m        [38;5;32m'n'[39m
 [38;5;209m1.0[39m  0.380662  0.00832284  0.375166     0.969435  0.484251   0.475818
 [38;5;209m2.0[39m  0.654537  0.639212    0.153219     0.711697  0.761295   0.202744
 [38;5;209m3.0[39m  0.664038  0.602315    0.589564     0.85775   0.0684288  0.925042
```

```julia
julia> name(A1)
```

```ansi
:my_array
```


== change the metadata

```julia
julia> A1 = rebuild(A; metadata=Dict(:a => "foo", :b => "bar"))
```

```ansi
[90m┌ [39m[38;5;209m3[39m×[38;5;32m14[39m DimArray{Float64, 2}[90m ┐[39m
[90m├───────────────────────────┴──────────────────────────────── dims ┐[39m
  [38;5;209m↓ [39m[38;5;209mX[39m Sampled{Float64} [38;5;209m1.0:1.0:3.0[39m [38;5;244mForwardOrdered[39m [38;5;244mRegular[39m [38;5;244mPoints[39m,
  [38;5;32m→ [39m[38;5;32mY[39m Categorical{Char} [38;5;32m'a':1:'n'[39m [38;5;244mForwardOrdered[39m
[90m├──────────────────────────────────────────────────────── metadata ┤[39m
  Dict{Symbol, String} with 2 entries:
  :a => "foo"
  :b => "bar"
[90m└──────────────────────────────────────────────────────────────────┘[39m
 [38;5;209m↓[39m [38;5;32m→[39m   [38;5;32m'a'[39m       [38;5;32m'b'[39m         [38;5;32m'c'[39m      …   [38;5;32m'l'[39m       [38;5;32m'm'[39m        [38;5;32m'n'[39m
 [38;5;209m1.0[39m  0.380662  0.00832284  0.375166     0.969435  0.484251   0.475818
 [38;5;209m2.0[39m  0.654537  0.639212    0.153219     0.711697  0.761295   0.202744
 [38;5;209m3.0[39m  0.664038  0.602315    0.589564     0.85775   0.0684288  0.925042
```

```julia
julia> metadata(A1)
```

```ansi
Dict{Symbol, String} with 2 entries:
  :a => "foo"
  :b => "bar"
```


::::

The most common use internally is the arg version on `Dimension`. This is _very_ useful in dimension-based algorithms as a way to transform a dimension wrapper from one object to another:

```julia
julia> d = X(1)
```

```ansi
[38;5;209mX[39m [38;5;1m1[39m
```

```julia
julia> rebuild(d, 1:10)
```

```ansi
[38;5;209mX[39m [37m1:10[39m
```


`rebuild` applications are listed here. `AbstractDimArray` and `AbstractDimStack` _always_ accept these keywords or arguments, but those in [ ] brackets may be thrown away if not needed. Keywords in ( ) will error if used where they are not accepted.

| Type                                                                        | Keywords                                                                | Arguments            |
|:--------------------------------------------------------------------------- |:----------------------------------------------------------------------- |:-------------------- |
| [`AbstractDimArray`](/api/reference#DimensionalData.AbstractDimArray)       | `data`, `dims`, [`refdims`, `name`, `metadata`]                         | as with kw, in order |
| [`AbstractDimStack`](/api/reference#DimensionalData.AbstractDimStack)       | `data`, `dims`, [`refdims`], `layerdims`, [`metadata`, `layermetadata`] | as with kw, in order |
| [`Dimension`](/api/dimensions#DimensionalData.Dimensions.Dimension)         | `val`                                                                   | val                  |
| [`Selector`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.Selector) | `val`, (`atol`)                                                         | val                  |
| [`Lookup`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.Lookup)     | `data`, (`order`, `span`, `sampling`, `metadata`)                       | keywords only        |


### `rebuild` magic {#rebuild-magic}

`rebuild` with keywords will even work on objects DD doesn&#39;t know about!

```julia
julia> nt = (a = 1, b = 2)
```

```ansi
(a = 1, b = 2)
```

```julia
julia> rebuild(nt, a = 99)
```

```ansi
(a = 99, b = 2)
```


Really, the keyword version is just `ConstructionBase.setproperties` underneath, but wrapped so objects can customise the DD interface without changing the more generic ConstructionBase.jl behaviours and breaking e.g. Accessors.jl in the process.

## `set` {#set}

[`set`](/object_modification#set) gives us a way to set the values of the immutable objects in DD, like `Dimension` and `LookupArray`. Unlike `rebuild` it tries its best to _do the right thing_. You don&#39;t have to specify what field you want to set. Just pass in the object you want to be part of the lookup. Usually, there is no possible ambiguity.

`set` is still improving. Sometimes it may not do the right thing. If you think this is the case, create a [GitHub issue](https://github.com/rafaqz/DimensionalData.jl/issues).

:::: tabs

=== set the dimension wrapper

```julia
julia> set(A, Y => Z)
```

```ansi
[90m┌ [39m[38;5;209m3[39m×[38;5;32m14[39m DimArray{Float64, 2}[90m ┐[39m
[90m├───────────────────────────┴──────────────────────────────── dims ┐[39m
  [38;5;209m↓ [39m[38;5;209mX[39m Sampled{Float64} [38;5;209m1.0:1.0:3.0[39m [38;5;244mForwardOrdered[39m [38;5;244mRegular[39m [38;5;244mPoints[39m,
  [38;5;32m→ [39m[38;5;32mZ[39m Categorical{Char} [38;5;32m'a':1:'n'[39m [38;5;244mForwardOrdered[39m
[90m└──────────────────────────────────────────────────────────────────┘[39m
 [38;5;209m↓[39m [38;5;32m→[39m   [38;5;32m'a'[39m       [38;5;32m'b'[39m         [38;5;32m'c'[39m      …   [38;5;32m'l'[39m       [38;5;32m'm'[39m        [38;5;32m'n'[39m
 [38;5;209m1.0[39m  0.380662  0.00832284  0.375166     0.969435  0.484251   0.475818
 [38;5;209m2.0[39m  0.654537  0.639212    0.153219     0.711697  0.761295   0.202744
 [38;5;209m3.0[39m  0.664038  0.602315    0.589564     0.85775   0.0684288  0.925042
```


=== clear the lookups

```julia
julia> set(A, X => NoLookup, Y => NoLookup)
```

```ansi
[90m┌ [39m[38;5;209m3[39m×[38;5;32m14[39m DimArray{Float64, 2}[90m ┐[39m
[90m├───────────────────── dims ┤[39m
  [38;5;209m↓ [39m[38;5;209mX[39m, [38;5;32m→ [39m[38;5;32mY[39m
[90m└───────────────────────────┘[39m
 0.380662  0.00832284  0.375166  0.936831  …  0.969435  0.484251   0.475818
 0.654537  0.639212    0.153219  0.876112     0.711697  0.761295   0.202744
 0.664038  0.602315    0.589564  0.749253     0.85775   0.0684288  0.925042
```


=== set different lookup values

```julia
julia> set(A, Y => 10:10:140)
```

```ansi
[90m┌ [39m[38;5;209m3[39m×[38;5;32m14[39m DimArray{Float64, 2}[90m ┐[39m
[90m├───────────────────────────┴──────────────────────────────── dims ┐[39m
  [38;5;209m↓ [39m[38;5;209mX[39m Sampled{Float64} [38;5;209m1.0:1.0:3.0[39m [38;5;244mForwardOrdered[39m [38;5;244mRegular[39m [38;5;244mPoints[39m,
  [38;5;32m→ [39m[38;5;32mY[39m Categorical{Int64} [38;5;32m10:10:140[39m [38;5;244mForwardOrdered[39m
[90m└──────────────────────────────────────────────────────────────────┘[39m
 [38;5;209m↓[39m [38;5;32m→[39m  [38;5;32m10[39m         [38;5;32m20[39m           …  [38;5;32m120[39m         [38;5;32m130[39m          [38;5;32m140[39m
 [38;5;209m1.0[39m   0.380662   0.00832284       0.969435    0.484251     0.475818
 [38;5;209m2.0[39m   0.654537   0.639212         0.711697    0.761295     0.202744
 [38;5;209m3.0[39m   0.664038   0.602315         0.85775     0.0684288    0.925042
```


=== set lookup type as well as values

Change the values but also set the type to Sampled. TODO: broken

```julia
julia> set(A, Y => Sampled(10:10:140))
```

```ansi
[90m┌ [39m[38;5;209m3[39m×[38;5;32m14[39m DimArray{Float64, 2}[90m ┐[39m
[90m├───────────────────────────┴──────────────────────────────── dims ┐[39m
  [38;5;209m↓ [39m[38;5;209mX[39m Sampled{Float64} [38;5;209m1.0:1.0:3.0[39m [38;5;244mForwardOrdered[39m [38;5;244mRegular[39m [38;5;244mPoints[39m,
  [38;5;32m→ [39m[38;5;32mY[39m Sampled{Int64} [38;5;32m10:10:140[39m [38;5;244mForwardOrdered[39m [38;5;244mNoSpan[39m [38;5;244mNoSampling[39m
[90m└──────────────────────────────────────────────────────────────────┘[39m
 [38;5;209m↓[39m [38;5;32m→[39m  [38;5;32m10[39m         [38;5;32m20[39m           …  [38;5;32m120[39m         [38;5;32m130[39m          [38;5;32m140[39m
 [38;5;209m1.0[39m   0.380662   0.00832284       0.969435    0.484251     0.475818
 [38;5;209m2.0[39m   0.654537   0.639212         0.711697    0.761295     0.202744
 [38;5;209m3.0[39m   0.664038   0.602315         0.85775     0.0684288    0.925042
```


=== set the points in X to be intervals

```julia
julia> set(A, X => Intervals)
```

```ansi
[90m┌ [39m[38;5;209m3[39m×[38;5;32m14[39m DimArray{Float64, 2}[90m ┐[39m
[90m├───────────────────────────┴─────────────────────────────────────────── dims ┐[39m
  [38;5;209m↓ [39m[38;5;209mX[39m Sampled{Float64} [38;5;209m1.0:1.0:3.0[39m [38;5;244mForwardOrdered[39m [38;5;244mRegular[39m [38;5;244mIntervals{Center}[39m,
  [38;5;32m→ [39m[38;5;32mY[39m Categorical{Char} [38;5;32m'a':1:'n'[39m [38;5;244mForwardOrdered[39m
[90m└─────────────────────────────────────────────────────────────────────────────┘[39m
 [38;5;209m↓[39m [38;5;32m→[39m   [38;5;32m'a'[39m       [38;5;32m'b'[39m         [38;5;32m'c'[39m      …   [38;5;32m'l'[39m       [38;5;32m'm'[39m        [38;5;32m'n'[39m
 [38;5;209m1.0[39m  0.380662  0.00832284  0.375166     0.969435  0.484251   0.475818
 [38;5;209m2.0[39m  0.654537  0.639212    0.153219     0.711697  0.761295   0.202744
 [38;5;209m3.0[39m  0.664038  0.602315    0.589564     0.85775   0.0684288  0.925042
```


=== set the categories in Y to be `Unordered`

```julia
julia> set(A, Y => Unordered)
```

```ansi
[90m┌ [39m[38;5;209m3[39m×[38;5;32m14[39m DimArray{Float64, 2}[90m ┐[39m
[90m├───────────────────────────┴──────────────────────────────── dims ┐[39m
  [38;5;209m↓ [39m[38;5;209mX[39m Sampled{Float64} [38;5;209m1.0:1.0:3.0[39m [38;5;244mForwardOrdered[39m [38;5;244mRegular[39m [38;5;244mPoints[39m,
  [38;5;32m→ [39m[38;5;32mY[39m Categorical{Char} [38;5;32m'a':1:'n'[39m [38;5;244mUnordered[39m
[90m└──────────────────────────────────────────────────────────────────┘[39m
 [38;5;209m↓[39m [38;5;32m→[39m   [38;5;32m'a'[39m       [38;5;32m'b'[39m         [38;5;32m'c'[39m      …   [38;5;32m'l'[39m       [38;5;32m'm'[39m        [38;5;32m'n'[39m
 [38;5;209m1.0[39m  0.380662  0.00832284  0.375166     0.969435  0.484251   0.475818
 [38;5;209m2.0[39m  0.654537  0.639212    0.153219     0.711697  0.761295   0.202744
 [38;5;209m3.0[39m  0.664038  0.602315    0.589564     0.85775   0.0684288  0.925042
```


:::
