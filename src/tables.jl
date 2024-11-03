"""
    AbstractDimTable <: Tables.AbstractColumns

Abstract supertype for dim tables
"""
abstract type AbstractDimTable <: Tables.AbstractColumns end

struct Columns end
struct Rows end

# Tables.jl interface for AbstractDimStack and AbstractDimArray

DimTableSources = Union{AbstractDimStack,AbstractDimArray}

Tables.istable(::Type{<:DimTableSources}) = true
Tables.columnaccess(::Type{<:DimTableSources}) = true
Tables.columns(x::DimTableSources) = DimTable(x)
Tables.columnnames(x::DimTableSources) = _colnames(x)
Tables.schema(x::DimTableSources) = Tables.schema(DimTable(x))

@inline Tables.getcolumn(x::DimTableSources, i::Int) = Tables.getcolumn(DimTable(x), i)
@inline Tables.getcolumn(x::DimTableSources, key::Symbol) =
    Tables.getcolumn(DimTable(x), key)
@inline Tables.getcolumn(x::DimTableSources, ::Type{T}, i::Int, key::Symbol) where T =
    Tables.getcolumn(DimTable(x), T, i, key)
@inline Tables.getcolumn(t::DimTableSources, dim::DimOrDimType) =
    Tables.getcolumn(t, dimnum(t, dim))

_colnames(s::AbstractDimStack) = (map(name, dims(s))..., keys(s)...)
function _colnames(A::AbstractDimArray)
    n = Symbol(name(A)) == Symbol("") ? :value : Symbol(name(A))
    (map(name, dims(A))..., n)
end
_colnames(A::AbstractDimVector{T}) where T<:NamedTuple = 
    (map(name, dims(A))..., _colnames(T)...)
_colnames(::Type{<:NamedTuple{Keys}}) where Keys = Keys

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
[`DimensionalData.name`](@ref). This means type `Ti` becomes the
column name `:Ti`, and `Dim{:custom}` becomes `:custom`.

To get dimension columns, you can index with `Dimension` (`X()`) or
`Dimension` type (`X`) as well as the regular `Int` or `Symbol`.

# Keywords
- `mergedims`: Combine two or more dimensions into a new dimension.
- `layersfrom`: Treat a dimension of an `AbstractDimArray` as layers of an `AbstractDimStack`.

# Example

```jldoctest
julia> using DimensionalData, Tables

julia> a = DimArray(ones(16, 16, 3), (X, Y, Dim{:band}))
╭─────────────────────────────╮
│ 16×16×3 DimArray{Float64,3} │
├─────────────────────── dims ┤
  ↓ X, → Y, ↗ band
└─────────────────────────────┘
[:, :, 1]
 1.0  1.0  1.0  1.0  1.0  1.0  1.0  1.0  …  1.0  1.0  1.0  1.0  1.0  1.0  1.0
 1.0  1.0  1.0  1.0  1.0  1.0  1.0  1.0     1.0  1.0  1.0  1.0  1.0  1.0  1.0
 1.0  1.0  1.0  1.0  1.0  1.0  1.0  1.0     1.0  1.0  1.0  1.0  1.0  1.0  1.0
 1.0  1.0  1.0  1.0  1.0  1.0  1.0  1.0     1.0  1.0  1.0  1.0  1.0  1.0  1.0
 1.0  1.0  1.0  1.0  1.0  1.0  1.0  1.0     1.0  1.0  1.0  1.0  1.0  1.0  1.0
 1.0  1.0  1.0  1.0  1.0  1.0  1.0  1.0  …  1.0  1.0  1.0  1.0  1.0  1.0  1.0
 1.0  1.0  1.0  1.0  1.0  1.0  1.0  1.0     1.0  1.0  1.0  1.0  1.0  1.0  1.0
 1.0  1.0  1.0  1.0  1.0  1.0  1.0  1.0     1.0  1.0  1.0  1.0  1.0  1.0  1.0
 1.0  1.0  1.0  1.0  1.0  1.0  1.0  1.0     1.0  1.0  1.0  1.0  1.0  1.0  1.0
 1.0  1.0  1.0  1.0  1.0  1.0  1.0  1.0     1.0  1.0  1.0  1.0  1.0  1.0  1.0
 1.0  1.0  1.0  1.0  1.0  1.0  1.0  1.0  …  1.0  1.0  1.0  1.0  1.0  1.0  1.0
 1.0  1.0  1.0  1.0  1.0  1.0  1.0  1.0     1.0  1.0  1.0  1.0  1.0  1.0  1.0
 1.0  1.0  1.0  1.0  1.0  1.0  1.0  1.0     1.0  1.0  1.0  1.0  1.0  1.0  1.0
 1.0  1.0  1.0  1.0  1.0  1.0  1.0  1.0     1.0  1.0  1.0  1.0  1.0  1.0  1.0
 1.0  1.0  1.0  1.0  1.0  1.0  1.0  1.0     1.0  1.0  1.0  1.0  1.0  1.0  1.0
 1.0  1.0  1.0  1.0  1.0  1.0  1.0  1.0  …  1.0  1.0  1.0  1.0  1.0  1.0  1.0

julia>

```
"""
struct DimTable{Mode} <: AbstractDimTable
    parent::Union{AbstractDimArray,AbstractDimStack}
    colnames::Vector{Symbol}
    dimcolumns::Vector{AbstractVector}
    dimarraycolumns::Vector
end

function DimTable(s::AbstractDimStack;
    mergedims=nothing,
)
    s = isnothing(mergedims) ? s : DD.mergedims(s, mergedims)
    dimcolumns = collect(_dimcolumns(s))
    dimarraycolumns = if hassamedims(s)
        map(vec, layers(s))
    else
        map(A -> vec(DimExtensionArray(A, dims(s))), layers(s))
    end |> collect
    keys = collect(_colnames(s))
    return DimTable{Columns}(s, keys, dimcolumns, dimarraycolumns)
end
function DimTable(As::Vararg{AbstractDimArray};
    layernames=nothing,
    mergedims=nothing,
)
    # Check that dims are compatible
    comparedims(As...)
    # Construct Layer Names
    layernames = isnothing(layernames) ? uniquekeys(As) : layernames
    # Construct dimension and array columns with DimExtensionArray
    As = isnothing(mergedims) ? As : map(x -> DD.mergedims(x, mergedims), As)
    dims_ = dims(first(As))
    dimcolumns = collect(_dimcolumns(dims_))
    dimnames = collect(map(name, dims_))
    dimarraycolumns = collect(map(vec ∘ parent, As))
    colnames = vcat(dimnames, layernames)

    # Return DimTable
    return DimTable{Columns}(first(As), colnames, dimcolumns, dimarraycolumns)
end
function DimTable(A::AbstractDimArray;
    layersfrom=nothing,
    mergedims=nothing,
)
    if !isnothing(layersfrom) && any(hasdim(A, layersfrom))
        d = dims(A, layersfrom)
        nlayers = size(A, d)
        layers = [view(A, rebuild(d, i)) for i in 1:nlayers]
        layernames = if iscategorical(d)
            Symbol.((name(d),), '_', lookup(d))
        else
            Symbol.(("$(name(d))_$i" for i in 1:nlayers))
        end
        return DimTable(layers...; layernames, mergedims)
    else
        A = isnothing(mergedims) ? A : DD.mergedims(A, mergedims)
        dimcolumns = collect(_dimcolumns(A))
        colnames = collect(_colnames(A))
        if (ndims(A) == 1) && (eltype(A) <: NamedTuple)
            dimarrayrows = parent(A)
            return DimTable{Rows}(A, colnames, dimcolumns, dimarrayrows)
        else
            dimarraycolumns = [vec(parent(A))]
            @show colnames dimcolumns dimarraycolumns
            return DimTable{Columns}(A, colnames, dimcolumns, dimarraycolumns)
        end
    end
end

_dimcolumns(x) = map(d -> _dimcolumn(x, d), dims(x))
function _dimcolumn(x, d::Dimension)
    lookupvals = parent(lookup(d))
    if length(dims(x)) == 1
        lookupvals
    else
        dim_as_dimarray = DimArray(lookupvals, d)
        vec(DimExtensionArray(dim_as_dimarray, dims(x)))
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
    types = vcat([map(eltype, dimcolumns(t))...], _dimarraycolumn_eltypes(t))
    Tables.Schema(colnames(t), types)
end

_dimarraycolumn_eltypes(t::DimTable{Columns}) = [map(eltype, dimarraycolumns(t))...]
_dimarraycolumn_eltypes(t::DimTable{Rows}) = _eltypes(eltype(dimarraycolumns(t)))
_eltypes(::Type{T}) where T<:NamedTuple = collect(T.types)

@inline function Tables.getcolumn(t::DimTable{Rows}, i::Int)
    nkeys = length(colnames(t))
    if i > length(dims(t))
        map(nt -> nt[i], dimarraycolumns(t))
    elseif i > 0 && i < nkeys
        dimcolumns(t)[i]
    else
        throw(ArgumentError("There is no table column $i"))
    end
end
@inline function Tables.getcolumn(t::DimTable{Columns}, i::Int)
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
@inline function Tables.getcolumn(t::DimTable{Rows}, key::Symbol)
    key in colnames(t) || throw(ArgumentError("There is no table column $key"))
    if hasdim(parent(t), key)
        dimcolumns(t)[dimnum(t, key)]
    else
        # Function barrier
        _col_from_rows(dimarraycolumns(t), key)
    end
end
@inline function Tables.getcolumn(t::DimTable{Columns}, key::Symbol)
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

_col_from_rows(rows, key) = map(row -> row[key], rows) 

# TableTraits.jl interface
TableTraits.isiterabletable(::DimTableSources) = true
TableTraits.isiterabletable(::DimTable) = true

# IteratorInterfaceExtensions.jl interface
IteratorInterfaceExtensions.getiterator(x::DimTableSources) =
    Tables.datavaluerows(Tables.dictcolumntable(x))
IteratorInterfaceExtensions.getiterator(t::DimTable) =
    Tables.datavaluerows(Tables.dictcolumntable(t))
IteratorInterfaceExtensions.isiterable(::DimTableSources) = true
IteratorInterfaceExtensions.isiterable(::DimTable) = true
