using DimensionalData, Statistics, Test, Unitful, SparseArrays, Dates

using DimensionalData: EmptyDim

using LinearAlgebra: Transpose

using Combinatorics: combinations

@testset "*" begin
    timespan = DateTime(2001):Month(1):DateTime(2001,12)
    A1 = DimensionalArray(rand(12), (Ti(timespan),)) 
    A2 = DimensionalArray(rand(12, 1), (Ti(timespan), X(10:10:10))) 

    @test length.(dims(A1)) == size(A1)
    @test dims(data(A1) * permutedims(A1)) isa Tuple{<:Ti,<:Ti}
    @test data(A1) * permutedims(A1) == data(A1) * permutedims(data(A1))
    @test dims(permutedims(A1) * data(A1)) isa Tuple{<:EmptyDim}
    @test permutedims(A1) * data(A1) == permutedims(data(A1)) * data(A1)

    @test length.(dims(permutedims(A1) * data(A1))) == size(permutedims(data(A1)) * data(A1))
    @test length.(dims(permutedims(A1) * A1)) == size(permutedims(data(A1)) * data(A1))
    @test length.(dims(permutedims(data(A1)) * A1)) == size(permutedims(data(A1)) * data(A1))

    @test length.(dims(data(A1) * permutedims(A1))) == size(data(A1) * permutedims(data(A1)))
    @test length.(dims(A1 * permutedims(A1))) == size(data(A1) * permutedims(data(A1)))
    @test length.(dims(A1 * permutedims(data(A1)))) == size(data(A1) * permutedims(data(A1)))

    @test length.(dims(A2)) == size(A2)
    @test length.(dims(A2')) == size(A2')

    sze1 = (12, 12)
    @test size(data(A2) * data(A2)') == sze1
    @test length.(dims(A2 * A2')) == sze1
    @test length.(dims(data(A2) * A2')) == sze1
    @test length.(dims(A2 * data(A2'))) == sze1
    sze2 = (1, 1)
    @test size(data(A2') * data(A2)) == sze2
    @test length.(dims(A2' * A2)) == sze2
    @test length.(dims(data(A2') * A2)) == sze2
    @test length.(dims(A2' * data(A2))) == sze2

    B1 = DimensionalArray(rand(12, 6), (Ti(timespan), X(1:6)))
    B2 = DimensionalArray(rand(8, 12), (Y(1:8), Ti(timespan)))
    b1 = DimensionalArray(rand(12), Ti(timespan))

    # Test dimension propagation
    @test (B2 * B1) == (data(B2) * data(B1))
    @test dims(B2 * B1) isa Tuple{<:Y, <:X}
    @test length.(dims(B2 * B1)) == (8, 6)

    # Test where results have an empty dim
    true_result = (data(b1)' * data(B1))
    for flip in (adjoint, transpose, permutedims)
        result = flip(b1) * B1
        @test result ≈ true_result  # Permute dims is not exactly transpose
        @test dims(result) isa Tuple{<:EmptyDim, <:X}
        @test length.(dims(result)) == (1, 6)
    end

    # Test flipped * flipped
    for (flip1, flip2) in combinations((adjoint, transpose, permutedims), 2)
        result = flip1(B1) * flip2(B2)
        @test result == flip1(data(B1)) * flip2(data(B2))
        @test dims(result) isa Tuple{<:X, <:Y}
        @test size(result) == (6, 8)
    end

end


@testset "map" begin
    a = [1 2; 3 4]
    dimz = (X((143, 145)), Y((-38, -36)))
    da = DimensionalArray(a, dimz)
    @test map(x -> 2x, da) == [2 4; 6 8]
    @test map(x -> 2x, da) isa DimensionalArray{Int64,2}
end

@testset "dimension reducing methods" begin
    a = [1 2; 3 4]
    dimz = X((143, 145); indexmode=SampledIndex()), Y((-38, -36); indexmode=SampledIndex())
    da = DimensionalArray(a, dimz)
    @test sum(da; dims=X()) == sum(a; dims=1)
    @test sum(da; dims=Y()) == sum(a; dims=2)
    @test dims(sum(da; dims=Y())) ==
        (X(LinRange(143.0, 145.0, 2), SampledIndex(Ordered(), RegularSpan(2.0), PointSampling()), nothing),
         Y([-37.0], SampledIndex(Ordered(), RegularSpan(4.0), PointSampling()), nothing))
    @test prod(da; dims=X) == [3 8]
    @test prod(da; dims=2) == [2 12]'
    resultdimz =
        (X([144.0], SampledIndex(Ordered(), RegularSpan(4.0), PointSampling()), nothing),
         Y(LinRange(-38.0, -36.0, 2), SampledIndex(Ordered(), RegularSpan(2.0), PointSampling()), nothing))
    @test typeof(dims(prod(da; dims=X()))) == typeof(resultdimz)
    @test bounds(dims(prod(da; dims=X()))) == bounds(resultdimz)
    @test maximum(x -> 2x, da; dims=X) == [6 8]
    @test maximum(x -> 2x, da; dims=2) == [4 8]'
    @test maximum(da; dims=X) == [3 4]
    @test maximum(da; dims=2) == [2 4]'
    @test minimum(da; dims=1) == [1 2]
    @test minimum(da; dims=Y()) == [1 3]'
    @test dims(minimum(da; dims=X())) ==
        (X([144.0], SampledIndex(Ordered(), RegularSpan(4.0), PointSampling()), nothing),
         Y(LinRange(-38.0, -36.0, 2), SampledIndex(Ordered(), RegularSpan(2.0), PointSampling()), nothing))
    @test mean(da; dims=1) == [2.0 3.0]
    @test mean(da; dims=Y()) == [1.5 3.5]'
    @test dims(mean(da; dims=Y())) ==
        (X(LinRange(143.0, 145.0, 2), SampledIndex(Ordered(), RegularSpan(2.0), PointSampling()), nothing),
         Y([-37.0], SampledIndex(Ordered(), RegularSpan(4.0), PointSampling()), nothing))
    @test mapreduce(x -> x > 3, +, da; dims=X) == [0 1]
    @test mapreduce(x -> x > 3, +, da; dims=2) == [0 1]'
    @test dims(mapreduce(x-> x > 3, +, da; dims=Y())) ==
        (X(LinRange(143.0, 145.0, 2), SampledIndex(Ordered(), RegularSpan(2.0), PointSampling()), nothing),
         Y([-37.0], SampledIndex(Ordered(), RegularSpan(4.0), PointSampling()), nothing))
    @test reduce(+, da) == reduce(+, a)
    @test reduce(+, da; dims=X) == [4 6]
    @test reduce(+, da; dims=Y()) == [3 7]'
    @test dims(reduce(+, da; dims=Y())) ==
        (X(LinRange(143.0, 145.0, 2), SampledIndex(Ordered(), RegularSpan(2.0), PointSampling()), nothing),
         Y([-37.0], SampledIndex(Ordered(), RegularSpan(4.0), PointSampling()), nothing))
    @test std(da) === std(a)
    @test std(da; dims=1) == [1.4142135623730951 1.4142135623730951]
    @test std(da; dims=Y()) == [0.7071067811865476 0.7071067811865476]'
    @test var(da; dims=1) == [2.0 2.0]
    @test var(da; dims=Y()) == [0.5 0.5]'
    if VERSION > v"1.1-"
        @test extrema(da; dims=Y) == permutedims([(1, 2) (3, 4)])
        @test extrema(da; dims=X) == [(1, 3) (2, 4)]
    end
    @test dims(var(da; dims=Y())) ==
        (X(LinRange(143.0, 145.0, 2), SampledIndex(Ordered(), RegularSpan(2.0), PointSampling()), nothing),
         Y([-37.0], SampledIndex(Ordered(), RegularSpan(4.0), PointSampling()), nothing))
    a = [1 2 3; 4 5 6]
    da = DimensionalArray(a, dimz)
    @test median(da) == 3.5
    @test median(da; dims=X()) == [2.5 3.5 4.5]
    @test median(da; dims=2) == [2.0 5.0]'
end

@testset "dimension dropping methods" begin
    a = [1 2 3; 4 5 6]
    dimz = X((143, 145); indexmode=SampledIndex()), Y((-38, -36); indexmode=SampledIndex())
    da = DimensionalArray(a, dimz)
    # Dimensions must have length 1 to be dropped
    @test dropdims(da[X(1:1)]; dims=X) == [1, 2, 3]
    @test dropdims(da[2:2, 1:1]; dims=(X(), Y()))[] == 4
    @test typeof(dropdims(da[2:2, 1:1]; dims=(X(), Y()))) <: DimensionalArray{Int,0,Tuple{}}
    @test refdims(dropdims(da[X(1:1)]; dims=X)) == 
        (X(143.0; indexmode=SampledIndex(;span=RegularSpan(2.0))),)
    dropped = dropdims(da[X(1:1)]; dims=X)
    @test dropped[1:2] == [1, 2]
    @test length.(dims(dropped[1:2])) == size(dropped[1:2])
end

if VERSION > v"1.1-"
    @testset "iteration methods" begin
        a = [1 2 3 4
             3 4 5 6
             5 6 7 8]
        # eachslice
        da = DimensionalArray(a, (Y((10, 30)), Ti(1:4)))
        @test [mean(s) for s in eachslice(da; dims=Ti)] == [3.0, 4.0, 5.0, 6.0]
        @test [mean(s) for s in eachslice(da; dims=2)] == [3.0, 4.0, 5.0, 6.0]
        slices = [s .* 2 for s in eachslice(da; dims=Y)]
        @test map(sin, da) == map(sin, a)
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


@testset "simple dimension reordering methods" begin
    da = DimensionalArray(zeros(5, 4), (Y((10, 20); indexmode=SampledIndex()), 
                                        X(1:4; indexmode=SampledIndex())))
    tda = transpose(da)
    @test tda == transpose(data(da))
    resultdims = (X(1:4; indexmode=SampledIndex(span=RegularSpan(1))),
                  Y(LinRange(10.0, 20.0, 5); indexmode=SampledIndex(span=RegularSpan(2.5))))
    @test typeof(dims(tda)) == typeof(resultdims) 
    @test dims(tda) == resultdims
    @test size(tda) == (4, 5)

    tda = Transpose(da)
    @test tda == Transpose(data(da))
    @test dims(tda) == (X(1:4; indexmode=SampledIndex(span=RegularSpan(1))),
                        Y(LinRange(10.0, 20.0, 5); indexmode=SampledIndex(span=RegularSpan(2.5))))
    @test size(tda) == (4, 5)
    @test typeof(tda) <: DimensionalArray

    ada = adjoint(da)
    @test ada == adjoint(data(da))
    @test dims(ada) == (X(1:4; indexmode=SampledIndex(span=RegularSpan(1))),
                        Y(LinRange(10.0, 20.0, 5); indexmode=SampledIndex(span=RegularSpan(2.5))))
    @test size(ada) == (4, 5)

    dsp = permutedims(da)
    @test permutedims(data(da)) == data(dsp)
    @test dims(dsp) == reverse(dims(da))
end


@testset "dimension reordering methods with specified permutation" begin
    da = DimensionalArray(ones(5, 2, 4), (Y((10, 20); indexmode=SampledIndex()), 
                                          Ti(10:11; indexmode=SampledIndex()), 
                                          X(1:4; indexmode=SampledIndex())))
    dsp = permutedims(da, [3, 1, 2])

    @test permutedims(da, [X, Y, Ti]) == permutedims(da, (X, Y, Ti))
    @test permutedims(da, [X(), Y(), Ti()]) == permutedims(da, (X(), Y(), Ti()))
    dsp = permutedims(da, (X(), Y(), Ti()))
    @test dsp == permutedims(data(da), (3, 1, 2))
    @test dims(dsp) == (X(1:4; indexmode=SampledIndex(span=RegularSpan(1))),
                        Y(LinRange(10.0, 20.0, 5); indexmode=SampledIndex(span=RegularSpan(2.5))),
                        Ti(10:11; indexmode=SampledIndex(span=RegularSpan(1))))
    dsp = PermutedDimsArray(da, (3, 1, 2))
    @test dsp == PermutedDimsArray(data(da), (3, 1, 2))
    @test typeof(dsp) <: DimensionalArray
end

@testset "dimension mirroring methods" begin
    a = rand(5, 4)
    da = DimensionalArray(a, (Y((10, 20); indexmode=SampledIndex()), 
                              X(1:4; indexmode=SampledIndex())))

    cvda = cov(da; dims=X)
    @test cvda == cov(a; dims=2)
    @test dims(cvda) == (Y(LinRange(10.0, 20.0, 5); indexmode=SampledIndex(span=RegularSpan(2.5))),
                         Y(LinRange(10.0, 20.0, 5); indexmode=SampledIndex(span=RegularSpan(2.5))))
    crda = cor(da; dims=Y)
    @test crda == cor(a; dims=1)
    @test dims(crda) == (X(1:4; indexmode=SampledIndex(span=RegularSpan(1))),
                         X(1:4; indexmode=SampledIndex(span=RegularSpan(1))))
end

@testset "mapslices" begin
    a = [1 2 3 4
         3 4 5 6
         5 6 7 8]
    da = DimensionalArray(a, (Y((10, 30); indexmode=SampledIndex(sampling=IntervalSampling())), 
                              Ti(1:4; indexmode=SampledIndex(sampling=IntervalSampling()))))
    ms = mapslices(sum, da; dims=Y)
    @test ms == [9 12 15 18]
    @test typeof(dims(ms)) == 
    typeof((Y([10.0]; indexmode=SampledIndex(Ordered(), RegularSpan(30.0), IntervalSampling(Center()))),
            Ti(1:4; indexmode=SampledIndex(Ordered(), RegularSpan(1), IntervalSampling(Start())))))
    @test refdims(ms) == ()
    ms = mapslices(sum, da; dims=Ti)
    @test data(ms) == [10 18 26]'
end

@testset "array info" begin
    da = DimensionalArray(zeros(5, 4), (Y((10, 20)), X(1:4)))
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
    da = DimensionalArray(a, (X(1:2), Y(1:3)))
    b = [7 8 9; 10 11 12]
    db = DimensionalArray(b, (X(3:4), Y(1:3)))
    @test cat(da, db; dims=X()) == [1 2 3; 4 5 6; 7 8 9; 10 11 12]
    testdims = (X([1, 2, 3, 4]; indexmode=SampledIndex(span=RegularSpan(1))),
                Y(1:3; indexmode=SampledIndex(span=RegularSpan(1))))
    @test cat(da, db; dims=(X(),)) == cat(da, db; dims=X()) == cat(da, db; dims=X)
          cat(da, db; dims=1) == cat(da, db; dims=(1,))
    @test typeof(dims(cat(da, db; dims=X()))) == typeof(testdims)
    @test val.(dims(cat(da, db; dims=X()))) == val.(testdims)
    @test indexmode.(dims(cat(da, db; dims=X()))) == indexmode.(testdims)
    @test cat(da, db; dims=Y()) == [1 2 3 7 8 9; 4 5 6 10 11 12]
    @test cat(da, db; dims=Z(1:2)) == cat(a, b; dims=3)
    @test cat(da, db; dims=(Z(1:1), Ti(1:2))) == cat(a, b; dims=4)
    @test cat(da, db; dims=(X(), Ti(1:2))) == cat(a, b; dims=3)
    dx = cat(da, db; dims=(X(), Ti(1:2)))
    @test dims(dx) == DimensionalData.formatdims(dx, (X(1:2), Y(1:3), Ti(1:2)))
end

@testset "unique" begin
    a = [1 1 6; 1 1 6]
    da = DimensionalArray(a, (X(1:2), Y(1:3)))
    @test unique(da; dims=X()) == [1 1 6]
    @test unique(da; dims=Y) == [1 6; 1 6]
end

# These need fixes in base. kwargs are ::Integer so we can't add methods
# or dispatch on AbstractDimension in underscore _methods
# accumulate
# cumsum
# cumprod
