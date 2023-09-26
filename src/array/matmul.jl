using LinearAlgebra: AbstractTriangular, AbstractRotation

# Copied from symmetric.jl
const AdjTransVec = Union{Transpose{<:Any,<:AbstractVector},Adjoint{<:Any,<:AbstractVector}}
const RealHermSym{T<:Real,S} = Union{Hermitian{T,S}, Symmetric{T,S}}
const RealHermSymComplexHerm{T<:Real,S} = Union{Hermitian{T,S}, Symmetric{T,S}, Hermitian{Complex{T},S}}
const RealHermSymComplexSym{T<:Real,S} = Union{Hermitian{T,S}, Symmetric{T,S}, Symmetric{Complex{T},S}}

# Ambiguities
for (a, b) in (
    (AbstractDimVector, AbstractDimMatrix),
    (AbstractDimMatrix, AbstractDimVector),
    (AbstractDimMatrix, AbstractDimMatrix),
    (AbstractDimMatrix, AbstractVector),
    (AbstractDimVector, AbstractMatrix),
    (AbstractDimMatrix, AbstractMatrix),
    (AbstractMatrix, AbstractDimVector),
    (AbstractVector, AbstractDimMatrix),
    (AbstractMatrix, AbstractDimMatrix),
    (AbstractDimVector, Adjoint{<:Any,<:AbstractMatrix}),
    (AbstractDimVector, AdjTransVec),
    (AbstractDimVector, Transpose{<:Any,<:AbstractMatrix}),
    (AbstractDimMatrix, Diagonal),
    (AbstractDimMatrix, Adjoint{<:Any,<:RealHermSymComplexHerm}),
    (AbstractDimMatrix, Adjoint{<:Any,<:AbstractTriangular}),
    (AbstractDimMatrix, Transpose{<:Any,<:AbstractTriangular}),
    (AbstractDimMatrix, Transpose{<:Any,<:RealHermSymComplexSym}),
    (AbstractDimMatrix, AbstractTriangular),
    (Diagonal, AbstractDimVector),
    (Diagonal, AbstractDimMatrix),
    (Transpose{<:Any,<:AbstractTriangular}, AbstractDimVector),
    (Transpose{<:Any,<:AbstractTriangular}, AbstractDimMatrix),
    (Transpose{<:Any,<:AbstractVector}, AbstractDimVector),
    (Transpose{<:Real,<:AbstractVector}, AbstractDimVector),
    (Transpose{<:Any,<:AbstractVector}, AbstractDimMatrix),
    (Transpose{<:Any,<:RealHermSymComplexSym}, AbstractDimMatrix),
    (Transpose{<:Any,<:RealHermSymComplexSym}, AbstractDimVector),
    (AbstractTriangular, AbstractDimVector),
    (AbstractTriangular, AbstractDimMatrix),
    (Adjoint{<:Any,<:AbstractTriangular}, AbstractDimVector),
    (Adjoint{<:Any,<:AbstractVector}, AbstractDimMatrix),
    (Adjoint{<:Any,<:RealHermSymComplexHerm}, AbstractDimMatrix),
    (Adjoint{<:Any,<:AbstractTriangular}, AbstractDimMatrix),
    (Adjoint{<:Number,<:AbstractVector}, AbstractDimVector{<:Number}),
    (AdjTransVec, AbstractDimVector),
    (Adjoint{<:Any,<:RealHermSymComplexHerm}, AbstractDimVector),
)
    @eval Base.:*(A::$a, B::$b) = _rebuildmul(A, B)
end


Base.:*(A::AbstractDimVector, B::Adjoint{T,<:AbstractRotation}) where T = _rebuildmul(A, B)
Base.:*(A::Adjoint{T,<:AbstractRotation}, B::AbstractDimMatrix) where T = _rebuildmul(A, B)
Base.:*(A::Transpose{<:Any,<:AbstractMatrix{T}}, B::AbstractDimArray{S,1}) where {T,S} = _rebuildmul(A, B)
Base.:*(A::Adjoint{<:Any,<:AbstractMatrix{T}}, B::AbstractDimArray{S,1}) where {T,S} = _rebuildmul(A, B)


function _rebuildmul(A::AbstractDimVector, B::AbstractDimMatrix)
    # Vector has no dim 2 to compare
    rebuild(A, parent(A) * parent(B), (first(dims(A)), last(dims(B)),))
end
function _rebuildmul(A::AbstractDimMatrix, B::AbstractDimVector)
    comparedims(last(dims(A)), first(dims(B)); val=true)
    rebuild(A, parent(A) * parent(B), (first(dims(A)),))
end
function _rebuildmul(A::AbstractDimMatrix, B::AbstractDimMatrix)
    comparedims(last(dims(A)), first(dims(B)); val=true)
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
