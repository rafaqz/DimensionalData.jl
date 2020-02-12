"""
An AbstractDimension tags the dimensions in an AbstractArray.

It can also contain spatial coordinates and their metadata. For simplicity,
the same types are used both for storing dimension information and for indexing.
"""
abstract type AbstractDimension{T,G,M} end

abstract type XDim{T,G,M} <: AbstractDimension{T,G,M} end
abstract type YDim{T,G,M} <: AbstractDimension{T,G,M} end
abstract type ZDim{T,G,M} <: AbstractDimension{T,G,M} end
abstract type CategoricalDim{T,G,M} <: AbstractDimension{T,G,M} end

ConstructionBase.constructorof(d::Type{<:AbstractDimension}) = basetypeof(d)

const AbDim = AbstractDimension
const AbDimType = Type{<:AbDim}
const AbDimTuple = Tuple{<:AbDim,Vararg{<:AbDim,N}} where N
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
relationorder(dim::AbDim) = relationorder(order(dim))

locus(dim::AbDim) = locus(grid(dim))
sampling(dim::AbDim) = sampling(grid(dim))

# DimensionalData interface methods
rebuild(dim::D, val, grid=grid(dim), metadata=metadata(dim)) where D <: AbDim =
    constructorof(D)(val, grid, metadata)

dims(x::AbDim) = x
dims(x::AbDimTuple) = x
name(dim::AbDim) = name(typeof(dim))
shortname(d::AbDim) = shortname(typeof(d))
shortname(d::Type{<:AbDim}) = name(d) # Use `name` as fallback
units(dim::AbDim) = metadata(dim) == nothing ? nothing : get(val(metadata(dim)), :units, nothing)

bounds(dims::AbDimTuple, lookupdims::Tuple) = bounds(dims[[dimnum(dims, lookupdims)...]]...)
bounds(dims::AbDimTuple, lookupdim::DimOrDimType) = bounds(dims[dimnum(dims, lookupdim)])
bounds(dims::AbDimTuple) = (bounds(dims[1]), bounds(tail(dims))...)
bounds(dims::Tuple{}) = ()
bounds(dim::AbDim) = bounds(grid(dim), dim)


# TODO bounds for irregular grids


# Base methods
Base.eltype(dim::Type{<:AbDim{T}}) where T = T
Base.ndims(dim::AbDim) = ndims(val(dim))
Base.size(dim::AbDim) = size(val(dim))
Base.length(dim::AbDim) = length(val(dim))
Base.getindex(dim::AbDim, I...) = getindex(val(dim), I...)
Base.iterate(dim::AbDim, args...) = iterate(val(dim), args...)
Base.firstindex(dim::AbDim) = firstindex(val(dim))
Base.lastindex(dim::AbDim) = lastindex(val(dim))
Base.step(dim::AbDim) = step(grid(dim))
Base.:(==)(dim1::AbDim, dim2::AbDim) =
    typeof(dim1) == typeof(dim2) &&
    val(dim1) == val(dim2) &&
    grid(dim1) == grid(dim2) &&
    metadata(dim1) == metadata(dim2)

# AbstractArray methods where dims are the dispatch argument

@inline rebuildsliced(A, data, I, name::String = A.name) =
    rebuild(A, data, slicedims(A, I)...,name)

Base.@propagate_inbounds Base.getindex(A::AbstractArray, dim::AbDim, dims::Vararg{<:AbDim}) =
    getindex(A, dims2indices(A, (dim, dims...))...)

Base.@propagate_inbounds Base.setindex!(A::AbstractArray, x, dim::AbDim, dims::Vararg{<:AbDim}) =
    setindex!(A, x, dims2indices(A, (dim, dims...))...)

Base.@propagate_inbounds Base.view(A::AbstractArray, dim::AbDim, dims::Vararg{<:AbDim}) =
    view(A, dims2indices(A, (dim, dims...))...)

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


struct EmptyDim <: AbstractDimension{Int,NoGrid,Nothing} end

val(::EmptyDim) = 1:1
grid(::EmptyDim) = NoGrid()
metadata(::EmptyDim) = nothing
name(::EmptyDim) = "Empty"

"""
    @dim typ [supertype=AbstractDimension] [name=string(typ)] [shortname=string(typ)]

Macro to easily define specific dimensions.

Example:
```julia
@dim Lat "Lattitude" "lat"
@dim Lon AbstraxtX "Longitude"
```
"""
macro dim(typ::Symbol, args...)
    dimmacro(typ::Symbol, :AbstractDimension, args...)
end

macro dim(typ::Symbol, supertyp::Symbol, args...)
    dimmacro(typ, supertyp, args...)
end

dimmacro(typ, supertype, name=string(typ), shortname=string(typ)) =
    esc(quote
        struct $typ{T,G,M} <: $supertype{T,G,M}
            val::T
            grid::G
            metadata::M
        end
        $typ(val=:; grid=UnknownGrid(), metadata=nothing) = $typ(val, grid, metadata)
        DimensionalData.name(::Type{<:$typ}) = $name
        DimensionalData.shortname(::Type{<:$typ}) = $shortname
    end)

# Define some common dimensions. Time is taken by Dates, so we use Ti
@dim X XDim
@dim Y YDim
@dim Z ZDim
@dim Ti XDim "Time"

const Time = Ti # For some backwards compat
