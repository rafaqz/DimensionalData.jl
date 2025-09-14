module DimensionalDataAbstractFFTsExt

using DimensionalData
using AbstractFFTs, LinearAlgebra

const DD = DimensionalData

import LinearAlgebra: *

struct Inverse end
struct Forward end
struct RealFFT end
struct ComplexFFT end

const NotQuantity = Union{<:Real,Complex{<:Real}}

"""
    reinterpret_into_datatype(T, vec)

Convinience function to reinterpret a vector of Quantity{T} into a vector of T.
"""
function reinterpret_into_datatype(T::Type{<:NotQuantity}, vec)
    return reinterpret(T, vec)
end,
function reinterpret_into_datatype(T::Type{<:Number}, vec)
    return reinterpret_into_datatype(one(T), vec)
end,
function reinterpret_into_datatype(val::T, vec) where {T<:NotQuantity}
    return reinterpret_into_datatype(T, vec)
end

"""
    DDPlan{T, X, I, F, P<:AbstractFFTs.Plan, A}

Plan for performing FFTs on DimensionalArray. DDPlan wraps an AbstractFFTs.Plan and stores additional information related with the lookups dimensions of the input data. A temporary array `temp` is used to store intermediate results to avoid uncessary allocations when performing multiples FFTs with the same plan.
    T - Data type of the plan.
    X - Data type of the scaling factor related with the dx of the Fourier transform (function get_scale_factor).
    I - Inverse or Forward transform.
    F - Type of the FFT (RealFFT or ComplexFFT).
    P - Type of the AbstractFFTs.Plan that is wrapped.
    A - Type of the temporary array used to store intermediate results. Must match the size of the data in Fourier space.
"""
struct DDPlan{T,X,I,F,P<:AbstractFFTs.Plan,A} <: AbstractFFTs.Plan{T}
    p::P
    temp::A
    function DDPlan{X,I,F}(p::P, temp::A) where {X,I,F,P<:AbstractFFTs.Plan{T},A} where {T}
        return new{T,X,I,F,P,A}(p, temp)
    end
end

AbstractFFTs.fftdims(plan::DDPlan) = AbstractFFTs.fftdims(plan.p)
AbstractFFTs.output_size(plan::DDPlan) = AbstractFFTs.output_size(plan.p)
Base.size(plan::DDPlan) = size(plan.p)

is_inverse_transform(plan::DDPlan{<:Any,<:Any,Inverse}) = true
is_inverse_transform(plan::DDPlan{<:Any,<:Any,Forward}) = false

"""
    _step(lookup)

Simple wrapper to get the step of the lookup dimensions.
"""
function _step(lookup)
    if !DD.Lookups.isregular(lookup)
        throw(
            ArgumentError(
                "The spacing of the lookup along the dimensions to which FFT will be applied must be regular.",
            ),
        )
    end
    return step(lookup)
end,
function _step(x::DD.Dimensions.Dimension{<:AbstractFFTs.Frequencies})
    return step(parent(lookup(x)))
end,
function _step(
    x::DimensionalData.Dimensions.Dimension{
        <:DimensionalData.Dimensions.Lookups.Sampled{<:Any,<:Frequencies{<:Any}}
    },
)
    return step(parent(lookup(x)))
end

"""
    _fftfreq(dd_lookup)

Returns a dimension with the frequencies for a single lookup dimension of the FFT.
"""
function _fftfreq(dd_lookup)
    return DD.basetypeof(dd_lookup)(fftfreq(length(dd_lookup), 1 / _step(dd_lookup)))
end

"""
    _ifftfreq(dd_lookup)
Returns a dimension with the lookup for a single frequency lookup dimension for the inverse FFT.
"""
function _ifftfreq(dd_lookup)
    len = length(dd_lookup)
    dx = 1 / _step(dd_lookup) / len
    return DD.basetypeof(dd_lookup)(range(zero(dx); step=dx, length=len))
end

"""
    _rfftfreq(dd_lookup)
Returns a dimension with the frequencies for a single lookup dimension of the real FFT.
"""
function _rfftfreq(dd_lookup)
    return DD.basetypeof(dd_lookup)(rfftfreq(length(dd_lookup), 1 / _step(dd_lookup)))
end

"""
    _irfftfreq(dd_lookup, len)
Returns a dimension with the lookup for a single frequency lookup dimension for the inverse real FFT.
"""
function _irfftfreq(dd_lookup, len::Integer)
    dx = 1 / _step(dd_lookup) / len
    return DD.basetypeof(dd_lookup)(range(zero(dx); step=dx, length=len))
end

"""
    get_fft_frequencies_dim(::Type{<:DDPlan{<:Any, <:Any, I, R}}, dd_lookup, is_fft_dim, is_first_fft_dim, len) where {I,R}

Returns the lookup dimension of the FFT data for a single dimension. For real FFTs, needs to now the order of the dimension to return the correct frequencies. `is_fft_dim` indicates if the dimension is a FFT dimension, and `is_first_fft_dim` indicates if it is the first FFT dimension. `len` is the length of the output data.

"""
function get_fft_frequencies_dim(
    ::Type{<:DDPlan{<:Any,<:Any,Forward,R}}, dd_lookup, is_fft_dim, is_first_fft_dim, len
) where {R}
    if is_fft_dim
        if is_first_fft_dim
            if R == RealFFT
                _rfftfreq(dd_lookup)
            else
                _fftfreq(dd_lookup)
            end
        else
            _fftfreq(dd_lookup)
        end
    else
        dd_lookup
    end
end,
function get_fft_frequencies_dim(
    ::Type{<:DDPlan{<:Any,<:Any,Inverse,R}}, dd_lookup, is_fft_dim, is_first_fft_dim, len
) where {R}
    if is_fft_dim
        if is_first_fft_dim
            if R == RealFFT
                _irfftfreq(dd_lookup, len)
            else
                _ifftfreq(dd_lookup)
            end
        else
            _ifftfreq(dd_lookup)
        end
    else
        dd_lookup
    end
end

"""
    get_freqs(plan::P, dd::DD.AbstractDimArray{<:Any, N}) where {P<:AbstractFFTs.Plan, N}
Returns the lookups of the transformed data for all dimensions of the input `dd` that are transformed by the FFT plan `plan`. The lookups are returned as a tuple of dimensions, one for each dimension of the input data.
"""
@noinline function get_freqs(
    plan::P, dd::DD.AbstractDimArray{<:Any,N}
) where {P<:AbstractFFTs.Plan,N}
    fft_dims = AbstractFFTs.fftdims(plan)
    is_fft_dims = ntuple(i -> i in fft_dims, N)
    is_first_fft_dim = ntuple(i -> i == first(fft_dims), N)
    out_size = AbstractFFTs.output_size(plan)
    return ntuple(
        i -> get_fft_frequencies_dim(
            P, dims(dd, i), is_fft_dims[i], is_first_fft_dim[i], out_size[i]
        ),
        N,
    )
end

"""
    get_scale_factor(plan::P, dd::DD.AbstractDimArray{T, N}) where {T,P<:AbstractFFTs.Plan, N}

Return the scaling factor of the transform associated with the dx of the Fourier transform which is not included in non-DimensionalData transforms.
"""
function get_scale_factor(
    plan::P, dd::DD.AbstractDimArray{T,N}
) where {T,P<:AbstractFFTs.Plan,N}
    fft_dims = AbstractFFTs.fftdims(plan)
    is_fft_dims = ntuple(i -> i in fft_dims, N)
    steps_dd = ntuple(i -> is_fft_dims[i] ? _step(dims(dd, i)) : 1, N)
    return prod(steps_dd)
end

function (*)(plan::DDPlan{<:Any,X}, dd::DD.AbstractDimArray{T}) where {T,X}
    lookups = get_freqs(plan, dd)
    input_to_plan = if is_inverse_transform(plan)
        copyto!(parent(plan.temp), parent(dd))
        correct_phase_reference!(plan.temp, plan, lookups, 1)
        plan.temp
    else
        dd
    end

    _fft_dd = plan.p * reinterpret_into_datatype(T, parent(input_to_plan))
    fft_dd = reinterpret(
        typeof(Integer(real(oneunit(T)) * oneunit(X)) * oneunit(eltype(_fft_dd))), _fft_dd
    )
    dd_out = DimArray(fft_dd, lookups)
    if !is_inverse_transform(plan)
        correct_phase_reference!(dd_out, plan, lookup(dd), -1)
    end
    return dd_out
end
function LinearAlgebra.mul!(
    dd_out::DD.AbstractDimArray{Tout,N},
    plan::DDPlan{<:Any,Tp},
    dd_in::DD.AbstractDimArray{Tin,N},
) where {N,Tin,Tout,Tp}
    lookups_out = get_freqs(plan, dd_in)
    if !all(i -> dims(dd_out, i) == lookups_out[i], 1:N)
        throw(
            ArgumentError("The lookups of the output and input DimensionalData must match.")
        )
    end
    input_to_plan = if is_inverse_transform(plan)
        copyto!(parent(plan.temp), parent(dd_in))
        correct_phase_reference!(plan.temp, plan, lookups_out, 1)
        plan.temp
    else
        dd_in
    end

    LinearAlgebra.mul!(
        reinterpret_into_datatype(Tout, parent(dd_out)),
        plan.p,
        reinterpret_into_datatype(Tin, parent(input_to_plan)),
    )
    if !is_inverse_transform(plan)
        correct_phase_reference!(dd_out, plan, lookup(dd_in), -1)
    end

    # Corrects for the unit of the output. For example, if the input is g*s and the output is kg*s.
    correct_unit = real(oneunit(Tin) * oneunit(Tp) / oneunit(Tout))
    dd_out .*= correct_unit # Also used as a check to ensure that the output has the correct units.

    return dd_out
end

"""
    correct_phase_reference!(dd::DD.AbstractDimArray{<:Any, N}, plan::DDPlan, lookup_refs, phase_scaling) where N = nothing

Multiply the input `dd` by a phase ramp to account to account for the spatial sampling of the input spatial data.
"""
function correct_phase_reference!(
    dd::DD.AbstractDimArray{<:Any,N}, plan::DDPlan, lookup_refs, phase_scaling
) where {N}
    for i in fftdims(plan)
        @d dd .*= exp.((im * 2π * phase_scaling * first(lookup_refs[i])) .* dims(dd, i))
    end
end

for i in (:fft, :ifft, :rfft)
    signal = i == :ifft ? "i" : "-i"
    fft_freq = i == :ifft ? "ifftfreq" : "fftfreq"
    docsstring = """
          fft(A [, dims])

        Performs a multidimensional $(i) of the array `A`. The optional `dims` argument specifies an iterable subset of dimensions (e.g. an integer, range, tuple, or array) to transform along. A one-dimensional $(i) computes the one-dimensional discrete Fourier transform (DFT) as defined by:

        ```math
        \\operatorname{DFT}(A)[k] =
        \\sum_{n=1}^{\\operatorname{length}(A)} \\exp\\left($(signal)\\pi x[n]f[k] \\right) A[n] dx.
        ```
        where `x` is the lookup dimension of the input data, `f` is the lookup dimension of the output data, and `dx` is the step of the lookup dimension of the input data.

        Return a DimensionalData array with the transformed data, where the lookup dimensions are the output of $(fft_freq)
        """
    @eval begin
        function AbstractFFTs.$i(
            dd::AbstractDimArray{<:Any,N}, dims=ntuple(identity, N); kwargs...
        ) where {N}
            plan = $(Symbol(:plan_, i))(dd, dims; kwargs...)
            return plan * dd
        end
    end
end

"""
    irfft(A [, dims])

    Performs a multidimensional ifft of the array `A`. The optional `dims` argument specifies an iterable subset of dimensions (e.g. an integer, range, tuple, or array) to transform along. A one-dimensional irfft computes the one-dimensional discrete Fourier transform (DFT) as defined by:

        ```math
        \\operatorname{DFT}(A)[k] =
        \\sum_{n=1}^{\\operatorname{length}(A)} \\exp\\left(i\\pi x[n]f[k] \\right) A[n] dx.
        ```
        where `x` is the lookup dimension of the input data, `f` is the lookup dimension of the output data, and `dx` is the step of the lookup dimension of the input data.

        Return a DimensionalData array with the transformed data, where the lookup dimensions are the output of ifftfreq
"""
function AbstractFFTs.irfft(
    dd::AbstractDimArray{<:Any,N}, len::Integer, dims=ntuple(identity, N); kwargs...
) where {N}
    plan = plan_irfft(dd, len, dims; kwargs...)
    return plan * dd
end

"""
    plan_fft(dd::AbstractDimArray{T, N}, dd_dims = ntuple(identity, N); kwargs...) where {T,N}

Return the plan for performing a multidimensional FFT on the input DimensionalData array `dd`. The optional `dd_dims` argument specifies an iterable subset of dimensions (e.g. an integer, range, tuple, or array) to transform along. The plan is a DDPlan object that contains all the information needed to compute the FFT quickly.
"""
function AbstractFFTs.plan_fft(
    dd::AbstractDimArray{T,N}, dd_dims=ntuple(identity, N); kwargs...
) where {T,N}
    dims = DD.dimnum(dd, dd_dims)

    p = AbstractFFTs.plan_fft(reinterpret_into_datatype(T, parent(dd)), dims; kwargs...)
    s = get_scale_factor(p, dd)
    unitless_s = s / oneunit(s)
    return DDPlan{typeof(s),Forward,ComplexFFT}(
        AbstractFFTs.ScaledPlan(p, unitless_s), similar(dd, complex(T))
    )
end

"""
    plan_rfft(dd::AbstractDimArray{T, N}, dd_dims = ntuple(identity, N); kwargs...) where {T,N}

Return the plan for performing a multidimensional real FFT on the input DimensionalData array `dd`. The optional `dd_dims` argument specifies an iterable subset of dimensions (e.g. an integer, range, tuple, or array) to transform along. The plan is a DDPlan object that contains all the information needed to compute the real FFT quickly.
"""
function AbstractFFTs.plan_rfft(
    dd::AbstractDimArray{T,N}, dd_dims=ntuple(identity, N); kwargs...
) where {N,T}
    dims = DD.dimnum(dd, dd_dims)
    p = AbstractFFTs.plan_rfft(reinterpret_into_datatype(T, parent(dd)), dims; kwargs...)
    s = get_scale_factor(p, dd)
    unitless_s = s / oneunit(s)
    return DDPlan{typeof(s),Forward,RealFFT}(
        AbstractFFTs.ScaledPlan(p, unitless_s), similar(dd, complex(T))
    )
end

"""
    plan_ifft(dd::AbstractDimArray{T, N}, dd_dims = ntuple(identity, N); kwargs...) where {N, T}

Return the plan for performing a multidimensional inverse FFT on the input DimensionalData array `dd`. The optional `dd_dims` argument specifies an iterable subset of dimensions (e.g. an integer, range, tuple, or array) to transform along. The plan is a DDPlan object that contains all the information needed to compute the inverse FFT quickly.
"""
function AbstractFFTs.plan_ifft(
    dd::AbstractDimArray{T,N}, dd_dims=ntuple(identity, N); kwargs...
) where {N,T}
    dims = DD.dimnum(dd, dd_dims)

    p = AbstractFFTs.plan_bfft(reinterpret_into_datatype(T, parent(dd)), dims; kwargs...)
    s = get_scale_factor(p, dd)
    unitless_s = s / oneunit(s)
    return DDPlan{typeof(s),Inverse,ComplexFFT}(
        AbstractFFTs.ScaledPlan(p, unitless_s), similar(dd)
    )
end

function AbstractFFTs.plan_inv(plan::DDPlan)
    throw(
        ErrorException(
            "The plan_inv function is not implemented yet for DDPlan. Use plan_ifft or plan_irfft instead.",
        ),
    )
end

function LinearAlgebra.inv(plan::DDPlan)
    throw(
        ErrorException(
            "The plan_inv function is not implemented yet for DDPlan. Use plan_ifft or plan_irfft instead.",
        ),
    )
end

"""
    plan_irfft(dd::AbstractDimArray{T, N}, len::Integer, dd_dims = ntuple(identity, N); kwargs...) where {N, T}

Return the plan for performing a multidimensional inverse real FFT on the input DimensionalData array `dd`. The optional `dd_dims` argument specifies an iterable subset of dimensions (e.g. an integer, range, tuple, or array) to transform along. The plan is a DDPlan object that contains all the information needed to compute the inverse real FFT quickly.
"""
function AbstractFFTs.plan_irfft(
    dd::AbstractDimArray{T,N}, len::Integer, dd_dims=ntuple(identity, N); kwargs...
) where {N,T}
    dims = DD.dimnum(dd, dd_dims)
    p = AbstractFFTs.plan_brfft(
        reinterpret_into_datatype(T, parent(dd)), len, dims; kwargs...
    )
    s = get_scale_factor(p, dd)
    unitless_s = s / oneunit(s)
    return DDPlan{typeof(s),Inverse,RealFFT}(
        AbstractFFTs.ScaledPlan(p, unitless_s), similar(dd)
    )
end

for f in (:fftshift, :ifftshift)
    docsstring_dd = """
        $(f)(dd::DD.AbstractDimArray{<:Any, N}, dims = ntuple(identity, N)) where N
        Applies the $(f) operation to the input DimensionalData array `dd` along the specified dimensions `dims`. The $(f) operation is applied to both the lookup dimensions and the data of the DimensionalData array.
        """
    docsstring_look = """
        $(f)(lookup::DD.Dimensions.Dimension)
        Applies the $(f) operation to the input lookup dimension `lookup`.
        """
    @eval begin
        @doc $docsstring_look function AbstractFFTs.$f(dim::DD.Dimensions.Dimension)
            return DD.basetypeof(dim)(AbstractFFTs.$f(parent(lookup(dim))))
        end
        function $(Symbol(:apply_, f))(lookup, is_fft_dim)
            if is_fft_dim
                return AbstractFFTs.$f(lookup)
            else
                return lookup
            end
        end

        @doc $docsstring_dd function AbstractFFTs.$f(
            dd::AbstractDimArray{<:Any,N}, dd_dims=ntuple(identity, N)
        ) where {N}
            dims = DD.dimnum(dd, dd_dims)
            is_fft_dims = ntuple(i -> i in dims, N)
            dims_dd = DD.dims(dd)
            return DimArray(
                $f(parent(dd), dims),
                ntuple(i -> $(Symbol(:apply_, f))(dims_dd[i], is_fft_dims[i]), N),
            )
        end
    end
end
end

