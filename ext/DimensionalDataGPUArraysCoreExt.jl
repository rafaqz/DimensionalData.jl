module DimensionalDataGPUArraysCoreExt

using DimensionalData: AbstractDimArray
using GPUArraysCore: AbstractGPUArrayStyle
using Base.Broadcast: Broadcasted

function Base.copyto!(des::AbstractDimArray, bc::Broadcasted{<:AbstractGPUArrayStyle})
    copyto!(parent(des), bc)
    return des
end

end
