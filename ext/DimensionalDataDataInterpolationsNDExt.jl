module DimensionalDataDataInterpolationsNDExt

using DimensionalData
using DataInterpolationsND
using DimensionalData.Lookups
using DimensionalData.Dimensions

const DD = DimensionalData

caninterp(::DataInterpolationsND.InterpArray) = true

interpolable(A::AbstractDimArray, args...) = _interpolable(A, nothing, args...)
interpolable(A::AbstractDimArray; to=nothing) = _interpolable(A, to)

_interpolable(A::AbstractDimArray, to::Nothing, id1::Pair, interp_dims::Pair...) =
    _interpolable(A, pairs2dims((id1, interp_dims...)))
_interpolable(A::AbstractDimArray, to::Nothing, id1::Pair, interp_dims::Pair...) =
    _interpolable(A, pairs2dims((id1, interp_dims...)))
_interpolable(A::AbstractDimArray, to::Nothing, id1::Dimension, interp_dims::Dimension...) =
    _interpolable(A, (id1, interp_dims...))
function _interpolable(A::AbstractDimArray, to::Nothing, interp_dims::Tuple{Vararg{Dimension}})
    sorted_interp = sortdims(dims(A), interp_dims)
    unwrapped_interp = map(ds, i) do d, i
        if isnothing(i) 
            NoInterpolationDimension() 
        else
            (i isa NoInterpolationDimension || issampled(d)) || _interp_non_sampled_error(d, i)
            val(d)
        end
    end
    data = DataInterpolationsND.InterpArray(parent(A), unwrapped_interp)

    return rebuild(A; data, dims)
end
# By default use linear interpolation for all Sampled dimensions
function _interpolatable(A::AbstractDimArray, to)
    interp_dims = map(dims(A)) do d
        itp = if lookup(d) isa AbstractSampled 
            if isnothing(to) 
                LinearInterpolationDimension()
            else
                LinearInterpolationDimension(; t_eval=parent(lookup(to, d)))
            end
        else
            NoInterpolationDimension()
        end
        rebuild(d, itp)
    end

    return _interpolable(A, nothing, interp_dims)
end

_interp_non_sampled_error(d) = 
    throw(ArgumentError("Interpolator $i not allowed on dimension $(bastypeof(d)) with $(basetypeof(lookup(d))) lookup"))

end
