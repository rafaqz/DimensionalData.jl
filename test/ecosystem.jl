using OffsetArrays, ImageFiltering, ImageTransformations, DimensionalData

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
    @testset "Indexing and selectors work with offsets" begin
        @test axes(oda) == (-1:1, 5:8)
        @test oda[-1, 5] == oa[-1, 5] == 1
        @test oda[Near(105), At(:a)] == oa[-1, 5] == 1
        @test oda[Between(100, 250), At(:a)] == oa[-1:0, 5] == [1, 3]
    end
    @testset "Subsetting reverts to a regular array and dims" begin
        @test axes(oda[0:1, 7:8]) == (1:2, 1:2)
        @test axes.(dims(oda[0:1, 7:8])) == ((1:2,), (1:2,))
    end
    @testset "show" begin
        s = sprint(show, MIME("text/plain"), oda)
        @test occursin(":a", sv)
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
