using DimensionalData, Test, Unitful
using DimensionalData: Forward, slicedims

@dim TestDim "Test dimension"

@testset "dims creation macro" begin
    @test name(TestDim) == "Test dimension"
    @test label(TestDim) == "Test dimension"
    @test shortname(TestDim) == "TestDim"
    @test val(TestDim(:test)) == :test
    @test metadata(TestDim(1, Auto(), "metadata")) == "metadata"
    @test units(TestDim) == nothing
    @test label(TestDim) == "Test dimension"
    @test eltype(TestDim(1)) <: Int
    @test eltype(TestDim([1, 2, 3])) <: Int
    @test length(TestDim(1)) == 1
    @test length(TestDim([1, 2, 3])) == 3
    @test_throws ErrorException step(TestDim(1:2:3)) == 2
    @test step(TestDim(1:2:3; mode=Sampled(span=Regular(2)))) == 2
    @test firstindex(TestDim(10:20)) == 1
    @test lastindex(TestDim(10:20)) == 11
    @test size(TestDim(10:20)) == (11,)
    @test ndims(TestDim(10:20)) == 1
end

# Basic dim and array initialisation
a = ones(5, 4)
# Must construct with a tuple for dims/refdims

@test_throws MethodError DimensionalArray(a, X((140, 148)))
@test_throws MethodError DimensionalArray(a, (X((140, 148)), Y((2, 11))), Z(1))
da = DimensionalArray(a, (X((140, 148)), Y((2, 11))))

dimz = dims(da)
@test d = slicedims(dimz, (2:4, 3)) == 
    ((X(LinRange(142,146,3); mode=Sampled(span=Regular(2.0))),),
     (Y(8.0, mode=Sampled(span=Regular(3.0))),))
@test name(dimz) == ("X", "Y")
@test shortname(dimz) == ("X", "Y")
@test units(dimz) == (nothing, nothing)
@test label(dimz) == ("X, Y")

a = [1 2 3 4
     2 3 4 5
     3 4 5 6]
da = DimensionalArray(a, (X((143, 145)), Y((-38, -35))))
dimz = dims(da) 

@testset "dims" begin
    @test dims(dimz) === dimz
    @test dims(dimz, X) === dimz[1]
    @test dims(dimz, Y) === dimz[2]
    @test_throws ArgumentError dims(dimz, Ti)
    @test typeof(dims(da)) == 
        Tuple{X{LinRange{Float64},Sampled{Ordered{Forward,Forward,Forward},Regular{Float64},Points},Nothing},
              Y{LinRange{Float64},Sampled{Ordered{Forward,Forward,Forward},Regular{Float64},Points},Nothing}}
end

@testset "arbitrary dim names" begin
    dimz = (Dim{:row}((10, 30)), Dim{:column}((-20, 10)))
    @test name(dimz) == ("Dim row", "Dim column")
    @test shortname(dimz) == ("row", "column")
    @test label(dimz) == ("Dim row, Dim column")
end

@testset "repeating dims of the same type is allowed" begin
    dimz = X((143, 145)), X((-38, -35))
    @test dims(dimz, X) === dimz[1]
    @test dims(dimz, (X, X)) === dimz
    @test dimnum(dimz, (X, X)) === (1, 2)
    @test hasdim(dimz, (X, X)) === (true, true)
    @test permutedims(dimz, (X, X)) === dimz
end

@testset "applying function on a dimension" begin
    d = X(0:0.01:2π)
    a = DimensionalArray(cos, d)
    @test length(dims(a)) == 1
    @test typeof(dims(a)[1]) <: X
    @test a.data == cos.(d.val)
end
