using DimensionalData, Test
using DimensionalData: X, Y
using BenchmarkTools

for N ∈ (10, 100, 1000)
    x = X(range(1; length = N))
    y = Y(range(1; length = N))
    d = (x, y)
    A = DimArray(rand(length.(d)...), d)

    println("N=$(N). Time to access via X(1:3)")
    @btime $(A)[$(X(1:3))];
end

println("Time to access if X(1:3) is not interpolated constant")
@btime $(A)[X(1:3)];
println("Time to just access A.data")
@btime $(A)[1:3, :]
@btime $(A)[1, 1]

# println("Time to do A+A")
# @btime $(A) .+ $(A);
# println("Time to do A.data + A.data")
# @btime $(A.data) .+ $(A.data);
