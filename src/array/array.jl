"""
    AbstractDimArray <: AbstractArray

Abstract supertype for all "dim" arrays.

These arrays return a `Tuple` of [`Dimension`](@ref)
from a [`dims`](@ref) method, and can be rebuilt using [`rebuild`](@ref).

`parent` must return the source array.

They should have [`metadata`](@ref), [`name`](@ref) and [`refdims`](@ref)
methods, although these are optional.

A [`rebuild`](@ref) method for `AbstractDimArray` must accept
`data`, `dims`, `refdims`, `name`, `metadata` arguments.

Indexing `AbstractDimArray` with non-range `AbstractArray` has undefined effects
on the `Dimension` index. Use forward-ordered arrays only"
"""
abstract type AbstractDimArray{T,N,D<:Tuple,A} <: AbstractArray{T,N} end

const AbstractDimVector = AbstractDimArray{T,1} where T
const AbstractDimMatrix = AbstractDimArray{T,2} where T


# DimensionalData.jl interface methods ####################################################

# Standard fields
dims(A::AbstractDimArray) = A.dims
refdims(A::AbstractDimArray) = A.refdims
data(A::AbstractDimArray) = A.data
name(A::AbstractDimArray) = A.name
metadata(A::AbstractDimArray) = A.metadata

layerdims(A::AbstractDimArray) = basedims(A)

"""
    rebuild(A::AbstractDimArray, data, [dims, refdims, name, metadata]) => AbstractDimArray
    rebuild(A::AbstractDimArray; kw...) => AbstractDimArray

Rebuild and `AbstractDimArray` with some field changes. All types
that inherit from `AbstractDimArray` must define this method if they
have any additional fields or alternate field order.

Implementations can discard arguments like `refdims`, `name` and `metadata`.

Additional arguments can be added to the keyword argument method. 

For readability it is preferable to use keyword versions for any more than a few arguments.
"""
@inline function rebuild(
    A::AbstractDimArray, data, dims::Tuple=dims(A), refdims=refdims(A), name=name(A)
)
    rebuild(A, data, dims, refdims, name, metadata(A))
end

@inline rebuildsliced(A::AbstractDimArray, args...) = rebuildsliced(getindex, A, args...)
@inline rebuildsliced(f::Function, A::AbstractDimArray, data::AbstractArray, I::Tuple, name=name(A)) =
    rebuild(A, data, slicedims(f, A, I)..., name)

for func in (:val, :index, :lookup, :metadata, :order, :sampling, :span, :locus, :bounds, :intervalbounds)
    @eval ($func)(A::AbstractDimArray, args...) = ($func)(dims(A), args...)
end

Extents.extent(A::AbstractDimArray, args...) = Extents.extent(dims(A), args...) 
 

# Array interface methods ######################################################

Base.size(A::AbstractDimArray) = size(parent(A))
Base.axes(A::AbstractDimArray) = map(Dimensions.DimUnitRange, axes(parent(A)), dims(A))
Base.iterate(A::AbstractDimArray, args...) = iterate(parent(A), args...)
Base.IndexStyle(A::AbstractDimArray) = Base.IndexStyle(parent(A))
Base.parent(A::AbstractDimArray) = data(A)
Base.vec(A::AbstractDimArray) = vec(parent(A))
@inline Base.axes(A::AbstractDimArray, dims::DimOrDimType) = axes(A, dimnum(A, dims))
@inline Base.size(A::AbstractDimArray, dims::DimOrDimType) = size(A, dimnum(A, dims))
# Only compare data and dim - metadata and refdims can be different
Base.:(==)(A1::AbstractDimArray, A2::AbstractDimArray) =
    parent(A1) == parent(A2) && dims(A1) == dims(A2)

const IDim = Dimension{<:StandardIndices}
function Base.checkbounds(::Type{Bool}, A::AbstractDimArray, dims::IDim...)
    Base.checkbounds(Bool, A, dims2indices(A, dims)...)
end
function Base.checkbounds(A::AbstractDimArray, dims::IDim...)
    Base.checkbounds(A, dims2indices(A, dims)...)
end

# undef constructor for Array, using dims 
function Base.Array{T}(x::UndefInitializer, d1::Dimension, dims::Dimension...) where T 
    Base.Array{T}(x, (d1, dims...))
end
Base.Array{T}(x::UndefInitializer, dims::DimTuple; kw...) where T = Array{T}(x, size(dims))

function Base.NamedTuple(A1::AbstractDimArray, As::AbstractDimArray...) 
    arrays = (A1, As...)
    keys = map(Symbol ∘ name, arrays)
    NamedTuple{keys}(arrays)
end

# undef constructor for all AbstractDimArray 
(::Type{A})(x::UndefInitializer, dims::Dimension...; kw...) where {A<:AbstractDimArray{<:Any}} = A(x, dims; kw...)
function (::Type{A})(x::UndefInitializer, dims::DimTuple; kw...) where {A<:AbstractDimArray{T}} where T
    basetypeof(A)(Array{T}(undef, size(dims)), dims; kw...)
end
function (::Type{A})(x::UndefInitializer, dims::Tuple{}; kw...) where {A<:AbstractDimArray{T}} where T
    basetypeof(A)(Array{T}(undef, ()), dims; kw...)
end

# Dummy `read` methods that does nothing.
# This can be used to actually read `AbstractDimArray` subtypes that dont hold in-memory Arrays.
Base.read(A::AbstractDimArray) = A

# Methods that create copies of an AbstractDimArray #######################################

# Need to cover a few type signatures to avoid ambiguity with base
Base.similar(A::AbstractDimArray) =
    rebuild(A; data=similar(parent(A)), dims=dims(A), refdims=refdims(A), name=_noname(A), metadata=metadata(A))
Base.similar(A::AbstractDimArray, ::Type{T}) where T =
    rebuild(A; data=similar(parent(A), T), dims=dims(A), refdims=refdims(A), name=_noname(A), metadata=metadata(A))
# We can't resize the dims or add missing dims, so return the unwraped Array type?
# An alternative would be to fill missing dims with `Anon`, and keep existing
# dims but strip the Lookup? It just seems a little complicated when the methods
# below using DimTuple work better anyway.
Base.similar(A::AbstractDimArray, i::Integer, I::Vararg{Integer}) =
    similar(A, eltype(A), (i, I...))
Base.similar(A::AbstractDimArray, I::Tuple{Int,Vararg{Int}}) = 
    similar(A, eltype(A), I)
Base.similar(A::AbstractDimArray, ::Type{T}, i::Integer, I::Vararg{Integer}) where T =
    similar(A, T, (i, I...))
Base.similar(A::AbstractDimArray, ::Type{T}, I::Tuple{Int,Vararg{Int}}) where T =
    similar(parent(A), T, I)

const MaybeDimUnitRange = Union{Integer,Base.OneTo,Dimensions.DimUnitRange}
# when all axes are DimUnitRanges we can return an `AbstractDimArray`
# This code covers the likely most common cases where at least one DimUnitRange is in the
# first 4 axes of the array being created. If all of the axes are DimUnitRange, then an
# AbstractDimArray is returned. Otherwise an array like the parent array is returned.
# This ensures no ambiguity with each other and Base without type piracy.
for s1 in (:(Dimensions.DimUnitRange), :MaybeDimUnitRange)
    s1 === :MaybeDimUnitRange || @eval begin
        function Base.similar(
            A::AbstractArray, T::Type, shape::Tuple{$s1,Vararg{MaybeDimUnitRange}}
        )
            _similar(A, T, shape)
        end
        function Base.similar(
            T::Type{<:AbstractArray}, shape::Tuple{$s1,Vararg{MaybeDimUnitRange}}
        )
            _similar(T, shape)
        end
    end
    for s2 in (:(Dimensions.DimUnitRange), :MaybeDimUnitRange)
        all(Base.Fix2(===, :MaybeDimUnitRange), (s1, s2)) || @eval begin
            function Base.similar(
                A::AbstractArray, T::Type, shape::Tuple{$s1,$s2,Vararg{MaybeDimUnitRange}}
            )
                _similar(A, T, shape)
            end
            function Base.similar(
                T::Type{<:AbstractArray}, shape::Tuple{$s1,$s2,Vararg{MaybeDimUnitRange}}
            )
                _similar(T, shape)
            end
        end
        for s3 in (:(Dimensions.DimUnitRange), :MaybeDimUnitRange)
            all(Base.Fix2(===, :MaybeDimUnitRange), (s1, s2, s3)) || @eval begin
                function Base.similar(
                    A::AbstractArray, T::Type, shape::Tuple{$s1,$s2,$s3,Vararg{MaybeDimUnitRange}}
                )
                    _similar(A, T, shape)
                end
                function Base.similar(
                    T::Type{<:AbstractArray}, shape::Tuple{$s1,$s2,$s3,Vararg{MaybeDimUnitRange}}
                )
                    _similar(T, shape)
                end        
            end    
            for s4 in (:(Dimensions.DimUnitRange), :MaybeDimUnitRange)
                all(Base.Fix2(===, :MaybeDimUnitRange), (s1, s2, s3, s4)) && continue
                @eval begin
                    function Base.similar(
                        A::AbstractArray, T::Type, shape::Tuple{$s1,$s2,$s3,$s4,Vararg{MaybeDimUnitRange}}
                    )
                        _similar(A, T, shape)
                    end
                    function Base.similar(
                        T::Type{<:AbstractArray}, shape::Tuple{$s1,$s2,$s3,$s4,Vararg{MaybeDimUnitRange}}
                    )
                        _similar(T, shape)
                    end            
                end
            end
        end
    end
end
function _similar(A::AbstractArray, T::Type, shape::Tuple)
    data = similar(parent(A), T, map(_parent_range, shape))
    shape isa Tuple{Vararg{Dimensions.DimUnitRange}} || return data
    C = dimconstructor(dims(shape))
    return C(data, dims(shape))
end
function _similar(::Type{T}, shape::Tuple) where {T<:AbstractArray}
    data = similar(T, map(_parent_range, shape))
    shape isa Tuple{Vararg{Dimensions.DimUnitRange}} || return data
    C = dimconstructor(dims(shape))
    return C(data, dims(shape))
end
_parent_range(r::Dimensions.DimUnitRange) = parent(r)
_parent_range(r) = r
# With Dimensions we can return an `AbstractDimArray`
Base.similar(A::AbstractDimArray, D::DimTuple) = Base.similar(A, eltype(A), D) 
Base.similar(A::AbstractDimArray, D::Dimension...) = Base.similar(A, eltype(A), D) 
Base.similar(A::AbstractDimArray, ::Type{T}, D::Dimension...) where T =
    Base.similar(A, T, D) 
Base.similar(A::AbstractDimArray, ::Type{T}, D::DimTuple) where T =
    rebuild(A; data=similar(parent(A), T, size(D)), dims=D, refdims=(), metadata=NoMetadata())
Base.similar(A::AbstractDimArray, ::Type{T}, D::Tuple{}) where T =
    rebuild(A; data=similar(parent(A), T, ()), dims=(), refdims=(), metadata=NoMetadata())

# Keep the same type in `similar`
_noname(A::AbstractDimArray) = _noname(name(A))
_noname(::NoName) = NoName()
_noname(::Symbol) = Symbol("")
_noname(name::Name) = name # Keep the name so the type doesn't change

for func in (:copy, :one, :oneunit, :zero)
    @eval begin
        (Base.$func)(A::AbstractDimArray; kw...) = rebuild(A; data=($func)(parent(A)), kw...)
    end
end

Base.Array(A::AbstractDimArray) = Array(parent(A))
Base.collect(A::AbstractDimArray) = collect(parent(A))

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
# Ambiguity
@static if VERSION >= v"1.9.0"
    Base.copyto!(dst::AbstractDimArray{T,2}, src::SparseArrays.CHOLMOD.Dense{T}) where T<:Union{Float64,ComplexF64} =
        copyto!(parent(dst), src)
    Base.copyto!(dst::AbstractDimArray{T}, src::SparseArrays.CHOLMOD.Dense{T}) where T<:Union{Float64,ComplexF64} =
        copyto!(parent(dst), src)
    Base.copyto!(dst::DimensionalData.AbstractDimArray, src::SparseArrays.CHOLMOD.Dense) =
        copyto!(parent(dst), src)
    Base.copyto!(dst::SparseArrays.AbstractCompressedVector, src::AbstractDimArray{T, 1} where T) =
        copyto!(dst, parent(src))
    Base.copyto!(dst::AbstractDimArray{T,2} where T, src::SparseArrays.AbstractSparseMatrixCSC) =
        copyto!(parent(dst), src)
    Base.copyto!(dst::AbstractDimArray{T,2} where T, src::LinearAlgebra.AbstractQ) =
        copyto!(parent(dst), src)
    function Base.copyto!(
        dst::AbstractDimArray{<:Any,2}, 
        dst_i::CartesianIndices{2, R} where R<:Tuple{OrdinalRange{Int64, Int64}, OrdinalRange{Int64, Int64}}, 
        src::SparseArrays.AbstractSparseMatrixCSC{<:Any}, 
        src_i::CartesianIndices{2, R} where R<:Tuple{OrdinalRange{Int64, Int64}, OrdinalRange{Int64, Int64}}
    )
        copyto!(parent(dst), dst_i, src, src_i)
    end
    Base.copy!(dst::SparseArrays.AbstractCompressedVector{T}, src::AbstractDimArray{T, 1}) where T =
        copy!(dst, parent(src))
end
Base.copy!(dst::SparseArrays.SparseVector, src::AbstractDimArray{T,1}) where T =
    copy!(dst, parent(src))
Base.copyto!(dst::PermutedDimsArray, src::AbstractDimArray) = 
    copyto!(dst, parent(src))

ArrayInterface.parent_type(::Type{<:AbstractDimArray{T,N,D,A}}) where {T,N,D,A} = A

function Adapt.adapt_structure(to, A::AbstractDimArray)
    rebuild(A,
        data=Adapt.adapt(to, parent(A)),
        dims=Adapt.adapt(to, dims(A)),
        refdims=Adapt.adapt(to, refdims(A)),
        name=Name(name(A)),
        metadata=Adapt.adapt(to, metadata(A)),
    )
end

# Concrete implementation ######################################################

"""
    DimArray <: AbstractDimArray

    DimArray(data, dims, refdims, name, metadata)
    DimArray(data, dims::Tuple; refdims=(), name=NoName(), metadata=NoMetadata())

The main concrete subtype of [`AbstractDimArray`](@ref).

`DimArray` maintains and updates its `Dimension`s through transformations and
moves dimensions to reference dimension `refdims` after reducing operations
(like e.g. `mean`).

## Arguments

- `data`: An `AbstractArray`.
- `dims`: A `Tuple` of `Dimension`
- `name`: A string name for the array. Shows in plots and tables.
- `refdims`: refence dimensions. Usually set programmatically to track past
    slices and reductions of dimension for labelling and reconstruction.
- `metadata`: `Dict` or `Metadata` object, or `NoMetadata()`

Indexing can be done with all regular indices, or with [`Dimension`](@ref)s
and/or [`Selector`](@ref)s. 

Indexing `AbstractDimArray` with non-range `AbstractArray` has undefined effects
on the `Dimension` index. Use forward-ordered arrays only"

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
    function DimArray(
        data::A, dims::D, refdims::R, name::Na, metadata::Me
    ) where {D<:Tuple,R<:Tuple,A<:AbstractArray{T,N},Na,Me} where {T,N}
        checkdims(data, dims)
        new{T,N,D,R,A,Na,Me}(data, dims, refdims, name, metadata)
    end
end
# 2 arg version
DimArray(data::AbstractArray, dims; kw...) = DimArray(data, (dims,); kw...)
function DimArray(data::AbstractArray, dims::Union{Tuple,NamedTuple}; 
    refdims=(), name=NoName(), metadata=NoMetadata()
)
    DimArray(data, format(dims, data), refdims, name, metadata)
end
# All keyword argument version
function DimArray(; data, dims, refdims=(), name=NoName(), metadata=NoMetadata())
    DimArray(data, dims; refdims, name, metadata)
end
# Construct from another AbstractDimArray
function DimArray(A::AbstractDimArray;
    data=data(A), dims=dims(A), refdims=refdims(A), name=name(A), metadata=metadata(A)
)
    DimArray(data, dims; refdims, name, metadata)
end
DimArray{T}(A::AbstractDimArray; kw...) where T = DimArray(convert.(T, A))
DimArray{T}(A::AbstractDimArray{T}; kw...) where T = DimArray(A; kw...)
"""
    DimArray(f::Function, dim::Dimension; [name])

Apply function `f` across the values of the dimension `dim`
(using `broadcast`), and return the result as a dimensional array with
the given dimension. Optionally provide a name for the result.
"""
function DimArray(f::Function, dim::Dimension; name=Symbol(nameof(f), "(", name(dim), ")"))
     DimArray(f.(val(dim)), (dim,); name)
end

Base.convert(::Type{DimArray}, A::AbstractDimArray) = DimArray(A)
Base.convert(::Type{DimArray{T}}, A::AbstractDimArray) where {T} = DimArray{T}(A)

checkdims(A::AbstractArray{<:Any,N}, dims::Tuple) where N = checkdims(N, dims)
checkdims(::Type{<:AbstractArray{<:Any,N}}, dims::Tuple) where N = checkdims(N, dims)
checkdims(n::Integer, dims::Tuple) = length(dims) == n || _dimlengtherror(n, length(dims))

@noinline _dimlengtherror(na, nd) =
    throw(ArgumentError("axes of the array ($na) do not match number of dimensions ($nd)")) 

"""
    rebuild(A::DimArray, data, dims, refdims, name, metadata) => DimArray
    rebuild(A::DimArray; kw...) => DimArray

Rebuild a `DimArray` with new fields. Handling partial field
update is dealt with in `rebuild` for `AbstractDimArray`.
"""
@inline function rebuild(
    A::DimArray, data::AbstractArray, dims::Tuple, refdims::Tuple, name, metadata
)
    DimArray(data, dims, refdims, name, metadata)
end


"""
    Base.fill(x, dims::Dimension...; kw...) => DimArray
    Base.fill(x, dims::Tuple{Vararg{Dimension}}; kw...) => DimArray

Create a [`DimArray`](@ref) with a fill value of `x`.

There are two kinds of `Dimension` value acepted:
- A `Dimension` holding an `AbstractVector` will set the dimension index to 
  that `AbstractVector`, and detect the dimension lookup.
- A `Dimension` holding an `Integer` will set the length of the axis,
  and set the dimension lookup to [`NoLookup`](@ref).

Keywords are the same as for [`DimArray`](@ref).

# Example

```@doctest
julia> using DimensionalData

julia> rand(Bool, X(2), Y(4))
2×4 DimArray{Bool,2} with dimensions: X, Y
 1  0  0  1
 1  0  1  1
```
"""
Base.fill

"""
    Base.rand(x, dims::Dimension...; kw...) => DimArray
    Base.rand(x, dims::Tuple{Vararg{Dimension}}; kw...) => DimArray
    Base.rand(r::AbstractRNG, x, dims::Tuple{Vararg{Dimension}}; kw...) => DimArray
    Base.rand(r::AbstractRNG, x, dims::Dimension...; kw...) => DimArray

Create a [`DimArray`](@ref) of random values.

There are two kinds of `Dimension` value acepted:
- A `Dimension` holding an `AbstractVector` will set the dimension index to 
  that `AbstractVector`, and detect the dimension lookup.
- A `Dimension` holding an `Integer` will set the length of the axis,
  and set the dimension lookup to [`NoLookup`](@ref).

Keywords are the same as for [`DimArray`](@ref).

# Example

```julia
julia> using DimensionalData

julia> rand(Bool, X(2), Y(4))
2×4 DimArray{Bool,2} with dimensions: X, Y
 1  0  0  1
 1  0  1  1

julia> rand(X([:a, :b, :c]), Y(100.0:50:200.0))
3×3 DimArray{Float64,2} with dimensions:
  X: Symbol[a, b, c] Categorical: Unordered,
  Y: 100.0:50.0:200.0 Sampled: Ordered Regular Points
 0.43204   0.835111  0.624231
 0.752868  0.471638  0.193652
 0.484558  0.846559  0.455256
```
"""
Base.rand

"""
    Base.zeros(x, dims::Dimension...; kw...) => DimArray
    Base.zeros(x, dims::Tuple{Vararg{Dimension}}; kw...) => DimArray

Create a [`DimArray`](@ref) of zeros.

There are two kinds of `Dimension` value acepted:
- A `Dimension` holding an `AbstractVector` will set the dimension index to 
  that `AbstractVector`, and detect the dimension lookup.
- A `Dimension` holding an `Integer` will set the length of the axis,
  and set the dimension lookup to [`NoLookup`](@ref).

Keywords are the same as for [`DimArray`](@ref).

# Example

```@doctest
julia> using DimensionalData

julia> zeros(Bool, X(2), Y(4))
2×4 DimArray{Bool,2} with dimensions: X, Y
 0  0  0  0
 0  0  0  0

julia> zeros(X([:a, :b, :c]), Y(100.0:50:200.0))
3×3 DimArray{Float64,2} with dimensions:
  X: Symbol[a, b, c] Categorical: Unordered,
  Y: 100.0:50.0:200.0 Sampled: Ordered Regular Points
 0.0  0.0  0.0
 0.0  0.0  0.0
 0.0  0.0  0.0
```
"""
Base.zeros

"""
    Base.ones(x, dims::Dimension...; kw...) => DimArray
    Base.ones(x, dims::Tuple{Vararg{Dimension}}; kw...) => DimArray

Create a [`DimArray`](@ref) of ones.

There are two kinds of `Dimension` value acepted:
- A `Dimension` holding an `AbstractVector` will set the dimension index to 
  that `AbstractVector`, and detect the dimension lookup.
- A `Dimension` holding an `Integer` will set the length of the axis,
  and set the dimension lookup to [`NoLookup`](@ref).

Keywords are the same as for [`DimArray`](@ref).

# Example

```@doctest
julia> using DimensionalData

julia> ones(Bool, X(2), Y(4))
2×4 DimArray{Bool,2} with dimensions: X, Y
 1  1  1  1
 1  1  1  1

julia> ones(X([:a, :b, :c]), Y(100.0:50:200.0))
3×3 DimArray{Float64,2} with dimensions:
  X: Symbol[a, b, c] Categorical: Unordered,
  Y: 100.0:50.0:200.0 Sampled: Ordered Regular Points
 1.0  1.0  1.0
 1.0  1.0  1.0
 1.0  1.0  1.0
```
"""
Base.ones

# Dimension only DimArray creation methods

for f in (:zeros, :ones, :rand)
    @eval begin
        Base.$f(dim1::Dimension, dims::Dimension...; kw...) = $f((dim1, dims...); kw...)
        Base.$f(dims::DimTuple; kw...) = $f(Float64, dims; kw...)
    end
end
for f in (:trues, :falses)
    @eval begin
        Base.$f(dim1::Dimension, dims::Dimension...; kw...) = $f((dim1, dims...); kw...)
        function Base.$f(dims::DimTuple; kw...)
            C = dimconstructor(dims)
            C($f(_dimlength(dims)), _maybestripval(dims); kw...)
        end
    end
end
# Type specific DimArray creation methods
for f in (:zeros, :ones, :rand)
    @eval begin
        Base.$f(::Type{T}, d1::Dimension, dims::Dimension...; kw...) where T = 
            $f(T, (d1, dims...); kw...)
        function Base.$f(::Type{T}, dims::DimTuple; kw...) where T
            C = dimconstructor(dims)
            C($f(T, _dimlength(dims)), _maybestripval(dims); kw...)
        end
    end
end
# Arbitrary object DimArray creation methods
for f in (:fill, :rand)
    @eval begin
        Base.$f(x, d1::Dimension, dims::Dimension...; kw...) = $f(x, (d1, dims...); kw...)
        function Base.$f(x, dims::DimTuple; kw...)
            A = $f(x, _dimlength(dims))
            C = dimconstructor(dims)
            C(A, _maybestripval(dims); kw...)
        end
    end
end
# AbstractRNG rand DimArray creation methods
Base.rand(r::AbstractRNG, x, d1::Dimension, dims::Dimension...; kw...) = rand(r, x, (d1, dims...); kw...)
function Base.rand(r::AbstractRNG, x, dims::DimTuple; kw...)
    C = dimconstructor(dims)
    C(rand(r, x, _dimlength(dims)), _maybestripval(dims); kw...)
end
function Base.rand(r::AbstractRNG, d1::Dimension, dims::Dimension...; kw...)
    rand(r, (d1, dims...); kw...)
end
function Base.rand(r::AbstractRNG, ::Type{T}, d1::Dimension, dims::Dimension...; kw...) where T
    rand(r, T, (d1, dims...); kw...)
end
function Base.rand(r::AbstractRNG, dims::DimTuple; kw...)
    C = dimconstructor(dims)
    C(rand(r, _dimlength(dims)), _maybestripval(dims); kw...)
end
function Base.rand(r::AbstractRNG, ::Type{T}, dims::DimTuple; kw...) where T
    C = dimconstructor(dims)
    C(rand(r, T, _dimlength(dims)), _maybestripval(dims); kw...)
end

_dimlength(dims::Tuple) = map(_dimlength, dims)
_dimlength(dim::Dimension{<:AbstractArray}) = length(dim)
_dimlength(dim::Dimension{<:Val{Keys}}) where Keys = length(Keys)
_dimlength(dim::Dimension{<:Integer}) = val(dim)
@noinline _dimlength(dim::Dimension) =
    throw(ArgumentError("$(basetypeof(dim)) must hold an Integer or an AbstractArray, instead holds: $(val(dim))"))

function _maybestripval(dims)
    dims = map(dims) do d
        val(d) isa AbstractArray ? d : basetypeof(d)()
    end
end

# dimconstructor
# Allow customising constructors based on dimension types
# Thed default constructor is DimArray
dimconstructor(dims::DimTuple) = dimconstructor(tail(dims)) 
dimconstructor(dims::Tuple{}) = DimArray 

"""
    mergedims(old_dims => new_dim) => Dimension

Return a dimension `new_dim` whose indices are a [`MergedLookup`](@ref) of the indices of
`old_dims`.
"""
function mergedims((old_dims, new_dim)::Pair)
    data = vec(DimPoints(_astuple(old_dims)))
    return rebuild(basedims(new_dim), MergedLookup(data, old_dims))
end

"""
    mergedims(dims, old_dims => new_dim, others::Pair...) => dims_new

If dimensions `old_dims`, `new_dim`, etc. are found in `dims`, then return new `dims_new`
where all dims in `old_dims` have been combined into a single dim `new_dim`.
The returned dimension will keep only the name of `new_dim`. Its coords will be a
[`MergedLookup`](@ref) of the coords of the dims in `old_dims`. New dimensions are always
placed at the end of `dims_new`. `others` contains other dimension pairs to be merged.

# Example

````jldoctest
julia> ds = (X(0:0.1:0.4), Y(10:10:100), Ti([0, 3, 4]));
julia> mergedims(ds, Ti => :time, (X, Y) => :space)
Dim{:time} MergedLookup{Tuple{Int64}} Tuple{Int64}[(0,), (3,), (4,)] Ti,
Dim{:space} MergedLookup{Tuple{Float64, Int64}} Tuple{Float64, Int64}[(0.0, 10), (0.1, 10), …, (0.3, 100), (0.4, 100)] X, Y
````
"""
function mergedims(all_dims, dim_pairs::Pair...)
    # filter out dims completely missing
    dim_pairs = map(x -> _filter_dims(all_dims, first(x)) => last(x), dim_pairs)
    dim_pairs_complete = filter(dim_pairs) do (old_dims,)
        dims_present = dims(all_dims, _astuple(old_dims))
        isempty(dims_present) && return false
        all(hasdim(dims_present, old_dims)) || throw(ArgumentError(
            "Not all dimensions $old_dims found in $(map(basetypeof, all_dims))"
        ))
        return true
    end
    isempty(dim_pairs_complete) && return all_dims
    dim_pairs_concrete = map(dim_pairs_complete) do (old_dims, new_dim)
        return dims(all_dims, _astuple(old_dims)) => new_dim
    end
    # throw error if old dim groups overlap
    old_dims_tuples = map(first, dim_pairs_concrete)
    if !dimsmatch(_cat_tuples(old_dims_tuples...), combinedims(old_dims_tuples...))
        throw(ArgumentError("Dimensions to be merged are not all unique"))
    end
    return _mergedims(all_dims, dim_pairs_concrete...)
end

"""
    mergedims(A::AbstractDimArray, dim_pairs::Pair...) => AbstractDimArray
    mergedims(A::AbstractDimStack, dim_pairs::Pair...) => AbstractDimStack

Return a new array or stack whose dimensions are the result of [`mergedims(dims(A), dim_pairs)`](@ref).
"""
function mergedims(A::AbstractDimArray, dim_pairs::Pair...)
    isempty(dim_pairs) && return A
    all_dims = dims(A)
    dims_new = mergedims(all_dims, dim_pairs...)
    dimsmatch(all_dims, dims_new) && return A
    dims_perm = _unmergedims(dims_new, map(last, dim_pairs))
    Aperm = PermutedDimsArray(A, dims_perm)
    data_merged = reshape(data(Aperm), map(length, dims_new))
    rebuild(A, data_merged, dims_new)
end

"""
    unmergedims(merged_dims::Tuple{Vararg{Dimension}}) => Tuple{Vararg{Dimension}}

Return the unmerged dimensions from a tuple of merged dimensions. However, the order of the original dimensions are not necessarily preserved.
"""
function unmergedims(merged_dims::Tuple{Vararg{Dimension}})
    reduce(map(dims, merged_dims), init=()) do acc, x
        x isa Tuple ? (acc..., x...) : (acc..., x)
    end
end

"""
    unmergedims(A::AbstractDimArray, original_dims) => AbstractDimArray
    unmergedims(A::AbstractDimStack, original_dims) => AbstractDimStack

Return a new array or stack whose dimensions are restored to their original prior to calling [`mergedims(A, dim_pairs)`](@ref).
"""
function unmergedims(A::AbstractDimArray, original_dims)
    merged_dims = dims(A)
    unmerged_dims = unmergedims(merged_dims)
    reshaped = reshape(data(A), size(unmerged_dims))
    permuted = permutedims(reshaped, dimnum(unmerged_dims, original_dims))
    return DimArray(permuted, original_dims)
end

function _mergedims(all_dims, dim_pair::Pair, dim_pairs::Pair...)
    old_dims, new_dim = dim_pair
    dims_to_merge = dims(all_dims, _astuple(old_dims))
    merged_dim = mergedims(dims_to_merge => new_dim)
    all_dims_new = (otherdims(all_dims, dims_to_merge)..., merged_dim)
    isempty(dim_pairs) && return all_dims_new
    return _mergedims(all_dims_new, dim_pairs...)
end

function _unmergedims(all_dims, merged_dims)
    _merged_dims = dims(all_dims, merged_dims)
    unmerged_dims = map(all_dims) do d
        hasdim(_merged_dims, d) || return _astuple(d)
        return dims(lookup(d))
    end
    return _cat_tuples(unmerged_dims...)
end

_unmergedims(all_dims, dim_pairs::Pair...) = _cat_tuples(replace(all_dims, dim_pairs...))

_cat_tuples(tuples...) = mapreduce(_astuple, (x, y) -> (x..., y...), tuples)

_filter_dims(alldims, dims) = filter(dim -> hasdim(alldims, dim), dims)
