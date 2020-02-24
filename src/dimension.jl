"""
An AbstractDimension tags the dimensions in an AbstractArray.

It can also contain spatial coordinates and their metadata. For simplicity,
the same types are used both for storing dimension information and for indexing.
"""
abstract type AbstractDimension{T,G,M} end
# T is the type of underlying values
# G is the type of the "grid"
# M is the type of the metadata

"""
Abstract supertype for independent dimensions. Will plot on the X axis.
"""
abstract type IndependentDim{T,G,M} <: AbstractDimension{T,G,M} end
"""
Abstract supertype for Dependent dimensions. Will plot on the Y axis.
"""
abstract type DependentDim{T,G,M} <: AbstractDimension{T,G,M} end
"""
Abstract supertype for categorical dimensions.
"""
abstract type CategoricalDim{T,G,M} <: AbstractDimension{T,G,M} end

"""
Abstract parent type for all X dimensions.
"""
abstract type XDim{T,G,M} <: AbstractDimension{T,G,M} end

"""
Abstract parent type for all Y dimensions.
"""
abstract type YDim{T,G,M} <: AbstractDimension{T,G,M} end

"""
Abstract parent type for all Z dimensions.
"""
abstract type ZDim{T,G,M} <: AbstractDimension{T,G,M} end

"""
Abstract parent type for all categorical dimensions.
"""
abstract type CategoricalDim{T,G,M} <: AbstractDimension{T,G,M} end

"""
Abstract parent type for all time dimensions.
"""
abstract type TimeDim{T,G,M} <: IndependentDim{T,G,M} end

ConstructionBase.constructorof(d::Type{<:AbstractDimension}) = basetypeof(d)

const AbDim = AbstractDimension
const AbDimType = Type{<:AbDim}
const AbDimTuple = Tuple{<:AbDim,Vararg{<:AbDim,N}} where N
const AbDimTypeTuple = Tuple{Vararg{AbDimType}}
const AbDimVector = Vector{<:AbDim}
const DimOrDimType = Union{AbDim,AbDimType}
const AllDimensions = Union{AbDim,AbDimTuple,AbDimType,AbDimTypeTuple,AbDimVector}


# Getters
val(dim::AbDim) = dim.val
grid(dim::AbDim) = dim.grid
grid(dim::Type{<:AbDim}) = nothing
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
Base.eltype(dim::Type{<:AbDim{A}}) where A<:AbstractArray{T} where T = T
Base.size(dim::AbDim) = size(val(dim))
Base.length(dim::AbDim) = length(val(dim))
Base.ndims(dim::AbDim) = 0
Base.ndims(dim::AbDim{<:AbstractArray}) = ndims(val(dim))
Base.getindex(dim::AbDim) = val(dim)
Base.getindex(dim::AbDim{<:AbstractArray}, I...) = getindex(val(dim), I...)
Base.iterate(dim::AbDim{<:AbstractArray}, args...) = iterate(val(dim), args...)
Base.first(dim::AbDim) = val(dim)
Base.last(dim::AbDim) = val(dim)
Base.first(dim::AbDim{<:AbstractArray}) = first(val(dim))
Base.last(dim::AbDim{<:AbstractArray}) = last(val(dim))
Base.firstindex(dim::AbDim{<:AbstractArray}) = firstindex(val(dim))
Base.lastindex(dim::AbDim{<:AbstractArray}) = lastindex(val(dim))
Base.step(dim::AbDim) = step(grid(dim))
Base.eachindex(dim::AbDim{<:AbstractArray}) = eachindex(dim.val)
Base.Array(dim::AbDim{<:AbstractArray}) = Array(val(dim))
Base.:(==)(dim1::AbDim, dim2::AbDim) =
    typeof(dim1) == typeof(dim2) &&
    val(dim1) == val(dim2) &&
    grid(dim1) == grid(dim2) &&
    metadata(dim1) == metadata(dim2)

# AbstractArray methods where dims are the dispatch argument

@inline rebuildsliced(A, data, I, name::String=name(A)) =
    rebuild(A, data, slicedims(A, I)..., name)

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

"""
Undefined dimension.
"""
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
@dim Lon XDim "Longitude"
```
"""
macro dim end

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

# Define some common dimensions.
@dim X XDim
@doc "X dimension. `X <: XDim <: IndependentDim" X

@dim Y YDim
@doc "Y dimension. `Y <: YDim <: DependentDim" Y

@dim Z ZDim
@doc "Z dimension. `Z <: ZDim <: AbstractDimension" Z

@dim Ti TimeDim "Time"
@doc """
Time dimension. `Ti <: TimeDim <: IndependentDim

`Time` is already used by Dates, so we use `Ti` to avoid clashing.
""" Ti

const Time = Ti # For some backwards compat

#########################################################################
# coordinate dimensions
#########################################################################
struct Coord{T<:Vector{<:AbstractVector}, G, M, D} <: AbstractDimension{T,G,M}
    val::T
    dims::Tuple{D}
    grid::G
    metadata::M
end

DimensionalData.shortname(::Type{<:Coord}) = "Coord"
DimensionalData.longname(::Type{<:Coord}) = "Coordinates"
const Coordinates = Coord

# This constructs the dimension
Coord(val::T, dims::Tuple{D}) where {T, D} =
Coord{T, D, UnknownGrid, Nothing}(val, dims, UnknownGrid(), nothing)
