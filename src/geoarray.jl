# A basic GeoArray type to test the framework.

struct GeoArray{T,N,D,R,L,A<:AbstractArray{T,N},Mi,Me} <: AbstractGeoArray{T,N,D}
    data::A
    dims::D
    refdims::R
    label::L
    missingval::Mi
    metadata::Me
end
GeoArray(a::AbstractArray{T,N}, dims; refdims=(), label="",
         missingval=missing, metadata=Dict()) where {T,N} = begin
    GeoArray(a, checkdim(dims, a), refdims, label, missingval, metadata)
end

# Array interface
Base.parent(a::GeoArray) = a.data

# GeoArray interface
dims(a::GeoArray) = a.dims
refdims(a::GeoArray) = a.refdims
label(a::GeoArray) = a.label
missingval(a::GeoArray) = a.missingval
metadata(a::GeoArray) = a.metadata

rebuild(a::GeoArray, data, dims, refdims) =
    GeoArray(data, dims, refdims, a.label, a.missingval, a.metadata)

# CoordinateReferenceSystemsBase interface
CoordinateReferenceSystemsBase.crs(a::GeoArray) = 
    haskey(metadata(a), :crs) ? metadata(a)[:crs] : error("No crs metadata associated with this array")
