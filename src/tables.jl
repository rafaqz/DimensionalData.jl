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
    dimkeys = map(name, dims(s))
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

# Example

Here we generate a GeoInterface.jl compatible table with `:geometry` 
column made of `(X, Y)` points, and data columns from `:band` slices.

```jldoctest tables
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

```jldoctest tables
julia> DimTable(A; preservedims=:band)
DimTable with 12 rows, 3 columns, and schema:
 :X     …  Int64
 :Y        Int64
 :data     DimVector{Float64, Tuple{Dim{:band, Categorical{Char, StepRange{Char, Int64}, ForwardOrdered, NoMetadata}}}, Tuple{X{NoLookup{UnitRange{Int64}}}, Y{NoLookup{UnitRange{Int64}}}}, SubArray{Float64, 1, Array{Float64, 3}, Tuple{Int64, 
Int64, Slice{OneTo{Int64}}}, true}, Symbol, NoMetadata} (alias for DimArray{Float64, 1, Tuple{Dim{:band, Categorical{Char, StepRange{Char, Int64}, ForwardOrdered, NoMetadata}}}, Tuple{X{NoLookup{UnitRange{Int64}}}, Y{NoLookup{UnitRange{Int64}}}}, SubArray{Float64, 1, Array{Float64, 3}, Tuple{Int64, Int64, Base.Slice{Base.OneTo{Int64}}}, true}, Symbol, NoMetadata})
````

With no keywords, all data is flattened to a single column, 
and all dimensions are included as columns, unrolled to match
the length of the data.

```jldoctest tables
julia> DimTable(A)
DimTable with 48 rows, 4 columns, and schema:
 :X     Int64
 :Y     Int64
 :band  Char
 :data  Float64
"""
struct DimTable <: AbstractDimTable
    parent::Union{AbstractDimArray,AbstractDimStack}
    colnames::Vector{Symbol}
    dimcolumns::Vector{AbstractVector}
    dimarraycolumns::Vector{AbstractVector}
end

function DimTable(s::AbstractDimStack; 
    mergedims=nothing,
    preservedims=nothing,
)
    s = isnothing(mergedims) ? s : DD.mergedims(s, mergedims)
    s = if isnothing(preservedims) 
        s
    else
        maplayers(s) do A
            S = DimSlices(A; dims=otherdims(A, preservedims))
            dimconstructor(dims(S))(OpaqueArray(S), dims(S))
        end
    end
    dimcolumns = collect(_dimcolumns(s))
    dimarraycolumns = if hassamedims(s)
        map(vec, layers(s))
    else
        map(A -> vec(DimExtensionArray(A, dims(s))), layers(s))
    end |> collect
    keys = collect(_colnames(s))
    return DimTable(s, keys, dimcolumns, dimarraycolumns)
end
function DimTable(xs::Vararg{AbstractDimArray}; 
    layernames=nothing, mergedims=nothing, preservedims=nothing
)
    # Check that dims are compatible
    comparedims(xs...)

    # Construct Layer Names
    layernames = isnothing(layernames) ? [Symbol("layer_$i") for i in eachindex(xs)] : layernames

    # Construct dimension and array columns with DimExtensionArray
    xs = isnothing(mergedims) ? xs : map(x -> DimensionalData.mergedims(x, mergedims), xs)
    xs = if isnothing(preservedims)
        xs
    else
        map(xs) do A
            S = DimSlices(A; dims=otherdims(A, preservedims))
            dimconstructor(dims(S))(OpaqueArray(S), dims(S))
        end
    end
    dims_ = dims(first(xs))
    dimcolumns = collect(_dimcolumns(dims_))
    dimnames = collect(map(name, dims_))
    dimarraycolumns = collect(map(vec ∘ parent, xs))
    colnames = vcat(dimnames, layernames)

    # Return DimTable
    return DimTable(first(xs), colnames, dimcolumns, dimarraycolumns)
end
function DimTable(x::AbstractDimArray; 
    layersfrom=nothing, mergedims=nothing, kw...
)
    if !isnothing(layersfrom) && any(hasdim(x, layersfrom))
        d = dims(x, layersfrom)
        nlayers = size(x, d)
        layers = [view(x, rebuild(d, i)) for i in 1:nlayers]
        layernames = if iscategorical(d)
            Symbol.((name(d),), '_', lookup(d))
        else
            Symbol.(("$(name(d))_$i" for i in 1:nlayers))
        end
        return DimTable(layers...; layernames, mergedims, kw...)
    else
        s = name(x) == NoName() ? DimStack((;value=x)) : DimStack(x)
        return  DimTable(s; mergedims, kw...)
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
