"""
Supertype for dimensional datasets.

These have multiple layers of data, but share dimensions.
"""
abstract type AbstractDimDataset{L,D} end

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
all layers have been sliced.  `setindex!` must pass a `Tuple` or `NamedTuple` maching 
the layers.

Most `Base` and `Statistics` methods that apply gto `AbstractArray` can be used on 
all layers of the dataset simulataneously. The result is always a `DimDataset`, or
a NamedTuple if methods like `mean` are used without `dims` arguments.

## Example

```jldoctest
julia> using DimensionalData

julia> A = [1.0 2.0 3.0; 4.0 5.0 6.0];

julia> dimz = (X([:a, :b]), Y(10.0:10.0:30.0))
(X: Symbol[a, b] (AutoMode), Y: 10.0:10.0:30.0 (AutoMode))

julia> da1 = DimArray(1A, dimz, "one");


julia> da2 = DimArray(2A, dimz, "two");


julia> da3 = DimArray(3A, dimz, "three");


julia> ds = DimDataset(da1, da2, da3)
DimDataset{NamedTuple{(:one, :two, :three),Tuple{Array{Float64,2},Array{Float64,2},Array{Float64,2}}},Tuple{X{Array{Symbol,1},Categorical{Unordered{ForwardRelation}},Nothing},Y{StepRangeLen{Float64,Base.TwicePrecision{Float64},Base.TwicePrecision{Float64}},Sampled{Ordered{ForwardIndex,ForwardArray,ForwardRelation},Regular{Float64},Points},Nothing}},Tuple{},NamedTuple{(:one, :two, :three),Tuple{Nothing,Nothing,Nothing}}}((one = [1.0 2.0 3.0; 4.0 5.0 6.0], two = [2.0 4.0 6.0; 8.0 10.0 12.0], three = [3.0 6.0 9.0; 12.0 15.0 18.0]), (X: Symbol[a, b] (Categorical: Unordered), Y: 10.0:10.0:30.0 (Sampled: Ordered Regular Points)), (), (one = nothing, two = nothing, three = nothing))

julia> ds[:b, 10.0]
(one = 4.0, two = 8.0, three = 12.0)

julia> ds[X(:a)]
DimDataset{NamedTuple{(:one, :two, :three),Tuple{Array{Float64,1},Array{Float64,1},Array{Float64,1}}},Tuple{Y{StepRangeLen{Float64,Base.TwicePrecision{Float64},Base.TwicePrecision{Float64}},Sampled{Ordered{ForwardIndex,ForwardArray,ForwardRelation},Regular{Float64},Points},Nothing}},Tuple{X{Symbol,Categorical{Unordered{ForwardRelation}},Nothing}},NamedTuple{(:one, :two, :three),Tuple{Nothing,Nothing,Nothing}}}((one = [1.0, 2.0, 3.0], two = [2.0, 4.0, 6.0], three = [3.0, 6.0, 9.0]), (Y: 10.0:10.0:30.0 (Sampled: Ordered Regular Points),), (X: a (Categorical: Unordered),), (one = nothing, two = nothing, three = nothing))
```


"""
struct DimDataset{L,D,R,M} <: AbstractDimDataset{L,D}
    layers::L
    dims::D
    refdims::R
    metadata::M
end
DimDataset(das::AbstractDimArray...) = DimDataset(das)
DimDataset(das::Tuple{Vararg{<:AbstractDimArray}}) =
    DimDataset(NamedTuple{uniquekeys(das)}(das))
DimDataset(das::NamedTuple{<:Any,<:Tuple{Vararg{<:AbstractDimArray}}}) = begin
    layers = map(parent, das)
    dims = comparedims(das...)
    meta = map(metadata, das)
    refdims = () # das might have different refdims
    DimDataset(layers, dims, refdims, meta)
end
DimDataset(layers::NamedTuple, dims::DimTuple; refdims=(), metadata=nothing) =
    DimDataset(layers, dims, refdims, metadata)

layers(ds::AbstractDimDataset) = ds.layers
dimarrays(ds::AbstractDimDataset{<:NamedTuple{Keys}}) where Keys =
    NamedTuple{Keys}(map(k -> ds[k], Keys))
dims(ds::DimDataset) = ds.dims
metadata(ds::AbstractDimDataset) = ds.metadata
Base.keys(ds::AbstractDimDataset) = keys(layers(ds))
Base.values(ds::AbstractDimDataset) = values(layers(ds))

# Only compare data and dim - metadata and refdims can be different
Base.:(==)(ds1::AbstractDimDataset, ds2::AbstractDimDataset) = 
    layers(ds1) == layers(ds2) && dims(ds1) == dims(ds2)

rebuild(ds::AbstractDimDataset, layers, dims=dims(ds), refdims=refdims(ds), metadata=metadata(ds)) =
    basetypeof(ds)(layers, dims, refdims, metadata)

rebuildsliced(A::AbstractDimDataset, layers, I) =
    rebuild(A, layers, slicedims(A, I)...)

# Dipatch on Tuple of Dimension, and map
for func in (:index, :mode, :metadata, :sampling, :span, :bounds, :locus, :order)
    @eval ($func)(ds::AbstractDimDataset, args...) = ($func)(dims(ds), args...)
end

"""
    Base.map(f, ds::AbstractDimDataset)

Apply functrion `f` to each layer of the dataset `ds`, and rebuild it.

If `f` returns `DimArray`s the result will be another `DimDataset`.
Other values will be returned in a `NamedTuple`.
"""
Base.map(f, ds::AbstractDimDataset) = maybedataset(map(f, dimarrays(ds)))

maybedataset(As::NamedTuple{<:Any,<:Tuple{Vararg{<:AbstractDimArray}}}) = DimDataset(As)
maybedataset(x::NamedTuple) = x


# getindex/view/setindex!

# No indices
Base.@propagate_inbounds Base.getindex(ds::AbstractDimDataset) = 
    map(A -> getindex(parent(A), dimarrays(ds)))
Base.@propagate_inbounds Base.view(ds::AbstractDimDataset) = 
    map(A -> view(parent(A), dimarrays(ds)))
Base.@propagate_inbounds Base.setindex!(ds::AbstractDimDataset, x) = 
    map(A -> setindex!(parent(A), x), dimarrays(ds))

# Symbol key
Base.@propagate_inbounds Base.getindex(ds::AbstractDimDataset, key::Symbol) =
    DimArray(layers(ds)[key], dims(ds), String(key))

# Integer getindex returns a single value
Base.@propagate_inbounds Base.getindex(ds::AbstractDimDataset, i::Int, I::Int...) =
    map(l -> getindex(l, i, I...), layers(ds))

# Standard indices
Base.@propagate_inbounds Base.getindex(ds::AbstractDimDataset, i1::StandardIndices, i2::StandardIndices, I::StandardIndices...) = begin
    newlayers = map(l -> getindex(l, i1, i2, I...), layers(ds))
    rebuildsliced(ds, newlayers, (i1, i2, I...))
end
Base.@propagate_inbounds Base.view(ds::AbstractDimDataset, i1::StandardIndices, i2::StandardIndices, I::StandardIndices...) = begin
    newlayers = map(l -> view(l, i1, i2, I...), layers(ds))
    rebuildsliced(ds, newlayers, (i1, i2, I...))
end
Base.@propagate_inbounds Base.setindex!(ds::AbstractDimDataset, x, i1::StandardIndices, i2::StandardIndices, I::StandardIndices...) =
    map(l -> setindex!(l, x, i1, i2, I...), layers(ds))

# Linear indexing returns a NamedTuple of Arrays
Base.@propagate_inbounds Base.getindex(ds::AbstractDimDataset{<:Any, N} where N, i::Union{Colon,AbstractArray}) =
    map(l -> getindex(l, i, I...), layers(ds))
# Exempt 1D DimArrays
Base.@propagate_inbounds Base.getindex(ds::AbstractDimDataset{<:Any, 1}, i::Union{Colon,AbstractArray}) =
    rebuildsliced(A, map(l -> getindex(l, i, I...), layers(ds)), (i,))
# Linear indexing returns a NamedTuple of unwrapped SubArrays
Base.@propagate_inbounds Base.view(A::AbstractDimDataset{<:Any, N} where N, i::StandardIndices) =
    map(l -> view(l, i, I...), layers(ds))
# Exempt 1D DimArrays
Base.@propagate_inbounds Base.view(A::AbstractDimDataset{<:Any, 1}, i::StandardIndices) =
    rebuildsliced(A, map(l -> view(l, i, I...), layers(ds)), (i,))

# Cartesian indices
Base.@propagate_inbounds Base.getindex(A::AbstractDimDataset, I::CartesianIndex) =
    map(A -> getindex(parent(A), I), dimarrays(A))
Base.@propagate_inbounds Base.view(A::AbstractDimDataset, I::CartesianIndex) =
    map(A -> view(parent(A), I), dimarrays(A))
Base.@propagate_inbounds Base.setindex!(A::AbstractDimDataset, x, I::CartesianIndex) =
    map(A -> setindex!(parent(A), x, I), dimarrays(A))

# Selectors with standard indices
Base.@propagate_inbounds Base.getindex(A::AbstractDimDataset, i, I...) =
    getindex(A, sel2indices(A, maybeselector(i, I...))...)
Base.@propagate_inbounds Base.view(A::AbstractDimDataset, i, I...) =
    view(A, sel2indices(A, maybeselector(i, I...))...)

# Dimensions
Base.@propagate_inbounds Base.getindex(ds::AbstractDimDataset, dim::Dimension, dims::Dimension...) =
    getindex(ds, dims2indices(ds, (dim, dims...))...)
Base.@propagate_inbounds Base.view(ds::AbstractDimDataset, dim::Dimension, dims::Dimension...) =
    view(ds, dims2indices(ds, (dim, dims...))...)
Base.@propagate_inbounds Base.setindex!(ds::AbstractDimDataset, x, dim::Dimension, dims::Dimension...) =
    setindex!(ds, x, dims2indices(ds, (dim, dims...))...)

# Symbol keyword-argument indexing.
Base.@propagate_inbounds Base.getindex(ds::AbstractDimDataset, args::Dimension...; kwargs...) =
    getindex(ds, args..., _kwargdims(kwargs.data)...)
Base.@propagate_inbounds Base.view(ds::AbstractDimDataset, args::Dimension...; kwargs...) =
    view(ds, args..., _kwargdims(kwargs.data)...)
Base.@propagate_inbounds Base.setindex!(ds::AbstractDimDataset, x, args::Dimension...; kwargs...) =
    setindex!(ds, x, args..., _kwargdims(kwargs)...)


# Array methods

# Methods with no arguments that return a DimDataset
for (mod, fnames) in
    (:Base => (:inv, :adjoint, :transpose), :LinearAlgebra => (:Transpose,))
    for fname in fnames
        @eval ($mod.$fname)(ds::AbstractDimDataset) = map(A -> ($mod.$fname)(A), ds)
    end
end

# Methods with an argument that return a DimDataset
for fname in (:rotl90, :rotr90, :rot180, :PermutedDimsArray, :permutedims)
    @eval (Base.$fname)(ds::AbstractDimDataset, args...) = 
        map(A -> (Base.$fname)(A, args...), ds)
end

# Base/Statistics methods with keyword arguments that return a DimDataset
for (mod, fnames) in 
    (:Base => (:sum, :prod, :maximum, :minimum, :extrema, :dropdims),
     :Statistics => (:cor, :cov, :mean, :median, :std, :var))
    for fname in fnames
        @eval ($mod.$fname)(ds::AbstractDimDataset; kwargs...) =
            maybedataset(map(A -> ($mod.$fname)(A; kwargs...), dimarrays(ds)))
    end
end

# Methods that take a function
for (mod, fnames) in (:Base => (:reduce, :sum, :prod, :maximum, :minimum, :extrema),
                      :Statistics => (:mean,))
    for fname in fnames
        _fname = Symbol(:_, fname)
        @eval begin
            ($mod.$fname)(f::Function, ds::AbstractDimDataset; dims=Colon()) =
                ($_fname)(f, ds, dims)
            # Colon returns a NamedTuple
            ($_fname)(f::Function, ds::AbstractDimDataset, dims::Colon) =
                map(A -> ($mod.$fname)(f, A), layers(ds))
            # Otherwise return a DimDataset
            ($_fname)(f::Function, ds::AbstractDimDataset, dims) =
                map(A -> ($mod.$fname)(f, A; dims), ds)
        end
    end
end

