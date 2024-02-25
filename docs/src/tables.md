# Tables and DataFrames

[Tables.jl](https://github.com/JuliaData/Tables.jl) provides an 
ecosystem-wide interface to tabular data in julia, giving interop with 
[DataFrames.jl](https://dataframes.juliadata.org/stable/), 
[CSV.jl](https://csv.juliadata.org/stable/) and hundreds of other 
packages that implement the standard.

DimensionalData.jl implements the Tables.jl interface for
`AbstractDimArray` and `AbstractDimStack`. `DimStack` layers
are unrolled so they are all the same size, and dimensions similarly loop
over array strides to match the length of the largest layer.

Columns are given the [`name`](@ref) or the array or the stack layer key.
`Dimension` columns use the `Symbol` version (the result of `DD.dim2key(dimension)`).

Looping of dimensions and stack layers is done _lazily_,
and does not allocate unless collected.

## Example

````@example dataframe
using DimensionalData, Dates, DataFrames
````

Define some dimensions:

````@ansi dataframe
x, y, c = X(1:10), Y(1:10), Dim{:category}('a':'z')
````

::: tabs

== create a `DimArray`

````@ansi dataframe
A = rand(x, y, c; name=:data)
````

== create a `DimStack`

````@ansi dataframe
st = DimStack((data1 = rand(x, y), data2=rand(x, y, c)))
````

::: 

## Converting to DataFrame

::: tabs

== array default

Arrays will have columns for each dimension, and only one data column

````@ansi dataframe
DataFrame(A)
````

== stack default

Stacks will become a table with a column for each dimension, 
and one for each layer:

````@ansi dataframe
DataFrame(st)
````

== layersfrom

Using [`DimTable`](@ref) we can specify that a `DimArray` 
should take columns from one of the dimensions:

````@ansi dataframe
DataFrame(DimTable(A; layersfrom=:category))
DimStack(A; layersfrom=:category)
````

== mergedims

Using [`DimTable`](@ref) we can merge the spatial 
dimensions so the column is a tuple:

````@ansi dataframe
DataFrame(DimTable(st; mergedims=(:X, :Y)=>:XY))
````

::: 

## Converting to CSV

We can also write arrays and stacks directly to CSV.jl, or 
any other data type supporting the Tables.jl interface.

````@ansi dataframe
using CSV
CSV.write("dimstack.csv", st)
readlines("dimstack.csv")
````
