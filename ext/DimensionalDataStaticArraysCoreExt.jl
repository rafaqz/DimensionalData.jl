module DimensionalDataStaticArraysCoreExt

using DimensionalData
import StaticArraysCore

Base.:*(A::StaticArraysCore.StaticArray{Tuple{N, M}, T, 2}, B::DimensionalData.AbstractDimVector) where {N, M, T} =
    DimensionalData._rebuildmul(A, B)

end
