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
    dimkeys = map(dim2key, dims(s))
    # The data is always the last column/s
    (dimkeys..., keys(s)...)
end

# DimTable

"""
    DimTable <: AbstractDimTable

    DimTable(s::AbstractDimStack; mergedims=nothing)
    DimTable(x::AbstractDimArray; layersfrom=nothing, mergedims=nothing)
    DimTable(xs::Vararg{AbstractDimArray}; layernames=nothing, mergedims=nothing)

Construct a Tables.jl/TableTraits.jl compatible object out of an `AbstractDimArray` or `AbstractDimStack`.

This table will have columns for the array data and columns for each
`Dimension` index, as a [`DimColumn`]. These are lazy, and generated
as required.

Column names are converted from the dimension types using
[`DimensionalData.dim2key`](@ref). This means type `Ti` becomes the
column name `:Ti`, and `Dim{:custom}` becomes `:custom`.

To get dimension columns, you can index with `Dimension` (`X()`) or
`Dimension` type (`X`) as well as the regular `Int` or `Symbol`.

# Keywords
- `mergedims`: Combine two or more dimensions into a new dimension.
- `layersfrom`: Treat a dimension of an `AbstractDimArray` as layers of an `AbstractDimStack`.

# Example
```jldoctest
julia> a = DimArray(rand(32,32,3), (X,Y,Dim{:band}));

julia> DimTable(a, layersfrom=Dim{:band}, mergedims=(X,Y)=>:geometry)
DimTable with 1024 rows, 4 columns, and schema:
 :geometry  Tuple{Int64, Int64}
 :band_1    Float64
 :band_2    Float64
 :band_3    Float64
```
"""
struct DimTable <: AbstractDimTable
    parent::Union{AbstractDimArray,AbstractDimStack}
    colnames::Vector{Symbol}
    dimcolumns::Vector{AbstractVector}
    dimarraycolumns::Vector{AbstractVector}
end

function DimTable(s::AbstractDimStack; mergedims=nothing)
    s = isnothing(mergedims) ? s : DD.mergedims(s, mergedims)
    dimcolumns = collect(_dimcolumns(s))
    dimarraycolumns = if hassamedims(s)
        map(vec, layers(s))
    else
        map(A -> vec(DimExtensionArray(A, dims(s))), layers(s))
    end |> collect
    keys = collect(_colnames(s))
    return DimTable(s, keys, dimcolumns, dimarraycolumns)
end

_dimcolumns(x) = map(d -> _dimcolumn(x, d), dims(x))
function _dimcolumn(x, d::Dimension)
    dim_as_dimarray = DimArray(index(d), d)
    vec(DimExtensionArray(dim_as_dimarray, dims(x)))
end

function DimTable(xs::Vararg{AbstractDimArray}; layernames=nothing, mergedims=nothing)
    # Check that dims are compatible
    comparedims(xs...)

    # Construct Layer Names
    layernames = isnothing(layernames) ? [Symbol("layer_$i") for i in eachindex(xs)] : layernames

    # Construct dimwnsion and array columns with DimExtensionArray
    xs = isnothing(mergedims) ? xs : map(x -> DimensionalData.mergedims(x, mergedims), xs)
    dims_ = dims(first(xs))
    dimcolumns = collect(_dimcolumns(dims_))
    dimnames = collect(map(dim2key, dims_))
    dimarraycolumns = collect(map(vec ∘ parent, xs))
    colnames = vcat(dimnames, layernames)

    # Return DimTable
    return DimTable(first(xs), colnames, dimcolumns, dimarraycolumns)
end

function DimTable(x::AbstractDimArray; layersfrom=nothing, mergedims=nothing)
    if !isnothing(layersfrom) && any(hasdim(x, layersfrom))
        d = dims(x, layersfrom)
        nlayers = size(x, d)
        layers = [view(x, rebuild(d, i)) for i in 1:nlayers]
        layernames = if iscategorical(d)
            Symbol.(Ref(dim2key(d)), '_', lookup(d))
        else
            Symbol.(("$(dim2key(d))_$i" for i in 1:nlayers))
        end
        return DimTable(layers..., layernames=layernames, mergedims=mergedims)
    else
        s = name(x) == NoName() ? DimStack((;value=x)) : DimStack(x)
        return  DimTable(s, mergedims=mergedims)
    end
end

dimcolumns(t::DimTable) = getfield(t, :dimcolumns)
dimarraycolumns(t::DimTable) = getfield(t, :dimarraycolumns)
colnames(t::DimTable) = Tuple(getfield(t, :colnames))

Base.parent(t::DimTable) = getfield(t, :parent)

for func in (:dims, :val, :index, :lookup, :metadata, :order, :sampling, :span, :bounds,
             :locus, :name, :label, :units)
    @eval $func(t::DimTable, args...) = $func(parent(t), args...)

end

Tables.istable(::DimTable) = true
Tables.columnaccess(::Type{<:DimTable}) = true
Tables.columns(t::DimTable) = t
Tables.columnnames(c::DimTable) = colnames(c)

function Tables.schema(t::DimTable)
    types = vcat([map(eltype, dimcolumns(t))...], [map(eltype, dimarraycolumns(t))...])
    Tables.Schema(colnames(t), types)
end

@inline function Tables.getcolumn(t::DimTable, i::Int)
    nkeys = length(colnames(t))
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

@inline function Tables.getcolumn(t::DimTable, key::Symbol)
    keys = colnames(t)
    i = findfirst(==(key), keys)
    if isnothing(i)
        throw(ArgumentError("There is no table column $key"))
    else
        return Tables.getcolumn(t, i)
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
