# A basic DimensionalArray type 

struct DimensionalArray{T,N,D,R,A<:AbstractArray{T,N}} <: AbstractDimensionalArray{T,N,D}
    data::A
    dims::D
    refdims::R
end
DimensionalArray(a::AbstractArray{T,N}, dims; refdims=()) where {T,N} = 
    DimensionalArray(a, checkdims(a, dims), refdims)

# Array interface (AbstractDimensionalArray takes care of everything else)
Base.parent(a::DimensionalArray) = a.data

# DimensionalArray interface
rebuild(a::DimensionalArray, data, dims, refdims) = DimensionalArray(data, dims, refdims)

dims(a::DimensionalArray) = a.dims
refdims(a::DimensionalArray) = a.refdims
