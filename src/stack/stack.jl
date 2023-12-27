"""
    AbstractDimStack

Abstract supertype for dimensional stacks.

These have multiple layers of data, but share dimensions.

Notably, their behaviour lies somewhere between a `DimArray` and a `NamedTuple`:

- indexing with a `Symbol` as in `dimstack[:symbol]` returns a `DimArray` layer.
- iteration amd `map` are apply over array layers, as indexed with a `Symbol`.
- `getindex` and many base methods are applied as for `DimArray` - to avoid the need 
    to allways use `map`.

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
abstract type AbstractDimStack{T,N,L,D} <: AbstractBasicDimArray{T,N,D} end

data(s::AbstractDimStack) = getfield(s, :data)
dims(s::AbstractDimStack) = getfield(s, :dims)
refdims(s::AbstractDimStack) = getfield(s, :refdims)
metadata(s::AbstractDimStack) = getfield(s, :metadata)

layerdims(s::AbstractDimStack) = getfield(s, :layerdims)
layerdims(s::AbstractDimStack, key::Symbol) = dims(s, layerdims(s)[key])
layermetadata(s::AbstractDimStack) = getfield(s, :layermetadata)
layermetadata(s::AbstractDimStack, key::Symbol) = layermetadata(s)[key]

layers(nt::NamedTuple) = nt
Base.@assume_effects :foldable function layers(s::AbstractDimStack{<:NamedTuple{Keys}}) where Keys
    NamedTuple{Keys}(map(K -> s[K], Keys))
end

"""
    rebuild_from_arrays(s::AbstractDimStack, das::NamedTuple{<:Any,<:Tuple{Vararg{AbstractDimArray}}}; kw...)

Rebuild an `AbstractDimStack` from a `Tuple` or `NamedTuple` of `AbstractDimArray`
and an existing stack.

# Keywords

Keywords are simply the fields of the stack object:

- `data`
- `dims`
- `refdims`
- `metadata`
- `layerdims`
- `layermetadata`
"""
function rebuild_from_arrays(
    s::AbstractDimStack{<:NamedTuple{Keys}}, das::Tuple{Vararg{AbstractDimArray}}; kw...
) where Keys
    rebuild_from_arrays(s, NamedTuple{Keys}(das), kw...)
end
function rebuild_from_arrays(
    s::AbstractDimStack, das::NamedTuple{<:Any,<:Tuple{Vararg{AbstractDimArray}}};
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

Base.parent(s::AbstractDimStack) = data(s)
@inline Base.keys(s::AbstractDimStack) = keys(data(s))
@inline Base.propertynames(s::AbstractDimStack) = keys(data(s))
Base.haskey(::AbstractDimStack{<:NamedTuple{Keys}}, k) where Keys = k in Keys
Base.values(s::AbstractDimStack) = values(layers(s))
Base.values(s::AbstractDimStack{<:NamedTuple{Keys}}) where Keys = map(K -> s[K], Keys)
# Only compare data and dim - metadata and refdims can be different
Base.:(==)(s1::AbstractDimStack, s2::AbstractDimStack) =
    data(s1) == data(s2) && dims(s1) == dims(s2) && layerdims(s1) == layerdims(s2)
Base.getproperty(s::AbstractDimStack, x::Symbol) = s[x]
Base.length(s::AbstractDimStack) = length(keys(s))
Base.size(s::AbstractDimStack) = map(length, dims(s))
Base.size(s::AbstractDimStack, dims::DimOrDimType) = size(s, dimnum(s, dims))
Base.size(s::AbstractDimStack, dims::Integer) = size(s)[dims]
Base.axes(s::AbstractDimStack) = map(first ∘ axes, dims(s))
Base.axes(s::AbstractDimStack, dims::DimOrDimType) = axes(s, dimnum(s, dims))
Base.axes(s::AbstractDimStack, dims::Integer) = axes(s)[dims]
Base.IndexStyle(::Type{<:AbstractDimStack}) = IndexCartesian()
Base.CartesianIndices(s::AbstractDimStack) = CartesianIndices(map(first ∘ axes, lookup(s)))
Base.iterate(s::AbstractDimStack, args...) = iterate(layers(s), args...)
Base.read(s::AbstractDimStack) = maplayers(read, s)
# `merge` for AbstractDimStack and NamedTuple.
# One of the first three arguments must be an AbstractDimStack for dispatch to work.
Base.merge(s::AbstractDimStack) = s
function Base.merge(x1::AbstractDimStack, x2::Union{AbstractDimStack,NamedTuple}, xs::Union{AbstractDimStack,NamedTuple}...) 
    rebuild_from_arrays(x1, merge(map(layers, (x1, x2, xs...))...); refdims=())
end
function Base.merge(s::AbstractDimStack, pairs) 
    rebuild_from_arrays(s, merge(layers(s), pairs); refdims=())
end
function Base.merge(x1::NamedTuple, x2::AbstractDimStack, xs::Union{AbstractDimStack,NamedTuple}...)
    merge(map(layers, (x1, x2, xs...))...)
end
function Base.merge(x1::NamedTuple, x2::NamedTuple, x3::AbstractDimStack, xs::Union{AbstractDimStack,NamedTuple}...)
    merge(map(layers, (x1, x2, x3, xs...))...)
end
function Base.setindex(s::AbstractDimStack, val::AbstractDimArray, key) 
    rebuild_from_arrays(s, Base.setindex(layers(s), val, key))
end
Base.NamedTuple(s::AbstractDimStack) = layers(s)

Extents.extent(A::AbstractDimStack, args...) = Extents.extent(dims(A), args...) 

ConstructionBase.getproperties(s::AbstractDimStack) = layers(s)
ConstructionBase.setproperties(s::AbstractDimStack, patch::NamedTuple) = 
    ConstructionBase.constructorof(typeof(s))(ConstructionBase.setproperties(layers(s), patch))

function rebuild(
    s::AbstractDimStack, data, dims=dims(s), refdims=refdims(s),
    layerdims=layerdims(s), metadata=metadata(s), layermetadata=layermetadata(s)
)
    basetypeof(s)(data, dims, refdims, layerdims, metadata, layermetadata)
end
function rebuild(s::AbstractDimStack; data=data(s), dims=dims(s), refdims=refdims(s),
    layerdims=layerdims(s), metadata=metadata(s), layermetadata=layermetadata(s)
)
    basetypeof(s)(data, dims, refdims, layerdims, metadata, layermetadata)
end

function rebuildsliced(f::Function, s::AbstractDimStack, layers, I)
    layerdims = map(basedims, layers)
    dims, refdims = slicedims(f, s, I)
    rebuild(s; data=map(parent, layers), dims=dims, refdims=refdims, layerdims=layerdims)
end

Adapt.adapt_structure(to, s::AbstractDimStack) = map(A -> Adapt.adapt(to, A), s)

# Dipatch on Tuple of Dimension, and map
for func in (:index, :lookup, :metadata, :sampling, :span, :bounds, :locus, :order)
    @eval ($func)(s::AbstractDimStack, args...) = ($func)(dims(s), args...)
end

function mergedims(ds::AbstractDimStack, dim_pairs::Pair...)
    isempty(dim_pairs) && return ds
    vals = map(A -> mergedims(A, dim_pairs...), values(ds))
    rebuild_from_arrays(ds, vals)
end

function unmergedims(s::AbstractDimStack, original_dims)
    return map(A -> unmergedims(A, original_dims), s)
end

function _similar(st::AbstractDimStack, T::Type, shape::Tuple)
    # Use the first layer as a template array type
    template_layer = parent(first(layers(st)))
    data = similar(template_layer, T, map(_parent_range, shape))
    shape isa Tuple{Vararg{Dimensions.DimUnitRange}} || return data
    C = dimconstructor(dims(shape))
    return C(data, dims(shape))
end


"""
    DimStack <: AbstractDimStack

    DimStack(data::AbstractDimArray...)
    DimStack(data::Tuple{Vararg{AbstractDimArray}})
    DimStack(data::NamedTuple{Keys,Vararg{AbstractDimArray}})
    DimStack(data::NamedTuple, dims::DimTuple; metadata=NoMetadata())

DimStack holds multiple objects sharing some dimensions, in a `NamedTuple`.

Notably, their behaviour lies somewhere between a `DimArray` and a `NamedTuple`:

- indexing with a `Symbol` as in `dimstack[:symbol]` returns a `DimArray` layer.
- iteration amd `map` are apply over array layers, as indexed with a `Symbol`.
- `getindex` or `view` with `Int`, `Dimension`s or `Selector`s that resolve to `Int` will
    return a `NamedTuple` of values from each layer in the stack.
    This has very good performace, and avoids the need to always use `map`.
- `getindex` or `view` with a `Vector` or `Colon` will return another `DimStack` where
    all data layers have been sliced.  
- `setindex!` must pass a `Tuple` or `NamedTuple` maching the layers.
- many base and `Statistics` methods (`sum`, `mean` etc) will work as for a `DimArray`
    again removing the need to use `map`.

For example, here we take the mean over the time dimension for all layers :

```julia
mean(mydimstack; dims=Ti)
```

And this equivalent to:

```julia
map(A -> mean(A; dims=Ti), mydimstack)
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
X Symbol[:a, :b],
Y 10.0:10.0:30.0

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
struct DimStack{T,N,L,D<:Tuple,R<:Tuple,LD<:Union{NamedTuple,Nothing},M,LM<:NamedTuple} <: AbstractDimStack{T,N,L,D}
    data::L
    dims::D
    refdims::R
    layerdims::LD
    metadata::M
    layermetadata::LM
end
function DimStack(data::L, dims::D, refdims::R, layerdims::LD, metadata::M, layermetadata::LM) where {L<:NamedTuple{K},D<:Tuple,R<:Tuple,LD,M,LM<:NamedTuple} where K
    T = NamedTuple{K,Tuple{map(eltype, data)...}}
    N = length(dims)
    DimStack{T,N,L,D,R,LD,M,LM}(data, dims, refdims, layerdims, metadata, layermetadata)
end
DimStack(@nospecialize(das::AbstractDimArray...); kw...) = DimStack(collect(das); kw...)
DimStack(@nospecialize(das::Tuple{Vararg{AbstractDimArray}}); kw...) = DimStack(collect(das); kw...)
function DimStack(@nospecialize(das::AbstractArray{<:AbstractDimArray});
    metadata=NoMetadata(), refdims=(),
)
    keys_vec = uniquekeys(das)
    keys_tuple = ntuple(i -> keys_vec[i], length(keys_vec))
    dims = DD.combinedims(collect(das))
    as = map(parent, das)
    data = NamedTuple{keys_tuple}(as)
    layerdims = NamedTuple{keys_tuple}(map(basedims, das))
    layermetadata = NamedTuple{keys_tuple}(map(DD.metadata, das))

    DimStack(data, dims, refdims, layerdims, metadata, layermetadata)
end
function DimStack(das::NamedTuple{<:Any,<:Tuple{Vararg{AbstractDimArray}}};
    data=map(parent, das), dims=combinedims(collect(das)), layerdims=map(basedims, das),
    refdims=(), metadata=NoMetadata(), layermetadata=map(DD.metadata, das)
)
    DimStack(data, dims, refdims, layerdims, metadata, layermetadata)
end
# Same sized arrays
function DimStack(data::NamedTuple, dims::Tuple;
    refdims=(), metadata=NoMetadata(), 
    layermetadata=map(_ -> NoMetadata(), data),
    layerdims = map(_ -> basedims(dims), data),
)
    all(map(d -> axes(d) == axes(first(data)), data)) || _stack_size_mismatch()
    DimStack(data, format(dims, first(data)), refdims, layerdims, metadata, layermetadata)
end

@noinline _stack_size_mismatch() = throw(ArgumentError("Arrays must have identical axes. For mixed dimensions, use DimArrays`"))

layerdims(s::DimStack{<:Any,<:Any,<:Any,<:Any,<:Any,Nothing}, key::Symbol) = dims(s)
