## Installation

If you want to use this package you need to install it first. You can do it using the following commands:

````julia
julia> ] # ']' should be pressed
pkg> add DimensionalData
````
or

````julia
julia> using Pkg
julia> Pkg.add("DimensionalData")
````

Additionally, it is recommended to check the version that you have installed with the status command.

````julia
julia> ]
pkg> status DimensionalData
````

## Basics

Start using the package:

````@example basics
using DimensionalData
````

and create your first DimArray

````@ansi basics
A = DimArray(rand(4,5), (a=1:4, b=1:5))
````

or

````@ansi basics
C = DimArray(rand(Int8, 10), (alpha='a':'j',))
````

or something a little bit more complicated:

````@ansi basics
data = rand(Int8, 2, 10, 3) .|> abs
B = DimArray(data, (channel=[:left, :right], time=1:10, iter=1:3))
````
