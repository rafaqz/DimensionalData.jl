# Tables.jl interface

Tables.istable(::Type{<:AbstractDimArray}) = true
Tables.istable(::AbstractDimArray) = true
Tables.columnaccess(::Type{<:AbstractDimArray}) = true
Tables.columns(A::AbstractDimArray) = DimTable(A)
Tables.columnnames(A::AbstractDimArray) = _colnames(A)
Tables.schema(A::AbstractDimArray{T}) where T = 
    Tables.Schema(_colnames(A), (map(eltype, dims(A))..., T))
@inline Tables.getcolumn(A::AbstractDimArray, i::Int) =
    Tables.getcolumn(DimTable(A), i)
@inline Tables.getcolumn(A::AbstractDimArray, key::Symbol) =
    Tables.getcolumn(DimTable(A), key)
@inline Tables.getcolumn(A::AbstractDimArray, ::Type{T}, i::Int, key::Symbol) where T =
    Tables.getcolumn(DimTable(A), T, i, key)

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

array(c::DimColumn) = getfield(c, :array)
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


"""
    DimTable(A::AbstractDimArray)

Construct a Tables.jl compatible object out of an `AbstractDimArray`.

This table will have a column for the array data and columns for each 
`Dimension` index, as a [`DimColumn`]. These are lazy, and generated
as required.

Column names  are converted from the dimension types using `dim2key`.

This means type `Ti` becomes the column name `:Ti`, and `Dim{:custom}`
becomes `:custom`.
"""
struct DimTable{Keys,A,C} <: Tables.AbstractColumns 
    array::A
    dimcolumns::C
end
DimTable(A::AbstractDimArray) = begin
    dims_ = dims(A)
    dimcolumns = map(d -> DimColumn(d, dims_), dims_)
    keys = _colnames(A)
    DimTable{keys,typeof(A),typeof(dimcolumns)}(A, dimcolumns)
end
array(t::DimTable) = getfield(t, :array)
dimcolumns(t::DimTable) = getfield(t, :dimcolumns)
dims(t::DimTable) = dims(array(t))

for func in (:dims, :val, :index, :mode, :metadata, :order, :sampling, :span, :bounds, :locus, 
             :name, :shortname, :label, :units, :arrayorder, :indexorder, :relation)
    @eval ($func)(t::DimTable, args...) = ($func)(array(t), args...)
end

# Tables interface

Tables.istable(::Type{<:DimTable}) = true
Tables.istable(::DimTable) = true
Tables.columnaccess(::Type{<:DimTable}) = true
Tables.columns(t::DimTable) = t
Tables.columnnames(c::DimTable{Keys}) where Keys = Keys
Tables.schema(t::DimTable{Keys}) where Keys = begin
    A = array(t)
    Tables.Schema(Keys, (map(eltype, dims(A))..., eltype(A)))
end

@inline Tables.getcolumn(t::DimTable{Keys}, i::Int) where Keys = begin
    nkeys = length(Keys) 
    if i == nkeys
        vec(array(t))
    elseif i < nkeys
        dimcolumns(t)[i]
    else
        error("There is no column $i")
    end
end
# Retrieve a column by name
@inline Tables.getcolumn(t::DimTable{Keys}, key::Symbol) where Keys = begin
    if key == last(Keys)
        vec(array(t))
    else
        dimcolumns(t)[dimnum(dims(t), key)]
    end
end
@inline Tables.getcolumn(t::DimTable, ::Type{T}, i::Int, key::Symbol) where T =
    Tables.getcolumn(t, key)


_colnames(A) = begin
    arraykey = name(A) == "" ? :value : Symbol(name(A))
    dimkeys = map(dim2key, (dims(A)))
    # The data is always the last column
    (dimkeys..., arraykey)
end
