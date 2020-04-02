# Crash course

This is brief a tutorial for DimensionalData.jl.

The main functionality is explained here, but the full list of features is
listed at the [API](@ref) page.

## Dimensions and DimensionalArrays

The core type of DimensionalData.jl is the [`Dimension`](@ref) and the types
that inherit from it, such as `Ti`, `X`, `Y`, `Z`, the generic `Dim{:x}`, or
others that you define manually using the [`@dim`](@ref) macro.

`Dimension`s are primarily used in [`DimensionalArray`](@ref), other
[`AbstractDimensionalArray`](@ref).

We can use dimensions without a value index - these simply label the axis.
A `DimensionalArray` with labelled dimensions is constructed by:

```@example main
using DimensionalData
A = DimensionalArray(rand(5, 5), (X, Y))
```

But often we want to provide values for the dimension.

```@example main
using Dates
t = Ti(DateTime(2001):Month(1):DateTime(2001,12))
x = X(10:10:100)
```

Here both `X` and `Ti` are dimensions from `DimensionalData`. The currently
exported dimensions are `X, Y, Z, Ti`. `Ti` is shortening of `Time` -
to avoid the conflict with `Dates.Time`.

We pass a `Tuple` of the dimensions to the constructor of `DimensionalArray`,
after the array:

```@example main
A = DimensionalArray(rand(12, 10), (t, x))
```

The length of each dimension index has to match the size of the corresponding
array axis. 


## Indexing the array by name and index

Dimensions can be used to index the array by name, without having to worry
about the order of the dimensions.

The simplest case is to select a dimension by index. Let's say every 2nd point
of the `Ti` dimension and every 3rd point of the `X` dimension. This is done
with the simple `Ti(range)` syntax like so:

```@example main
A[X(1:3:end), Ti(1:2:end)]
```

Of course, when specifying only one dimension, all elements of the other
dimensions are assumed to be included:

```@example main
A[X(1:3:10)]
```

!!! info "Indexing"
    Indexing `AbstractDimensionalArray`s works with `getindex`, `setindex!` and
    `view`. The result is still an `AbstracDimensionalArray`.


## Selecting by name and value

The above example is useful because one does not have to care about the ordering
of the dimensions. But arguably more useful is to be able to select a dimension
by its values. For example, we would like to get all values of `A` where the `X`
dimension is between two values.

Selecting by value in `DimensionalData` is done with the **selectors**, which
are listed in the [Selectors](@ref) page. This avoids the ambiguity of what
happens when the index values of the dimension are also integers (like the case
here for the dimension `X`).

For simplicity, here we use the [`Between`](@ref) selector, but  others also
exist, like [`At`](@ref), [`Contains`](@ref), or [`Near`](@ref).

```@example main
A[X(Between(12, 35)), Ti(Between(Date(2001, 5), Date(2001, 7)))]
```

## Selecting by position

So far, the selection protocols we have mentioned work by specifying the _name_
of the dimension, without worry about the order.

However normal indexing also works by specifying dimensions by position. This
functionality also covers [`Selector`](@ref)s.

Continuing to use `A` we defined above, you can see how this works by comparing
the statements without and with names:

```@example main
A[:, Between(12, 35)] == A[X(Between(12, 35))]
A[:, 1:5] == A[X(1:5)]
A[1:5, :] == A[Ti(1:5)]
```

Using this approach it is necessary to specify _all_ dimensions by position. 

In addition, to support as base Julia functionality single index access like in
standard `Array`:

```@example main
A[1:5]
```

selects the first 5 entries of the underlying array. In the case that `A` has
only one dimension, it will be retained. Multidimensional
`AbstracDimensionalArray` indexed this way will return a regular array.



## Specifying `dims` keyword arguments with `Dimension`

In many Julia functions like `size, sum`, you can specify the dimension along
which to perform the operation, as an `Int`. It is also possible to do this
using `Dimension` types with `AbstractDimensionalArray`:

```@example main
sum(A; dims=X)
```

## Numeric operations on dimension arrays and dimensions

Numeric operations on a `AbstractDimensionalArray` match base Julia as much as
possible. Standard broadcasting and other type of operations across dimensional
arrays typically perform as expected while still returning an
`AbstractDimensionalArray` type with correct dimensions.

In cases where you would like to do some operation on the dimension index, e.g.
take the cosines of the values of the dimension `X` while still keeping the
dimensional information of `X`, you can use the syntax:

```@example main
DimensionalArray(cos, x)
```

## Referenced dimensions

The reference dimensions record the previous dimensions that an array
was selected from. These can be use for plot labelling, and tracking array
changes.


## IndexMode

DimensionalData provides types for specifying details about the dimension index.
This enables optimisations with `Selector`s, and modified behaviours such as
selection of intervals or points, which will give slightly different results for
selectors like [`Between`](@ref).

The major categories are [`Categorical`](@ref), [`Sampled`](@ref) and
[`NoIndex`](@ref), which are all types of [`Aligned`](@ref).
[`Unaligned`](@ref) also exists to handle dimensions with an index that is
rotated or otherwise transformed in relation to the underlying array, such as
[`Transformed`](@ref). These are a work in progress.

[`Aligned`] types will be detected automatically if not specified. A
Dimension containing and index of `String`, `Char` or `Symbol` will be labelled
with [`Categorical`](@ref). A range will be [`Sampled`](@ref),
defaulting to [`Points`](@ref) and [`Regular`](@ref). 

See the api docs for specifics about these [`IndexMode`](@ref)s.
