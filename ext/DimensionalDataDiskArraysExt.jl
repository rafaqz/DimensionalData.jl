"""
    DimensionalDataDiskArraysExt

Extend some methods of DiskArrays (`cache`, etc) to work on the base data of any DimArray.  
"""
module DimensionalDataDiskArraysExt

using DimensionalData
import DimensionalData: AbstractBasicDimArray
import DiskArrays

DiskArrays.cache(da::AbstractBasicDimArray; kwargs...) = rebuild(da; data = DiskArrays.cache(parent(da); kwargs...))

DiskArrays.haschunks(da::AbstractBasicDimArray) = DiskArrays.haschunks(parent(da))
DiskArrays.eachchunk(da::AbstractBasicDimArray) = DiskArrays.eachchunk(parent(da))


end
