# `broadcast_dims` and `broadcast_dims!`

[`broadcast_dims`](@ref) is a dimension-aware extension to Base julia `broadcast`. 

Because we know the names of the dimensions there is no ambiguity in which
one we mean to broadcast together. We can permute and reshape dims so that 
broadcasts that would fail with a regular `Array` just work with a `DimArray`. 

As an added bonus, `broadcast_dims` even works on `DimStack`s.

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

But `broadcast_dims` knows to broadcast over the `Ti` dimension:

````@ansi bd
scaled = broadcast_dims(*, data, month_scalars)
````

We can see the means of each month are scaled by the broadcast :

````@ansi bd
mean(eachslice(data; dims=(X, Y)))
mean(eachslice(scaled; dims=(X, Y)))
````
