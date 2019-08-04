# A basic GeoArray type to test the framework.

struct GeoArray{T,N,D,R,A<:AbstractArray{T,N},Mi,U,Me} <: AbstractGeoArray{T,N,D}
    data::A
    dims::D
    refdims::R
    missingval::Mi
    units::U
    metadata::Me
end
GeoArray(a::AbstractArray{T,N}, dims; refdims=(), missingval=missing, units="", 
         metadata=Dict()) where {T,N} = 
    GeoArray(a, checkdims(a, dims), refdims, missingval, units, metadata)

# Array interface (AbstractGeoArray takes care of everything else)
Base.parent(a::GeoArray) = a.data

# CoordinateReferenceSystemsBase interface
CoordinateReferenceSystemsBase.crs(a::GeoArray) = get(metadata(a), :crs, nothing)


# GeoArray interface
rebuild(a::GeoArray, data, dims, refdims) =
    GeoArray(data, dims, refdims, a.missingval, a.units, a.metadata)

dims(a::GeoArray) = a.dims
refdims(a::GeoArray) = a.refdims
missingval(a::GeoArray) = a.missingval
units(a::GeoArray) = a.units
metadata(a::GeoArray) = a.metadata
name(a::GeoArray) = get(metadata(a), :name, "")
shortname(a::GeoArray) = get(metadata(a), :shortname, "")

