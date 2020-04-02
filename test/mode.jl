using DimensionalData, Test, Unitful
using DimensionalData: Forward, Reverse,
      reversearray, reverseindex, slicebounds, slicemode, identify,
      indexorder, arrayorder, relationorder

@testset "identify IndexMode" begin
    @test identify(Sampled(sampling=Intervals()), X, 1:1) ==
        Sampled(Ordered(), Regular(1), Intervals(Center()))
    @test identify(Sampled(sampling=Intervals()), Ti, 1:2:3) ==
        Sampled(Ordered(), Regular(2), Intervals(Start()))

    @test identify(AutoIndex(), X, 1:2:10) ==
        Sampled(Ordered(), Regular(2), Points())
    @test identify(AutoIndex(), X, [1, 2, 3, 4, 5]) ==
        Sampled(Ordered(), Irregular(), Points())

    @test identify(Sampled(), X, 1:2:10) ==
        Sampled(Ordered(), Regular(2), Points())
    @test identify(Sampled(), X, [1, 2, 3, 4, 5]) ==
        Sampled(Ordered(), Irregular(), Points())

    @test identify(Sampled(sampling=Intervals()), X, 1:2:10) ==
        Sampled(Ordered(), Regular(2), Intervals(Center()))
    @test identify(Sampled(sampling=Intervals()), X, [1, 2, 3, 4, 5]) ==
        Sampled(Ordered(), Irregular(), Intervals(Center()))

    @test identify(Sampled(order=Ordered(Reverse(), Forward(), Forward())), X, 10:-2:1) ==
        Sampled(Ordered(Reverse(), Forward(), Forward()), Regular(-2), Points())

    @test identify(AutoIndex(), X, [:a, :b]) == Categorical()
    @test identify(AutoIndex(), X, ["a", "b"]) == Categorical()
    @test identify(AutoIndex(), X, ['a', 'b']) == Categorical()
    @test identify(AutoIndex(), X, [1, 2, 3, 4]) ==
        Sampled(span=Irregular())
    @test_broken identify(AutoIndex(AutoOrder()), X, [4, 3, 2, 1]) ==
        Sampled(Ordered(Reverse(), Forward(), Forward()), NoLocus())
    @test_broken identify(AutoIndex(AutoOrder()), X, [1, 3, 2, 9]) ==
        Sampled(Unordered(Forward(), NoLocus()))

end

@testset "order" begin
    @test indexorder(Ordered()) == Forward()
    @test arrayorder(Ordered()) == Forward()
    @test relationorder(Ordered()) == Forward()
    @test indexorder(Unordered()) == Unordered()
    @test arrayorder(Unordered()) == Unordered()
    @test relationorder(Unordered()) == Forward()
end

@testset "reverse" begin
    @test reverse(Reverse()) == Forward()
    @test reverse(Forward()) == Reverse()

    @test reversearray(Unordered(Forward())) ==
        Unordered(Reverse())
    @test reversearray(Ordered(Forward(), Reverse(), Forward())) ==
        Ordered(Forward(), Forward(), Reverse())

    @test reverseindex(Unordered(Forward())) ==
        Unordered(Reverse())
    @test reverseindex(Ordered(Forward(), Reverse(), Forward())) ==
        Ordered(Reverse(), Reverse(), Reverse())

    @test order(reverseindex(Sampled(order=Ordered(Forward(), Reverse(), Forward())))) ==
        Ordered(Reverse(), Reverse(), Reverse())
        Ordered(Forward(), Forward(), Reverse())
    @test order(reverseindex(Sampled(order=Ordered(Forward(), Reverse(), Reverse())))) ==
        Ordered(Reverse(), Reverse(), Forward())
    @test order(reverseindex(Categorical(order=Ordered(Forward(), Reverse(), Reverse())))) ==
        Ordered(Reverse(), Reverse(), Forward())
end

@testset "slicebounds and slicemode" begin
    index = [10.0, 20.0, 30.0, 40.0, 50.0]
    bound = (10.0, 60.0)
    @test slicebounds(Start(), bounds, index, 2:3) == (20.0, 40.0)
    bound = (0.0, 50.0)
    @test slicebounds(End(), bounds, index, 2:3) == (10.0, 30.0)
    bound = (0.5, 55.0)
    @test slicebounds(Center(), bounds, index, 2:3) == (15.0, 35.0)

    @testset "forwards" begin
        mode = Sampled(span=Irregular((10.0, 60.0)), sampling=Intervals(Start()))
        @test bounds(slicemode(mode, index, 3), X(index)) == (30.0, 40.0)
        @test bounds(slicemode(mode, index, 1:5), X(index)) == (10.0, 60.0)
        @test bounds(slicemode(mode, index, 2:3), X(index)) == (20.0, 40.0)
    end

    @testset "reverse" begin
        mode = Sampled(order=Ordered(index=Reverse()), span=Irregular(10.0, 60.0),
                       sampling=Intervals(Start()))
        @test bounds(slicemode(mode, index, 1:5), X(index)) == (10.0, 60.0)
        @test bounds(slicemode(mode, index, 1:3), X(index)) == (30.0, 60.0)
    end

    @testset "Irregular with no bounds" begin
        mode = Sampled(span=Irregular(), sampling=Intervals(Start()))
        @test bounds(slicemode(mode, index, 3), X()) == (30.0, 40.0)
        @test bounds(slicemode(mode, index, 2:4), X()) == (20.0, 50.0)
        # TODO should this be built into `identify` to at least get one bound?
        @test bounds(slicemode(mode, index, 1:5), X()) == (10.0, nothing)
        mode = Sampled(span=Irregular(), sampling=Intervals(End()))
        @test bounds(slicemode(mode, index, 3), X()) == (20.0, 30.0)
        @test bounds(slicemode(mode, index, 2:4), X()) == (10.0, 40.0)
        @test bounds(slicemode(mode, index, 1:5), X()) == (nothing, 50.0)
        mode = Sampled(span=Irregular(), sampling=Intervals(Center()))
        @test bounds(slicemode(mode, index, 3), X()) == (25.0, 35.0)
        @test bounds(slicemode(mode, index, 2:4), X()) == (15.0, 45.0)
        @test bounds(slicemode(mode, index, 1:5), X()) == (nothing, nothing)
    end

    @testset "regular intervals are unchanged" begin
        mode = Sampled(span=Regular(1.0), sampling=Intervals(Start()))
        @test slicemode(mode, index, 2:3) === mode
    end

    @testset "point sampling is unchanged" begin
        mode = Sampled(span=Regular(1.0), sampling=Points())
        @test slicemode(mode, index, 2:3) === mode
    end

end

@testset "Intervals bounds" begin
    @testset "Regular" begin
        @testset "forward index" begin
            index = 10.0:10.0:50.0
            dim = X(index; mode=Sampled(; sampling=Intervals(Start()), span=Regular(10.0)))
            @test bounds(dim) == (10.0, 60.0)
            dim = X(index; mode=Sampled(sampling=Intervals(End()), span=Regular(10.0)))
            @test bounds(dim) == (0.0, 50.0)
            dim = X(index; mode=Sampled(sampling=Intervals(Center()), span=Regular(10.0)))
            @test bounds(dim) == (5.0, 55.0)
        end
        @testset "reverse index" begin
            revindex = [10.0, 9.0, 8.0, 7.0, 6.0]
            dim = X(revindex; mode=Sampled(; order=Ordered(Reverse(),Forward(),Forward()),
                                               sampling=Intervals(Start()), span=Regular(-1.0)))
            @test bounds(dim) == (6.0, 11.0)
            dim = X(revindex; mode=Sampled(; order=Ordered(Reverse(),Forward(),Forward()),
                                               sampling=Intervals(End()), span=Regular(-1.0)))
            @test bounds(dim) == (5.0, 10.0)
            dim = X(revindex; mode=Sampled(; order=Ordered(Reverse(),Forward(),Forward()),
                                               sampling=Intervals(Center()), span=Regular(-1.0)))
            @test bounds(dim) == (5.5, 10.5)
        end
    end
end

@testset "Points bounds" begin
    index = 10:15
    dim = X(index; mode=Sampled(order=Ordered(), sampling=Points()))
    @test bounds(dim) == (10, 15)
    index = 15:-1:10
    dim = X(index; mode=Sampled(order=Ordered(index=Reverse()), sampling=Points()))
    last(dim), first(dim)
    @test bounds(dim) == (10, 15)
    dim = X(index; mode=Sampled(order=Unordered(), sampling=Points()))
    @test_throws ErrorException bounds(dim)
end

@testset "Categorical bounds" begin
    index = [:a, :b, :c, :d]
    dim = X(index; mode=Categorical(; order=Ordered()))
    @test bounds(dim) == (:a, :d)
    dim = X(index; mode=Categorical(; order=Ordered(;index=Reverse())))
    @test bounds(dim) == (:d, :a)
    dim = X(index; mode=Categorical(; order=Unordered()))
    @test_throws ErrorException bounds(dim)
end

