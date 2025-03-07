"""
    DimensionalDataDiskArraysExt

Extend some methods of DiskArrays (`cache`, etc) to work on the base data of any DimArray.  
"""
module DimensionalDataDiskArraysExt

using DimensionalData
import DimensionalData: AbstractBasicDimArray
import DiskArrays

const DD = DimensionalData

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
    DiskArrays.pad(x::Union{AbstractDimArray,AbstractDimStack}, padding::Tuple{Vararg{Tuple{<:Integer,<:Integer}}}; kw...) =
        DiskArrays.pad(x, map(rebbuild, dims(x, padding)))
    DiskArrays.pad(x::Union{AbstractDimArray,AbstractDimStack}, padding::NamedTuple; kw...) =
        DiskArrays.pad(x, DD.kw2dims(padding); kw...)
    DiskArrays.pad(x::Union{AbstractDimArray,AbstractDimStack}, p1::Pair, pairs::Pair...; kw...) =
        DiskArrays.pad(x, DD.Dimensions.pairs2dims(p1, pairs...); kw...)
    function DiskArrays.pad(x::AbstractDimStack, padding::DD.DimTuple; kw...)
        DD.maplayers(x) do A
            DiskArrays.pad(A, padding; kw...)
        end
    end
    function DiskArrays.pad(x::AbstractDimArray, padding::DD.DimTuple; kw...)
        tuple_padding = map(DD.dims(x)) do d
            hasdim(padding, d) ? map(Int, val(DD.dims(padding, d))) : (0, 0)
        end
        paddeddims = map(DD.dims(x)) do d
            if hasdim(padding, d) 
                DiskArrays.pad(d, val(DD.dims(padding, d)))
            else
                d
            end
        end
        paddeddata = DiskArrays.pad(parent(x), tuple_padding; kw...)
        return rebuild(x; data=paddeddata, dims=paddeddims)
    end
    DiskArrays.pad(d::DD.Dimension, padding::Tuple{<:Integer,<:Integer}) = 
        rebuild(d, DiskArrays.pad(lookup(d), padding))
    DiskArrays.pad(l::DD.AbstractNoLookup, (startpad, stoppad)::Tuple{<:Integer,<:Integer}) =
        DD.NoLookup(Base.OneTo(length(l) + startpad + stoppad))
    function DiskArrays.pad(l::DD.Lookup, padding::Tuple{<:Integer,<:Integer})
        (DD.issampled(l) && DD.isregular(l)) || throw(ArgumentError("Can only pad `Regular` `AbstractSampled` lookups"))
        rebuild(l; data=_pad(parent(l), step(l), padding))
        # Use ranges for math because they have TwicePrecision magic
        # Define a range down to the lowest value,
        # but anchored at the existing value
    end

    _pad(l::AbstractRange, step, (startpad, stoppad)::Tuple{<:Integer,<:Integer}) =
        (first(l) - startpad * step):step:(last(l) + stoppad * step)
    _pad(l::AbstractUnitRange, step, (startpad, stoppad)::Tuple{<:Integer,<:Integer}) =
        (first(l) - startpad):(last(l) + stoppad)
    function _pad(l::AbstractVector, step, (startpad, stoppad)::Tuple{<:Integer,<:Integer})
        # First pad as a range
        range = parent(_pad(first(l):step:last(l), step, (startpad, stoppad)))
        # Then convert back to vector
        data = collect(range)
        # And fill the middle with the values from the original vector
        # This prevents floating point error changing the original values
        data[startpad+1:end-stoppad] .= l
        # Rebuild the lookup with the padded data
        return data
    end
end

@inline function DimensionalData.lazypermutedims(A::AbstractArray, perm) 
    # For DiskArrays `permutedims` is lazy
    if isdisk(A)
        permutedims(A, perm)
    else
        DimensionalData._permuteddimsarray(A, perm)
    end
end

end
