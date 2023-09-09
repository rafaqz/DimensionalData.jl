"""
    AbstractDimTable <: Tables.AbstractColumns

Abstract supertype for dim tables
"""
abstract type AbstractDimTable <: Tables.AbstractColumns end

# Tables.jl interface for AbstractDimStack and AbstractDimArray

DimTableSources = Union{AbstractDimStack,AbstractDimArray}

Tables.istable(::Type{<:DimTableSources}) = true
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

function _colnames(s::AbstractDimStack)
    dimkeys = map(dim2key, (dims(s)))
    # The data is always the last column/s
    (dimkeys..., keys(s)...)
end


# DimColumn


"""
    DimColumn{T,D<:Dimension} <: AbstractVector{T}

    DimColumn(dim::Dimension, dims::Tuple{Vararg{DimTuple}})
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


# MergedDimColumn


struct MergedDimColumn{T,DS} <: AbstractVector{T}
    colname::Symbol
    dimcols::DS
end
function MergedDimColumn(dims::DS, name::Symbol) where DS
    MergedDimColumn{Tuple{map(eltype, dims)...},DS}(name, dims)
end

colname(c::MergedDimColumn) = getfield(c, :colname)
dimcols(c::MergedDimColumn) = getfield(c, :dimcols)

Base.length(c::MergedDimColumn) = length(first(dimcols(c)))
@inline function Base.getindex(c::MergedDimColumn{T}, i::Int) where T
    return map(x -> x[i], dimcols(c))
end
Base.getindex(c::MergedDimColumn, ::Colon) = vec(c)
Base.getindex(c::MergedDimColumn, A::AbstractArray) = [c[i] for i in A]
Base.size(c::MergedDimColumn) = (length(c),)
Base.axes(c::MergedDimColumn) = (Base.OneTo(length(c)),)
Base.vec(c::MergedDimColumn{T}) where T = [c[i] for i in eachindex(c)]
Base.Array(c::MergedDimColumn) = vec(c)


# DimArrayColumn


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


#DimTable


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
struct DimTable <: AbstractDimTable
    colnames::Vector{Symbol}
    dimcolumns::Vector{DimColumn}
    dimarraycolumns::Vector{DimArrayColumn}
end

function DimTable(s::AbstractDimStack; mergedims=nothing)
    s = isnothing(mergedims) ? s : DimensionalData.mergedims(s, mergedims)
    dims_ = dims(s)
    dimcolumns = collect(map(d -> DimColumn(d, dims_), dims_))
    dimarraycolumns = collect(map(A -> DimArrayColumn(A, dims(s)), s))

    keys = collect(_colnames(s))
    return DimTable(keys, dimcolumns, dimarraycolumns)
end

function DimTable(xs::Vararg{AbstractDimArray}; layernames=[Symbol("layer_$i") for i in eachindex(xs)], mergedims=nothing)
    # Construct DimColumns
    xs = isnothing(mergedims) ? xs : map(x -> DimensionalData.mergedims(x, mergedims), xs)
    dims_ = dims(first(xs))
    dimcolumns = collect(map(d -> DimColumn(d, dims_), dims_))
    dimnames = collect(map(dim2key, dims_))

    # Construct DimArrayColumns
    dimarraycolumns = collect(map(A -> DimArrayColumn(A, dims_), xs))

    colnames = vcat(dimnames, layernames)
    return DimTable(colnames, dimcolumns, dimarraycolumns)
end

function DimTable(x::AbstractDimArray; layersfrom=nothing, mergedims=nothing)
    if !isnothing(layersfrom) && (layersfrom <: Dimension) && (any(isa.(dims(x), layersfrom)))
        nlayers = size(x, layersfrom)
        layers = [(@view x[layersfrom(i)]) for i in 1:nlayers]
        layernames = Symbol.(["$(dim2key(layersfrom))_$i" for i in 1:nlayers])
        return DimTable(layers..., layernames=layernames, mergedims=mergedims)
    else
        # Construct DimColumns
        dims_ = dims(x)
        dimcolumns = map(d -> DimColumn(d, dims_), dims_)
        dimnames = collect(map(dim2key, dims_))

        # Construct DimArrayColumn
        dimarraycolumn = DimArrayColumn(x, dims_)

        # Merge DimColumns
        if mergedims
            colnames = vcat([:geometry], [:value])
            dimcol = MergedDimColumn(Tuple(dimcolumns), :geometry)
            return DimTable{typeof(dimcol)}(colnames, dimcol, [dimarraycolumn])
        else
            return DimTable{typeof(dimcolumns)}(vcat(dimnames, [:value]), dimcolumns, [dimarraycolumn])
        end
    end
end

dimcolumns(t::DimTable) = getfield(t, :dimcolumns)
dimarraycolumns(t::DimTable) = getfield(t, :dimarraycolumns)
dims(t::DimTable) = dims(parent(t))

Base.parent(t::DimTable) = getfield(t, :colnames)

for func in (:dims, :val, :index, :lookup, :metadata, :order, :sampling, :span, :bounds,
             :locus, :name, :label, :units)
    @eval $func(t::DimTable, args...) = $func(parent(t), args...)

end

Tables.istable(::DimTable) = true
Tables.columnaccess(::Type{<:DimTable}) = true
Tables.columns(t::DimTable) = t
Tables.columnnames(c::DimTable) = parent(c)

function Tables.schema(t::DimTable) 
    colnames = parent(t)
    types = vcat([map(eltype, dimcolumns(t))...], [map(eltype, dimarraycolumns(t))...])
    Tables.Schema(colnames, types)
end

@inline function Tables.getcolumn(t::DimTable, key::Symbol)
    keys = parent(t)
    i = findfirst(==(key), keys)
    n_dimcols = length(dimcolumns(t))
    if i <= n_dimcols
        return dimcolumns(t)[i]
    else
        return dimarraycolumns(t)[i - n_dimcols]
    end
end

@inline function Tables.getcolumn(t::DimTable, ::Type{T}, i::Int, key::Symbol) where T
    Tables.getcolumn(t, key)
end


# TableTraits.jl interface


function IteratorInterfaceExtensions.getiterator(x::DimTableSources)
    return Tables.datavaluerows(Tables.dictcolumntable(x))
end
IteratorInterfaceExtensions.isiterable(::DimTableSources) = true
TableTraits.isiterabletable(::DimTableSources) = true

function IteratorInterfaceExtensions.getiterator(t::DimTable)
    return Tables.datavaluerows(Tables.dictcolumntable(t))
end
IteratorInterfaceExtensions.isiterable(::DimTable) = true
TableTraits.isiterabletable(::DimTable) = true


function fromtable(table, dims)
    @time xlookup = enumerate(dims[1]) .|> reverse |> Dict
    @time ylookup = enumerate(dims[2]) .|> reverse |> Dict

    dst = zeros(Float32, size(dims))
    geoms = collect(table.geometry)
    vals = collect(table.band_1)
    for i in eachindex(geoms)
        (x, y) = geoms[i]
        dst[xlookup[x],ylookup[y]] = vals[i]
    end
    return dst
end

function getindices(vals, ref)
    i = 1
    n = length(ref)
    indices = Int64[]
    for val in vals
        while (i <= n) && (val != ref[i])
            i += 1
        end
        push!(indices, i)
    end
    return indices
end

function fromtable(geoms, vals, dims)
    @time dst = zeros(Float32, length(dims))
    @time sortedvals = sort(zip(geoms, vals), by=(reverse ∘ first))
    @time indices = DD.getindices(first.(sortedvals), dims)
    @time dst[indices] .= last.(sortedvals)
    return dst
end