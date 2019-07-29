# A basic GeoArray type to test the framework.

struct GeoArray{T,N,D,R,L,A<:AbstractArray{T,N},M,Cr,Ca} <: AbstractGeoArray{T,N,D}
    data::A
    dims::D
    refdims::R
    label::L
    missingval::M
    crs::Cr
    calendar::Ca
end
GeoArray(a::AbstractArray{T,N}, dims; refdims=(),label="",  
         missingval=missing, crs=nothing, calendar=nothing) where {T,N} = begin
    dimlen = length(dims)
    dims = Tuple(checkdim.(dims, Ref(a), 1:N))
    dimlen == N || throw(ArgumentError("dims ($dimlen) don't match array dimensions $(N)"))
    GeoArray(a, dims, refdims, label, missingval, crs, calendar)
end

checkdim(dim::AbstractGeoDim{<:AbstractArray}, a, n) = 
    if length(val(dim)) == size(a, n) 
        dim 
    else
        throw(ArgumentError("length of $dim $(length(val(dim))) does not match size of array dimension $n $(size(a, n))"))
    end
checkdim(dim::AbstractGeoDim{<:Union{UnitRange,NTuple{2}}}, a, n) = begin
    range = val(dim)
    start, stop = first(range), last(range)
    steprange = start:(stop-start)/(size(a, n)-1):stop
    basetype(dim)(steprange)
end


# Array interface
Base.size(a::GeoArray) = size(a.data)
Base.IndexStyle(::Type{T}) where {T<:GeoArray} = IndexLinear()
Base.iterate(a::GeoArray) = iterate(a.data)
Base.length(a::GeoArray) = length(a.data)
Base.eltype(::Type{GeoArray{T}}) where T = T
Base.parent(a::GeoArray) = a.data
Base.permutedims(a::GeoArray{T,2}) where T =  
    GeoArray(permutedims(parent(a)), reverse(dims(a)), a.refdims, a.label, a.missingval, a.crs, a.calendar)

Base.getindex(a::GeoArray, I::Vararg{<:Number}) = getindex(a.data, I...)
Base.getindex(a::GeoArray{T}, I::Vararg{<:Union{AbstractArray,Colon,Number}}) where T = begin
    a1 = getindex(a.data, I...)
    dims, refdims = subsetdim(a, I)
    GeoArray(a1, dims, (a.refdims..., refdims...), a.label, a.missingval, a.crs, a.calendar)
end

Base.view(a::GeoArray, I::Vararg{<:Union{Number,AbstractArray,Colon}}) = begin
    v = view(a.data, I...) 
    dims, refdims = subsetdim(a, I)
    GeoArray(v, dims, (a.refdims..., refdims...), a.label, a.missingval, a.crs, a.calendar)
end


# GeoArray interface
GeoArrayBase.dims(a::GeoArray) = a.dims
GeoArrayBase.refdims(a::GeoArray) = a.refdims
GeoArrayBase.label(a::GeoArray) = a.label
GeoArrayBase.missingval(a::GeoArray) = a.missingval
GeoArrayBase.calendar(a::GeoArray) = a.calendar
GeoArrayBase.bounds(a::GeoArray, args::Vararg{Integer}) = bounds.(Ref(a), args)  
GeoArrayBase.bounds(a::GeoArray, i::Integer) = bounds(dims(a)[i])

# CoordinateReferenceSystemsBase interface
CoordinateReferenceSystemsBase.crs(a::GeoArray) = a.crs
