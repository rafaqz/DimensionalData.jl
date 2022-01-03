# Crash course

## Dimensions and DimArrays

The core type of DimensionalData.jl is the [`Dimension`](@ref) and the types
that inherit from it, such as `Ti`, `X`, `Y`, `Z`, the generic `Dim{:x}`, or
others that you define manually using the [`@dim`](@ref) macro.

`Dimension`s are primarily used in [`DimArray`](@ref), other
[`AbstractDimArray`](@ref).

We can use dimensions without a value index - these simply label the axis.
A `DimArray` with labelled dimensions is constructed by:

```@example main
using DimensionalData
A = rand(X(5), Y(5))
A[Y(1), X(2)]
```

As shown above, `Dimension`s can be used to construct arrays in `rand`, `ones`,
`zeros` and `fill` with either a range for a lookup index or a number for the
dimension length.

Or we can use the `Dim{X}` dims by using `Symbol`s, and indexing with keywords:

```@example main
A = DimArray(rand(5, 5), (:a, :b))
A[a=3, b=5]
```

Often, we want to provide a lookup index for the dimension:

```@example main
using Dates
t = DateTime(2001):Month(1):DateTime(2001,12)
x = 10:10:100
A = rand(X(x), Ti(t))
```

Here both `X` and `Ti` are dimensions from `DimensionalData`. The currently
exported dimensions are `X, Y, Z, Ti` (`Ti` is shortening of `Time`).

The length of each dimension index has to match the size of the corresponding
array axis. 

This can also be done with `Symbol`, using `Dim{X}`:

```@example main
A2 = DimArray(rand(12, 10), (time=t, distance=x))
```

Symbols can be more convenient to use than defining custom dims with `@dim`, but
have some downsides. They don't inherit from a specific `Dimension` type, so
plots will not know what axis to put them on. They also cannot use the basic
constructor methods like `rand` or `zeros`, as we cannot dispatch on `Symbol`
for Base methods without "type-piracy".


## Indexing the array by name and index

Dimensions can be used to index the array by name, without having to worry
about the order of the dimensions.

The simplest case is to select a dimension by index. Let's say every 2nd point
of the `Ti` dimension and every 3rd point of the `X` dimension. This is done
with the simple `Ti(range)` syntax like so:

```@example main
A[X(1:3:11), Ti(1:2:11)]
```

When specifying only one dimension, all elements of the other
dimensions are assumed to be included:

```@example main
A[X(1:3:10)]
```

!!! info "Indexing"
    Indexing `AbstractDimArray`s works with `getindex`, `setindex!` and
    `view`. The result is still an `AbstracDimArray`, unless using all single
    `Int` or `Selector`s that resolve to `Int`.


`Dimension`s can be used to construct arrays in `rand`, `ones`, `zeros` and
`fill` with either a range for a lookup index or a number for the dimension
length.

```@example ones
using DimensionalData
A1 = ones(X(1:40), Y(50))
```

We can also use dim wrappers for indexing, so that the dimension order in the underlying array
does not need to be known:

```@example ones
A1[Y(1), X(1:10)]
```

## Indexing Performance

Indexing with `Dimension` has no runtime cost:

```julia
julia> A2 = ones(X(3), Y(3))
3×3 DimArray{Float64,2} with dimensions: X, Y
 1.0  1.0  1.0
 1.0  1.0  1.0
 1.0  1.0  1.0

julia> @btime $A2[X(1), Y(2)]
  1.077 ns (0 allocations: 0 bytes)
1.0

julia> @btime parent($A2)[1, 2]
  1.078 ns (0 allocations: 0 bytes)
1.0
```

## Specifying `dims` keyword arguments with `Dimension`

In many Julia functions like `size` or `sum`, you can specify the dimension
along which to perform the operation as an `Int`. It is also possible to do this
using [`Dimension`](@ref) types with `AbstractDimArray`:

```@example main
A3 = rand(X(3), Y(4), Ti(5));
sum(A3; dims=Ti)
```

This also works in methods from `Statistics`:

```@example main
using Statistics
mean(A3; dims=Ti)
```

### Methods where dims, dim types, or `Symbol`s can be used to indicate the array dimension:

- `size`, `axes`, `firstindex`, `lastindex`
- `cat`, `reverse`, `dropdims`
- `reduce`, `mapreduce`
- `sum`, `prod`, `maximum`, `minimum`,
- `mean`, `median`, `extrema`, `std`, `var`, `cor`, `cov`
- `permutedims`, `adjoint`, `transpose`, `Transpose`
- `mapslices`, `eachslice`


## LookupArrays and Selectors

Indexing by value in `DimensionalData` is done with [Selectors](@ref).
IntervalSets.jl is now used for selecting ranges of values (formerly `Between`).


| Selector                | Description                                                         |
| :---------------------- | :------------------------------------------------------------------ |
| [`At(x)`]               | get the index exactly matching the passed in value(s)               |
| [`Near(x)`]             | get the closest index to the passed in value(s)                     |
| [`Contains(x)`]         | get indices where the value x falls within an interval              |
| [`Where(f)`]            | filter the array axis by a function of the dimension index values.  |
| [`a..b`]                | get all indices between two values, inclusively.                    |
| [`OpenInterval(a, b)`]  | get all indices between `a` and `b`, exclusively.                   |
| [`Interval{A,B}(a, b)`] | get all indices between `a` and `b`, as `:closed` or `:open`.       |


Selectors find indices in the `LookupArray`, for each dimension. 
Here we use an `Interval` to select a range between integers and `DateTime`:

```@example main
A[X(12..35), Ti(Date(2001, 5)..Date(2001, 7))]
```

Selectors can be used in `getindex`, `setindex!` and
`view` to select indices matching the passed in value(s)

We can use selectors inside dim wrappers, here selecting values from `DateTime` and `Int`:

```@example main
using Dates
timespan = DateTime(2001,1):Month(1):DateTime(2001,12)
A4 = rand(Ti(timespan), X(10:10:100))
A4[X(Near(35)), Ti(At(DateTime(2001,5)))]
```

Without dim wrappers selectors must be in the right order, and specify all axes:

```@example main
using Unitful
A5 = rand(Y((1:10:100)u"m"), Ti((1:5:100)u"s"));
A5[10.5u"m" .. 50.5u"m", Near(23u"s")]
```

We can also use Linear indices as in standard `Array`:

```@example main
A5[1:5]
```

But unless the `DimArray` is one dimensional, this will return a regular
`Array`. It is not possible to keep the `LookupArray` or even `Dimension`s after
linear indexing is used.

## LookupArrays and traits

Using a regular range or `Vector` as a lookup index has a number of downsides.
We cannot use `searchsorted` for fast searches without knowing the order of the
array, and this is slow to compute at runtime. It also means `reverse` or
rotations cannot be used while keeping the `DimArray` wrapper.

Step sizes are also a problem. Some ranges like `LinRange` lose their step size
with a length of `1`. Often, instead of a range, multi-dimensional data formats
provide a `Vector` of evenly spaced values for a lookup, with a step size
specified separately. Converting to a range introduces floating point errors
that means points may not be selected with `At` without setting tolerances.

This means using a lookup wrapper with traits is more generally robust and
versatile than simply using a range or vector. DimensionalData provides types
for specifying details about the dimension index, in the [`LookupArrays`](@ref)
sub-module:

```julia
using DimensionalData
using .LookupArrays
```

The main [`LookupArray`](@ref) are :

- [`Sampled`](@ref) 
- [`Categorical`](@ref),
- [`NoLookup`](@ref)

Each comes with specific traits that are either fixed or variable, depending
on the contained index. These enable optimisations with `Selector`s, and modified
behaviours, such as:

1. Selection of [`Intervals`](@ref) or [`Points`](@ref), which will give slightly
  different results for selectors like `..` - as whole intervals are
  selected, and have different `bounds` values.

2. Tracking of lookup order. A reverse order is labelled `ReverseOrdered` and
  will still work with `searchsorted`, and for plots to always be the right way
  up when either the index or the array is backwards. Reversing a `DimArray`
  will reverse the `LookupArray` for that dimension, swapping `ReverseOrdered`
  to `ForwardOrdered`.

3. `Sampled` [`Intervals`](@ref) can have index located at a [`Locus`](@ref) of: 

- [`Start`](@ref),
- [`Center`](@ref) 
- [`End`](@ref)

Which specifies the point of the interval represented in the index, to match
different data standards, e.g. GeoTIFF (`Start`) and NetCDF (`Center`).

4. A [`Span`](@ref) specifies the gap between `Points` or the size of
`Intervals`. This may be: 

- [`Regular`](@ref), in the case of a range and equally spaced vector, 
- [`Irregular`](@ref) for unequally spaced vectors
- [`Explicit`](@ref) for the case where all interval start and end points are
  specified explicitly - as is common in the NetCDF standard.

These traits all for subtypes of [`Aligned`](@ref).

[`Unaligned`](@ref) also exists to handle dimensions with an index that is
rotated or otherwise transformed in relation to the underlying array, such as
[`Transformed`](@ref).


## LookupArray detection

[`Aligned`](@ref) types will be detected automatically if not specified - which
usually isn't required. 

- An empty `Dimension` or a `Type` or `Symbol` will be assigned `NoLookup` -
  this behaves as a simple named dimension without a lookup index.
- A `Dimension` containing and index of `String`, `Char`, `Symbol` or mixed
  types will be given the [`Categorical`](@ref) mode,
- A range will be assigned [`Sampled`](@ref), defaulting to 
  [`Regular`](@ref), [`Points`](@ref) 
- Other `AbstractVector` will be assigned [`Sampled`](@ref) [`Irregular`](@ref)
  [`Points`](@ref).

In all cases the [`Order`](@ref) of [`ForwardOrdered`](@ref) or
[`ReverseOrdered`](@ref) will be be detected, otherwise [`Unordered`](@ref)
for an unsorted `Array`.

See the [`LookupArray`](@ref) API docs for more detail.

## Referenced dimensions

The reference dimensions record the previous dimensions that an array was
selected from. These can be use for plot labelling, and tracking array changes
so that `cat` can reconstruct the lookup array from previous dimensions that
have been sliced.

## Warnings

Indexing with unordered or reverse-ordered arrays has undefined behaviour.
It will trash the dimension index, break `searchsorted` and nothing will make
sense any more. So do it at you own risk.

However, indexing with sorted vectors of `Int` can be useful, so it's allowed.
But it may do strange things to interval sizes for [`Intervals`](@ref) that are
not [`Explicit`](@ref).

This selects the first 5 entries of the underlying array. In the case that `A`
has only one dimension, it will be retained. Multidimensional `AbstracDimArray`
indexed this way will return a regular array.
