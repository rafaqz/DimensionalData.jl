
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

label(dim::AbstractDimension) = join((dimname(dim), getstring(units(dim))), " ")
label(dims::Dimensions) = join(join.(zip(dimname.(dims), string.(shorten.(val.(dims)))), ": ", ), ", ")

# This shouldn't be hard coded, but makes plots tolerable for now
shorten(x::AbstractFloat) = round(x, sigdigits=4)
shorten(x) = x

# Nothing doesn't string
getstring(::Nothing) = ""
getstring(x) = string(x)


# Base methods
Base.eltype(dim::AbstractDimension) = eltype(typeof(dim))
Base.eltype(dim::Type{AbstractDimension{T}}) where T = T
Base.size(dim::AbstractDimension, args...) = size(val(dim), args...)
Base.map(f, dim::AbstractDimension) = basetype(dim)(f(val(dim)))


# DimensionalData interface methods

dimname(a::AbstractArray) = dimname(dims(a))
dimname(dims::Dimensions) = (dimnames(dims), dimname(tail(dims))...)
dimname(dim::AbstractDimension) = dimname(typeof(dim))
dimname(dimtype::Type{<:AbstractDimension}) = dimname(dimtype)

dims(x::AbstractDimension) = x
dims(x::Dimensions) = x
dimtype(x) = typeof(dims(x))
dimtype(x::Type) = x

shortname(d::AbstractDimension) = shortname(typeof(d))
shortname(d::Type{<:AbstractDimension}) = dimname(d)

bounds(a, args...) = bounds(dims(a), args...)
bounds(dims::Dimensions, lookupdims::Tuple) = bounds(dims[[dimnums(dims)...]])
bounds(dims::Dimensions) = (bounds(dim2[1]), bounds(tail(dims)...,))
bounds(dim::AbstractDimension) = first(val(dim)), last(val(dim))


#= Lowe-level utility methods.

These do most of the work in the package, and are all @generated or recusive
functions for performance reasons.
=#

@inline hasdim(x::AbstractArray, lookup::AllDimensions) = hasdim(dims(x), lookup) 
@inline hasdim(dims::Dimensions, lookup::Tuple) = 
    hasdim(dims, lookup[1]) & hasdim(dims, tail(lookup)) 
@inline hasdim(dims::Dimensions, lookup::Tuple{}) = true
@inline hasdim(dims::Dimensions, lookup::AbstractDimension) = hasdim(dims, typeof(lookup))
@inline hasdim(dims::Dimensions, lookup::Type{<:AbstractDimension}) = 
    hasdim(typeof(dims), basetype(lookup))
@inline hasdim(dimtypes::Type, lookup::Type{<:AbstractDimension}) = 
    basetype(lookup) in basetype.(dimtypes.parameters)
@inline hasdim(dimtypes::Type, lookup::Type{UnionAll}) = 
    basetype(lookup) in basetype.(dimtypes.parameters)


dims2indices_inner(dimtypes::Type{<:Tuple}, lookup::Type{<:Tuple}) = begin
    indexexps = []
    dimtypes = flattendimtypes(dimtypes)
    # all(hasdim.(dimtypes, lookup.parameters)) || return :(throw(ArgumentError("Not all $lookup in $dimtypes")))
    for dimtype in dimtypes
        index = findfirst(l -> l <: basetype(dimtype), lookup.parameters)
        if index == nothing
            # A missing dim uses the emptyval arg
            push!(indexexps, :(emptyval))
        else
            push!(indexexps, :(val(lookup[$index])))
        end
    end
    Expr(:tuple, indexexps...)
end
@generated dims2indices(dimtypes::Type{DT}, lookup::Tuple, emptyval=:) where DT =
    dims2indices_inner(DT, lookup)
@inline dims2indices(a::AbstractArray, dims::Tuple, args...) = dims2indices(dimtype(a), dims, args...)
@inline dims2indices(a, dim::AbstractDimension, args...) = dims2indices(a, (dim,), args...)

@inline mapdims(f, dims::Dimensions) =
    (mapdims(f, dims[1]), mapdims(f, tail(dims))...,)
@inline mapdims(f, dims::Tuple{}) = ()
@inline mapdims(f, dim::AbstractDimension) = map(f, dim)

# Not type stable, but only runs inside @generated
@inline flattendimtypes(dimtypes::Type) = flattendimtypes((dimtypes.parameters...,))
@inline flattendimtypes(dimtypes::Tuple) = 
    (flattendimtypes(dimtypes[1]), flattendimtypes(tail(dimtypes))...,)
@inline flattendimtypes(dimtypes::Tuple{}) = ()
@inline flattendimtypes(dim::Type{<:AbstractDimension}) = dim
@inline flattendimtypes(affdims::Type{<:AbstractAffineDimensions}) = 
    flattendimtypes((affdims.parameters...,))

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

@inline dimnum(a, dims) = dimnum(dimtype(a), dims)
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

@inline getdim(a::AbstractArray, dim) = getdim(dims(a), basetype(dim))
@inline getdim(dims::Dimensions, dim::Integer) = dims[dim]
@inline getdim(dims::Dimensions, dim) = getdim(dims, basetype(dim))
@generated getdim(dims::DT, lookup::Type{L}) where {DT<:Dimensions,L} = begin
    index = findfirst(dt -> dt <: L, DT.parameters)
    if index == nothing
        :(throw(ArgumentError("No $lookup in $dims")))
    else
        :(dims[$index])
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

# Should only be used from kwargs constructors, so performance doesn't matter
@inline formatdims(a::AbstractArray{T,N}, dims::Tuple) where {T,N} = begin
    dimlen = length(dims)
    dimlen == N || throw(ArgumentError("dims ($dimlen) don't match array dimensions $(N)"))
    formatdims(a, dims, 1)
end
@inline formatdims(a, dims::Tuple, n) = (formatdims(a, dims[1], n), formatdims(a, tail(dims), n+1)...,)
@inline formatdims(a, dims::Tuple{}, n) = ()
@inline formatdims(a, dim::AbstractDimension{<:AbstractArray}, n) =
    if length(val(dim)) == size(a, n)
        dim
    else
        throw(ArgumentError("length of $dim $(length(val(dim))) does not match size of array dimension $n $(size(a, n))"))
    end
@inline formatdims(a, dim::AbstractDimension{<:Union{UnitRange,NTuple{2}}}, n) = begin
    range = val(dim)
    start, stop = first(range), last(range)
    steprange = start:(stop-start)/(size(a, n)-1):stop
    basetype(dim)(steprange)
end


#= AbstractArray methods where dims are an argument

These use AbstractArray instead of AbstractDimensionArray, which means most of
the interface can be used without inheriting from it.
=#

Base.@propagate_inbounds Base.getindex(a::AbstractArray, dims::Vararg{<:AbstractDimension}) =
    getindex(a, dims2indices(a, dims)...)
Base.@propagate_inbounds Base.setindex!(a::AbstractArray, x, rims::Vararg{<:AbstractDimension}) =
    setindex!(a, x, dims2indices(a, dims)...)
Base.@propagate_inbounds Base.view(a::AbstractArray, dims::Vararg{<:AbstractDimension}) =
    view(a, dims2indices(a, dims)...)
Base.similar(a::AbstractArray, ::Type{T}, dims::AllDimensions) where T =
    similar(a, T, dims2indices(a, dims))
Base.to_shape(dims::AllDimensions) = dims # For use in similar()
Base.accumulate(f, A::AbstractArray, dims::AllDimensions) = accumulate(f, A, dimnum(a, dims))
Base.permutedims(a::AbstractArray, dims::AllDimensions) = permutedims(a, dimnum(a, dims))
Base.adjoint(a::AbstractArray, dims::AllDimensions) = adjoint(a, dimnum(a, dims))
Base.transpose(a::AbstractArray, dims::AllDimensions) = transpose(a, dimnum(a, dims))


#= SplitApplyCombine methods?
Should allow groupby using dims lookup to make this worth the dependency
Like group by time/lattitude/height band etc.

SplitApplyCombine.splitdims(a::AbstractArray, dims::AllDimensions) =
    SplitApplyCombine.splitdims(a, dimnum(a, dims))

SplitApplyCombine.splitdimsview(a::AbstractArray, dims::AllDimensions) =
    SplitApplyCombine.splitdimsview(a, dimnum(a, dims))
=#

