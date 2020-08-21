using LinearAlgebra: AbstractTriangular, AbstractRotation

Base.:*(A::AbstractDimVector, B::AbstractDimMatrix) = rebuildmul(A, B)
Base.:*(A::AbstractDimMatrix, B::AbstractDimVector) = rebuildmul(A, B)
Base.:*(A::AbstractDimMatrix, B::AbstractDimMatrix) = rebuildmul(A, B)
Base.:*(A::AbstractDimMatrix, B::AbstractVector) = rebuildmul(A, B)
Base.:*(A::AbstractDimVector, B::AbstractMatrix) = rebuildmul(A, B)
Base.:*(A::AbstractDimMatrix, B::AbstractMatrix) = rebuildmul(A, B)
Base.:*(A::AbstractMatrix, B::AbstractDimVector) = rebuildmul(A, B)
Base.:*(A::AbstractVector, B::AbstractDimMatrix) = rebuildmul(A, B)
Base.:*(A::AbstractMatrix, B::AbstractDimMatrix) = rebuildmul(A, B)

# Copied from symmetric.jl
const AdjTransVec = Union{Transpose{<:Any,<:AbstractVector},Adjoint{<:Any,<:AbstractVector}}
const RealHermSym{T<:Real,S} = Union{Hermitian{T,S}, Symmetric{T,S}}
const RealHermSymComplexHerm{T<:Real,S} = Union{Hermitian{T,S}, Symmetric{T,S}, Hermitian{Complex{T},S}}
const RealHermSymComplexSym{T<:Real,S} = Union{Hermitian{T,S}, Symmetric{T,S}, Symmetric{Complex{T},S}}

# Ambiguities
Base.:*(A::AbstractDimMatrix, B::Diagonal) = rebuildmul(A, B)
Base.:*(A::AbstractDimVector, B::Adjoint{T,<:AbstractRotation}) where T = rebuildmul(A, B)
Base.:*(A::AbstractDimVector, B::Adjoint{<:Any,<:AbstractMatrix}) = rebuildmul(A, B)
Base.:*(A::AbstractDimVector, B::AdjTransVec) = rebuildmul(A, B)
Base.:*(A::AbstractDimVector, B::Transpose{<:Any,<:AbstractMatrix}) = rebuildmul(A, B)
Base.:*(A::AbstractDimMatrix, B::Adjoint{<:Any,<:RealHermSymComplexHerm}) = rebuildmul(A, B)
Base.:*(A::AbstractDimMatrix, B::Adjoint{<:Any,<:AbstractRotation}) = rebuildmul(A, B)
Base.:*(A::AbstractDimMatrix, B::Adjoint{<:Any,<:AbstractTriangular}) = rebuildmul(A, B)
Base.:*(A::AbstractDimMatrix, B::Transpose{<:Any,<:AbstractTriangular}) = rebuildmul(A, B)
Base.:*(A::AbstractDimMatrix, B::Transpose{<:Any,<:RealHermSymComplexSym}) = rebuildmul(A, B)
Base.:*(A::AbstractDimMatrix, B::AbstractTriangular) = rebuildmul(A, B)

Base.:*(A::Diagonal, B::AbstractDimVector) = rebuildmul(A, B)
Base.:*(A::Diagonal, B::AbstractDimMatrix) = rebuildmul(A, B)
Base.:*(A::Transpose{<:Any,<:AbstractTriangular}, B::AbstractDimVector) = rebuildmul(A, B)
Base.:*(A::Transpose{<:Any,<:AbstractTriangular}, B::AbstractDimMatrix) = rebuildmul(A, B)
Base.:*(A::Transpose{<:Any,<:AbstractVector}, B::AbstractDimVector) = rebuildmul(A, B)
Base.:*(A::Transpose{<:Real,<:AbstractVector}, B::AbstractDimVector) = rebuildmul(A, B)
Base.:*(A::Transpose{<:Any,<:AbstractVector}, B::AbstractDimMatrix) = rebuildmul(A, B)
Base.:*(A::Transpose{<:Any,<:AbstractMatrix{T}}, B::AbstractDimArray{S,1}) where {T,S} = rebuildmul(A, B)
Base.:*(A::Transpose{<:Any,<:RealHermSymComplexSym}, B::AbstractDimMatrix) = rebuildmul(A, B)
Base.:*(A::Transpose{<:Any,<:RealHermSymComplexSym}, B::AbstractDimVector) = rebuildmul(A, B)
Base.:*(A::AbstractTriangular, B::AbstractDimVector) = rebuildmul(A, B)
Base.:*(A::AbstractTriangular, B::AbstractDimMatrix) = rebuildmul(A, B)

Base.:*(A::Adjoint{<:Any,<:AbstractTriangular}, B::AbstractDimVector) = rebuildmul(A, B)
Base.:*(A::Adjoint{<:Any,<:AbstractVector}, B::AbstractDimMatrix) = rebuildmul(A, B)
Base.:*(A::Adjoint{<:Any,<:RealHermSymComplexHerm}, B::AbstractDimMatrix) = rebuildmul(A, B)
Base.:*(A::Adjoint{<:Any,<:AbstractTriangular}, B::AbstractDimMatrix) = rebuildmul(A, B)
Base.:*(A::Adjoint{<:Number,<:AbstractVector}, B::AbstractDimVector{<:Number}) = rebuildmul(A, B)
Base.:*(A::Adjoint{<:Any,<:AbstractMatrix{T}}, B::AbstractDimArray{S,1}) where {T,S} = rebuildmul(A, B)
Base.:*(A::Adjoint{T,<:AbstractRotation}, B::AbstractDimMatrix) where T = rebuildmul(A, B)
Base.:*(A::AdjTransVec, B::AbstractDimVector) = rebuildmul(A, B)
Base.:*(A::Adjoint{<:Any,<:RealHermSymComplexHerm}, B::AbstractDimVector) = rebuildmul(A, B)


rebuildmul(A::AbstractDimVector, B::AbstractDimMatrix) = begin
    # Vector has no dim 2 to compare
    rebuild(A, parent(A) * parent(B), (first(dims(A)), last(dims(B)),))
end
rebuildmul(A::AbstractDimMatrix, B::AbstractDimVector) = begin
    comparedims(last(dims(A)), first(dims(B)))
    rebuild(A, parent(A) * parent(B), (first(dims(A)),))
end
rebuildmul(A::AbstractDimMatrix, B::AbstractDimMatrix) = begin
    comparedims(last(dims(A)), first(dims(B)))
    rebuild(A, parent(A) * parent(B), (first(dims(A)), last(dims(B))))
end
rebuildmul(A::AbstractDimVector, B::AbstractMatrix) =
    rebuild(A, parent(A) * B, (first(dims(A)), AnonDim(Base.OneTo(size(B, 2)))))
rebuildmul(A::AbstractDimMatrix, B::AbstractVector) =
    rebuild(A, parent(A) * B, (first(dims(A)),))
rebuildmul(A::AbstractDimMatrix, B::AbstractMatrix) =
    rebuild(A, parent(A) * B, (first(dims(A)), AnonDim(Base.OneTo(size(B, 2)))))
rebuildmul(A::AbstractVector, B::AbstractDimMatrix) =
    rebuild(B, A * parent(B), (AnonDim(Base.OneTo(size(A, 1))), last(dims(B))) )
rebuildmul(A::AbstractMatrix, B::AbstractDimVector) =
    rebuild(B, A * parent(B), (AnonDim(Base.OneTo(1)),))
rebuildmul(A::AbstractMatrix, B::AbstractDimMatrix) =
    rebuild(B, A * parent(B), (AnonDim(Base.OneTo(size(A, 1))), last(dims(B))))
