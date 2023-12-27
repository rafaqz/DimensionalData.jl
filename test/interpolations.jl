using DimensionalData
using Interpolations

f((x1, x2)) = log(x1+x2)
A = f.(DimPoints((X(1:.1:10), Y(1:.5:20))))
to = rand(X(2:.3:7), Y(2:.3:17))
out = DimensionalData.interp(A; to)

A_x1 = 1:.1:10
A_x2 = 1:.5:20
f(x1, x2) = log(x1+x2)
A = [f(x1,x2) for x1 in A_x1, x2 in A_x2]
itp = interpolate(A, BSpline(Cubic(Line(OnGrid()))))
sitp = scale(itp, A_x1, A_x2)
sitp(5., 10.) # exactly log(5 + 10)
sitp([5.6, 5.2], [7.1, 7.1]) # approximately log(5.6 + 7.1)
