"""
    AbstracDimArray <: AbstractArray

Abstract supertype for all "dim" arrays.

These arrays return a `Tuple` of [`Dimension`](@ref)
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

const StandardIndices = Union{AbstractArray{<:Integer},Colon,Integer}

# DimensionalData.jl interface methods ####################################################

# Standard fields
dims(A::AbstractDimArray) = A.dims
refdims(A::AbstractDimArray) = A.refdims
data(A::AbstractDimArray) = A.data
name(A::AbstractDimArray) = A.name
metadata(A::AbstractDimArray) = A.metadata

"""
    rebuild(A::AbstractDimArray, data, [dims, refdims, name, metadata]) => AbstractDimArray
    rebuild(A::AbstractDimArray; kw...) => AbstractDimArray

Rebuild and `AbstractDimArray` with some field changes. All types
that inherit from `AbstractDimArray` must define this method if they
have any additional fields or alternate field order.

Implementations can discard arguments like `refdims`, `name` and `metadata`.

This method can also be used with keyword arguments in place of regular arguments.
"""
@inline function rebuild(
    A::AbstractDimArray, data, dims::Tuple=dims(A), refdims=refdims(A), name=name(A)
)
    rebuild(A, data, dims, refdims, name, metadata(A))
end

@inline rebuildsliced(args...) = rebuildsliced(getindex, args...)
@inline rebuildsliced(f::Function, A, data, I, name=name(A)) = rebuild(A, data, slicedims(f, A, I)..., name)

for func in (:val, :index, :mode, :metadata, :order, :sampling, :span, :bounds, :locus,
             :arrayorder, :indexorder, :relation)
    @eval ($func)(A::AbstractDimArray, args...) = ($func)(dims(A), args...)
end

order(ot::Type{<:SubOrder}, A::AbstractDimArray, args...) = order(ot, dims(A), args...)

# Array interface methods ######################################################

Base.size(A::AbstractDimArray) = size(parent(A))
Base.axes(A::AbstractDimArray) = axes(parent(A))
Base.iterate(A::AbstractDimArray, args...) = iterate(parent(A), args...)
Base.IndexStyle(A::AbstractDimArray) = Base.IndexStyle(parent(A))
Base.parent(A::AbstractDimArray) = data(A)
Base.vec(A::AbstractDimArray) = vec(parent(A))
@inline Base.axes(A::AbstractDimArray, dims::DimOrDimType) = axes(A, dimnum(A, dims))
@inline Base.size(A::AbstractDimArray, dims::DimOrDimType) = size(A, dimnum(A, dims))
# Only compare data and dim - metadata and refdims can be different
Base.:(==)(A1::AbstractDimArray, A2::AbstractDimArray) =
    parent(A1) == parent(A2) && dims(A1) == dims(A2)

# Methods that create copies of an AbstractDimArray #######################################

# Need to cover a few type signatures to avoid ambiguity with base
Base.similar(A::AbstractDimArray) =
    rebuild(A, similar(parent(A)), dims(A), refdims(A), Symbol(""))
Base.similar(A::AbstractDimArray, ::Type{T}) where T =
    rebuild(A, similar(parent(A), T), dims(A), refdims(A), Symbol(""))
# If the shape changes, use the wrapped array:
Base.similar(A::AbstractDimArray, ::Type{T}, I::Tuple{Int,Vararg{Int}}) where T =
    similar(parent(A), T, I)
Base.similar(A::AbstractDimArray, ::Type{T}, i::Integer, I::Vararg{<:Integer}) where T =
    similar(parent(A), T, i, I...)

for func in (:copy, :one, :oneunit, :zero)
    @eval begin
        (Base.$func)(A::AbstractDimArray) = rebuild(A, ($func)(parent(A)))
    end
end

Base.Array(A::AbstractDimArray) = Array(parent(A))

_maybeunwrap(A::AbstractDimArray) = parent(A)
_maybeunwrap(A::AbstractArray) = A

for (d, s) in ((:AbstractDimArray, :AbstractDimArray), 
               (:AbstractDimArray, :AbstractArray), 
               (:AbstractArray, :AbstractDimArray))
    @eval begin
        Base.copy!(dst::$d{T,N}, src::$s{T,N}) where {T,N} = copy!(_maybeunwrap(dst), _maybeunwrap(src))
        Base.copy!(dst::$d{T,1}, src::$s{T,1}) where T = copy!(_maybeunwrap(dst), _maybeunwrap(src))
        Base.copyto!(dst::$d, src::$s) = copyto!(_maybeunwrap(dst), _maybeunwrap(src))
        Base.copyto!(dst::$d, dstart::Integer, src::$s) = 
            copyto!(_maybeunwrap(dst), dstart, _maybeunwrap(src))
        Base.copyto!(dst::$d, dstart::Integer, src::$s, sstart::Integer) = 
            copyto!(_maybeunwrap(dst), dstart, _maybeunwrap(src), sstart)
        Base.copyto!(dst::$d, dstart::Integer, src::$s, sstart::Integer, n::Integer) = 
            copyto!(_maybeunwrap(dst), dstart, _maybeunwrap(src), sstart, n)
        Base.copyto!(dst::$d{T1,N}, Rdst::CartesianIndices{N}, src::$s{T2,N}, Rsrc::CartesianIndices{N}) where {T1,T2,N} =
            copyto!(_maybeunwrap(dst), Rdst, _maybeunwrap(src), Rsrc)        
    end
end
Base.copy!(dst::SparseArrays.SparseVector, src::AbstractDimArray{T,1}) where T = copy!(dst, parent(src))

function Adapt.adapt_structure(to, A::AbstractDimArray) 
    rebuild(A, 
        data=adapt(to, parent(A)),
        dims=adapt(to, dims(A)),
        refdims=adapt(to, refdims(A)),
        name=Name(name(A)),
        metadata=adapt(to, metadata(A)),
    )
end

# Concrete implementation ######################################################

"""
    DimArray <: AbstractDimArray

    DimArray(data, dims, refdims, name)
    DimArray(data, dims::Tuple [, name::Symbol]; refdims=(), metadata=NoMetadata())

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
- `metadata`: Array metadata, or `NoMetadata()`

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
struct DimArray{T,N,D<:Tuple,R<:Tuple,A<:AbstractArray{T,N},Na,Me} <: AbstractDimArray{T,N,D,A}
    data::A
    dims::D
    refdims::R
    name::Na
    metadata::Me
end
# 2 or 3 argument version
function DimArray(data::AbstractArray, dims, name=NoName(); refdims=(), metadata=NoMetadata())
    DimArray(data, formatdims(data, dims), refdims, name, metadata)
end
# All keyword argument version
function DimArray(; data, dims, refdims=(), name=NoName(), metadata=NoMetadata())
    DimArray(data, formatdims(data, dims), refdims, name, metadata)
end
# Construct from another AbstractDimArray
function DimArray(A::AbstractDimArray; 
    data=data(A), dims=dims(A), refdims=refdims(A), name=name(A), metadata=metadata(A)
)
    DimArray(data, formatdims(data, dims), refdims, name, metadata)
end
"""
    DimArray(f::Function, dim::Dimension [, name])

Apply function `f` across the values of the dimension `dim`
(using `broadcast`), and return the result as a dimensional array with
the given dimension. Optionally provide a name for the result.
"""
function DimArray(f::Function, dim::Dimension, name=Symbol(nameof(f), "(", name(dim), ")"))
     DimArray(f.(val(dim)), (dim,), name)
end

"""
    rebuild(A::DimArray, data::AbstractArray, dims::Tuple,
            refdims::Tuple, name::Symbol, metadata) => DimArray

Rebuild a `DimArray` with new fields. Handling partial field
update is dealth with in `rebuild` for `AbstractDimArray`.
"""
@inline function rebuild(
    A::DimArray, data::AbstractArray, dims::Tuple, refdims::Tuple, name, metadata
)
    DimArray(data, dims, refdims, name, metadata)
end


"""
    Base.fill(x::T, dims::Vararg{Dimension,N}}) => DimArray{T,N}
    Base.fill(x::T, dims::Tuple{Vararg{Dimension,N}}) => DimArray{T,N}

Create a [`DimArray`](@ref) from a fill value `x` and `Dimension`s.

A `Dimension` with an `AbstractVector` value will set the array axis

A `Dimension` holding an `Integer` will set the length
of the Array axis, and set the dimension mode to [`NoIndex`](@ref).
"""
Base.fill(x, dim1::Dimension, dims::Dimension...) = fill(x, (dim1, dims...))
function Base.fill(x, dims::DimTuple)
    lengths = map(_dimlen, dims)
    DimArray(fill(x, lengths), map(_indexdim, dims))
end

for f in (:zeros, :ones, :rand)
    @eval begin
        Base.$f(dim1::Dimension, dims::Dimension...) = $f((dim1, dims...))
        Base.$f(dims::DimTuple) = $f(Float64, dims)
        Base.$f(::Type{T}, d1::Dimension, dims::Dimension...) where T = $f(T, (d1, dims...))
        function Base.$f(::Type{T}, dims::DimTuple) where T
            lengths = map(_dimlen, dims)
            DimArray($f(T, lengths), map(_indexdim, dims))
        end
    end
end
function Base.rand(x, d1::Dimension, dims::Dimension...)
    lengths = map(_dimlen, (d1, dims...))
    DimArray(rand(x, lengths), map(_indexdim, (d1, dims...)))
end

_dimlen(dim::Dimension{<:AbstractArray}) = length(dim)
_dimlen(dim::Dimension{<:Integer}) = val(dim)
@noinline _dimlen(dim::Dimension) =
    throw(ArgumentError("$(basetypeof(dim)) must hold an Integer or an AbstractArray, instead holds: $(val(dim))"))

_indexdim(dim::Dimension{<:AbstractArray}) = dim
_indexdim(dim::Dimension{<:Integer}) = basetypeof(dim)(:, NoIndex(), metadata(dim))
