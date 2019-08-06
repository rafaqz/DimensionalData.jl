
"""
An AbstractDimension tags the dimensions in an AbstractArray.

It can also contain spatial coordinates and their units. For simplicity,
the same types are used both for storing dimension information and for indexing.
"""
abstract type AbstractDimension{T} end

(::Type{T})(dim::D) where {T<:AbstractDimension,D<:T} = T(val(dim))
(::Type{T})() where T<:AbstractDimension = T(:)
(::Type{T})(a) where T<:AbstractDimension = T(dims(a)[dimnum(a, T())])

const Dimensions = Tuple{Vararg{<:AbstractDimension,N}} where N
const AllDimensions = Union{AbstractDimension,Dimensions,Type{<:AbstractDimension},
                            Tuple{Vararg{<:Type{<:AbstractDimension}}}, 
                            Vector{<:AbstractDimension}}

abstract type AbstractAffineDimensions{T} end

struct CoordDims{T} <: AbstractAffineDimensions{T}
    dims::T 
end

# Getters 

val(aff::AbstractAffineDimensions) = aff.dims
val(dim::AbstractDimension) = dim.val
val(dim) = dim

cleanup(x::AbstractFloat) = round(x, sigdigits=4)
cleanup(x) = x

getstring(::Nothing) = ""
getstring(x) = string(x)

label(dim::AbstractDimension) = join((dimname(dim), getstring(units(dim))), " ")
label(dims::Dimensions) = join(join.(zip(dimname.(dims), string.(cleanup.(val.(dims)))), ": ", ), ", ")


# Base methods

Base.eltype(dim::AbstractDimension) = eltype(typeof(dim))
Base.eltype(dim::Type{AbstractDimension{T}}) where T = T

# Dimensions interface methods

dimname(a::AbstractArray) = dimname(dims(a))
dimname(dims::Dimensions) = (dimnames(dims), dimname(tail(dims))...)
dimname(dim::AbstractDimension) = dimname(typeof(dim))
dimname(dimtype::Type{<:AbstractDimension}) = dimname(dimtype)

dimtype(x) = typeof(dims(x))

shortname(d::AbstractDimension) = shortname(typeof(d))
# Default to dimname if shortname isn't defined
shortname(d::Type{<:AbstractDimension}) = dimname(d)

bounds(dims::Tuple) = (bounds(dim2[1]), bounds(tail(dims)...,))
bounds(dim::AbstractDimension{<:AbstractArray}) = first(val(dim)), last(val(dim))
bounds(dim::AbstractDimension{<:Number}) = val(dim)


#= Lowe-level utility methods. 

These do most of the work in the package, and are all @generated or recusive 
functions for performance reasons.
=#

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
@inline dims2indices(a::AbstractArray, dims::Tuple, args...) = dims2indices(dimtype(a), dims, args...)
@inline dims2indices(a, dim::AbstractDimension, args...) = dims2indices(a, (dim,), args...)

@inline replacedimval(f, dims::Tuple) = 
    (replacedimval(f, dims[1]), replacedimval(f, tail(dims))...,)
@inline replacedimval(f, dims::Tuple{}) = ()
@inline replacedimval(f, dim::AbstractDimension) = basetype(dim)(f(val(dim)))

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
@inline sortdims(a::AbstractArray, dims::Tuple) = sortdims(dimtype(a), dims)

@inline dimnum(a::AbstractArray, dims) = dimnum(dimtype(a), dims)
@inline dimnum(dimtypes::Type, dims::AbstractArray) = dimnum(dimtypes, (dims...,)) 
@inline dimnum(dimtypes::Type, dim::Number) = dim
@inline dimnum(dimtypes::Type, dims::Tuple) = 
    (dimnum(dimtypes, dims[1]), dimnum(dimtypes, tail(dims))...,)
@inline dimnum(dimtypes::Type, dims::Tuple{}) = ()
@inline dimnum(dimtypes::Type, dim::AbstractDimension) = dimnum(dimtypes, typeof(dim))
@generated dimnum(::Type{DTS}, ::Type{D}) where {DTS,D} = begin
    index = findfirst(dt -> D <: basetype(dt), DTS.parameters)
    if index == nothing
        :(throw(ArgumentError("No $dim in dimensions $dimtypes")))
    else
        :($index)
    end
end

@inline slicedims(a::AbstractArray, I::Tuple) = begin
    newdims, newrefdims = slicedims(dims(a), I)
    # Combine new refdims with existing refdims
    newdims, (refdims(a)..., newrefdims...) 
end
@inline slicedims(dims::Tuple, I::Tuple) = begin
    d = slicedims(dims[1], I[1])
    ds = slicedims(tail(dims), tail(I))
    out = (d[1]..., ds[1]...), (d[2]..., ds[2]...)
    out
end
@inline slicedims(dims::Tuple{}, I::Tuple{}) = ((), ())
@inline slicedims(d::AbstractDimension, i::Number) = 
    ((), (basetype(d)(val(d)[i], d.units),))
@inline slicedims(d::AbstractDimension, i::Colon) = 
    ((basetype(d)(val(d), d.units),), ())
@inline slicedims(d::AbstractDimension, i::AbstractVector) = 
    ((basetype(d)(val(d)[i], d.units),), ())
@inline slicedims(d::AbstractDimension{<:StepRange}, i::AbstractRange) = begin
    start = first(val(d))
    stp = step(val(d))
    d = basetype(d)(start+stp*(first(i) - 1):stp:start+stp*(last(i) - 1), d.units)
    ((d,), ())
end

@inline checkdims(a::AbstractArray{T,N}, dims::Tuple) where {T,N} = begin
    dimlen = length(dims)
    dimlen == N || throw(ArgumentError("dims ($dimlen) don't match array dimensions $(N)"))
    checkdims(a, dims, 1)
end
@inline checkdims(a, dims::Tuple, n) = (checkdims(a, dims[1], n), checkdims(a, tail(dims), n+1)...,) 
@inline checkdims(a, dims::Tuple{}, n) = ()
@inline checkdims(a, dim::AbstractDimension{<:AbstractArray}, n) = 
    if length(val(dim)) == size(a, n) 
        dim 
    else
        throw(ArgumentError("length of $dim $(length(val(dim))) does not match size of array dimension $n $(size(a, n))"))
    end
@inline checkdims(a, dim::AbstractDimension{<:Union{UnitRange,NTuple{2}}}, n) = begin
    range = val(dim)
    start, stop = first(range), last(range)
    steprange = start:(stop-start)/(size(a, n)-1):stop
    basetype(dim)(steprange)
end

@inline flattendimtypes(dimtypes::Type) = flattendimtypes((dimtypes.parameters...,))
@inline flattendimtypes(dimtypes::Tuple) = 
    (flattendimtypes(dimtypes[1]), flattendimtypes(tail(dimtypes))...,)
@inline flattendimtypes(dimtypes::Tuple{}) = ()
@inline flattendimtypes(geodim::Type{<:AbstractDimension}) = geodim
@inline flattendimtypes(affdims::Type{<:AbstractAffineDimensions}) = 
    flattendimtypes((affdims.parameters...,))


#= AbstractArray methods where dims are an argument

These use AbstractArray instead of AbstractDimensionArray, which means most of 
the interface can be used without inheriting from it.
=#

Base.@propagate_inbounds Base.getindex(a::AbstractArray, dims::Vararg{<:AbstractDimension}) = 
    getindex(a, dims2indices(a, dims)...)

Base.@propagate_inbounds Base.setindex!(a::AbstractArray, x, ::Vararg{<:AbstractDimension}) = 
    setindex!(a, x, dims2indices(a, dims)...)

Base.@propagate_inbounds Base.view(a::AbstractArray, dims::Vararg{<:AbstractDimension}) = 
    view(a, dims2indices(a, dims)...)

Base.similar(a::AbstractArray, ::Type{T}, dims::AllDimensions) where T = 
    similar(a, T, dims2indices(a, dims))
# For use in similar()
Base.to_shape(dims::AllDimensions) = dims

Base.accumulate(f, A::AbstractArray, dims::AllDimensions) = accumulate(f, A, dimnum(a, dims))

Base.permutedims(a::AbstractArray, dims::AllDimensions) = permutedims(a, dimnum(a, dims))


#= SplitApplyCombine methods?
Should allow groupby using dims lookup to make this worth the dependency
Like group by time/lattitude/height band etc.

SplitApplyCombine.splitdims(a::AbstractArray, dims::AllDimensions) = 
    SplitApplyCombine.splitdims(a, dimnum(a, dims))

SplitApplyCombine.splitdimsview(a::AbstractArray, dims::AllDimensions) = 
    SplitApplyCombine.splitdimsview(a, dimnum(a, dims))
=#

