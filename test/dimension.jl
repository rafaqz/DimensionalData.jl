using DimensionalData, Test, Unitful
using DimensionalData: X, Y, Z, Time, Forward, @dim, slicedims, dimnum, hasdim

@dim TestDim "Test dimension" 

@testset "dims creation macro" begin
    @test name(TestDim) == "Test dimension"
    @test label(TestDim) == "Test dimension"
    @test shortname(TestDim) == "TestDim"
    @test val(TestDim(:test)) == :test
    @test metadata(TestDim(1, UnknownGrid(), "metadata")) == "metadata"
    @test units(TestDim) == nothing
    @test label(TestDim) == "Test dimension" 
    @test eltype(TestDim(1)) == Int
    @test eltype(TestDim([1,2,3])) == Vector{Int}
    @test length(TestDim(1)) == 1
    @test length(TestDim([1,2,3])) == 3
    @test_throws ErrorException step(TestDim(1:2:3)) == 2
    @test step(TestDim(1:2:3; grid=RegularGrid(; step=2))) == 2
    @test firstindex(TestDim(10:20)) == 1
    @test lastindex(TestDim(10:20)) == 11
    @test size(TestDim(10:20)) == (11,)
    @test ndims(TestDim(10:20)) == 1 
end

# Basic dim and array initialisation
a = ones(5, 4)
# Must construct with a tuple for dims/refdims
@test_throws ArgumentError DimensionalArray(a, X((140, 148)))
@test_throws MethodError DimensionalArray(a, (X((140, 148)), Y((2, 11))), Z(1)) 
da = DimensionalArray(a, (X((140, 148)), Y((2, 11))))

dimz = dims(da)
@test slicedims(dimz, (2:4, 3)) == ((X(LinRange(142,146,3); grid=RegularGrid(step=2.0)),), 
                                    (Y(8.0, grid=RegularGrid(step=3.0)),))
@test name(dimz) == ("X", "Y") 
@test shortname(dimz) == ("X", "Y") 
@test units(dimz) == (nothing, nothing) 
@test label(dimz) == ("X, Y") 

a = [1 2 3 4 
     2 3 4 5
     3 4 5 6]
dimz = X((143, 145)), Y((-38, -35))
da = DimensionalArray(a, dimz)

@testset "dims" begin
    @test dims(dimz) === dimz
    @test dims(dimz, X) === dimz[1]
    @test dims(dimz, Y) === dimz[2]
    @test_throws ArgumentError dims(dimz, Time)
    @test typeof(dims(da)) == Tuple{X{LinRange{Float64},RegularGrid{Ordered{Forward,Forward,Forward},Start,UnknownSampling,Float64},Nothing},
                                Y{LinRange{Float64},RegularGrid{Ordered{Forward,Forward,Forward},Start,UnknownSampling,Float64},Nothing}}
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
