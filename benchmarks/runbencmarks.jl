using DimensionalData, Test
using DimensionalData: X, Y
using BenchmarkTools

Nx = 10 # total points in x
Ny = 12 # total points in y

x = X(range(1; length = Nx))
y = Y(range(1; length = Ny))
d = (x, y)
A = DimensionalArray(rand(length.(d)...), d)


println("Time to access via X(1:3)")
@btime $(A)[$(X(1:3))];
println("Time to access if X(1:3) is not interpolated constant")
@btime $(A)[X(1:3)];
println("Time to just access A.data")
@btime $(A)[1:3, :]

println("Time to do A+A")
@btime $(A) .+ $(A);
println("Time to do A.data + A.data")
@btime $(A.data) .+ $(A.data);
