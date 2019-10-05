"""
Trait indicating that the dimension is in the normal forward order. 
"""
struct Forward end

"""
Trait indicating that the dimension is in the reverse order. 
Selector lookup and plotting will be reverse.
"""
struct Reverse end

"""
An AbstractDimension tags the dimensions in an AbstractArray.

It can also contain spatial coordinates and their metadata. For simplicity,
the same types are used both for storing dimension information and for indexing.
"""
abstract type AbstractDimension{T,M,O} end

"""
AbstractCombined holds mapping that require multiple dimension
when `select()` is used, shuch as for situations where they share an
affine map or similar transformation instead of linear maps. Each dim
that shares the mapping must contain the same (identical) object.

Dimensions holding a DimCombination will work as usual for direct indexing.

All AbstractDimension are assumed to `val` and `metadata` fields.
"""
abstract type AbstractDimCombination end

const AbDim = AbstractDimension
const AbDimType = Type{<:AbDim}
const AbDimTuple = Tuple{Vararg{<:AbDim,N}} where N
const AbDimVector = Vector{<:AbDim}
const DimOrDimType = Union{AbDim,AbDimType}
const AllDimensions = Union{AbDim,AbDimTuple,AbDimType,
                            Tuple{Vararg{AbDimType}},
                            Vector{<:AbDim}}

# Getters
val(dim::AbDim) = dim.val
metadata(dim::AbDim) = dim.metadata
order(dim::AbDim) = dim.order

# DimensionalData interface methods
rebuild(dim::AbDim, val) = basetype(dim)(val, metadata(dim), order(dim))

dims(x::AbDim) = x
dims(x::AbDimTuple) = x
name(dim::AbDim) = name(typeof(dim))
shortname(d::AbDim) = shortname(typeof(d))
shortname(d::Type{<:AbDim}) = name(d)
units(dim::AbDim) = metadata(dim) == nothing ? "" : get(metadata(dim), :units, "")

bounds(a, args...) = bounds(dims(a), args...)
bounds(dims::AbDimTuple, lookupdims::Tuple) = bounds(dims[[dimnum(dims, lookupdims)...]]...)
bounds(dims::AbDimTuple, dim::DimOrDimType) = bounds(dims[dimnum(dims, dim)])
bounds(dims::AbDimTuple) = (bounds(dims[1]), bounds(tail(dims))...)
bounds(dims::Tuple{}) = ()
bounds(dim::AbDim) = bounds(order(dim), dim)
bounds(::Forward, dim::AbDim) = first(val(dim)), last(val(dim))
bounds(::Reverse, dim::AbDim) = last(val(dim)), first(val(dim))

# Base methods
Base.eltype(dim::Type{<:AbDim{T}}) where T = T
Base.length(dim::AbDim) = length(val(dim))
Base.show(io::IO, dim::AbDim) = begin
    printstyled(io, "\n", name(dim), ": "; color=:red)
    show(io, typeof(dim))
    printstyled(io, "\nval: "; color=:green)
    show(io, val(dim))

    # printstyled(io, indent, name(v), color=:green)
    printstyled(io, "\nmetadata: "; color=:blue)
    show(io, metadata(dim))
    print(io, "\n")
end

# AbstractArray methods where dims are the dispatch argument

@inline rebuildsliced(a, data, I) = rebuild(a, data, slicedims(a, I)...)

Base.@propagate_inbounds Base.getindex(a::AbstractArray, dims::Vararg{<:AbDim{<:Number}}) =
    getindex(a, dims2indices(a, dims)...)
Base.@propagate_inbounds Base.getindex(a::AbstractArray, dims::Vararg{<:AbstractDimension}) = 
    getindex(a, dims2indices(a, dims)...)

Base.@propagate_inbounds Base.setindex!(a::AbstractArray, x, dims::Vararg{<:AbstractDimension}) =
    setindex!(a, x, dims2indices(a, dims)...)

Base.@propagate_inbounds Base.view(a::AbstractArray, dims::Vararg{<:AbstractDimension}) = 
    view(a, dims2indices(a, dims)...)

@inline Base.axes(a::AbstractArray, dims::DimOrDimType) = axes(a, dimnum(a, dims))
@inline Base.size(a::AbstractArray, dims::DimOrDimType) = size(a, dimnum(a, dims))


#= SplitApplyCombine methods?
Should allow groupby using dims lookup to make this worth the dependency
Like group by time/lattitude/height band etc.

SplitApplyCombine.splitdims(a::AbstractArray, dims::AllDimensions) =
    SplitApplyCombine.splitdims(a, dimnum(a, dims))

SplitApplyCombine.splitdimsview(a::AbstractArray, dims::AllDimensions) =
    SplitApplyCombine.splitdimsview(a, dimnum(a, dims))
=#




"""
Dimensions with user-set type paremeters
"""
abstract type AbstractParametricDimension{X,T,M,O} <: AbstractDimension{T,M,O} end

"""
A generic dimension. For use when custom dims are required when loading
data from a file. The sintax is ugly and verbose to use for indexing, 
ie `Dim{:lat}(1:9)` rather than `Lat(1:9)`. This is the main reason 
they are not the only type of dimension availabile.
"""
struct Dim{X,T,M,O} <: AbstractParametricDimension{X,T,M,O} 
    val::T
    metadata::M
    order::O
    Dim{X}(val, metadata, order) where X = 
        new{X,typeof(val),typeof(metadata),typeof(order)}(val, metadata, order)
end

@inline Dim{X}(val=:; metadata=nothing, order=Forward()) where X = 
    Dim{X}(val, metadata, order)
name(::Type{<:Dim{X}}) where X = "Dim $X"
shortname(::Type{<:Dim{X}}) where X = "$X"
basetype(::Type{<:Dim{X,T,N}}) where {X,T,N} = Dim{X}


"""
    @dim typ [name=string(typ)] [shortname=string(typ)]

Macro to easily define specific dimensions.

Example:
```julia
@dim Lat "Lattitude"
```
"""
macro dim(typ, name=string(typ), shortname=string(typ))
    esc(quote
        struct $typ{T,M,O} <: AbstractDimension{T,M,O}
            val::T
            metadata::M
            order::O
        end
        $typ(val=:; metadata=nothing, order=Forward()) = $typ(val, metadata, order)
        DimensionalData.name(::Type{<:$typ}) = $name
        DimensionalData.shortname(::Type{<:$typ}) = $shortname
    end)
end

# Define some common dimensions
@dim Time
@dim X 
@dim Y 
@dim Z 
