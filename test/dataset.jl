using DimensionalData, Test, LinearAlgebra, Statistics

A = [1.0 2.0 3.0;
     4.0 5.0 6.0]

da1 = DimArray(A, (X([:a, :b]), Y(10.0:10.0:30.0)), :one)
da2 = DimArray(Float32.(2A), (X([:a, :b]), Y(10.0:10.0:30.0)), :two)
da3 = DimArray(Int.(3A), (X([:a, :b]), Y(10.0:10.0:30.0)), :three)
#da3 = DimArray(cat(3A, 3A; dims=Z(1:2; mode=NoIndex())), (X([:a, :b]), Y(10.0:10.0:30.0), Z()), "three")
#@edit cat(da1, da2; dims=3)

das = (da1, da2, da3)

ds = DimDataset(das)

@testset "Properties" begin
    @test DimensionalData.dims(ds) == dims(da1)
    @test keys(layers(ds)) == (:one, :two, :three)
    @test keys(layers(ds)) == (:one, :two, :three)
    da1x = ds[:one]
    @test parent(da1x) === parent(da1)
    @test dims(da1x) === dims(da1)
end

@testset "getindex" begin
    @test ds[1, 1] === (one=1.0, two=2.0f0, three=3)
    @test ds[X(2), Y(3)] === (one=6.0, two=12.0f0, three=18)
    @test ds[X=:b, Y=10.0] === (one=4.0, two=8.0f0, three=12)
    slicedds = ds[:a, :]
    @test slicedds[:one] == [1.0, 2.0, 3.0]
    @test layers(slicedds) == (one=[1.0, 2.0, 3.0], two=[2.0f0, 4.0f0, 6.0f0], three=[3, 6, 9])
end

@testset "map" begin
    @test values(map(a -> a .* 2, ds)) == values(DimDataset(2da1, 2da2, 2da3))
    @test dims(map(a -> a .* 2, ds)) == dims(DimDataset(2da1, 2da2, 2da3))
    @test map(a -> a[1], ds) == (one=1.0, two=2.0, three=3.0)
end



@testset "Methods with no arguments" begin
    @testset "permuting methods" begin
        @test layers(permutedims(ds)) == 
            (one=[1.0 4.0; 2.0 5.0; 3.0 6.0],
             two=[2.0 8.0; 4.0 10.0; 6.0 12.0],
             three=[3.0 12.0; 6.0 15.0; 9.0 18.0])
        @test adjoint(ds) == DimDataset(adjoint(da1), adjoint(da2), adjoint(da3))
        @test transpose(ds) == DimDataset(transpose(da1), transpose(da2), transpose(da3))
        @test Transpose(ds) == DimDataset(Transpose(da1), Transpose(da2), Transpose(da3))
        @test layers(rotl90(ds)) ==
            (one=[3.0 6.0;  2.0 5.0;  1.0 4.0],
             two=[6.0 12.0; 4.0 10.0; 2.0 8.0],
           three=[9.0 18.0; 6.0 15.0; 3.0 12.0])
        @test rotl90(ds) == DimDataset(rotl90(da1), rotl90(da2), rotl90(da3))
        @test rotr90(ds) == DimDataset(rotr90(da1), rotr90(da2), rotr90(da3))
        @test rot180(ds) == DimDataset(rot180(da1), rot180(da2), rot180(da3))
    end

    @test cor(ds) isa DimDataset
    @test cov(ds) isa DimDataset

    @test inv(ds[1:2, 1:2]) isa DimDataset

    @testset "reducing methods" begin
        @test sum(ds) === (one=21.0, two=42.0f0, three=63)
        @test prod(ds) === (one=720.0, two=46080.0f0, three=524880)
        @test Base.minimum(ds) === (one=1.0, two=2.0f0, three=3)
        @test maximum(ds) === (one=6.0, two=12.0f0, three=18)
        @test extrema(ds) === (one=(1.0, 6.0), two=(2.0f0, 12.0f0), three=(3, 18))
        @test mean(ds) === (one=3.5, two=7.0f0, three=10.5)
        @test std(ds) === (one=1.8708286933869707, two=3.7416575f0, three=5.612486080160912)
        @test var(ds) === (one=3.5, two=14.0f0, three=31.5)
        @test median(ds) === (one=3.5, two=7.0f0, three=10.5)
    end
end

@testset "Methods with a dims keyword argument" begin
    @testset "reducing methods" begin
        sum_ = sum(ds; dims=X)
        @test sum_  == DimDataset(sum(da1; dims=X), sum(da2; dims=X), sum(da3; dims=X))
        @test dims(sum_) == (X([:combined], Categorical()), dims(da1, Y))
        @test prod(ds; dims=X) == DimDataset(prod(da1; dims=X), prod(da2; dims=X), prod(da3; dims=X))
        @test dims(maximum(ds; dims=X)) == 
            dims(DimDataset(maximum(da1; dims=X), maximum(da2; dims=X), maximum(da3; dims=X)))
        @test minimum(ds; dims=X) == DimDataset(minimum(da1; dims=X), minimum(da2; dims=X), minimum(da3; dims=X))
        @test mean(ds; dims=X()) == DimDataset(mean(da1; dims=X), mean(da2; dims=X), mean(da3; dims=X))
        @test std(ds; dims=X) == DimDataset(std(da1; dims=X), std(da2; dims=X), std(da3; dims=X))
        @test var(ds; dims=X) == DimDataset(var(da1; dims=X), var(da2; dims=X), var(da3; dims=X))
        @test median(ds; dims=X) == DimDataset(median(da1; dims=X), median(da2; dims=X), median(da3; dims=X))
    end

    @testset "dim duplicating methods" begin
        @test cor(ds; dims=X) isa DimDataset
        @test cov(ds; dims=X) isa DimDataset
    end

    @testset "dim dropping methods" begin
        @test DimensionalData.dimarrays(dropdims(ds[X([1])]; dims=X)) == 
            (one=DimArray([1.0, 2.0, 3.0], dims(da1, Y)), 
             two=DimArray([2.0, 4.0, 6.0], dims(da1, Y)),
             three=DimArray([3.0, 6.0, 9.0], dims(da1, Y)))
    end

end

@testset "permuting methods with an argument" begin
    @test permutedims(ds, (Y, X)) == 
        DimDataset(permutedims(da1, (Y, X)), permutedims(da2, (Y, X)), permutedims(da3, (Y, X)))
    @test PermutedDimsArray(ds, (Y(), X())) ==
        DimDataset(PermutedDimsArray(da1, (Y, X)), PermutedDimsArray(da2, (Y, X)), PermutedDimsArray(da3, (Y, X)))
    rot = rotl90(ds, 1)
    @test rot isa DimDataset
    @test typeof(layers(rot)) == NamedTuple{(:one, :two, :three),Tuple{Matrix{Float64},Matrix{Float32},Matrix{Int64}}}
    @test layers(rot) ==
        (one=[3.0 6.0;  2.0 5.0;  1.0 4.0],
         two=[6.0f0 12.0f0; 4.0f0 10.0f0; 2.0f0 8.0f0],
       three=[9 18; 6 15; 3 12])
    @test rot[:one][X(:a), Y(10.0)] == da1[X(:a), Y(10.0)]
    @test rotr90(ds, 2) == DimDataset(rotr90(da1, 2), rotr90(da2, 2), rotr90(da3, 2))
    @test rot180(ds, 1) == DimDataset(rot180(da1, 1), rot180(da2, 1), rot180(da3, 1))
end

@testset "reducing methods that take a function" begin
    f = x -> 2x
    @test layers(minimum(f, ds; dims=X)) == 
        (one=[2.0 4.0 6.0], two=[4.0 8.0 12.0], three=[6.0 12.0 18.0])
    @test layers(mean(x -> 2x, ds; dims=X())) ==
        (one=mean(2da1; dims=X) , two=mean(2da2; dims=X), three=mean(2da3; dims=X))
    @test mean(f, ds; dims=X) == DimDataset(mean(f, da1; dims=X), mean(f, da2; dims=X), mean(f, da3; dims=X))
    @test reduce(+, ds; dims=X) == DimDataset(reduce(+, da1; dims=X), reduce(+, da2; dims=X), reduce(+, da3; dims=X))
    @test sum(f, ds; dims=X) == DimDataset(sum(f, da1; dims=X), sum(f, da2; dims=X), sum(f, da3; dims=X))
    @test prod(f, ds; dims=X) == DimDataset(prod(f, da1; dims=X), prod(f, da2; dims=X), prod(f, da3; dims=X))
    @test maximum(f, ds; dims=X) == DimDataset(maximum(f, da1; dims=X), maximum(f, da2; dims=X), maximum(f, da3; dims=X))
    @test extrema(f, ds; dims=X) == DimDataset(extrema(f, da1; dims=X), extrema(f, da2; dims=X), extrema(f, da3; dims=X))
    @test reduce(+, ds) == (one=21.0, two=42.0, three=63.0)
    @test sum(f, ds) == (one=42.0, two=84.0, three=126.0)
    @test prod(f, ds) == (one=46080., two=2.94912e6, three=3.359232e7)
    @test Base.minimum(f, ds) == (one=2.0, two=4.0, three=6.0)
    @test maximum(f, ds) == (one=12.0, two=24.0, three=36.0)
    @test extrema(f, ds) == (one=(2.0, 12.0), two=(4.0, 24.0), three=(6.0, 36.0))
    @test mean(f, ds) == (one=7.0, two=14.0, three=21)
end
