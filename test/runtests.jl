using GeoArrayBase, Test, BenchmarkTools, CoordinateReferenceSystemsBase

struct GeoArray{T,N,A<:AbstractArray{T,N},D,CR,CA} <: GeoArrayBase.AbstractGeoArray{T,N}
    data::A
    crs::CR
    calendar::CA
end
GeoArray(a::AbstractArray{T,N}, dims::Type; crs=nothing, calendar=nothing) where {T,N} = begin
    length(dims.parameters) == N || throw(ArgumentError, "Dims don't match array dimensions")
    GeoArray{T,N,typeof(a),dims,typeof(crs),typeof(calendar)}(a, crs, calendar)
end

# Array interface
Base.size(a::GeoArray) = size(a.data)
Base.IndexStyle(::Type{T}) where {T<:GeoArray} = IndexLinear()
Base.iterate(a::GeoArray) = iterate(a.data)
Base.length(a::GeoArray) = length(a.data)
Base.eltype(::Type{GeoArray{T}}) where T = T

Base.getindex(a::GeoArray, I::Vararg{<:Number}) = getindex(a.data, I...)
Base.getindex(a::GeoArray{T,N,A,D,CR,CA}, I::Vararg{<:Union{AbstractArray,Colon,Number}}
             ) where {T,N,A,D,CR,CA} = begin
    a1 = getindex(a.data, i...)
    GeoArray{T,ndims(a1),typeof(a1),GeoArrayBase.argstodims(a, I),CR,CA}(a1, a.crs, a.calendar)
end

Base.view(a::GeoArray{T,N,A,D,CR,CA}, I::Vararg{<:Union{Number,AbstractArray,Colon}}
         ) where {T,N,A,D,CR,CA} = begin
    v = view(a.data, I...) 
    GeoArray{T,ndims(v),typeof(v),GeoArrayBase.argstodims(a, I),CR,CA}(v, a.crs, a.calendar)
end

# GeoArray interface
GeoArrayBase.dimtype(a::GeoArray{T,N,A,D,CR,CA}) where {T,N,A,D,CR,CA} = D
GeoArrayBase.calendar(a::GeoArray) = a.calendar

# CoordinateReferenceSystemsBase interface
CoordinateReferenceSystemsBase.crs(a::GeoArray) = a.crs


g = GeoArray([1 2; 3 4], Tuple{LongDim, LatDim}; crs=EPSGcode("EPSG:28992"))

# Using LatDim, LongDim etc for indexing
# view() and getindex() defined above use specific types 
# to avoid ambiguities with AbstractGeoArray

# getindex returns values
@test g[LongDim(1), LatDim(2)] == 2
@test g[LongDim(2), LatDim(2)] == 4

# or new GeoArray slices with the right dimensions
a = g[LongDim(1:2), LatDim(1)]
@test a == [1, 3]
@test typeof(a) <: GeoArray{Int,1} 
@test dimtype(a) == Tuple{LongDim}
@test crs(a) == EPSGcode("EPSG:28992")

a = g[LongDim(1), LatDim(1:2)]
@test a == [1, 2]
@test typeof(a) <: GeoArray{Int,1} 
@test dimtype(a) == Tuple{LatDim}
@test crs(a) == EPSGcode("EPSG:28992")

a = g[LatDim(:)]
@test a == [1 2; 3 4]
@test typeof(a) <: GeoArray{Int,2} 
@test dimtype(a) == Tuple{LongDim,LatDim}
@test crs(a) == EPSGcode("EPSG:28992")


# view() returns GeoArrays containing views 
v = view(g, LatDim(1), LongDim(1))
@test v[] == 1
@test typeof(v) <: GeoArray{Int,0,<:SubArray} 
@test dimtype(v) == Tuple{}
@test crs(v) == EPSGcode("EPSG:28992")

v = view(g, LatDim(1), LongDim(1:2))
@test v == [1, 3]
@test typeof(v) <: GeoArray{Int,1,<:SubArray} 
@test dimtype(v) == Tuple{LongDim}
@test crs(v) == EPSGcode("EPSG:28992")
v = view(g, LatDim(1:2), LongDim(1))

v = view(g, LatDim(1:2), LongDim(1))
@test v == [1, 2]
@test typeof(v) <: GeoArray{Int,1,<:SubArray} 
@test dimtype(v) == Tuple{LatDim}
@test crs(v) == EPSGcode("EPSG:28992")


vd1() = view(g, LongDim(1))
vd2() = view(g, LongDim(1), LatDim(:))
vd3() = view(g, LongDim(1), LatDim(1:2))
v1() = view(g.data, 1, 1:2)
v2() = view(g.data, 1, :)

@test vd1() == vd2() == vd3() == v1() == v2()

@btime vd1() 
@btime vd2()
@btime vd3()
@btime v1()
@btime v2()

d1() = g[LatDim(1)]
d2() = g[LatDim(1), LongDim(:)]
d3() = g[LatDim(1), LongDim(1:2)]
i1() = g[:, 1]
i2() = g[1:2, 1]

# These are all equivalent
@test d1() == d2() == d3() == i1() == i2()

@btime d1() 
@btime d2()
@btime d3()
@btime i1()
@btime i2()
