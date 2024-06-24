using DimensionalData
using Interpolations

f((x1, x2)) = log(x1+x2)
a = f.(DimPoints((X(1:1:10), Y(1:1.5:20))))
b = f.(DimPoints((X(1:1:10), Y([1.0,3,7.5,10,15]))))
to = rand(X(2:.3:7), Y(2:.3:17))
# out = DimensionalData.interp(A; to)

itp_a = linear_interpolation(a)
itp_b = linear_interpolation(b)
itp_ex = linear_interpolation(a, extrapolation_bc=(Flat(), Linear()))

itp_a(7.5,7.5)
itp_b(7.5,7.5)
itp_ex(10,13)
itp_ex(11,13)
itp_ex(10,14)

itp_ca = cubic_spline_interpolation(a)
# itp_cb = cubic_spline_interpolation(b) #fails, as expected

itp_ca(10,10)