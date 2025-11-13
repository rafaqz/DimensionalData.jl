using DimensionalData
using DimensionalData.Dimensions: Dim, DimUnitRange, basetypeof
using OffsetArrays
using Test

struct AxesArrayWrapper{T,N} <: AbstractArray{T,N}
    data::AbstractArray{T,N}
    axes
end
Base.size(A::AxesArrayWrapper) = size(A.data)
Base.axes(A::AxesArrayWrapper) = A.axes
Base.getindex(A::AxesArrayWrapper, i::Int) = A.data[i]
Base.getindex(A::AxesArrayWrapper, I::Vararg{Int,N}) where {N} = A.data[I...]

axdims = [
    (Base.OneTo(3), X(["x", "y", "z"])),
    (axes(OffsetVector(ones(2), 0:1), 1), Dim{:f}([:a, :b])),
]
@testset for (ax, dim) in axdims
    r = DimUnitRange(ax, dim)
    r2 = DimUnitRange(Base.OneTo(5), Dim{:g}(6:10))
    @test r isa DimUnitRange
    @test parent(r) === ax
    @test dims(r) === r.dim
    @test dims((r, r2)) === (r.dim, r2.dim)
    @test sprint(show, "text/plain", r) == "$(basetypeof(r.dim))($(r.range))"
    @test length(r) == length(ax)
    @test !isempty(r)
    @test first(r) == first(ax)
    @test last(r) == last(ax)
    @test axes(r) === (r,)
    @test axes(r, 1) === r
    @test Base.axes1(r) === r
    @test iterate(r) === iterate(ax)
    @test iterate(r, iterate(r)[2]) === iterate(ax, iterate(r)[2])
    @test r[begin] == ax[begin]
    @test r[1] == ax[1]
    @test checkindex(Bool, r, 1)
    @test checkindex(Bool, r, 0) == checkindex(Bool, ax, 0)
    bigr = DimUnitRange{BigInt}(r)
    @test eltype(bigr) === BigInt
    @test eltype(parent(bigr)) === BigInt
    @test dims(bigr) === dim
    @test bigr == ax
    @test DimUnitRange{eltype(r)}(r) === r
    @test Base.OrdinalRange{Int,Int}(r) == r
    @test AbstractUnitRange{BigInt}(r) isa DimUnitRange{BigInt}
    @test parent(AbstractUnitRange{BigInt}(r)) == AbstractUnitRange{BigInt}(parent(r))
    @test dims(AbstractUnitRange{BigInt}(r)) === dim
end

@testset "CartesianIndices/LinearIndices for BigInt ranges" begin
    r = DimUnitRange(1:2, X(["x", "y"]))
    rbig = DimUnitRange(big(1):big(2), X(["x", "y"]))
    @test CartesianIndices(rbig) == CartesianIndices(r)
    @test LinearIndices(rbig) == LinearIndices(r)
    @test eachindex(rbig) == eachindex(r)
end

@testset "similar" begin
    dim = X(["x", "y", "z"])
    r = DimUnitRange(Base.OneTo(3), dim)
    da_sim = similar(r)
    @test da_sim isa DimArray{Int,1}
    @test dims(da_sim) == (dim,)
    @test dims(da_sim) !== (dim,)

    da_sim2 = similar(r, Missing)
    @test da_sim2 isa DimArray{Missing,1}
    @test dims(da_sim2) == (dim,)
    @test dims(da_sim2) !== (dim,)
end

@testset "map" begin
    dim = X(["x", "y", "z"])
    r = DimUnitRange(Base.OneTo(3), dim)
    y = map(one, r)
    @test y isa DimArray{Int,1}
    @test y == ones(3)
    @test dims(y) == (dim,)
end

@testset "broadcast" begin
    dim = X(["x", "y", "z"])
    r = DimUnitRange(Base.OneTo(3), dim)
    y = sin.(r)
    @test y isa DimArray{Float64,1}
    @test y == sin.(1:3)
    @test dims(y) == (dim,)
end

@testset "dims for array with DimUnitRange indices" begin
    xdim = X(["x", "y", "z"])
    ydim = Y(2.0:6.0)
    xi = DimUnitRange(Base.OneTo(3), xdim)
    yi = DimUnitRange(Base.OneTo(5), ydim)

    @testset "dims is not nothing if all indices are DimUnitRange" begin
        A = AxesArrayWrapper(Array(rand(xdim, ydim)), (xi, yi))
        @test axes(A) == (xi, yi)
        @test !isnothing(dims(A))
        @test Dimensions.comparedims(Bool, dims(A), (xdim, ydim))

        A2 = AxesArrayWrapper(Array(rand(xdim)), (xi,))
        @test axes(A2) == (xi,)
        @test !isnothing(dims(A2))
        @test Dimensions.comparedims(Bool, dims(A2), (xdim,))

    end

    @testset "dims is nothing if any indices are not DimUnitRange" begin
        A = AxesArrayWrapper(Array(rand(xdim, ydim)), (xi, Base.OneTo(length(ydim))))
        @test isnothing(dims(A))

        A2 = AxesArrayWrapper(Array(rand(xdim, ydim)), (Base.OneTo(length(xdim)), yi))
        @test isnothing(dims(A2))
    end
end
