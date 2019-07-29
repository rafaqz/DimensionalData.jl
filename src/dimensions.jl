
"""
AbstractGeoDim formalises the dimensions in an AbstractGeoArray

It can contain spatial coordinates or array indices as Number, UnitRange, or
Colon types AbstractVector will also work but will be less performant.
"""
abstract type AbstractGeoDim{T} end

(::Type{T})(a::AbstractGeoArray) where T<:AbstractGeoDim = T(dims(a)[dimindex(a, T())])
(::Type{T})(dim::D) where {T<:AbstractGeoDim,D<:T} = T(val(dim))
(::Type{T})() where T<:AbstractGeoDim = T(:)

macro geodim(typ, name, shortname=name)
    esc(quote
        struct $typ{T} <: AbstractGeoDim{T}
            val::T
        end
        GeoArrayBase.shortname(::Type{<:$typ}) = $shortname
        GeoArrayBase.dimname(::Type{<:$typ}) = $name
    end)
end

@geodim LatDim "Lattitude" "Lat"
@geodim LongDim "Longitude" "Long"
@geodim VertDim "Vertical" "Vert"
@geodim TimeDim "Time"


abstract type AbstractAffinceDims{T,N} <: AbstractGeoDim{T} end

# Running AbstractAffinceDims runs its AffineTransform
(aff::AbstractAffinceDims)(args...) = val(aff)(args...)

struct CoordDims{T,N} <: AbstractAffinceDims{T,N}
    val::T 
end


Base.eltype(dim::AbstractGeoDim) = eltype(typeof(dim))
Base.eltype(dim::Type{AbstractGeoDim{T}}) where T = T

# GeoArrayBase methods
dimname(a::AbstractGeoArray) = dimname.(dimtype(a).parameters)
dimname(a::AbstractGeoData) = dimname.(dimtype(a).parameters)

dimtype(a::AbstractGeoArray{T,N,D}) where {T,N,D} = D

dimname(d::AbstractGeoDim) = dimname(typeof(d))
shortname(d::AbstractGeoDim) = shortname(typeof(d))
shortname(d::Type{<:AbstractGeoDim}) = dimname(d)

extract(a::AbstractGeoArray, dims::Vararg{<:AbstractGeoDim}) =
    extract(a, dims2indices(dimtype(a), dims)...)

bounds(a::AbstractGeoArray, dims::Vararg{<:AbstractGeoDim}) =
    bounds(a, dimindex.(Ref(a), dims)...)
bounds(dim::AbstractGeoDim{<:AbstractArray}) = first(val(dim)), last(val(dim))
bounds(dim::AbstractGeoDim{<:Number}) = val(dim)

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
val(dim) = dim

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
        if !(eltype(dimtype) <: Number) # Ignore dims with no array dimension
            index = findfirst(d -> d <: basetype(dimtype), dims.parameters)
            if index == nothing
                # A missing dim is the same as XXXDim(:)
                push!(indexexps, :(Colon()))
            else
                push!(indexexps, :(GeoArrayBase.val(dims[$index])))
            end
        end
    end
    Expr(:tuple, indexexps...)
end



sortdims_inner(dimtypes::Type, dims::Type) = begin
    indexexps = []
    for dt in dimtypes.parameters
        index = findfirst(d -> d <: basetype(dt), dims.parameters)
        if index == nothing
            push!(indexexps, :(nothing))
        else
            push!(indexexps, :(dims[$index]))
        end
    end
    Expr(:tuple, indexexps...)
end

sortdims(a::AbstractGeoArray, dims::Tuple) = sortdims(a, dimtype(a), dims)
@generated sortdims(a::AbstractGeoArray, dimtypes::Type{DT}, dims::Tuple) where DT =
    sortdims_inner(DT, dims)

dimindex(a::AbstractGeoArray, dim) = dimindex(dimtype(a), dim)
@generated dimindex(dimtypes::Type{DTS}, dim::AbstractGeoDim) where DTS = begin
    index = findfirst(dt -> dim <: basetype(dt), DTS.parameters)
    if index == nothing
        :(throw(ArgumentError("No $dim in dimensions $dimtypes")))
    else
        :($index)
    end
end

hasdim(a::AbstractGeoArray, dim::Type) = dim in dimtype(a).parameters

@generated dimindex(dimtypes::Type{DTS}, dim::AbstractGeoDim) where DTS = begin
    index = findfirst(dt -> dim <: basetype(dt), DTS.parameters)
    if index == nothing
        :(throw(ArgumentError("No $dim in dimensions $dimtypes")))
    else
        :($index)
    end
end

subsetdim(a::AbstractGeoArray, I::Tuple) = subsetdim(dims(a), I)
subsetdim(dims::Tuple, I::Tuple) = begin
    d = subsetdim(dims[1], I[1])
    ds = subsetdim(tail(dims), tail(I))
    out = (d[1]..., ds[1]...), (d[2]..., ds[2]...)
    out
end
subsetdim(dims::Tuple{}, I::Tuple{}) = ((), ())
subsetdim(d::AbstractGeoDim, i::Number) = ((), (basetype(d)(val(d)[i]),))
subsetdim(d::AbstractGeoDim, i::AbstractVector) = ((basetype(d)(val(d)[i]),), ())
subsetdim(d::AbstractGeoDim, i::Colon) = ((d,), ())
subsetdim(d::AbstractGeoDim, i::AbstractRange) = begin
    start = first(val(d))
    stp = step(val(d))
    d = basetype(d)(start+stp*(first(i) - 1):stp:start+stp*(last(i) - 1))
    ((d,), ())
end

basetype(x) = basetype(typeof(x))
basetype(t::Type) = t.name.wrapper

