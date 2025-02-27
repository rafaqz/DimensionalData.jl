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

@static if isdefined(DiskArrays, :isdisk)
    DiskArrays.isdisk(dd::AbstractDimArray) = DiskArrays.isdisk(parent(dd))
end

@static if isdefined(DiskArrays, :rechunk)
    DiskArrays.rechunk(x::Union{AbstractDimStack,AbstractDimArray}, chunks) = 
        modify(A -> DiskArrays.rechunk(A, chunks), x)
end

DiskArrays.haschunks(da::AbstractBasicDimArray) = DiskArrays.haschunks(parent(da))
DiskArrays.eachchunk(da::AbstractBasicDimArray) = DiskArrays.eachchunk(parent(da))


end
