# Tables.jl interface
# https://juliadata.github.io/Tables.jl/stable/



# DimArray tables interface 

# Declare that your table type implements the interface
Tables.istable(::Type{<:AbstractDimArray}) = true
Tables.istable(::AbstractDimArray) = true
Tables.columnaccess(::Type{<:AbstractDimArray}) = true
Tables.columns(A::AbstractDimArray) = DimTable(A)
Tables.columnnames(A::AbstractDimArray) = _colnames(A)
Tables.schema(A::AbstractDimArray{T}) where T = 
    Tables.Schema(_colnames(A), (map(eltype, dims(A))..., T))


# DimColumn

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



# DimTable

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

Tables.columnnames(c::DimTable{Keys}) where Keys = Keys
Tables.schema(t::DimTable{Keys}) where Keys = begin
    A = array(t)
    Tables.Schema(Keys, (map(eltype, dims(A))..., eltype(A)))
end

@inline Tables.getcolumn(t::DimTable{Keys}, i::Int) where Keys = begin
    nkeys = length(Keys) 
    if i == nkeys
        vec(parent(array(t)))
    elseif i < nkeys
        dimcolumns(t)[i]
    else
        error("There is no column $i")
    end
end
# Retrieve a column by name
@inline Tables.getcolumn(t::DimTable{Keys}, key::Symbol) where Keys = begin
    if key == last(Keys)
        vec(parent(array(t)))
    else
        dimcolumns(t)[dimnum(dims(t), key)]
    end
end
@inline Tables.getcolumn(row, ::Type{T}, i::Int, key::Symbol) where T =
    Tables.getcolumn(row, key)


_colnames(A) = begin
    arraykey = name(A) == "" ? :value : Symbol(name(A))
    dimkeys = map(dimkey, (dims(A)))
    # The data is always the last column
    (dimkeys..., arraykey)
end


# This can move to primitives.jl
@inline dimstride(x, n) = dimstride(dims(x), n) 
@inline dimstride(::Nothing, n) = error("no dims Tuple available")
@inline dimstride(dims::DimTuple, d::DimOrDimType) = dimstride(dims, dimnum(dims, d)) 
@inline dimstride(dims::DimTuple, n::Int) = prod(map(length, dims)[1:n-1])
