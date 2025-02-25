const SelectorOrStandard = Union{SelectorOrInterval,StandardIndices}
const DimensionIndsArrays = Union{AbstractArray{<:Dimension},AbstractArray{<:DimTuple}}
const DimensionalIndices = Union{DimTuple,DimIndices,DimSelectors,Dimension,DimensionIndsArrays}
const _DimIndicesAmb = Union{AbstractArray{Union{}},DimIndices{<:Integer},DimSelectors{<:Integer}}
const IntegerOrCartesian = Union{Integer,CartesianIndex}

# getindex/view/setindex! ======================================================

for f in (:getindex, :view, :dotview)
    _dim_f = Symbol(:_dim_, f)

    # Integer indexing
    if f === :view
        # With one Integer and 0d and 1d we try to rebuild
        @eval @propagate_inbounds Base.$f(A::AbstractBasicDimArray{<:Any,0}, i::Integer) =
            rebuildsliced(Base.$f, A, (i,))
        # One Integer on a vector and we also rebuild
        @eval @propagate_inbounds Base.$f(A::AbstractBasicDimVector, i::Integer) =
            rebuildsliced(Base.$f, A, (i,))
        # More Integers and we rebuild
        @eval @propagate_inbounds Base.$f(A::AbstractBasicDimArray, i1::Integer, i2::Integer, I::Integer...) =
            rebuildsliced(Base.$f, A, (i1, i2, I...))
        # Otherwise its linear indexing, don't rebuild
        @eval @propagate_inbounds Base.$f(A::AbstractBasicDimArray, i::Integer) =
            Base.$f(parent(A), i)
    end
    @eval begin
        ### Standard indices
        @propagate_inbounds Base.$f(A::AbstractBasicDimVector, I::CartesianIndex) =
            Base.$f(A, to_indices(A, (I,))...)
        @propagate_inbounds Base.$f(A::AbstractBasicDimArray, I::CartesianIndex) =
            Base.$f(A, to_indices(A, (I,))...)
        @eval @propagate_inbounds Base.$f(A::AbstractBasicDimArray, i1::IntegerOrCartesian, i2::IntegerOrCartesian, Is::IntegerOrCartesian...) =
            Base.$f(A, to_indices(A, (i1, i2, Is...))...)
        # 1D DimArrays dont need linear indexing
        @propagate_inbounds Base.$f(A::AbstractBasicDimVector, i::Union{Colon,AbstractArray{<:Integer}}) =
            rebuildsliced(Base.$f, A, (i,))
        @propagate_inbounds Base.$f(A::AbstractBasicDimVector, I::CartesianIndices) = rebuildsliced(Base.$f, A, (I,))
        @propagate_inbounds Base.$f(A::AbstractBasicDimArray, I::CartesianIndices) = rebuildsliced(Base.$f, A, (I,))
        @eval @propagate_inbounds Base.$f(A::AbstractBasicDimArray, i1::StandardIndices, i2::StandardIndices, Is::StandardIndices...) =
            rebuildsliced(Base.$f, A, to_indices(A, (i1, i2, Is...)))

        ### Selector/Interval indexing
        @propagate_inbounds Base.$f(A::AbstractBasicDimVector, i::SelectorOrInterval) = 
            Base.$f(A, dims2indices(A, (i,))...)
        @propagate_inbounds Base.$f(A::AbstractBasicDimArray, i1::SelectorOrStandard, i2::SelectorOrStandard, I::SelectorOrStandard...) =
            Base.$f(A, dims2indices(A, (i1, i2, I...))...)
        @propagate_inbounds Base.$f(A::AbstractBasicDimVector, i::Selector{<:Extents.Extent}) = 
            Base.$f(A, dims2indices(A, i)...)
        @propagate_inbounds Base.$f(A::AbstractBasicDimArray, i::Selector{<:Extents.Extent}) = 
            Base.$f(A, dims2indices(A, i)...)

        # Extent indexing
        @propagate_inbounds Base.$f(A::AbstractBasicDimVector, extent::Extents.Extent) =
            Base.$f(A, dims2indices(A, extent)...)
        @propagate_inbounds Base.$f(A::AbstractBasicDimArray, extent::Extents.Extent) =
            Base.$f(A, dims2indices(A, extent)...)

        ### Dimension indexing
        @propagate_inbounds function Base.$f(A::AbstractBasicDimArray; kw...)
            # Need to use one method and check keywords to avoid method overwrites
            if isempty(kw)
                rebuildsliced(Base.$f, A, ())
            else
                $_dim_f(A, _simplify_dim_indices(kw2dims(values(kw))...,)...)
            end
        end
        @propagate_inbounds Base.$f(A::AbstractBasicDimArray, d1::DimensionalIndices; kw...) =
            $_dim_f(A, _simplify_dim_indices(d1, kw2dims(values(kw))...)...)
        @propagate_inbounds Base.$f(A::AbstractBasicDimArray, d1::DimensionalIndices, d2::DimensionalIndices, D::DimensionalIndices...; kw...) =
            $_dim_f(A, _simplify_dim_indices(d1, d2, D..., kw2dims(values(kw))...)...)
        @propagate_inbounds Base.$f(A::AbstractBasicDimVector, i::DimensionalIndices) =
            $_dim_f(A, _simplify_dim_indices(i)...)
 
        # All dimension indexing is passed to these underscore methods to minimise ambiguities
        @propagate_inbounds $_dim_f(A::AbstractBasicDimArray, ds::DimTuple) = $_dim_f(A, ds...)
        @propagate_inbounds $_dim_f(A::AbstractBasicDimArray, d1::Dimension, ds::Dimension...) =
            Base.$f(A, dims2indices(A, (d1, ds...))...)
        # Regular non-dimensional indexing
        @propagate_inbounds $_dim_f(A::AbstractBasicDimArray, I...) = Base.$f(A, I...)
        # Catch the edge case dims were passed but did not match - 
        # we want to index with all colons [:, :, ...], not []
        @propagate_inbounds $_dim_f(A::AbstractBasicDimArray{<:Any,N}) where N =
            rebuildsliced(Base.$f, A, ntuple(i -> Colon(), Val(N)))
        @propagate_inbounds function $_dim_f(
            A::AbstractBasicDimArray, 
            d1::Union{Dimension,DimensionIndsArrays}, 
            ds::Union{Dimension,DimensionIndsArrays}...
        )
            return merge_and_index(Base.$f, A, (d1, ds...))
        end
        @propagate_inbounds function $_dim_f(A::AbstractBasicDimArray{<:Any,0}, d1::Dimension, ds::Dimension...)
            Dimensions._extradimswarn((d1, ds...))
            return rebuildsliced(Base.$f, A, ())
        end
    end

    ##### AbstractDimArray only methods
    # Here we know we can just index into the parent object
    # Linear indexing forwards to the parent array as it will break the dimensions
    # AbstractBasicDimArray must defined their own methods
    @eval @propagate_inbounds Base.$f(A::AbstractDimArray, i::Union{Colon,AbstractArray{<:Integer}}) =
        Base.$f(parent(A), i)
    # Except for AbstractDimVector
    @eval @propagate_inbounds Base.$f(A::AbstractDimVector, i::Union{Colon,AbstractArray{<:Integer}}) =
        rebuildsliced(Base.$f, A, (i,))
    if f in (:getindex, :dotview)
        # We only define getindex with Integer on AbstractDimArray
        # AbstractBasicDimArray must defined their own
        @eval @propagate_inbounds Base.$f(A::AbstractDimVector, i::Integer) = Base.$f(parent(A), i)
        @eval @propagate_inbounds Base.$f(A::AbstractDimArray, i::Integer) = Base.$f(parent(A), i)
        @eval @propagate_inbounds Base.$f(A::AbstractDimArray, i1::Integer, i2::Integer, I::Integer...) =
            Base.$f(parent(A), i1, i2, I...)
        @eval @propagate_inbounds Base.$f(A::AbstractDimArray) = Base.$f(parent(A))
    end
    # Special case zero dimensional arrays being indexed with missing dims
    if f == :getindex
        # Catch this before the dimension is converted to ()
        @eval $_dim_f(A::AbstractDimArray{<:Any,0}) = rebuild(A, fill(A[]))
        @eval function $_dim_f(A::AbstractDimArray{<:Any,0}, d1::Dimension, ds::Dimension...)
            Dimensions._extradimswarn((d1, ds...))
            return rebuild(A, fill(A[]))
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
                # Index anyway with all Colon() just for type consistency
                f(M, basedims(M)...)
            end
        else
            m_inds = CartesianIndex.(dims2indices.(Ref(A), inds))
            f(A, m_inds)
        end
    else
        f(A, only(dims_to_merge))
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

Base.@assume_effects :foldable @inline _simplify_dim_indices(d::Dimension, ds...) =
    (d, _simplify_dim_indices(ds)...)
Base.@assume_effects :foldable @inline _simplify_dim_indices(d::Tuple, ds...) =
    (d..., _simplify_dim_indices(ds)...)
Base.@assume_effects :foldable @inline _simplify_dim_indices(d::AbstractArray{<:Dimension}, ds...) =
    (d, _simplify_dim_indices(ds)...)
Base.@assume_effects :foldable @inline _simplify_dim_indices(d::AbstractArray{<:DimTuple}, ds...) =
    (d, _simplify_dim_indices(ds)...)
Base.@assume_effects :foldable @inline _simplify_dim_indices(::Tuple{}) = ()
Base.@assume_effects :foldable @inline _simplify_dim_indices(d::DimIndices, ds...) =
    (dims(d)..., _simplify_dim_indices(ds)...)
Base.@assume_effects :foldable @inline function _simplify_dim_indices(d::DimSelectors, ds...)
    seldims = map(dims(d), d.selectors) do d, s
        # But the dimension values inside selectors
        rebuild(d, rebuild(s; val=val(d)))
    end
    return (seldims..., _simplify_dim_indices(ds)...)
end
Base.@assume_effects :foldable @inline _simplify_dim_indices() = ()

@inline _unwrap_cartesian(i1::CartesianIndices, I...) = (Tuple(i1)..., _unwrap_cartesian(I...)...)
@inline _unwrap_cartesian(i1::CartesianIndex, I...) = (Tuple(i1)..., _unwrap_cartesian(I...)...)
@inline _unwrap_cartesian(i1, I...) = (i1, _unwrap_cartesian(I...)...)
@inline _unwrap_cartesian() = ()

#### setindex ####

@propagate_inbounds Base.setindex!(A::AbstractDimArray, x) = setindex!(parent(A), x)
@propagate_inbounds Base.setindex!(A::AbstractDimArray, x, i, I...) =
    setindex!(A, x, dims2indices(A, (i, I...))...)
@propagate_inbounds Base.setindex!(A::AbstractDimArray, x, I::DimensionalIndices...; kw...) =
    setindex!(A, x, dims2indices(A, _simplify_dim_indices(I..., kw2dims(values(kw))...))...)
@propagate_inbounds Base.setindex!(::DimensionalData.AbstractDimArray, x, ::_DimIndicesAmb, ::_DimIndicesAmb...; kw...) = setindex!(A, x, dims2indices(A, _simplify_dim_indices(I..., kw2dims(values(kw))...))...)
@propagate_inbounds Base.setindex!(A::AbstractDimArray, x, i1::StandardIndices, I::StandardIndices...) =
    setindex!(parent(A), x, i1, I...)

# For @views macro to work with keywords
@propagate_inbounds Base.maybeview(A::AbstractDimArray, args...; kw...) =
    view(A, args...; kw...)
@propagate_inbounds Base.maybeview(A::AbstractDimArray, args::Vararg{Union{Number,Base.AbstractCartesianIndex}}; kw...) =
    view(A, args...; kw...)

# We only own this to_indices dispatch for AbstractBasicDimArray
Base.to_indices(A::AbstractBasicDimArray, inds, (r, args...)::Tuple{<:Type,Vararg}) =
    (Lookups._to_index(inds[1], r), to_indices(A, Base.tail(inds), args)...)