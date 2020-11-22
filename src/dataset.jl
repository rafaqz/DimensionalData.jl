"""
Supertype for dimensional datasets.

These have multiple layers of data, but share dimensions.
"""
abstract type AbstractDimDataset{L,N,D} end

"""
    DimDataset(data::AbstractDimArray...)
    DimDataset(data::Tuple{Vararg{<:AbstractDimArray}})
    DimDataset(data::NamedTuple{Keys,Vararg{<:AbstractDimArray}}) 
    DimDataset(data::NamedTuple, dims::DimTuple; metadata=nothing)

DimDataset holds multiple objects with the same dimensions, in a `NamedTuple`.
Indexing operates as for [`AbstractDimArray`](@ref), except it occurs for all
data layers of the dataset simulataneously. Layer objects can hold values of any type.

DimDataset can be constructed from multiple `AbstractDimArray` or a `NamedTuple`
of `AbstractArray` and a matching `dims` `Tuple`. If `AbstractDimArray`s have
the same name they will be given the name `:layer1`, substitiuting the actual
layer number for `1`.

`getindex` with `Int` or `Dimension`s or `Selector`s that resolve to `Int` will
return a `NamedTuple` of values from each layer in the dataset. This has very good
performace, and usually takes less time than the sum of indexing each array 
separately.

Indexing with a `Vector` or `Colon` will return another `DimDataset` where
all data layers have been sliced.  `setindex!` must pass a `Tuple` or `NamedTuple` maching 
the layers.

Most `Base` and `Statistics` methods that apply gto `AbstractArray` can be used on 
all layers of the dataset simulataneously. The result is a `DimDataset`, or
a `NamedTuple` if methods like `mean` are used without `dims` arguments, and 
return a single non-array value.

## Example

```jldoctest
julia> using DimensionalData

julia> A = [1.0 2.0 3.0; 4.0 5.0 6.0];

julia> dimz = (X([:a, :b]), Y(10.0:10.0:30.0))
(X (type X): Symbol[a, b] (AutoMode), Y (type Y): 10.0:10.0:30.0 (AutoMode))

julia> da1 = DimArray(1A, dimz, :one);



julia> da2 = DimArray(2A, dimz, :two);



julia> da3 = DimArray(3A, dimz, :three);



julia> ds = DimDataset(da1, da2, da3)
DimDataset{NamedTuple{(:one, :two, :three),Tuple{Array{Float64,2},Array{Float64,2},Array{Float64,2}}},2,Tuple{X{Array{Symbol,1},Categorical{Unordered{ForwardRelation}},NoMetadata},Y{StepRangeLen{Float64,Base.TwicePrecision{Float64},Base.TwicePrecision{Float64}},Sampled{Ordered{ForwardIndex,ForwardArray,ForwardRelation},Regular{Float64},Points},NoMetadata}},Tuple{},NamedTuple{(:one, :two, :three),Tuple{Nothing,Nothing,Nothing}}}((one = [1.0 2.0 3.0; 4.0 5.0 6.0], two = [2.0 4.0 6.0; 8.0 10.0 12.0], three = [3.0 6.0 9.0; 12.0 15.0 18.0]), (X (type X): Symbol[a, b] (Categorical: Unordered), Y (type Y): 10.0:10.0:30.0 (Sampled: Ordered Regular Points)), (), (one = nothing, two = nothing, three = nothing))

julia> ds[:b, 10.0]
(one = 4.0, two = 8.0, three = 12.0)

julia> ds[X(:a)]
DimDataset{NamedTuple{(:one, :two, :three),Tuple{Array{Float64,1},Array{Float64,1},Array{Float64,1}}},1,Tuple{Y{StepRangeLen{Float64,Base.TwicePrecision{Float64},Base.TwicePrecision{Float64}},Sampled{Ordered{ForwardIndex,ForwardArray,ForwardRelation},Regular{Float64},Points},NoMetadata}},Tuple{X{Symbol,Categorical{Unordered{ForwardRelation}},NoMetadata}},NamedTuple{(:one, :two, :three),Tuple{Nothing,Nothing,Nothing}}}((one = [1.0, 2.0, 3.0], two = [2.0, 4.0, 6.0], three = [3.0, 6.0, 9.0]), (Y (type Y): 10.0:10.0:30.0 (Sampled: Ordered Regular Points),), (X (type X): a (Categorical: Unordered),), (one = nothing, two = nothing, three = nothing))
```

"""
struct DimDataset{L,N,D,R,M} <: AbstractDimDataset{L,N,D}
    data::L
    dims::D
    refdims::R
    metadata::M
    DimDataset(data::L, dims::D, refdims::R, metadata::M) where {L,D,R,M} = begin
        N = length(dims)
        new{L,N,D,R,M}(data, dims, refdims, metadata)
    end
end
DimDataset(das::AbstractDimArray...) = DimDataset(das)
DimDataset(das::Tuple{Vararg{<:AbstractDimArray}}) =
    DimDataset(NamedTuple{uniquekeys(das)}(das))
DimDataset(das::NamedTuple{<:Any,<:Tuple{Vararg{<:AbstractDimArray}}}) = begin
    data = map(parent, das)
    dims = comparedims(das...)
    meta = map(metadata, das)
    refdims = () # das might have different refdims
    DimDataset(data, dims, refdims, meta)
end
DimDataset(data::NamedTuple, dims::DimTuple; refdims=(), metadata=nothing) =
    DimDataset(data, formatdims(first(data), dims), refdims, metadata)

data(ds::AbstractDimDataset) = ds.data
dimarrays(ds::AbstractDimDataset{<:NamedTuple{Keys}}) where Keys =
    NamedTuple{Keys}(map(Keys, values(ds)) do k, A
        DimArray(A, dims(ds), refdims(ds), k, nothing)
    end)
dims(ds::DimDataset) = ds.dims
metadata(ds::AbstractDimDataset) = ds.metadata
Base.keys(ds::AbstractDimDataset) = keys(data(ds))
Base.values(ds::AbstractDimDataset) = values(data(ds))

# Only compare data and dim - metadata and refdims can be different
Base.:(==)(ds1::AbstractDimDataset, ds2::AbstractDimDataset) = 
    data(ds1) == data(ds2) && dims(ds1) == dims(ds2)

rebuild(ds::AbstractDimDataset, data, dims=dims(ds), refdims=refdims(ds), metadata=metadata(ds)) =
    basetypeof(ds)(data, dims, refdims, metadata)

rebuildsliced(ds::AbstractDimDataset, data, I) =
    rebuild(ds, data, slicedims(ds, I)...)

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

# Symbol key
@propagate_inbounds Base.getindex(ds::AbstractDimDataset, key::Symbol) =
    DimArray(data(ds)[key], dims(ds), refdims(ds), key, nothing)

# No indices. These just prevent stack overflows
@propagate_inbounds Base.getindex(ds::AbstractDimDataset) = 
    map(A -> getindex(A), data(ds))
@propagate_inbounds Base.view(ds::AbstractDimDataset) = 
    map(A -> view(A), data(ds))
@propagate_inbounds Base.setindex!(ds::AbstractDimDataset, xs) = 
    map((A, x) -> setindex!(A, x), data(ds), xs)

# Integer getindex returns a single value
@propagate_inbounds Base.getindex(ds::AbstractDimDataset, i::Int, I::Int...) =
    map(A -> getindex(A, i, I...), data(ds))

# Standard indices
@propagate_inbounds Base.getindex(ds::AbstractDimDataset, i1::StandardIndices, i2::StandardIndices, I::StandardIndices...) = begin
    newdata = map(A -> getindex(A, i1, i2, I...), data(ds))
    rebuildsliced(ds, newdata, (i1, i2, I...))
end
@propagate_inbounds Base.view(ds::AbstractDimDataset, i1::StandardIndices, i2::StandardIndices, I::StandardIndices...) = begin
    newdata = map(A -> view(A, i1, i2, I...), data(ds))
    rebuildsliced(ds, newdata, (i1, i2, I...))
end
@propagate_inbounds Base.setindex!(ds::AbstractDimDataset, xs::Tuple, 
                              i1::StandardIndices, i2::StandardIndices, I::StandardIndices...) =
    map((A, x) -> setindex!(A, x, i1, i2, I...), data(ds), xs)
@propagate_inbounds Base.setindex!(ds::AbstractDimDataset{<:NamedTuple{K1}}, xs::NamedTuple{K2}, 
                                   i1::StandardIndices, i2::StandardIndices, I::StandardIndices...) where {K1,K2} = begin
    K1 == K2 || _keysmismatch(K1, K2)
    map((A, x) -> setindex!(A, x, i1, i2, I...), data(ds), xs)
end

# Linear indexing returns a NamedTuple of Arrays
@propagate_inbounds Base.getindex(ds::AbstractDimDataset{<:Any,N} where N, i::Union{Colon,AbstractArray}) =
    map(A -> getindex(A, i), data(ds))
# Exempt 1D DimArrays
@propagate_inbounds Base.getindex(ds::AbstractDimDataset{<:Any,1}, i::Union{Colon,AbstractArray}) =
    rebuildsliced(ds, map(A -> getindex(A, i), data(ds)), (i,))
# Linear indexing returns a NamedTuple of unwrapped SubArrays
@propagate_inbounds Base.view(ds::AbstractDimDataset{<:Any,N} where N, i::StandardIndices) =
    map(A -> view(A, i), data(ds))
# Exempt 1D DimArrays
@propagate_inbounds Base.view(ds::AbstractDimDataset{<:Any,1}, i::StandardIndices) =
    rebuildsliced(ds, map(A -> view(A, i), data(ds)), (i,))

# Cartesian indices
@propagate_inbounds Base.getindex(ds::AbstractDimDataset, I::CartesianIndex) =
    map(A -> getindex(A, I), data(ds))
@propagate_inbounds Base.view(ds::AbstractDimDataset, I::CartesianIndex) =
    map(A -> view(A, I), data(ds))
@propagate_inbounds Base.setindex!(ds::AbstractDimDataset, xs::Tuple, I::CartesianIndex) =
    map((A, x) -> setindex!(A, x, I), data(ds), xs)
@propagate_inbounds Base.setindex!(ds::AbstractDimDataset{<:NamedTuple{K1}}, 
                                   xs::NamedTuple{K2}, I::CartesianIndex) where {K1,K2} = begin
    K1 == K2 || _keysmismatch(K1, K2)
    map((A, x) -> setindex!(A, x, I), data(ds), xs)
end

_keysmismatch(K1, K2) = throw(ArgumentError("NamedTuple keys $K2 do not mach dataset keys $K1"))

# Selectors with standard indices
@propagate_inbounds Base.getindex(ds::AbstractDimDataset, i, I...) =
    getindex(ds, sel2indices(ds, maybeselector(i, I...))...)
@propagate_inbounds Base.view(ds::AbstractDimDataset, i, I...) =
    view(ds, sel2indices(ds, maybeselector(i, I...))...)
@propagate_inbounds Base.setindex!(ds::AbstractDimDataset, xs, i, I...) =
    setindex!(ds, xs, sel2indices(ds, maybeselector(i, I...))...)

# Dimensions
@propagate_inbounds Base.getindex(ds::AbstractDimDataset, dim::Dimension, dims::Dimension...) =
    getindex(ds, dims2indices(ds, (dim, dims...))...)
@propagate_inbounds Base.view(ds::AbstractDimDataset, dim::Dimension, dims::Dimension...) =
    view(ds, dims2indices(ds, (dim, dims...))...)
@propagate_inbounds Base.setindex!(ds::AbstractDimDataset, xs, dim::Dimension, dims::Dimension...) =
    setindex!(ds, xs, dims2indices(ds, (dim, dims...))...)

# Symbol keyword-argument indexing.
@propagate_inbounds Base.getindex(ds::AbstractDimDataset, args::Dimension...; kwargs...) =
    getindex(ds, args..., _kwargdims(kwargs.data)...)
@propagate_inbounds Base.view(ds::AbstractDimDataset, args::Dimension...; kwargs...) =
    view(ds, args..., _kwargdims(kwargs.data)...)
@propagate_inbounds Base.setindex!(ds::AbstractDimDataset, xs, args::Dimension...; kwargs...) =
    setindex!(ds, xs, args..., _kwargdims(kwargs)...)


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
                map(A -> ($mod.$fname)(f, A), data(ds))
            # Otherwise return a DimDataset
            ($_fname)(f::Function, ds::AbstractDimDataset, dims) =
                map(A -> ($mod.$fname)(f, A; dims=dims), ds)
        end
    end
end

