using DimensionalData, Test, Unitful
using DimensionalData.LookupArrays, DimensionalData.Dimensions
using Statistics: mean

dim = Coord([(1.0,1.0,1.0), (1.0,2.0,2.0), (3.0,4.0,4.0), (1.0,3.0,4.0)], (X(), Y(), Z()))
da = DimArray(0.1:0.1:0.4, dim)
da2 = DimArray((0.1:0.1:0.4) * (1:1:3)', (dim, Ti(1u"s":1u"s":3u"s")))
Coord()

@testset "regular indexing" begin
    @test da[Coord()] === da[Coord(:)] === da
    @test da[Coord([1, 2])] == [0.1, 0.2]
    @test da[Coord(4)] == 0.4
    @test da2[Coord(4), Ti(3)] ≈ 1.2
end

@testset "coord selector indexing" begin
    @test da[Coord(:, :, :)] == [0.1, 0.2, 0.3, 0.4]
    @test da[Coord(Between(1, 5), :, At(4.0))] == [0.3, 0.4]
    @test da[Coord(:, Between(1, 3), :)] == [0.1, 0.2]
    @test da2[Ti(At(1u"s")), Coord(:, Between(1, 3), :)] ≈ [0.1, 0.2]
end

@testset "coord dimension indexing" begin
    @test da[Coord(Z(At(1.0)), Y(Between(1, 3)))] == [0.1]
end

@test index(da[Coord(:, Between(1, 3), :)], Coord) == [(1.0,1.0,1.0), (1.0,2.0,2.0)]

@test bounds(da) == (((1.0, 3.0), (1.0, 4.0), (1.0, 4.0)),)

@testset "coord named reduction" begin
    m = mean(da2; dims = Coord)
    @test size(m) == (1,3)
    @test length(dims(m, Coord)) == 1
    @test dims(m, Coord).val == DimensionalData.NoLookup(Base.OneTo(1))
    pure_mean = mean(da2.data; dims = 1)
    @test vec(pure_mean) == vec(m.data)
    @test Dimensions._tozero((1.0, 1.0)) == (0.0, 0.0)
end

@testset "coord indexing with intervals" begin
    interval = (0.1,0.1,0.1)..(0.2,0.2,0.2)
    sel = da[Coord(interval)]
    @test length(sel) == 2
end