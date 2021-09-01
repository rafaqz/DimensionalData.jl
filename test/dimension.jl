using DimensionalData, Test, Unitful
using DimensionalData: slicedims, basetypeof, formatdims, modetype, name

@dim TestDim "Testname"

@testset "dims creation macro" begin
    @test TestDim(1:10, Sampled(), NoMetadata()) == TestDim(1:10, Sampled(), NoMetadata())
    @test TestDim(1:10; mode=Categorical()) == TestDim(1:10, Categorical(), NoMetadata())
    @test DimensionalData.name(TestDim) == :Testname
    @test label(TestDim) == "Testname"
    @test val(TestDim(:testval)) == :testval
    @test metadata(TestDim(1, AutoMode(), Metadata(a=1))) == Metadata(a=1)
    @test units(TestDim) == nothing
    @test label(TestDim) == "Testname"
    @test eltype(TestDim(1)) == Int
    @test eltype(TestDim([1, 2, 3])) <: Int
    @test length(TestDim(1)) == 1
    @test length(TestDim([1, 2, 3])) == 3
    @test eachindex(TestDim(10:10:30)) == Base.OneTo(3)
    @test eachindex(TestDim(10)) == Base.OneTo(1)
    @test step(TestDim(1:2:3)) == 2
    @test step(TestDim(Base.OneTo(10), mode=NoIndex())) == 1
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
    @test TestDim(5.0:7.0)[2] == 6.0
    @test TestDim(10)[] == 10
    @test TestDim(5.0:7.0, Sampled(Ordered(), Regular(1.0), Points()))[At(6.0)] == 6.0
end

@testset "formatdims" begin
    A = [1 2 3; 4 5 6]
    @test formatdims(A, (X, Y)) == (X(Base.OneTo(2), NoIndex(), NoMetadata()),
                                    Y(Base.OneTo(3), NoIndex(), NoMetadata()))
    @test formatdims(zeros(3), Ti) == (Ti(Base.OneTo(3), NoIndex(), NoMetadata()),)
    @test formatdims(A, (:a, :b)) == (Dim{:a}(Base.OneTo(2), NoIndex(), NoMetadata()),
                                      Dim{:b}(Base.OneTo(3), NoIndex(), NoMetadata()))
    @test formatdims(51:100, :c) == (Dim{:c}(Base.OneTo(50), NoIndex(), NoMetadata()),)
    @test formatdims(A, (a=[:A, :B], b=(10.0:10.0:30.0))) ==
    (Dim{:a}([:A, :B], Categorical(Ordered()), NoMetadata()),
     Dim{:b}(10.0:10:30.0, Sampled(Ordered(), Regular(10.0), Points()), NoMetadata()))
    @test formatdims(A, (X([:A, :B]; metadata=Metadata(a=5)),
           Y(10.0:10.0:30.0, Categorical(Ordered()), Metadata("metadata"=>1)))) ==
          (X([:A, :B], Categorical(Ordered()), Metadata(a=5)),
           Y(10.0:10:30.0, Categorical(Ordered()), Metadata("metadata"=>1)))
    @test formatdims(zeros(3, 4), 
        (Dim{:row}(Val((:A, :B, :C))), 
         Dim{:column}(Val((-20, -10, 0, 10)), Sampled(), NoMetadata()))) ==
        (Dim{:row}(Val((:A, :B, :C)), Categorical(), NoMetadata()), 
         Dim{:column}(Val((-20, -10, 0, 10)), Sampled(Ordered(),Irregular(),Points()), NoMetadata()))
    @test formatdims(A, (X(:, Sampled(Ordered(), Regular(), Points())), Y)) == 
        (X(Base.OneTo(2), Sampled(Ordered(), Regular(1), Points()), NoMetadata()), Y(Base.OneTo(3), NoIndex(), NoMetadata()))
end

@testset "Val" begin
    @test dims(Val{X}()) == Val{X}()
    @test mode(Val{X}()) == NoIndex()
end

@testset "AnonDim" begin
    @test val(AnonDim()) == Colon()
    @test mode(AnonDim()) == NoIndex()
    @test metadata(AnonDim()) == NoMetadata()
    @test name(AnonDim()) == :Anon
end

@testset "Basic dim and array initialisation and methods" begin
    a = ones(5, 4)

    @test_throws DimensionMismatch DimArray(a, X)
    @test_throws DimensionMismatch DimArray(a, (X, Y, Z))

    da = DimArray(a, (X(LinRange(140, 148, 5)), Y(LinRange(2, 11, 4))))
    dimz = dims(da)

    for args in ((dimz,), (dimz, (X(), Y())), (dimz, X(), Y()), 
                 (dimz, (X, Y)), (dimz, X, Y), 
                 (dimz, (1, 2)), (dimz, 1, 2))
        @test val(args...) == index(args...) == (LinRange(140, 148, 5), LinRange(2, 11, 4))
        @test name(args...) == (:X, :Y)
        @test units(args...) == (nothing, nothing)
        @test label(args...) == ("X", "Y")
        @test sampling(args...) == (Points(), Points())
        @test span(args...) == (Regular(2.0), Regular(3.0))
        @test locus(args...) == (Center(), Center())
        @test order(args...) == (Ordered(), Ordered())
        @test arrayorder(args...) == order(ArrayOrder, args...) == (ForwardArray(), ForwardArray())
        @test indexorder(args...) == order(IndexOrder, args...) == (ForwardIndex(), ForwardIndex())
        @test relation(args...) == order(Relation, args...) == (ForwardRelation(), ForwardRelation())
        @test bounds(args...) == ((140, 148), (2, 11))
        @test mode(args...) == (Sampled(Ordered(), Regular(2.0), Points()), 
                             Sampled(Ordered(), Regular(3.0), Points()))
    end

    @test val(dimz, ()) == index(dimz, ()) == ()
    @test val(dimz, 1) == val(dimz, X) == val(dimz, X()) == val(dimz[1])
    @test order(Relation, dimz, 1) == order(Relation, dimz, X) == order(Relation, dimz, X()) == ForwardRelation()
    @test order(Relation, dimz, ()) == ()

    @test dims(dimz, Y) === dimz[2]
    @test slicedims(dimz, (2:4, 3)) ==
        ((X(LinRange(142,146,3); mode=Sampled(Ordered(), Regular(2.0), Points())),),
             (Y(8.0, mode=Sampled(Ordered(), Regular(3.0), Points())),))

    @test mode(X) == NoIndex()
    @test modetype(dims(dimz, X)) == Sampled{Ordered{ForwardIndex,ForwardArray,ForwardRelation},Regular{Float64},Points}
end


@testset "arbitrary dim names and Val index" begin
    dimz = formatdims(zeros(3, 4),
           (Dim{:row}(Val((:A, :B, :C))), 
            Dim{:column}(Val((-20, -10, 0, 10)), Sampled(Ordered(),Regular(10),Points()), NoMetadata()))
    )
    @test name(dimz) == (:row, :column)
    @test label(dimz) == ("row", "column")
    @test basetypeof(dimz[1]) == Dim{:row}
    @test length(dims(dimz, :row)) == 3
    @test size(dims(dimz, :row)) == (3,)
    @test eltype(dims(dimz, :row)) == Symbol
    @test firstindex(dimz[1]) == 1
    @test lastindex(dimz[1]) == 3
    @test ndims(dimz[1]) == 1
    @test Array(dimz[1]) == [:A, :B, :C]

    @testset "specify dim with Symbol" begin
        # @test_throws ArgumentError arrayorder(dimz, :x)
        # TODO Does this make sense?
        @test arrayorder(dimz, :row) == ForwardArray()
        @test arrayorder(dimz, :column) == ForwardArray()
        @test bounds(dimz, :row) == (nothing, nothing)
        @test bounds(dimz, :column) == (-20, 10)
        @test index(dimz, :row) == (:A, :B, :C)
        @test index(dimz, :column) == (-20, -10, 0, 10)
    end

end

@testset "repeating dims of the same type is allowed" begin
    dimz = X((143, 145)), X((-38, -35))
    @test dims(dimz, X) === dimz[1]
    @test dims(dimz, (X, X)) === dimz
    @test dimnum(dimz, (X, X)) === (1, 2)
    @test hasdim(dimz, (X, X)) === (true, true)
    @test sortdims(dimz, (X, X)) === dimz
end

@testset "applying function on a dimension" begin
    d = X(0:0.01:2π)
    a = DimArray(cos, d)
    @test length(dims(a)) == 1
    @test typeof(dims(a)[1]) <: X
    @test a.data == cos.(d.val)
end
