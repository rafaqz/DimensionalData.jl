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

To extend `AbstractDimStack`, implement [`rebuild`](@ref) and
[`rebuild_from_arrays`](@ref).
"""
abstract type AbstractDimStack{L} end

data(s::AbstractDimStack) = s.data
dims(s::AbstractDimStack) = s.dims
refdims(s::AbstractDimStack) = s.refdims
metadata(s::AbstractDimStack) = s.metadata


layerdims(s::AbstractDimStack) = s.layerdims
layerdims(s::AbstractDimStack, key::Symbol) = dims(s, layerdims(s)[key])
layermetadata(s::AbstractDimStack) = s.layermetadata
layermetadata(s::AbstractDimStack, key::Symbol) = layermetadata(s)[key]

Base.parent(s::AbstractDimStack) = s.data
@inline Base.keys(s::AbstractDimStack) = keys(data(s))
Base.haskey(s::AbstractDimStack, k) = k in keys(s)
Base.values(s::AbstractDimStack) = values(layers(s))
Base.first(s::AbstractDimStack) = s[first(keys(s))]
Base.last(s::AbstractDimStack) = s[last(keys(s))]
# Only compare data and dim - metadata and refdims can be different
Base.:(==)(s1::AbstractDimStack, s2::AbstractDimStack) =
    data(s1) == data(s2) && dims(s1) == dims(s2) && layerdims(s1) == layerdims(s2)
Base.length(s::AbstractDimStack) = length(keys(s))
Base.size(s::AbstractDimStack) = map(length, dims(s))
Base.size(A::AbstractDimStack, dims::DimOrDimType) = size(A, dimnum(A, dims))
Base.size(A::AbstractDimStack, dims::Integer) = size(A)[dims]
Base.axes(s::AbstractDimStack) = map(first ∘ axes, dims(s))
Base.axes(A::AbstractDimStack, dims::DimOrDimType) = axes(A, dimnum(A, dims))
Base.axes(A::AbstractDimStack, dims::Integer) = axes(A)[dims]
Base.iterate(s::AbstractDimStack, args...) = iterate(layers(s), args...)
Base.read(s::AbstractDimStack) = map(read, s)

function rebuild(
    s::AbstractDimStack, data, dims=dims(s), refdims=refdims(s),
    layerdims=layerdims(s), metadata=metadata(s), layermetadata=layermetadata(s)
)
    basetypeof(s)(data, dims, refdims, layerdims, metadata, layermetadata)
end

function rebuildsliced(f::Function, s::AbstractDimStack, layers, I)
    layerdims = map(basedims, layers)
    dims, refdims = slicedims(f, s, I)
    rebuild(s; data=map(parent, layers), dims=dims, refdims=refdims, layerdims=layerdims)
end

"""
    rebuild_from_arrays(s::AbstractDimStack, das::NamedTuple{<:Any,<:Tuple{Vararg{<:AbstractDimArray}}}; kw...)

Rebuild an `AbstractDimStack` from a `NamedTuple` of `AbstractDimArray`
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
    s::AbstractDimStack, das::Tuple{Vararg{<:AbstractDimArray}}; kw...
)
    rebuild_from_arrays(s, NamedTuple{keys(s)}(das); kw...)
end
function rebuild_from_arrays(
    s::AbstractDimStack, das::NamedTuple{<:Any,<:Tuple{Vararg{<:AbstractDimArray}}};
    refdims=refdims(s),
    metadata=DD.metadata(s),
    data=map(parent, das),
    dims=DD.combinedims(das...),
    layerdims=map(DD.basedims, das),
    layermetadata=map(DD.metadata, das),
)
    rebuild(s; data, dims, refdims, layerdims, metadata, layermetadata)
end

function layers(s::AbstractDimStack{<:NamedTuple{Keys}}) where Keys
    NamedTuple{Keys}(map(K -> s[K], Keys))
end

Adapt.adapt_structure(to, s::AbstractDimStack) = map(A -> Adapt.adapt(to, A), s)

# Dipatch on Tuple of Dimension, and map
for func in (:index, :lookup, :metadata, :sampling, :span, :bounds, :locus, :order)
    @eval ($func)(s::AbstractDimStack, args...) = ($func)(dims(s), args...)
end

"""
    DimStack <: AbstractDimStack

    DimStack(data::AbstractDimArray...)
    DimStack(data::Tuple{Vararg{<:AbstractDimArray}})
    DimStack(data::NamedTuple{Keys,Vararg{<:AbstractDimArray}})
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
X Symbol[a, b],
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
struct DimStack{L,D<:Tuple,R<:Tuple,LD<:NamedTuple,M,LM<:NamedTuple} <: AbstractDimStack{L}
    data::L
    dims::D
    refdims::R
    layerdims::LD
    metadata::M
    layermetadata::LM
end
DimStack(das::AbstractDimArray...; kw...) = DimStack(das; kw...)
function DimStack(das::Tuple{Vararg{<:AbstractDimArray}}; kw...)
    DimStack(NamedTuple{uniquekeys(das)}(das); kw...)
end
function DimStack(das::NamedTuple{<:Any,<:Tuple{Vararg{<:AbstractDimArray}}};
    data=map(parent, das), dims=combinedims(das...), layerdims=map(basedims, das),
    refdims=(), metadata=NoMetadata(), layermetadata=map(DD.metadata, das)
)
    DimStack(data, dims, refdims, layerdims, metadata, layermetadata)
end
# Same sized arrays
function DimStack(data::NamedTuple, dims::Tuple;
    refdims=(), metadata=NoMetadata(), layermetadata=map(_ -> NoMetadata(), data)
)
    all(map(d -> axes(d) == axes(first(data)), data)) || _stack_size_mismatch()
    layerdims = map(_ -> basedims(dims), data)
    DimStack(data, format(dims, first(data)), refdims, layerdims, metadata, layermetadata)
end

@noinline _stack_size_mismatch() = throw(ArgumentError("Arrays must have identical axes. For mixed dimensions, use DimArrays`"))
