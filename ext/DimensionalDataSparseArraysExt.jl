module DimensionalDataSparseArraysExt

using DimensionalData
using SparseArrays

# Ambiguity
Base.copyto!(dst::AbstractDimArray{T,2}, src::SparseArrays.CHOLMOD.Dense{T}) where T<:Union{Float64,ComplexF64} =
    (copyto!(parent(dst), src); dst)
Base.copyto!(dst::AbstractDimArray{T}, src::SparseArrays.CHOLMOD.Dense{T}) where T<:Union{Float64,ComplexF64} =
    (copyto!(parent(dst), src); dst)
Base.copyto!(dst::DimensionalData.AbstractDimArray, src::SparseArrays.CHOLMOD.Dense) =
    (copyto!(parent(dst), src); dst)
Base.copyto!(dst::AbstractDimArray{T,2} where T, src::SparseArrays.AbstractSparseMatrixCSC) =
    (copyto!(parent(dst), src); dst)
Base.copyto!(dst::SparseArrays.AbstractCompressedVector, src::AbstractDimArray{T, 1} where T) =
    (copyto!(dst, parent(src)); dst)

function Base.copyto!(
    dst::AbstractDimArray{<:Any,2}, 
    dst_i::CartesianIndices{2, R} where R<:Tuple{OrdinalRange{Int64, Int64}, OrdinalRange{Int64, Int64}}, 
    src::SparseArrays.AbstractSparseMatrixCSC{<:Any}, 
    src_i::CartesianIndices{2, R} where R<:Tuple{OrdinalRange{Int64, Int64}, OrdinalRange{Int64, Int64}}
)
    copyto!(parent(dst), dst_i, src, src_i)
    return dst
end
Base.copy!(dst::SparseArrays.AbstractCompressedVector{T}, src::AbstractDimArray{T, 1}) where T =
    (copy!(dst, parent(src)); dst)
Base.copy!(dst::SparseArrays.SparseVector, src::AbstractDimArray{T,1}) where T =
    (copy!(dst, parent(src)); dst)

end
