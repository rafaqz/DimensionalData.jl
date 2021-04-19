using DimensionalData, Test

dim = Coord([(1.0,1.0,1.0), (1.0,2.0,2.0), (3.0,4.0,4.0), (1.0,3.0,4.0)], (X(), Y(), Z()))
da = DimArray(0.1:0.1:0.4, dim)

@test da[Coord()] === da
@test da[Coord(:, :, :)] == [0.1, 0.2, 0.3, 0.4]
@test da[Coord(Between(1, 5), :, At(4.0))] == [0.3, 0.4]
@test da[Coord(:, Between(1, 3), :)] == [0.1, 0.2]
@test da[Coord(Z(At(1.0)), Y(Between(1, 3)))] == [0.1]
@test index(da[Coord(:, Between(1, 3), :)], Coord) == [(1.0,1.0,1.0), (1.0,2.0,2.0)]
