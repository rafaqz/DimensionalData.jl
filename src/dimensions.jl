
"""
An AbstractDimension tags the dimensions in an AbstractArray.

It can also contain spatial coordinates and their metadata. For simplicity,
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

"""
AbstractDimensionsWrapper Wraps other dimensions, for
situations where they share an affine map or similar transformation
instead of linear maps, but need to work as usual for direct indexing.
"""
abstract type AbstractDimensionWrapper{T} end


# Getters

val(dim::AbstractDimension) = dim.val
val(dim) = dim

metadata(dim::AbstractDimension) = dim.metadata


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

label(dim::AbstractDimension) = join((dimname(dim), getstring(metadata(dim))), " ")
label(dims::Dimensions) = join(join.(zip(dimname.(dims), string.(shorten.(val.(dims)))), ": ", ), ", ")

# This shouldn't be hard coded, but it makes plots tolerable for now
shorten(x::AbstractFloat) = round(x, sigdigits=4)
shorten(x) = x

# Nothing doesn't string
getstring(::Nothing) = ""
getstring(x) = string(x)


# Primitives

# These do most of the work in the package, and are all @generated or recusive
# functions for performance reasons.

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
@inline dims2indices(a::AbstractArray, dims::Tuple, args...) = 
    dims2indices(dimtype(a), dims, args...)
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
@inline flattendimtypes(affdims::Type{<:AbstractDimensionWrapper}) =
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
@generated dimnum(dimtypes::Type{DTS}, dim::Type{D}) where {DTS,D} = begin
    index = findfirst(dt -> D <: basetype(dt), DTS.parameters)
    if index == nothing
        :(throw(ArgumentError("No $dim in $dimtypes")))
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
    ((), (basetype(d)(val(d)[i], metadata(d)),))
@inline slicedims(d::AbstractDimension, i::Colon) =
    ((basetype(d)(val(d), metadata(d)),), ())
@inline slicedims(d::AbstractDimension, i::AbstractVector) =
    ((basetype(d)(val(d)[i], metadata(d)),), ())
@inline slicedims(d::AbstractDimension{<:LinRange}, i::AbstractRange) = begin
    range = val(d)
    start, stop, len = range[first(i)], range[last(i)], length(i)
    d = basetype(d)(LinRange(start, stop, len), metadata(d))
    ((d,), ())
end


# Should only be used from kwargs constructors, so performance doesn't matter
@inline formatdims(a::AbstractArray{T,N}, dims::Tuple) where {T,N} = begin
    dimlen = length(dims)
    dimlen == N || throw(ArgumentError("dims ($dimlen) don't match array dimensions $(N)"))
    formatdims(a, dims, 1)
end
@inline formatdims(a, dims::Tuple, n) = 
    (formatdims(a, dims[1], n), formatdims(a, tail(dims), n + 1)...,)
@inline formatdims(a, dims::Tuple{}, n) = ()
@inline formatdims(a, dim::AbstractDimension{<:AbstractArray}, n) =
    if length(val(dim)) == size(a, n)
        dim
    else
        throw(ArgumentError("length of $dim $(length(val(dim))) does not match size of array dimension $n $(size(a, n))"))
    end
@inline formatdims(a, dim::AbstractDimension{<:Union{UnitRange,NTuple{2}}}, n) = begin
    range = val(dim)
    start, stop, len = first(range), last(range), size(a, n)
    basetype(dim)(LinRange(start, stop, len))
end


otherdimnums(n, removedims) =
    if n < 1
        ()
    elseif n in removedims
        (otherdimnums(n-1, removedims)...,)
    else
        (otherdimnums(n-1, removedims)..., n)
    end


reduceindices(a::AbstractArray{T,N}, reducedims) where {T,N} = reduceindices(N, reducedims)
reduceindices(n::Integer, reducedims) =
    if n < 1
        ()
    elseif n in reducedims
        (reduceindices(n-1, reducedims)..., 1)
    else
        (reduceindices(n-1, reducedims)..., :)
    end
