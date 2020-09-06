using DimensionalData, Statistics, Test, Unitful, SparseArrays, Dates

using LinearAlgebra: Transpose

using DimensionalData: Rot90, Rot180, Rot270, Rot360, rotdims, rottype

@testset "map" begin
    a = [1 2; 3 4]
    dimz = (X((143, 145)), Y((-38, -36)))
    da = DimArray(a, dimz)
    @test @inferred map(x -> 2x, da) == [2 4; 6 8]
    @test map(x -> 2x, da) isa DimArray{Int64,2}
end

@testset "dimension reducing methods" begin
    a = [1 2; 3 4]
    dimz = X((143, 145); mode=Sampled()), Y((-38, -36); mode=Sampled())
    da = DimArray(a, dimz)

    @test @inferred sum(da; dims=X()) == sum(a; dims=1)
    @test @inferred sum(da; dims=Y()) == sum(a; dims=2)
    @test dims(sum(da; dims=Y())) ==
        (X(LinRange(143.0, 145.0, 2), Sampled(Ordered(), Regular(2.0), Points()), nothing),
         Y([-37.0], Sampled(Ordered(), Regular(4.0), Points()), nothing))

    @test @inferred prod(da; dims=X) == [3 8]
    @test @inferred prod(da; dims=2) == [2 12]'
    resultdimz =
        (X([144.0], Sampled(Ordered(), Regular(4.0), Points()), nothing),
         Y(LinRange(-38.0, -36.0, 2), Sampled(Ordered(), Regular(2.0), Points()), nothing))
    @test typeof(dims(prod(da; dims=X()))) == typeof(resultdimz)
    @test @inferred bounds(dims(prod(da; dims=X()))) == bounds(resultdimz)

    @test @inferred maximum(x -> 2x, da; dims=X) == [6 8]
    @test @inferred maximum(x -> 2x, da; dims=2) == [4 8]'
    @test @inferred maximum(da; dims=X) == [3 4]
    @test @inferred maximum(da; dims=2) == [2 4]'

    @test @inferred minimum(da; dims=1) == [1 2]
    @test @inferred minimum(da; dims=Y()) == [1 3]'
    @test dims(minimum(da; dims=X())) ==
        (X([144.0], Sampled(Ordered(), Regular(4.0), Points()), nothing),
         Y(LinRange(-38.0, -36.0, 2), Sampled(Ordered(), Regular(2.0), Points()), nothing))

    @test mean(da; dims=1) == [2.0 3.0]
    @test mean(da; dims=Y()) == [1.5 3.5]'
    @test dims(mean(da; dims=Y())) ==
        (X(LinRange(143.0, 145.0, 2), Sampled(Ordered(), Regular(2.0), Points()), nothing),
         Y([-37.0], Sampled(Ordered(), Regular(4.0), Points()), nothing))

    @test mapreduce(x -> x > 3, +, da; dims=X) == [0 1]
    @test mapreduce(x -> x > 3, +, da; dims=2) == [0 1]'
    @test dims(mapreduce(x-> x > 3, +, da; dims=Y())) ==
        (X(LinRange(143.0, 145.0, 2), Sampled(Ordered(), Regular(2.0), Points()), nothing),
         Y([-37.0], Sampled(Ordered(), Regular(4.0), Points()), nothing))

    @test reduce(+, da) == reduce(+, a)
    @test reduce(+, da; dims=X) == [4 6]
    @test reduce(+, da; dims=Y()) == [3 7]'
    @test dims(reduce(+, da; dims=Y())) ==
        (X(LinRange(143.0, 145.0, 2), Sampled(Ordered(), Regular(2.0), Points()), nothing),
         Y([-37.0], Sampled(Ordered(), Regular(4.0), Points()), nothing))

    @test std(da) === std(a)
    @test std(da; dims=1) == [1.4142135623730951 1.4142135623730951]
    @test std(da; dims=Y()) == [0.7071067811865476 0.7071067811865476]'

    @test var(da; dims=1) == [2.0 2.0]
    @test var(da; dims=Y()) == [0.5 0.5]'
    @test dims(var(da; dims=Y())) ==
        (X(LinRange(143.0, 145.0, 2), Sampled(Ordered(), Regular(2.0), Points()), nothing),
         Y([-37.0], Sampled(Ordered(), Regular(4.0), Points()), nothing))

    if VERSION > v"1.1-"
        @test extrema(da; dims=Y) == permutedims([(1, 2) (3, 4)])
        @test extrema(da; dims=X) == [(1, 3) (2, 4)]
    end

    a = [1 2 3; 4 5 6]
    da = DimArray(a, dimz)
    @test median(da) == 3.5
    @test median(da; dims=X()) == [2.5 3.5 4.5]
    @test median(da; dims=2) == [2.0 5.0]'
end

@testset "dimension dropping methods" begin
    a = [1 2 3; 4 5 6]
    dimz = X((143, 145); mode=Sampled()), Y((-38, -36); mode=Sampled())
    da = DimArray(a, dimz)
    # Dimensions must have length 1 to be dropped
    @test dropdims(da[X(1:1)]; dims=X) == [1, 2, 3]
    @test dropdims(da[2:2, 1:1]; dims=(X(), Y()))[] == 4
    @test typeof(dropdims(da[2:2, 1:1]; dims=(X(), Y()))) <: DimArray{Int,0,Tuple{}}
    @test refdims(dropdims(da[X(1:1)]; dims=X)) == 
        (X(143.0; mode=Sampled(Ordered(), Regular(2.0), Points())),)
    dropped = dropdims(da[X(1:1)]; dims=X)
    @test dropped[1:2] == [1, 2]
    @test length.(dims(dropped[1:2])) == size(dropped[1:2])
end

if VERSION > v"1.1-"
    @testset "eachslice" begin
        a = [1 2 3 4
             3 4 5 6
             5 6 7 8]
        da = DimArray(a, (Y((10, 30)), Ti(1:4)))
        @test [mean(s) for s in eachslice(da; dims=Ti)] == [3.0, 4.0, 5.0, 6.0]
        @test [mean(s) for s in eachslice(da; dims=2)] == [3.0, 4.0, 5.0, 6.0]

        slices = [s .* 2 for s in eachslice(da; dims=Y)]
        @test slices[1] == [2, 4, 6, 8]
        @test slices[2] == [6, 8, 10, 12]
        @test slices[3] == [10, 12, 14, 16]
        dims(slices[1]) == (Ti(1.0:1.0:4.0),)

        slices = [s .* 2 for s in eachslice(da; dims=Ti)]
        @test slices[1] == [2, 6, 10]
        dims(slices[1]) == (Y(10.0:10.0:30.0),)
        @test_throws ArgumentError [s .* 2 for s in eachslice(da; dims=(Y, Ti))]
    end
end

@testset "simple dimension permuting methods" begin
    da = DimArray(zeros(5, 4), (Y((10, 20); mode=Sampled()), 
                                        X(1:4; mode=Sampled())))
    tda = transpose(da)
    @test tda == transpose(parent(da))
    resultdims = (X(1:4; mode=Sampled(Ordered(), Regular(1), Points())),
                  Y(LinRange(10.0, 20.0, 5); mode=Sampled(Ordered(), Regular(2.5), Points())))
    @test typeof(dims(tda)) == typeof(resultdims) 
    @test dims(tda) == resultdims
    @test size(tda) == (4, 5)

    tda = Transpose(da)
    @test tda == Transpose(parent(da))
    @test dims(tda) == (X(1:4; mode=Sampled(Ordered(), Regular(1), Points())),
                        Y(LinRange(10.0, 20.0, 5); mode=Sampled(Ordered(), Regular(2.5), Points())))
    @test size(tda) == (4, 5)
    @test typeof(tda) <: DimArray

    ada = adjoint(da)
    @test ada == adjoint(parent(da))
    @test dims(ada) == (X(1:4; mode=Sampled(Ordered(), Regular(1), Points())),
                        Y(LinRange(10.0, 20.0, 5); mode=Sampled(Ordered(), Regular(2.5), Points())))
    @test size(ada) == (4, 5)

    dsp = permutedims(da)
    @test permutedims(parent(da)) == parent(dsp)
    @test dims(dsp) == reverse(dims(da))
end


@testset "dimension permuting methods with specified permutation" begin
    da = DimArray(ones(5, 2, 4), (Y((10, 20); mode=Sampled()), 
                                          Ti(10:11; mode=Sampled()), 
                                          X(1:4; mode=Sampled())))
    dsp = permutedims(da, [3, 1, 2])
    @test permutedims(da, [X, Y, Ti]) == permutedims(da, (X, Y, Ti))
    @test permutedims(da, [X(), Y(), Ti()]) == permutedims(da, (X(), Y(), Ti()))
    dsp = permutedims(da, (X(), Y(), Ti()))
    @test dsp == permutedims(parent(da), (3, 1, 2))
    @test dims(dsp) == (X(1:4; mode=Sampled(Ordered(), Regular(1), Points())),
                        Y(LinRange(10.0, 20.0, 5); mode=Sampled(Ordered(), Regular(2.5), Points())),
                        Ti(10:11; mode=Sampled(Ordered(), Regular(1), Points())))

    dsp = PermutedDimsArray(da, (3, 1, 2))
    @test dsp == PermutedDimsArray(parent(da), (3, 1, 2))
    @test typeof(dsp) <: DimArray
end

@testset "reversing methods" begin
    revdim = reverse(X(10:10:20; mode=Sampled(order=Ordered())))
    @test val(revdim) == 20:-10:10
    @test order(revdim) == Ordered(ReverseIndex(), ForwardArray(), ReverseRelation())

    A = [1 2 3; 4 5 6]
    da = DimArray(A, (X(10:10:20), Y(300:-100:100)))
    rev = reverse(ArrayOrder, da, Y)

    @test rev == [3 2 1; 6 5 4]
    @test val(dims(rev, X)) == 10:10:20
    @test val(dims(rev, Y)) == 300:-100:100
    @test order(dims(rev, X)) == Ordered(ForwardIndex(), ForwardArray(), ForwardRelation())
    @test order(dims(rev, Y)) == Ordered(ReverseIndex(), ReverseArray(), ReverseRelation())
end


@testset "dimension rotating methods" begin
    @test rottype(-100) == Rot360()
    @test rottype(-4) == Rot360()
    @test rottype(-3) == Rot90()
    @test rottype(-2) == Rot180()
    @test rottype(-1) == Rot270()
    @test rottype(0) == Rot360()
    @test rottype(1) == Rot90()
    @test rottype(2) == Rot180()
    @test rottype(3) == Rot270()
    @test rottype(4) == Rot360()
    @test rottype(101) == Rot90()

    da = DimArray([1 2; 3 4], (X([:a, :b]), Y([1.0, 2.0])))

    l90 = rotl90(da)
    r90 = rotr90(da)
    r180_1 = rot180(da)
    r180_2 = rotl90(da, 2)
    r180_3 = rotr90(da, 2)
    r270 = rotl90(da, 3)
    r360 = rotr90(da, 4)
    da[X(:a), Y(At(2.0))]
    @test l90[X(:a), Y(At(2.0))] == 2
    @test r90[X(:a), Y(At(2.0))] == 2
    @test r180_1[X(:a), Y(At(2.0))] == 2
    @test r180_2[X(:a), Y(At(2.0))] == 2
    @test r180_3[X(:a), Y(At(2.0))] == 2
    @test r270[X(:a), Y(At(2.0))] == 2
    @test r360[X(:a), Y(At(2.0))] == 2
end


@testset "dimension mirroring methods" begin
    a = rand(5, 4)
    da = DimArray(a, (Y((10, 20); mode=Sampled()), 
                              X(1:4; mode=Sampled())))
    cvda = cov(da; dims=X)
    @test cvda == cov(a; dims=2)
    @test dims(cvda) == (Y(LinRange(10.0, 20.0, 5); mode=Sampled(Ordered(), Regular(2.5), Points())),
                         Y(LinRange(10.0, 20.0, 5); mode=Sampled(Ordered(), Regular(2.5), Points())))
    crda = cor(da; dims=Y)
    @test crda == cor(a; dims=1)
    @test dims(crda) == (X(1:4; mode=Sampled(Ordered(), Regular(1), Points())),
                         X(1:4; mode=Sampled(Ordered(), Regular(1), Points())))
end

@testset "mapslices" begin
    a = [1 2 3 4
         3 4 5 6
         5 6 7 8]
    da = DimArray(a, (Y((10, 30); mode=Sampled(sampling=Intervals())), 
                              Ti(1:4; mode=Sampled(sampling=Intervals()))))
    ms = mapslices(sum, da; dims=Y)
    @test ms == [9 12 15 18]
    @test typeof(dims(ms)) == 
    typeof((Y([10.0]; mode=Sampled(Ordered(), Regular(30.0), Intervals(Center()))),
            Ti(1:4; mode=Sampled(Ordered(), Regular(1), Intervals(Start())))))
    @test refdims(ms) == ()
    ms = mapslices(sum, da; dims=Ti)
    @test parent(ms) == [10 18 26]'
end

@testset "array info" begin
    da = DimArray(zeros(5, 4), (Y((10, 20)), X(1:4)))
    @test size(da, Y) == 5
    @test size(da, X()) == 4
    @test axes(da, Y()) == Base.OneTo(5)
    @test axes(da, X) == Base.OneTo(4)
    @test firstindex(da, Y) == 1
    @test firstindex(da, X()) == 1
    @test lastindex(da, Y()) == 5
    @test lastindex(da, X) == 4
end

@testset "cat" begin
    a = [1 2 3; 4 5 6]
    da = DimArray(a, (X(1:2), Y(1:3)))
    b = [7 8 9; 10 11 12]
    db = DimArray(b, (X(3:4), Y(1:3)))
    @test cat(da, db; dims=X()) == [1 2 3; 4 5 6; 7 8 9; 10 11 12]
    testdims = (X([1, 2, 3, 4]; mode=Sampled(Ordered(), Regular(1), Points())),
                Y(1:3; mode=Sampled(Ordered(), Regular(1), Points())))
    @test cat(da, db; dims=(X(),)) == cat(da, db; dims=X()) == cat(da, db; dims=X)
          cat(da, db; dims=1) == cat(da, db; dims=(1,))
    @test typeof(dims(cat(da, db; dims=X()))) == typeof(testdims)
    @test val.(dims(cat(da, db; dims=X()))) == val.(testdims)
    @test mode.(dims(cat(da, db; dims=X()))) == mode.(testdims)
    @test cat(da, db; dims=Y()) == [1 2 3 7 8 9; 4 5 6 10 11 12]
    @test cat(da, db; dims=Z(1:2)) == cat(a, b; dims=3)
    @test cat(da, db; dims=(Z(1:1), Ti(1:2))) == cat(a, b; dims=4)
    @test cat(da, db; dims=(X(), Ti(1:2))) == cat(a, b; dims=3)
    dx = cat(da, db; dims=(X(), Ti(1:2)))
    @test dims(dx) == DimensionalData.formatdims(dx, (X(1:2), Y(1:3), Ti(1:2)))
end

@testset "unique" begin
    a = [1 1 6; 1 1 6]
    da = DimArray(a, (X(1:2), Y(1:3)))
    @test unique(da; dims=X()) == [1 1 6]
    @test unique(da; dims=Y) == [1 6; 1 6]
end
