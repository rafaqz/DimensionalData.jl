using DimensionalData, Test

A = zeros(X(4.0:7.0), Y(10.0:12.0))
di = DimIndices(A)

ci = CartesianIndices(A)
@test val.(collect(di)) == Tuple.(collect(ci))

di[4, 3] == (X(4), Y(3))
@test di[X(1)] == [(Y(1),), (Y(2),), (Y(3),)]
@test map(ds -> A[ds...] + 2, di) == fill(2.0, 4, 3)
@test map(ds -> A[ds...], di[X(At(7.0))]) == [fill(0.0, 4) for i in 1:3]
@test_throws ArgumentError DimIndices(zeros(2, 2))

di = DimKeys(A)
di[4, 3] == (X(At(7.0)), Y(At(12.0)))
@test di[X(1)] == [(Y(At(10.0)),), (Y(At(11.0)),), (Y(At(12.0)),)]
@test map(ds -> A[ds...] + 2, di) == fill(2.0, 4, 3)
@test map(ds -> A[ds...], di[X(At(7.0))]) == [fill(0.0, 4) for i in 1:3]
@test_throws ArgumentError DimIndices(zeros(2, 2))
