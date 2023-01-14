struct DimUnitRange{T,R<:AbstractUnitRange{T},D<:Dimension} <: AbstractUnitRange{T}
    range::R
    dim::D
end

DimUnitRange{T}(r::DimUnitRange{T}) where {T<:Integer} = r
function DimUnitRange{T}(r::DimUnitRange) where {T<:Integer}
    return DimUnitRange(AbstractUnitRange{T}(parent(r)), dims(r))
end

@inline Base.parent(r::DimUnitRange) = r.range

@inline dims(r::DimUnitRange) = r.dim
@inline dims(rs::Tuple{DimUnitRange,Vararg{DimUnitRange}}) = map(dims, rs)

# this is necessary to ensure that keyword syntax for DimArray works correctly
Base.Slice(r::DimUnitRange) = Base.Slice(parent(r))

Base.show(io::IO, r::DimUnitRange) = print(io, DimUnitRange, (r.range, r.dim))

# the below are adapted from OffsetArrays
# https://github.com/JuliaArrays/OffsetArrays.jl/blob/master/src/axes.jl

for f in [:length, :isempty, :first, :last]
    @eval @inline Base.$f(r::DimUnitRange) = Base.$f(parent(r))
end
@inline Base.axes(r::DimUnitRange) = (r,)
if VERSION < v"1.8.2"
    # On recent Julia versions, these don't need to be defined, and defining them may
    # increase validations, see https://github.com/JuliaArrays/OffsetArrays.jl/pull/311
    Base.axes1(r::DimUnitRange) = r
    for f in [:firstindex, :lastindex]
        @eval @inline Base.$f(r::DimUnitRange) = $f(parent(r))
    end
end
@inline Base.iterate(r::DimUnitRange, i...) = iterate(parent(r), i...)
@inline Base.getindex(r::DimUnitRange, i::Integer) = getindex(parent(r), i)

# Conversions to an AbstractUnitRange{Int} (and to an OrdinalRange{Int,Int} on Julia v"1.6") are necessary
# to evaluate CartesianIndices for BigInt ranges, as their axes are also BigInt ranges
Base.AbstractUnitRange{T}(r::DimUnitRange) where {T<:Integer} = DimUnitRange{T}(r)

# https://github.com/JuliaLang/julia/pull/40038
if v"1.6" <= VERSION < v"1.9.0-DEV.642"
    Base.OrdinalRange{T,T}(r::DimUnitRange) where {T<:Integer} = DimUnitRange{T}(r)
end

@inline function Base.checkindex(::Type{Bool}, r::DimUnitRange, i::Real)
    return Base.checkindex(Bool, parent(r), i)
end
