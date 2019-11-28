"""
An AbstractDimension tags the dimensions in an AbstractArray.

It can also contain spatial coordinates and their metadata. For simplicity,
the same types are used both for storing dimension information and for indexing.
"""
abstract type AbstractDimension{T,G,M} end

ConstructionBase.constructorof(d::Type{<:AbstractDimension}) = basetypeof(d)

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
grid(dim::AbDim) = dim.grid
metadata(dim::AbDim) = dim.metadata

order(dim::AbDim) = order(grid(dim))
indexorder(dim::AbDim) = indexorder(order(dim))
arrayorder(dim::AbDim) = arrayorder(order(dim))

# DimensionalData interface methods
rebuild(dim::D, val, grid=grid(dim)) where D <: AbDim = 
    rebuild(dim, val, grid, metadata(dim))
rebuild(dim::D, val, grid, metadata) where D <: AbDim = 
    constructorof(D)(val, grid, metadata)

dims(x::AbDim) = x
dims(x::AbDimTuple) = x
name(dim::AbDim) = name(typeof(dim))
shortname(d::AbDim) = shortname(typeof(d))
shortname(d::Type{<:AbDim}) = name(d)
units(dim::AbDim) = metadata(dim) == nothing ? nothing : get(metadata(dim), :units, nothing)

bounds(A::AbstractArray, args...) = bounds(dims(A), args...)

bounds(dims::AbDimTuple, lookupdims::Tuple) = bounds(dims[[dimnum(dims, lookupdims)...]]...)
bounds(dims::AbDimTuple, lookupdim::DimOrDimType) = bounds(dims[dimnum(dims, lookupdim)])

bounds(dims::AbDimTuple) = (bounds(dims[1]), bounds(tail(dims))...)
bounds(dims::Tuple{}) = ()
bounds(dim::AbDim) = bounds(grid(dim), dim)

bounds(grid::AllignedGrid, dim) = bounds(grid)
bounds(grid::UnknownGrid, dim) = first(val(dim)), last(val(dim))

bounds(grid::CategoricalGrid, dim) = bounds(indexorder(grid), grid, dim)
bounds(::Forward, grid, dim) = first(val(dim)), last(val(dim))
bounds(::Reverse, grid, dim) = last(val(dim)), first(val(dim))
bounds(::Unordered, grid, dim) = throw(MethodError("Cannot call `bounds` on an unordered grid"))

bounds(grid::RegularGrid, dim) = bounds(indexorder(grid), locus(grid), grid, dim)
bounds(::Forward, ::Start, grid, dim) = first(val(dim)), last(val(dim)) + span(grid)
bounds(::Reverse, ::Start, grid, dim) = last(val(dim)), first(val(dim)) + span(grid)
bounds(::Forward, ::Center, grid, dim) = first(val(dim)) - span(grid) / 2, last(val(dim)) + span(grid) / 2
bounds(::Reverse, ::Center, grid, dim) = last(val(dim)) - span(grid) / 2, first(val(dim)) + span(grid) / 2
bounds(::Forward, ::End, grid, dim) = first(val(dim)) - span(grid), last(val(dim))
bounds(::Reverse, ::End, grid, dim) = last(val(dim)) - span(grid), first(val(dim))

# TODO bounds for irregular grids


# Base methods
Base.eltype(dim::Type{<:AbDim{T}}) where T = T
Base.length(dim::AbDim) = length(val(dim))

Base.show(io::IO, dim::AbDim) = begin
    printstyled(io, "\n", name(dim), ": "; color=:red)
    show(io, typeof(dim))
    printstyled(io, "\nval: "; color=:green)
    show(io, val(dim))
    printstyled(io, "\ngrid: "; color=:yellow)
    show(io, grid(dim))
    printstyled(io, "\nmetadata: "; color=:blue)
    show(io, metadata(dim))
    print(io, "\n")
end

# AbstractArray methods where dims are the dispatch argument

@inline rebuildsliced(A, data, I) = rebuild(A, data, slicedims(A, I)...)

Base.@propagate_inbounds Base.getindex(A::AbstractArray, dims::Vararg{<:AbDim{<:Number}}) =
    getindex(A, dims2indices(A, dims)...)
Base.@propagate_inbounds Base.getindex(A::AbstractArray, dims::Vararg{<:AbstractDimension}) = 
    getindex(A, dims2indices(A, dims)...)

Base.@propagate_inbounds Base.setindex!(A::AbstractArray, x, dims::Vararg{<:AbstractDimension}) =
    setindex!(A, x, dims2indices(A, dims)...)

Base.@propagate_inbounds Base.view(A::AbstractArray, dims::Vararg{<:AbstractDimension}) = 
    view(A, dims2indices(A, dims)...)

@inline Base.axes(A::AbstractArray, dims::DimOrDimType) = axes(A, dimnum(A, dims))
@inline Base.size(A::AbstractArray, dims::DimOrDimType) = size(A, dimnum(A, dims))


"""
Dimensions with user-set type paremeters
"""
abstract type AbstractParametricDimension{X,T,G,M} <: AbstractDimension{T,G,M} end

"""
A generic dimension. For use when custom dims are required when loading
data from a file. The sintax is ugly and verbose to use for indexing, 
ie `Dim{:lat}(1:9)` rather than `Lat(1:9)`. This is the main reason 
they are not the only type of dimension availabile.
"""
struct Dim{X,T,G,M} <: AbstractParametricDimension{X,T,G,M} 
    val::T
    grid::G
    metadata::M
    Dim{X}(val, grid, metadata) where X = 
        new{X,typeof(val),typeof(grid),typeof(metadata)}(val, grid, metadata)
end

Dim{X}(val=:; grid=UnknownGrid(), metadata=nothing) where X = Dim{X}(val, grid, metadata)
name(::Type{<:Dim{X}}) where X = "Dim $X"
shortname(::Type{<:Dim{X}}) where X = "$X"
basetypeof(::Type{<:Dim{X}}) where {X} = Dim{X}


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
        struct $typ{T,G,M} <: AbstractDimension{T,G,M}
            val::T
            grid::G
            metadata::M
        end
        $typ(val=:; grid=UnknownGrid(), metadata=nothing) = $typ(val, grid, metadata)
        DimensionalData.name(::Type{<:$typ}) = $name
        DimensionalData.shortname(::Type{<:$typ}) = $shortname
    end)
end

# Define some common dimensions
@dim Time
@dim X 
@dim Y 
@dim Z 
