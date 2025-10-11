struct DimUnitRange{T,R<:AbstractUnitRange{T},D<:Dimension} <: AbstractUnitRange{T}
    range::R
    dim::D
end

DimUnitRange{T}(r::DimUnitRange{T}) where {T<:Integer} = r
function DimUnitRange{T}(r::DimUnitRange) where {T<:Integer}
    return DimUnitRange(AbstractUnitRange{T}(parent(r)), dims(r))
end

@inline Base.parent(r::DimUnitRange) = r.range

function Base.reduced_index(dur::DimUnitRange) 
    r = Base.reduced_index(parent(dur))
    d = dims(dur)
    d1 = if isreverse(d)
        d[end:end]
    else
        d[begin:begin]
    end
    return DimUnitRange(r, d1)
end

@inline dims(r::DimUnitRange) = r.dim
@inline dims(rs::Tuple{DimUnitRange,Vararg{DimUnitRange}}) = map(dims, rs)

# this is necessary to ensure that keyword syntax for DimArray works correctly
Base.Slice(r::DimUnitRange) = Base.Slice(parent(r))

Base.show(io::IO, r::DimUnitRange) = print(io, basetypeof(r.dim), "(", r.range, ")") # concise presentation

# the below are adapted from OffsetArrays
# https://github.com/JuliaArrays/OffsetArrays.jl/blob/master/src/axes.jl

@inline Base.first(r::DimUnitRange) = Base.first(parent(r))
@inline Base.last(r::DimUnitRange) = Base.last(parent(r))
@inline Base.axes(r::DimUnitRange) = (r,)

# Conversions to an AbstractUnitRange{Int} (and to an OrdinalRange{Int,Int} on Julia v"1.6") are necessary
# to evaluate CartesianIndices for BigInt ranges, as their axes are also BigInt ranges
Base.AbstractUnitRange{T}(r::DimUnitRange) where {T<:Integer} = DimUnitRange{T}(r)
