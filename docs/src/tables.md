# Tables and DataFrames

Tables.jl provides an ecosystem-wide interface to tabular data in julia,
giving interop with DataFrames.jl, CSV.jl and hundreds of other packages
that implement the standard.

DimensionalData.jl implements the Tables.jl interface for 
`AbstractDimArray` and `AbstractDimStack`. `DimStack` layers 
are unrolled so they are all the same size, and dimensions similarly loop
over array strides to match the length of the largest layer.

Columns are given the `name` or the array or the stack layer key.
`Dimension` columns use the `Symbol` version (the result of `DD.dim2key(dimension)`).

Looping of unevenly size dimensions and layers is done _lazily_, 
and does not allocate unless collected.


