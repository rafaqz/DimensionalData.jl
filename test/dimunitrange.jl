using DimensionalData
using DimensionalData.Dimensions: Dim, DimUnitRange
using OffsetArrays
using Test

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
    @test length(r) == length(ax)
    @test !isempty(r)
    @test first(r) == first(ax)
    @test last(r) == last(ax)
    @test axes(r) === (r,)
    @test axes(r, 1) === r
    @test Base.axes1(r) === r
    if VERSION < v"1.8.2"
        @test firstindex(r) == firstindex(ax)
        @test lastindex(r) == lastindex(ax)
    end
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
    if VERSION >= v"1.6"
        @test Base.OrdinalRange{Int,Int}(r) == r
    end
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
