using GeoArrayBase, Test, BenchmarkTools, CoordinateReferenceSystemsBase

using GeoArrayBase: sortdims, indices2dims, indices2dims_inner, dims2dimtypes, subsetdim

struct GeoArray{T,N,A<:AbstractArray{T,N},D,Cr,Ca} <: AbstractGeoArray{T,N}
    data::A
    dimcoords::D
    crs::Cr
    calendar::Ca
end
GeoArray(a::AbstractArray{T,N}, dims; crs=nothing, calendar=nothing) where {T,N} = begin
    dimlen = length(dims)
    dimlen == N || throw(ArgumentError, "dims ($dimlen) don't match array dimensions $(N)")
    GeoArray(a, dims, crs, calendar)
end

# Array interface
Base.size(a::GeoArray) = size(a.data)
Base.IndexStyle(::Type{T}) where {T<:GeoArray} = IndexLinear()
Base.iterate(a::GeoArray) = iterate(a.data)
Base.length(a::GeoArray) = length(a.data)
Base.eltype(::Type{GeoArray{T}}) where T = T

Base.getindex(a::GeoArray, I::Vararg{<:Number}) = getindex(a.data, I...)
Base.getindex(a::GeoArray{T}, I::Vararg{<:Union{AbstractArray,Colon,Number}}) where T = begin
    a1 = getindex(a.data, I...)
    dimcoords = subsetdim(a, I)
    GeoArray(a1, dimcoords, a.crs, a.calendar)
end

Base.view(a::GeoArray, I::Vararg{<:Union{Number,AbstractArray,Colon}}) = begin
    v = view(a.data, I...) 
    dimcoords = subsetdim(a, I)
    GeoArray(v, dimcoords, a.crs, a.calendar)
end

# GeoArray interface
GeoArrayBase.dimtype(a::GeoArray) = dims2dimtypes(a.dimcoords)

GeoArrayBase.coords(a::GeoArray) = a.dimcoords

GeoArrayBase.calendar(a::GeoArray) = a.calendar

# CoordinateReferenceSystemsBase interface
CoordinateReferenceSystemsBase.crs(a::GeoArray) = a.crs



g = GeoArray([1 2; 3 4], (LongDim(143:2:145), LatDim(-38:2:-36)); crs=EPSGcode("EPSG:28992"))
GeoArrayBase.subsetdim(g.dimcoords, (1:2, [1:2]))

# dimensions.jl

# Using LatDim, LongDim etc for indexing
# view() and getindex() defined above use specific types 
# to avoid ambiguities with AbstractGeoArray

@test sortdims(g, (LatDim(1:2), LongDim(1))) == (LongDim(1), LatDim(1:2))
@test dimtype(g) == Tuple{LongDim,LatDim}

# getindex returns values
@test g[LongDim(1), LatDim(2)] == 2
@test g[LongDim(2), LatDim(2)] == 4

# or new GeoArray slices with the right dimensions
a = g[LongDim(1:2), LatDim(1)]
@test a == [1, 3]
@test typeof(a) <: GeoArray{Int,1} 
@test dimtype(a) == Tuple{LongDim}
@test crs(a) == EPSGcode("EPSG:28992")
@test coords(a) == (LongDim(143:145), LatDim(-38))

GeoArrayBase.dims2dimtypes(a.dimcoords)

a = g[LongDim(1), LatDim(1:2)]
@test a == [1, 2]
@test typeof(a) <: GeoArray{Int,1} 
@test dimtype(a) == Tuple{LatDim}
@test crs(a) == EPSGcode("EPSG:28992")
@test coords(a) == (LongDim(143), LatDim(-38:-36))

a = g[LatDim(:)]
@test a == [1 2; 3 4]
@test typeof(a) <: GeoArray{Int,2} 
@test dimtype(a) == Tuple{LongDim,LatDim}
@test crs(a) == EPSGcode("EPSG:28992")
@test coords(a) == (LongDim(143:2:145), LatDim(-38:2:-36))


# view() returns GeoArrays containing views 
v = view(g, LatDim(1), LongDim(1))
@test v[] == 1
@test typeof(v) <: GeoArray{Int,0,<:SubArray} 
@test dimtype(v) == Tuple{}
@test crs(v) == EPSGcode("EPSG:28992")
@test coords(v) == (LongDim(143), LatDim(-38))

v = view(g, LatDim(1), LongDim(1:2))
@test v == [1, 3]
@test typeof(v) <: GeoArray{Int,1,<:SubArray} 
@test dimtype(v) == Tuple{LongDim}
@test crs(v) == EPSGcode("EPSG:28992")
@test coords(v) == (LongDim(143:145), LatDim(-38))

v = view(g, LatDim(1:2), LongDim(1))
@test v == [1, 2]
@test typeof(v) <: GeoArray{Int,1,<:SubArray} 
@test dimtype(v) == Tuple{LatDim}
@test crs(v) == EPSGcode("EPSG:28992")
@test coords(v) == (LongDim(143), LatDim(-38:-36))


# coordinates.jl

# What should the behaviour be for coords??
# This is what getindex returns for Int, UnitRange etc inputs

@test lattitude(g, 1:2) == [-38, -36]
@test longitude(g, 1:2) == [143, 145]
# @test vertical(g, 1:2) == 
# @test timespan(g, 1:2) == 


# Benchmarks

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

