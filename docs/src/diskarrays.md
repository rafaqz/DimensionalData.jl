### [DiskArrays.jl](https://github.com/meggart/DiskArrays.jl) compatability


The combination of DiskArrays.jl and DimensionalData.jl is Julias answer to
pythons [xarray](https://github.com/pydata/xarray). 

Rasters.jl and YAXArrays.jl are the user-facing tools building on this
combination.

DiskArrays.jl is rarely used directly by users, but is present in most 
disk and cloud based spatial data packages in julia, including:
- ArchGDAL.jl
- NetCDF.jl
- Zarr.jl
- NCDatasets.lj
- GRIBDatasets.jl
- CommonDataModel.jl
- etc...

So that lazy, chunked data access conforms to julias array 
interface but also scales to operating on terrabytes of data. 

DiskArrays enables chunk ordered lazy application of:

- broadcast
- reduce
- iteration
- generators
- zip

DimensionalData.jl is a common front-end for accessing DiskArrays.jl 
compatible datasets. Wherever An `AbstractDimArray` wraps a disk array we 
will do our best to make sure all of the DimensionalData.jl indexing and
DiskArrays.jl lazy/chunked operations work together cleanly.

They have no direct dependency relationships, with but are intentionally 
designed to integrate via both adherence to julias `AbstractArray` 
interface, and by coordination during development of both packages.
