# getindex/view/setindex! ======================================================

#### getindex/view ####

# Integer returns a single value, but not for view
@propagate_inbounds Base.getindex(A::AbstractDimArray, i1::Integer, i2::Integer, I::Integer...) =
    Base.getindex(parent(A), i1, i2, I...)
# No indices. These just prevent stack overflows
@propagate_inbounds Base.getindex(A::AbstractDimArray) = Base.getindex(parent(A))
@propagate_inbounds Base.view(A::AbstractDimArray) = rebuild(A, Base.view(parent(A)), ())

const SelectorOrStandard = Union{SelectorOrInterval,StandardIndices}
const DimensionIndsArrays = Union{AbstractArray{<:Dimension},AbstractArray{<:DimTuple}}
const DimensionalIndices = Union{DimTuple,DimIndices,DimSelectors,Dimension,DimensionIndsArrays}
const _DimIndicesAmb = Union{AbstractArray{Union{}},DimIndices{<:Integer},DimSelectors{<:Integer}}

for f in (:getindex, :view, :dotview)
    _f = Symbol(:_, f)
    @eval begin
        if Base.$f === Base.view
            @eval @propagate_inbounds function Base.$f(A::AbstractDimArray, i::Union{CartesianIndex,CartesianIndices})
                x = Base.$f(parent(A), i)
                I = to_indices(A, (i,))
                rebuildsliced(Base.$f, A, x, I)
            end
            @eval @propagate_inbounds function Base.$f(A::AbstractDimArray, i::Integer)
                x = Base.$f(parent(A), i)
                I = to_indices(A, (CartesianIndices(A)[i],))
                rebuildsliced(Base.$f, A, x, I)
            end
        else
            #### Array getindex/view ###
            # These are needed to resolve ambiguity
            @propagate_inbounds Base.$f(A::AbstractDimArray, i::Integer) = Base.$f(parent(A), i)
            @propagate_inbounds Base.$f(A::AbstractDimArray, i::CartesianIndex) = Base.$f(parent(A), i)
            # CartesianIndices
            @propagate_inbounds Base.$f(A::AbstractDimArray, I::CartesianIndices) =
                Base.$f(A, to_indices(A, (I,))...)
        end
        # Linear indexing forwards to the parent array as it will break the dimensions
        @propagate_inbounds Base.$f(A::AbstractDimArray, i::Union{Colon,AbstractArray{<:Integer}}) =
            Base.$f(parent(A), i)
        # Except 1D DimArrays
        @propagate_inbounds Base.$f(A::AbstractDimVector, i::Union{Colon,AbstractArray{<:Integer}}) =
            rebuildsliced(Base.$f, A, Base.$f(parent(A), i), (i,))
        # Selector/Interval indexing
        @propagate_inbounds Base.$f(A::AbstractDimArray, i1::SelectorOrStandard, I::SelectorOrStandard...) =
            Base.$f(A, dims2indices(A, (i1, I...))...)

        @propagate_inbounds Base.$f(A::AbstractBasicDimArray, extent::Extents.Extent) =
            Base.$f(A, dims2indices(A, extent)...)
        # All Dimension indexing modes combined
        @propagate_inbounds Base.$f(A::AbstractBasicDimArray, D::DimensionalIndices...; kw...) =
            $_f(A, _simplify_dim_indices(D..., kwdims(values(kw))...)...)
        # For ambiguity
        @propagate_inbounds Base.$f(A::AbstractDimArray, i::DimIndices) = $_f(A, i)
        @propagate_inbounds Base.$f(A::AbstractDimArray, i::DimSelectors) = $_f(A, i)
        @propagate_inbounds Base.$f(A::AbstractDimVector, i::DimIndices) = $_f(A, i)
        @propagate_inbounds Base.$f(A::AbstractDimVector, i::DimSelectors) = $_f(A, i)
        @propagate_inbounds Base.$f(A::AbstractDimVector, i::_DimIndicesAmb) = $_f(A, i)
        @propagate_inbounds Base.$f(A::AbstractDimArray, i1::_DimIndicesAmb, I::_DimIndicesAmb...) = $_f(A, i1, I...)

        # Use underscore methods to minimise ambiguities
        @propagate_inbounds $_f(A::AbstractBasicDimArray, d1::Dimension, ds::Dimension...) =
            Base.$f(A, dims2indices(A, (d1, ds...))...)
        @propagate_inbounds $_f(A::AbstractBasicDimArray, ds::Dimension...; kw...) =
            Base.$f(A, dims2indices(A, ds)...)
        @propagate_inbounds function $_f(
            A::AbstractBasicDimArray, dims::Union{Dimension,DimensionIndsArrays}...
        )
            return merge_and_index($f, A, dims)
        end
    end
    # Standard indices
    if f == :view
        @eval @propagate_inbounds function Base.$f(A::AbstractDimArray, i1::StandardIndices, i2::StandardIndices, I::StandardIndices...)
            I = to_indices(A, (i1, i2, I...))
            x = Base.$f(parent(A), I...)
            rebuildsliced(Base.$f, A, x, I)
        end
    else
        @eval @propagate_inbounds function Base.$f(A::AbstractDimArray, i1::StandardIndices, i2::StandardIndices, Is::StandardIndices...)
            I = to_indices(A, (i1, i2, Is...))
            x = Base.$f(parent(A), I...)
            all(i -> i isa Integer, I) ? x : rebuildsliced(Base.$f, A, x, I)
        end
    end
end


function merge_and_index(f, A, dims)
    dims, inds_arrays = _separate_dims_arrays(_simplify_dim_indices(dims...)...)
    # No arrays here, so abort (dispatch is tricky...)
    length(inds_arrays) == 0 && return f(A, dims...)

    V1 = length(dims) > 0 ? view(A, dims...) : A
    # We have an array of dims of dim tuples
    V2 = reduce(inds_arrays[1:end-1]; init=V1) do A, i
        _merge_and_index(view, A, i)
    end

    return _merge_and_index(f, V2, inds_arrays[end])
end

function _merge_and_index(f, A, inds)
    # Get any other dimensions not passed in
    dims_to_merge = first(inds)
    if length(dims_to_merge) > 1
        if inds isa AbstractVector
            M = mergedims(A, dims_to_merge)
            ods = otherdims(M, DD.dims(A))
            if length(ods) > 0
                mdim = only(ods)
                lazylinear = rebuild(mdim, LazyDims2Linear(inds, DD.dims(A, dims_to_merge)))
                f(M, lazylinear)
            else
                # Index anyway with al Colon() just for type consistency
                f(M, basedims(M)...)
            end
        else
            m_inds = CartesianIndex.(dims2indices.(Ref(A), inds))
            f(A, m_inds)
        end
    else
        d = first(dims_to_merge)
        val_array = reinterpret(typeof(val(d)), dims_to_merge)
        f(A, rebuild(d, val_array))
    end
end

# This AbstractArray is for indexing, presenting as Array{CartesianIndex}
# `CartesianIndex` are generated on the fly from `dimtuples`,
# which is e.g. a view into DimIndices
struct LazyDims2Cartesian{T,N,D,A<:AbstractArray{<:Any,N}} <: AbstractArray{T,N}
    dimtuples::A
    dims::D
end
function LazyDims2Cartesian(dimtuples::A, dims::D) where {A<:AbstractArray{<:DimTuple,N},D<:DimTuple} where N
    LazyDims2Cartesian{CartesianIndex{length(dims)},N,D,A}(dimtuples, dims)
end

dims(A::LazyDims2Cartesian) = A.dims

Base.size(A::LazyDims2Cartesian) = size(A.dimtuples)
Base.getindex(A::LazyDims2Cartesian, I::Integer...) =
    CartesianIndex(dims2indices(DD.dims(A), A.dimtuples[I...]))

struct LazyDims2Linear{N,D,A<:AbstractArray{<:Any,N}} <: AbstractArray{Int,N}
    dimtuples::A
    dims::D
end
function LazyDims2Linear(dimtuples::A, dims::D) where {A<:AbstractArray{<:DimTuple,N},D<:DimTuple} where N
    LazyDims2Linear{N,D,A}(dimtuples, dims)
end

dims(A::LazyDims2Linear) = A.dims

Base.size(A::LazyDims2Linear) = size(A.dimtuples)
Base.getindex(A::LazyDims2Linear, I::Integer...) =
    LinearIndices(size(dims(A)))[dims2indices(DD.dims(A), A.dimtuples[I...])...]

function _separate_dims_arrays(d::Dimension, ds...)
    ds, as = _separate_dims_arrays(ds...)
    (ds..., d), as
end
function _separate_dims_arrays(a::AbstractArray, ds...)
    ds, as = _separate_dims_arrays(ds...)
    ds, (a, as...)
end
_separate_dims_arrays() = (), ()

Base.@assume_effects :foldable _simplify_dim_indices(d::Dimension, ds...) =
    (d, _simplify_dim_indices(ds)...)
Base.@assume_effects :foldable _simplify_dim_indices(d::Tuple, ds...) =
    (d..., _simplify_dim_indices(ds)...)
Base.@assume_effects :foldable _simplify_dim_indices(d::AbstractArray{<:Dimension}, ds...) =
    (d, _simplify_dim_indices(ds)...)
Base.@assume_effects :foldable _simplify_dim_indices(d::AbstractArray{<:DimTuple}, ds...) =
    (d, _simplify_dim_indices(ds)...)
Base.@assume_effects :foldable _simplify_dim_indices(::Tuple{}) = ()
Base.@assume_effects :foldable _simplify_dim_indices(d::DimIndices, ds...) =
    (dims(d)..., _simplify_dim_indices(ds)...)
Base.@assume_effects :foldable function _simplify_dim_indices(d::DimSelectors, ds...)
    seldims = map(dims(d), d.selectors) do d, s
        # But the dimension values inside selectors
        rebuild(d, rebuild(s; val=val(d)))
    end
    return (seldims..., _simplify_dim_indices(ds)...)
end
Base.@assume_effects :foldable _simplify_dim_indices() = ()

@inline _unwrap_cartesian(i1::CartesianIndices, I...) = (Tuple(i1)..., _unwrap_cartesian(I...)...)
@inline _unwrap_cartesian(i1::CartesianIndex, I...) = (Tuple(i1)..., _unwrap_cartesian(I...)...)
@inline _unwrap_cartesian(i1, I...) = (i1, _unwrap_cartesian(I...)...)
@inline _unwrap_cartesian() = ()

#### setindex ####

@propagate_inbounds Base.setindex!(A::AbstractDimArray, x) = setindex!(parent(A), x)
@propagate_inbounds Base.setindex!(A::AbstractDimArray, x, args::Dimension...; kw...) =
    setindex!(A, x, dims2indices(A, (args..., kwdims(values(kw))...))...)
@propagate_inbounds Base.setindex!(A::AbstractDimArray, x, i, I...) =
    setindex!(A, x, dims2indices(A, (i, I...))...)
@propagate_inbounds Base.setindex!(A::AbstractDimArray, x, i1::StandardIndices, I::StandardIndices...) =
    setindex!(parent(A), x, i1, I...)

# For @views macro to work with keywords
Base.maybeview(A::AbstractDimArray, args...; kw...) =
    view(A, args...; kw...)
Base.maybeview(A::AbstractDimArray, args::Vararg{Union{Number,Base.AbstractCartesianIndex}}; kw...) =
    view(A, args...; kw...)
