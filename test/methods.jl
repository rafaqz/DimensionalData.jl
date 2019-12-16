using DimensionalData, Statistics, Test, Unitful, SparseArrays

using DimensionalData: X, Y, Z, Time

using LinearAlgebra: Transpose

@testset "dimension reducing methods" begin
    a = [1 2; 3 4]
    dimz = (X((143, 145)), Y((-38, -36)))
    da = DimensionalArray(a, dimz)

    @test sum(da; dims=X()) == sum(da; dims=1)
    @test sum(da; dims=Y()) == sum(da; dims=2) 
    @test typeof(dims(sum(da; dims=Y()))) == typeof((X(LinRange(143.0, 145.0, 2); grid=RegularGrid(;span=2.0)), 
                                                     Y([-38.0]; grid=RegularGrid(;order=Unordered(), span=4.0, sampling=MultiSample()))))
    @test prod(da; dims=X) == [3 8]
    @test prod(da; dims=Y()) == [2 12]'
    resultdimz = (X([143.0]; grid=RegularGrid(;order=Unordered(), span=4.0, sampling=MultiSample())), 
            Y(LinRange(-38.0, -36.0, 2); grid=RegularGrid(;span=2.0)))
    @test typeof(dims(prod(da; dims=X()))) == typeof(resultdimz)
    @test_broken bounds(dims(prod(da; dims=X()))) == bounds(resultdimz)
    @test maximum(da; dims=X) == [3 4]
    @test maximum(da; dims=Y()) == [2 4]'
    @test minimum(da; dims=X) == [1 2]
    @test minimum(da; dims=Y()) == [1 3]'
    @test_broken dims(minimum(da; dims=X())) == (X(143.0), Y(LinRange(-38.0, -36.0, 2)))
    @test mean(da; dims=X) == [2.0 3.0]
    @test mean(da; dims=Y()) == [1.5 3.5]'
    @test_broken  dims(mean(da; dims=Y())) == (X(LinRange(143.0, 145.0, 2)), Y(-38.0))
    @test mapreduce(x -> x > 3, +, da; dims=X) == [0 1]
    @test mapreduce(x -> x > 3, +, da; dims=Y()) == [0 1]'
    @test_broken dims(mapreduce(x-> x > 3, +, da; dims=Y())) == (X(LinRange(143.0, 145.0, 2)), Y(-38.0))
    @test reduce(+, da) == reduce(+, a)
    @test reduce(+, da; dims=X) == [4 6]
    @test reduce(+, da; dims=Y()) == [3 7]'
    @test_broken dims(reduce(+, da; dims=Y())) == (X(LinRange(143.0, 145.0, 2)), Y(-38.0))
    @test std(da; dims=X()) == [1.4142135623730951 1.4142135623730951]
    @test std(da; dims=Y()) == [0.7071067811865476 0.7071067811865476]'
    @test var(da; dims=X()) == [2.0 2.0]
    @test var(da; dims=Y()) == [0.5 0.5]'
    if VERSION > v"1.1-"
        @test extrema(da; dims=Y) == permutedims([(1, 2) (3, 4)])
        @test extrema(da; dims=X) == [(1, 3) (2, 4)]
    end
    @test_broken dims(var(da; dims=Y())) == (X(LinRange(143.0, 145.0, 2)), Y(-38.0))
    a = [1 2 3; 4 5 6]
    da = DimensionalArray(a, dimz)
    @test median(da; dims=Y()) == [2.0 5.0]'
    @test median(da; dims=X()) == [2.5 3.5 4.5]

end

@testset "dimension dropping methods" begin
    a = [1 2 3; 4 5 6]
    dimz = (X((143, 145)), Y((-38, -36)))
    da = DimensionalArray(a, dimz)
    # Dimensions must have length 1 to be dropped 
    @test dropdims(da[X(1:1)]; dims=X) == [1, 2, 3]
    @test dropdims(da[2:2, 1:1]; dims=(X(), Y()))[] == 4
    @test typeof(dropdims(da[2:2, 1:1]; dims=(X(), Y()))) <: DimensionalArray{Int,0,Tuple{}}
    @test refdims(dropdims(da[X(1:1)]; dims=X)) == (X(143.0; grid=RegularGrid(;span=2.0)),)
end

if VERSION > v"1.1-"
    @testset "iteration methods" begin
        a = [1 2 3 4
             3 4 5 6
             5 6 7 8]
        # eachslice
        da = DimensionalArray(a, (Y((10, 30)), Time(1:4)))
        @test [mean(s) for s in eachslice(da; dims=Time)] == [3.0, 4.0, 5.0, 6.0]
        slices = [s .* 2 for s in eachslice(da; dims=Y)] 
        @test map(sin, da) == map(sin, a)
        @test slices[1] == [2, 4, 6, 8]
        @test slices[2] == [6, 8, 10, 12]
        @test slices[3] == [10, 12, 14, 16]
        dims(slices[1]) == (Time(1.0:1.0:4.0),)
        slices = [s .* 2 for s in eachslice(da; dims=Time)] 
        @test slices[1] == [2, 6, 10]
        dims(slices[1]) == (Y(10.0:10.0:30.0),)
    end
end


@testset "simple dimension reordering methods" begin
    da = DimensionalArray(zeros(5, 4), (Y((10, 20)), X(1:4)))
    tda = transpose(da)
    @test tda == transpose(parent(da))
    @test dims(tda) == (X(LinRange(1.0, 4.0, 4); grid=RegularGrid(;span=1.0)), 
                  Y(LinRange(10.0, 20.0, 5); grid=RegularGrid(;span=2.5)))
    @test size(tda) == (4, 5)

    tda = Transpose(da)
    @test tda == Transpose(parent(da))
    @test dims(tda) == (X(LinRange(1.0, 4.0, 4); grid=RegularGrid(;span=1.0)), 
                        Y(LinRange(10.0, 20.0, 5); grid=RegularGrid(;span=2.5)))
    @test size(tda) == (4, 5)
    @test typeof(tda) <: DimensionalArray

    ada = adjoint(da)
    @test ada == adjoint(parent(da))
    @test dims(ada) == (X(LinRange(1.0, 4.0, 4); grid=RegularGrid(;span=1.0)), 
                        Y(LinRange(10.0, 20.0, 5); grid=RegularGrid(;span=2.5)))
    @test size(ada) == (4, 5)

    dsp = permutedims(da)
    @test permutedims(parent(da)) == parent(dsp)
    @test dims(dsp) == reverse(dims(da))
end


@testset "dimension reordering methods with specified permutation" begin
    da = DimensionalArray(ones(5, 2, 4), (Y((10, 20)), Time(10:11), X(1:4)))
    dsp = permutedims(da, [3, 1, 2])

    @test permutedims(da, [X, Y, Time]) == permutedims(da, (X, Y, Time))
    @test permutedims(da, [X(), Y(), Time()]) == permutedims(da, (X(), Y(), Time()))
    dsp = permutedims(da, (X(), Y(), Time()))
    @test dsp == permutedims(parent(da), (3, 1, 2)) 
    @test dims(dsp) == (X(LinRange(1.0, 4.0, 4); grid=RegularGrid(;span=1.0)), 
                        Y(LinRange(10.0, 20.0, 5); grid=RegularGrid(;span=2.5)), 
                        Time(LinRange(10.0, 11.0, 2); grid=RegularGrid(;span=1.0)))
    dsp = PermutedDimsArray(da, (3, 1, 2))
    @test dsp == PermutedDimsArray(parent(da), (3, 1, 2)) 
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
    @test dims(cvda) == (X(LinRange(1.0, 4.0, 4); grid=RegularGrid(;span=1.0)), 
                         X(LinRange(1.0, 4.0, 4); grid=RegularGrid(;span=1.0)))
    crda = cor(da; dims=Y)
    @test crda == cor(a; dims=1)
    @test dims(crda) == (Y(LinRange(10.0, 20.0, 5); grid=RegularGrid(;span=2.5)), 
                         Y(LinRange(10.0, 20.0, 5); grid=RegularGrid(;span=2.5)))
end

@testset "mapslices" begin
    a = [1 2 3 4
         3 4 5 6
         5 6 7 8]
    da = DimensionalArray(a, (Y((10, 30)), Time(1:4)))
    ms = mapslices(sum, da; dims=Y)
    @test ms == [9 12 15 18]
    @test typeof(dims(ms)) == typeof((Y([10.0]; grid=RegularGrid(;span=30.0, order=Unordered(), sampling=MultiSample())),
                                      Time(LinRange(1.0, 4.0, 4); grid=RegularGrid(;span=1.0))))
    @test refdims(ms) == ()
    ms = mapslices(sum, da; dims=Time)
    @test parent(ms) == [10 18 26]'
end

@testset "indexes" begin
    da = DimensionalArray(zeros(5, 4), (Y((10, 20)), X(1:4)))
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
accumulate
cumsum
cumprod
