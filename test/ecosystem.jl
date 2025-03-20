using DimensionalData
using Test

using OffsetArrays
using ImageFiltering
using ImageTransformations
using ArrayInterface
using StatsBase
using DiskArrays

using DimensionalData.Lookups

@testset "ArrayInterface" begin
    a = [1 2; 3 4]
    dimz = X(143.0:2.0:145.0), Y(-38.0:2.0:-36.0)
    da = DimArray(a, dimz)
    @test ArrayInterface.parent_type(typeof(da)) == Matrix{Int}
end

@testset "OffsetArray" begin
    a = [1 2 3 4
         3 4 5 6
         4 5 6 7]
    oa = OffsetArray(a, -1:1, 5:8)
    @testset "Regular dimensions don't work: axes must match" begin
        dimz = (X(100:100:300), Y([:a, :b, :c, :d]))
        @test_throws DimensionMismatch DimArray(oa, dimz)
    end
    odimz = (X(OffsetArray(100:100:300, -1:1)), Y(OffsetArray([:a, :b, :c, :d], 5:8)))
    oda = DimArray(oa, odimz)
    size(DimensionalData.LazyLabelledPrintMatrix(oda[Y=End]))
    size(oda[Y=End])
    @testset "Indexing and selectors work with offsets" begin
        @test axes(oda) == (-1:1, 5:8)
        @test oda[-1, 5] == oa[-1, 5] == 1
        @test oda[Near(105), At(:a)] == oa[-1, 5] == 1
        @test oda[At(200), At(:a)] == oa[0, 5] == 3
        @test oda[Between(100, 250), At(:a)] == oa[-1:0, 5] == [1, 3]
    end
    @testset "And when sampling is Regular" begin
        odimz_r = (X(OffsetArray(100:100:300, -1:1); span=Regular(100)), Y(OffsetArray([1.0, 2.0, 3.0, 4.0], 5:8); span=Regular(1)))
        oda_r = DimArray(oa, odimz_r)
        @test oda_r[At(100), At(1.0)] == oa[-1, 5] == 1
        @test oda_r[At(200), At(3.0)] == oa[0, 7] == 5
        @test oda_r[Between(100, 250), At(1)] == oa[-1:0, 5] == [1, 3]
    end
    @testset "Subsetting reverts to a regular array and dims" begin
        @test axes(oda[0:1, 7:8]) == (1:2, 1:2)
        @test axes.(dims(oda[0:1, 7:8])) == ((1:2,), (1:2,))
    end
    @testset "show" begin
        s = sprint(show, MIME("text/plain"), oda)
        s = sprint(show, MIME("text/plain"), oda; context=:displaysize=>(10, 10))
        s = sprint(show, MIME("text/plain"), oda; context=:displaysize=>(100, 100))
        @test occursin(":a", s)
    end
    @testset "3 dimensions" begin
        z = Z(OffsetArray('a':'j', -10:-1))
        oa3 = OffsetArray(zeros(10, 3, 4), -10:-1, -1:1, 5:8)
        oda3 = DimArray(oa3, (z, odimz...))
        s = sprint(show, MIME("text/plain"), oda3)
        @test occursin("'d'", s)
        @test occursin("'a'", s)
        @test occursin("'j'", s)
        s = sprint(show, MIME("text/plain"), oda3; context=:displaysize=>(15, 25))
        @test_broken !occursin("'d'", s) # Not sure what happened here?
    end
end

@testset "ImageFiltering and ImageTransformations" begin
    da = DimArray(randn(10, 10), (X, Y))

    # We are just testing that they actually run
    imfilter(da, Kernel.gaussian(1.0)) isa DimArray 
    # Array is a different size so the index is changed.
    # But we cant handle this without a dependency.
    # Maybe some tricks with ArrayInterface.jl can solve this.
    imresize(da, ratio=2) isa Matrix
    imresize(parent(dims(da, X)), ratio=2)
    imrotate(da, 0.3)
end

@testset "StatsBase" begin
    da = rand(X(1:10), Y(1:3))
    @test mean(da, weights([0.3,0.3,0.4]); dims=Y) == mean(parent(da), weights([0.3,0.3,0.4]); dims=2)
    @test sum(da, weights([0.3,0.3,0.4]); dims=Y) == sum(parent(da), weights([0.3,0.3,0.4]); dims=2)
end

@testset "DiskArrays" begin
    raw_data = rand(100, 100, 2)
    chunked_data = DiskArrays.TestTypes.ChunkedDiskArray(raw_data, (10, 10, 2))
    ds = (X(1.0:100), Y(collect(10:10:1000); span=Regular(10)), Z())
    da = DimArray(chunked_data, ds)
    st = DimStack((a = da, b = da))

    @testset "cache" begin
        @test parent(da) isa DiskArrays.TestTypes.ChunkedDiskArray
        @test DiskArrays.cache(da) isa DimArray
        @test parent(DiskArrays.cache(da)) isa DiskArrays.CachedDiskArray
        @test da == DiskArrays.cache(da)
    end
    @testset "chunks" begin
        @test DiskArrays.haschunks(da) == DiskArrays.haschunks(chunked_data)
        @test DiskArrays.eachchunk(da) == DiskArrays.eachchunk(chunked_data)
    end
    @testset "isdisk" begin
        @test DiskArrays.isdisk(da)
        @test !DiskArrays.isdisk(rand(X(5), Y(4)))
    end
    @testset "pad" begin
        p = DiskArrays.pad(da, (; X=(2, 3), Y=(40, 50)); fill=1.0)
        pst = DiskArrays.pad(st, (; X=(2, 3), Y=(40, 50)); fill=1.0)
        dims(p)
        @test size(p) == size(pst) == 
            map(length, dims(p)) == map(length, dims(pst)) == 
            size(da) .+ (5, 90, 0) == (105, 190, 2)
        @test dims(p) == dims(pst) == map(DimensionalData.format, (X(-1.0:103.0), Y(collect(-390:10:1500); span=Regular(10)), Z(NoLookup(Base.OneTo(2)))))
        @test sum(p) ≈ sum(da) + prod(size(p)) - prod(size(da))
        maplayers(pst) do A
            @test sum(A) ≈ sum(da) + prod(size(A)) - prod(size(da))
        end
    end
    @testset "PermutedDimsArray and PermutedDiskArray" begin
        @test parent(PermutedDimsArray(modify(Array, da), (3, 1, 2))) isa PermutedDimsArray
        @test parent(PermutedDimsArray(da, (3, 1, 2))) isa DiskArrays.PermutedDiskArray
    end
end
