
"""
AbstractGeoDim formalises the dimensions in an AbstractGeoArray

It can contain spatial coordinates or array indices as Number, UnitRange, or
Colon types AbstractVector will also work but will be less performant.
"""
abstract type AbstractGeoDim{T} end

(::Type{T})(dim::D) where {T<:AbstractGeoDim,D<:T} = T(val(dim))
(::Type{T})() where T<:AbstractGeoDim = T(:)


const GeoDims = Union{AbstractGeoDim,Tuple{Vararg{<:AbstractGeoDim, N}}} where N


abstract type AbstractAffineDims{T} end

# Running AbstractAffineDims runs its AffineTransform
# (aff::T)(args...) where T <: AbstractAffineDims = val(aff)(args...)

struct CoordDims{T} <: AbstractAffineDims{T}
    dims::T 
end

val(aff::AbstractAffineDims) = aff.dims

# Getters 

val(dim::AbstractGeoDim) = dim.val
val(dim) = dim

units(dim) = dim.units


# Base methods

Base.eltype(dim::AbstractGeoDim) = eltype(typeof(dim))
Base.eltype(dim::Type{AbstractGeoDim{T}}) where T = T

# For use in similar()
Base.to_shape(dims::GeoDims) = dims



# GeoDataBase methods

name(d::AbstractGeoDim) = name(typeof(d))
name(d::GeoDims) = name.(d)

shortname(d::AbstractGeoDim) = shortname(typeof(d))
shortname(d::Type{<:AbstractGeoDim}) = name(d)

bounds(dims::Tuple) = (bounds(dim2[1]), bounds(tail(dims)...,))
bounds(dim::AbstractGeoDim{<:AbstractArray}) = first(val(dim)), last(val(dim))
bounds(dim::AbstractGeoDim{<:Number}) = val(dim)



# Lowe-level utility methods. 
#
# These do most of the work in the package and are all @generated or recusive 
# functions for performance reasons.

dims2indices_inner(dimtypes::Type, dims::Type) = begin
    indexexps = []
    for dimtype in flattendimtypes(dimtypes)
        index = findfirst(d -> d <: basetype(dimtype), dims.parameters)
        if index == nothing
            # A missing dim uses the emptyval arg
            push!(indexexps, :(emptyval))
        else
            push!(indexexps, :(val(dims[$index])))
        end
    end
    Expr(:tuple, indexexps...)
end
@generated dims2indices(dimtypes::Type{DT}, dims::Tuple, emptyval=:) where DT =
    dims2indices_inner(DT, dims)

replacedimval(f, dims::Tuple) = (replacedimval(f, dims[1]), replacedimval(f, tail(dims))...,)
replacedimval(f, dims::Tuple{}) = ()
replacedimval(f, dim::AbstractGeoDim) = basetype(dim)(f(val(dim)))

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
@generated sortdims(dimtypes::Type{DT}, dims::Tuple) where DT = sortdims_inner(DT, dims)


dimnum(dimtypes::Type, dim::Number) = dim
dimnum(dimtypes::Type, dims::Tuple) = (dimnum(dimtypes, dims[1]), dimnum(dimtypes, tail(dims))...,)
dimnum(dimtypes::Type, dims::Tuple{}) = ()
@generated dimnum(dimtypes::Type{DTS}, dim::AbstractGeoDim) where DTS = begin
    index = findfirst(dt -> dim <: basetype(dt), DTS.parameters)
    if index == nothing
        :(throw(ArgumentError("No $dim in dimensions $dimtypes")))
    else
        :($index)
    end
end


slicedims(dims::Tuple, I::Tuple) = begin
    d = slicedims(dims[1], I[1])
    ds = slicedims(tail(dims), tail(I))
    out = (d[1]..., ds[1]...), (d[2]..., ds[2]...)
    out
end
slicedims(dims::Tuple{}, I::Tuple{}) = ((), ())
slicedims(d::AbstractGeoDim, i::Number) = ((), (basetype(d)(val(d)[i], d.units),))
slicedims(d::AbstractGeoDim, i::AbstractVector) = ((basetype(d)(val(d)[i], d.units),), ())
slicedims(d::AbstractGeoDim, i::Colon) = ((d,), ())
slicedims(d::AbstractGeoDim, i::AbstractRange) = ((basetype(d)(val(d)[i], d.units),), ())
slicedims(d::AbstractGeoDim{<:StepRange}, i::AbstractRange) = begin
    start = first(val(d))
    stp = getste((val(d)))
    d = basetype(d)(start+stp*(first(i) - 1):stp:start+stp*(last(i) - 1), d.units)
    ((d,), ())
end

checkdims(a::AbstractArray{T,N}, dims::Tuple) where {T,N} = begin
    dimlen = length(dims)
    dimlen == N || throw(ArgumentError("dims ($dimlen) don't match array dimensions $(N)"))
    checkdims(a, dims, 1)
end
@inline checkdims(a, dims::Tuple, n) = (checkdims(a, dims[1], n), checkdims(a, tail(dims), n+1)...,) 
@inline checkdims(a, dims::Tuple{}, n) = ()
@inline checkdims(a, dim::AbstractGeoDim{<:AbstractArray}, n) = 
    if length(val(dim)) == size(a, n) 
        dim 
    else
        throw(ArgumentError("length of $dim $(length(val(dim))) does not match size of array dimension $n $(size(a, n))"))
    end
@inline checkdims(a, dim::AbstractGeoDim{<:Union{UnitRange,NTuple{2}}}, n) = begin
    range = val(dim)
    start, stop = first(range), last(range)
    steprange = start:(stop-start)/(size(a, n)-1):stop
    basetype(dim)(steprange)
end

flattendimtypes(dimtypes::Type) = flattendimtypes((dimtypes.parameters...,))
flattendimtypes(dimtypes::Tuple) = (flattendimtypes(dimtypes[1]), flattendimtypes(tail(dimtypes))...,)
flattendimtypes(dimtypes::Tuple{}) = ()
flattendimtypes(geodim::Type{<:AbstractGeoDim}) = geodim
flattendimtypes(affdims::Type{<:AbstractAffineDims}) = flattendimtypes((affdims.parameters...,))



"""
    @geodim typ name [shortname=name]

Define new dimensions with a macro
"""
macro geodim(typ, name, shortname=name)
    esc(quote
        struct $typ{T,U} <: AbstractGeoDim{T}
            val::T
            units::U
        end
        $typ(val; units=nothing) = $typ(val, units)
        GeoDataBase.shortname(::Type{<:$typ}) = $shortname
        GeoDataBase.name(::Type{<:$typ}) = $name
    end)
end


#= Define some common dimensions

These are intentionally a little more standardised than axis 
arrays arbitrary axis symbols. They should be used in packages
and expected to work accross multiple AbstractGeoArray/Data types.
=#

@geodim Lat "Lattitude" "Lat"
@geodim Lon "Longitude" "Lon"
@geodim Vert "Vertical" "Vert"
@geodim Time "Time"
