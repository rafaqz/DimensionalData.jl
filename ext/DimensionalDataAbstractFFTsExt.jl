module DimensionalDataAbstractFFTsExt

using DimensionalData
using AbstractFFTs, LinearAlgebra

const DD = DimensionalData

import LinearAlgebra: *

const Inverse = 1
const Forward = -1
const RealFFT = -1
const ComplexFFT = 1

const NotQuantity = Union{<:Real, Complex{<:Real}}

struct DDPlan{T, X, I, F, P<:AbstractFFTs.Plan,A} <: AbstractFFTs.Plan{T}
    p::P
    temp::A
    function DDPlan{X,I,F}(p::P, temp::A) where {X, I, F, P<:AbstractFFTs.Plan{T},A} where T
        new{T, X, I, F, P, A}(p, temp)
    end
end

AbstractFFTs.fftdims(plan::DDPlan) = AbstractFFTs.fftdims(plan.p)
AbstractFFTs.output_size(plan::DDPlan) = AbstractFFTs.output_size(plan.p)
Base.size(plan::DDPlan) = size(plan.p)

is_inverse_transform(plan::DDPlan{<:Any, <:Any, Inverse}) = true
is_inverse_transform(plan::DDPlan{<:Any, <:Any, Forward}) = false

function _step(lookup)
    if !DD.Lookups.isregular(lookup)
        throw(ArgumentError("The spacing of the lookup along the dimensions to which FFT will be applied must be regular."))
    end
    lookup[2] - lookup[1]
end

_step(lookup::DD.Dimensions.Dimension{<:AbstractFFTs.Frequencies}) = lookup[2]
_step(lookup::DimensionalData.Dimensions.Dimension{<:DimensionalData.Dimensions.Lookups.Sampled{<:Any, <:Frequencies{<:Any}}}) = lookup[2]

function _fftfreq(dd_lookup)
    DD.basetypeof(dd_lookup)(fftfreq(length(dd_lookup), 1 / _step(dd_lookup)))
end

function _ifftfreq(dd_lookup)
    len = length(dd_lookup)
    dx = 1 / _step(dd_lookup) / len
    if isodd(len)
        DD.basetypeof(dd_lookup)(range(-(len - 1) / 2 * dx, step = dx, length = len))
    else
        DD.basetypeof(dd_lookup)(range(-len / 2 * dx, step = dx, length = len))
    end
end

function _rfftfreq(dd_lookup)
    DD.basetypeof(dd_lookup)(rfftfreq(length(dd_lookup), 1 / _step(dd_lookup)))
end

function _irfftfreq(dd_lookup, len::Integer)
    dx = 1 / _step(dd_lookup) / len
    if isodd(len)
        DD.basetypeof(dd_lookup)(range(-(len - 1) / 2 * dx, step = dx, length = len))
    else
        DD.basetypeof(dd_lookup)(range(-len / 2 * dx, step = dx, length = len))
    end
end

function get_fft_frequencies_dim(::Type{<:DDPlan{<:Any, <:Any, Forward, R}}, dd_lookup, is_fft_dim, is_first_fft_dim, len) where R
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
end

function get_fft_frequencies_dim(::Type{<:DDPlan{<:Any, <:Any, Inverse, R}}, dd_lookup, is_fft_dim, is_first_fft_dim, len) where R
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

function get_freqs(plan::P, dd::DD.AbstractDimArray{<:Any, N}) where {P<:AbstractFFTs.Plan, N}
    fft_dims = AbstractFFTs.fftdims(plan)
    is_fft_dims = ntuple(i -> i in fft_dims, N)
    is_first_fft_dim = ntuple(i -> i == first(fft_dims), N)
    out_size = AbstractFFTs.output_size(plan)
    ntuple(i -> get_fft_frequencies_dim(P, dims(dd, i), is_fft_dims[i], is_first_fft_dim[i], out_size[i]), N)
end

function get_scale_factor(plan::P, dd::DD.AbstractDimArray{<:Any, N}) where {P<:AbstractFFTs.Plan, N}
    fft_dims = AbstractFFTs.fftdims(plan)
    is_fft_dims = ntuple(i -> i in fft_dims, N)
    steps_dd = ntuple(i -> is_fft_dims[i] ? _step(dims(dd, i)) : 1, N)
    prod(steps_dd)
end

function (*)(plan::DDPlan{<:Any, X}, dd::DD.AbstractDimArray{T}) where {T, X}
    lookups = get_freqs(plan, dd)
    input_to_plan = if is_inverse_transform(plan)
        copyto!(parent(plan.temp), parent(dd))
        correct_phase_reference!(plan.temp, plan, lookups, 1)
        plan.temp
    else
        dd
    end

    T_val = T <: NotQuantity ? eltype(input_to_plan) : typeof(input_to_plan[1].val)
    _fft_dd = plan.p * reinterpret(T_val, parent(input_to_plan))
    fft_dd = reinterpret(typeof(real(oneunit(T)) * oneunit(X) * oneunit(eltype(_fft_dd))), _fft_dd)
    dd_out = DimArray(fft_dd, lookups)
    if !is_inverse_transform(plan)
        correct_phase_reference!(dd_out, plan, lookup(dd), -1)
    end
    dd_out
end
function LinearAlgebra.mul!(dd_out::DD.AbstractDimArray{Tout, N}, plan::DDPlan, dd_in::DD.AbstractDimArray{Tin, N}) where {N, Tin, Tout}
    lookups_out = get_freqs(plan, dd_in)
    if !all(i -> dims(dd_out, i) == lookups_out[i], 1:N)
        throw(ArgumentError("The lookups of the output and input DimensionalData must match."))
    end
    input_to_plan = if is_inverse_transform(plan)
        copyto!(parent(plan.temp), parent(dd_in))
        correct_phase_reference!(plan.temp, plan, lookups_out, 1)
        plan.temp
    else
        dd_in
    end
    
    T_in_val = Tin <: NotQuantity ? eltype(input_to_plan) : typeof(input_to_plan[1].val)
    T_out_val = Tout <: NotQuantity ? eltype(dd_out) : typeof(dd_out[1].val)

    LinearAlgebra.mul!(reinterpret(T_out_val, parent(dd_out)), plan.p, reinterpret(T_in_val, parent(input_to_plan)))
    if !is_inverse_transform(plan)
        correct_phase_reference!(dd_out, plan, lookup(dd_in), -1)
    end
    dd_out
end

function correct_phase_reference!(dd::DD.AbstractDimArray{<:Any, N}, plan::DDPlan, lookup_refs, phase_scaling) where N
    for i in fftdims(plan)
        @d dd .*= exp.((im * 2π * phase_scaling * first(lookup_refs[i])) .* dims(dd, i))
    end
end

for i in (:fft, :ifft, :rfft)
    eval(quote
        function AbstractFFTs.$i(dd::AbstractDimArray{<:Any, N}, dims = ntuple(identity, N); kwargs...) where N
            plan = $(Symbol(:plan_, i))(dd, dims; kwargs...)
            plan * dd
        end
    end)
end

function AbstractFFTs.irfft(dd::AbstractDimArray{<:Any, N}, len::Integer, dims = ntuple(identity, N); kwargs...) where N
    plan = plan_irfft(dd, len, dims; kwargs...)
    plan * dd
end


function AbstractFFTs.plan_fft(dd::AbstractDimArray{T, N}, dd_dims = ntuple(identity, N); kwargs...) where {T,N}
    dims = DD.dimnum(dd, dd_dims)
    T_val = T <: NotQuantity ? eltype(parent(dd)) : typeof(parent(dd)[1].val)
    p = AbstractFFTs.plan_fft(reinterpret(T_val, parent(dd)), dims; kwargs...)
    s = get_scale_factor(p, dd)
    unitless_s = s / oneunit(s)
    DDPlan{typeof(s), Forward, ComplexFFT}(AbstractFFTs.ScaledPlan(p, unitless_s), similar(dd, complex(T)))
end
function AbstractFFTs.plan_rfft(dd::AbstractDimArray{T, N}, dd_dims = ntuple(identity, N); kwargs...) where {N,T}
    dims = DD.dimnum(dd, dd_dims)
    T_val = T <: NotQuantity ? eltype(dd) : typeof(parent(dd)[1].val)
    p = AbstractFFTs.plan_rfft(reinterpret(T_val, parent(dd)), dims; kwargs...)
    s = get_scale_factor(p, dd)
    unitless_s = s / oneunit(s)
    DDPlan{typeof(s), Forward, RealFFT}(AbstractFFTs.ScaledPlan(p, unitless_s), similar(dd, complex(T)))
end

function AbstractFFTs.plan_ifft(dd::AbstractDimArray{T, N}, dd_dims = ntuple(identity, N); kwargs...) where {N, T}
    dims = DD.dimnum(dd, dd_dims)

    T_val = T <: NotQuantity ? eltype(dd) : typeof(parent(dd)[1].val)
    p = AbstractFFTs.plan_ifft(reinterpret(T_val, parent(dd)), dims; kwargs...)
    s = get_scale_factor(p, dd)
    unitless_s = s / oneunit(s)
    DDPlan{typeof(s), Inverse, ComplexFFT}(AbstractFFTs.ScaledPlan(p.p, unitless_s), similar(dd))
end

function AbstractFFTs.plan_inv(plan::DDPlan)
    throw(ErrorException("The plan_inv function is not implemented yet for DDPlan. Use plan_ifft or plan_irfft instead."))
end

function LinearAlgebra.inv(plan::DDPlan)
    throw(ErrorException("The plan_inv function is not implemented yet for DDPlan. Use plan_ifft or plan_irfft instead."))
end

function AbstractFFTs.plan_irfft(dd::AbstractDimArray{T, N}, len::Integer, dd_dims = ntuple(identity, N); kwargs...) where {N, T}
    dims = DD.dimnum(dd, dd_dims)
    T_val = T <: NotQuantity ? eltype(dd) : typeof(parent(dd)[1].val)
    p = AbstractFFTs.plan_irfft(reinterpret(T_val, parent(dd)), len, dims; kwargs...)
    s = get_scale_factor(p, dd)
    unitless_s = s / oneunit(s)
    DDPlan{typeof(s), Inverse, RealFFT}(AbstractFFTs.ScaledPlan(p.p, unitless_s), similar(dd))
end


for f in (:fftshift, :ifftshift)
    eval(quote
        function AbstractFFTs.$f(dim::DD.Dimensions.Dimension)
            DD.basetypeof(dim)(AbstractFFTs.$f(parent(lookup(dim))))
        end
        function $(Symbol(:apply_, f))(lookup, is_fft_dim)
            if is_fft_dim
                return AbstractFFTs.$f(lookup)
            else
                return lookup
            end
        end
        function AbstractFFTs.$f(dd::AbstractDimArray{<:Any, N}, dd_dims = ntuple(identity, N)) where N
            dims = DD.dimnum(dd, dd_dims)
            is_fft_dims = ntuple(i -> i in dims, N)
            dims_dd = DD.dims(dd)
            DimArray($f(parent(dd), dims), ntuple(i -> $(Symbol(:apply_, f))(dims_dd[i], is_fft_dims[i]), N))
        end
    end)
end
end

