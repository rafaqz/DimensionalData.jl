using DimensionalData, Test, Unitful, BenchmarkTools
using DimensionalData.Lookups, DimensionalData.Dimensions

@dim TestDim "Testname"

@testset "dims creation macro" begin
    @test parent(TestDim(1:10)) == 1:10
    @test val(TestDim(1:10)) == 1:10
    @test name(TestDim) == :TestDim
    @test val(TestDim(:testval)) == :testval
    @test metadata(TestDim(Sampled(1:1; metadata=Metadata(a=1)))) == Metadata(a=1)
    @test units(TestDim) == nothing
    @test label(TestDim) == "Testname"
    @test label(TestDim()) == "Testname"
    @test eltype(TestDim(1)) == Int
    @test eltype(TestDim([1, 2, 3])) <: Int
    @test length(TestDim(1)) == 1
    @test length(TestDim([1, 2, 3])) == 3
    @test eachindex(TestDim(10:10:30)) == Base.OneTo(3)
    @test eachindex(TestDim(1)) == Base.OneTo(1)
    @test step(TestDim(1:2:3)) == 2
    @test step(TestDim(Base.OneTo(10))) == 1
    @test step(TestDim(1:2:3)) == 2
    @test step(TestDim(Sampled(1:2:3; span=Regular(2)))) == 2
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
    @test TestDim(5.0:7.0)[2] == 6.0
    @test TestDim(10)[] == 10
    @test TestDim(Sampled(5.0:7.0, ForwardOrdered(), Regular(1.0), Points(), NoMetadata()))[At(6.0)] == 6.0
end

@testset "name" begin
    @test name(X()) == :X
    @test name(Dim{:x}) == :x
    @test name(TestDim()) == :TestDim
    @test name(Dim{:test}()) == :test
    @test (@ballocated name(Dim{:test}())) == 0
    @test name(Val{TimeDim}()) == :TimeDim
end

@testset "format" begin
    A = [1 2 3; 4 5 6]
    @test format((X, Y), A) == (X(NoLookup(Base.OneTo(2))), Y(NoLookup(Base.OneTo(3))))
    @test format(Ti, zeros(3)) == (Ti(NoLookup(Base.OneTo(3))),)
    @test format((:a, :b), A) == (Dim{:a}(NoLookup(Base.OneTo(2))),
                                  Dim{:b}(NoLookup(Base.OneTo(3))))
    @test format(:c, 51:100) == (Dim{:c}(NoLookup(Base.OneTo(50))),)
    @test format((a=[:A, :B], b=(10.0:10.0:30.0)), A) ==
        (Dim{:a}(Categorical([:A, :B], Unordered(), NoMetadata())),
         Dim{:b}(Sampled(10.0:10:30.0, ForwardOrdered(), Regular(10.0), Points(), NoMetadata())))
    @test format((X([:A, :B]; metadata=Metadata(a=5)),
           Y(Categorical(10.0:10.0:30.0, Unordered(), Metadata("metadata"=>1)))), A) ==
          (X(Categorical([:A, :B], Unordered(), Metadata(a=5))),
           Y(Categorical(10.0:10.0:30.0, Unordered(), Metadata("metadata"=>1))))
    @test format((X(Sampled(Base.OneTo(2); order=ForwardOrdered(), span=Regular(), sampling=Points())), Y), A) == 
        (X(Sampled(Base.OneTo(2), ForwardOrdered(), Regular(1), Points(), NoMetadata())), 
         Y(NoLookup(Base.OneTo(3))))
end

@testset "Val" begin
    @test dims(Val{X}()) == Val{X}()
    @test lookup(Val{X}()) == NoLookup()
end

@testset "AnonDim" begin
    @test val(AnonDim()) == Colon()
    @test lookup(AnonDim(NoLookup())) == NoLookup()
    @test metadata(AnonDim()) == NoMetadata()
    @test name(AnonDim()) == :AnonDim
end

@testset "Basic dim and array initialisation and methods" begin
    a = ones(5, 4)

    @test_throws DimensionMismatch DimArray(a, X)
    @test_throws DimensionMismatch DimArray(a, (X, Y, Z))

    da = DimArray(a, (X(LinRange(140, 148, 5)), Y(LinRange(2, 11, 4))))
    dimz = dims(da)

    for args in ((dimz,), 
                 (dimz, (X(), Y())), 
                 (dimz, X(), Y()), 
                 (dimz, (X, Y)) , 
                 (dimz, X, Y), 
                 (dimz, (1, 2)), 
                 (dimz, 1, 2)
        )
        @test name(args...) == (:X, :Y)
        @test units(args...) == (nothing, nothing)
        @test label(args...) == ("X", "Y")
        @test sampling(args...) == (Points(), Points())
        @test span(args...) == (Regular(2.0), Regular(3.0))
        @test locus(args...) == (Center(), Center())
        @test order(args...) == (ForwardOrdered(), ForwardOrdered())
        @test bounds(args...) == ((140, 148), (2, 11))
        @test lookup(args...) == (Sampled(LinRange(140, 148, 5), ForwardOrdered(), Regular(2.0), Points(), NoMetadata()), 
                                Sampled(LinRange(2, 11, 4), ForwardOrdered(), Regular(3.0), Points(), NoMetadata()))
    end

    @test val(dimz, ()) == ()
    @test val(dimz, 1) == val(dimz, X) == val(dimz, X()) == val(dimz[1])

    @test dims(dimz, Y) === dimz[2]
    @test slicedims(dimz, (2:4, 3)) ==
        ((X(Sampled(LinRange(142, 146, 3), ForwardOrdered(), Regular(2.0), Points(), NoMetadata())),),
         (Y(Sampled(LinRange(8.0, 8.0, 1), ForwardOrdered(), Regular(3.0), Points(), NoMetadata())),))

    @test lookup(X) == NoLookup()
end

@testset "repeating dims of the same type is allowed" begin
    dimz = X((143, 145)), X((-38, -35))
    @test dims(dimz, X) === dimz[1]
    @test dims(dimz, (X, X)) === dimz
    @test dimnum(dimz, (X, X)) === (1, 2)
    @test hasdim(dimz, (X, X)) === (true, true)
    @test sortdims(dimz, (X, X)) === dimz
end

@testset "constructing with keywords" begin
    @test X(1; foo=:bar) == X(DimensionalData.AutoVal(1, (; foo=:bar)))
    @test X(1:10; foo=:bar) == X(DimensionalData.AutoLookup(1:10, (; foo=:bar)))
    @test Dim{:x}(1; foo=:bar) == Dim{:x}(DimensionalData.AutoVal(1, (; foo=:bar)))
    @test Dim{:x}(1:10; foo=:bar) == Dim{:x}(DimensionalData.AutoLookup(1:10, (; foo=:bar)))
end

@testset "applying function on a dimension" begin
    d = X(0:0.01:2π)
    a = DimArray(cos, d)
    @test length(dims(a)) == 1
    @test typeof(dims(a)[1]) <: X
    @test a.data == cos.(d.val)
end

@testset "dims(::Array) is nothing" begin
    sz = ntuple(identity, 4)
    @testset for ndims in eachindex(sz)
        @test isnothing(dims(randn(sz[1:ndims])))
    end
end
