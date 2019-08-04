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
    GeoArray(a, checkdim(a, dims), refdims, missingval, units, metadata)

# Array interface
Base.parent(a::GeoArray) = a.data

# CoordinateReferenceSystemsBase interface
CoordinateReferenceSystemsBase.crs(a::GeoArray) = get(metadata(a), :crs, nothing)

rebuild(a::GeoArray, data, dims, refdims) =
    GeoArray(data, dims, refdims, a.missingval, a.units, a.metadata)

# GeoArray interface
dims(a::GeoArray) = a.dims
refdims(a::GeoArray) = a.refdims
missingval(a::GeoArray) = a.missingval
metadata(a::GeoArray) = a.metadata
key(a::GeoArray) = get(metadata(a), :key, "")
name(a::GeoArray) = get(metadata(a), :name, "")

