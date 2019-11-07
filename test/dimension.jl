@dim TestDim "Test dimension" 

@testset "dims creation macro" begin
    @test name(TestDim) == "Test dimension"
    @test shortname(TestDim) == "TestDim"
    @test val(TestDim(:test)) == :test
    @test metadata(TestDim(1, AllignedGrid(), "metadata")) == "metadata"
    @test units(TestDim) == nothing
    @test label(TestDim) == "Test dimension" 
    @test eltype(TestDim(1)) == Int
    @test eltype(TestDim([1,2,3])) == Vector{Int}
    @test length(TestDim(1)) == 1
    @test length(TestDim([1,2,3])) == 3
end

# Basic dim and array initialisation
a = ones(5, 4)
# Must construct with a tuple for dims/refdims
@test_throws MethodError DimensionalArray(a, X((140, 148)))
@test_throws MethodError DimensionalArray(a, (X((140, 148)), Y((2, 11))), Z(1)) 
da = DimensionalArray(a, (X((140, 148)), Y((2, 11))))


dimz = dims(da)
@test slicedims(dimz, (2:4, 3)) == ((X(LinRange(142,146,3)),), (Y(8.0),))
@test name(dimz) == ("X", "Y") 
@test shortname(dimz) == ("X", "Y") 
@test units(dimz) == (nothing, nothing) 
@test label(dimz) == ("X, Y") 

a = [1 2 3 4 
     2 3 4 5
     3 4 5 6]
dimz = (X((143, 145), AllignedGrid(), nothing), 
        Y((-38, -35), AllignedGrid(), nothing))
da = DimensionalArray(a, dimz)

@testset "dims" begin
    @test dims(dimz) === dimz
    @test dims(dimz, X) === dimz[1]
    @test dims(dimz, Y) === dimz[2]
    @test_throws ArgumentError dims(dimz, Time)
    @test typeof(dims(da)) == Tuple{X{LinRange{Float64},AllignedGrid{Ordered{Forward,Forward},Center,UnknownSampling,Nothing},Nothing},
                                Y{LinRange{Float64},AllignedGrid{Ordered{Forward,Forward},Center,UnknownSampling,Nothing},Nothing}}
end

@testset "arbitrary dim names" begin
    dimz = (Dim{:row}((10, 30)), Dim{:column}((-20, 10)))
    @test name(dimz) == ("Dim row", "Dim column")
    @test shortname(dimz) == ("row", "column")
    @test label(dimz) == ("Dim row, Dim column")
end
