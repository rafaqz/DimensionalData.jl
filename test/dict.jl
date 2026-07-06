using DimensionalData
using DataStructures

@testset "Dict" begin
    d = Dict{Int, Float64}(
        n => rand()
        for n in 1:10
    )
    A = DimArray(d, X)

    @testset for n in keys(d)
        @test d[n] == A[X(At(n))]
    end
end

@testset "OrderedDict" begin
    d = OrderedDict{Char,Int}()
    for c in 'a':'e'
        d[c] = c-'a'+1
    end

    A = DimArray(d, Y)

    @testset for c in keys(d)
        @test d[c] == A[Y(At(c))]
    end
end

@testset "RobinDict" begin
    d = RobinDict{Int, Char}(1 => 'a', 2 => 'b')
    A = DimArray(d, Dim{:n})

    @testset for n in keys(d)
        d[n] == A[n = At(n)]
    end
end

@testset "OrderedRobinDict" begin
    d = OrderedRobinDict{Int, Char}(1 => 'a', 2 => 'b')
    A = DimArray(d, Dim{:n})

    @testset for n in keys(d)
        d[n] == A[n = At(n)]
    end
end

@testset "SwissDict" begin
    d = SwissDict(1 => 'a', 2 => 'b')
    A = DimArray(d, Dim{:n})

    @testset for n in keys(d)
        d[n] == A[n = At(n)]
    end
end

@testset "SortedDict" begin
    d = SortedDict('a' => 1, 'c' => 3, 'b' => 2)
    A = DimArray(d, Dim{:c})

    @testset for c in keys(d)
        d[c] == A[c = At(c)]
    end
end

# @testset "SortedMultiDict" begin
#     d = SortedMultiDict{Int, String}()

#     # Insert elements
#     insert!(d, 3, "third")
#     insert!(d, 1, "first")
#     insert!(d, 2, "second")
#     insert!(d, 1, "another-first")

#     @test_throws ErrorException DimArray(d, DD.AnonDim)
# end
