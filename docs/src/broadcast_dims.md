# `broadcast_dims` and `broadcast_dims!`

[`broadcast_dims`](@ref) is like Base julia `broadcast` on dimensional steroids.
Because we know the names of the dimensions, there is ambiguity in which
one we mean, and we can permuted and reshape them so that broadcasta that
would fail with a regular `Array` just work with a `DimArray`. As an added
bonus, `broadcast_dims` even works on `DimStack`s.

````@ansi bd
using DimensionalData
x, y, t = X(1:100), Y(1:25), Ti(DateTime(2000):Month(1):DateTime(2000, 12))

month_scalars = DimArray(month, t)
data = rand(x, y, t)
````

A regular broadcast fails:

````@ansi bd
data .* month_scalars
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

````@ansi bd
data .* month_scalars
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
