using DimensionalData, Extents, Test

a = zeros(X(10.0:10.0:100.0), Y(0.1:0.1:1.0))
@test extent(a) == extent(dims(a)) == Extent(X=(10.0, 100.0), Y=(0.1, 1.0))
@test extent(a, X) == extent(dims(a), X) == Extent(; X=(10.0, 100.0))
@test dims(extent(a)) == (X((10.0, 100.0)), Y((0.1, 1.0)))
@test dims(extent(a), Y) == Y((0.1, 1.0))
