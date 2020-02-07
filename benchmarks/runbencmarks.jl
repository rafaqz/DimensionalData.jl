using DimensionalData, Test
using DimensionalData: Time, X, @dim
using Dates: DateTime, Month
using BenchmarkTools

dt = 12
dx = 20.0

timespan = DateTime(2001):Month(dt):DateTime(2011,12)
t = Time(timespan)
x = X(Vector(0.5:dx:359.5))
d = (x, t)
A = DimensionalArray(rand(length.(d)...), d)

println("Time to access via Tim(1:3)")
@btime $(A)[$(Time(1:3))];
println("Time to access via A.data[:, 1:3]")
@btime $(A.data)[1:3];

println("Time to access X(1), Time(1)")
@btime $(A)[$(X(1)), $(Time(1))];
println("Time to access data[1,1]")
@btime $(A.data)[1, 1];


println("Time to do A+A")
@btime $(A) .+ $(A);

println("Time to do A.data + A.data")
@btime $(A.data) .+ $(A.data);
