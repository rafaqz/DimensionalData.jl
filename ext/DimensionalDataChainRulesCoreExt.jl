module DimensionalDataChainRulesCoreExt

using DimensionalData
import DimensionalData as DD
using ChainRulesCore

function ChainRulesCore.ProjectTo(x::DD.AbstractDimArray)
    return ProjectTo{DD.DimArray}(
        data = ProjectTo(parent(x)),
        dims = dims(x),
        name = name(x),
        refdims = refdims(x),
        metadata = metadata(x)
    )
end

(project::ProjectTo{DD.DimArray})(dx::DD.AbstractDimArray) =
    DD.DimArray(project.data(parent(dx)), project.dims; name=project.name, refdims=project.refdims, metadata=project.metadata)

(project::ProjectTo{DD.DimArray})(dx::AbstractArray) =
    DD.DimArray(project.data(dx), project.dims; name=project.name, refdims=project.refdims, metadata=project.metadata)

(project::ProjectTo{DD.DimArray})(dx::AbstractZero) = dx

DimArray_pullback(ȳ, project) = (NoTangent(), project(ȳ))
DimArray_pullback(ȳ::Tangent, project) = DimArray_pullback(ȳ.data, project)
DimArray_pullback(ȳ::AbstractThunk, project) = DimArray_pullback(unthunk(ȳ), project)

function ChainRulesCore.rrule(::typeof(parent), x::DD.AbstractDimArray)
    project = ProjectTo(x)
    function parent_pullback(ȳ)
        return DimArray_pullback(ȳ, project)
    end
    return parent(x), parent_pullback
end

#! rrule for keyword getindex with selectors
function ChainRulesCore.rrule(::typeof(getindex), A::DD.AbstractDimArray; kwargs...)
    dimsA = dims(A)
    indices = ntuple(i -> begin
        dim = dimsA[i]
        key = name(dim)
        if haskey(kwargs, key)
            # Convert selector/Colon to actual indices along dimension
            DD.Lookups.selectindices(dim, kwargs[key])
        else
            Colon()
        end
    end, length(dimsA))

    B = getindex(A, indices...)

    function pb(ȳ)
        grad = zero(A)
        if ȳ isa Number && length(grad[indices...]) == 1
            grad[indices...] = ȳ
        else
            grad[indices...] .= ȳ
        end
        return (NoTangent(), grad)
    end

    return B, pb
end

end