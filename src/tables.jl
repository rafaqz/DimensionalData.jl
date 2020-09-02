# Tables.jl interface
# https://juliadata.github.io/Tables.jl/stable/


# Declare that your table type implements the interface
Tables.istable(::Type{<:AbstractDimArray}) = true
Tables.istable(::AbstractDimArray) = true
Tables.columnaccess(::Type{<:AbstractDimArray}) = true
Tables.columns(A::AbstractDimArray) = DimTable(A)
# Return column names for a table as an indexable collection
Tables.columnnames(A::AbstractDimArray) = _colnames(A)
Tables.schema(A::AbstractDimArray{T}) where T = 
    Tables.Schema(_colnames(A), (map(eltype, dims(A))..., T))

# Retrieve a column by index
Tables.getcolumn(A::AbstractDimArray{T,N}, i::Int) where {T,N} = begin
    if i == N + 1
        vec(parent(A))
    elseif i <= N
        dim = dims(A, i)
        DimColumn(dim, dims(A))
    else
        error("There is no column $i")
    end
end
# Retrieve a column by name
Tables.getcolumn(A::AbstractDimArray, key::Symbol) = begin
    if key == Symbol(name(A)) || key == :value
        vec(parent(A))
    else
        dim = dims(A, key2dim(key))
        DimColumn(dim, dims(A))
    end
end

# a custom row type; acts as a "view" into a row of an AbstractMatrix
struct DimColumn{T,D<:Dimension} <: AbstractVector{T}
    dim::D
    length::Int
    dimstride::Int
end
DimColumn(dim::D, dims::DimTuple) where D<:Dimension = begin
    # This is the apparent stride for indexing purposes, 
    # which is not always the real array stride
    stride = dimstride(dims, dim) 
    len = prod(map(length, dims))
    DimColumn{eltype(dim),D}(dim, len, stride)
end
array(c::DimColumn) = getfield(c, :array)
dim(c::DimColumn) = getfield(c, :dim)
dimstride(c::DimColumn) = getfield(c, :dimstride)
Base.length(c::DimColumn) = getfield(c, :length)

Base.getindex(c::DimColumn, i::Int) = 
    dim(c)[mod((i - 1) ÷ dimstride(c), length(dim(c))) + 1]
Base.getindex(c::DimColumn, ::Colon) = vec(c)
Base.getindex(c::DimColumn, range::AbstractRange) = [c[i] for i in range] 
Base.length(c::DimColumn) = c.length
Base.size(c::DimColumn) = (length(c),)
Base.axes(c::DimColumn) = (Base.OneTo(length(c)),)
# Base.iterate(A::DimColumn, args...) = 
Base.vec(c::DimColumn{T}) where T = [c[i] for i in eachindex(c)]
Base.Array(c::DimColumn) = vec(c)

struct DimTable{A} <: Tables.AbstractColumns 
    array::A
end
array(dc::DimTable) = getfield(dc, :array)

for func in (:dims, :val, :index, :mode, :metadata, :order, :sampling, :span, :bounds, :locus, 
             :name, :shortname, :label, :units, :arrayorder, :indexorder, :relation)
    @eval ($func)(t::DimTable, args...) = ($func)(array(t), args...)
end

Tables.columnnames(c::DimTable) = _colnames(array(c))

_colnames(A) = begin
    arraykey = name(A) == "" ? :value : Symbol(name(A))
    dimkeys = map(dimkey, (dims(A)))
    # The data is always the last column
    (dimkeys..., arraykey)
end

Tables.schema(c::DimTable{T}) where T = Tables.Schema(array(c))

Tables.getcolumn(c::DimTable, key::Symbol) = Tables.getcolumn(array(c), key)
Tables.getcolumn(c::DimTable, i::Int) = Tables.getcolumn(array(c), i)
Tables.getcolumn(row, ::Type{T}, i::Int, key::Symbol) where T =
    Tables.getcolumn(row, key)


# This can move to primitives.jl
@inline dimstride(x, n) = dimstride(dims(x), n) 
@inline dimstride(::Nothing, n) = error("no dims Tuple available")
@inline dimstride(dims::DimTuple, d::DimOrDimType) = dimstride(dims, dimnum(dims, d)) 
@inline dimstride(dims::DimTuple, n::Int) = prod(map(length, dims)[1:n-1])
