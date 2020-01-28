using DimensionalData, Statistics, Test, Unitful, SparseArrays

using DimensionalData: X, Y, Z, Time

using LinearAlgebra: Transpose


@testset "map" begin
    a = [1 2; 3 4]
    dimz = (X((143, 145)), Y((-38, -36)))
    da = DimensionalArray(a, dimz)

    @test map(x -> 2x, da) == [2 4; 6 8]
    @test map(x -> 2x, da) isa DimensionalArray{Int64,2}
end

@testset "dimension reducing methods" begin
    a = [1 2; 3 4]
    dimz = (X((143, 145)), Y((-38, -36)))
    da = DimensionalArray(a, dimz)

    @test sum(da; dims=X()) == sum(a; dims=1)
    @test sum(da; dims=Y()) == sum(a; dims=2)
    @test dims(sum(da; dims=Y())) ==
        (X(LinRange(143.0, 145.0, 2); grid=RegularGrid(;step=2.0)),
         Y([-38.0]; grid=RegularGrid(; step=4.0, sampling=MultiSample())))
    @test prod(da; dims=X) == [3 8]
    @test prod(da; dims=2) == [2 12]'
    resultdimz = (X([143.0]; grid=RegularGrid(;step=4.0, sampling=MultiSample())),
            Y(LinRange(-38.0, -36.0, 2); grid=RegularGrid(;step=2.0)))
    @test typeof(dims(prod(da; dims=X()))) == typeof(resultdimz)
    @test bounds(dims(prod(da; dims=X()))) == bounds(resultdimz)
    @test maximum(x -> 2x, da; dims=X) == [6 8]
    @test maximum(x -> 2x, da; dims=2) == [4 8]'
    @test maximum(da; dims=X) == [3 4]
    @test maximum(da; dims=2) == [2 4]'
    @test minimum(da; dims=1) == [1 2]
    @test minimum(da; dims=Y()) == [1 3]'
    @test dims(minimum(da; dims=X())) ==
        (X([143.0]; grid=RegularGrid(;step=4.0, sampling=MultiSample())),
         Y(LinRange(-38.0, -36.0, 2); grid=RegularGrid(;step=2.0)))
    @test mean(da; dims=1) == [2.0 3.0]
    @test mean(da; dims=Y()) == [1.5 3.5]'
    @test dims(mean(da; dims=Y())) ==
        (X(LinRange(143.0, 145.0, 2); grid=RegularGrid(;step=2.0)),
         Y([-38.0]; grid=RegularGrid(; step=4.0, sampling=MultiSample())))
    @test mapreduce(x -> x > 3, +, da; dims=X) == [0 1]
    @test mapreduce(x -> x > 3, +, da; dims=2) == [0 1]'
    @test dims(mapreduce(x-> x > 3, +, da; dims=Y())) ==
        (X(LinRange(143.0, 145.0, 2); grid=RegularGrid(;step=2.0)),
         Y([-38.0]; grid=RegularGrid(; step=4.0, sampling=MultiSample())))
    @test reduce(+, da) == reduce(+, a)
    @test reduce(+, da; dims=X) == [4 6]
    @test reduce(+, da; dims=Y()) == [3 7]'
    @test dims(reduce(+, da; dims=Y())) ==
        (X(LinRange(143.0, 145.0, 2); grid=RegularGrid(;step=2.0)),
         Y([-38.0]; grid=RegularGrid(; step=4.0, sampling=MultiSample())))
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
        (X(LinRange(143.0, 145.0, 2); grid=RegularGrid(;step=2.0)),
         Y([-38.0]; grid=RegularGrid(;step=4.0, sampling=MultiSample())))
    a = [1 2 3; 4 5 6]
    da = DimensionalArray(a, dimz)
    @test median(da) == 3.5
    @test median(da; dims=X()) == [2.5 3.5 4.5]
    @test median(da; dims=2) == [2.0 5.0]'
end

@testset "dimension dropping methods" begin
    a = [1 2 3; 4 5 6]
    dimz = (X((143, 145)), Y((-38, -36)))
    da = DimensionalArray(a, dimz)
    # Dimensions must have length 1 to be dropped
    @test dropdims(da[X(1:1)]; dims=X) == [1, 2, 3]
    @test dropdims(da[2:2, 1:1]; dims=(X(), Y()))[] == 4
    @test typeof(dropdims(da[2:2, 1:1]; dims=(X(), Y()))) <: DimensionalArray{Int,0,Tuple{}}
    @test refdims(dropdims(da[X(1:1)]; dims=X)) == (X(143.0; grid=RegularGrid(;step=2.0)),)
end

if VERSION > v"1.1-"
    @testset "iteration methods" begin
        a = [1 2 3 4
             3 4 5 6
             5 6 7 8]
        # eachslice
        da = DimensionalArray(a, (Y((10, 30)), Time(1:4)))
        @test [mean(s) for s in eachslice(da; dims=Time)] == [3.0, 4.0, 5.0, 6.0]
        @test [mean(s) for s in eachslice(da; dims=2)] == [3.0, 4.0, 5.0, 6.0]
        slices = [s .* 2 for s in eachslice(da; dims=Y)]
        @test map(sin, da) == map(sin, a)
        @test slices[1] == [2, 4, 6, 8]
        @test slices[2] == [6, 8, 10, 12]
        @test slices[3] == [10, 12, 14, 16]
        dims(slices[1]) == (Time(1.0:1.0:4.0),)
        slices = [s .* 2 for s in eachslice(da; dims=Time)]
        @test slices[1] == [2, 6, 10]
        dims(slices[1]) == (Y(10.0:10.0:30.0),)
        @test_throws ArgumentError [s .* 2 for s in eachslice(da; dims=(Y, Time))]
    end
end


@testset "simple dimension reordering methods" begin
    da = DimensionalArray(zeros(5, 4), (Y((10, 20)), X(1:4)))
    tda = transpose(da)
    @test tda == transpose(data(da))
    @test dims(tda) == (X(1:4; grid=RegularGrid(;step=1)),
                  Y(LinRange(10.0, 20.0, 5); grid=RegularGrid(;step=2.5)))
    @test size(tda) == (4, 5)

    tda = Transpose(da)
    @test tda == Transpose(data(da))
    @test dims(tda) == (X(1:4; grid=RegularGrid(;step=1)),
                        Y(LinRange(10.0, 20.0, 5); grid=RegularGrid(;step=2.5)))
    @test size(tda) == (4, 5)
    @test typeof(tda) <: DimensionalArray

    ada = adjoint(da)
    @test ada == adjoint(data(da))
    @test dims(ada) == (X(1:4; grid=RegularGrid(;step=1)),
                        Y(LinRange(10.0, 20.0, 5); grid=RegularGrid(;step=2.5)))
    @test size(ada) == (4, 5)

    dsp = permutedims(da)
    @test permutedims(data(da)) == data(dsp)
    @test dims(dsp) == reverse(dims(da))
end


@testset "dimension reordering methods with specified permutation" begin
    da = DimensionalArray(ones(5, 2, 4), (Y((10, 20)), Time(10:11), X(1:4)))
    dsp = permutedims(da, [3, 1, 2])

    @test permutedims(da, [X, Y, Time]) == permutedims(da, (X, Y, Time))
    @test permutedims(da, [X(), Y(), Time()]) == permutedims(da, (X(), Y(), Time()))
    dsp = permutedims(da, (X(), Y(), Time()))
    @test dsp == permutedims(data(da), (3, 1, 2))
    @test dims(dsp) == (X(1:4; grid=RegularGrid(;step=1)),
                        Y(LinRange(10.0, 20.0, 5); grid=RegularGrid(;step=2.5)),
                        Time(10:11; grid=RegularGrid(;step=1)))
    dsp = PermutedDimsArray(da, (3, 1, 2))
    @test dsp == PermutedDimsArray(data(da), (3, 1, 2))
    @test typeof(dsp) <: DimensionalArray
end

@testset "dimension mirroring methods" begin
    # Need to think about dims for these, currently (Y, Y) etc.
    # But you can't index (Y, Y) with dims as you get the
    # first Y both times. It will plot correctly at least.
    a = rand(5, 4)
    da = DimensionalArray(a, (Y((10, 20)), X(1:4)))

    cvda = cov(da; dims=X)
    @test cvda == cov(a; dims=2)
    @test dims(cvda) == (X(1:4; grid=RegularGrid(;step=1)),
                         X(1:4; grid=RegularGrid(;step=1)))
    crda = cor(da; dims=Y)
    @test crda == cor(a; dims=1)
    @test dims(crda) == (Y(LinRange(10.0, 20.0, 5); grid=RegularGrid(;step=2.5)),
                         Y(LinRange(10.0, 20.0, 5); grid=RegularGrid(;step=2.5)))
end

@testset "mapslices" begin
    a = [1 2 3 4
         3 4 5 6
         5 6 7 8]
    da = DimensionalArray(a, (Y((10, 30)), Time(1:4)))
    ms = mapslices(sum, da; dims=Y)
    @test ms == [9 12 15 18]
    @test typeof(dims(ms)) == typeof((Y([10.0]; grid=RegularGrid(; step=30.0, sampling=MultiSample())),
                                      Time(1:4; grid=RegularGrid(; step=1))))
    @test refdims(ms) == ()
    ms = mapslices(sum, da; dims=Time)
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
    testdims = (X([1, 2, 3, 4]; grid=RegularGrid(; step=1)),
                Y(1:3; grid=RegularGrid(; step=1)))
    @test cat(da, db; dims=(X(),)) == cat(da, db; dims=X()) == cat(da, db; dims=X)
          cat(da, db; dims=1) == cat(da, db; dims=(1,))
    @test typeof(dims(cat(da, db; dims=X()))) == typeof(testdims)
    @test val.(dims(cat(da, db; dims=X()))) == val.(testdims)
    @test grid.(dims(cat(da, db; dims=X()))) == grid.(testdims)
    @test cat(da, db; dims=Y()) == [1 2 3 7 8 9; 4 5 6 10 11 12]
    @test cat(da, db; dims=Z(1:2)) == cat(a, b; dims=3)
    @test cat(da, db; dims=(Z(1:1), Time(1:2))) == cat(a, b; dims=4)
    @test cat(da, db; dims=(X(), Time(1:2))) == cat(a, b; dims=3)
    dx = cat(da, db; dims=(X(), Time(1:2)))
    @test dims(dx) == DimensionalData.formatdims(dx, (X(1:2), Y(1:3), Time(1:2)))
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
