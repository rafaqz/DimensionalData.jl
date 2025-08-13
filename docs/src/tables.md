```@meta
Description = "Convert DimensionalData.jl arrays to Tables.jl format and DataFrames - seamless interoperability with Julia's data ecosystem"
```

# Tables and DataFrames

[Tables.jl](https://github.com/JuliaData/Tables.jl) provides an ecosystem-wide interface to tabular data in Julia, ensuring interoperability with [DataFrames.jl](https://dataframes.juliadata.org/stable/), [CSV.jl](https://csv.juliadata.org/stable/), and hundreds of other packages that implement the standard.

## Dimensional data are tables
DimensionalData.jl implements the Tables.jl interface for `AbstractDimArray` and `AbstractDimStack`. `DimStack` layers are unrolled so they are all the same size, and dimensions loop to match the length of the largest layer.

Columns are given the [`name`](@ref) of the array or stack layer, and the result of `DD.name(dimension)` for `Dimension` columns.

Looping of dimensions and stack layers is done _lazily_, and does not allocate unless collected.

## Materializing tables to DimArray or DimStack
`DimArray` and `DimStack` have fallback methods to materialize any `Tables.jl`-compatible table.

By default, it will treat columns such as X, Y, Z, and Band as dimensions, and other columns as data.
Pass a `name` keyword argument to determine which column(s) are used.

You have full control over which columns are dimensions - and what those dimensions look like exactly. If you pass a `Tuple` of `Symbol` or dimension types (e.g. `X`) as the second argument, those columns are treated as dimensions. Passing a `Tuple` of dimensions preserves these dimensions - with values matched to the corresponding columns.

Materializing tables will worked even if the table is not ordered, and can handle missing values.

## Example

````@example dataframe
using DimensionalData
using Dates
using DataFrames
````

Define some dimensions:

````@ansi dataframe
x, y, c = X(1:10), Y(1:10), Dim{:category}('a':'z')
````

::: tabs

== Create a `DimArray`

````@ansi dataframe
A = rand(x, y, c; name=:data)
````

== Create a `DimStack`

````@ansi dataframe
st = DimStack((data1 = rand(x, y), data2=rand(x, y, c)))
````

::: 

## Converting to DataFrame

::: tabs

== Array Default

Arrays will have columns for each dimension, and only one data column

````@ansi dataframe
DataFrame(A)
````

== Stack Default

Stacks will become a table with a column for each dimension, and one for each layer:

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

We can also write arrays and stacks directly to CSV.jl, or any other data type supporting the Tables.jl interface.

````@example dataframe
using CSV
CSV.write("dimstack.csv", st)
readlines("dimstack.csv")
````

## Converting a DataFrame to a DimArray or DimStack

The Dataframe we use will have 5 columns: X, Y, category, data1, and data2

````@ansi dataframe
df = DataFrame(st)
````

::: tabs

== Create a `DimArray`

Converting this DataFrame to a DimArray without other arguments will read the `category` columns as data and ignore data1 and data2:

````@ansi dataframe
DimArray(df)
````

Specify dimenion names to ensure these get treated as dimensions. Now data1 is read in instead.
````@ansi dataframe
DimArray(df, (X,Y,:category))
````

You can also pass in the actual dimensions.
````@ansi dataframe
DimArray(df, dims(st))
````

Pass in a name argument to read in data2 instead.
````@ansi dataframe
DimArray(df, dims(st); name = :data2)
````

== Create a `DimStack`

Converting the DataFrame to a `DimStack` will by default read category, data1, and data2 as layers
````@ansi dataframe
DimStack(df)
````


Specify dimenion names to ensure these get treated as dimensions. Now data1 and data2 are layers.
````@ansi dataframe
DimStack(df, (X,Y,:category))
````

You can also pass in the actual dimensions. 
````@ansi dataframe
DimStack(df, dims(st))
````

Pass in a tuple of column names to control which columns are read.
````@ansi dataframe
DimStack(df, dims(st); name = (:data2,))
````

:::