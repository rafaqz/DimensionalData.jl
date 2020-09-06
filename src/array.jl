
"""
Supertype for all "dim" arrays.

These arrays return a [`Tuple`](@ref) of [`Dimension`](@ref)
from a [`dims`](@ref) method, and can be rebuilt using [`rebuild`](@ref).

`parent` must return the source array.

They should have [`metadata`](@ref), [`name`](@ref) and [`refdims`](@ref)
methods, although these are optional.

A [`rebuild`](@ref) method for `AbstractDimArray` must accept
`data`, `dims`, `refdims`, `name`, `metadata` arguments.

Indexing AbstractDimArray with non-range `AbstractArray` has undefined effects 
on the `Dimension` index. Use forward-ordered arrays only"
"""
abstract type AbstractDimArray{T,N,D<:Tuple,A} <: AbstractArray{T,N} end

const AbstractDimVector = AbstractDimArray{T,1} where T
const AbstractDimMatrix = AbstractDimArray{T,2} where T

const StandardIndices = Union{AbstractArray,Colon,Integer}



# DimensionalData.jl interface methods ############################################################

# Standard fields

dims(A::AbstractDimArray) = A.dims
refdims(A::AbstractDimArray) = A.refdims
data(A::AbstractDimArray) = A.data
name(A::AbstractDimArray) = A.name
metadata(A::AbstractDimArray) = A.metadata
label(A::AbstractDimArray) = name(A)


"""
    rebuild(A::AbstractDimArray, data, dims=dims(A), refdims=refdims(A),
            name=name(A), metadata=metadata(A)) => AbstractDimArray

Rebuild and `AbstractDimArray` with some field changes. All types
that inherit from `AbstractDimArray` must define this method if they
have any additional fields or alternate field order.

They can discard arguments like `refdims`, `name` and `metadata`.

This method can also be used with keyword arguments in place of regular arguments.
"""
@inline rebuild(A::AbstractDimArray, data, dims::Tuple=dims(A), refdims=refdims(A),
                name=name(A), metadata=metadata(A)) =
    rebuild(A, data, dims, refdims, name, metadata)

# Dipatch on Tuple of Dimension, and map
for func in (:index, :mode, :metadata, :sampling, :span, :bounds, :locus, :order)
    @eval ($func)(A::AbstractDimArray, args...) = ($func)(dims(A), args...)
end

order(ot::Type{<:SubOrder}, A::AbstractDimArray, args...) = 
    order(ot, dims(A), args...)


# Array interface methods ######################################################

Base.size(A::AbstractDimArray) = size(parent(A))
Base.axes(A::AbstractDimArray) = axes(parent(A))
Base.iterate(A::AbstractDimArray, args...) = iterate(parent(A), args...)
Base.IndexStyle(A::AbstractDimArray) = Base.IndexStyle(parent(A))
Base.parent(A::AbstractDimArray) = data(A)
Base.vec(A::AbstractDimArray) = vec(parent(A))

@inline Base.axes(A::AbstractDimArray, dims::DimOrDimType) = axes(A, dimnum(A, dims))
@inline Base.size(A::AbstractDimArray, dims::DimOrDimType) = size(A, dimnum(A, dims))

@inline rebuildsliced(A, data, I, name::String=name(A)) =
    rebuild(A, data, slicedims(A, I)..., name)


# getindex/view/setindex! ======================================================

# Standard indices
Base.@propagate_inbounds Base.getindex(A::AbstractDimArray, i::Integer, I::Integer...) =
    getindex(parent(A), i, I...)
Base.@propagate_inbounds Base.getindex(A::AbstractDimArray, i::StandardIndices, I::StandardIndices...) =
    rebuildsliced(A, getindex(parent(A), i, I...), (i, I...))
Base.@propagate_inbounds Base.view(A::AbstractDimArray, i::StandardIndices, I::StandardIndices...) =
    rebuildsliced(A, view(parent(A), i, I...), (i, I...))
Base.@propagate_inbounds Base.setindex!(A::AbstractDimArray, x, i::StandardIndices, I::StandardIndices...) =
    setindex!(parent(A), x, i, I...)

# No indices
Base.@propagate_inbounds Base.getindex(A::AbstractDimArray) = getindex(parent(A))
Base.@propagate_inbounds Base.view(A::AbstractDimArray) = view(parent(A))
Base.@propagate_inbounds Base.setindex!(A::AbstractDimArray, x) = setindex!(parent(A), x)

# Cartesian indices
Base.@propagate_inbounds Base.getindex(A::AbstractDimArray, I::CartesianIndex) =
    getindex(parent(A), I)
Base.@propagate_inbounds Base.view(A::AbstractDimArray, I::CartesianIndex) =
    view(parent(A), I)
Base.@propagate_inbounds Base.setindex!(A::AbstractDimArray, x, I::CartesianIndex) =
    setindex!(parent(A), x, I)

# Dimension indexing. Additional methods for dispatch ambiguity
Base.@propagate_inbounds Base.getindex(A::AbstractDimArray, dim::Dimension, dims::Dimension...) =
    getindex(A, dims2indices(A, (dim, dims...))...)
Base.@propagate_inbounds Base.getindex(A::AbstractArray, dim::Dimension, dims::Dimension...) =
    getindex(A, dims2indices(A, (dim, dims...))...)
Base.@propagate_inbounds Base.view(A::AbstractDimArray, dim::Dimension, dims::Dimension...) =
    view(A, dims2indices(A, (dim, dims...))...)
Base.@propagate_inbounds Base.view(A::AbstractArray, dim::Dimension, dims::Dimension...) =
    view(A, dims2indices(A, (dim, dims...))...)
Base.@propagate_inbounds Base.setindex!(A::AbstractDimArray, x, dim::Dimension, dims::Dimension...) =
    setindex!(A, x, dims2indices(A, (dim, dims...))...)
Base.@propagate_inbounds Base.setindex!(A::AbstractArray, x, dim::Dimension, dims::Dimension...) =
    setindex!(A, x, dims2indices(A, (dim, dims...))...)

# Symbol keyword-argument indexing. This allows indexing with A[somedim=25.0] for Dim{:somedim}
Base.@propagate_inbounds Base.getindex(A::AbstractDimArray, args::Dimension...; kwargs...) =
    getindex(A, args..., _kwargdims(kwargs.data)...)
Base.@propagate_inbounds Base.view(A::AbstractDimArray, args::Dimension...; kwargs...) =
    view(A, args..., _kwargdims(kwargs.data)...)
Base.@propagate_inbounds Base.setindex!(A::AbstractDimArray, x, args::Dimension...; kwargs...) =
    setindex!(A, x, args..., _kwargdims(kwargs)...)

# Selector indexing without dim wrappers. Must be in the right order!
Base.@propagate_inbounds Base.getindex(A::AbstractDimArray, i, I...) =
    getindex(A, sel2indices(A, maybeselector(i, I...))...)
Base.@propagate_inbounds Base.view(A::AbstractDimArray, i, I...) =
    view(A, sel2indices(A, maybeselector(i, I...))...)
Base.@propagate_inbounds Base.setindex!(A::AbstractDimArray, x, i, I...) =
    setindex!(A, x, sel2indices(A, maybeselector(i, I...))...)

# Linear indexing returns Array
Base.@propagate_inbounds Base.getindex(A::AbstractDimArray{<:Any, N} where N, i::Union{Colon,AbstractArray}) =
    getindex(parent(A), i)
# Exempt 1D DimArrays
Base.@propagate_inbounds Base.getindex(A::AbstractDimArray{<:Any, 1}, i::Union{Colon,AbstractArray}) =
    rebuildsliced(A, getindex(parent(A), i), (i,))

# Linear indexing returns unwrapped SubArray
Base.@propagate_inbounds Base.view(A::AbstractDimArray{<:Any, N} where N, i::StandardIndices) =
    view(parent(A), i)
# Exempt 1D DimArrays
Base.@propagate_inbounds Base.view(A::AbstractDimArray{<:Any, 1}, i::StandardIndices) =
    rebuildsliced(A, view(parent(A), i), (i,))


# Methods that create copies of an AbstractDimArray #######################################

# Similar

# Need to cover a few type signatures to avoid ambiguity with base
Base.similar(A::AbstractDimArray) =
    rebuild(A, similar(parent(A)), dims(A), refdims(A), "")
Base.similar(A::AbstractDimArray, ::Type{T}) where T =
    rebuild(A, similar(parent(A), T), dims(A), refdims(A), "")
# If the shape changes, use the wrapped array:
Base.similar(A::AbstractDimArray, ::Type{T}, I::Tuple{Int,Vararg{Int}}) where T =
    similar(parent(A), T, I)
Base.similar(A::AbstractDimArray, ::Type{T}, i::Integer, I::Vararg{<:Integer}) where T =
    similar(parent(A), T, i, I...)


# Copy

for func in (:copy, :one, :oneunit, :zero)
    @eval begin
        (Base.$func)(A::AbstractDimArray) = rebuild(A, ($func)(parent(A)))
    end
end

Base.Array(A::AbstractDimArray) = Array(parent(A))

Base.copy!(dst::AbstractDimArray{T,N}, src::AbstractDimArray{T,N}) where {T,N} = copy!(parent(dst), parent(src))
Base.copy!(dst::AbstractDimArray{T,N}, src::AbstractArray{T,N}) where {T,N} = copy!(parent(dst), src)
Base.copy!(dst::AbstractArray{T,N}, src::AbstractDimArray{T,N}) where {T,N}  = copy!(dst, parent(src))
# Most of these methods are for resolving ambiguity errors
Base.copy!(dst::SparseArrays.SparseVector, src::AbstractDimArray{T,1}) where T = copy!(dst, parent(src))
Base.copy!(dst::AbstractDimArray{T,1}, src::AbstractArray{T,1}) where T = copy!(parent(dst), src)
Base.copy!(dst::AbstractArray{T,1}, src::AbstractDimArray{T,1}) where T = copy!(dst, parent(src))
Base.copy!(dst::AbstractDimArray{T,1}, src::AbstractDimArray{T,1}) where T = copy!(parent(dst), parent(src))


# Concrete implementation ######################################################

"""
    DimArray(data, dims, refdims, name)
    DimArray(data, dims::Tuple [, name::String]; refdims=(), metadata=nothing)

The main concrete subtype of [`AbstractDimArray`](@ref).

`DimArray` maintains and updates its `Dimension`s through transformations and 
moves dimensions to reference dimension `refdims` after reducing operations 
(like e.g. `mean`).

## Arguments/Fields

- `data`: An `AbstractArray`.
- `dims`: A `Tuple` of `Dimension`
- `name`: A string name for the array. Shows in plots and tables.
- `refdims`: refence dimensions. Usually set programmatically to track past 
  slices and reductions of dimension for labelling and reconstruction.
- `metadata`: Array metadata, or `nothing`

Indexing can be done with all regular indices, or with [`Dimension`](@ref)s 
and/or [`Selector`](@ref)s. Indexing AbstractDimArray with non-range `AbstractArray` 
has undefined effects on the `Dimension` index. Use forward-ordered arrays only"

Example:

```julia
using Dates, DimensionalData

ti = (Ti(DateTime(2001):Month(1):DateTime(2001,12)),
x = X(10:10:100))
A = DimArray(rand(12,10), (ti, x), "example")

julia> A[X(Near([12, 35])), Ti(At(DateTime(2001,5)))];

julia> A[Near(DateTime(2001, 5, 4)), Between(20, 50)];
```
"""
struct DimArray{T,N,D<:Tuple,R<:Tuple,A<:AbstractArray{T,N},Na<:AbstractString,Me} <: AbstractDimArray{T,N,D,A}
    data::A
    dims::D
    refdims::R
    name::Na
    metadata::Me
end
DimArray(A::AbstractArray, dims, name::String=""; refdims=(), metadata=nothing) =
    DimArray(A, formatdims(A, dims), refdims, name, metadata)
DimArray(A::AbstractDimArray; dims=dims(A), refdims=refdims(A), name=name(A), metadata=metadata(A)) =
    DimArray(A, formatdims(parent(A), dims), refdims, name, metadata)
DimArray(; data, dims, refdims=(), name="", metadata=nothing) =
    DimArray(A, formatdims(A, dims), refdims, name, metadata)

"""
    rebuild(A::DimArray, data::AbstractArray, dims::Tuple,
            refdims::Tuple, name::AbstractString, metadata) => DimArray

Rebuild a `DimArray` with new fields. Handling partial field
update is dealth with in `rebuild` for `AbstractDimArray`.
"""
@inline rebuild(A::DimArray, data::AbstractArray, dims::Tuple,
                refdims::Tuple, name::AbstractString, metadata) =
    DimArray(data, dims, refdims, name, metadata)

# Array interface (AbstractDimArray takes care of everything else)
Base.@propagate_inbounds Base.setindex!(A::DimArray, x, I::Vararg{StandardIndices}) =
    setindex!(parent(A), x, I...)

"""
    DimArray(f::Function, dim::Dimension [, name])

Apply function `f` across the values of the dimension `dim`
(using `broadcast`), and return the result as a dimensional array with
the given dimension. Optionally provide a name for the result.
"""
DimArray(f::Function, dim::Dimension, name=string(nameof(f), "(", name(dim), ")")) =
     DimArray(f.(val(dim)), (dim,), name)


"""
    Base.fill(x::T, dims::Vararg{Dimension,N}}) => DimArray{T,N}
    Base.fill(x::T, dims::Tuple{Vararg{Dimension,N}}) => DimArray{T,N}

Create a [`DimArray`](@ref) from a fill value `x` and `Dimension`s.

A `Dimension` with an `AbstractVector` value will set the array axis

A `Dimension` holding an `Integer` will set the length
of the Array axis, and set the dimension mode to [`NoIndex`](@ref).
"""
Base.fill(x, dim1::Dimension, dims::Dimension...) = fill(x, (dim1, dims...))
Base.fill(x, dims::Tuple{<:Dimension,Vararg{<:Dimension}}) = begin
    dims = map(_intdim2rangedim, dims)
    DimArray(fill(x, map(length, dims)), dims)
end

_intdim2rangedim(dim::Dimension{<:Integer}) =  begin
    mode_ = mode(dim) isa AutoMode ? NoIndex() : mode(dim)
    basetypeof(dim)(Base.OneTo(val(dim)), mode_, metadata(dim))
end
_intdim2rangedim(dim::Dimension{<:AbstractArray}) = dim
_intdim2rangedim(dim::Dimension) =
    error("dim $(basetypeof(dim)) must hold an Integer or an AbstractArray. Has $(val(dim))")
