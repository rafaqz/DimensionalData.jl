```@meta
Description = "DiskArrays.jl integration with DimensionalData.jl - lazy chunked operations for large datasets from disk and cloud storage"
```

# DiskArrays.jl compatibility

[DiskArrays.jl](https://github.com/meggart/DiskArrays.jl) enables lazy, chunked application of:

- broadcast
- reductions
- iteration
- generators
- zip

as well as caching chunks in RAM via `DiskArrays.cache(dimarray)`.

It is rarely used directly, but is present in most 
disk and cloud based spatial data packages in julia, including:
[ArchGDAL.jl](https://github.com/yeesian/ArchGDAL.jl), 
[NetCDF.jl](https://github.com/JuliaGeo/NetCDF.jl),
[Zarr.jl](https://github.com/JuliaIO/Zarr.jl),
[NCDatasets.jl](https://github.com/Alexander-Barth/NCDatasets.jl),
[GRIBDatasets.jl](https://github.com/JuliaGeo/GRIBDatasets.jl) and
[CommonDataModel.jl](https://github.com/JuliaGeo/CommonDataModel.jl).

The combination of DiskArrays.jl and DimensionalData.jl is Julia's answer to
python's [xarray](https://xarray.dev/). [Rasters.jl](https://github.com/rafaqz/Rasters.jl) and [YAXArrays.jl](https://github.com/JuliaDataCubes/YAXArrays.jl) are user-facing 
tools building on this combination.


They have no meaningful direct dependency relationships, but are intentionally 
designed to integrate via both adherence to Julia's `AbstractArray` 
interface, and by coordination during development of both packages.
