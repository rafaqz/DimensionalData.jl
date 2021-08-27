"""
    AbstractDimStack

Abstract supertype for dimensional stacks.

These have multiple layers of data, but share dimensions.
"""
abstract type AbstractDimStack{L} end

data(s::AbstractDimStack) = s.data
dims(s::AbstractDimStack) = s.dims
refdims(s::AbstractDimStack) = s.refdims
layerdims(s::AbstractDimStack) = s.layerdims
layerdims(s::AbstractDimStack, key::Symbol) = dims(s, layerdims(s)[key])
metadata(s::AbstractDimStack) = s.metadata
layermetadata(s::AbstractDimStack) = s.layermetadata
layermetadata(s::AbstractDimStack, key::Symbol) = layermetadata(s)[key]
metadata(s::AbstractDimStack, key::Symbol) = layermetadata(s)[key]

layerdims(A::AbstractDimArray) = basedims(A)

@inline Base.keys(s::AbstractDimStack) = keys(data(s))
Base.haskey(s::AbstractDimStack, k) = k in keys(s)
Base.values(s::AbstractDimStack) = values(layers(s))
Base.first(s::AbstractDimStack) = s[first(keys(s))]
Base.last(s::AbstractDimStack) = s[last(keys(s))]
# Only compare data and dim - metadata and refdims can be different
Base.:(==)(s1::AbstractDimStack, s2::AbstractDimStack) =
    data(s1) == data(s2) && dims(s1) == dims(s2) && layerdims(s1) == layerdims(s2)
Base.length(s::AbstractDimStack) = length(data(s))
Base.size(s::AbstractDimStack) = map(length, dims(s))
Base.size(A::AbstractDimStack, dims::DimOrDimType) = size(A, dimnum(A, dims))
Base.size(A::AbstractDimStack, dims::Integer) = size(A)[dims]
Base.axes(s::AbstractDimStack) = map(first ∘ axes, dims(s))
Base.axes(A::AbstractDimStack, dims::DimOrDimType) = axes(A, dimnum(A, dims))
Base.axes(A::AbstractDimStack, dims::Integer) = axes(A)[dims] 
Base.iterate(s::AbstractDimStack, args...) = iterate(layers(s), args...)

function rebuild(
    s::AbstractDimStack, data, dims=dims(s), refdims=refdims(s), 
    layerdims=layerdims(s), metadata=metadata(s), layermetadata=layermetadata(s)
)
    basetypeof(s)(data, dims, refdims, layerdims, metadata, layermetadata)
end

function rebuildsliced(f::Function, s::AbstractDimStack, data, I) 
    layerdims = map(basedims, data)
    dims, refdims = slicedims(f, s, I)
    rebuild(s; data=map(parent, data), dims=dims, refdims=refdims, layerdims=layerdims)
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


Adapt.adapt_structure(to, s::AbstractDimStack) = map(A -> adapt(to, A), s)

# Dipatch on Tuple of Dimension, and map
for func in (:index, :mode, :metadata, :sampling, :span, :bounds, :locus, :order)
    @eval ($func)(s::AbstractDimStack, args...) = ($func)(dims(s), args...)
end

"""
    Base.copy!(dst::AbstractArray, src::DiskGeoStack, key::Key)

Copy the stack layer `key` to `dst`, which can be any `AbstractArray`.

## Example

Copy the `:humidity` layer from `stack` to `array`.

```julia
copy!(array, stack, :humidity)
```
"""
Base.copy!(dst::AbstractArray, src::AbstractDimStack, key) = copy!(dst, src[key])

"""
    Base.copy!(dst::AbstractDimStack, src::AbstractDimStack, [keys=keys(dst)])

Copy all or a subset of layers from one stack to another.

## Example

Copy just the `:sea_surface_temp` and `:humidity` layers from `src` to `dst`.

```julia
copy!(dst::AbstractDimStack, src::AbstractDimStack, keys=(:sea_surface_temp, :humidity))
```
"""
function Base.copy!(dst::AbstractDimStack, src::AbstractDimStack, keys=keys(dst))
    # Check all keys first so we don't copy anything if there is any error
    for key in keys
        key in Base.keys(dst) || throw(ArgumentError("key $key not found in dest keys"))
        key in Base.keys(src) || throw(ArgumentError("key $key not found in source keys"))
    end
    for key in keys
        copy!(dst[key], src[key])
    end
end

"""
    Base.map(f, s::AbstractDimStack)

Apply functrion `f` to each layer of the stack `s`, and rebuild it.

If `f` returns `DimArray`s the result will be another `DimStack`.
Other values will be returned in a `NamedTuple`.
"""
Base.map(f, s::AbstractDimStack...) = _maybestack(s[1], map(f, map(layers, s)...))

_maybestack(s::AbstractDimStack, x::NamedTuple) = x
function _maybestack(
    s::AbstractDimStack, das::NamedTuple{K,<:Tuple{Vararg{<:AbstractDimArray}}}
) where K
    rebuild_from_arrays(s, das; refdims=DD.refdims(s), metadata=DD.metadata(s))
end

"""
    Base.cat(stacks::AbstractGeoStack...; [keys=keys(stacks[1])], dims)

Concatenate all or a subset of layers for all passed in stacks.

# Keywords

- `keys`: `Tuple` of `Symbol` for the stack keys to concatenate.
- `dims`: Dimension of child array to concatenate on.

# Example

Concatenate the :sea_surface_temp and :humidity layers in the time dimension:

```julia
cat(stacks...; keys=(:sea_surface_temp, :humidity), dims=Ti)
```
"""
function Base.cat(s1::AbstractDimStack, stacks::AbstractDimStack...; keys=keys(s1), dims)
    vals = Tuple(cat((s[k] for s in (s1, stacks...))...; dims=dims) for k in keys)
    DD.basetypeof(s1)(NamedTuple{keys}(vals))
end

# Array methods

# Methods with no arguments that return a DimStack
for (mod, fnames) in
    (:Base => (:inv, :adjoint, :transpose), :LinearAlgebra => (:Transpose,))
    for fname in fnames
        @eval ($mod.$fname)(s::AbstractDimStack) = map(A -> ($mod.$fname)(A), s)
    end
end

# Methods with an argument that return a DimStack
for fname in (:rotl90, :rotr90, :rot180, :PermutedDimsArray, :permutedims)
    @eval (Base.$fname)(s::AbstractDimStack, args...) =
        map(A -> (Base.$fname)(A, args...), s)
end

# Methods with keyword arguments that return a DimStack
for (mod, fnames) in
    (:Base => (:sum, :prod, :maximum, :minimum, :extrema, :dropdims),
     :Statistics => (:mean, :median, :std, :var))
    for fname in fnames
        @eval function ($mod.$fname)(s::AbstractDimStack; dims=:, kw...)
            map(s) do A
                # Ignore dims not found in layer
                if dims isa Union{Colon,Int}
                    ($mod.$fname)(A; dims, kw...)
                else
                    ldims = commondims(DD.dims(A), dims)
                    # With no matching dims we do nothing
                    ldims == () ? A : ($mod.$fname)(A; dims=ldims, kw...)
                end
            end
        end
    end
end
for fname in (:cor, :cov)
    @eval function (Statistics.$fname)(s::AbstractDimStack; dims=1, kw...)
        map(s) do A
            if dims isa Int
                (Statistics.$fname)(A; dims, kw...)
            else
                ldims = only(commondims(DD.dims(A), dims))
                ldims == () ? A : (Statistics.$fname)(A; dims=ldims, kw...)
            end
        end
    end
end

# Methods that take a function
for (mod, fnames) in (:Base => (:reduce, :sum, :prod, :maximum, :minimum, :extrema),
                      :Statistics => (:mean,))
    for fname in fnames
        _fname = Symbol(:_, fname)
        @eval function ($mod.$fname)(f::Function, s::AbstractDimStack; dims=Colon())
            map(A -> ($mod.$fname)(f, A; dims=dims), s)
        end
                # ($_fname)(f, s, dims)
            # Colon returns a NamedTuple
            # ($_fname)(f::Function, s::AbstractDimStack, dims::Colon) =
                # map(A -> ($mod.$fname)(f, A), data(s))
            # Otherwise maybe return a DimStack
            # function ($_fname)(f::Function, s::AbstractDimStack, dims) =
            # end
        # end
    end
end


"""
    DimStack <: AbstractDimStack

    DimStack(data::AbstractDimArray...)
    DimStack(data::Tuple{Vararg{<:AbstractDimArray}})
    DimStack(data::NamedTuple{Keys,Vararg{<:AbstractDimArray}})
    DimStack(data::NamedTuple, dims::DimTuple; metadata=NoMetadata())

DimStack holds multiple objects sharing some dimensions, in a `NamedTuple`.
Indexing operates as for [`AbstractDimArray`](@ref), except it occurs for all
data layers of the stack simulataneously. Layer objects can hold values of any type.

DimStack can be constructed from multiple `AbstractDimArray` or a `NamedTuple`
of `AbstractArray` and a matching `dims` `Tuple`. If `AbstractDimArray`s have
the same name they will be given the name `:layer1`, substitiuting the
layer number for `1`.

`getindex` with `Int` or `Dimension`s or `Selector`s that resolve to `Int` will
return a `NamedTuple` of values from each layer in the stack. This has very good
performace, and usually takes less time than the sum of indexing each array
separately.

Indexing with a `Vector` or `Colon` will return another `DimStack` where
all data layers have been sliced.  `setindex!` must pass a `Tuple` or `NamedTuple` maching
the layers.

Most `Base` and `Statistics` methods that apply to `AbstractArray` can be used on
all layers of the stack simulataneously. The result is a `DimStack`, or
a `NamedTuple` if methods like `mean` are used without `dims` arguments, and
return a single non-array value.

## Example

```jldoctest
julia> using DimensionalData

julia> A = [1.0 2.0 3.0; 4.0 5.0 6.0];

julia> dimz = (X([:a, :b]), Y(10.0:10.0:30.0))

  X: Symbol[a, b],
  Y: 10.0:10.0:30.0

julia> da1 = DimArray(1A, dimz, :one);

julia> da2 = DimArray(2A, dimz, :two);

julia> da3 = DimArray(3A, dimz, :three);

julia> s = DimStack(da1, da2, da3);

julia> s[:b, 10.0]
(one = 4.0, two = 8.0, three = 12.0)

julia> s[X(:a)] isa DimStack
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
DimStack(das::AbstractDimArray...; kwargs...) = DimStack(das; kwargs...)
function DimStack(das::Tuple{Vararg{<:AbstractDimArray}}; kwargs...)
    DimStack(NamedTuple{uniquekeys(das)}(das); kwargs...)
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
    DimStack(data, formatdims(first(data), dims), refdims, layerdims, metadata, layermetadata)
end

@noinline _stack_size_mismatch() = throw(ArgumentError("Arrays must have identical axes. For mixed dimensions, use DimArrays`"))
