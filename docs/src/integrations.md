# Integrations

## Rasters.jl

[Rasters.jl](https://rafaqz.github.io/Rasters.jl/stable) extends DD
for geospatial data manipulation, providing file load/save for
a wide range of raster data sources and common GIS tools like
polygon rasterization and masking. `Raster` types are aware
of `crs` and their `missingval` (which is often not `missing`
for performance and storage reasons).

Rasters.jl is also the reason DimensionalData.jl exists at all!
But it always made sense to separate out spatial indexing from
GIS tools and dependencies.

A `Raster` is a `AbstractDimArray`, a `RasterStack` is a `AbstractDimStack`,
and `Projected` and `Mapped` are `AbstractSample` lookups.

## YAXArrays.jl

[YAXArrays.jl](https://juliadatacubes.github.io/YAXArrays.jl/dev/) is another
spatial data package aimed more at (very) large datasets. It's functionality
is slowly converging with Rasters.jl (both wrapping DiskArray.jl/DimensionalData.jl)
and we work closely with the developers.

`YAXArray` is a `AbstractDimArray` and inherits its behaviours.

## ClimateBase.jl

[ClimateBase.jl](https://juliaclimate.github.io/ClimateBase.jl/dev/)
Extends DD with methods for analysis of climate data.

## ArviZ.jl

[ArviZ.jl](https://arviz-devs.github.io/ArviZ.jl/dev/)
Is a Julia package for exploratory analysis of Bayesian models.

An `ArviZ.Dataset` is an `AbstractDimStack`!

## JuMP.jl

[JuMP.jl](https://jump.dev/) is a powerful optimization DSL.
It defines its own named array types but now accepts any `AbstractDimArray`
too, through a package extension.

## CryoGrid.jl

[CryoGrid.jl](https://juliahub.com/ui/Packages/General/CryoGrid)
A Julia implementation of the CryoGrid permafrost model.

`CryoGridOutput` uses `DimArray` for views into output data.

## DynamicGrids.jl

[DynamicGrids.jl](https://github.com/cesaraustralia/DynamicGrids.jl)
is a spatial simulation engine, for cellular automata and spatial process
models.

All DynamicGrids.jl `Outputs` are `<: AbstractDimArray`, and
`AbstractDimArray` are used for auxiliary data to allow temporal
synchronisation during simulations. Notably, this all works on GPUs!

## AstroImages.jl

[AstroImages.jl](http://juliaastro.org/dev/modules/AstroImages)
Provides tools to load and visualise astronomical images.
`AstroImage` is `<: AbstractDimArray`.

## TimeseriesTools.jl

[TimeseriesTools.jl](https://juliahub.com/ui/Packages/General/TimeseriesTools)
Uses `DimArray` for time-series data.

