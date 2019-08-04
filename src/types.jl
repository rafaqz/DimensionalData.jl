"""
Abstract type for spatial data that isn't an array but uses some of the same methods

I imagine these will be DataFrames or similar collections of coordinate with values.
But I don't really use these formats, so help is required here.

Examples:
`SpatialGrids.Raster`
`GeoStatsBase.AbstractSpatialObject`
"""
abstract type AbstractGeoData{T,N,D} end


"""
Stack object for holding multiple arrays and datasets
with the same spatial metadata and bounds. As in Rs raster stack.

Contained objects must share common dims D?
"""
abstract type AbstractGeoStack{D} end


