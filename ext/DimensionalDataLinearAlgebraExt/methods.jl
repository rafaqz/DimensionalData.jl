# Ambiguity
Base.copyto!(dst::AbstractDimArray{T,2} where T, src::LinearAlgebra.AbstractQ) =
    (copyto!(parent(dst), src); dst)

# We need to override copy_similar because our `similar` doesn't work with size changes
# Fixed in Base in https://github.com/JuliaLang/julia/pull/53210
LinearAlgebra.copy_similar(A::AbstractDimArray, ::Type{T}) where {T} = copyto!(similar(A, T), A)

# See methods.jl 
@eval begin
    @inline LinearAlgebra.Transpose(A::AbstractDimArray{<:Any,2}) =
        rebuild(A, LinearAlgebra.Transpose(parent(A)), reverse(dims(A)))
    @inline LinearAlgebra.Transpose(A::AbstractDimArray{<:Any,1}) =
        rebuild(A, LinearAlgebra.Transpose(parent(A)), (AnonDim(NoLookup(Base.OneTo(1))), dims(A)...))
    @inline function LinearAlgebra.Transpose(s::AbstractDimStack)
        maplayers(s) do l
            ndims(l) > 1 ? LinearAlgebra.Transpose(l) : l
        end
    end
end
