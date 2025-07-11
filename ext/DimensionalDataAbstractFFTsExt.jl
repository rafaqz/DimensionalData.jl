module DimensionalDataAbstractFFTsExt

using DimensionalData
using AbstractFFTs, LinearAlgebra

const DD = DimensionalData

import LinearAlgebra: *

const Inverse = 1
const Forward = -1

struct DDPlan{T, P<:AbstractFFTs.Plan, I,A} <: AbstractFFTs.Plan{T}
    p::P
    temp::A
    function DDPlan{I}(p::P, temp::A) where {I, P<:AbstractFFTs.Plan{T},A} where T
        new{T, P, I, A}(p, temp)
    end
end

AbstractFFTs.fftdims(plan::DDPlan) = AbstractFFTs.fftdims(plan.p)
Base.size(plan::DDPlan) = size(plan.p)

is_inverse_transform(plan::DDPlan{<:Any, <:Any, Inverse}) = true
is_inverse_transform(plan::DDPlan{<:Any, <:Any, Forward}) = false

function _step(lookup)
    if !DD.Lookups.isregular(lookup)
        throw(ArgumentError("The spacing of the lookup along the fft dimension must be regular."))
    end
    lookup[2] - lookup[1]
end

function _step(lookup::DD.Lookups.Sampled{<:Real, <:AbstractFFTs.Frequencies})
    lookup[2]
end

function _fftfreq_dd(::Type{P}, dd_lookup, is_fft_dim, is_first_fft_dim) where P
    if is_fft_dim
        if dd_lookup isa DD.Lookups.Sampled{<:Real, <:AbstractFFTs.Frequencies}
            len = length(dd_lookup)
            dx = 1 / _step(dd_lookup) / len
            return range(-len / 2 * dx, step = dx, length = len)
        else
            return fftfreq(length(dd_lookup), 1 / _step(dd_lookup))
        end
    else
        return dd_lookup
    end
end

function _fftfreq_dd(::Type{<:AbstractFFTs.Plan{<:Real}}, dd_lookup, is_fft_dim, is_first_fft_dim)
    if is_fft_dim
        if is_first_fft_dim
            return rfftfreq(length(dd_lookup), 1 / _step(dd_lookup))
        else
            return fftfreq(length(dd_lookup), 1 / _step(dd_lookup))
        end
    else
        return dd_lookup
    end
end

function get_freqs(plan::P, dd::DD.AbstractDimArray{<:Any, N}) where {P<:AbstractFFTs.Plan, N}
    fft_dims = AbstractFFTs.fftdims(plan)
    is_fft_dims = ntuple(i -> i in fft_dims, N)
    is_first_fft_dim = ntuple(i -> i == first(fft_dims), N)
    freqs = ntuple(i -> _fftfreq_dd(P, lookup(dd, i), is_fft_dims[i], is_first_fft_dim[i]), N)
    lookups = ntuple(i -> DD.basetypeof(dims(dd, i))(freqs[i]), N)
    lookups
end

function get_scale_factor(plan::P, dd::DD.AbstractDimArray{<:Any, N}) where {P<:AbstractFFTs.Plan, N}
    fft_dims = AbstractFFTs.fftdims(plan)
    is_fft_dims = ntuple(i -> i in fft_dims, N)
    steps_dd = ntuple(i -> is_fft_dims[i] ? _step(lookup(dd, i)) : 1, N)
    prod(steps_dd)
end

function (*)(plan::DDPlan, dd::DD.AbstractDimArray)
    lookups = get_freqs(plan, dd)
    input_to_plan = if is_inverse_transform(plan)
        copyto!(parent(plan.temp), parent(dd))
        correct_phase_reference!(plan.temp, plan, lookups, 1)
        plan.temp
    else
        dd
    end
    fft_dd = plan.p * parent(input_to_plan)
    dd_out = DimArray(fft_dd, lookups)
    if !is_inverse_transform(plan)
        correct_phase_reference!(dd_out, plan, lookup(dd), -1)
    end
    dd_out
end
function LinearAlgebra.mul!(dd_out::DD.AbstractDimArray{<:Any, N}, plan::DDPlan, dd_in::DD.AbstractDimArray{<:Any, N}) where N
    lookups_out = get_freqs(plan, dd_in)
    if !all(i -> dims(dd_out, i) == lookups_out[i], 1:N)
        throw(ArgumentError("The lookups of the output and input DimensionalData must match."))
    end
    input_to_plan = if is_inverse_transform(plan)
        @show "asda"
        copyto!(parent(plan.temp), parent(dd_in))
        correct_phase_reference!(plan.temp, plan, lookups_out, 1)
        plan.temp
    else
        dd_in
    end
    @show plan.p
    LinearAlgebra.mul!(parent(dd_out), plan.p, parent(input_to_plan))
    if !is_inverse_transform(plan)
        correct_phase_reference!(dd_out, plan, lookup(dd_in), -1)
    end
    dd_out
end

function correct_phase_reference!(dd::DD.AbstractDimArray{<:Any, N}, plan::DDPlan, lookup_refs, phase_scaling) where N
    for i in fftdims(plan)
        dd .*= exp.((im * 2π * phase_scaling * first(lookup_refs[i])) .* lookup(dd, i))
    end
end

for i in (:fft, :ifft, :rfft)
    eval(quote
        function AbstractFFTs.$i(dd::AbstractDimArray{<:Any, N}, dims = 1:N; kwargs...) where N
            plan = $(Symbol(:plan_, i))(dd, dims; kwargs...)
            plan * dd
        end
    end)
end

function AbstractFFTs.plan_fft(dd::AbstractDimArray{T, N}, dims = 1:N; kwargs...) where {T,N}
    p = AbstractFFTs.plan_fft(parent(dd), dims; kwargs...)
    s = get_scale_factor(p, dd)
    DDPlan{Forward}(AbstractFFTs.ScaledPlan(p, s), similar(dd, complex(T)))
end
function AbstractFFTs.plan_rfft(dd::AbstractDimArray{T, N}, dims = 1:N; kwargs...) where {N,T}
    p = AbstractFFTs.plan_rfft(parent(dd), dims; kwargs...)
    s = get_scale_factor(p, dd)
    DDPlan{Forward}(AbstractFFTs.ScaledPlan(p, s), similar(dd, complex(T)))
end

function AbstractFFTs.plan_ifft(dd::AbstractDimArray{<:Any, N}, dims = 1:N; kwargs...) where N
    p = AbstractFFTs.plan_ifft(parent(dd), dims; kwargs...)
    s = get_scale_factor(p, dd)
    DDPlan{Inverse}(AbstractFFTs.ScaledPlan(p.p, s), similar(dd))
end

function AbstractFFTs.plan_inv(plan::DDPlan)
    throw(ErrorException("The plan_inv function is not implemented yet for DDPlan. Use plan_ifft or plan_irfft instead."))
end

function LinearAlgebra.inv(plan::DDPlan)
    throw(ErrorException("The plan_inv function is not implemented yet for DDPlan. Use plan_ifft or plan_irfft instead."))
end

function AbstractFFTs.plan_irfft(dd::AbstractDimArray{<:Any, N}, len, dims = 1:N; kwargs...) where N
    p = AbstractFFTs.plan_irfft(parent(dd), len, dims; kwargs...)
    s = get_scale_factor(p, dd)
    DDPlan{Inverse}(AbstractFFTs.ScaledPlan(p.p, s), similar(dd))
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
        function AbstractFFTs.$f(dd::AbstractDimArray{<:Any, N}, dims = 1:N) where N
            is_fft_dims = ntuple(i -> i in dims, N)
            dims_dd = DD.dims(dd)
            DimArray($f(parent(dd), dims), ntuple(i -> $(Symbol(:apply_, f))(dims_dd[i], is_fft_dims[i]), N))
        end
    end)
end
end

