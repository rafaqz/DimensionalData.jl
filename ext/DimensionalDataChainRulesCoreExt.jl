module DimensionalDataChainRulesCoreExt

using DimensionalData
using ChainRulesCore

function ChainRulesCore.ProjectTo(x::DimensionalData.AbstractDimArray)
    return ProjectTo{DimensionalData.DimArray}(; data=ProjectTo(parent(x)), dims=dims(x))
end

(project::ProjectTo{DimensionalData.DimArray})(dx::DimensionalData.AbstractDimArray) =
    DimArray(project.data(parent(dx)), project.dims)
(project::ProjectTo{DimensionalData.DimArray})(dx::AbstractArray) =
    DimArray(project.data(dx), project.dims)
(project::ProjectTo{DimensionalData.DimArray})(dx::AbstractZero) = dx

_DimArray_pullback(ȳ, project) = (NoTangent(), project(ȳ))
_DimArray_pullback(ȳ::Tangent, project) = _DimArray_pullback(ȳ.data, project)
_DimArray_pullback(ȳ::AbstractThunk, project) = _DimArray_pullback(unthunk(ȳ), project)

function ChainRulesCore.rrule(::typeof(parent), x::DimensionalData.AbstractDimArray)
    pb(y) = _DimArray_pullback(y, ProjectTo(x))
    return parent(x), pb
end

end