# getindex/view/setindex! ======================================================

#### getindex/view ####

# Integer returns a single value, but not for view
@propagate_inbounds Base.getindex(A::AbstractDimArray, i1::Integer, i2::Integer, I::Integer...) =
    Base.getindex(parent(A), i1, i2, I...)
# No indices. These just prevent stack overflows
@propagate_inbounds Base.getindex(A::AbstractDimArray) = Base.getindex(parent(A))
@propagate_inbounds Base.view(A::AbstractDimArray) = rebuild(A, Base.view(parent(A)), ())

const SelectorOrStandard = Union{SelectorOrInterval,StandardIndices}

for f in (:getindex, :view, :dotview)
    @eval begin
        if Base.$f === Base.view
            @eval @propagate_inbounds function Base.$f(A::AbstractDimArray, i::Union{Integer,CartesianIndex,CartesianIndices})
                I = to_indices(A, (i,))
                x = Base.$f(parent(A), I...)
                rebuildsliced(Base.$f, A, x, I)
            end
        else
            #### Array getindex/view ###
            @propagate_inbounds Base.$f(A::AbstractDimArray, i::Integer) = Base.$f(parent(A), i)
            @propagate_inbounds Base.$f(A::AbstractDimArray, i::CartesianIndex) = Base.$f(parent(A), i)
            # CartesianIndices
            @propagate_inbounds Base.$f(A::AbstractDimArray, I::CartesianIndices) =
                Base.$f(A, to_indices(A, (I,))...)
        end
        # Linear indexing forwards to the parent array as it will break the dimensions
        @propagate_inbounds Base.$f(A::AbstractDimArray, i::Union{Colon,AbstractVector{<:Integer}}) =
            Base.$f(parent(A), i)
        @propagate_inbounds Base.$f(A::AbstractDimArray, i::AbstractArray{<:Bool}) =
            Base.$f(parent(A), i)
        # Except 1D DimArrays
        @propagate_inbounds Base.$f(A::AbstractDimArray{<:Any,1}, i::Union{Colon,AbstractVector{<:Integer}}) =
            rebuildsliced(Base.$f, A, Base.$f(parent(A), i), (i,))
        # Selector/Interval indexing
        @propagate_inbounds Base.$f(A::AbstractDimArray, i1::SelectorOrStandard, I::SelectorOrStandard...) =
            Base.$f(A, dims2indices(A, (i1, I...))...)
        @propagate_inbounds Base.$f(A::AbstractDimArray, extent::Extents.Extent) =
            Base.$f(A, dims2indices(A, extent)...)
        # Dimension indexing. Allows indexing with A[somedim=At(25.0)] for Dim{:somedim}
        @propagate_inbounds Base.$f(A::AbstractDimArray, args::Dimension...; kw...) =
            Base.$f(A, dims2indices(A, (args..., kwdims(values(kw))...))...)
        # Everything else works on the parent array - such as custom indexing types from other packages.
        # We can't know what they do so cant handle the potential dimension transformations
        @propagate_inbounds Base.$f(A::AbstractDimArray, i1, I...) = Base.$f(parent(A), i1, I...)
    end
    # Standard indices
    if f == :view
        @eval @propagate_inbounds function Base.$f(A::AbstractDimArray, i1::StandardIndices, i2::StandardIndices, I::StandardIndices...)
            I = to_indices(A, (i1, i2, I...))
            x = Base.$f(parent(A), I...)
            rebuildsliced(Base.$f, A, x, I)
        end
    else
        @eval @propagate_inbounds function Base.$f(A::AbstractDimArray, i1::StandardIndices, i2::StandardIndices, I::StandardIndices...)
            I = to_indices(A, (i1, i2, I...))
            x = Base.$f(parent(A), I...)
            all(i -> i isa Integer, I) ? x : rebuildsliced(Base.$f, A, x, I)
        end
    end
end

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
