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
#	Retrieve a column by index
Tables.getcolumn(A::AbstractDimArray{T,N}, i::Int) where {T,N} = begin
    if i == N + 1
        vec(parent(A))
    elseif i <= N
        dim = dims(A, i)
        DimColumn(dim, A)
    else
        error("There is no column $i")
    end
end
# Retrieve a column by name
Tables.getcolumn(A::AbstractDimArray, nm::Symbol) = begin
    if nm == Symbol(name(A)) || nm == :value
        vec(parent(A))
    else
        dim = dims(A, dimtypeof(nm))
        DimColumn(dim, A)
    end
end

# a custom row type; acts as a "view" into a row of an AbstractMatrix
struct DimColumn{T,D<:Dimension,A<:AbstractArray} <: AbstractVector{T}
    dim::D
    array::A
    stride::Int
    DimColumn(dim::D, array::A) where {D<:Dimension,A<:AbstractDimArray} = begin
        dnum = dimnum(array, dim)
        # This is the apparent stride for indexing purposes, 
        # which is not always the real stride
        stride = reduce((x, y) -> x * y, size(dim)[1:dnum-1]; init=1)
        new{eltype(dim),D,A}(dim, array, stride)
    end
end

array(c::DimColumn) = getfield(c, :array)
dim(c::DimColumn) = getfield(c, :dim)
stride(c::DimColumn) = getfield(c, :stride)
dimnum(c::DimColumn) = dimnum(array(c), dim(c))

Base.getindex(c::DimColumn, i) = dim(c)[mod((i - 1) ÷ stride(c), length(dim(c))) + 1]
Base.length(c::DimColumn) = length(array(c))
Base.size(c::DimColumn) = (length(array(c)),)
Base.axes(c::DimColumn) = (Base.OneTo(length(array(c))),)
# Base.iterate(A::DimColumn, args...) = 
# Base.IndexStyle(A::DimColumn) = Base.IndexStyle(parent(A))
# Base.parent(A::DimColumn) = index(dim(A))
Base.vec(c::DimColumn{T}) where T = [c[i] for i in eachindex(c)]
Base.Array(c::DimColumn) = vec(c)

_nreps(c::DimColumn) = _nreps(dim(c), array(c))
_nreps(dim::Dimension, A::AbstractDimArray) = (length(A) ÷ length(dim))


struct DimTable{A} <: Tables.AbstractColumns 
    array::A
end
array(dc::DimTable) = getfield(dc, :array)

for func in (:dims, :val, :index, :mode, :metadata, :order, :sampling, :span, :bounds, :locus, 
             :name, :shortname, :label, :units, :arrayorder, :indexorder, :relation)
    @eval ($func)(t::DimTable, args...) = ($func)(array(t), args...)
end

Tables.columnnames(c::DimTable) = _colnames(array(c))
Tables.schema(c::DimTable{T}) where T = Tables.Schema(array(c))
Tables.getcolumn(c::DimTable, x::Symbol) = Tables.getcolumn(array(c), x)
Tables.getcolumn(c::DimTable, x::Int) = Tables.getcolumn(array(c), x)
Tables.getcolumn(row, ::Type{T}, i::Int, nm::Symbol) where T =
    Tables.getcolumn(row, T, i, nm)
Tables.columnnames(c::DimTable) = _colnames(array(c))

_colnames(A) = begin
    arraykey = name(A) == "" ? :value : Symbol(name(A))
    dimkeys = map(dimkey, (dims(A)))
    # The data is always the last column
    (dimkeys..., arraykey)
end

# Given a column eltype T, index i, and column name nm, retrieve the column. Provides a type-stable or even constant-prop-able mechanism for efficiency.
# Tables.getcolumn(table, ::Type{T}, i::Int, nm::Symbol)	
