# OpaqueArray is an array that doesn't know what it holds, to simplify dispatch.
# One key property is that `parent(A::OpaqueArray)` returns the `OpaqueArray` `A`
# not the array it holds. 
# 
# It is often used here to hide dimensional arrays that may be generated lazily,
# To force them to act like simple Arrays without dimensional properties.
#
# OpaqueArray can also hold something that is not an AbstractArray itself.
struct OpaqueArray{T,N,P} <: AbstractArray{T,N}
    parent::P
end
OpaqueArray(A::P) where P<:AbstractArray{T,N} where {T,N} = OpaqueArray{T,N,P}(A)
OpaqueArray(st::P) where P<:AbstractDimStack{<:Any,T,N} where {T,N} = OpaqueArray{T,N,P}(st)

Base.size(A::OpaqueArray) = size(A.parent)
Base.getindex(A::OpaqueArray, I::Union{StandardIndices,Not{<:StandardIndices}}...) = 
    Base.getindex(A.parent, I...)
Base.setindex!(A::OpaqueArray, x, I::Union{StandardIndices,Not{<:StandardIndices}}...) = 
    Base.setindex!(A.parent, x, I...)