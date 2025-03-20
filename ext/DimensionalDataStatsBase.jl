module DimensionalDataStatsBase

using DimensionalData
using Statistics
using StatsBase

const DD = DimensionalData

function Statistics.mean(A::AbstractDimArray, w::StatsBase.AbstractWeights; dims=:)
    data = mean(parent(A), w; dims=dimnum(A, dims))
    return rebuild(A, data, DD.reducedims(A, dims))
end
# For ambiguity
function Statistics.mean(A::AbstractDimArray, w::StatsBase.UnitWeights; dims=:)
    data = mean(parent(A), w; dims=dimnum(A, dims))
    return rebuild(A, data, DD.reducedims(A, dims))
end

function Base.sum(A::AbstractDimArray, w::AbstractWeights{<:Real}; dims=:)
    data = sum(parent(A), w; dims=dimnum(A, dims))
    return rebuild(A, data, DD.reducedims(A, dims))
end

end
