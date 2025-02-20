"""
    DimensionalDataDiskArraysExt

Extend some methods of DiskArrays (`cache`, etc) to work on the base data of any DimArray.  
"""
module DimensionalDataDiskArraysExt

using DimensionalData
import DimensionalData: AbstractBasicDimArray
import DiskArrays

DiskArrays.haschunks(da::AbstractBasicDimArray) = DiskArrays.haschunks(parent(da))
DiskArrays.eachchunk(da::AbstractBasicDimArray) = DiskArrays.eachchunk(parent(da))

# Only define methods if they are available, 
# to avoid dropping older DiskArrays versions
# TODO remove these checks
@static if isdefined(DiskArrays, :isdisk)
    DiskArrays.isdisk(x::AbstractDimArray) = DiskArrays.isdisk(parent(x))
    DiskArrays.isdisk(x::AbstractDimStack) = any(map(DiskArrays.isdisk, layers(x)))
end

@static if isdefined(DiskArrays, :cache)
    DiskArrays.cache(x::Union{AbstractDimStack,AbstractDimArray}; kw...) = 
        modify(A -> DiskArrays.cache(A; kw...), x)
end

@static if isdefined(DiskArrays, :pad)
    DiskArrays.pad(x::AbstractDimArray, padding::Tuple{Vararg{Tuple{<:Integer,<:Integer}}}; kw...) =
        DiskArrays.pad(x, map(rebbuild, dims(x, padding)))
    DiskArrays.pad(x::AbstractDimArray, padding::NamedTuple; kw...) =
        DiskArrays.pad(x, DimensionalData.kw2dims(padding); kw...)
    DiskArrays.pad(x::AbstractDimArray, pairs::Pair...; kw...) =
        DiskArrays.pad(x, DimensionalData.pair2dims(pairs); kw...)
    function DiskArrays.pad(x::AbstractDimArray, padding::DimTuple; kw...)
        tuple_padding = map(dims(x)) do d
            hasdim(padding, d) ? map(Int, val(dim(padding, d))) : (0, 0)
        end
        dims = map(padding) do dp
            DiskArrays.pad(dims(x, dp), val(dp))
        end
        data = DiskArrays.pad(parent(x), tuple_padding; kw...)
        return rebuild(x; data, dims)
    end
    DiskArrays.pad(d::Dimension, padding::Tuple{<:Integer,<:Integer}) = 
        DiskArrays.pad(lookup(d), padding)
    function DiskArrays.pad(l::Lookup, padding::Tuple{<:Integer,<:Integer})
        isregular(l) || throw(ArgumentError("Can only pad `Regular` lookups"))
        rebuild(l; data=_pad(parent(l), step(l), padding))
        # Use ranges for math because they have TwicePrecision magic
        # Define a range down to the lowest value,
        # but anchored at the existing value
    end

    _pad(l::AbstractRange, step, (startpad, stoppad)::Tuple{<:Integer,<:Integer})
        (first(l) - startpad * step(l)):step(l):(last(l) + stoppad * step(l))
    _pad(l::AbstractUnitRange, step, (startpad, stoppad)::Tuple{<:Integer,<:Integer})
        (first(l) - startpad):(last(l) + stoppad)
    function _pad(l::AbstractVector, step, (startpad, stoppad)::Tuple{<:Integer,<:Integer})
        # First pad as a range
        range = parent(_pad(first(l):last(l), step, (startpad, stoppad)))
        # Then convert back to vector
        data = collect(range)
        # And fill the middle with the values from the original vector
        # This prevents floating point error changing the original values
        data[startpad+1:end-stoppad] .= l
        # Rebuild the lookup with the padded data
        return rebild(l; data)
    end
end
        

end
