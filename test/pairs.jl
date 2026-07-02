using DimensionalData
using Test

@testset "Int => Int" begin
    p = [n => n^2 for n in -3:3]
    A = DimArray(p, X; name = :Square)

    @testset for (n, n²) in p
        @test n² == A[X(At(n))]
    end
end

@testset "Char => Int" begin
    p = [c => rand(Int) for c in 'a':'f']
    A = DimArray(p, Dim{:c}; name = :Character)

    @testset for (c, n) in p
        @test n == A[c = At(c)]
    end
end

@testset "String => Float64" begin
    # Mix up construction of pairs vector.
    pairs = [
        "Hello" => rand(),
        "Goodbye" => rand(),
        "Yo" => rand(),
        "What's up" => rand(),
    ]
    A = DimArray(pairs, Dim{:Greeting}; name = :Probability)

    @testset for (g, p) in pairs
        @test p == A[Greeting = At(g)]
    end
end
