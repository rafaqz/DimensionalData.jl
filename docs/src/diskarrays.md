# DiskArrays.jl compatability

[DiskArrays.jl](https://github.com/meggart/DiskArrays.jl) enables lazy, chunked application of:

- broadcast
- reductions
- iteration
- generators
- zip

It is rarely used directly, but is present in most
disk and cloud based spatial data packages in julia, including:
ArchGDAL.jl, NetCDF.jl, Zarr.jl, NCDatasets.lj, GRIBDatasets.jl and CommonDataModel.jl

The combination of DiskArrays.jl and DimensionalData.jl is Julias answer to
pythons [xarray](https://xarray.dev/). Rasters.jl and YAXArrays.jl are user-facing
tools building on this combination.

They have no direct dependency relationships, with but are intentionally
designed to integrate via both adherence to julias `AbstractArray`
interface, and by coordination during development of both packages.
