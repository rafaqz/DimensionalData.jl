```@meta
Description = "DimStacks in DimensionalData.jl - collections of arrays sharing dimensions, combining NamedTuple and array-like behavior"
```

# DimStacks

An `AbstractDimStack` represents a collection of `AbstractDimArray`
layers that share some or all dimensions. For any two layers, a dimension
of the same name must have the identical lookup - in fact, only one is stored
for all layers to enforce this consistency.


````@ansi stack
using DimensionalData
x, y = X(1.0:10.0), Y(5.0:10.0)
st = DimStack((a=rand(x, y), b=rand(x, y), c=rand(y), d=rand(x)))
````

The behavior of a `DimStack` is at times like a `NamedTuple` of
`DimArray` and, at other times, an `AbstractArray` of `NamedTuple`.

## NamedTuple-like indexing

::: tabs

== getting layers

Layers can be accessed with `.name` or `[:name]`

````@ansi stack
st.a
st[:c]
````

== subsetting layers

We can subset layers with a `Tuple` of `Symbol`:

````@ansi stack
st[(:a, :c)]
````

== inverted subsets

`Not` works on `Symbol` keys just like it does on `Selector`:
It inverts the keys to give you a `DimStack` with all the other layers:

````@ansi stack
st[Not(:b)]
st[Not((:a, :c))]
````

== merging

We can merge a `DimStack` with another `DimStack`:

````@ansi stack
st2 = DimStack((m=rand(x, y), n=rand(x, y), o=rand(y)))
merge(st, st2)
````

Or merge a `DimStack` with a `NamedTuple` of `DimArray`:

````@ansi stack
merge(st, (; d = rand(y, x), e = rand(y)))
````

Merging only works when dimensions match: 

````@ansi stack
merge(st, (; d = rand(Y('a':'n'))))
````

:::


## Array-like indexing

::: tabs

== scalars

Indexing with a scalar returns a `NamedTuple` of values, one for each layer:

````@ansi stack
st[X=1, Y=4]
````

== selectors

Selectors for single values also return a `NamedTuple`

````@ansi stack
st[X=At(2.0), Y=Near(20)]
````

== partial indexing

If not all dimensions are scalars, we return another `DimStack`.
The layers without another dimension are now zero-dimensional:

````@ansi stack
st[X=At(2.0)]
````

== linear indexing

If we index with `:` we get a `Vector{<:NamedTuple}`

````@ansi stack
st[:]
````

:::

## Reducing functions

Base functions like `mean`, `maximum`, `reverse` are applied to all layers of the stack.

````@example stack
using Statistics
````

::: tabs

== maximum

````@ansi stack
maximum(st)
maximum(st; dims=Y)
````

== minimum

````@ansi stack
minimum(st)
minimum(st; dims=Y)
````

== sum

````@ansi stack
sum(st)
sum(st; dims=Y)
````

== prod

````@ansi stack
prod(st)
prod(st; dims=Y)
````

== mean

````@ansi stack
mean(st)
mean(st; dims=Y)
````

== std

````@ansi stack
std(st)
std(st; dims=Y)
````

== var

````@ansi stack
var(st)
var(st; dims=Y)
````

== reduce

````@ansi stack
reduce(+, st)
reduce(+, st; dims=Y)
````

== extrema

````@ansi stack
extrema(st)
extrema(st; dims=Y)
````

== dropdims

````@ansi stack
sum_st = sum(st; dims=Y)
dropdims(sum_st; dims=Y)
````

:::

[`broadcast_dims`](@ref) broadcasts functions over any mix of `AbstractDimStack` and
`AbstractDimArray` returning a new `AbstractDimStack` with layers the size of
the largest layer in the broadcast. This will work even if dimension permutation 
does not match in the objects.


::: tabs

== rotl90

Only matrix layers can be rotated

````@ansi stack
rotl90(st[(:a, :b)])
rotl90(st[(:a, :b)], 2)
````

== rotr90

````@ansi stack
rotr90(st[(:a, :b)])
rotr90(st[(:a, :b)], 2)
````

== rot180

````@ansi stack
rot180(st[(:a, :b)])
rot180(st[(:a, :b)], 2)
````

== permutedims

````@ansi stack
permutedims(st)
permutedims(st, (2, 1))
permutedims(st, (Y, X))
````

== transpose

````@ansi stack
transpose(st)
````

== adjoint

````@ansi stack
adjoint(st)
st'
````

== PermutedDimsArray

````@ansi stack
PermutedDimsArray(st, (2, 1))
PermutedDimsArray(st, (Y, X))
````

:::

## Performance 

Indexing a stack is fast - indexing a single value and returning a `NamedTuple` from all 
layers is usually measured in nanoseconds, and no slower than manually indexing
into each parent array directly.

There are some compilation overheads to this though, and stacks with very many 
layers can take a long time to compile.

````@ansi stack
using BenchmarkTools
@btime $st[X=1, Y=4]
@btime $st[1, 4]
````
