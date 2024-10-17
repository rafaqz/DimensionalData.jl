# Getters

DimensionalData.jl defines consistent methods to retrieve information
from objects like `DimArray`, `DimStack`, `Tuple`s of `Dimension`,
`Dimension`, and `Lookup`.

First, we will define an example `DimArray`.

```@example getters
using DimensionalData
using DimensionalData.Lookups
x, y = X(10:-1:1), Y(100.0:10:200.0)
```

```@ansi getters
A = rand(x, y)
```

::: tabs

== dims

`dims` retrieves dimensions from any object that has them.

What makes it so useful is that you can filter which dimensions
you want, and specify in what order, using any `Dimension`, `Type{Dimension}`
or `Symbol`.

```@ansi getters
dims(A)
dims(A, Y)
dims(A, Y())
dims(A, :Y)
dims(A, (X,))
dims(A, (Y, X))
dims(A, reverse(dims(A)))
dims(A, isregular)
```

== otherdims

`otherdims` is just like `dims` but returns whatever
`dims` would _not_ return from the same query.

```@ansi getters
otherdims(A, Y)
otherdims(A, Y())
otherdims(A, :Y)
otherdims(A, (X,))
otherdims(A, (Y, X))
otherdims(A, dims(A))
otherdims(A, isregular)
```

== lookup

Get all the `Lookup` in an object

```@ansi getters
lookup(A)
lookup(dims(A))
lookup(A, X)
lookup(dims(A, Y))
```

== val

`val` is used where there is an unambiguous single value:

```@ansi getters
val(X(7))
val(At(10.5))
```

== order

Get the order of a `Lookup`, or a `Tuple`
from a `DimArray` or `DimTuple`.

```@ansi getters
order(A)
order(dims(A))
order(A, X)
order(lookup(A, Y))
```

== sampling

Get the sampling of a `Lookup`, or a `Tuple`
from a `DimArray` or `DimTuple`.

```@ansi getters
sampling(A)
sampling(dims(A))
sampling(A, X)
sampling(lookup(A, Y))
```

== span

Get the span of a `Lookup`, or a `Tuple`
from a `DimArray` or `DimTuple`.

```@ansi getters
span(A)
span(dims(A))
span(A, X)
span(lookup(A, Y))
```

== locus

Get the locus of a `Lookup`, or a `Tuple`
from a `DimArray` or `DimTuple`.

(`locus` is our term for distinguishing if an lookup value
specifies the start, center, or end of an interval)

```@ansi getters
locus(A)
locus(dims(A))
locus(A, X)
locus(lookup(A, Y))
```

== bounds

Get the bounds of each dimension. This is different for `Points` 
and `Intervals` - the bounds for points of a `Lookup` are 
simply `(first(l), last(l))`.

```@ansi getters
bounds(A)
bounds(dims(A))
bounds(A, X)
bounds(lookup(A, Y))
```

== intervalbounds

Get the bounds of each interval along a dimension.

```@ansi getters
intervalbounds(A)
intervalbounds(dims(A))
intervalbounds(A, X)
intervalbounds(lookup(A, Y))
```

== extent

[Extents.jl](https://github.com/rafaqz/Extent) provides an `Extent` 
object that combines the names of dimensions with their bounds. 

```@ansi getters
using Extents: extent
extent(A)
extent(A, X)
extent(dims(A))
extent(dims(A, Y))
```

:::


## Predicates

These always return `true` or `false`. With multiple
dimensions, `false` means `!all` and `true` means `all`.

`dims` and all other methods listed above can use predicates
to filter the returned dimensions.

::: tabs

== issampled

```@ansi getters
issampled(A)
issampled(dims(A))
issampled(A, Y)
issampled(lookup(A, Y))
dims(A, issampled)
otherdims(A, issampled)
lookup(A, issampled)
```

== iscategorical

```@ansi getters
iscategorical(A)
iscategorical(dims(A))
iscategorical(dims(A, Y))
iscategorical(lookup(A, Y))
dims(A, iscategorical)
otherdims(A, iscategorical)
lookup(A, iscategorical)
```

== iscyclic

```@ansi getters
iscyclic(A)
iscyclic(dims(A))
iscyclic(dims(A, Y))
iscyclic(lookup(A, Y))
dims(A, iscyclic)
otherdims(A, iscyclic)
```

== isordered

```@ansi getters
isordered(A)
isordered(dims(A))
isordered(A, X)
isordered(lookup(A, Y))
dims(A, isordered)
otherdims(A, isordered)
```

== isforward

```@ansi getters
isforward(A)
isforward(dims(A))
isforward(A, X)
dims(A, isforward)
otherdims(A, isforward)
```

== isreverse

```@ansi getters
isreverse(A)
isreverse(dims(A))
isreverse(A, X)
dims(A, isreverse)
otherdims(A, isreverse)
```

== isintervals

```@ansi getters
isintervals(A)
isintervals(dims(A))
isintervals(A, X)
isintervals(lookup(A, Y))
dims(A, isintervals)
otherdims(A, isintervals)
```

== ispoints

```@ansi getters
ispoints(A)
ispoints(dims(A))
ispoints(A, X)
ispoints(lookup(A, Y))
dims(A, ispoints)
otherdims(A, ispoints)
```

== isregular

```@ansi getters
isregular(A)
isregular(dims(A))
isregular(A, X)
dims(A, isregular)
otherdims(A, isregular)
```

== isexplicit

```@ansi getters
isexplicit(A)
isexplicit(dims(A))
isexplicit(A, X)
dims(A, isexplicit)
otherdims(A, isexplicit)
```

== isstart

```@ansi getters
isstart(A)
isstart(dims(A))
isstart(A, X)
dims(A, isstart)
otherdims(A, isstart)
```

== iscenter

```@ansi getters
iscenter(A)
iscenter(dims(A))
iscenter(A, X)
dims(A, iscenter)
otherdims(A, iscenter)
```

== isend

```@ansi getters
isend(A)
isend(dims(A))
isend(A, X)
dims(A, isend)
otherdims(A, isend)
```

:::
