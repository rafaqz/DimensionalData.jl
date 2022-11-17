# Tables.jl interface

DimTableSources = Union{AbstractDimStack,AbstractDimArray}

Tables.istable(::DimTableSources) = true
Tables.columnaccess(::Type{<:DimTableSources}) = true
Tables.columns(x::DimTableSources) = DimTable(x)

Tables.columnnames(A::AbstractDimArray) = _colnames(DimStack(A))
Tables.columnnames(s::AbstractDimStack) = _colnames(s)

Tables.schema(A::AbstractDimArray) = Tables.schema(DimStack(A))
Tables.schema(s::AbstractDimStack) = Tables.schema(DimTable(s))

@inline Tables.getcolumn(x::DimTableSources, i::Int) = Tables.getcolumn(DimTable(x), i)
@inline Tables.getcolumn(x::DimTableSources, key::Symbol) =
    Tables.getcolumn(DimTable(x), key)
@inline Tables.getcolumn(x::DimTableSources, ::Type{T}, i::Int, key::Symbol) where T =
    Tables.getcolumn(DimTable(x), T, i, key)
@inline Tables.getcolumn(t::DimTableSources, dim::DimOrDimType) =
    Tables.getcolumn(t, dimnum(t, dim))

"""
    DimColumn{T,D<:Dimension} <: AbstractVector{T}

    DimColumn(dim::Dimension, dims::Tuple{Vararg{<:DimTuple}})
    DimColumn(dim::DimColumn, length::Int, dimstride::Int)

A table column based on a `Dimension` and it's relationship with other
`Dimension`s in `dims`.

`length` is the product of all dim lengths (usually the length of the corresponding
array data), while stride is the product of the preceding dimension lengths, which
may or may not be the real stride of the corresponding array depending on the data type.
For `A isa Array`, the `dimstride` will match the `stride`.

When the second argument is a `Tuple` of `Dimension`, the `length` and `dimstride`
fields are calculated from the dimensions, relative to the column dimension `dim`.


This object will be returned as a column of [`DimTable`](@ref).
"""
struct DimColumn{T,D<:Dimension} <: AbstractVector{T}
    dim::D
    dimstride::Int
    length::Int
end
function DimColumn(dim::D, alldims::DimTuple) where D<:Dimension
    # This is the apparent stride for indexing purposes,
    # it is not always the real array stride
    stride = dimstride(alldims, dim)
    len = prod(map(length, alldims))
    DimColumn{eltype(dim),D}(dim, stride, len)
end

dim(c::DimColumn) = getfield(c, :dim)
dimstride(c::DimColumn) = getfield(c, :dimstride)

# Simple Array interface

Base.length(c::DimColumn) = getfield(c, :length)
@inline function Base.getindex(c::DimColumn, i::Int)
    Base.@boundscheck checkbounds(c, i)
    dim(c)[mod((i - 1) ÷ dimstride(c), length(dim(c))) + 1]
end
Base.getindex(c::DimColumn, ::Colon) = vec(c)
Base.getindex(c::DimColumn, A::AbstractArray) = [c[i] for i in A]
Base.size(c::DimColumn) = (length(c),)
Base.axes(c::DimColumn) = (Base.OneTo(length(c)),)
Base.vec(c::DimColumn{T}) where T = [c[i] for i in eachindex(c)]
Base.Array(c::DimColumn) = vec(c)

struct DimArrayColumn{T,A<:AbstractDimArray{T},DS,DL,L} <: AbstractVector{T}
    data::A
    dimstrides::DS
    dimlengths::DL
    length::L
end
function DimArrayColumn(A::AbstractDimArray{T}, alldims::DimTupleOrEmpty) where T
    # This is the apparent stride for indexing purposes,
    # it is not always the real array stride
    dimstrides = map(d -> dimstride(alldims, d), dims(A))
    dimlengths = map(length, dims(A))
    len = prod(map(length, alldims))
    DimArrayColumn(A, dimstrides, dimlengths, len)
end

Base.parent(c::DimArrayColumn) = getfield(c, :data)
dimstrides(c::DimArrayColumn) = getfield(c, :dimstrides)
dimlengths(c::DimArrayColumn) = getfield(c, :dimlengths)

# Simple Array interface

Base.length(c::DimArrayColumn) = getfield(c, :length)
@inline function Base.getindex(c::DimArrayColumn, i::Int)
    Base.@boundscheck checkbounds(c, i)
    I = map((s, l) -> _strideind(s, l, i), dimstrides(c), dimlengths(c))
    parent(c)[I...]
end

_strideind(stride, len, i) = mod((i - 1) ÷ stride, len) + 1

Base.getindex(c::DimArrayColumn, ::Colon) = vec(c)
Base.getindex(c::DimArrayColumn, A::AbstractArray) = [c[i] for i in A]
Base.size(c::DimArrayColumn) = (length(c),)
Base.axes(c::DimArrayColumn) = (Base.OneTo(length(c)),)
Base.vec(c::DimArrayColumn{T}) where T = [c[i] for i in eachindex(c)]
Base.Array(c::DimArrayColumn) = vec(c)

"""
    AbstractDimTable <: Tables.AbstractColumns

Abstract supertype for dim tables
"""
abstract type AbstractDimTable <: Tables.AbstractColumns end

"""
    DimTable <: AbstractDimTable

    DimTable(A::AbstractDimArray)

Construct a Tables.jl/TableTraits.jl compatible object out of an `AbstractDimArray`.

This table will have a column for the array data and columns for each
`Dimension` index, as a [`DimColumn`]. These are lazy, and generated
as required.

Column names are converted from the dimension types using
[`DimensionalData.dim2key`](@ref). This means type `Ti` becomes the
column name `:Ti`, and `Dim{:custom}` becomes `:custom`.

To get dimension columns, you can index with `Dimension` (`X()`) or
`Dimension` type (`X`) as well as the regular `Int` or `Symbol`.
"""
struct DimTable{Keys,S,DC,DAC} <: AbstractDimTable
    stack::S
    dimcolumns::DC
    dimarraycolumns::DAC
end
DimTable{K}(stack::S, dimcolumns::DC, strides::SD) where {K,S,DC,SD} = 
    DimTable{K,S,DC,SD}(stack, dimcolumns, strides)
DimTable(A::AbstractDimArray, As::AbstractDimArray...) = DimTable((A, As...))
function DimTable(As::Tuple{<:AbstractDimArray,Vararg{<:AbstractDimArray}}...)
    DimTable(DimStack(As...))
end
function DimTable(s::AbstractDimStack)
    dims_ = dims(s)
    dimcolumns = map(d -> DimColumn(d, dims_), dims_)
    dimarraycolumns = map(A -> DimArrayColumn(A, dims_), s)
    keys = _colnames(s)
    DimTable{keys}(s, dimcolumns, dimarraycolumns)
end

dimcolumns(t::DimTable) = getfield(t, :dimcolumns)
dimarraycolumns(t::DimTable) = getfield(t, :dimarraycolumns)
dims(t::DimTable) = dims(parent(t))

Base.parent(t::DimTable) = getfield(t, :stack)

for func in (:dims, :val, :index, :lookup, :metadata, :order, :sampling, :span, :bounds,
             :locus, :name, :label, :units)
    @eval $func(t::DimTable, args...) = $func(parent(t), args...)

end

# Tables interface

Tables.istable(::DimTable) = true
Tables.columnaccess(::Type{<:DimTable}) = true
Tables.columns(t::DimTable) = t
Tables.columnnames(c::DimTable{Keys}) where Keys = Keys
function Tables.schema(t::DimTable{Keys}) where Keys
    s = parent(t)
    types = (map(eltype, dims(s))..., map(eltype, parent(s))...)
    Tables.Schema(Keys, types)
end

@inline function Tables.getcolumn(t::DimTable{Keys}, i::Int) where Keys
    nkeys = length(Keys)
    if i > length(dims(t))
        dimarraycolumns(t)[i - length(dims(t))]
    elseif i > 0 && i < nkeys
        dimcolumns(t)[i]
    else
        throw(ArgumentError("There is no table column $i"))
    end
end
@inline function Tables.getcolumn(t::DimTable, dim::DimOrDimType)
    dimcolumns(t)[dimnum(t, dim)]
end
# Retrieve a column by name
@inline function Tables.getcolumn(t::DimTable{Keys}, key::Symbol) where Keys
    if key in keys(dimarraycolumns(t))
        dimarraycolumns(t)[key]
    else
        dimcolumns(t)[dimnum(dims(t), key)]
    end
end
@inline function Tables.getcolumn(t::DimTable, ::Type{T}, i::Int, key::Symbol) where T
    Tables.getcolumn(t, key)
end

function _colnames(s::AbstractDimStack)
    dimkeys = map(dim2key, (dims(s)))
    # The data is always the last column/s
    (dimkeys..., keys(s)...)
end


# TableTraits.jl interface

function IteratorInterfaceExtensions.getiterator(x::DimTableSources)
    return Tables.datavaluerows(Tables.columntable(x))
end
IteratorInterfaceExtensions.isiterable(::DimTableSources) = true
TableTraits.isiterabletable(::DimTableSources) = true

function IteratorInterfaceExtensions.getiterator(t::DimTable)
    return Tables.datavaluerows(Tables.columntable(t))
end
IteratorInterfaceExtensions.isiterable(::DimTable) = true
TableTraits.isiterabletable(::DimTable) = true
