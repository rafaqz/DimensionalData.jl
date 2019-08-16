
"""
An AbstractDimension tags the dimensions in an AbstractArray.

It can also contain spatial coordinates and their metadata. For simplicity,
the same types are used both for storing dimension information and for indexing.
"""
abstract type AbstractDimension{T,M} end

const AbDim = AbstractDimension
const AbDimType = Type{<:AbDim}
const AbDimTuple = Tuple{Vararg{<:AbDim,N}} where N
const AbDimVector = Vector{<:AbDim}
const DimOrDimType = Union{AbDim,AbDimType}
const AllDimensions = Union{AbDim,AbDimTuple,AbDimType,
                            Tuple{Vararg{AbDimType}},
                            Vector{<:AbDim}}

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
val(dim::AbDim) = dim.val
metadata(dim::AbDim) = dim.metadata

# DimensionalData interface methods

dimname(a::AbstractArray) = dimname(dims(a))
dimname(dims::AbDimTuple) = (dimname(dims[1]), dimname(tail(dims))...)
dimname(dims::Tuple{}) = ()
dimname(dim::AbDim) = dimname(typeof(dim))

dims(x::AbDim) = x
dims(x::AbDimTuple) = x
dimtype(x) = typeof(dims(x))
dimtype(x::Type) = x

shortname(d::AbDim) = shortname(typeof(d))
shortname(d::Type{<:AbDim}) = dimname(d)

bounds(a, args...) = bounds(dims(a), args...)
bounds(dims::AbDimTuple, lookupdims::Tuple) = bounds(dims[[dimnums(dims)...]])
bounds(dims::AbDimTuple) = (bounds(dim2[1]), bounds(tail(dims)...,))
bounds(dim::AbDim) = first(val(dim)), last(val(dim))

units(dim::AbDim) = isnothing(metadata(dim)) ? "" : get(metadata(dim), :units, "")

label(dim::AbDim) = join((dimname(dim), getstring(units(dim))), " ")
label(dims::AbDimTuple) = join(join.(zip(dimname.(dims), string.(shorten.(val.(dims)))), ": ", ), ", ")

# This shouldn't be hard coded, but it makes plots tolerable for now
shorten(x::AbstractFloat) = round(x, sigdigits=4)
shorten(x) = x

# Nothing doesn't string
getstring(::Nothing) = ""
getstring(x) = string(x)


# Base methods

# Base.eltype(dim::AbDim) = eltype(typeof(dim))
# Base.eltype(dim::Type{AbDim{T}}) where T = T
Base.length(dim::AbDim) = 1
Base.show(io::IO, dim::AbDim) = begin
    printstyled(io, "\n", dimname(dim), ": "; color=:red)
    show(io, typeof(dim))
    printstyled(io, "\nval: "; color=:green)
    show(io, val(dim))

    # printstyled(io, indent, name(v), color=:green)
    printstyled(io, "\nmetadata: "; color=:blue)
    show(io, metadata(dim))
    print(io, "\n")
end
# Base.axes(f, dim::AbDimTuple) =
# Base.broadcast


# AbstractArray methods where dims are the dispatch argument

rebuildsliced(a, data, I) = rebuild(a, data, slicedims(a, I)...)

Base.@propagate_inbounds Base.getindex(a::AbstractArray, dims::Vararg{<:AbDim{<:Number}}) =
    getindex(a, dims2indices(a, dims)...)
Base.@propagate_inbounds Base.getindex(a::AbstractArray, dims::Vararg{<:AbDim}) = 
    rebuildsliced(a, getindex(parent(a), dims2indices(a, dims)...), dims)

Base.@propagate_inbounds Base.setindex!(a::AbstractArray, x, dims::Vararg{<:AbDim}) =
    setindex!(parent(a), x, dims2indices(a, dims)...)

Base.@propagate_inbounds Base.view(a::AbstractArray, dims::Vararg{<:AbDim}) = 
    rebuildsliced(a, view(parent(a), dims2indices(a, dims)...), dims)

@inline Base.permutedims(a::AbstractArray, perm::AllDimensions) = begin
    perm = dimnum(a, perm)
    rebuild(a, permutedims(parent(a), [perm...]), permutedims(a.dims, perm), refdims(a))
end
@inline Base.axes(a::AbstractArray, dims::DimOrDimType) = axes(a, dimnum(a, dims))
@inline Base.size(a::AbstractArray, dims::DimOrDimType) = size(a, dimnum(a, dims))

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

@inline Statistics._median(a::AbstractArray, dims::AllDimensions) =
    Base._median(a, dimnum(a, dims))
@inline Base._mapreduce_dim(f, op, nt::NamedTuple{(),<:Tuple}, A::AbstractArray, dims::AllDimensions) =
    Base._mapreduce_dim(f, op, nt, A, dimnum(A, dims))
# Unfortunately Base/accumulate.jl kwargs methods all force dims to be Integer.
# accumulate wont work unless that is relaxed, or we copy half of the file here.
@inline Base._accumulate!(op, B, A, dims::AllDimensions, init::Union{Nothing, Some}) =
    Base._accumulate!(op, B, A, dimnum(A, dims), init)


#= SplitApplyCombine methods?
Should allow groupby using dims lookup to make this worth the dependency
Like group by time/lattitude/height band etc.

SplitApplyCombine.splitdims(a::AbstractArray, dims::AllDimensions) =
    SplitApplyCombine.splitdims(a, dimnum(a, dims))

SplitApplyCombine.splitdimsview(a::AbstractArray, dims::AllDimensions) =
    SplitApplyCombine.splitdimsview(a, dimnum(a, dims))
=#
