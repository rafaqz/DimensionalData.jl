# A basic DimensionArray type 

struct DimensionArray{T,N,D,R,A<:AbstractArray{T,N}} <: AbstractDimensionArray{T,N,D}
    data::A
    dims::D
    refdims::R
end
DimensionArray(a::AbstractArray{T,N}, dims; refdims=()) where {T,N} = 
    DimensionArray(a, checkdims(a, dims), refdims)

# Array interface (AbstractDimensionArray takes care of everything else)
Base.parent(a::DimensionArray) = a.data

# DimensionArray interface
rebuild(a::DimensionArray, data, dims, refdims) = DimensionArray(data, dims, refdims)

dims(a::DimensionArray) = a.dims
refdims(a::DimensionArray) = a.refdims
