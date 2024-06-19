# Modifying objects

DimensionalData.jl objects are all `struct` rather than
`mutable struct`. The only things you can modify in-place
are the values of the contained arrays or metadata `Dict`s if
they exist.

Everything else must be _rebuilt_ and assigned to a variable.

## `modify`

Modify the inner arrays of a `AbstractDimArray` or `AbstractDimStack`, with
[`modify`](@ref). This can be useful to e.g. replace all arrays with `CuArray`
moving the data to the GPU, `collect` all inner arrays to `Array` without losing
the outer `DimArray` wrappers, and similar things.

::::tabs

== array

````@ansi helpers
using DimensionalData
A = falses(X(3), Y(5))
parent(A)
A_mod = modify(Array, A)
parent(A_mod)
````

== stack

For a stack this applied to all layers, and is where `modify`
starts to be more powerful:

````@ansi helpers
st = DimStack((a=falses(X(3), Y(5)), b=falses(X(3), Y(5))))
parent(st.a)
parent(modify(Array, st).a)
parent(modify(Array, st).b)
````

::::

## `reorder`

[`reorder`](@ref) is like reverse but declarative, rather than
imperative: we tell it how we want the object to be, not what to do.

::::tabs

== specific dimension/s

Reorder a specific dimension

````@ansi helpers
using DimensionalData.Lookups;
A = rand(X(1.0:3.0), Y('a':'n'));
reorder(A, X => ReverseOrdered())
````

== all dimensions

````@ansi helpers
reorder(A, ReverseOrdered())
````

::::

## `mergedims`

[`mergedims`](@ref) is like `reshape`, but simultaneously merges multiple
dimensions into a single combined dimension with a lookup holding
`Tuples` of the values of both dimensions.


## `rebuild`

[`rebuild`](@ref) is one of the core functions of DimensionalData.jl.
Basically everything uses it somewhere. And you can too, with a few caveats.

`rebuild` assumes you _know what you are doing_. You can quite eaily set
values to things that don't make sense. The constructor may check a few things,
like the number of dimensions matches the axes of the array. But not much else.

:::: tabs

== change the name

````@ansi helpers
A1 = rebuild(A; name=:my_array)
name(A1)
````

== change the metadata

````@ansi helpers
A1 = rebuild(A; metadata=Dict(:a => "foo", :b => "bar"))
metadata(A1)
````

::::

The most common use internally is the arg version on `Dimension`.
This is _very_ useful in dimension-based algorithms as a way
to transform a dimension wrapper from one object to another:

```@ansi helpers
d = X(1)
rebuild(d, 1:10)
```

`rebuild` applications are listed here. `AbstractDimArray` and
`AbstractDimStack` _always_ accept these keywords or arguments,
but those in [ ] brackets may be thrown away if not needed.
Keywords in ( ) will error if used where they are not accepted.

| Type                       | Keywords                                                    | Arguments            |
|--------------------------- |------------------------------------------------------------ |----------------------|
| [`AbstractDimArray`](@ref) | data, dims, [refdims, name, metadata]                       | as with kw, in order |
| [`AbstractDimStack`](@ref) | data, dims, [refdims], layerdims, [metadata, layermetadata] | as with kw, in order |
| [`Dimension`](@ref)        | val                                                         | val                  |
| [`Selector`](@ref)         | val, (atol)                                                 | val                  |
| [`Lookup`](@ref)      | data, (order, span, sampling, metadata)                     | keywords only        |

### `rebuild` magic

`rebuild` with keywords will even work on objects DD doesn't know about!

````@ansi helpers
nt = (a = 1, b = 2)
rebuild(nt, a = 99)
````

Really, the keyword version is just `ConstructionBase.setproperties` underneath,
but wrapped so objects can customise the DD interface without changing the
more generic ConstructionBase.jl behaviours and breaking e.g. Accessors.jl in
the process.

## `set`

[`set`](@ref) gives us a way to set the values of the immutable objects
in DD, like `Dimension` and `LookupArray`. Unlike `rebuild` it tries its best
to _do the right thing_. You don't have to specify what field you want to set.
Just pass in the object you want to be part of the lookup. Usually, there is
no possible ambiguity.

`set` is still improving. Sometimes it may not do the right thing.
If you think this is the case, create a
[GitHub issue](https://github.com/rafaqz/DimensionalData.jl/issues).

:::: tabs

=== set the dimension wrapper

````@ansi helpers
set(A, Y => Z)
````

=== clear the lookups

````@ansi helpers
set(A, X => NoLookup, Y => NoLookup)
````

=== set different lookup values

````@ansi helpers
set(A, Y => 10:10:140)
````

=== set lookup type as well as values

Change the values but also set the type to Sampled. TODO: broken

````@ansi helpers
set(A, Y => Sampled(10:10:140))
````

=== set the points in X to be intervals

````@ansi helpers
set(A, X => Intervals)
````

=== set the categories in Y to be `Unordered`

````@ansi helpers
set(A, Y => Unordered)
````

:::
