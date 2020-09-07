"""
Supertype for dimensional datasets.

These have multiple layers of data, but share dimensions.
"""
abstract type AbstractDimDataset end

"""
    DimDataset(layers::AbstractDimArray...)
    DimDataset(layers::Tuple{Vararg{<:AbstractDimArray}})
    DimDataset(layers::NamedTuple, dims::DimTuple; metadata=nothing)

DimDataset holds multiple objects with the same dimensions, in a `NamedTuple`. 
Indexing operates as for [`AbstractDimArray`](@ref), except it occurs for all
layers of the dataset simulataneously. Layer objects can hold values of any type.

`getindex` with `Int` or `Dimension`s or `Selector`s that resolve to `Int` will
return a `NamedTuple` of values from each layer in the dataset. 
Indexing with a `Vector` or `Colon` will return another `DimDataset` where 
all layers have been sliced.

`setindex!` must pass a `Tuple` or `NamedTuple` maching the layers.
## Example 

```jldoctest
julia> A = [1.0 2.0 3.0; 4.0 5.0 6.0];

julia> dimz = (X([:a, :b]), Y(10.0:10.0:30.0))

julia> da1 = DimArray(1A, dimz, "one");

julia> da2 = DimArray(2A, dimz, "two");

julia> da3 = DimArray(3A, dimz, "three");

julia> ds = DimDataset(da1, da2, da3)
DimDataset{NamedTuple{(:one, :two, :three),Tuple{Array{Float64,2},Array{Float64,2},Array{Float64,2}}},Tuple{X{Array{Symbol,1},Categorical{Unordered{ForwardRelation}},Nothing},Y{StepRangeLen{Float64,Base.TwicePrecision{Float64},Base.TwicePrecision{Float64}},Sampled{Ordered{ForwardIndex,ForwardArray,ForwardRelation},Regular{
Float64},Points},Nothing}},Tuple{},Tuple{Nothing,Nothing,Nothing}}((one = [1.0 2.0 3.0; 4.0 5.0 6.0], two = [2.0 4.0 6.0; 8.0 10.0 12.0], three = [3.0 6.0 9.0; 12.0 15.0 18.0]), (X: Symbol[a, b] (Categorical: Unordered), Y: 10.0:10.0:30.0 (Sampled: Ordered Regular Points)), (), (nothing, nothing, nothing))

julia> ds[:b, 10.0] 
(one = 4.0, two = 8.0, three = 12.0)

julia> ds[X(:a)]
DimDataset{NamedTuple{(:one, :two, :three),Tuple{Array{Float64,1},Array{Float64,1
},Array{Float64,1}}},Tuple{Y{StepRangeLen{Float64,Base.TwicePrecision{Float64},Base.TwicePrecision{Float64}},Sampled{Ordered{ForwardIndex,ForwardArray,ForwardRelation},Regular{Float64},Points},Nothing}},Tuple{X{Symbol,Categorical{Unordered{ForwardRelation}},Nothing}},Tuple{Nothing,Nothing,Nothing}}((one = [1.0, 2.0, 3.0], 
two = [2.0, 4.0, 6.0], three = [3.0, 6.0, 9.0]), (Y: 10.0:10.0:30.0 (Sampled: Ordered Regular Points),), (X: a (Categorical: Unordered),), (nothing, nothing, nothing))
```
"""
struct DimDataset{L,D,R,M} <: AbstractDimDataset
    layers::L
    dims::D
    refdims::R
    metadata::M
end
DimDataset(das::AbstractDimArray...) = DimDataset(das)
DimDataset(das::Tuple{Vararg{<:AbstractDimArray}}) = begin
    dims = comparedims(das...)
    keys = Symbol.(map(name, das))
    layers = NamedTuple{keys}(map(parent, das))
    meta = map(metadata, das)
    refdims = () # das might have different refdims
    DimDataset(layers, dims, refdims, meta)
end
DimDataset(layers::NamedTuple, dims::DimTuple; refdims=(), metadata=nothing) =
    DimDataset(layers, dims, refdims, metadata)

layers(ds::DimDataset) = ds.layers
dims(ds::DimDataset) = ds.dims
metadata(ds::DimDataset) = ds.metadata
Base.keys(ds::DimDataset) = keys(layers(ds))
Base.values(ds::DimDataset) = values(layers(ds))

rebuild(ds::AbstractDimDataset, layers, dims=dims(ds), refdims=refdims(ds), metadata=metadata(ds)) = 
    basetypeof(ds)(layers, dims, refdims, metadata)

rebuildsliced(A::AbstractDimDataset, layers, I) =
    rebuild(A, layers, slicedims(A, I)...)

# getindex

Base.@propagate_inbounds Base.getindex(ds::DimDataset, key::Symbol) =
    DimArray(layers(ds)[key], dims(ds), String(key))
Base.@propagate_inbounds Base.getindex(ds::DimDataset, i::Int, I::Int...) =
    map(l -> getindex(l, i, I...), layers(ds))

Base.@propagate_inbounds Base.getindex(ds::DimDataset, i::StandardIndices, I::StandardIndices...) = begin
    newlayers = map(l -> getindex(l, i, I...), layers(ds))
    rebuildsliced(ds, newlayers, (i, I...))
end
Base.@propagate_inbounds Base.view(ds::DimDataset, i::StandardIndices, I::StandardIndices...) = begin
    newlayers = map(l -> view(l, i, I...), layers(ds))
    rebuildsliced(ds, newlayers, (i, I...))
end
Base.@propagate_inbounds Base.setindex!(ds::DimDataset, x, i::StandardIndices, I::StandardIndices...) =
    map(l -> setindex!(l, x, i, I...), layers(ds))

Base.@propagate_inbounds Base.getindex(A::DimDataset, i, I...) =
    getindex(A, sel2indices(A, maybeselector(i, I...))...)
Base.@propagate_inbounds Base.view(A::DimDataset, i, I...) =
    view(A, sel2indices(A, maybeselector(i, I...))...)

Base.@propagate_inbounds Base.getindex(ds::DimDataset, dim::Dimension, dims::Dimension...) =
    getindex(ds, dims2indices(ds, (dim, dims...))...)
Base.@propagate_inbounds Base.view(ds::DimDataset, dim::Dimension, dims::Dimension...) =
    view(ds, dims2indices(ds, (dim, dims...))...)
Base.@propagate_inbounds Base.setindex!(ds::DimDataset, x, dim::Dimension, dims::Dimension...) =
    setindex!(ds, x, dims2indices(ds, (dim, dims...))...)


# Linear indexing returns a NamedTuple of Arrays
Base.@propagate_inbounds Base.getindex(ds::DimDataset{<:Any, N} where N, i::Union{Colon,AbstractArray}) =
    map(l -> getindex(l, i, I...), layers(ds))
# Exempt 1D DimArrays
Base.@propagate_inbounds Base.getindex(ds::DimDataset{<:Any, 1}, i::Union{Colon,AbstractArray}) =
    rebuildsliced(A, map(l -> getindex(l, i, I...), layers(ds)), (i,))

# Linear indexing returns a NamedTuple of unwrapped SubArrays
Base.@propagate_inbounds Base.view(A::DimDataset{<:Any, N} where N, i::StandardIndices) =
    map(l -> view(l, i, I...), layers(ds))
# Exempt 1D DimArrays
Base.@propagate_inbounds Base.view(A::DimDataset{<:Any, 1}, i::StandardIndices) =
    rebuildsliced(A, map(l -> view(l, i, I...), layers(ds)), (i,))

# TODO

# Which array methods should be suppported on DimDataset? All of them?
