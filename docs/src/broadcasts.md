# Dimensional broadcasts with `@d` and `broadcast_dims`

Broadcasting over AbstractDimArray works as usual with Base Julia broadcasts,
except that dimensions are checked for compatibility with each other, and that
values match. Strict checks can be turned off globally with
`strict_broadcast!(false)`. 
To avoid even dimension name checks, broadcast over `parent(dimarray)`.

The [`@d`](@ref) macro is a dimension-aware extension to regular dot broadcasting.
[`broadcast_dims`](@ref) is analogous to Base Julia's `broadcast`. 

Because we know the names of the dimensions, there is no ambiguity in which ones
we mean to broadcast together. This means we can permute and reshape dims so
that broadcasts that would fail with a regular `Array` just work with a
`DimArray`. 

As an added bonus, `broadcast_dims` even works on `DimStack`s. Currently, `@d` 
does not work on `DimStack`.

## Example: scaling along the time dimension

Define some dimensions:

````@example bd
using DimensionalData
using Dates
using Statistics
````

````@ansi bd
x, y, t = X(1:100), Y(1:25), Ti(DateTime(2000):Month(1):DateTime(2000, 12))
````

A DimArray from 1:12 to scale with:

````@ansi bd
month_scalars = DimArray(month, t)
````

And a larger DimArray for example data:

````@ansi bd
data = rand(x, y, t)
````

A regular broadcast fails:

````@ansi bd
scaled = data .* month_scalars
````

But `@d` knows to broadcast over the `Ti` dimension:

````@ansi bd
scaled = @d data .* month_scalars
````

We can see the means of each month are scaled by the broadcast :

````@ansi bd
mean(eachslice(data; dims=(X, Y)))
mean(eachslice(scaled; dims=(X, Y)))
````

You can also use `broadcast_dims` the same way:

````@ansi bd
broadcast_dims(*, data, month_scalars)
````

And with the [`@d`](@ref) macro you can set the dimension order and other
properties of the output array, by passing a single assignment or a `NamedTuple`
argument to `@d` after the broadcast:

````@ansi bd
@d data .* month_scalars dims=(Ti, X, Y)
````

Or
````@ansi bd
@d data .* month_scalars (dims=(Ti, X, Y), name=:scaled)
````
