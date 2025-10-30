"""
    AbstractDimStack

Abstract supertype for dimensional stacks.

These have multiple layers of data, but share dimensions.

Notably, their behaviour lies somewhere between a `DimArray` and a `NamedTuple`:

- indexing with a `Symbol` as in `dimstack[:symbol]` returns a `DimArray` layer.
- iteration and `map` apply over array layers, as indexed with a `Symbol`.
- `getindex` and many base methods are applied as for `DimArray` - to avoid the need
  to always use `map`.

This design gives very succinct code when working with many-layered, mixed-dimension objects.
But it may be jarring initially - the most surprising outcome is that `dimstack[1]` will return
a `NamedTuple` of values for the first index in all layers, while `first(dimstack)` will return
the first value of the iterator - the `DimArray` for the first layer.

See [`DimStack`](@ref) for the concrete implementation.
Most methods are defined on the abstract type.

To extend `AbstractDimStack`, implement argument and keyword version of
[`rebuild`](@ref) and also [`rebuild_from_arrays`](@ref).

The constructor of an `AbstractDimStack` must accept a `NamedTuple`.
"""
abstract type AbstractDimStack{K,T,N,L} end
const AbstractVectorDimStack = AbstractDimStack{K,T,1} where {K,T}
const AbstractMatrixDimStack = AbstractDimStack{K,T,2} where {K,T}

DimArray(st::AbstractDimStack; kw...) = dimarray_from_dimstack(DimArray, st; kw...) 

dimarray_from_dimstack(T, st; kw...) =
    T([st[D] for D in DimIndices(st)]; dims=dims(st), metadata=metadata(st), kw...)

data(s::AbstractDimStack) = getfield(s, :data)
dims(s::AbstractDimStack) = getfield(s, :dims)
name(s::AbstractDimStack) = keys(s)
refdims(s::AbstractDimStack) = getfield(s, :refdims)
metadata(s::AbstractDimStack) = getfield(s, :metadata)

layerdims(s::AbstractDimStack) = getfield(s, :layerdims)

@inline layerdims(s::AbstractDimStack, name::Symbol) = dims(s, layerdims(s)[name])
@inline layermetadata(s::AbstractDimStack) = getfield(s, :layermetadata)
@inline layermetadata(s::AbstractDimStack, name::Symbol) = layermetadata(s)[name]

layers(nt::NamedTuple) = nt
@generated function layers(s::AbstractDimStack{K}) where K
    expr = Expr(:tuple, map(k -> :(s[$(QuoteNode(k))]), K)...)
    return :(NamedTuple{K}($expr))
end
@assume_effects :foldable DD.layers(s::AbstractDimStack{K}, i::Integer) where K = s[K[i]]
@assume_effects :foldable DD.layers(s::AbstractDimStack, k::Symbol) = s[k]

@assume_effects :foldable data_eltype(nt::NamedTuple{K}) where K =
    NamedTuple{K,Tuple{unrolled_map(eltype, Tuple(nt))...}}
stacktype(s, data, dims, layerdims::NamedTuple{K}) where K =
    basetypeof(s){K,data_eltype(data),length(dims)}

const DimArrayOrStack = Union{AbstractDimArray,AbstractDimStack}

@assume_effects :foldable function hassamedims(s::AbstractDimStack)
    all(map(==(first(layerdims(s))), layerdims(s)))
end

function rebuild(
    s::AbstractDimStack, data, dims=dims(s), refdims=refdims(s),
    layerdims=layerdims(s), metadata=metadata(s), layermetadata=layermetadata(s)
)
    T = stacktype(s, data, dims, layerdims)
    return T(data, dims, refdims, layerdims, metadata, layermetadata)
end
function rebuild(s::AbstractDimStack; 
    data=data(s),
    dims=dims(s),
    refdims=refdims(s),
    layerdims=layerdims(s),
    metadata=metadata(s),
    layermetadata=layermetadata(s)
)
    T = stacktype(s, data, dims, layerdims)
    return T(data, dims, refdims, layerdims, metadata, layermetadata)
end

function rebuildsliced(f::Function, s::AbstractDimStack, layers::NamedTuple, I)
    layerdims = unrolled_map(basedims, layers)
    dims, refdims = slicedims(f, s, I)
    return rebuild(s; data=unrolled_map(parent, layers), dims, refdims, layerdims)
end
function rebuildsliced(f::Function, s::AbstractDimStack{K}, layers::Tuple, I) where K
    layerdims = NamedTuple{K}(unrolled_map(basedims, layers))
    dims, refdims = slicedims(f, s, I)
    return rebuild(s; data=unrolled_map(parent, layers), dims, refdims, layerdims)
end

"""
    rebuild_from_arrays(s::AbstractDimStack, das::NamedTuple{<:Any,<:Tuple{Vararg{AbstractDimArray}}}; kw...)

Rebuild an `AbstractDimStack` from a `Tuple` or `NamedTuple` of `AbstractDimArray`
and an existing stack.

# Keywords

Keywords are simply the common fields of an `AbstractDimStack` object:

- `data`
- `dims`
- `refdims`
- `metadata`
- `layerdims`
- `layermetadata`

There is no promise that these keywords will be used in all cases.
"""
function rebuild_from_arrays(
    s::AbstractDimStack{Keys}, das::Tuple{Vararg{AbstractBasicDimArray}}; kw...
) where Keys
    rebuild_from_arrays(s, NamedTuple{Keys}(das), kw...)
end
function rebuild_from_arrays(
    s::AbstractDimStack, das::NamedTuple{<:Any,<:Tuple{Vararg{AbstractBasicDimArray}}};
    data=map(parent, das),
    refdims=refdims(s),
    metadata=DD.metadata(s),
    dims=nothing,
    layerdims=map(DD.basedims, das),
    layermetadata=map(DD.metadata, das),
)
    if isnothing(dims)
        Base.invokelatest() do
            dims = DD.combinedims(collect(das))
        end
        rebuild(s; data, dims, refdims, layerdims, metadata, layermetadata)
    else
        rebuild(s; data, dims, refdims, layerdims, metadata, layermetadata)
    end
end

# Dispatch on Tuple of Dimension, and map
for func in INTERFACE_QUERY_FUNCTION_NAMES 
    @eval ($func)(s::AbstractDimStack, args...) = ($func)(dims(s), args...)
end

Base.parent(s::AbstractDimStack) = data(s)
# Only compare data and dim - metadata and refdims can be different
Base.:(==)(s1::AbstractDimStack, s2::AbstractDimStack) =
    dims(s1) == dims(s2) && layerdims(s1) == layerdims(s2) && data(s1) == data(s2)
Base.isequal(s1::AbstractDimStack, s2::AbstractDimStack) =
    isequal(dims(s1), dims(s2)) && isequal(layerdims(s1), layerdims(s2)) && isequal(data(s1), data(s2))
Base.read(s::AbstractDimStack) = maplayers(read, s)

# Array-like
Base.size(s::AbstractDimStack) = map(length, dims(s))
Base.size(s::AbstractDimStack, dims::DimOrDimType) = size(s, dimnum(s, dims))
Base.size(s::AbstractDimStack, dims::Integer) = size(s)[dims]
Base.length(s::AbstractDimStack) = prod(size(s))
Base.axes(s::AbstractDimStack) = map(first ∘ axes, dims(s))
Base.axes(s::AbstractDimStack, dims::DimOrDimType) = axes(s, dimnum(s, dims))
Base.axes(s::AbstractDimStack, dims::Integer) = axes(s)[dims]
Base.eltype(::AbstractDimStack{<:Any,T}) where T = T
Base.ndims(::AbstractDimStack{<:Any,<:Any,N}) where N = N
Base.CartesianIndices(s::AbstractDimStack) = CartesianIndices(dims(s))
Base.LinearIndices(s::AbstractDimStack) = 
    LinearIndices(CartesianIndices(map(l -> axes(l, 1), lookup(s))))
Base.IteratorSize(::AbstractDimStack{<:Any,<:Any,N}) where N = Base.HasShape{N}()
function Base.eachindex(s::AbstractDimStack)
    li = LinearIndices(s)
    first(li):last(li)
end
Base.firstindex(s::AbstractDimStack) = first(LinearIndices(s))
Base.lastindex(s::AbstractDimStack) = last(LinearIndices(s))
Base.first(s::AbstractDimStack) = s[firstindex((s))]
Base.last(s::AbstractDimStack) = s[lastindex(LinearIndices(s))]
Base.copy(s::AbstractDimStack) = modify(copy, s)
# all of methods.jl is also Array-like...

# NamedTuple-like
@assume_effects :foldable Base.getproperty(s::AbstractDimStack, x::Symbol) = s[x]
Base.haskey(s::AbstractDimStack{K}, k) where K = k in K
Base.values(s::AbstractDimStack) = _values_gen(s)
@generated function _values_gen(s::AbstractDimStack{K}) where K
    Expr(:tuple, map(k -> :(s[$(QuoteNode(k))]), K)...)
end
Base.checkbounds(s::AbstractDimStack, I...) = checkbounds(CartesianIndices(s), I...)
Base.checkbounds(T::Type, s::AbstractDimStack, I...) = checkbounds(T, CartesianIndices(s), I...)

@inline Base.keys(s::AbstractDimStack{K}) where K = K
@inline Base.propertynames(s::AbstractDimStack{K}) where K = K
@inline Base.setindex(s::AbstractDimStack, val::AbstractBasicDimArray, name::Symbol) =
    rebuild_from_arrays(s, Base.setindex(layers(s), val, name))
Base.NamedTuple(s::AbstractDimStack) = NamedTuple(layers(s))
Base.collect(st::AbstractDimStack) = parent([st[D] for D in DimIndices(st)])
Base.Array(st::AbstractDimStack) = collect(st)
Base.vec(st::AbstractDimStack) = vec(collect(st))
Base.get(st::AbstractDimStack, k::Symbol, default) =
    haskey(st, k) ? st[k] : default
Base.get(f::Base.Callable, st::AbstractDimStack, k::Symbol) =
    haskey(st, k) ? st[k] : f()
@propagate_inbounds Base.iterate(st::AbstractDimStack) = iterate(st, 1)
@propagate_inbounds Base.iterate(st::AbstractDimStack, i) =
    i > length(st) ? nothing : (st[DimIndices(st)[i]], i + 1)

Base.similar(s::AbstractDimStack) = similar(s, eltype(s))
Base.similar(s::AbstractDimStack, dims::Dimension...) = similar(s, dims)
Base.similar(s::AbstractDimStack, ::Type{T},dims::Dimension...) where T =
    similar(s, T, dims)
Base.similar(s::AbstractDimStack, dims::Tuple{Vararg{Dimension}}) = 
    similar(s, eltype(s), dims)
Base.similar(s::AbstractDimStack, ::Type{T}) where T = 
    similar(s, T, dims(s))
function Base.similar(s::AbstractDimStack, ::Type{T}, dims::Tuple) where T
    # Any dims not in the stack are added to all layers
    ods = otherdims(dims, DD.dims(s))
    maplayers(s) do A
        # Original layer dims are maintained, other dims are added
        D = DD.commondims(dims, (DD.dims(A)..., ods...))
        similar(A, T, D)
    end
end
function Base.similar(s::AbstractDimStack, ::Type{T}, dims::Tuple) where T<:NamedTuple
    ods = otherdims(dims, DD.dims(s))
    maplayers(s, _nt_types(T)) do A, Tx 
        D = DD.commondims(dims, (DD.dims(A)..., ods...))
        similar(A, Tx, D)
    end
end

@generated function _nt_types(::Type{NamedTuple{K,T}}) where {K,T}
    expr = Expr(:tuple, T.parameters...)
    return :(NamedTuple{K}($expr))
end

# `merge` for AbstractDimStack and NamedTuple.
# One of the first three arguments must be an AbstractDimStack for dispatch to work.
Base.merge(s::AbstractDimStack) = s
function Base.merge(
    x1::AbstractDimStack,
    x2::Union{AbstractDimStack,NamedTuple},
    xs::Union{AbstractDimStack,NamedTuple}...;
    kw...
)
    rebuild_from_arrays(x1, merge(map(layers, (x1, x2, xs...))...); kw...)
end
function Base.merge(
    x1::NamedTuple, x2::AbstractDimStack, xs::Union{AbstractDimStack,NamedTuple}...;
)
    merge(map(layers, (x1, x2, xs...))...)
end
function Base.merge(
    x1::NamedTuple, x2::NamedTuple, x3::AbstractDimStack,
    xs::Union{AbstractDimStack,NamedTuple}...;
    kw...
)
    merge(map(layers, (x1, x2, x3, xs...))...)
end

"""
    maplayers(f, s::Union{AbstractDimStack,NamedTuple}...)

Map function `f` over the layers of `s`.
"""
maplayers(f, s::AbstractDimStack) =
    _maybestack(s, unrolled_map(f, values(s)))
function maplayers(
    f, x1::Union{AbstractDimStack,NamedTuple}, xs::Union{AbstractDimStack,NamedTuple}...
)
    stacks = (x1, xs...)
    _check_same_names(stacks...)
    vals = map(f, map(values, stacks)...)
    return _maybestack(_firststack(stacks...), vals)
end

# Other interfaces

Extents.extent(A::AbstractDimStack, args...) = Extents.extent(dims(A), args...)

ConstructionBase.getproperties(s::AbstractDimStack) = layers(s)
ConstructionBase.setproperties(s::AbstractDimStack, patch::NamedTuple) =
    ConstructionBase.constructorof(typeof(s))(ConstructionBase.setproperties(layers(s), patch))

Adapt.adapt_structure(to, s::AbstractDimStack) = maplayers(A -> Adapt.adapt(to, A), s)

function mergedims(st::AbstractDimStack, dim_pairs::Pair...)
    dim_pairs = map(dim_pairs) do (as, b)
        basedims(as) => b
    end
    isempty(dim_pairs) && return st
    # Extend missing dimensions in all layers
    maplayers(st) do layer
        extended_layer = if all(map((ds...) -> all(hasdim(layer, ds)), map(first, dim_pairs)...))
            layer
        else
            DimExtensionArray(layer, dims(st))
        end
        mergedims(extended_layer, dim_pairs...)
    end
end

function unmergedims(s::AbstractDimStack, original_dims)
    return maplayers(A -> unmergedims(A, original_dims), s)
end

@noinline _stack_size_mismatch() = throw(ArgumentError("Arrays must have identical axes. For mixed dimensions, use DimArrays`"))

function _layerkeysfromdim(A, dim)
    map(lookup(A, dim)) do x
        if x isa Number
            Symbol(string(name(dim), "_", x))
        else
            Symbol(x)
        end
    end
end

_check_same_names(::Union{AbstractDimStack{names},NamedTuple{names}},
    ::Union{AbstractDimStack{names},NamedTuple{names}}...) where {names} = nothing
_check_same_names(::Union{AbstractDimStack,NamedTuple}, ::Union{AbstractDimStack,NamedTuple}...) =
    throw(ArgumentError("Named tuple names do not match."))

_firststack(s::AbstractDimStack, args...) = s
_firststack(arg1, args...) = _firststack(args...)
_firststack() = nothing

_maybestack(s::AbstractDimStack{<:NamedTuple{K}}, xs::Tuple) where K = NamedTuple{K}(xs)
_maybestack(s::AbstractDimStack, xs::Tuple) = NamedTuple{keys(s)}(xs)
# Without the `@nospecialise` here this method is also compile with the above method
# on every call to _maybestack. And `rebuild_from_arrays` is expensive to compile.
function _maybestack(
    s::AbstractDimStack, das::Tuple{AbstractDimArray,Vararg{AbstractDimArray}}
)
    # Avoid compiling this in the simple cases in the above method
    Base.invokelatest(() -> rebuild_from_arrays(s, das))
end
function _maybestack(
    s::AbstractDimStack{<:NamedTuple{K}}, das::Tuple{AbstractDimArray,Vararg{AbstractDimArray}}
) where K
    Base.invokelatest(() -> rebuild_from_arrays(s, das))
end


"""
    DimStack <: AbstractDimStack

    DimStack(table, [dims]; kw...)
    DimStack(data::AbstractDimArray...; kw...)
    DimStack(data::Union{AbstractArray,Tuple,NamedTuple}, [dims::DimTuple]; kw...)
    DimStack(data::AbstractDimArray; layersfrom, kw...)

DimStack holds multiple objects sharing some dimensions, in a `NamedTuple`.

## Arguments

- `data`: `AbstractDimArray` or an `AbstractArray`, `Tuple` or `NamedTuple` of `AbstractDimArray`s or `AbstractArray`s.
- `dims`: `DimTuple` of `Dimension`s. Required when `data` is not `AbstractDimArray`s.

## Keywords

- `name`: `Array` or `Tuple` of `Symbol` names for each layer. By default
    the names of `DimArrays` are or keys of a `NamedTuple` are used, 
    or `:layer1`, `:layer2`, etc.
- `metadata`: `AbstractDict` or `NamedTuple` metadata for the stack. 
- `layersfrom`: A dimension to slice layers from if data is a single
    `DimArray`. Defaults to `nothing`. 

(These are for advanced uses)
- `layerdims`: `Array`, `Tuple` or `NamedTuple` of dimension tuples to match the
    dimensions of each layer. Dimensions in `layerdims` must also be in `dims`.
- `layermetadata`: `Array`, `Tuple` or `NamedTuple` of metadata for each layer.
- `refdims`: `NamedTuple` of `Dimension`s for each layer, `()` by default.

## Details

`DimStack` behaviour lies somewhere between a `DimArray` and a `NamedTuple`:

- indexing with a `Symbol` as in `dimstack[:layername]` or using `getproperty` 
    `dimstack.layername` returns a `DimArray` layer.
- A `DimStack` iterates `NamedTuple`s corresponding to the value of each layer. This means functions like `map`, `broadcast`, and `collect` behave as if the `DimStack` were a `DimArray{<:NamedTuple}`
- `getindex` or `view` with a `Vector` or `Colon` will return another `DimStack` where
    all data layers have been sliced, unless this resolves to a single element, in which case 
    `getindex` returns a `NamedTuple`
- `setindex!` must pass a `Tuple` or `NamedTuple` matching the layers.
- many base and `Statistics` methods (`sum`, `mean` etc) will work as for a `DimArray`,
    applied to all layers separately.
- to apply a function to each layer of a `DimStack`, use [`maplayers`](@ref).


```julia
function DimStack(A::AbstractDimArray;
    layersfrom=nothing, name=nothing, metadata=metadata(A), refdims=refdims(A), kw...
)
```

For example, here we take the mean over the time dimension for all layers:

```julia
mean(mydimstack; dims=Ti)
```

And this equivalent to:

```julia
maplayers(A -> mean(A; dims=Ti), mydimstack)
```

This design gives succinct code when working with many-layered, mixed-dimension objects.

But it may be jarring initially - the most surprising outcome is that `dimstack[1]` will return
a `NamedTuple` of values for the first index in all layers, while `first(dimstack)` will return
the first value of the iterator - the `DimArray` for the first layer.

`DimStack` can be constructed from multiple `AbstractDimArray` or a `NamedTuple`
of `AbstractArray` and a matching `dims` tuple.

Most `Base` and `Statistics` methods that apply to `AbstractArray` can be used on
all layers of the stack simulataneously. The result is a `DimStack`, or
a `NamedTuple` if methods like `mean` are used without `dims` arguments, and
return a single non-array value.

## Example

```jldoctest
julia> using DimensionalData

julia> A = [1.0 2.0 3.0; 4.0 5.0 6.0];

julia> dimz = (X([:a, :b]), Y(10.0:10.0:30.0))
(↓ X [:a, :b],
→ Y 10.0:10.0:30.0)

julia> da1 = DimArray(1A, dimz; name=:one);

julia> da2 = DimArray(2A, dimz; name=:two);

julia> da3 = DimArray(3A, dimz; name=:three);

julia> s = DimStack(da1, da2, da3);

julia> s[At(:b), At(10.0)]
(one = 4.0, two = 8.0, three = 12.0)

julia> s[X(At(:a))] isa DimStack
true
```
"""
struct DimStack{K,T,N,L,D<:Tuple,R<:Tuple,LD,M,LM} <: AbstractDimStack{K,T,N,L}
    data::L
    dims::D
    refdims::R
    layerdims::NamedTuple{K,LD}
    metadata::M
    layermetadata::NamedTuple{K,LM}
    function DimStack(
        data, dims, refdims, layerdims::LD, metadata, layermetadata::NamedTuple{K}
    ) where LD<:NamedTuple{K} where K
        T = data_eltype(data)
        N = length(dims)
        DimStack{K,T,N}(data, dims, refdims, layerdims, metadata, layermetadata)
    end
    function DimStack{K,T,N}(
        data::L, dims::D, refdims::R, layerdims::NamedTuple{K,LD}, metadata::M, layermetadata::NamedTuple{K,LM}
    ) where {K,T,N,L,D,R,LD,M,LM}
        new{K,T,N,L,D,R,LD,M,LM}(data, dims, refdims, layerdims, metadata, layermetadata)
    end
end
DimStack(@nospecialize(das::AbstractDimArray...); kw...) = DimStack(collect(das); kw...)
DimStack(@nospecialize(das::Tuple{Vararg{AbstractDimArray}}); kw...) = DimStack(collect(das); kw...)
function DimStack(@nospecialize(das::AbstractArray{<:AbstractDimArray});
    metadata=NoMetadata(),
    refdims=(),
    name=uniquekeys(das),
)
    dims = DD.combinedims(das)
    name_tuple = Tuple(name)
    data = NamedTuple{name_tuple}(map(parent, das))
    layerdims = NamedTuple{name_tuple}(map(basedims, das))
    layermetadata = NamedTuple{name_tuple}(map(DD.metadata, das))

    DimStack(data, dims, refdims, layerdims, metadata, layermetadata)
end
function DimStack(A::AbstractDimArray;
    layersfrom=nothing, 
    metadata=metadata(A), 
    refdims=refdims(A), 
    name=nothing,
    kw...
)
    layers = if isnothing(layersfrom)
        name = if isnothing(name)
            DD.name(A) in (NoName(), Symbol(""), Name(Symbol(""))) ? (:layer1,) : (DD.name(A),)
        else
            name
        end
        NamedTuple{name}((A,))
    else
        name = if isnothing(name)
            Tuple(_layerkeysfromdim(A, layersfrom))
        else
            name
        end
        slices = Tuple(eachslice(A; dims=layersfrom))
        NamedTuple{name}(slices)
    end
    return DimStack(layers; refdims, metadata, kw...)
end
function DimStack(das::NamedTuple{<:Any,<:Tuple{Vararg{AbstractDimArray}}};
    data=map(parent, das), 
    dims=combinedims(collect(das)), 
    layerdims=map(basedims, das),
    refdims=(), 
    metadata=NoMetadata(), 
    layermetadata=map(DD.metadata, das)
)
    return DimStack(data, dims, refdims, layerdims, metadata, layermetadata)
end
DimStack(data::Union{Tuple,AbstractArray,NamedTuple}, dim::Dimension; name=uniquekeys(data), kw...) = 
    DimStack(NamedTuple{Tuple(name)}(data), (dim,); kw...)
DimStack(data::Union{Tuple,AbstractArray{<:AbstractArray}}, dims::Tuple; name=uniquekeys(data), kw...) = 
    DimStack(NamedTuple{Tuple(name)}(data), dims; kw...)
function DimStack(data::NamedTuple{K}, dims::Tuple;
    refdims=(), 
    metadata=NoMetadata(),
    layermetadata=nothing,
    layerdims=nothing
) where K
    if length(data) > 0 && Tables.istable(data) && all(d -> name(d) in keys(data), dims)
        return dimstack_from_table(DimStack, data, dims; refdims, metadata)
    end
    layerdims = if isnothing(layerdims) 
        all(map(d -> axes(d) == axes(first(data)), data)) || _stack_size_mismatch()
        map(_ -> basedims(dims), data)
    else
        NamedTuple{K}(map(basedims, layerdims))
    end
    layermetadata = if isnothing(layermetadata)
        map(_ -> NoMetadata(), data)
    else
        NamedTuple{K}(layermetadata)
    end
    dims1 = isempty(data) ? () : format(dims, first(data))
    return DimStack(data, dims1, refdims, layerdims, metadata, layermetadata)
end
# From another stack
function DimStack(st::AbstractDimStack;
    data=data(st), 
    dims=dims(st), 
    refdims=refdims(st), 
    layerdims=layerdims(st), 
    metadata=metadata(st),
    layermetadata=layermetadata(st),
)
    DimStack(data, dims, refdims, layerdims, metadata, layermetadata)
end

# Write each column from a table with one or more coordinate columns to a layer in a DimStack
function DimStack(data, dims::Tuple; kw...
)
    if Tables.istable(data)
        table = Tables.columns(data)
        all(map(d -> Dimensions.name(d) in Tables.columnnames(table), dims)) || throw(ArgumentError(
            "All dimensions in dims must be in the table columns."
        ))
        dims = guess_dims(table, dims; kw...)
        return dimstack_from_table(DimStack, table, dims; kw...)
    else
        throw(ArgumentError(
            """data must be a table with coordinate columns, an AbstractArray, 
            or a Tuple or NamedTuple of AbstractArrays"""
        ))

    end
end
function DimStack(table; kw...)
    if Tables.istable(table)
        table = Tables.columns(table)
        dimstack_from_table(DimStack, table, guess_dims(table; kw...); kw...)
    else
        throw(ArgumentError(
            """data must be a table with coordinate columns, an AbstractArray, 
            or a Tuple or NamedTuple of AbstractArrays"""
        ))    end
end

function dimstack_from_table(::Type{T}, table, dims; 
    name=nothing, 
    selector=nothing, 
    precision=6, 
    missingval=missing, 
    kw...
) where T<:AbstractDimStack
    table = Tables.columnaccess(table) ? table : Tables.columns(table)
    data_cols = isnothing(name) ? data_col_names(table, dims) : name
    dims = guess_dims(table, dims; precision)
    indices = coords_to_indices(table, dims; selector)
    layers = map(data_cols) do col
        d = Tables.getcolumn(table, col)
        restore_array(d, indices, dims, missingval)
    end
    return T(layers, dims; name = data_cols, kw...)
end

layerdims(s::DimStack{<:Any,<:Any,<:Any,<:Any,<:Any,<:Any,Nothing}, name::Symbol) = dims(s)

### Skipmissing on DimStacks

"""
    skipmissing(itr::AbstractDimStack)

Returns an iterable over the elements in a `AbstractDimStack` object, skipping any values if any of the layers are missing.
"""
Base.skipmissing

# Specialized dispatch of iterate to skip values if any layer is missing.
function Base.iterate(itr::Base.SkipMissing{<:AbstractDimStack}, state...)
    y = iterate(itr.x, state...)
    y === nothing && return nothing
    item, state = y
    while any(map(ismissing, item)) # instead of ismissing(item)
        y = iterate(itr.x, state)
        y === nothing && return nothing
        item, state = y
    end
    item, state
end

Base.eltype(::Type{Base.SkipMissing{T}}) where {T<:AbstractDimStack{<:Any, NT}} where NT =
    _nonmissing_nt(NT)

@generated _nonmissing_nt(NT::Type{<:NamedTuple{K,V}}) where {K,V} =
    NamedTuple{K, Tuple{map(Base.nonmissingtype, V.parameters)...}}
