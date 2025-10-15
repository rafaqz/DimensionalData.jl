module DimensionalDataStatsBaseExt

using DimensionalData
using Statistics
using StatsBase

const DD = DimensionalData

Statistics.mean(A::AbstractDimArray, w::StatsBase.AbstractWeights; dims=:) =
    _weighted(mean, A, w, dims)
# For ambiguity
Statistics.mean(A::AbstractDimArray, w::StatsBase.UnitWeights; dims=:) =
    _weighted(mean, A, w, dims)

Base.sum(A::AbstractDimArray, w::AbstractWeights{<:Real}; dims=:) =
    _weighted(sum, A, w, dims)

function _weighted(f::F, A, w, dims) where F
    if dims isa Colon
        return f(parent(A), w; dims=:)
    else
        data = f(parent(A), w; dims=dimnum(A, dims))
        return rebuild(A, data, DD.reducedims(A, dims))
    end
end

end
