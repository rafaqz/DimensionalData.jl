# Interpolations

interpolable(A::AbstractArray, args...) = _interpolable_error(A)
interpolable(A::AbstractArray; kw...) = _interpolable_error(A)

# Either error that the package is missing or MethodError
_interpolable_error(A::AbstractDimArray, args...; kw...) =
        error("Run `using DataInterpolationsND` to use `interpolable`")
_interpolable_error(A::AbstractArray, args...; kw...) = throw(MethodError(interpolable, A, args...; kw...))

checkcaninterp(A) =
    caninterp(A) || throw(ArgumentError("Using `Interp` selector on non-interpolable array. Did you run `Aitp = interpolable(A)` first?"))

caninterp(::AbstractArray) = false

