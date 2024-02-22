# Stacks

An `AbstractDimStack` represents a collection of `AbstractDimArray`
layers that share some or all dimensions. For any two layers, a dimension
of the same name must have the identical lookup - in fact only one is stored
for all layers to enforce this consistency.


````@ansi stack
using DimensionalData
x, y = X(1.0:10.0), Y(5.0:10.0)
st = DimStack((a=rand(x, y), b=rand(x, y), c=rand(y), d=rand(x)))
````

The behaviour is somewhere ebetween a `NamedTuple` and an `AbstractArray`.

::::tabs

== getting layers

Layers can be accessed with `.name` or `[:name]`

````@ansi stack
st.a
st[:c]
````

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

::::

Indexing with `Dimensions`, `Selectors` works as with an `AbstractDimArray`, 
except it indexes for all layers at the same time, returning either a new
small `AbstractDimStack` or a scalar value, if all layers are scalars. 

Base functions like `mean`, `maximum`, `reverse` are applied to all layers of the stack.

`broadcast_dims` broadcasts functions over any mix of `AbstractDimStack` and
`AbstractDimArray` returning a new `AbstractDimStack` with layers the size of
the largest layer in the broadcast. This will work even if dimension permutation 
does not match in the objects.

# Performance 

Indexing stack is fast - indexing a single value return a `NamedTuple` from all layers
usingally, measures in nanoseconds. There are some compilation overheads to this
though, and stacks with very many layers can take a long time to compile.

````@ansi stack
using BenchmarkTools
@btime $st[X=1, Y=4]
@btime $st[1, 4]
````
