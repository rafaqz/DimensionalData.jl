# getindex/view/setindex! ======================================================

#### getindex/view ####

# Integer returns a single value, but not for view
@propagate_inbounds Base.getindex(A::AbstractDimArray, i1::Integer, i2::Integer, I::Integer...) =
    Base.getindex(parent(A), i1, i2, I...)
# No indices. These just prevent stack overflows
@propagate_inbounds Base.getindex(A::AbstractDimArray) = Base.getindex(parent(A))
@propagate_inbounds Base.view(A::AbstractDimArray) = rebuild(A, Base.view(parent(A)), ())

for f in (:getindex, :view, :dotview)
    @eval begin
        #### Array getindex/view ###
        @propagate_inbounds Base.$f(A::AbstractDimArray, i::Integer) = Base.$f(parent(A), i)
        @propagate_inbounds Base.$f(A::AbstractDimArray, I::CartesianIndex) = Base.$f(parent(A), I)
        @propagate_inbounds Base.$f(A::AbstractDimArray, I...) = Base.$f(A, dims2indices(A, I)...)
        # Linear indexing forwards to the parent array
        @propagate_inbounds Base.$f(A::AbstractDimArray, i::Union{Colon,AbstractVector{<:Integer}}) =
            Base.$f(parent(A), i)
        @propagate_inbounds Base.$f(A::AbstractDimArray, i::AbstractArray{<:Bool}) =
            Base.$f(parent(A), i)
        # Except 1D DimArrays
        @propagate_inbounds Base.$f(A::AbstractDimArray{<:Any, 1}, i::Union{Colon,AbstractVector{<:Integer}}) =
            rebuildsliced(Base.$f, A, Base.$f(parent(A), i), (i,))
        # Dimension indexing. Allows indexing with A[somedim=At(25.0)] for Dim{:somedim}
        @propagate_inbounds Base.$f(A::AbstractDimArray, args::Dimension...; kw...) =
            Base.$f(A, dims2indices(A, (args..., kwdims(values(kw))...))...)
        # Standard indices
        @propagate_inbounds Base.$f(A::AbstractDimArray, i1::StandardIndices, i2::StandardIndices, I::StandardIndices...) =
            rebuildsliced(Base.$f, A, Base.$f(parent(A), i1, i2, I...), (i1, i2, I...))
    end
end

#### setindex ####

@propagate_inbounds Base.setindex!(A::AbstractDimArray, x) = setindex!(parent(A), x)
@propagate_inbounds Base.setindex!(A::AbstractDimArray, x, args::Dimension...; kw...) =
    setindex!(A, x, dims2indices(A, (args..., kwdims(values(kw))...))...)
@propagate_inbounds Base.setindex!(A::AbstractDimArray, x, i, I...) =
    setindex!(A, x, dims2indices(A, (i, I...))...)
@propagate_inbounds Base.setindex!(A::AbstractDimArray, x, i1::StandardIndices, I::StandardIndices...) =
    setindex!(parent(A), x, i1, I...)
@propagate_inbounds Base.setindex!(A::AbstractDimArray, x, I::CartesianIndex) =
    setindex!(parent(A), x, I)
