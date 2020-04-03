
"""
Parent type for all dimensional arrays.
"""
abstract type AbstractDimensionalArray{T,N,D<:Tuple,A} <: AbstractArray{T,N} end

const AbDimArray = AbstractDimensionalArray

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
metadata(A::AbstractDimensionalArray, dim) = metadata(dims(A, dim))
metadata(A::AbstractDimensionalArray, dims::Tuple) =
    map(metadata, DimensionalData.dims(A, dims))

dims(A::AbDimArray) = A.dims
@inline rebuild(A::AbstractArray, data, dims::Tuple=dims(A), refdims=refdims(A),
                name=name(A), metadata=metadata(A)) =
    rebuild(A, data, dims, refdims, name, metadata)
# Rebuild for name-updating methods, to avoid having to add dims and refdims
@inline rebuild(A::AbstractArray, data, name::AbstractString) =
    rebuild(A, data, dims(A), refdims(A), name, metadata)

# Array interface methods ######################################################

Base.size(A::AbDimArray) = size(data(A))
Base.axes(A::AbDimArray) = axes(data(A))
Base.iterate(A::AbDimArray, args...) = iterate(data(A), args...)
Base.IndexStyle(A::AbstractDimensionalArray) = Base.IndexStyle(data(A))

Base.@propagate_inbounds Base.getindex(A::AbDimArray{<:Any, N}, I::Vararg{<:Integer, N}) where N =
    getindex(data(A), I...)
Base.@propagate_inbounds Base.getindex(A::AbDimArray, I::Vararg{<:StandardIndices}) =
    rebuildsliced(A, getindex(data(A), I...), I)

# Linear indexing
Base.@propagate_inbounds Base.getindex(A::AbDimArray{<:Any, N} where N, I::StandardIndices) =
    getindex(data(A), I)
# Exempt 1D DimArrays
Base.@propagate_inbounds Base.getindex(A::AbDimArray{<:Any, 1}, I::Union{Colon, AbstractArray}) =
    rebuildsliced(A, getindex(data(A), I), (I,))

Base.@propagate_inbounds Base.view(A::AbDimArray, I::Vararg{<:StandardIndices}) =
    rebuildsliced(A, view(data(A), I...), I)
Base.@propagate_inbounds Base.view(A::AbDimArray{<:Any, 1}, I::StandardIndices) =
    rebuildsliced(A, view(data(A), I), (I,))
Base.@propagate_inbounds Base.view(A::AbDimArray{<:Any, N} where N, I::StandardIndices) =
    view(data(A), I)

Base.@propagate_inbounds Base.setindex!(A::AbDimArray, x, I::Vararg{StandardIndices}) =
    setindex!(data(A), x, I...)

Base.copy(A::AbDimArray) = rebuild(A, copy(data(A)))
Base.copy!(dst::AbDimArray, src::AbDimArray) = copy!(data(dst), data(src))
Base.copy!(dst::AbDimArray, src::AbstractArray) = copy!(data(dst), src)
Base.copy!(dst::AbstractArray, src::AbDimArray) = copy!(dst, data(src))
Base.Array(A::AbDimArray) = data(A)

# Need to cover a few type signatures to avoid ambiguity with base
# Don't remove these even though they look redundant Base.similar(A::AbDimArray) = rebuild(A, similar(data(A)), "")
Base.similar(A::AbDimArray, ::Type{T}) where T = rebuild(A, similar(data(A), T), "")
# If the shape changes, use the wrapped array:
Base.similar(A::AbDimArray, ::Type{T}, I::Tuple{Int,Vararg{Int}}) where T = similar(data(A), T, I)
Base.similar(A::AbDimArray, ::Type{T}, i::Integer, I::Vararg{<:Integer}) where T = similar(data(A), T, i, I...)


# Concrete implementation ######################################################

"""
    DimensionalArray(data, dims, refdims, name)

The main subtype of `AbstractDimensionalArray`.
Maintains and updates its dimensions through transformations and moves dimensions to
`refdims` after reducing operations (like e.g. `mean`).
"""
struct DimensionalArray{T,N,D<:Tuple,R<:Tuple,A<:AbstractArray{T,N},Na<:AbstractString,Me} <: AbstractDimensionalArray{T,N,D,A}
    data::A
    dims::D
    refdims::R
    name::Na
    metadata::Me
    function DimensionalArray(data::A, dims::D, refdims::R, name::Na, metadata::Me
                             ) where {D,R,A<:AbstractArray{T,N},Na,Me} where {T,N}
        map(dims, size(data)) do d, s
            if !(val(d) isa Colon) && length(d) != s
                throw(DimensionMismatch(
                    "dims must have same size as data. This was not true for $dims and size $(size(data)) $(A)."
                ))
            end
        end
        new{T,N,D,R,A,Na,Me}(data, dims, refdims, name, metadata)
    end
end
"""
    DimensionalArray(data, dims::Tuple [, name::String]; refdims=(), metadata=nothing)

Constructor with optional `name`, and keyword `refdims` and `metadata`.

Example:
```julia
using Dates, DimensionalData

ti = (Ti(DateTime(2001):Month(1):DateTime(2001,12)),
x = X(10:10:100))
A = DimensionalArray(rand(12,10), (ti, x), "example")

julia> A[X(Near([12, 35])), Ti(At(DateTime(2001,5)))];

julia> A[Near(DateTime(2001, 5, 4)), Between(20, 50)];
```
"""
DimensionalArray(A::AbstractArray, dims, name::String=""; refdims=(), metadata=nothing) =
    DimensionalArray(A, formatdims(A, _to_tuple(dims)), refdims, name, metadata)
_to_tuple(t::T where T <: Tuple) = t
_to_tuple(t) = tuple(t)

# Getters
refdims(A::DimensionalArray) = A.refdims
data(A::DimensionalArray) = A.data
name(A::DimensionalArray) = A.name
metadata(A::DimensionalArray) = A.metadata
label(A::DimensionalArray) = name(A)

# AbstractDimensionalArray interface
@inline rebuild(A::DimensionalArray, data::AbstractArray, dims::Tuple,
                refdims::Tuple, name::AbstractString, metadata) =
    DimensionalArray(data, dims, refdims, name, metadata)

# Array interface (AbstractDimensionalArray takes care of everything else)
Base.@propagate_inbounds Base.setindex!(A::DimensionalArray, x, I::Vararg{StandardIndices}) =
    setindex!(data(A), x, I...)

"""
    DimensionalArray(f::Function, dim::Dimension [, name])

Apply function `f` across the values of the dimension `dim`
(using `broadcast`), and return the result as a dimensional array with
the given dimension. Optionally provide a name for the result.
"""
DimensionalArray(f::Function, dim::Dimension, name=string(nameof(f), "(", name(dim), ")")) =
     DimensionalArray(f.(val(dim)), (dim,), name)

