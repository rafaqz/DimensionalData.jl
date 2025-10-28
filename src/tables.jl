# This lets use switch array of NamedTupleto NamedTuple of Array
struct LayerArray{K,T,N,A} <: AbstractArray{T,N}
    data::A
end
function LayerArray{K}(a::A) where {A<:AbstractArray{<:NamedTuple,N}} where {K,N}
    T = typeof(a[1][K])
    LayerArray{K,T,N,A}(a)
end
Base.parent(A::LayerArray) = parent(A.data)
Base.size(A::LayerArray) = size(parent(A))
@propagate_inbounds Base.getindex(A::LayerArray{K}, I::Integer...) where K =
    getproperty(getindex(parent(A), I...), K)

function layerarrays(A::AbstractDimArray{<:NamedTuple{K}}) where K
    map(K) do k
        rebuild(A; data=LayerArray{k}(A))
    end |> NamedTuple{K}
end

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
@inline Tables.getcolumn(x::DimTableSources, key::DimOrDimType) =
    Tables.getcolumn(DimTable(x), key)

_colnames(s::AbstractDimStack) = _colnames(s, dims(s))
function _colnames(s::AbstractDimStack, alldims::Tuple)
    dimkeys = map(name, alldims)
    # The data is always the last column/s
    (dimkeys..., keys(s)...)
end
function _colnames(A::AbstractDimArray)
    n = Symbol(name(A)) == Symbol("") ? :value : Symbol(name(A))
    (map(name, dims(A))..., n)
end
_colnames(A::AbstractDimArray{T}) where T<:NamedTuple =
    (map(name, dims(A))..., _colnames(T)...)
_colnames(::Type{<:NamedTuple{Keys}}) where Keys = Keys

# DimTable

"""
    DimTable <: AbstractDimTable

    DimTable(s::AbstractDimStack; mergedims=nothing[, refdims])
    DimTable(x::AbstractDimArray; layersfrom=nothing, mergedims=nothing[, refdims])
    DimTable(xs::Vararg{AbstractDimArray}; layernames=nothing, mergedims=nothing[, refdims])

Construct a Tables.jl/TableTraits.jl compatible object out of an `AbstractDimArray` or `AbstractDimStack`.

This table will have columns for the array data and columns for each
`Dimension` lookup, as a [`DimColumn`]. These are lazy, and generated
as required.

Column names are converted from the dimension types using
[`DimensionalData.name`](@ref). This means type `Ti` becomes the
column name `:Ti`, and `Dim{:custom}` becomes `:custom`.

To get dimension columns, you can index with `Dimension` (`X()`) or
`Dimension` type (`X`) as well as the regular `Int` or `Symbol`.

# Keywords
- `mergedims`: Combine two or more dimensions into a new dimension.
- `preservedims`: Preserve one or more dimensions from flattening into the table.
    `DimArray`s of views with these dimensions will be present in the layer column,
    rather than scalar values.
- `layersfrom`: Treat a dimension of an `AbstractDimArray` as layers of an `AbstractDimStack`
    by specifying a dimension to use as layers.
- `refdims`: Additional reference dimensions to add to the table, defaults to `()`.

# Example

Here we generate a GeoInterface.jl compatible table with `:geometry`
column made of `(X, Y)` points, and data columns from `:band` slices.

```julia
julia> using DimensionalData, Tables

julia> A = ones(X(4), Y(3), Dim{:band}('a':'d'); name=:data);

julia> DimTable(A; layersfrom=:band, mergedims=(X, Y)=>:geometry)
DimTable with 12 rows, 5 columns, and schema:
 :geometry  Tuple{Int64, Int64}
 :band_a    Float64
 :band_b    Float64
 :band_c    Float64
 :band_d    Float64
```

And here bands for each X/Y position are kept as vectors, using `preservedims`.
This may be useful if e.g. bands are color components of spectral images.

```julia
julia> DimTable(A; preservedims=:band)
DimTable with 12 rows, 3 columns, and schema:
 :X     …  Int64
 :Y        Int64
 :data     DimVector{Float64, Tuple{Dim{:band, Categorical{Char, StepRange{Char, Int64}, ForwardOrdered, NoMetadata}}}, Tuple{X{NoLookup{UnitRange{Int64}}}, Y{NoLookup{UnitRange{Int64}}}}, SubArray{Float64, 1, Array{Float64, 3}, Tuple{Int64, Int64, Slice{OneTo{Int64}}}, true}, Symbol, NoMetadata} (alias for DimArray{Float64, 1, Tuple{Dim{:band, DimensionalData.Dimensions.Lookups.Categorical{Char, StepRange{Char, Int64}, DimensionalData.Dimensions.Lookups.ForwardOrdered, DimensionalData.Dimensions.Lookups.NoMetadata}}}, Tuple{X{DimensionalData.Dimensions.Lookups.NoLookup{UnitRange{Int64}}}, Y{DimensionalData.Dimensions.Lookups.NoLookup{UnitRange{Int64}}}}, SubArray{Float64, 1, Array{Float64, 3}, Tuple{Int64, Int64, Base.Slice{Base.OneTo{Int64}}}, true}, Symbol, DimensionalData.Dimensions.Lookups.NoMetadata})
```

```julia
julia> DimTable(A[X(3), Y(2)]; refdims=(X(3:3), Y(2:2)))  # slice X and Y and add the reference dimensions
DimTable with 3 rows, 4 columns, and schema:
 :band   Int64
 :X      Int64
 :Y      Int64
 :value  Float64
```
"""
struct DimTable{Mode} <: AbstractDimTable
    parent::Union{AbstractDimArray,AbstractDimStack}
    dims::Tuple{Vararg{Dimension}}
    colnames::Vector{Symbol}
    dimcolumns::Vector{AbstractVector}
    dimarraycolumns::Vector
end
function DimTable(s::AbstractDimStack;
    mergedims=nothing,
    preservedims=nothing,
    refdims=(),
)
    s = isnothing(mergedims) ? s : DD.mergedims(s, mergedims)
    s = if isnothing(preservedims)
        s
    else
        maplayers(s) do A
            _maybe_presevedims(A, preservedims)
        end
    end
    alldims = combinedims(dims(s), refdims)
    dimcolumns = collect(_dimcolumns(alldims))
    dimarraycolumns = if hassamedims(s) && isempty(refdims)
        map(vec, layers(s))
    else
        map(A -> vec(DimExtensionArray(A, alldims)), layers(s))
    end |> collect
    keys = collect(_colnames(s, alldims))
    return DimTable{Columns}(s, alldims, keys, dimcolumns, dimarraycolumns)
end
function DimTable(As::AbstractVector{<:AbstractDimArray};
    layernames=nothing,
    mergedims=nothing,
    preservedims=nothing,
    refdims=(),
)
    # Check that dims are compatible
    comparedims(As)
    # Construct Layer Names
    layernames = isnothing(layernames) ? uniquekeys(As) : layernames
    # Construct dimension and array columns with DimExtensionArray
    As = isnothing(mergedims) ? As : map(x -> DimensionalData.mergedims(x, mergedims), As)
    As = if isnothing(preservedims)
        As
    else
        map(As) do A
            _maybe_presevedims(A, preservedims)
        end
    end
    alldims = combinedims(dims(first(As)), refdims)
    dimcolumns = collect(_dimcolumns(alldims))
    dimnames = collect(map(name, alldims))
    dimarraycolumns = collect(map(vec ∘ parent, As))
    colnames = vcat(dimnames, layernames)

    # Return DimTable
    return DimTable{Columns}(first(As), alldims, colnames, dimcolumns, dimarraycolumns)
end
function DimTable(A::AbstractDimArray;
    layersfrom=nothing,
    mergedims=nothing,
    preservedims=nothing,
    refdims=(),
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
        return DimTable(layers; layernames, mergedims, preservedims, refdims)
    else
        A1 = isnothing(mergedims) ? A : DD.mergedims(A, mergedims)
        if eltype(A1) <: NamedTuple
            if isnothing(preservedims)
                alldims = combinedims(dims(A1), refdims)
                dimcolumns = collect(_dimcolumns(A1))
                colnames = collect(_colnames(A1))
                dimarrayrows = vec(parent(A1))
                return DimTable{Rows}(A1, alldims, colnames, dimcolumns, dimarrayrows)
            else
                las = layerarrays(A1)
                layernames = collect(keys(las))
                return DimTable(collect(las); layernames, mergedims, preservedims, refdims)
            end
        else
            A2 = _maybe_presevedims(A1, preservedims)
            alldims = combinedims(dims(A2), refdims)
            dimcolumns = collect(_dimcolumns(A2))
            colnames = collect(_colnames(A2))
            dimarraycolumns = [vec(parent(A2))]
            return DimTable{Columns}(A2, alldims, colnames, dimcolumns, dimarraycolumns)
        end
    end
end

_maybe_presevedims(A, preservedims::Nothing) = A
function _maybe_presevedims(A, preservedims)
    S = DimSlices(A; dims=otherdims(A, preservedims))
    rebuild(A; data=OpaqueArray(S), dims=dims(S))
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

for func in (:dims, :val, :metadata, INTERFACE_QUERY_FUNCTION_NAMES...)
    @eval $func(t::DimTable, args...) = $func(parent(t), args...)
end

_dims(t::DimTable) = getfield(t, :dims)

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
    if i > length(_dims(t))
        dimarraycolumns(t)[i - length(_dims(t))]
    elseif i > 0 && i < nkeys
        dimcolumns(t)[i]
    else
        throw(ArgumentError("There is no table column $i"))
    end
end
@inline function Tables.getcolumn(t::DimTable, dim::Union{Dimension,Type{<:Dimension}})
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
