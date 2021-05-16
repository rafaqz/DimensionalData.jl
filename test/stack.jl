using DimensionalData, Test, LinearAlgebra, Statistics

A = [1.0 2.0 3.0;
     4.0 5.0 6.0]
x, y, z = X([:a, :b]), Y(10.0:10.0:30.0), Z()
dimz = x, y
da1 = DimArray(A, (x, y), :one)
da2 = DimArray(Float32.(2A), (x, y), :two)
da3 = DimArray(Int.(3A), (x, y), :three)
da4 = DimArray(cat(4A, 5A, 6A; dims=3), (x, y, z), :extradim)

s = DimStack((da1, da2, da3))
mixed = DimStack((da1, da2, da4))

@testset "Constructors" begin
    @test DimStack((one=A, two=2A, three=3A), dimz) == s
    @test DimStack(da1, da2, da3) == s
    @test DimStack((one=da1, two=da2, three=da3), dimz) == s
end

@testset "Properties" begin
    @test DimensionalData.dims(s) == dims(da1)
    @test keys(data(s)) == (:one, :two, :three)
    @test keys(data(mixed)) == (:one, :two, :extradim)
    da1x = s[:one]
    @test parent(da1x) === parent(da1)
    @test dims(da1x) === dims(da1)
end

@testset "getindex" begin
    @test s[1, 1] === (one=1.0, two=2.0f0, three=3)
    @test s[X(2), Y(3)] === (one=6.0, two=12.0f0, three=18)
    @test s[X=:b, Y=10.0] === (one=4.0, two=8.0f0, three=12)
    slicedds = s[:a, :]
    @test slicedds[:one] == [1.0, 2.0, 3.0]
    @test data(slicedds) == (one=[1.0, 2.0, 3.0], two=[2.0f0, 4.0f0, 6.0f0], three=[3, 6, 9])
    @testset "linear indices" begin
        linear2d = s[1:2]
        @test linear2d isa NamedTuple
        @test linear2d == (one=[1.0, 4.0], two=[2.0f0, 8.0f0], three=[3, 12])
        linear1d = s[Y(1)][1:2]
        @test linear1d isa DimStack
        @test data(linear1d) == (one=[1.0, 4.0], two=[2.0f0, 8.0f0], three=[3, 12])
    end
    @testset "mixed" begin
        noz = mixed[Z(1)]
        @test dims(noz) == dims(da1)
        @test refdims(noz) == (Z(1; mode=NoIndex()),)
        @test mixed[X(1), Y(1)] == (one=1.0, two=2.0f0, extradim=mixed[:extradim][1, 1, :])
        linear = mixed[1:2]
        @test linear isa NamedTuple
        @test linear == (one=[1.0, 4.0], two=[2.0f0, 8.0f0], extradim=[4.0, 16.0])
    end
end

@testset "view" begin
    sv = view(s, 1, 1)
    @test sv.data == (one=fill(1.0), two=fill(2.0f0), three=fill(3))
    @test dims(sv) == ()
    sv = view(s, X(1:2), Y(3:3)) 
    @test sv.data == (one=[3.0 6.0]', two=[6.0f0 12.0f0]', three=[9 18]')
    slicedds = view(s, X=:a, Y=:)
    @test slicedds[:one] == [1.0, 2.0, 3.0]
    @test data(slicedds) == (one=[1.0, 2.0, 3.0], two=[2.0f0, 4.0f0, 6.0f0], three=[3, 6, 9])
    @testset "linear indices" begin
        linear2d = view(s, 1)
        @test linear2d isa NamedTuple
        @test linear2d == (one=fill(1.0), two=fill(2.0f0), three=fill(3))
        linear1d = view(s[X(1)], 1)
        @test_broken linear1d isa DimStack
        @test_broken data(linear1d) == (one=fill(1.0), two=fill(2.0f0), three=fill(3))
    end
end

@testset "setindex!" begin
    s_set = deepcopy(s)
    s_set[1, 1] = (one=9, two=10, three=11)
    @test s_set[1, 1] === (one=9.0, two=10.0f0, three=11) 
    s_set[X=:b, Y=10.0] = (one=7, two=11, three=13)
    @test s_set[2, 1] === (one=7.0, two=11.0f0, three=13) 
end


@testset "Empty getindedex/view/setindex throws a BoundsError" begin
    @test_throws BoundsError s[]
    @test_throws BoundsError view(s)
    @test_throws BoundsError s[] = 1
end

@testset "Cartesian indices work as usual" begin
    @test s[CartesianIndex(2, 2)] == (one=5.0, two=10.0, three=15.0)
    @test view(s, CartesianIndex(2, 2)) == map(d -> view(d, 2, 2), data(s))
    s_set = deepcopy(s)
    s_set[CartesianIndex(2, 2)] = (one=5, two=6, three=7)
    @test s_set[2, 2] === (one=5.0, two=6.0f0, three=7)
    s_set[CartesianIndex(2, 2)] = (9, 10, 11)
    @test s_set[2, 2] === (one=9.0, two=10.0f0, three=11)
    @test_throws ArgumentError s_set[CartesianIndex(2, 2)] = (seven=5, two=6, three=7)
end

@testset "map" begin
    @test values(map(a -> a .* 2, s)) == values(DimStack(2da1, 2da2, 2da3))
    @test dims(map(a -> a .* 2, s)) == dims(DimStack(2da1, 2da2, 2da3))
    @test map(a -> a[1], s) == (one=1.0, two=2.0, three=3.0)
end

@testset "Methods with no arguments" begin
    @testset "permuting methods" begin
        @test data(permutedims(s)) == 
            (one=[1.0 4.0; 2.0 5.0; 3.0 6.0],
             two=[2.0 8.0; 4.0 10.0; 6.0 12.0],
             three=[3.0 12.0; 6.0 15.0; 9.0 18.0])
        @test adjoint(s) == DimStack(adjoint(da1), adjoint(da2), adjoint(da3))
        @test transpose(s) == DimStack(transpose(da1), transpose(da2), transpose(da3))
        @test Transpose(s) == DimStack(Transpose(da1), Transpose(da2), Transpose(da3))
        @test data(rotl90(s)) ==
            (one=[3.0 6.0;  2.0 5.0;  1.0 4.0],
             two=[6.0f0 12.0f0; 4.0f0 10.0f0; 2.0f0 8.0],
           three=[9 18; 6 15; 3 12])
        @test rotl90(s) == DimStack(rotl90(da1), rotl90(da2), rotl90(da3))
        @test rotr90(s) == DimStack(rotr90(da1), rotr90(da2), rotr90(da3))
        @test rot180(s) == DimStack(rot180(da1), rot180(da2), rot180(da3))
    end

    @test cor(s) isa DimStack
    @test cov(s) isa DimStack

    @test inv(s[1:2, 1:2]) isa DimStack

    @testset "reducing methods" begin
        @test sum(s) === (one=21.0, two=42.0f0, three=63)
        @test prod(s) === (one=720.0, two=46080.0f0, three=524880)
        @test Base.minimum(s) === (one=1.0, two=2.0f0, three=3)
        @test maximum(s) === (one=6.0, two=12.0f0, three=18)
        @test extrema(s) === (one=(1.0, 6.0), two=(2.0f0, 12.0f0), three=(3, 18))
        @test mean(s) === (one=3.5, two=7.0f0, three=10.5)
        @test std(s) === (one=1.8708286933869707, two=3.7416575f0, three=5.612486080160912)
        @test var(s) === (one=3.5, two=14.0f0, three=31.5)
        @test median(s) === (one=3.5, two=7.0f0, three=10.5)
    end
end

@testset "Methods with a dims keyword argument" begin
    @testset "reducing methods" begin
        sum_ = sum(s; dims=X)
        @test sum_  == DimStack(sum(da1; dims=X), sum(da2; dims=X), sum(da3; dims=X))
        @test dims(sum_) == (X([:combined], Categorical()), dims(da1, Y))
        @test prod(s; dims=X) == DimStack(prod(da1; dims=X), prod(da2; dims=X), prod(da3; dims=X))
        @test dims(maximum(s; dims=X)) == 
            dims(DimStack(maximum(da1; dims=X), maximum(da2; dims=X), maximum(da3; dims=X)))
        @test minimum(s; dims=X) == DimStack(minimum(da1; dims=X), minimum(da2; dims=X), minimum(da3; dims=X))
        @test mean(s; dims=X()) == DimStack(mean(da1; dims=X), mean(da2; dims=X), mean(da3; dims=X))
        @test std(s; dims=X) == DimStack(std(da1; dims=X), std(da2; dims=X), std(da3; dims=X))
        @test var(s; dims=X) == DimStack(var(da1; dims=X), var(da2; dims=X), var(da3; dims=X))
        @test median(s; dims=X) == DimStack(median(da1; dims=X), median(da2; dims=X), median(da3; dims=X))
        mean(mixed; dims=X)
        mean(mixed; dims=Y)
        @test_broken mean(mixed; dims=Z)
    end

    @testset "dim duplicating methods" begin
        @test cor(s; dims=X) isa DimStack
        @test cov(s; dims=X) isa DimStack
    end

    @testset "dim dropping methods" begin
        @test DimensionalData.layers(dropdims(s[X([1])]; dims=X)) == 
            (one=DimArray([1.0, 2.0, 3.0], dims(da1, Y)), 
             two=DimArray([2.0, 4.0, 6.0], dims(da1, Y)),
             three=DimArray([3.0, 6.0, 9.0], dims(da1, Y)))
    end

end

@testset "permuting methods with an argument" begin
    @test permutedims(s, (Y, X)) == 
        DimStack(permutedims(da1, (Y, X)), permutedims(da2, (Y, X)), permutedims(da3, (Y, X)))
    @test PermutedDimsArray(s, (Y(), X())) ==
        DimStack(PermutedDimsArray(da1, (Y, X)), PermutedDimsArray(da2, (Y, X)), PermutedDimsArray(da3, (Y, X)))
    rot = rotl90(s, 1)
    @test rot isa DimStack
    @test typeof(data(rot)) == NamedTuple{(:one, :two, :three),Tuple{Matrix{Float64},Matrix{Float32},Matrix{Int64}}}
    @test data(rot) ==
        (one=[3.0 6.0;  2.0 5.0;  1.0 4.0],
         two=[6.0f0 12.0f0; 4.0f0 10.0f0; 2.0f0 8.0f0],
       three=[9 18; 6 15; 3 12])
    @test rot[:one][X(:a), Y(10.0)] == da1[X(:a), Y(10.0)]
    @test rotr90(s, 2) == DimStack(rotr90(da1, 2), rotr90(da2, 2), rotr90(da3, 2))
    @test rot180(s, 1) == DimStack(rot180(da1, 1), rot180(da2, 1), rot180(da3, 1))
end

@testset "reducing methods that take a function" begin
    f = x -> 2x
    @test data(minimum(f, s; dims=X)) == 
        (one=[2.0 4.0 6.0], two=[4.0 8.0 12.0], three=[6.0 12.0 18.0])
    @test data(mean(x -> 2x, s; dims=X())) ==
        (one=mean(2da1; dims=X) , two=mean(2da2; dims=X), three=mean(2da3; dims=X))
    @test mean(f, s; dims=X) == DimStack(mean(f, da1; dims=X), mean(f, da2; dims=X), mean(f, da3; dims=X))
    @test reduce(+, s; dims=X) == DimStack(reduce(+, da1; dims=X), reduce(+, da2; dims=X), reduce(+, da3; dims=X))
    @test sum(f, s; dims=X) == DimStack(sum(f, da1; dims=X), sum(f, da2; dims=X), sum(f, da3; dims=X))
    @test prod(f, s; dims=X) == DimStack(prod(f, da1; dims=X), prod(f, da2; dims=X), prod(f, da3; dims=X))
    @test maximum(f, s; dims=X) == DimStack(maximum(f, da1; dims=X), maximum(f, da2; dims=X), maximum(f, da3; dims=X))
    @test extrema(f, s; dims=X) == DimStack(extrema(f, da1; dims=X), extrema(f, da2; dims=X), extrema(f, da3; dims=X))
    @test reduce(+, s) == (one=21.0, two=42.0, three=63.0)
    @test sum(f, s) == (one=42.0, two=84.0, three=126.0)
    @test prod(f, s) == (one=46080., two=2.94912e6, three=3.359232e7)
    @test Base.minimum(f, s) == (one=2.0, two=4.0, three=6.0)
    @test maximum(f, s) == (one=12.0, two=24.0, three=36.0)
    @test extrema(f, s) == (one=(2.0, 12.0), two=(4.0, 24.0), three=(6.0, 36.0))
    @test mean(f, s) == (one=7.0, two=14.0, three=21)
end
