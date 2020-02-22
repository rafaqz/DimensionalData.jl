# Crash course

This is brief a tutorial for DimensionalData.jl.

All main functionality is explained here, but the full list of features is
listed at the [API](@ref) page.

## Dimensions and DimensionalArrays

The core type of DimensionalData.jl is [`DimensionalArray`](@ref), which bundles
a standard array with named and indexed dimensions. The dimensions are any
`AbstractDimension`, and types that inherit from it, such as `Ti`, `X`, `Y`,
`Z`, the generic `Dim{:x}` or others that you define manually using the
[`@dim`](@ref) macro.

A `DimensionalArray` dimensions are constructed by:

```@example main
using DimensionalData, Dates
t = Ti(DateTime(2001):Month(1):DateTime(2001,12))
x = X(10:10:100)
```

Here both `X` and `Ti` are dimensions from the `DimensionalData` module. The
currently exported predefined dimensions are `X, Y, Z, Ti`, with `Ti` an alias
of `DimensionalData.Time` (to avoid the conflict with `Dates.Time`).

We pass a `Tuple` of the dimensions to make a `DimensionalArray`:

```@example main
A = DimensionalArray(rand(12, 10), (t, x))
```


## Indexing the array by name and index

These dimensions can then be used to index the array by name, without having to
worry about the order of the dimensions.

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

Selecting by value in `DimensionalData` is **always** done with the
**selectors**, all of which are listed in the [Selectors](@ref) page. This
avoids the ambiguity of what happens when the index values of the dimension are
also integers (like the case here for the dimension `X`).

For simplicity, here we showcase the [`Between`](@ref) selector but  others also
exist, like [`At`](@ref) or [`Near`](@ref).

```@example main
A[X(Between(12, 35)), Ti(Between(Date(2001, 5), Date(2001, 7)))]
```

Notice that the selectors have to be applied to a dimension (alternative syntax
is `selector <| Dim`, which literally translates to `Dim(selector)`).


## Selecting by position

So far, the selection protocols we have mentioned work by specifying the _name_
of the dimension, without worry about the order.

However normal indexing also works by specifying dimensions by position. This
functionality also covers the selector functions.

Continuing to use `A` we defined above, you can see this by comparing the
statements without and with names:

```@example main
A[:, Between(12, 35)] == A[X(Between(12, 35))]
A[:, 1:5] == A[X(1:5)]
A[1:5, :] == A[Ti(1:5)]
```

etc. Of course, in this approach it is necessary to specify _all_ dimensions by
position, one cannot leave some unspecified.

In addition, to attempt supporting as much as base Julia functionality as
possible, single index access like in standard `Array`. For example

```@example main
A[1:5]
```

selects the first 5 entries of the underlying numerical data. In the case that
`A` has only one dimension, this kind of indexing retains the dimension.


## Specifying `dims` by dimension name

In many Julia functions like `size, sum`, you can specify the dimension along
which to perform the operation, as an Int. It is also possible to do this using
Dim types with `AbstractDimensionalArray` by specifying the dimension by its
type, for example:

```@example main
sum(A; dims = X)
```

## Numeric operations on dimension arrays and dimensions

We have tried to make all numeric operations on a `AbstractDimensionalArray` match 
base Julia as much as possible. Standard broadcasting and other type of operations 
across dimensional arrays typically perform as expected while still 
returning an `AbstractDimensionalArray` type with correct dimensions.

In cases where you would like to do some operation on the dimension index, e.g. 
take the cosines of the values of the dimension `X` while still keeping the dimensional 
information of `X`, you can use the syntax:

```@example main
DimensionalArray(cos, x)
```

## Referenced dimensions

The reference dimensions record the previous dimensions that an array
was selected from. These can be use for plot labelling, and tracking array
changes.

## Grid functionality

Coming soon.
