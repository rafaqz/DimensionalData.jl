module DimensionalDataInterpolations

using DimensionalData, Interpolations

function Interpolations.linear_interpolation(A::AbstractDimArray; kw...)
    linear_interpolation(DimensionalData.index(dims(A)), A; kw...)
end

function Interpolations.cubic_spline_interpolation(A::AbstractDimArray; varargs...)
    cubic_spline_interpolation(DimensionalData.index(dims(A)), A; varargs...)
end

end