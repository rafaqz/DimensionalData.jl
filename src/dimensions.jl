"""
AbstractGeoDim formalises the dimensions in an AbstractGeoArray

This could be acomplished by using axis arrays, but that locks
us into a particular implementation, while this is flexible.

It should facilitate conversion between the most common dimension arrangements.

Can also be used in methods like `bounds` to get the bounds for a particular dimension,
Instead of passing an Int.
"""
abstract type AbstractGeoDim end

struct LatDim{T} <: AbstractGeoDim
    val::T
end
LatDim() = LatDim(:)

struct LongDim{T}<: AbstractGeoDim
    val::T
end
LongDim() = LongDim(:)

struct VertDim{T} <: AbstractGeoDim
    val::T
end
VertDim() = VertDim(:)

struct TimeDim{T} <: AbstractGeoDim
    val::T
end
TimeDim() = TimeDim(:)


"""
Returns the GeoDim of a dimension, or a tuple for all dimensions.

eg. LongDim or `(LatDim, LongDim, TimeDim)`
"""
function dimtype end

function dimnum end

"""
Get the name of a dimension. Might be usefull for printing
and working with axis arrays etc. I'm not sure.
"""
function dimname end

"""
Handling units is a big question.

Ubiquitous Unitful units is my preference but it's not practical,
so a method like this might be required, with some wrapper types.

A utility package that does conversion between standard
unit strings in NetCDF etc. and Unitful units would help bridge the gap and alow
automated conversion between unitless and unitful GeoArray types.

This might help:
https://github.com/Alexander-Barth/UDUnits.jl
"""
function dimunits end


# GeoArrayBase methods
dimname(a::AbstractGeoArray) = dimname.(dimtype(a).parameters)
dimname(a::AbstractGeoData) = dimname.(dimtype(a).parameters)
dimnum(a::AbstractGeoArray, d::AbstractGeoDim) = findfirst(x -> x == d, dimtype(a).parameters)

dimname(::Type{LatDim}) = :lattitude
dimname(::Type{LongDim}) = :longitude
dimname(::Type{VertDim}) = :vertical
dimname(::Type{TimeDim}) = :time

extract(a::AbstractGeoArray, dims::Vararg{<:AbstractGeoDim}) =
    extract(a, dims2indices(dimtype(a), dims)...)

bounds(a::AbstractGeoArray, dims::Vararg{<:AbstractGeoDim}) =
    bounds(a, dims2indices(dimtype(a), dims)...)

# Base methods
#
# We handle getindex() and view() called with AbstractGeoDim args, 
# for any AbstractGeoArray.
#
# Dims are put in order with missing dims filled with Colon().
# Concrete types can mostly ignore Dims, except args... for view() 
# and getindex() must have specific types to avoid abimguity.

Base.getindex(a::AbstractGeoArray, dims::Vararg{<:AbstractGeoDim}) =
    getindex(a, dims2indices(a, dims)...)

Base.view(a::AbstractGeoArray, dims::Vararg{<:AbstractGeoDim}) =
    view(a, dims2indices(a, dims)...)


# Utility methods

val(dim::AbstractGeoDim) = dim.val

"""
Convert AbstractGeoDims to index args in the right order

Adds Colon() for any missing dim.
"""
dims2indices(a::AbstractGeoArray, dims::Tuple) = dims2indices(a, dimtype(a), dims)
@generated dims2indices(a::AbstractGeoArray, dimtypes::Type{DT}, dims::Tuple) where DT = 
    dims2indices_inner(DT, dims)

dims2indices_inner(dimtypes::Type, dims::Type) = begin
    indexexps = []
    for dimtype in dimtypes.parameters
        index = findfirst(d -> d <: dimtype, dims.parameters)
        if index == nothing
            push!(indexexps, :(Colon()))
        else
            push!(indexexps, :(GeoArrayBase.val(dims[$index])))
        end
    end
    Expr(:tuple, indexexps...)
end

sortdims(a::AbstractGeoArray, dims::Tuple) = sortdims(a, dimtype(a), dims)
@generated sortdims(a::AbstractGeoArray, dimtypes::Type{DT}, dims::Tuple) where DT = 
    sortdims_inner(DT, dims)

sortdims_inner(dimtypes::Type, dims::Type) = begin
    indexexps = []
    for dimtype in dimtypes.parameters
        index = findfirst(d -> d <: dimtype, dims.parameters)
        if index == nothing
            push!(indexexps, :(nothing))
        else
            push!(indexexps, :(dims[$index]))
        end
    end
    Expr(:tuple, indexexps...)
end

"""
Convert indices to AbstractGeoDims

Remove any indices that are only single numbers. This is used to 
determined new dims for substsets and views.
"""
indices2dims(a::AbstractGeoArray, I::Tuple) = indices2dims(a, dimtype(a), I)
@generated indices2dims(a::AbstractGeoArray, dimtypes::Type{DT}, dims::Tuple) where DT = indices2dims_inner(DT, dims)

indices2dims_inner(dimtypes::Type, dims::Type) = begin
    indexexps = []
    for (i, dim) in enumerate(dims.parameters)
        if !(dim <: Number)
            typ = dimtypes.parameters[i]
            push!(indexexps, :($typ(coords(a, dims[$i]))))
        end
    end
    Expr(:tuple, indexexps...)
end

hasdim(a::AbstractGeoArray, dim::Type) = dim in dimtype(a).parameters

dims2type(dims...) = dims2type(dims)
dims2type(dims::Tuple) = begin 
    dimtypes = (d -> typeof(d).name.wrapper).(dims)  
    Tuple{dimtypes...}
end
