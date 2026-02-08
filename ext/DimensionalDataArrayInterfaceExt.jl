module DimensionalDataArrayInterfaceExt

using DimensionalData: AbstractDimArray
import ArrayInterface

ArrayInterface.parent_type(::Type{<:AbstractDimArray{T,N,D,A}}) where {T,N,D,A} = A

end
