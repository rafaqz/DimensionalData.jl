using DimensionalData, Test, Unitful
using DimensionalData: Forward, slicedims, basetypeof, formatdims

@dim TestDim "Test dimension"

@testset "dims creation macro" begin
    @test name(TestDim) == "Test dimension"
    @test label(TestDim) == "Test dimension"
    @test shortname(TestDim) == "TestDim"
    @test val(TestDim(:test)) == :test
    @test metadata(TestDim(1, AutoMode(), "metadata")) == "metadata"
    @test units(TestDim) == nothing
    @test label(TestDim) == "Test dimension"
    @test eltype(TestDim(1)) <: Int
    @test eltype(TestDim([1, 2, 3])) <: Int
    @test length(TestDim(1)) == 1
    @test length(TestDim([1, 2, 3])) == 3
    @test_throws ErrorException step(TestDim(1:2:3)) == 2
    @test step(TestDim(1:2:3; mode=Sampled(span=Regular(2)))) == 2
    @test first(TestDim(5)) == 5
    @test last(TestDim(5)) == 5
    @test first(TestDim(10:20)) == 10
    @test last(TestDim(10:20)) == 20
    @test firstindex(TestDim(5)) == 1
    @test lastindex(TestDim(5)) == 1
    @test firstindex(TestDim(10:20)) == 1
    @test lastindex(TestDim(10:20)) == 11
    @test eachindex(TestDim(10:20)) == Base.OneTo(11)
    @test size(TestDim(10:20)) == (11,)
    @test ndims(TestDim(10:20)) == 1
    @test ndims(TestDim(1)) == 0
    @test Array(TestDim(10:15)) == [10, 11, 12, 13, 14, 15]
    @test iterate(TestDim(10:20)) == iterate(10:20)
end

@testset "formatdims" begin
    A = [1 2 3; 4 5 6]
    @test formatdims(A, (X, Y)) == (X(Base.OneTo(2), NoIndex(), nothing),
                                    Y(Base.OneTo(3), NoIndex(), nothing))
    @test formatdims(zeros(3), Ti) == (Ti(Base.OneTo(3), NoIndex(), nothing),)
    @test formatdims(A, (:a, :b)) == (Dim{:a}(Base.OneTo(2), NoIndex(), nothing),
                                      Dim{:b}(Base.OneTo(3), NoIndex(), nothing))
    @test formatdims(51:100, :c) == (Dim{:c}(Base.OneTo(50), NoIndex(), nothing),)
    @test formatdims(A, (a=[:A, :B], b=(10.0:10.0:30.0))) == 
        (Dim{:a}([:A, :B], Categorical(Unordered()), nothing), 
         Dim{:b}(10.0:10:30.0, Sampled(Ordered(), Regular(10.0), Points()), nothing))
    @test formatdims(A, (X([:A, :B]; metadata=5), 
                   Y(10.0:10.0:30.0, Categorical(Ordered()), Dict("metadata"=>1)))) == 
          (X([:A, :B], Categorical(Unordered()), 5), 
          Y(10.0:10:30.0, Categorical(Ordered()), Dict("metadata"=>1)))
end

@testset "Basic dim and array initialisation" begin
    a = ones(5, 4)
    # Must construct with a tuple for dims/refdims

    @test_throws DimensionMismatch DimArray(a, X)
    @test_throws DimensionMismatch DimArray(a, (X, Y, Z))

    da = DimArray(a, (X((140, 148)), Y((2, 11))))
    dimz = dims(da)
    @test d = typeof(slicedims(dimz, (2:4, 3))) == 
        typeof(((X(LinRange(142,146,3); mode=Sampled(order=Ordered(), span=Regular(2.0))),),
            (Y(8.0, mode=Sampled(order=Ordered(), span=Regular(3.0))),)))
    @test name(dimz) == ("X", "Y")
    @test shortname(dimz) == ("X", "Y")
    @test units(dimz) == (nothing, nothing)
    @test label(dimz) == ("X, Y")
end

a = [1 2 3 4
     2 3 4 5
     3 4 5 6]
da = DimArray(a, (X((143, 145)), Y((-38, -35))))
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
    @test name(dimz) == ("Dim{:row}", "Dim{:column}")
    @test shortname(dimz) == ("row", "column")
    @test label(dimz) == ("Dim{:row}, Dim{:column}")
    @test basetypeof(dimz[1]) == Dim{:row}
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
    a = DimArray(cos, d)
    @test length(dims(a)) == 1
    @test typeof(dims(a)[1]) <: X
    @test a.data == cos.(d.val)
end
