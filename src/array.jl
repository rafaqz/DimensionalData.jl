
"""
Parent type for all dimensional arrays.
"""
abstract type AbstractDimArray{T,N,D<:Tuple,A} <: AbstractArray{T,N} end

const AbstractDimVector = AbstractDimArray{T,1} where T
const AbstractDimMatrix = AbstractDimArray{T,2} where T

const StandardIndices = Union{AbstractArray,Colon,Integer}

# Interface methods ############################################################

"""
    bounds(A::AbstractArray)

Returns a tuple of bounds for each array axis.
"""
bounds(A::AbstractArray) = bounds(dims(A))
"""
    bounds(A::AbstractArray, dims)

Returns the bounds for the specified dimension(s).
`dims` can be a `Dimension`, a dimension type, or a tuple of either.
"""
bounds(A::AbstractArray, dims::DimOrDimType) =
    bounds(DimensionalData.dims(A), dims)

"""
    metadata(A::AbstractArray, dims)

Returns the bounds for the specified dimension(s).
`dims` can be a `Dimension`, a dimension type, or a tuple of either.
"""
metadata(A::AbstractDimArray, dim) = metadata(dims(A, dim))
metadata(A::AbstractDimArray, dims::Tuple) =
    map(metadata, DimensionalData.dims(A, dims))

# Standard fields

dims(A::AbstractDimArray) = A.dims
refdims(A::AbstractDimArray) = A.refdims
data(A::AbstractDimArray) = A.data
name(A::AbstractDimArray) = A.name
metadata(A::AbstractDimArray) = A.metadata
label(A::AbstractDimArray) = name(A)

@inline rebuild(A::AbstractArray, data, dims::Tuple=dims(A), refdims=refdims(A),
                name=name(A), metadata=metadata(A)) =
    rebuild(A, data, dims, refdims, name, metadata)

order(A::AbstractDimArray, args...) = order(dims(A, args...))
arrayorder(A::AbstractDimArray, args...) = arrayorder(dims(A, args...))
indexorder(A::AbstractDimArray, args...) = indexorder(dims(A, args...))
   

# Array interface methods ######################################################

Base.size(A::AbstractDimArray) = size(data(A))
Base.axes(A::AbstractDimArray) = axes(data(A))
Base.iterate(A::AbstractDimArray, args...) = iterate(data(A), args...)
Base.IndexStyle(A::AbstractDimArray) = Base.IndexStyle(data(A))
Base.parent(A::AbstractDimArray) = data(A)

@inline Base.axes(A::AbstractDimArray, dims::DimOrDimType) = axes(A, dimnum(A, dims))
@inline Base.size(A::AbstractDimArray, dims::DimOrDimType) = size(A, dimnum(A, dims))

@inline rebuildsliced(A, data, I, name::String=name(A)) =
    rebuild(A, data, slicedims(A, I)..., name)

# Standard indices
Base.@propagate_inbounds Base.getindex(A::AbstractDimArray, i::Integer, I::Integer...) =
    getindex(data(A), i, I...)
Base.@propagate_inbounds Base.getindex(A::AbstractDimArray, i::StandardIndices, I::StandardIndices...) =
    rebuildsliced(A, getindex(data(A), i, I...), (i, I...))
Base.@propagate_inbounds Base.view(A::AbstractDimArray, i::StandardIndices, I::StandardIndices...) =
    rebuildsliced(A, view(data(A), i, I...), (i, I...))
Base.@propagate_inbounds Base.setindex!(A::AbstractDimArray, x, i::StandardIndices, I::StandardIndices...) =
    setindex!(data(A), x, i, I...)

# No indices
Base.@propagate_inbounds Base.getindex(A::AbstractDimArray) = getindex(data(A))
Base.@propagate_inbounds Base.view(A::AbstractDimArray) = view(data(A))
Base.@propagate_inbounds Base.setindex!(A::AbstractDimArray, x) = setindex!(data(A), x)

# Cartesian indices
Base.@propagate_inbounds Base.getindex(A::AbstractDimArray, I::CartesianIndex) =
    getindex(data(A), I)
Base.@propagate_inbounds Base.view(A::AbstractDimArray, I::CartesianIndex) =
    view(data(A), I)
Base.@propagate_inbounds Base.setindex!(A::AbstractDimArray, x, I::CartesianIndex) =
    setindex!(data(A), x, I)

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

# Symbol indexing. This allows indexing with A[somedim=25.0] for Dim{:somedim}
Base.@propagate_inbounds Base.getindex(A::AbstractDimArray, args::Dimension...; kwargs...) =
    getindex(A, args..., map((key, val) -> Dim{key}(val), keys(kwargs), values(kwargs))...)

# Selector indexing without dim wrappers. Must be in the right order!
Base.@propagate_inbounds Base.getindex(A::AbstractDimArray, i, I...) =
    getindex(A, sel2indices(A, maybeselector(i, I...))...)
Base.@propagate_inbounds Base.view(A::AbstractDimArray, i, I...) =
    view(A, sel2indices(A, maybeselector(i, I...))...)
Base.@propagate_inbounds Base.setindex!(A::AbstractDimArray, x, i, I...) =
    setindex!(A, x, sel2indices(A, maybeselector(i, I...))...)

# Linear indexing returns Array
Base.@propagate_inbounds Base.getindex(A::AbstractDimArray{<:Any, N} where N, i::Union{Colon,AbstractArray}) =
    getindex(data(A), i)
# Exempt 1D DimArrays
Base.@propagate_inbounds Base.getindex(A::AbstractDimArray{<:Any, 1}, i::Union{Colon,AbstractArray}) =
    rebuildsliced(A, getindex(data(A), i), (i,))

# Linear indexing returns unwrapped SubArray
Base.@propagate_inbounds Base.view(A::AbstractDimArray{<:Any, N} where N, i::StandardIndices) =
    view(data(A), i)
# Exempt 1D DimArrays
Base.@propagate_inbounds Base.view(A::AbstractDimArray{<:Any, 1}, i::StandardIndices) =
    rebuildsliced(A, view(data(A), i), (i,))

Base.copy(A::AbstractDimArray) = rebuild(A, copy(data(A)))


Base.copy!(dst::AbstractDimArray{T,N}, src::AbstractDimArray{T,N}) where {T,N} = copy!(parent(dst), parent(src))
Base.copy!(dst::AbstractDimArray{T,N}, src::AbstractArray{T,N}) where {T,N} = copy!(parent(dst), src)
Base.copy!(dst::AbstractArray{T,N}, src::AbstractDimArray{T,N}) where {T,N}  = copy!(dst, parent(src))
# Most of these methods are for resolving ambiguity errors
Base.copy!(dst::SparseArrays.SparseVector, src::AbstractDimArray{T,1}) where T = copy!(dst, parent(src))
Base.copy!(dst::AbstractDimArray{T,1}, src::AbstractArray{T,1}) where T = copy!(parent(dst), src)
Base.copy!(dst::AbstractArray{T,1}, src::AbstractDimArray{T,1}) where T = copy!(dst, parent(src))
Base.copy!(dst::AbstractDimArray{T,1}, src::AbstractDimArray{T,1}) where T = copy!(parent(dst), parent(src))

Base.Array(A::AbstractDimArray) = data(A)

# Need to cover a few type signatures to avoid ambiguity with base
# Don't remove these even though they look redundant 
Base.similar(A::AbstractDimArray) = 
    rebuild(A, similar(data(A)), dims(A), refdims(A), "")
Base.similar(A::AbstractDimArray, ::Type{T}) where T = 
    rebuild(A, similar(data(A), T), dims(A), refdims(A), "")
# If the shape changes, use the wrapped array:
Base.similar(A::AbstractDimArray, ::Type{T}, I::Tuple{Int,Vararg{Int}}) where T = 
    similar(data(A), T, I)
Base.similar(A::AbstractDimArray, ::Type{T}, i::Integer, I::Vararg{<:Integer}) where T = 
    similar(data(A), T, i, I...)



# Concrete implementation ######################################################

"""
    DimArray(data, dims, refdims, name)

The main subtype of `AbstractDimArray`.
Maintains and updates its dimensions through transformations and moves dimensions to
`refdims` after reducing operations (like e.g. `mean`).
"""
struct DimArray{T,N,D<:Tuple,R<:Tuple,A<:AbstractArray{T,N},Na<:AbstractString,Me} <: AbstractDimArray{T,N,D,A}
    data::A
    dims::D
    refdims::R
    name::Na
    metadata::Me
end

const DimArray = DimArray


"""
    DimArray(data, dims::Tuple [, name::String]; refdims=(), metadata=nothing)

Constructor with optional `name`, and keyword `refdims` and `metadata`.

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
DimArray(A::AbstractArray, dims, name::String=""; refdims=(), metadata=nothing) =
    DimArray(A, formatdims(A, dims), refdims, name, metadata)
DimArray(A::AbstractDimArray; dims=dims(A), refdims=refdims(A), name=name(A), metadata=metadata(A)) =
    DimArray(A, formatdims(data(A), dims), refdims, name, metadata)
DimArray(; data, dims, refdims=(), name="", metadata=nothing) = 
    DimArray(A, formatdims(A, dims), refdims, name, metadata)

# AbstractDimArray interface
@inline rebuild(A::DimArray, data::AbstractArray, dims::Tuple,
                refdims::Tuple, name::AbstractString, metadata) =
    DimArray(data, dims, refdims, name, metadata)

# Array interface (AbstractDimArray takes care of everything else)
Base.@propagate_inbounds Base.setindex!(A::DimArray, x, I::Vararg{StandardIndices}) =
    setindex!(data(A), x, I...)

"""
    DimArray(f::Function, dim::Dimension [, name])

Apply function `f` across the values of the dimension `dim`
(using `broadcast`), and return the result as a dimensional array with
the given dimension. Optionally provide a name for the result.
"""
DimArray(f::Function, dim::Dimension, name=string(nameof(f), "(", name(dim), ")")) =
     DimArray(f.(val(dim)), (dim,), name)

