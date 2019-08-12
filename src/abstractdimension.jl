
"""
An AbstractDimension tags the dimensions in an AbstractArray.

It can also contain spatial coordinates and their metadata. For simplicity,
the same types are used both for storing dimension information and for indexing.
"""
abstract type AbstractDimension{T,M} end

const Dimensions = Tuple{Vararg{<:AbstractDimension,N}} where N
const AllDimensions = Union{AbstractDimension,Dimensions,Type{<:AbstractDimension},
                            Tuple{Vararg{<:Type{<:AbstractDimension}}},
                            Vector{<:AbstractDimension}}

"""
AbstractCombined holds mapping that require multiple dimension
when `select()` is used, shuch as for situations where they share an 
affine map or similar transformation instead of linear maps. Each dim 
that shares the mapping must contain the same (identical) object.

Dimensions holding a DimCombination will work as usual for direct indexing.

All AbstractDimension are assumed to `val` and `metadata` fields.
"""
abstract type AbstractDimCombination end

# Getters
val(dim::AbstractDimension) = val(dim.val)
val(dim) = dim

metadata(dim::AbstractDimension) = dim.metadata

# DimensionalData interface methods

dimname(a::AbstractArray) = dimname(dims(a))
dimname(dims::Dimensions) = (dimnames(dims), dimname(tail(dims))...)
dimname(dim::AbstractDimension) = dimname(typeof(dim))

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

units(dim::AbstractDimension) = isnothing(metadata(dim)) ? "" : get(metadata(dim), :units, "")

label(dim::AbstractDimension) = join((dimname(dim), getstring(units(dim))), " ")
label(dims::Dimensions) = join(join.(zip(dimname.(dims), string.(shorten.(val.(dims)))), ": ", ), ", ")

# This shouldn't be hard coded, but it makes plots tolerable for now
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
Base.show(io::IO, dim::AbstractDimension) = begin 
    printstyled(io, "\n", dimname(dim), ": "; color=:red)
    show(io, typeof(dim))
    printstyled(io, "\nval:\n"; color=:green)
    show(io, val(dim))

    # printstyled(io, indent, name(v), color=:green)
    printstyled(io, "\nmetadata:\n"; color=:blue)
    show(io, metadata(dim))
    print(io, "\n")
end


# AbstractArray methods where dims are the dispatch argument

# These use AbstractArray instead of AbstractDimensionArray, which means some of
# the interface can be used without inheriting from it.

rebuildsliced(a, data, I) = rebuild(a, data, slicedims(a, I)...)

Base.@propagate_inbounds Base.getindex(a::AbstractArray, dims::Vararg{<:AbstractDimension{<:Number}}) =
    getindex(a, dims2indices(a, dims)...)
Base.@propagate_inbounds Base.getindex(a::AbstractArray, dims::Vararg{<:AbstractDimension}) = begin
    I = dims2indices(a, dims)
    rebuildsliced(a, getindex(parent(a), I...), I)
end
Base.@propagate_inbounds Base.setindex!(a::AbstractArray, x, dims::Vararg{<:AbstractDimension}) = begin
    I = dims2indices(a, dims)
    rebuildsliced(a, setindex!(parent(a), x, I...), I)
end
Base.@propagate_inbounds Base.view(a::AbstractArray, dims::Vararg{<:AbstractDimension}) = begin
    I = dims2indices(a, dims)
    rebuildsliced(a, view(parent(a), I...), I)
end
Base.permutedims(a::AbstractArray, dims::AllDimensions) = begin
    perm = [dimnum(a, dims)...]
    rebuild(a, permutedims(parent(a), perm), a.dims[perm], refdims(a))
end
Base.axes(a::AbstractArray, dims::Union{AbstractDimension,Type{AbstractDimension}}) = 
    axes(a, dimnum(a, dims))
Base.size(a::AbstractArray, dims::Union{AbstractDimension,Type{AbstractDimension}}) = 
    size(a, dimnum(a, dims))

# Dimension reduction methods where dims are an argument
# targeting underscore _methods so we can use dispatch ont the dims arg

for (mod, fname) in ((:Base, :sum), (:Base, :prod), (:Base, :maximum), (:Base, :minimum), (:Statistics, :mean))
    _fname = Symbol('_', fname)
    @eval begin
        ($mod.$_fname)(a::AbstractArray{T,N}, dims::AllDimensions) where {T,N} =
            ($mod.$_fname)(a, dimnum(a, dims))
        ($mod.$_fname)(f, a::AbstractArray{T,N}, dims::AllDimensions) where {T,N} =
            ($mod._fname)(f, a, dimnum(a, dims))
    end
end

for fname in (:std, :var)
    _fname = Symbol('_', fname)
    @eval function (Statistics.$_fname)(a::AbstractArray{T,N} , corrected::Bool, mean, dims::AllDimensions) where {T,N}
        dimnums = dimnum(a, dims)
        (Statistics.$_fname)(a, corrected, mean, dimnums)
    end
end

Statistics._median(a::AbstractArray, dims::AllDimensions) = 
    Base._median(a, dimnum(a, dims))
Base._mapreduce_dim(f, op, nt::NamedTuple{(),<:Tuple}, A::AbstractArray, dims::AllDimensions) =
    Base._mapreduce_dim(f, op, nt, A, dimnum(A, dims))
# Unfortunately Base/accumulate.jl kwargs methods all force dims to be Integer.
# accumulate wont work unless that is relaxed, or we copy half of the file here.
Base._accumulate!(op, B, A, dims::AllDimensions, init::Union{Nothing, Some}) =
    Base._accumulate!(op, B, A, dimnum(A, dims), init)


#= SplitApplyCombine methods?
Should allow groupby using dims lookup to make this worth the dependency
Like group by time/lattitude/height band etc.

SplitApplyCombine.splitdims(a::AbstractArray, dims::AllDimensions) =
    SplitApplyCombine.splitdims(a, dimnum(a, dims))

SplitApplyCombine.splitdimsview(a::AbstractArray, dims::AllDimensions) =
    SplitApplyCombine.splitdimsview(a, dimnum(a, dims))
=#




# Primitives

# These do most of the work in the package, and are all @generated or recusive
# functions for performance reasons.

dims2indices_inner(dimtypes::Type{<:Tuple}, lookup::Type{<:Tuple}) = begin
    indexexps = []
    # all(hasdim.(dimtypes, lookup.parameters)) || return :(throw(ArgumentError("Not all $lookup in $dimtypes")))
    for dimtype in dimtypes.parameters
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


sortdims_inner(dimtypes::Type, lookup::Type) = begin
    indexexps = []
    for dimtype in dimtypes.parameters
        index = findfirst(d -> d <: basetype(dimtype), lookup.parameters)
        if index == nothing
            push!(indexexps, :(nothing))
        else
            push!(indexexps, :(lookup[$index]))
        end
    end
    Expr(:tuple, indexexps...)
end
@generated sortdims(dimtypes::Type{DT}, lookup::Tuple) where DT = sortdims_inner(DT, lookup)
@inline sortdims(a::AbstractArray, lookup::Tuple) = sortdims(dimtype(a), lookup)


@inline slicedims(a::AbstractArray, I::Tuple) = begin
    newdims, newrefdims = slicedims(dims(a), I)
    # Combine new refdims with existing refdims
    newdims, (refdims(a)..., newrefdims...)
end
@inline slicedims(dims::Tuple, I::Tuple) = begin
    d = slicedims(dims[1], I[1])
    ds = slicedims(tail(dims), tail(I))
    (d[1]..., ds[1]...), (d[2]..., ds[2]...)
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


# Use Setfield.jl for this kind of thing?
@inline replacedim_n(f, dims::Dimensions) = replacedim_n(f, dims, 1)
@inline replacedim_n(f, dims::Dimensions, n::Integer) =
    (replacedim_n(f, dims[1], n), replacedim_n(f, tail(dims), n+1)...,)
@inline replacedim_n(f, dims::Tuple{}, n::Integer) = ()
@inline replacedim_n(f, dim::AbstractDimension, n::Integer) = f(dim, n)


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

# @inline hasdim(x::AbstractArray, lookup::AllDimensions) = hasdim(dims(x), lookup)
# @inline hasdim(dims::Dimensions, lookup::Tuple) =
#     hasdim(dims, lookup[1]) & hasdim(dims, tail(lookup))
# @inline hasdim(dims::Dimensions, lookup::Tuple{}) = true
# @inline hasdim(dims::Dimensions, lookup::AbstractDimension) = hasdim(dims, typeof(lookup))
# @inline hasdim(dims::Dimensions, lookup::Type{<:AbstractDimension}) =
#     hasdim(typeof(dims), basetype(lookup))
# @inline hasdim(dimtypes::Type, lookup::Type{<:AbstractDimension}) =
#     basetype(lookup) in basetype.(dimtypes.parameters)
# @inline hasdim(dimtypes::Type, lookup::Type{UnionAll}) =
#     basetype(lookup) in basetype.(dimtypes.parameters)


# Should only be used from kwargs constructors, so performance doesn't matter so much
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

# Get the numbers for all the other dimensions
otherdimnums(a::AbstractArray{T,N}, removedims) where {T,N} = otherdimnums(N, removedims)
otherdimnums(n, removedims) =
    if n < 1
        ()
    elseif n in removedims
        (otherdimnums(n-1, removedims)...,)
    else
        (otherdimnums(n-1, removedims)..., n)
    end

# Return colon for dimensions to include, 1 for dimensions to reduce
reduceindices(a::AbstractArray{T,N}, reducedims) where {T,N} = reduceindices(N, reducedims)
reduceindices(n::Integer, reducedims) =
    if n < 1
        ()
    elseif n in reducedims
        (reduceindices(n-1, reducedims)..., 1)
    else
        (reduceindices(n-1, reducedims)..., :)
    end
