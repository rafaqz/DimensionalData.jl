using LinearAlgebra: AbstractTriangular, AbstractRotation

Base.:*(A::AbstractDimVector, B::AbstractDimMatrix) = _rebuildmul(A, B)
Base.:*(A::AbstractDimMatrix, B::AbstractDimVector) = _rebuildmul(A, B)
Base.:*(A::AbstractDimMatrix, B::AbstractDimMatrix) = _rebuildmul(A, B)
Base.:*(A::AbstractDimMatrix, B::AbstractVector) = _rebuildmul(A, B)
Base.:*(A::AbstractDimVector, B::AbstractMatrix) = _rebuildmul(A, B)
Base.:*(A::AbstractDimMatrix, B::AbstractMatrix) = _rebuildmul(A, B)
Base.:*(A::AbstractMatrix, B::AbstractDimVector) = _rebuildmul(A, B)
Base.:*(A::AbstractVector, B::AbstractDimMatrix) = _rebuildmul(A, B)
Base.:*(A::AbstractMatrix, B::AbstractDimMatrix) = _rebuildmul(A, B)

# Copied from symmetric.jl
const AdjTransVec = Union{Transpose{<:Any,<:AbstractVector},Adjoint{<:Any,<:AbstractVector}}
const RealHermSym{T<:Real,S} = Union{Hermitian{T,S}, Symmetric{T,S}}
const RealHermSymComplexHerm{T<:Real,S} = Union{Hermitian{T,S}, Symmetric{T,S}, Hermitian{Complex{T},S}}
const RealHermSymComplexSym{T<:Real,S} = Union{Hermitian{T,S}, Symmetric{T,S}, Symmetric{Complex{T},S}}

# Ambiguities
Base.:*(A::AbstractDimMatrix, B::Diagonal) = _rebuildmul(A, B)
Base.:*(A::AbstractDimVector, B::Adjoint{T,<:AbstractRotation}) where T = _rebuildmul(A, B)
Base.:*(A::AbstractDimVector, B::Adjoint{<:Any,<:AbstractMatrix}) = _rebuildmul(A, B)
Base.:*(A::AbstractDimVector, B::AdjTransVec) = _rebuildmul(A, B)
Base.:*(A::AbstractDimVector, B::Transpose{<:Any,<:AbstractMatrix}) = _rebuildmul(A, B)
Base.:*(A::AbstractDimMatrix, B::Adjoint{<:Any,<:RealHermSymComplexHerm}) = _rebuildmul(A, B)
Base.:*(A::AbstractDimMatrix, B::Adjoint{<:Any,<:AbstractRotation}) = _rebuildmul(A, B)
Base.:*(A::AbstractDimMatrix, B::Adjoint{<:Any,<:AbstractTriangular}) = _rebuildmul(A, B)
Base.:*(A::AbstractDimMatrix, B::Transpose{<:Any,<:AbstractTriangular}) = _rebuildmul(A, B)
Base.:*(A::AbstractDimMatrix, B::Transpose{<:Any,<:RealHermSymComplexSym}) = _rebuildmul(A, B)
Base.:*(A::AbstractDimMatrix, B::AbstractTriangular) = _rebuildmul(A, B)

Base.:*(A::Diagonal, B::AbstractDimVector) = _rebuildmul(A, B)
Base.:*(A::Diagonal, B::AbstractDimMatrix) = _rebuildmul(A, B)
Base.:*(A::Transpose{<:Any,<:AbstractTriangular}, B::AbstractDimVector) = _rebuildmul(A, B)
Base.:*(A::Transpose{<:Any,<:AbstractTriangular}, B::AbstractDimMatrix) = _rebuildmul(A, B)
Base.:*(A::Transpose{<:Any,<:AbstractVector}, B::AbstractDimVector) = _rebuildmul(A, B)
Base.:*(A::Transpose{<:Real,<:AbstractVector}, B::AbstractDimVector) = _rebuildmul(A, B)
Base.:*(A::Transpose{<:Any,<:AbstractVector}, B::AbstractDimMatrix) = _rebuildmul(A, B)
Base.:*(A::Transpose{<:Any,<:AbstractMatrix{T}}, B::AbstractDimArray{S,1}) where {T,S} = _rebuildmul(A, B)
Base.:*(A::Transpose{<:Any,<:RealHermSymComplexSym}, B::AbstractDimMatrix) = _rebuildmul(A, B)
Base.:*(A::Transpose{<:Any,<:RealHermSymComplexSym}, B::AbstractDimVector) = _rebuildmul(A, B)
Base.:*(A::AbstractTriangular, B::AbstractDimVector) = _rebuildmul(A, B)
Base.:*(A::AbstractTriangular, B::AbstractDimMatrix) = _rebuildmul(A, B)

Base.:*(A::Adjoint{<:Any,<:AbstractTriangular}, B::AbstractDimVector) = _rebuildmul(A, B)
Base.:*(A::Adjoint{<:Any,<:AbstractVector}, B::AbstractDimMatrix) = _rebuildmul(A, B)
Base.:*(A::Adjoint{<:Any,<:RealHermSymComplexHerm}, B::AbstractDimMatrix) = _rebuildmul(A, B)
Base.:*(A::Adjoint{<:Any,<:AbstractTriangular}, B::AbstractDimMatrix) = _rebuildmul(A, B)
Base.:*(A::Adjoint{<:Number,<:AbstractVector}, B::AbstractDimVector{<:Number}) = _rebuildmul(A, B)
Base.:*(A::Adjoint{<:Any,<:AbstractMatrix{T}}, B::AbstractDimArray{S,1}) where {T,S} = _rebuildmul(A, B)
Base.:*(A::Adjoint{T,<:AbstractRotation}, B::AbstractDimMatrix) where T = _rebuildmul(A, B)
Base.:*(A::AdjTransVec, B::AbstractDimVector) = _rebuildmul(A, B)
Base.:*(A::Adjoint{<:Any,<:RealHermSymComplexHerm}, B::AbstractDimVector) = _rebuildmul(A, B)


function _rebuildmul(A::AbstractDimVector, B::AbstractDimMatrix)
    # Vector has no dim 2 to compare
    rebuild(A, parent(A) * parent(B), (first(dims(A)), last(dims(B)),))
end
function _rebuildmul(A::AbstractDimMatrix, B::AbstractDimVector)
    comparedims(last(dims(A)), first(dims(B)))
    rebuild(A, parent(A) * parent(B), (first(dims(A)),))
end
function _rebuildmul(A::AbstractDimMatrix, B::AbstractDimMatrix)
    comparedims(last(dims(A)), first(dims(B)))
    rebuild(A, parent(A) * parent(B), (first(dims(A)), last(dims(B))))
end
function _rebuildmul(A::AbstractDimVector, B::AbstractMatrix)
    rebuild(A, parent(A) * B, (first(dims(A)), AnonDim(Base.OneTo(size(B, 2)))))
end
function _rebuildmul(A::AbstractDimMatrix, B::AbstractVector)
    newdata = parent(A) * B
    if newdata isa AbstractArray
        rebuild(A, parent(A) * B, (first(dims(A)),))
    else
        newdata
    end
end
function _rebuildmul(A::AbstractDimMatrix, B::AbstractMatrix)
    rebuild(A, parent(A) * B, (first(dims(A)), AnonDim(Base.OneTo(size(B, 2)))))
end
function _rebuildmul(A::AbstractVector, B::AbstractDimMatrix)
    rebuild(B, A * parent(B), (AnonDim(Base.OneTo(size(A, 1))), last(dims(B))))
end
function _rebuildmul(A::AbstractMatrix, B::AbstractDimVector)
    newdata = A * parent(B)
    if newdata isa AbstractArray
        rebuild(B, A * parent(B), (AnonDim(Base.OneTo(1)),))
    else
        newdata
    end
end
function _rebuildmul(A::AbstractMatrix, B::AbstractDimMatrix)
    rebuild(B, A * parent(B), (AnonDim(Base.OneTo(size(A, 1))), last(dims(B))))
end
