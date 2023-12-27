using DimensionalData
using Interpolations

f((x1, x2)) = log(x1+x2)
A = f.(DimPoints((X(1:.1:10), Y(1:.5:20))))
to = rand(X(2:.3:7), Y(2:.3:17))
out = DimensionalData.interp(A; to)
