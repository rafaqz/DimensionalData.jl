# Tables.jl interface

DimTableSources = Union{AbstractDimDataset,AbstractDimArray}

Tables.istable(::Type{<:DimTableSources}) = true
Tables.istable(::DimTableSources) = true
Tables.columnaccess(::Type{<:DimTableSources}) = true
Tables.columns(x::DimTableSources) = DimTable(x)

Tables.columnnames(A::AbstractDimArray) = _colnames(DimDataset(A))
Tables.schema(A::AbstractDimArray) = Tables.schema(DimDataset(A))

Tables.columnnames(ds::AbstractDimDataset) = _colnames(ds)
Tables.schema(ds::AbstractDimDataset) = 
    Tables.Schema(_colnames(ds), (map(eltype, dims(ds))..., map(eltype, layers(ds))...))

@inline Tables.getcolumn(x::DimTableSources, i::Int) =
    Tables.getcolumn(DimTable(x), i)
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
    length::Int
    dimstride::Int
end
DimColumn(dim::D, dims::DimTuple) where D<:Dimension = begin
    # This is the apparent stride for indexing purposes, 
    # it is not always the real array stride
    stride = dimstride(dims, dim) 
    len = prod(map(length, dims))
    DimColumn{eltype(dim),D}(dim, len, stride)
end

dataset(c::DimColumn) = getfield(c, :dataset)
dim(c::DimColumn) = getfield(c, :dim)
dimstride(c::DimColumn) = getfield(c, :dimstride)

# Simple Array interface

Base.length(c::DimColumn) = getfield(c, :length)
@inline Base.getindex(c::DimColumn, i::Int) = begin
    Base.@boundscheck checkbounds(c, i)
    dim(c)[mod((i - 1) ÷ dimstride(c), length(dim(c))) + 1]
end
Base.getindex(c::DimColumn, ::Colon) = vec(c)
Base.getindex(c::DimColumn, range::AbstractRange) = [c[i] for i in range] 
Base.size(c::DimColumn) = (length(c),)
Base.axes(c::DimColumn) = (Base.OneTo(length(c)),)
Base.vec(c::DimColumn{T}) where T = [c[i] for i in eachindex(c)]
Base.Array(c::DimColumn) = vec(c)

abstract type AbstractDimTable <: Tables.AbstractColumns end

"""
    DimTable(A::AbstractDimArray)

Construct a Tables.jl compatible object out of an `AbstractDimArray`.

This table will have a column for the array data and columns for each 
`Dimension` index, as a [`DimColumn`]. These are lazy, and generated
as required.

Column names are converted from the dimension types using 
[`DimensionalData.dim2key`](@ref). This means type `Ti` becomes the 
column name `:Ti`, and `Dim{:custom}` becomes `:custom`.

To get dimension columns, you can index with `Dimension` (`X()`) or
`Dimension` type (`X`) as well as the regular `Int` or `Symbol`.
"""
struct DimTable{Keys,DS,C} <: AbstractDimTable
    dataset::DS
    dimcolumns::C
end
DimTable(A::AbstractDimArray, As::AbstractDimArray...) = DimTable((A, As...))
DimTable(As::Tuple{<:AbstractDimArray,Vararg{<:AbstractDimArray}}...) = 
    DimTable(DimDataset(As...))
DimTable(ds::AbstractDimDataset) = begin
    dims_ = dims(ds)
    dimcolumns = map(d -> DimColumn(d, dims_), dims_)
    keys = _colnames(ds)
    DimTable{keys,typeof(ds),typeof(dimcolumns)}(ds, dimcolumns)
end

dataset(t::DimTable) = getfield(t, :dataset)
dimcolumns(t::DimTable) = getfield(t, :dimcolumns)
dims(t::DimTable) = dims(dataset(t))

for func in (:dims, :val, :index, :mode, :metadata, :order, :sampling, :span, :bounds, :locus, 
             :name, :shortname, :label, :units, :arrayorder, :indexorder, :relation)
    @eval ($func)(t::DimTable, args...) = ($func)(dataset(t), args...)
end

# Tables interface

Tables.istable(::Type{<:DimTable}) = true
Tables.istable(::DimTable) = true
Tables.columnaccess(::Type{<:DimTable}) = true
Tables.columns(t::DimTable) = t
Tables.columnnames(c::DimTable{Keys}) where Keys = Keys
Tables.schema(t::DimTable{Keys}) where Keys = begin
    ds = dataset(t)
    Tables.Schema(Keys, (map(eltype, dims(ds))..., map(eltype, layers(ds))...))
end

@inline Tables.getcolumn(t::DimTable{Keys}, i::Int) where Keys = begin
    nkeys = length(Keys) 
    if i > length(dims(t))
        vec(values(dataset(t))[i - length(dims(t))])
    elseif i < nkeys
        dimcolumns(t)[i]
    else
        error("There is no column $i")
    end
end
@inline Tables.getcolumn(t::DimTable, dim::DimOrDimType) =
    Tables.getcolumn(t, dimnum(t, dim))
# Retrieve a column by name
@inline Tables.getcolumn(t::DimTable{Keys}, key::Symbol) where Keys = begin
    if key in keys(dataset(t))
        vec(dataset(t)[key])
    else
        dimcolumns(t)[dimnum(dims(t), key)]
    end
end
@inline Tables.getcolumn(t::DimTable, ::Type{T}, i::Int, key::Symbol) where T =
    Tables.getcolumn(t, key)

_colnames(ds::AbstractDimDataset) = begin
    dimkeys = map(dim2key, (dims(ds)))
    # The data is always the last column/s
    (dimkeys..., keys(ds)...)
end
