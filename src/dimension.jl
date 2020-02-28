"""
Dimensions tag the dimensions of an AbstractArray, or other dimensional data.

It can also contain spatial coordinates and their metadata. For simplicity,
the same types are used both for storing dimension information and for indexing.
"""
abstract type Dimension{T,G,M} end

"""
Abstract supertype for independent dimensions. Will plot on the X axis.
"""
abstract type IndependentDim{T,G,M} <: Dimension{T,G,M} end

"""
Abstract supertype for Dependent dimensions. Will plot on the Y axis.
"""
abstract type DependentDim{T,G,M} <: Dimension{T,G,M} end

"""
Abstract supertype for categorical dimensions. 
"""
abstract type CategoricalDim{T,G,M} <: Dimension{T,G,M} end

"""
Abstract parent type for all X dimensions.
"""
abstract type XDim{T,G,M} <: IndependentDim{T,G,M} end

"""
Abstract parent type for all Y dimensions.
"""
abstract type YDim{T,G,M} <: DependentDim{T,G,M} end

"""
Abstract parent type for all Z dimensions.
"""
abstract type ZDim{T,G,M} <: Dimension{T,G,M} end

"""
Abstract parent type for all time dimensions.
"""
abstract type TimeDim{T,G,M} <: IndependentDim{T,G,M} end

ConstructionBase.constructorof(d::Type{<:Dimension}) = basetypeof(d)

const DimType = Type{<:Dimension}
const DimTuple = Tuple{<:Dimension,Vararg{<:Dimension}} where N
const DimTypeTuple = Tuple{Vararg{DimType}}
const DimVector = Vector{<:Dimension}
const DimOrDimType = Union{Dimension,DimType}
const AllDims = Union{Dimension,DimTuple,DimType,DimTypeTuple,DimVector}


# Getters
val(dim::Dimension) = dim.val
grid(dim::Dimension) = dim.grid
grid(dim::Type{<:Dimension}) = nothing
metadata(dim::Dimension) = dim.metadata

order(dim::Dimension) = order(grid(dim))
indexorder(dim::Dimension) = indexorder(order(dim))
arrayorder(dim::Dimension) = arrayorder(order(dim))
relationorder(dim::Dimension) = relationorder(order(dim))

locus(dim::Dimension) = locus(grid(dim))
sampling(dim::Dimension) = sampling(grid(dim))

# DimensionalData interface methods
rebuild(dim::D, val, grid=grid(dim), metadata=metadata(dim)) where D <: Dimension =
    constructorof(D)(val, grid, metadata)

dims(x::Dimension) = x
dims(x::DimTuple) = x
name(dim::Dimension) = name(typeof(dim))
shortname(d::Dimension) = shortname(typeof(d))
shortname(d::Type{<:Dimension}) = name(d) # Use `name` as fallback
units(dim::Dimension) = metadata(dim) == nothing ? nothing : get(val(metadata(dim)), :units, nothing)


bounds(dims::DimTuple, lookupdims::Tuple) = bounds(dims[[dimnum(dims, lookupdims)...]]...)
bounds(dims::DimTuple, lookupdim::DimOrDimType) = bounds(dims[dimnum(dims, lookupdim)])
bounds(dims::DimTuple) = (bounds(dims[1]), bounds(tail(dims))...)
bounds(dims::Tuple{}) = ()
bounds(dim::Dimension) = bounds(grid(dim), dim)


# TODO bounds for irregular grids


# Base methods
Base.eltype(dim::Type{<:Dimension{T}}) where T = T
Base.eltype(dim::Type{<:Dimension{A}}) where A<:AbstractArray{T} where T = T
Base.size(dim::Dimension) = size(val(dim))
Base.length(dim::Dimension) = length(val(dim))
Base.ndims(dim::Dimension) = 0
Base.ndims(dim::Dimension{<:AbstractArray}) = ndims(val(dim))
Base.getindex(dim::Dimension) = val(dim)
Base.getindex(dim::Dimension{<:AbstractArray}, I...) = getindex(val(dim), I...)
Base.iterate(dim::Dimension{<:AbstractArray}, args...) = iterate(val(dim), args...)
Base.first(dim::Dimension) = val(dim)
Base.last(dim::Dimension) = val(dim)
Base.first(dim::Dimension{<:AbstractArray}) = first(val(dim))
Base.last(dim::Dimension{<:AbstractArray}) = last(val(dim))
Base.firstindex(dim::Dimension{<:AbstractArray}) = firstindex(val(dim))
Base.lastindex(dim::Dimension{<:AbstractArray}) = lastindex(val(dim))
Base.step(dim::Dimension) = step(grid(dim))
Base.Array(dim::Dimension{<:AbstractArray}) = Array(val(dim))
Base.:(==)(dim1::Dimension, dim2::Dimension) =
    typeof(dim1) == typeof(dim2) &&
    val(dim1) == val(dim2) &&
    grid(dim1) == grid(dim2) &&
    metadata(dim1) == metadata(dim2)

# AbstractArray methods where dims are the dispatch argument

@inline rebuildsliced(A, data, I, name::String=name(A)) =
    rebuild(A, data, slicedims(A, I)..., name)

Base.@propagate_inbounds Base.getindex(A::AbstractArray, dim::Dimension, dims::Vararg{<:Dimension}) =
    getindex(A, dims2indices(A, (dim, dims...))...)

Base.@propagate_inbounds Base.setindex!(A::AbstractArray, x, dim::Dimension, dims::Vararg{<:Dimension}) =
    setindex!(A, x, dims2indices(A, (dim, dims...))...)

Base.@propagate_inbounds Base.view(A::AbstractArray, dim::Dimension, dims::Vararg{<:Dimension}) =
    view(A, dims2indices(A, (dim, dims...))...)

@inline Base.axes(A::AbstractArray, dims::DimOrDimType) = axes(A, dimnum(A, dims))
@inline Base.size(A::AbstractArray, dims::DimOrDimType) = size(A, dimnum(A, dims))


"""
Dimensions with user-set type paremeters
"""
abstract type ParametricDimension{X,T,G,M} <: Dimension{T,G,M} end

"""
A generic dimension. For use when custom dims are required when loading
data from a file. The sintax is ugly and verbose to use for indexing,
ie `Dim{:lat}(1:9)` rather than `Lat(1:9)`. This is the main reason
they are not the only type of dimension availabile.
"""
struct Dim{X,T,G,M} <: ParametricDimension{X,T,G,M}
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
struct EmptyDim <: Dimension{Int,NoGrid,Nothing} end

val(::EmptyDim) = 1:1
grid(::EmptyDim) = NoGrid()
metadata(::EmptyDim) = nothing
name(::EmptyDim) = "Empty"

"""
    @dim typ [supertype=Dimension] [name=string(typ)] [shortname=string(typ)]

Macro to easily define specific dimensions.

Example:
```julia
@dim Lat "Lattitude" "lat"
@dim Lon XDim "Longitude"
```
"""
macro dim end

macro dim(typ::Symbol, args...)
    dimmacro(typ::Symbol, :Dimension, args...)
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
@doc "Z dimension. `Z <: ZDim <: Dimension" Z

@dim Ti TimeDim "Time"
@doc """
Time dimension. `Ti <: TimeDim <: IndependentDim 

`Time` is already used by Dates, so we use `Ti` to avoid clashing.
""" Ti

const Time = Ti # For some backwards compat
