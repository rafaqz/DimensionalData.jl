using DimensionalData, Test

dim = Coord([(1.0,1.0,1.0), (1.0,2.0,2.0), (3.0,4.0,4.0), (1.0,3.0,4.0)], (X(), Y(), Z()))
da = DimArray(0.1:0.1:0.4, dim)

@testset "regular indexing" begin
    @test da[Coord()] === da[Coord(:)] === da
    @test da[Coord([1, 2])] == [0.1, 0.2]
    @test da[Coord(4)] == 0.4
end

@testset "selector indexing" begin
    @test da[Coord(:, :, :)] == [0.1, 0.2, 0.3, 0.4]
    @test da[Coord(Between(1, 5), :, At(4.0))] == [0.3, 0.4]
    @test da[Coord(:, Between(1, 3), :)] == [0.1, 0.2]
end

@testset "dimension indexing" begin
    @test da[Coord(Z(At(1.0)), Y(Between(1, 3)))] == [0.1]
end

@test index(da[Coord(:, Between(1, 3), :)], Coord) == [(1.0,1.0,1.0), (1.0,2.0,2.0)]
