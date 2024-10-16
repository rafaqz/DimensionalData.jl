# DiskArrays.jl compatibility

[DiskArrays.jl](https://github.com/meggart/DiskArrays.jl) enables lazy, chunked application of:

- broadcast
- reductions
- iteration
- generators
- zip

It is rarely used directly, but is present in most 
disk and cloud based spatial data packages in julia, including:
ArchGDAL.jl, NetCDF.jl, Zarr.jl, NCDatasets.jl, GRIBDatasets.jl and CommonDataModel.jl

The combination of DiskArrays.jl and DimensionalData.jl is Julia's answer to
python's [xarray](https://xarray.dev/). Rasters.jl and YAXArrays.jl are user-facing 
tools building on this combination.


They have no direct dependency relationships, but are intentionally 
designed to integrate via both adherence to Julia's `AbstractArray` 
interface, and by coordination during development of both packages.
