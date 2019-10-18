using LinearAlgebra: Transpose

@testset "dimension reducing methods" begin
    a = [1 2; 3 4]
    dimz = (X((143, 145)), Y((-38, -36)))
    da = DimensionalArray(a, dimz)

    @test sum(da; dims=X()) == sum(da; dims=1)
    @test sum(da; dims=Y()) == sum(da; dims=2) 
    @test dims(sum(da; dims=Y())) == (X(LinRange(143.0, 145.0, 2)), Y(-38.0))
    @test prod(da; dims=X) == [3 8]
    @test prod(da; dims=Y()) == [2 12]'
    @test dims(prod(da; dims=X())) == (X(143.0), Y(LinRange(-38.0, -36.0, 2)))
    @test maximum(da; dims=X) == [3 4]
    @test maximum(da; dims=Y()) == [2 4]'
    @test minimum(da; dims=X) == [1 2]
    @test minimum(da; dims=Y()) == [1 3]'
    @test dims(minimum(da; dims=X())) == (X(143.0), Y(LinRange(-38.0, -36.0, 2)))
    @test mean(da; dims=X) == [2.0 3.0]
    @test mean(da; dims=Y()) == [1.5 3.5]'
    @test dims(mean(da; dims=Y())) == (X(LinRange(143.0, 145.0, 2)), Y(-38.0))
    @test mapreduce(x -> x > 3, +, da; dims=X) == [0 1]
    @test mapreduce(x -> x > 3, +, da; dims=Y()) == [0 1]'
    @test dims(mapreduce(x-> x > 3, +, da; dims=Y())) == (X(LinRange(143.0, 145.0, 2)), Y(-38.0))
    @test reduce(+, da) == reduce(+, a)
    @test reduce(+, da; dims=X) == [4 6]
    @test reduce(+, da; dims=Y()) == [3 7]'
    @test dims(reduce(+, da; dims=Y())) == (X(LinRange(143.0, 145.0, 2)), Y(-38.0))
    @test std(da; dims=X()) == [1.4142135623730951 1.4142135623730951]
    @test std(da; dims=Y()) == [0.7071067811865476 0.7071067811865476]'
    @test var(da; dims=X()) == [2.0 2.0]
    @test var(da; dims=Y()) == [0.5 0.5]'
    @test dims(var(da; dims=Y())) == (X(LinRange(143.0, 145.0, 2)), Y(-38.0))
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
    @test refdims(dropdims(da[X(1:1)]; dims=X)) == (X(143.0),)
end

if VERSION > v"1.1-"
    @testset "iteration methods" begin
        a = [1 2 3 4
             3 4 5 6
             5 6 7 8]
        # eachslice
        da = DimensionalArray(a, (Y(10:30), Time(1:4)))
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
    da = DimensionalArray(zeros(5, 4), (Y(10:20), X(1:4)))
    tda = transpose(da)
    @test tda == transpose(parent(da))
    @test dims(tda) == (X(LinRange(1.0, 4.0, 4)), Y(LinRange(10.0, 20.0, 5)))
    @test size(tda) == (4, 5)

    tda = Transpose(da)
    @test tda == Transpose(parent(da))
    @test dims(tda) == (X(LinRange(1.0, 4.0, 4)), Y(LinRange(10.0, 20.0, 5)))
    @test size(tda) == (4, 5)
    @test typeof(tda) <: DimensionalArray

    ada = adjoint(da)
    @test ada == adjoint(parent(da))
    @test dims(ada) == (X(LinRange(1.0, 4.0, 4)), Y(LinRange(10.0, 20.0, 5)))
    @test size(ada) == (4, 5)

    dsp = permutedims(da)
    @test permutedims(parent(da)) == parent(dsp)
    @test dims(dsp) == reverse(dims(da))
end


@testset "dimension reordering methods with specified permutation" begin
    da = DimensionalArray(ones(5, 2, 4), (Y(10:20), Time(10:11), X(1:4)))
    dsp = permutedims(da, [3, 1, 2])

    @test permutedims(da, [X, Y, Time]) == permutedims(da, (X, Y, Time))
    @test permutedims(da, [X(), Y(), Time()]) == permutedims(da, (X(), Y(), Time()))
    dsp = permutedims(da, (X(), Y(), Time()))
    @test dsp == permutedims(parent(da), (3, 1, 2)) 
    @test dims(dsp) == (X(LinRange(1.0, 4.0, 4)), Y(LinRange(10.0, 20.0, 5)), Time(LinRange(10.0, 11.0, 2)))

    dsp = PermutedDimsArray(da, (3, 1, 2))
    @test dsp == PermutedDimsArray(parent(da), (3, 1, 2)) 
    @test typeof(dsp) <: DimensionalArray
end

@testset "dimension mirroring methods" begin
    # Need to think about dims for these, currently (Y, Y) etc.
    # But you can't index (Y, Y) with dims as you get the
    # first Y both times. It will plot correctly at least.
    a = rand(5, 4)
    da = DimensionalArray(a, (Y(10:20), X(1:4)))

    cvda = cov(da; dims=X)
    @test cvda == cov(a; dims=2)
    @test dims(cvda) == (X(LinRange(1.0, 4.0, 4)), X(LinRange(1.0, 4.0, 4)))
    crda = cor(da; dims=Y)
    @test crda == cor(a; dims=1)
    @test dims(crda) == (Y(LinRange(10.0, 20.0, 5)), Y(LinRange(10.0, 20.0, 5)))
end

@testset "mapslices" begin
    a = [1 2 3 4
         3 4 5 6
         5 6 7 8]
    da = DimensionalArray(a, (Y(10:30), Time(1:4)))
    ms = mapslices(sum, da; dims=Y)
    @test ms == [9 12 15 18]
    @test dims(ms) == (Y(10.0),Time(LinRange(1.0, 4.0, 4)))
    @test refdims(ms) == ()
    ms = mapslices(sum, da; dims=Time)
    @test parent(ms) == [10 18 26]'
end

# These need fixes in base. kwargs are ::Integer so we can't add methods
# or dispatch on AbstractDimension in underscore _methods
accumulate
cumsum
cumprod
