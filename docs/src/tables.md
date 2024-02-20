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

Columns are given the `name` or the array or the stack layer key.
`Dimension` columns use the `Symbol` version (the result of `DD.dim2key(dimension)`).

Looping of unevenly size dimensions and layers is done _lazily_,
and does not allocate unless collected.

````@ansi dataframe
using DimensionalData, Dates, DataFrames
x = X(1:10)
y = Y(1:10)
c = Dim{:category}('a':'z')
c = Dim{:category}(1:25.0)

A = DimArray(rand(x, y, c); name=:data)
st = DimStack((data1 = rand(x, y), data2=rand(x, y, c)))
````

By default this stack will become a table with a column for each
dimension, and one for each layer:

````@ansi dataframe
DataFrame(st)
````

Arrays behave the same way, but with only one data column
````@ansi
DataFrame(A)
````

We can also control how the table is created using [`DimTable`](@ref),
here we can merge the spatial dimensions so the column is a point:

````@ansi dataframe
DataFrame(DimTable(st; mergedims=(:X, :Y)=>:XY))
````

Or, for a `DimArray` we can take columns from one of the layers:

````@ansi dataframe
DataFrame(DimTable(A; layersfrom=:category))
````

We can also write arrays and stacks directly to CSV.jl, or 
any other data type supporting the Tables.jl interface.

````@ansi dataframe
using CSV
CSV.write("stack_datframe.csv", st)
````
