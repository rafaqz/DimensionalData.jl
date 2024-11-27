"""
    DimensionalDataDiskArraysExt

Extend some methods of DiskArrays (`cache`, etc) to work on the base data of any DimArray.  
"""
module DimensionalDataDiskArraysExt

using DimensionalData
import DimensionalData: AbstractBasicDimArray
import DiskArrays

# cache was only introduced in DiskArrays v0.4, so
# we lock out the method definition if the method does
# not exist.
@static if isdefined(DiskArrays, :cache)
    DiskArrays.cache(x::Union{AbstractDimStack,AbstractDimArray}; kw...) = 
        modify(A -> DiskArrays.cache(A; kw...), x)
end

DiskArrays.haschunks(da::AbstractBasicDimArray) = DiskArrays.haschunks(parent(da))
DiskArrays.eachchunk(da::AbstractBasicDimArray) = DiskArrays.eachchunk(parent(da))


end
