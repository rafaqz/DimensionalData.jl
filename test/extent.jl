using DimensionalData, Extents, Test

a = zeros(X(10.0:10.0:100.0), Y(0.1:0.1:1.0))
st = DimStack((a = a, b=a[Y=1]))
@test extent(st) == extent(a) == extent(dims(a)) == Extent(X=(10.0, 100.0), Y=(0.1, 1.0))
@test extent(st, X) == extent(a, X) == extent(dims(a), X) == Extent(; X=(10.0, 100.0))
@test dims(extent(st)) == dims(extent(a)) == (X((10.0, 100.0)), Y((0.1, 1.0)))
@test dims(extent(a), Y) == Y((0.1, 1.0))
