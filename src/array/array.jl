const IDim = Dimension{<:StandardIndices}

"""
    AbstractBasicDimArray <: AbstractArray

The abstract supertype for all arrays with a `dims` method that 
returns a `Tuple` of `Dimension`

Only keyword `rebuild` is guaranteed to work with `AbstractBasicDimArray`.
"""
abstract type AbstractBasicDimArray{T,N,D<:Tuple} <: AbstractArray{T,N} end

const AbstractBasicDimVector = AbstractBasicDimArray{T,1} where T
const AbstractBasicDimMatrix = AbstractBasicDimArray{T,2} where T
const AbstractBasicDimVecOrMat = Union{AbstractBasicDimVector,AbstractBasicDimMatrix}

refdims(::AbstractBasicDimArray) = ()
name(::AbstractBasicDimArray) = NoName()
metadata(::AbstractBasicDimArray) = NoMetadata()

# DimensionalData.jl interface methods ####################################################

for func in (:val, :index, :lookup, :order, :sampling, :span, :locus, :bounds, :intervalbounds)
    @eval ($func)(A::AbstractBasicDimArray, args...) = ($func)(dims(A), args...)
end

Extents.extent(A::AbstractBasicDimArray, args...) = Extents.extent(dims(A), args...) 

Base.size(A::AbstractBasicDimArray) = map(length, dims(A))
Base.size(A::AbstractBasicDimArray, dims::DimOrDimType) = size(A, dimnum(A, dims))
Base.axes(A::AbstractBasicDimArray) = map(d -> axes(d, 1), dims(A))
Base.axes(A::AbstractBasicDimArray, dims::DimOrDimType) = axes(A, dimnum(A, dims))
# This is too slow using the default, as it calls `axes` and makes DimUnitRanges
Base.CartesianIndices(s::AbstractBasicDimArray) = CartesianIndices(map(first ∘ axes, lookup(s)))

Base.checkbounds(::Type{Bool}, A::AbstractBasicDimArray, d1::IDim, dims::IDim...) =
    Base.checkbounds(Bool, A, dims2indices(A, (d1, dims...))...)
Base.checkbounds(A::AbstractBasicDimArray, d1::IDim, dims::IDim...) =
    Base.checkbounds(A, dims2indices(A, (d1, dims...))...)

"""
    AbstractDimArray <: AbstractBasicArray

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
abstract type AbstractDimArray{T,N,D<:Tuple,A} <: AbstractBasicDimArray{T,N,D} end

const AbstractDimVector = AbstractDimArray{T,1} where T
const AbstractDimMatrix = AbstractDimArray{T,2} where T
const AbstractDimVecOrMat = Union{AbstractDimVector,AbstractDimMatrix}

# DimensionalData.jl interface methods ####################################################
 
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

# Standard fields
dims(A::AbstractDimArray) = A.dims
refdims(A::AbstractDimArray) = A.refdims
data(A::AbstractDimArray) = A.data # Don't use this method directly, use `parent`
name(A::AbstractDimArray) = A.name
metadata(A::AbstractDimArray) = A.metadata

layerdims(A::AbstractDimArray) = basedims(A)

@inline rebuildsliced(A::AbstractBasicDimArray, args...) = rebuildsliced(getindex, A, args...)
@inline function rebuildsliced(f::Function, A::AbstractBasicDimArray, data::AbstractArray, I::Tuple, name=name(A))
    I1 = to_indices(A, I)
    rebuild(A, data, slicedims(f, A, I1)..., name)
end

# Array interface methods ######################################################

Base.size(A::AbstractDimArray) = size(parent(A))
Base.axes(A::AbstractDimArray) = map(Dimensions.DimUnitRange, axes(parent(A)), dims(A))
Base.iterate(A::AbstractDimArray, args...) = iterate(parent(A), args...)
Base.IndexStyle(A::AbstractDimArray) = Base.IndexStyle(parent(A))
Base.parent(A::AbstractDimArray) = data(A)
Base.vec(A::AbstractDimArray) = vec(parent(A))
# Only compare data and dim - metadata and refdims can be different
Base.:(==)(A1::AbstractDimArray, A2::AbstractDimArray) =
    parent(A1) == parent(A2) && dims(A1) == dims(A2)

# undef constructor for Array, using dims 
function Base.Array{T}(x::UndefInitializer, d1::Dimension, dims::Dimension...) where T 
    Base.Array{T}(x, (d1, dims...))
end
Base.Array{T}(x::UndefInitializer, dims::DimTuple; kw...) where T = Array{T}(x, size(dims))

function Base.NamedTuple(A1::AbstractDimArray, As::AbstractDimArray...) 
    arrays = (A1, As...)
    keys = map(Symbol ∘ name, arrays)
    return NamedTuple{keys}(arrays)
end

# undef constructor for all AbstractDimArray 
(::Type{A})(x::UndefInitializer, dims::Dimension...; kw...) where {A<:AbstractDimArray{T}} where T = 
    A(x, dims; kw...)
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
function Base.similar(A::AbstractDimArray; 
    data=similar(parent(A)), 
    dims=dims(A), refdims=refdims(A), name=_noname(A), metadata=metadata(A), kw...
)
    rebuild(A; data, dims=format(dims, data), refdims, name, metadata, kw...)
end
function Base.similar(A::AbstractDimArray, ::Type{T}; 
    data=similar(parent(A), T),
    dims=dims(A), refdims=refdims(A), name=_noname(A), metadata=metadata(A), kw...
) where T
    rebuild(A; data, dims=format(dims, data), refdims, name, metadata, kw...)
end

# We avoid calling `parent` for AbstractBasicDimArray as we don't know what it is/if there is one
function Base.similar(A::AbstractBasicDimArray{T,N}; 
    data=similar(Array{T,N}, size(A)),
    dims=dims(A), refdims=refdims(A), name=_noname(A), metadata=NoMetadata(), kw...
) where {T,N}
    dimconstructor(dims)(data, dims; refdims, name, metadata, kw...)
end
function Base.similar(A::AbstractBasicDimArray{<:Any,N}, ::Type{T}; 
    data=similar(Array{T,N}, size(A)),
    dims=dims(A), refdims=refdims(A), name=_noname(A), metadata=NoMetadata(), kw...
) where {T,N}
    dimconstructor(dims)(data, dims; refdims, name, metadata, kw...)
end
# We can't resize the dims or add missing dims, so return the unwraped Array type?
# An alternative would be to fill missing dims with `Anon`, and keep existing
# dims but strip the Lookup? It just seems a little complicated when the methods
# below using DimTuple work better anyway.
Base.similar(A::AbstractDimArray, i::Integer, I::Vararg{Integer}; kw...) =
    similar(A, eltype(A), (i, I...); kw...)
Base.similar(A::AbstractDimArray, I::Tuple{Int,Vararg{Int}}; kw...) = 
    similar(A, eltype(A), I; kw...)
Base.similar(A::AbstractDimArray, ::Type{T}, i::Integer, I::Vararg{Integer}; kw...) where T =
    similar(A, T, (i, I...); kw...)
Base.similar(A::AbstractDimArray, ::Type{T}, I::Tuple{Int,Vararg{Int}}; kw...) where T =
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
            A::AbstractArray, ::Type{T}, shape::Tuple{$s1,Vararg{MaybeDimUnitRange}}; kw...
        ) where T
            _similar(A, T, shape; kw...)
        end
        function Base.similar(
            ::Type{T}, shape::Tuple{$s1,Vararg{MaybeDimUnitRange}}; kw...
        ) where T<:AbstractArray
            _similar(T, shape; kw...)
        end
    end
    for s2 in (:(Dimensions.DimUnitRange), :MaybeDimUnitRange)
        all(Base.Fix2(===, :MaybeDimUnitRange), (s1, s2)) || @eval begin
            function Base.similar(
                A::AbstractArray, T::Type, shape::Tuple{$s1,$s2,Vararg{MaybeDimUnitRange}}; kw...
            )
                _similar(A, T, shape; kw...)
            end
            function Base.similar(
                T::Type{<:AbstractArray}, shape::Tuple{$s1,$s2,Vararg{MaybeDimUnitRange}}; kw...
            )
                _similar(T, shape; kw...)
            end
        end
        for s3 in (:(Dimensions.DimUnitRange), :MaybeDimUnitRange)
            all(Base.Fix2(===, :MaybeDimUnitRange), (s1, s2, s3)) || @eval begin
                function Base.similar(
                    A::AbstractArray, T::Type, shape::Tuple{$s1,$s2,$s3,Vararg{MaybeDimUnitRange}}; kw...
                )
                    _similar(A, T, shape; kw...)
                end
                function Base.similar(
                    T::Type{<:AbstractArray}, shape::Tuple{$s1,$s2,$s3,Vararg{MaybeDimUnitRange}}; kw...
                )
                    _similar(T, shape; kw...)
                end        
            end    
            for s4 in (:(Dimensions.DimUnitRange), :MaybeDimUnitRange)
                all(Base.Fix2(===, :MaybeDimUnitRange), (s1, s2, s3, s4)) && continue
                @eval begin
                    function Base.similar(
                        A::AbstractArray, T::Type, shape::Tuple{$s1,$s2,$s3,$s4,Vararg{MaybeDimUnitRange}}; kw...
                    )
                        _similar(A, T, shape; kw...)
                    end
                    function Base.similar(
                        T::Type{<:AbstractArray}, shape::Tuple{$s1,$s2,$s3,$s4,Vararg{MaybeDimUnitRange}}; kw...
                    )
                        _similar(T, shape; kw...)
                    end            
                end
            end
        end
    end
end
function _similar(A::AbstractArray, T::Type, shape::Tuple; kw...)
    data = similar(parent(A), T, map(_parent_range, shape))
    shape isa Tuple{Vararg{Dimensions.DimUnitRange}} || return data
    C = dimconstructor(dims(shape))
    return C(data, dims(shape); kw...)
end
function _similar(::Type{T}, shape::Tuple; kw...) where {T<:AbstractArray}
    data = similar(T, map(_parent_range, shape))
    shape isa Tuple{Vararg{Dimensions.DimUnitRange}} || return data
    C = dimconstructor(dims(shape))
    return C(data, dims(shape); kw...)
end

# With Dimensions we can return an `AbstractDimArray`
Base.similar(A::AbstractBasicDimArray, D::DimTuple; kw...) = Base.similar(A, eltype(A), D; kw...) 
Base.similar(A::AbstractBasicDimArray, D::Dimension...; kw...) = Base.similar(A, eltype(A), D; kw...) 
Base.similar(A::AbstractBasicDimArray, ::Type{T}, D::Dimension...; kw...) where T =
    Base.similar(A, T, D; kw...) 
function Base.similar(A::AbstractDimArray, ::Type{T}, D::DimTuple; 
    refdims=(), name=_noname(A), metadata=NoMetadata(), kw...
) where T
    data = similar(parent(A), T, _dimlength(D))
    dims = _maybestripval(D)
    return rebuild(A; data, dims, refdims, metadata, name, kw...)
end
function Base.similar(A::AbstractDimArray, ::Type{T}, D::Tuple{};
    refdims=(), name=_noname(A), metadata=NoMetadata(), kw...
) where T
    data = similar(parent(A), T, ())
    rebuild(A; data, dims=(), refdims, metadata, name, kw...)
end

# Keep the same type in `similar`
_noname(A::AbstractBasicDimArray) = _noname(name(A))
_noname(s::String) = ""
_noname(::NoName) = NoName()
_noname(::Symbol) = Symbol("")
_noname(name::Name) = name # Keep the name so the type doesn't change

_parent_range(r::Dimensions.DimUnitRange) = parent(r)
_parent_range(r) = r

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
        Base.copy!(dst::$d{T,N}, src::$s{T,N}) where {T,N} = (copy!(_maybeunwrap(dst), _maybeunwrap(src)); dst)
        Base.copy!(dst::$d{T,1}, src::$s{T,1}) where T = (copy!(_maybeunwrap(dst), _maybeunwrap(src)); dst)
        Base.copyto!(dst::$d, src::$s) = (copyto!(_maybeunwrap(dst), _maybeunwrap(src)); dst)
        Base.copyto!(dst::$d, dstart::Integer, src::$s) =
            (copyto!(_maybeunwrap(dst), dstart, _maybeunwrap(src)); dst)
        Base.copyto!(dst::$d, dstart::Integer, src::$s, sstart::Integer) =
            (copyto!(_maybeunwrap(dst), dstart, _maybeunwrap(src), sstart); dst)
        Base.copyto!(dst::$d, dstart::Integer, src::$s, sstart::Integer, n::Integer) =
            (copyto!(_maybeunwrap(dst), dstart, _maybeunwrap(src), sstart, n); dst)
        Base.copyto!(dst::$d{T1,N}, Rdst::CartesianIndices{N}, src::$s{T2,N}, Rsrc::CartesianIndices{N}) where {T1,T2,N} =
            (copyto!(_maybeunwrap(dst), Rdst, _maybeunwrap(src), Rsrc); dst)
    end
end
# Ambiguity
Base.copyto!(dst::AbstractDimArray{T,2}, src::SparseArrays.CHOLMOD.Dense{T}) where T<:Union{Float64,ComplexF64} =
    (copyto!(parent(dst), src); dst)
Base.copyto!(dst::AbstractDimArray{T}, src::SparseArrays.CHOLMOD.Dense{T}) where T<:Union{Float64,ComplexF64} =
    (copyto!(parent(dst), src); dst)
Base.copyto!(dst::DimensionalData.AbstractDimArray, src::SparseArrays.CHOLMOD.Dense) =
    (copyto!(parent(dst), src); dst)
Base.copyto!(dst::SparseArrays.AbstractCompressedVector, src::AbstractDimArray{T, 1} where T) =
    (copyto!(dst, parent(src)); dst)
Base.copyto!(dst::AbstractDimArray{T,2} where T, src::SparseArrays.AbstractSparseMatrixCSC) =
    (copyto!(parent(dst), src); dst)
Base.copyto!(dst::AbstractDimArray{T,2} where T, src::LinearAlgebra.AbstractQ) =
    (copyto!(parent(dst), src); dst)
function Base.copyto!(
    dst::AbstractDimArray{<:Any,2}, 
    dst_i::CartesianIndices{2, R} where R<:Tuple{OrdinalRange{Int64, Int64}, OrdinalRange{Int64, Int64}}, 
    src::SparseArrays.AbstractSparseMatrixCSC{<:Any}, 
    src_i::CartesianIndices{2, R} where R<:Tuple{OrdinalRange{Int64, Int64}, OrdinalRange{Int64, Int64}}
)
    copyto!(parent(dst), dst_i, src, src_i)
    return dst
end
Base.copy!(dst::SparseArrays.AbstractCompressedVector{T}, src::AbstractDimArray{T, 1}) where T =
    (copy!(dst, parent(src)); dst)

Base.copy!(dst::SparseArrays.SparseVector, src::AbstractDimArray{T,1}) where T =
    (copy!(dst, parent(src)); dst)
Base.copyto!(dst::PermutedDimsArray, src::AbstractDimArray) = 
    (copyto!(dst, parent(src)); dst)

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
    DimArray(gen; kw...)

The main concrete subtype of [`AbstractDimArray`](@ref).

`DimArray` maintains and updates its `Dimension`s through transformations and
moves dimensions to reference dimension `refdims` after reducing operations
(like e.g. `mean`).

## Arguments

- `data`: An `AbstractArray` or a table with coordinate columns corresponding to `dims`.
- `gen`: A generator expression. Where source iterators are `Dimension`s the dim args or kw is not needed.
- `dims`: A `Tuple` of `Dimension`
- `name`: A string name for the array. Shows in plots and tables.
- `refdims`: refence dimensions. Usually set programmatically to track past
    slices and reductions of dimension for labelling and reconstruction.
- `metadata`: `Dict` or `Metadata` object, or `NoMetadata()`
- `selector`: The coordinate selector type to use when materializing from a table.

Indexing can be done with all regular indices, or with [`Dimension`](@ref)s
and/or [`Selector`](@ref)s. 

Indexing `AbstractDimArray` with non-range `AbstractArray` has undefined effects
on the `Dimension` index. Use forward-ordered arrays only"

Note that the generator expression syntax requires usage of the semi-colon `;`
to distinguish generator dimensions from keywords.

Example:

```jldoctest dimarray; setup = :(using Random; Random.seed!(123))
julia> using Dates, DimensionalData

julia> ti = Ti(DateTime(2001):Month(1):DateTime(2001,12));

julia> x = X(10:10:100);

julia> A = DimArray(rand(12,10), (ti, x), name="example");

julia> A[X(Near([12, 35])), Ti(At(DateTime(2001,5)))]
┌ 2-element DimArray{Float64, 1} example ┐
├────────────────────────────────────────┴────────────── dims ┐
  ↓ X Sampled{Int64} [10, 40] ForwardOrdered Irregular Points
└─────────────────────────────────────────────────────────────┘
 10  0.253849
 40  0.637077

julia> A[Near(DateTime(2001, 5, 4)), Between(20, 50)]
┌ 4-element DimArray{Float64, 1} example ┐
├────────────────────────────────────────┴──────────── dims ┐
  ↓ X Sampled{Int64} 20:10:50 ForwardOrdered Regular Points
└───────────────────────────────────────────────────────────┘
 20  0.774092
 30  0.823656
 40  0.637077
 50  0.692235
```

Generator expression:

```jldoctest dimarray
julia> DimArray((x, y) for x in X(1:3), y in Y(1:2); name = :Value)
┌ 3×2 DimArray{Tuple{Int64, Int64}, 2} Value ┐
├────────────────────────────────────────────┴──── dims ┐
  ↓ X Sampled{Int64} 1:3 ForwardOrdered Regular Points,
  → Y Sampled{Int64} 1:2 ForwardOrdered Regular Points
└───────────────────────────────────────────────────────┘
 ↓ →  1        2
 1     (1, 1)   (1, 2)
 2     (2, 1)   (2, 2)
 3     (3, 1)   (3, 2)
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
    data=parent(A), dims=dims(A), refdims=refdims(A), name=name(A), metadata=metadata(A)
)
    DimArray(data, dims; refdims, name, metadata)
end
DimArray{T}(A::AbstractDimArray; kw...) where T = DimArray(convert.(T, A))
DimArray{T}(A::AbstractDimArray{T}; kw...) where T = DimArray(A; kw...)
# We collect other kinds of AbstractBasicDimArray 
# to avoid complicated nesting of dims
function DimArray(A::AbstractBasicDimArray;
    data=parent(A), dims=dims(A), refdims=refdims(A), name=name(A), metadata=metadata(A)
)
    newdata = collect(data)
    DimArray(newdata, format(dims, newdata); refdims, name, metadata)
end
# Write a single column from a table with one or more coordinate columns to a DimArray
function DimArray(table, dims;  kw...)
    # Confirm that the Tables interface is implemented
    Tables.istable(table) || throw(ArgumentError("`obj` must be an `AbstractArray` or satisfy the `Tables.jl` interface."))
    _dimarray_from_table(table, guess_dims(table, dims); kw...)
end
function DimArray(data::AbstractVector{<:NamedTuple{K}}, dims::Tuple; 
    refdims=(), name=NoName(), metadata=NoMetadata(), kw...
) where K
    if all(map(d -> Dimensions.name(d) in K, dims))
        table = Tables.columns(data)
        return _dimarray_from_table(table, guess_dims(table, dims; kw...); 
            refdims, name, metadata, kw...)
    else
        return DimArray(data, format(dims, data), refdims, name, metadata)
    end
end
# Same as above, but guess dimension names
function DimArray(table; kw...)
    # Confirm that the Tables interface is implemented
    Tables.istable(table) || throw(ArgumentError("`table` must satisfy the `Tables.jl` interface."))
    table = Tables.columnaccess(table) ? table : Tables.columns(table)
    # Use default dimension 
    return _dimarray_from_table(table, guess_dims(table; kw...); kw...)
end
function _dimarray_from_table(table, dims; name=NoName(), selector=nothing, precision=6, missingval=missing, kw...)
    # Determine row indices based on coordinate values
    indices = coords_to_indices(table, dims; selector, atol=10.0^-precision)

    # Extract the data column correspondong to `name`
    col = name == NoName() ? data_col_names(table, dims) |> first : Symbol(name)
    data = Tables.getcolumn(table, col)

    # Restore array data
    array = restore_array(data, indices, dims, missingval)

    # Return DimArray
    return DimArray(array, dims, name=col; kw...)
end

"""
    DimArray(f::Function, dim::Dimension; [name])

Apply function `f` across the values of the dimension `dim`
(using `broadcast`), and return the result as a dimensional array with
the given dimension. Optionally provide a name for the result.
"""
function DimArray(f::Function, dim::Dimension; name=Symbol(nameof(f), "(", name(dim), ")"))
    DimArray(f.(val(dim)), (dim,); name)
end

DimArray(itr::Base.Generator; kwargs...) = rebuild(collect(itr); kwargs...)

const DimVector = DimArray{T,1} where T
const DimMatrix = DimArray{T,2} where T
const DimVecOrMat = Union{DimVector,DimMatrix}

DimVector(A::AbstractVector, dim::Dimension, args...; kw...) = 
    DimArray(A, (dim,), args...; kw...)
DimVector(A::AbstractVector, args...; kw...) = DimArray(A, args...; kw...)
DimVector(f::Function, dim::Dimension; kw...) = 
    DimArray(f::Function, dim::Dimension; kw...) 
DimMatrix(A::AbstractMatrix, args...; kw...) = DimArray(A, args...; kw...)

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

```jldoctest
julia> using DimensionalData, Random; Random.seed!(123);

julia> fill(true, X(2), Y(4))
┌ 2×4 DimArray{Bool, 2} ┐
├───────────────── dims ┤
  ↓ X, → Y
└───────────────────────┘
 1  1  1  1
 1  1  1  1
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

```jldoctest; setup = :(using Random; Random.seed!(123))
julia> using DimensionalData

julia> rand(Bool, X(2), Y(4))
┌ 2×4 DimArray{Bool, 2} ┐
├───────────────── dims ┤
  ↓ X, → Y
└───────────────────────┘
 0  0  0  0
 1  0  0  1

julia> rand(X([:a, :b, :c]), Y(100.0:50:200.0))
┌ 3×3 DimArray{Float64, 2} ┐
├──────────────────────────┴──────────────────────────────────── dims ┐
  ↓ X Categorical{Symbol} [:a, :b, :c] ForwardOrdered,
  → Y Sampled{Float64} 100.0:50.0:200.0 ForwardOrdered Regular Points
└─────────────────────────────────────────────────────────────────────┘
 ↓ →  100.0       150.0       200.0
  :a    0.443494    0.253849    0.867547
  :b    0.745673    0.334152    0.0802658
  :c    0.512083    0.427328    0.311448
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

```jldoctest
julia> using DimensionalData

julia> zeros(Bool, X(2), Y(4))
┌ 2×4 DimArray{Bool, 2} ┐
├───────────────── dims ┤
  ↓ X, → Y
└───────────────────────┘
 0  0  0  0
 0  0  0  0

julia> zeros(X([:a, :b, :c]), Y(100.0:50:200.0))
┌ 3×3 DimArray{Float64, 2} ┐
├──────────────────────────┴──────────────────────────────────── dims ┐
  ↓ X Categorical{Symbol} [:a, :b, :c] ForwardOrdered,
  → Y Sampled{Float64} 100.0:50.0:200.0 ForwardOrdered Regular Points
└─────────────────────────────────────────────────────────────────────┘
 ↓ →  100.0  150.0  200.0
  :a    0.0    0.0    0.0
  :b    0.0    0.0    0.0
  :c    0.0    0.0    0.0

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

```jldoctest
julia> using DimensionalData

julia> ones(Bool, X(2), Y(4))
┌ 2×4 DimArray{Bool, 2} ┐
├───────────────── dims ┤
  ↓ X, → Y
└───────────────────────┘
 1  1  1  1
 1  1  1  1

julia> ones(X([:a, :b, :c]), Y(100.0:50:200.0))
┌ 3×3 DimArray{Float64, 2} ┐
├──────────────────────────┴──────────────────────────────────── dims ┐
  ↓ X Categorical{Symbol} [:a, :b, :c] ForwardOrdered,
  → Y Sampled{Float64} 100.0:50.0:200.0 ForwardOrdered Regular Points
└─────────────────────────────────────────────────────────────────────┘
 ↓ →  100.0  150.0  200.0
  :a    1.0    1.0    1.0
  :b    1.0    1.0    1.0
  :c    1.0    1.0    1.0

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
Base.rand(r::AbstractRNG, x, d1::Dimension, dims::Dimension...; kw...) = 
    rand(r, x, (d1, dims...); kw...)
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
    C(rand(r, _dimlength(dims)...), _maybestripval(dims); kw...)
end
function Base.rand(r::AbstractRNG, ::Type{T}, dims::DimTuple; kw...) where T
    C = dimconstructor(dims)
    C(rand(r, T, _dimlength(dims)), _maybestripval(dims); kw...)
end

function _dimlength(
    dims::Tuple{<:Dimension{<:Lookups.ArrayLookup},Vararg{Dimension{<:Lookups.ArrayLookup}}}
) 
    lookups = lookup(dims)
    sz1 = size(first(lookups).matrix)
    foreach(lookups) do l
        sz = size(l.matrix)
        sz1 == sz || throw(ArgumentError("ArrayLookup matrix sizes must match. Got $sz1 and $sz"))
    end
    return sz1
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
dimconstructor(::Tuple{}) = DimArray 

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

```jldoctest
julia> using DimensionalData

julia> ds = (X(0:0.1:0.4), Y(10:10:100), Ti([0, 3, 4]))
(↓ X  0.0:0.1:0.4,
→ Y  10:10:100,
↗ Ti [0, 3, 4])

julia> mergedims(ds, (X, Y) => :space)
(↓ Ti    [0, 3, 4],
→ space MergedLookup{Tuple{Float64, Int64}} [(0.0, 10), (0.1, 10), …, (0.3, 100), (0.4, 100)] (↓ X, → Y))
```
"""
function mergedims(x, dt1::Tuple, dts::Tuple...)
    pairs = map((dt1, dts...)) do ds
        ds => Dim{Symbol(map(name, ds)...)}()
    end
    mergedims(x, pairs...)
end
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
    data_merged = reshape(parent(Aperm), map(length, dims_new))
    return rebuild(A, data_merged, dims_new)
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
function unmergedims(A::AbstractBasicDimArray, original_dims)
    merged_dims = dims(A)
    unmerged_dims = unmergedims(merged_dims)
    reshaped = reshape(parent(A), size(unmerged_dims))
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
