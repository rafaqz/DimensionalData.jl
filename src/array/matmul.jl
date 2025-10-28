using LinearAlgebra: AbstractTriangular, AbstractRotation

const STRICT_MATMUL_CHECKS = Ref(true)
const STRICT_MATMUL_DOCS = """
With `strict=true` we check [`Lookup`](@ref) [`Order`](@ref) and values 
before attempting matrix multiplication, to ensure that dimensions match closely. 

We always check that dimension names match in matrix multiplication.
If you don't want this either, explicitly use `parent(A)` before
multiplying to remove the `AbstractDimArray` wrapper completely.
"""

"""
    strict_matmul()

Check if strickt broadcasting checks are active.

$STRICT_MATMUL_DOCS
"""
strict_matmul() = STRICT_MATMUL_CHECKS[]

"""
    strict_matmul!(x::Bool)

Set global matrix multiplication checks to `strict`, or not for all `AbstractDimArray`.

$STRICT_MATMUL_DOCS
"""
strict_matmul!(x::Bool) = STRICT_MATMUL_CHECKS[] = x

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
    out_dims = (_leading_dim_mul(A), _trailing_dim_mul(B))
    rebuild(B, parent(A) * parent(B), out_dims)
end
function _rebuildmul(A::AbstractDimMatrix, B::AbstractDimVector)
    _comparedims_mul(A, B)
    out_dims = (_leading_dim_mul(A),)
    rebuild(B, parent(A) * parent(B), out_dims)
end
function _rebuildmul(A::AbstractDimMatrix, B::AbstractDimMatrix)
    _comparedims_mul(A, B)
    out_dims = (_leading_dim_mul(A), _trailing_dim_mul(B))
    rebuild(A, parent(A) * parent(B), out_dims)
end
function _rebuildmul(A::AbstractDimVector, B::AbstractMatrix)
    out_dims = (_leading_dim_mul(A), _trailing_dim_mul(B))
    rebuild(A, parent(A) * B, out_dims)
end
function _rebuildmul(A::AbstractDimMatrix, B::AbstractVector)
    newdata = parent(A) * B
    if newdata isa AbstractArray
        out_dims = (_leading_dim_mul(A),)
        rebuild(A, newdata, out_dims)
    else
        newdata
    end
end
function _rebuildmul(A::AbstractDimMatrix, B::AbstractMatrix)
    _comparedims_mul(A, B)
    out_dim = _leading_dim_mul(A)
    rebuild(A, parent(A) * B, (out_dim, AnonDim(Base.OneTo(size(B, 2)))))
end
function _rebuildmul(A::AbstractVector, B::AbstractDimMatrix)
    _comparedims_mul(A, B)
    out_dims = (_leading_dim_mul(A), _trailing_dim_mul(B))
    rebuild(B, A * parent(B), out_dims)
end
function _rebuildmul(A::AbstractMatrix, B::AbstractDimVector)
    _comparedims_mul(A, B)
    newdata = A * parent(B)
    if newdata isa AbstractArray
        out_dim = _leading_dim_mul(A)
        rebuild(B, newdata, (out_dim,))
    else
        newdata
    end
end
function _rebuildmul(A::AbstractMatrix, B::AbstractDimMatrix)
    _comparedims_mul(A, B)
    out_dim1 = _leading_dim_mul(A)
    rebuild(B, A * parent(B), (out_dim1, last(dims(B))))
end

function _comparedims_mul(a, b)
    adims = dims(a)
    adims === nothing && return true
    bdims = dims(b)
    bdims === nothing && return true
    # Dont need to compare length if we compare values
    isstrict = strict_matmul()
    comparedims(last(adims), first(bdims);
        order=isstrict, val=isstrict, length=false
    )
end

function _leading_dim_mul(a::AbstractVecOrMat)
    adims = dims(a)
    adims === nothing && return AnonDim(axes(a, 1))
    first(adims)
end

function _trailing_dim_mul(a::AbstractMatrix)
    adims = dims(a)
    adims === nothing && return AnonDim(axes(a, 2))
    last(adims)
end
